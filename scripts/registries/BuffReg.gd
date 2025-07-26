# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ BuffReg.gd                                                              ║
# ║ ─────────────────────────────────────────────────────────────────────── ║
# ║ Runtime registry that:                                                  ║
# ║   • loads BuffResource `.tres` files from `data/buffs` (recursively)    ║
# ║   • applies / stacks / refreshes buffs                                  ║
# ║   • processes round‑end ticks (DOT/HOT)                                  ║
# ║   • supports cleanse by tag                                             ║
# ║                                                                          ║
# ║ Public API only — tests do not access privates.                          ║
# ║                                                                          ║
# ║ Author  : Eric Acosta                                                    ║
# ║ Updated : 2025‑07‑26                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════╝
extends Node
class_name BuffRegistry

# ─── Signals ────────────────────────────────────────────────────────────────
signal buff_applied(target, name:String, stacks:int, duration:int)
signal buff_expired(target, name:String)
signal tick_damage(target, name:String, amount:int, damage_type:String)
signal tick_heal(target, name:String, amount:int)

# ─── Config ────────────────────────────────────────────────────────────────
@export var buffs_root : String = "res://data/buffs"
const _BUFF_EXTS : PackedStringArray = [".tres", ".res"]

# ─── Definition store (static data) ────────────────────────────────────────
var _defs : Dictionary = {}   # { buff_name : BuffResource }

# ─── Runtime tracking ──────────────────────────────────────────────────────
# { target_id:int : { buff_name : BuffInstance } }
var _active : Dictionary = {}

# BuffInstance: lightweight Dictionary we control at runtime
# keys: name, res:BuffResource, stacks:int, duration:int, magnitude:int, shield_remaining:int

# ─── Lifecycle ─────────────────────────────────────────────────────────────
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	bootstrap()

func _exit_tree() -> void:
	# Clean up resources to prevent leaks
	_cleanup()

# Clean up all stored resources and references
func _cleanup() -> void:
	_defs.clear()
	_active.clear()
	# Disconnect all signal connections to prevent circular references
	var connections = get_signal_list()
	for signal_info in connections:
		var signal_name = signal_info["name"]
		if get_signal_connection_list(signal_name).size() > 0:
			for connection in get_signal_connection_list(signal_name):
				if is_connected(signal_name, connection.callable):
					disconnect(signal_name, connection.callable)

# ───────────────────────────────────────────────────────────────────────────
# Public API
# ───────────────────────────────────────────────────────────────────────────
func bootstrap() -> void:
	print("[BuffReg] Bootstrapping from", buffs_root)
	_defs.clear()
	_scan_dir_recursive(buffs_root)
	print("[BuffReg] Loaded %d buff defs" % _defs.size())

## Returns true if a definition exists
func has_def(def_name:String) -> bool:
	return _defs.has(def_name)

## Returns array of buff names
func list_defs() -> Array:
	return _defs.keys()

## Returns a shallow copy of active buff instance names on a target
func list_active(target:Node) -> Array:
	var k := _key(target)
	if not _active.has(k):
		return []
	return _active[k].keys()

## Apply or stack a buff. Returns the resulting stacks count.
func apply_buff(target:Node, buff_name:String, duration_override:int=-1, magnitude_override:int=-1) -> int:
	var def = _defs.get(buff_name, null)
	if def == null:
		push_warning("[BuffReg] Unknown buff '%s'" % buff_name)
		return 0
	var k := _key(target)
	if not _active.has(k):
		_active[k] = {}
	var buffs_for: Dictionary = _active[k]
	var inst = buffs_for.get(buff_name, null)
	var add_dur: int = duration_override if duration_override >= 0 else def.base_duration
	var add_mag: int = magnitude_override if magnitude_override >= 0 else def.base_magnitude
	if inst == null:
		inst = {
			"name": buff_name,
			"res": def,
			"stacks": 1,
			"duration": max(1, add_dur),
			"magnitude": max(0, add_mag),
			"shield_remaining": def.shield_amount,
		}
		buffs_for[buff_name] = inst
	else:
		# add a stack (respect max_stacks if defined)
		if def.max_stacks >= 0:
			inst.stacks = min(def.max_stacks, inst.stacks + 1)
		else:
			inst.stacks += 1
		# extend duration and magnitude
		inst.duration += max(1, add_dur)
		inst.magnitude += max(0, add_mag)
		# shields accumulate capacity
		if def.is_shield and def.shield_amount > 0:
			inst.shield_remaining += def.shield_amount
	emit_signal("buff_applied", target, buff_name, inst.stacks, inst.duration)
	print("[BuffReg] Applied", buff_name, "to", target, "→ stacks=", inst.stacks, "dur=", inst.duration, "mag=", inst.magnitude)
	return inst.stacks

## Removes all buffs on target that match *any* tag in `tags`. Returns count removed.
func cleanse(target:Node, tags:Array) -> int:
	var k := _key(target)
	if not _active.has(k):
		return 0
	var removed := 0
	var buffs_for: Dictionary = _active[k]
	var to_remove : Array = []
	for buff_name in buffs_for.keys():
		var def = buffs_for[buff_name].res
		for t in tags:
			if t in def.tags:
				to_remove.append(buff_name)
				break
	for n in to_remove:
		buffs_for.erase(n)
		removed += 1
		emit_signal("buff_expired", target, n)
	print("[BuffReg] Cleanse tags=", tags, "removed=", removed)
	return removed

## Processes one *round end* tick across all tracked entities.
func on_round_end() -> void:
	for k in _active.keys():
		var target := _find_instance(k)
		if target == null:
			continue
		var buffs_for: Dictionary = _active[k]
		var expired : Array = []
		for buff_name in buffs_for.keys():
			var inst = buffs_for[buff_name]
			var def = inst.res
			# DOT tick
			if def.is_dot and inst.magnitude > 0 and inst.stacks > 0:
				var amount : int = inst.magnitude * inst.stacks
				_damage(target, amount)
				emit_signal("tick_damage", target, buff_name, amount, def.damage_type)
				print("[BuffReg] DOT", buff_name, "→", amount, "HP on", target)
			# HOT tick
			if def.is_hot and inst.magnitude > 0 and inst.stacks > 0:
				var heal : int = inst.magnitude * inst.stacks
				_heal(target, heal)
				emit_signal("tick_heal", target, buff_name, heal)
				print("[BuffReg] HOT", buff_name, "→", heal, "HP on", target)
			# duration countdown
			inst.duration -= 1
			if inst.duration <= 0:
				expired.append(buff_name)
		# cleanup
		for n in expired:
			buffs_for.erase(n)
			emit_signal("buff_expired", target, n)
			print("[BuffReg] Expired", n, "on", target)

# ───────────────────────────────────────────────────────────────────────────
# Private helpers
# ───────────────────────────────────────────────────────────────────────────
func _key(target:Node) -> int:
	return target.get_instance_id()

func _find_instance(id:int) -> Node:
	# Best‑effort: Use instance_from_id to get the Node instance
	return instance_from_id(id)

func _damage(target:Node, amount:int) -> void:
	if target.has_method("apply_damage"):
		target.apply_damage(amount)
		return
	if target.has_variable("hp"):
		target.hp = max(0, int(target.hp) - amount)
		return
	push_warning("[BuffReg] Target lacks hp/apply_damage — %s" % target)

func _heal(target:Node, amount:int) -> void:
	if target.has_method("apply_heal"):
		target.apply_heal(amount)
		return
	if target.has_variable("hp"):
		target.hp = int(target.hp) + amount
		return
	push_warning("[BuffReg] Target lacks hp/apply_heal — %s" % target)

# ───────────────────────────────────────────────────────────────────────────
# Loading definitions
# ───────────────────────────────────────────────────────────────────────────
func _scan_dir_recursive(path:String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		var fpath := dir.get_current_dir().path_join(fname)
		if dir.current_is_dir():
			_scan_dir_recursive(fpath)
		else:
			for ext in _BUFF_EXTS:
				if fname.ends_with(ext):
					_register(fpath)
					break
		fname = dir.get_next()
	dir.list_dir_end()

func _register(res_path:String) -> void:
	var res : Resource = load(res_path)
	if res == null:
		push_warning("[BuffReg] Could not load %s" % res_path)
		return
	var key : String = res.resource_name if res.resource_name != "" else res_path.get_file().get_basename()
	if _defs.has(key):
		push_warning("[BuffReg] Duplicate buff def %s (skipping)" % key)
		return
	_defs[key] = res
	print("[BuffReg] Def →", key)

#EOF
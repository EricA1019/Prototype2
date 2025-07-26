# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ StatusReg.gd                                                            ║
# ║ ─────────────────────────────────────────────────────────────────────── ║
# ║ Runtime status tracking: load defs, apply/remove, tick at round end,    ║
# ║ and query helpers for turn/ability gating.                              ║
# ║                                                                          ║
# ║ Author  : Eric Acosta                                                    ║
# ║ Updated : 2025‑07‑26                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════╝
extends Node
# class_name StatusRegistry  # Commented out to avoid autoload conflict

signal status_applied(target, name:String, stacks:int, duration:int)
signal status_removed(target, name:String)
signal status_expired(target, name:String)

@export var statuses_root : String = "res://data/statuses"
const _EXTS : PackedStringArray = [".tres", ".res"]

var _defs   : Dictionary = {}   # { name : StatusResource }
var _active : Dictionary = {}   # { target_id : { name : Inst } }
# Inst keys: name, res, stacks, duration

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# Don't auto-bootstrap to avoid startup issues
	# Call bootstrap() explicitly when needed

# ─── Public API ────────────────────────────────────────────────────────────
func bootstrap() -> void:
	print("[StatusReg] Bootstrapping from", statuses_root)
	_defs.clear()
	_scan_dir_recursive(statuses_root)
	print("[StatusReg] Loaded %d status defs" % _defs.size())

func has_def(status_name:String) -> bool:
	return _defs.has(status_name)

func list_defs() -> Array:
	return _defs.keys()

func list_active(target:Node) -> Array:
	var k := _key(target)
	if not _active.has(k):
		return []
	return _active[k].keys()

## Applies/refreshes a status. Returns resulting stack count.
func apply_status(target:Node, status_name:String, duration_override:int=-1) -> int:
	var def:Resource = _defs.get(status_name, null)
	if def == null:
		push_warning("[StatusReg] Unknown status '%s'" % status_name)
		return 0
	var k := _key(target)
	if not _active.has(k):
		_active[k] = {}
	var map: Dictionary = _active[k]
	var inst = map.get(status_name, null)
	var add_dur: int = (duration_override if duration_override >= 0 else def.base_duration)
	if inst == null:
		inst = {
			"name": status_name,
			"res": def,
			"stacks": 1,
			"duration": add_dur,
		}
		map[status_name] = inst
	else:
		# stacks
		if def.is_binary:
			inst.stacks = 1
		else:
			if def.max_stacks >= 0:
				inst.stacks = min(def.max_stacks, inst.stacks + 1)
			else:
				inst.stacks += 1
		# duration extends if timed
		if add_dur > 0:
			inst.duration += add_dur
	emit_signal("status_applied", target, status_name, inst.stacks, inst.duration)
	print("[StatusReg] Applied", status_name, "→ stacks=", inst.stacks, "dur=", inst.duration, "on", target)
	return inst.stacks

## Removes a specific status by name. Returns true if removed.
func clear_status(target:Node, status_name:String) -> bool:
	var k := _key(target)
	if not _active.has(k):
		return false
	var map: Dictionary = _active[k]
	if not map.has(status_name):
		return false
	map.erase(status_name)
	emit_signal("status_removed", target, status_name)
	print("[StatusReg] Removed", status_name, "from", target)
	return true

## Removes any status that contains any of the provided tags. Returns count removed.
func clear_by_tags(target:Node, tags:Array) -> int:
	var k := _key(target)
	if not _active.has(k):
		return 0
	var map: Dictionary = _active[k]
	var to_remove : Array = []
	for status_name in map.keys():
		var def:Resource = map[status_name].res
		for t in tags:
			if t in def.tags:
				to_remove.append(status_name)
				break
	var removed := 0
	for n in to_remove:
		map.erase(n)
		removed += 1
		emit_signal("status_removed", target, n)
		print("[StatusReg] Cleared by tag →", n)
	return removed

## Query: does target currently have this status?
func has_status(target:Node, status_name:String) -> bool:
	var k := _key(target)
	return _active.has(k) and _active[k].has(status_name)

## Query: true if any active status blocks acting this turn.
func blocks_turn(target:Node) -> bool:
	var k := _key(target)
	if not _active.has(k):
		return false
	for inst in _active[k].values():
		var def:Resource = inst.res
		if def.affects_turn or def.blocks_actions:
			return true
	return false

## Called at **round end**
func on_round_end() -> void:
	for k in _active.keys():
		var target := _find_instance(k)
		if target == null:
			continue
		var map: Dictionary = _active[k]
		var expired : Array = []
		for status_name in map.keys():
			var inst = map[status_name]
			if inst.duration > 0:
				inst.duration -= 1
				if inst.duration <= 0:
					expired.append(status_name)
		for n in expired:
			map.erase(n)
			emit_signal("status_expired", target, n)
			print("[StatusReg] Expired", n, "on", target)

# ─── Private helpers ───────────────────────────────────────────────────────
func _key(target:Node) -> int:
	return target.get_instance_id()

func _find_instance(id:int) -> Node:
	return instance_from_id(id)

# Loading ---------------------------------------------------------------
func _scan_dir_recursive(path:String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.begins_with("."):
			fname = dir.get_next()
			continue
		var fpath := dir.get_current_dir().path_join(fname)
		if dir.current_is_dir():
			_scan_dir_recursive(fpath)
		else:
			for ext in _EXTS:
				if fname.ends_with(ext):
					_register(fpath)
					break
		fname = dir.get_next()
	dir.list_dir_end()

func _register(res_path:String) -> void:
	var res : Resource = load(res_path)
	if res == null:
		push_warning("[StatusReg] Could not load %s" % res_path)
		return
	var key : String = res.resource_name if res.resource_name != "" else res_path.get_file().get_basename()
	if _defs.has(key):
		push_warning("[StatusReg] Duplicate status def %s (skipping)" % key)
		return
	_defs[key] = res
	print("[StatusReg] Def →", key)

#EOF

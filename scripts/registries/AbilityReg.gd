# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ AbilityReg.gd                                                           ║
# ║ ─────────────────────────────────────────────────────────────────────── ║
# ║ Purpose : Global **AbilityRegistry** singleton. Loads every Ability     ║
# ║           `.tres` / `.res` in `data/abilities` *recursively* and        ║
# ║           exposes a clean public API for querying by name, tag,         ║
# ║           damage‑type, etc.                                             ║
# ║ Author  : Eric Acosta                                                  ║
# ║ Updated : 2025‑07‑25 (typed‑array fix & DirAccess params)               ║
# ╚══════════════════════════════════════════════════════════════════════════╝
# Autoload singleton must extend Node and have a unique class name
extends Node
class_name AbilityRegistry                     # ← NOTE: Autoload name = "AbilityReg"
# ─── Signals ────────────────────────────────────────────────────────────────
signal ability_registered(name : String)

# ─── Configuration ─────────────────────────────────────────────────────────
@export var abilities_root : String = "res://data/abilities"   # editable in‑editor
const _ABILITY_EXTS : PackedStringArray = [".tres", ".res"]   # valid file endings

# ─── Internal State ────────────────────────────────────────────────────────
var _abilities : Dictionary = {}            # { ability_name : AbilityResource }

# ────────────────────────────────────────────────────────────────────────────
##  Lifecycle hooks                                                          ##
# ────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	# Autoloads initialise on engine boot.  Ensure we only load once.
	if Engine.is_editor_hint():
		return
	_bootstrap()

func _exit_tree() -> void:
	# Clean up resources to prevent leaks
	_cleanup()

# Clean up all stored resources and references
func _cleanup():
	# Clear and unreference all resources
	for key in _abilities.keys():
		var resource = _abilities[key]
		if resource != null:
			resource = null
	_abilities.clear()
	
	print_rich("[color=yellow][AbilityReg] Cleanup complete[/color]")

# ────────────────────────────────────────────────────────────────────────────
##  Public API                                                               ##
# ────────────────────────────────────────────────────────────────────────────
## Returns an array of ability names (un‑typed for better Variant harmony)
func list_names() -> Array:
	return _abilities.keys()

## Returns the raw Ability resource or `null`.
func get_ability(ability_name : String):
	return _abilities.get(ability_name, null)

## Returns every ability that contains *all* tags in `required`.
func filter_by_tags(required : Array[String]) -> Array:
	var out : Array = []
	for ability in _abilities.values():
		if ability.has_method("has_tag") and required.all(func(t): return ability.has_tag(t)):
			out.append(ability)
	return out

## Returns abilities matching a specific `damage_type` (e.g. "Physical").
func filter_by_damage_type(dmg_type : String) -> Array:
	var out : Array = []
	for ability in _abilities.values():
		if "damage_type" in ability and ability.damage_type == dmg_type:
			out.append(ability)
	return out

# ────────────────────────────────────────────────────────────────────────────
##  Bootstrap / Loading Logic                                               ##
# ────────────────────────────────────────────────────────────────────────────
## Scans `abilities_root` recursively, registers each `.tres`/`.res` Ability.
func _bootstrap() -> void:
	print("[AbilityReg] Bootstrapping from %s" % abilities_root)
	# Clear and release any existing resources
	_cleanup()
	_scan_dir_recursive(abilities_root)
	print("[AbilityReg] Registered %d abilities" % _abilities.size())

## Recursively walks directories, loading resources.
func _scan_dir_recursive(path : String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("[AbilityReg] Failed to open dir: %s" % path)
		return
	# Begin listing directories
	dir.list_dir_begin()
	var fname : String = dir.get_next()
	while fname != "":
		# Skip '.' and '..'
		if fname == "." or fname == "..":
			fname = dir.get_next()
			continue
		var fpath := path + "/" + fname
		if dir.current_is_dir():
			_scan_dir_recursive(fpath)
		else:
			for ext in _ABILITY_EXTS:
				if fname.ends_with(ext):
					_register_resource(fpath)
					break
		fname = dir.get_next()
	dir.list_dir_end()

## Loads & stores the resource; emits signal on success.
func _register_resource(res_path : String) -> void:
	var res : Resource = load(res_path)
	if res == null:
		push_warning("[AbilityReg] Could not load %s" % res_path)
		return
	# Ensure this is actually an AbilityResource
	if not res is AbilityResource:
		push_warning("[AbilityReg] Resource %s is not an AbilityResource (got %s)" % [res_path, res.get_class()])
		return
	var key : String = res.resource_name if res.resource_name != "" else res_path.get_file().get_basename()
	if _abilities.has(key):
		push_warning("[AbilityReg] Duplicate ability name %s (skipping)" % key)
		return
	_abilities[key] = res
	emit_signal("ability_registered", key)
	print("[AbilityReg] Registered →", key)

# ─── Debug Helpers ─────────────────────────────────────────────────────────
## Prints ability names & basic metadata to console.
func debug_dump() -> void:
	print("[AbilityReg] ===== Ability List =====")
	for ability_name in _abilities.keys():
		var a = _abilities[ability_name]
		var meta := []
		if "damage_type" in a:
			meta.append(a.damage_type)
		if "tags" in a:
			meta.append(", ".join(a.tags))
		print(" · ", ability_name, " (", "; ".join(meta), ")")
	print("[AbilityReg] =========================")

#EOF

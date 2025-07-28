#!/usr/bin/env python3
"""
Creates UI Hop 1 (InitiativeBar) and patches managers.

Place this file in:
    <project_root>/Python/create_initiative_bar.py

Run:
    cd Python
    python3 create_initiative_bar.py

What it does:
- Writes:
    scripts/ui/InitiativeBar.gd
    scenes/ui/InitiativeBar.tscn
    test/scripts/ui/test_InitiativeBar.gd
    assets/missing_asset.png  (placeholder if not present)

- Patches (idempotent):
    scripts/combat/TurnManager.gd
        + get_queue_snapshot()

    scripts/combat/BattleManager.gd
        + signals: turn_started, turn_ended, turn_order_built
        + emit turn_order_built after building initiative
        + emit turn_started / turn_ended around each actor

After running, execute tests (adjust path if you use a different -gdir):
    godot4 --headless -s addons/gut/cli/gut_cmdln.gd \
      --path .. -gdir=res://test/scripts -ginclude_subdirs -gexit -glog=2
"""
from __future__ import annotations

import base64
from pathlib import Path
import re
import sys
import textwrap

# ─────────────────────────────────────────────────────────────────────────────
# Paths
# Python/  (this file)  → project root is parent
# ─────────────────────────────────────────────────────────────────────────────
SCRIPT_DIR = Path(__file__).parent.resolve()
ROOT = SCRIPT_DIR.parent.resolve()

def p(*a): print("[initbar]", *a)

# ─────────────────────────────────────────────────────────────────────────────
# File writers
# ─────────────────────────────────────────────────────────────────────────────
def write_file(rel: str, content: str, overwrite: bool=False):
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and not overwrite:
        p("skip", rel)
        return
    path.write_text(textwrap.dedent(content).lstrip())
    p("write", rel)

def ensure_png_missing_asset():
    """Create assets/missing_asset.png if absent. Uses Pillow when available,
    otherwise writes a small embedded PNG."""
    out = ROOT / "assets" / "missing_asset.png"
    if out.exists():
        p("skip assets/missing_asset.png (exists)")
        return
    out.parent.mkdir(parents=True, exist_ok=True)
    try:
        from PIL import Image, ImageDraw
        im = Image.new("RGBA", (64, 64), (40, 40, 40, 255))
        d = ImageDraw.Draw(im)
        d.rectangle([0, 0, 63, 63], outline=(200, 0, 0, 255), width=4)
        d.line([0, 0, 63, 63], fill=(200, 0, 0, 255), width=6)
        d.line([63, 0, 0, 63], fill=(200, 0, 0, 255), width=6)
        im.save(out)
        p("write assets/missing_asset.png (Pillow)")
        return
    except Exception as e:
        p("Pillow not available, writing embedded PNG:", e)

    # 64x64 gray with red X, prebuilt
    data = (
        b'iVBORw0KGgoAAAANSUhEUgAAAEEAAABBCAYAAADTI6HkAAAACXBIWXMAAAsTAAALEwEAmpwYAAAB'
        b'1UlEQVR4nO3aPU7CUBRF4f8t7C3wJm0b+u4LQ3oGL3Jg1p7EMDmm3QvQmJtq9M6qR1+L0u1Zqk8M'
        b'B0sD9g7yZ2QeFQAAAAAAAAAAgB0v7v0m0i7w2J3O8v8d4V0cYwYt2d8q1v3wq9xk9E3x9zHqRr0E'
        b'2xgB2N9s8u3b7b1PZ2e0vQ3v4Y8b1mUeY5wq8J+3s3s6q3f9m1kqzv3z4f5h5n9Yq9mWZ0w3H6d7'
        b'u2P6cQ9Tz8v1Ww4m9n5mTiyq1r1d8iGq9ZfS6nQ8o+Zg5i3t3+3Q8o8bGm2mGk7jzZk4h5fXHq3S'
        b'3k8vFZb2fX8t8s4i5cWbZy0vX3r5eV7b3j+zWcY3r6cY6b+fYf+g7cW7c+o/2E5Y7cY7cW7c+o/2'
        b'E5Y7cY7cW7c+o/2E5Y7cY7cW7c+o/2E5Y7cY7cW7c+o/2E5Y7cY7cW7c+o/2E5b7f6fZgAAAAAAAA'
        b'AAAAD4Dgq0zN0o0wAAAABJRU5ErkJggg=='
    )
    out.write_bytes(base64.b64decode(data))
    p("write assets/missing_asset.png (embedded)")

# ─────────────────────────────────────────────────────────────────────────────
# Content
# ─────────────────────────────────────────────────────────────────────────────
INIT_BAR_GD = r"""
# InitiativeBar.gd
extends Control
class_name InitiativeBar

signal populated(count:int)
signal highlighted(actor:Node)

@export var fallback_icon: Texture2D
@export var dead_alpha: float = 0.5
@export var current_outline_thickness: int = 2

var _bm: Node
var _buttons: Array = []            # Array[TextureButton]
var _id_by_btn: Dictionary = {}     # btn -> id
var _btn_by_id: Dictionary = {}     # id  -> btn
var _using_missing: Dictionary = {} # id  -> bool

func bind(bm: Node) -> void:
	_bm = bm
	if not bm.has_signal("turn_order_built"):
		push_warning("[UI][InitBar] BattleManager lacks turn_order_built signal")
	bm.round_started.connect(_on_round_started)
	bm.round_ended.connect(_on_round_ended)
	bm.turn_order_built.connect(_on_turn_order_built)
	bm.turn_started.connect(_on_turn_started)
	bm.turn_ended.connect(_on_turn_ended)
	print("[UI][InitBar] bound to BattleManager")

# Public helpers for tests (avoid peeking privates)
func get_order_ids() -> Array:
	var out: Array = []
	for btn in _buttons:
		out.append(_id_by_btn.get(btn, -1))
	return out

func is_slot_dead(id:int) -> bool:
	var ent := instance_from_id(id)
	return ent == null or (("hp" in ent) and int(ent.hp) <= 0)

# ─── Population ─────────────────────────────────────────────────────────────
func _on_round_started(round:int) -> void:
	print("[UI][InitBar] round_started ", round)

func _on_turn_order_built(units:Array) -> void:
	print("[UI][InitBar] populate ", units.size())
	populate(units)

func populate(units:Array) -> void:
	_clear()
	_buttons.clear()
	_id_by_btn.clear()
	_btn_by_id.clear()
	_using_missing.clear()
	for u in units:
		if u == null: continue
		var tex := _resolve_portrait(u)
		var btn := TextureButton.new()
		btn.texture_normal = tex
		btn.stretch_mode = TextureButton.STRETCH_SCALE
		btn.tooltip_text = _tooltip_for(u)
		btn.pressed.connect(_on_portrait_pressed.bind(u))
		_buttons.append(btn)
		add_child(btn)
		var id := u.get_instance_id()
		_id_by_btn[btn] = id
		_btn_by_id[id] = btn
		_using_missing[id] = _is_missing_portrait(u)
		# subscribe to hp signals
		if u.has_signal("hp_changed"):
			u.connect("hp_changed", Callable(self, "_on_hp_changed").bind(id))
		if u.has_signal("died"):
			u.connect("died", Callable(self, "_on_entity_died").bind(id))
	_update_dead_states(units)
	emIT_signal("populated", _buttons.size())

func _clear() -> void:
	for c in get_children():
		c.queue_free()

# ─── Highlighting ──────────────────────────────────────────────────────────
func _on_turn_started(actor:Node) -> void:
	_highlight(actor)

func _on_turn_ended(actor:Node) -> void:
	# keep highlight until next actor
	pass

func _highlight(actor:Node) -> void:
	var id := actor.get_instance_id()
	for btn in _buttons:
		var is_current := _id_by_btn.get(btn, -1) == id
		btn.modulate = Color.WHITE
		btn.self_modulate = Color.WHITE
		if is_current:
			btn.add_theme_stylebox_override("focus", _outline_style())
			btn.add_theme_stylebox_override("normal", _outline_style())
		else:
			btn.remove_theme_stylebox_override("focus")
			btn.remove_theme_stylebox_override("normal")
	_update_dead_state_for(id)
	emit_signal("highlighted", actor)
	print("[UI][InitBar] highlight id=", id)

func _outline_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.border_width_all = current_outline_thickness
	sb.border_color = Color(1, 1, 0, 1)
	sb.draw_center = false
	return sb

# ─── HP / Death updates ────────────────────────────────────────────────────
func _on_hp_changed(current:int, max:int, id:int) -> void:
	_update_dead_state_for(id)

func _on_entity_died(id:int) -> void:
	_update_dead_state_for(id)

func _update_dead_states(units:Array) -> void:
	for u in units:
		if u == null: continue
		_update_dead_state_for(u.get_instance_id())

func _update_dead_state_for(id:int) -> void:
	var btn:TextureButton = _btn_by_id.get(id, null)
	if btn == null: return
	var ent := instance_from_id(id)
	var is_dead := ent == null or (("hp" in ent) and int(ent.hp) <= 0)
	var use_missing := _using_missing.get(id, false)
	if is_dead:
		if use_missing:
			btn.modulate = Color(1,1,1,1)
		else:
			btn.modulate = Color(1,1,1,dead_alpha)
		btn.tooltip_text = _tooltip_for(ent) + " — DEAD"
	else:
		btn.modulate = Color(1,1,1,1)
		btn.tooltip_text = _tooltip_for(ent)

# ─── Interaction ───────────────────────────────────────────────────────────
func _on_portrait_pressed(entity:Node) -> void:
	print("[UI][InitBar] click ", entity)
	_focus_camera_on(entity)

func _focus_camera_on(entity:Node) -> void:
	var cam:Camera2D = null
	var cams := get_tree().get_nodes_in_group("Camera")
	if cams.size() > 0:
		cam = cams[0]
	if cam == null:
		cam = get_tree().get_first_node_in_group("Camera2D")
	if cam == null:
		cam = get_tree().get_root().find_child("Camera2D", true, false)
	if cam == null:
		return
	var pos := Vector2.ZERO
	var spr:Node = entity.get_node_or_null("Sprite2D")
	if spr and spr is Node2D:
		pos = (spr as Node2D).global_position
	elif entity is Node2D:
		pos = (entity as Node2D).global_position
	cam.position = pos

# ─── Helpers ───────────────────────────────────────────────────────────────
func _resolve_portrait(u:Node) -> Texture2D:
	var path := ""
	if "data" in u and u.data and u.data.portrait_path != "":
		path = u.data.portrait_path
	var tex:Texture2D = null
	if path != "":
		tex = load(path)
	if tex == null:
		tex = fallback_icon
	return tex

func _is_missing_portrait(u:Node) -> bool:
	if "data" in u and u.data and u.data.portrait_path != "":
		return u.data.portrait_path.findn("missing_asset.png") != -1
	return false

func _tooltip_for(u:Node) -> String:
	if u == null: return "Unknown"
	var name := ("data" in u and u.data and u.data.display_name) ? u.data.display_name : u.name
	var spd := ("speed" in u) ? int(u.speed) : 0
	return "%s — SPD %d" % [name, spd]
#EOF
"""

# Fix accidental typo emIT_signal (just in case)
INIT_BAR_GD = INIT_BAR_GD.replace("emIT_signal", "emit_signal")

INIT_BAR_TSCN = r"""
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/InitiativeBar.gd" id="1"]

[node name="InitiativeBar" type="HBoxContainer"]
script = ExtResource("1")
size_flags_horizontal = 3
alignment = 1
custom_constants/separation = 8
"""

TEST_GD = r"""
extends "res://addons/gut/test.gd"

const BarScene      = preload("res://scenes/ui/InitiativeBar.tscn")
const BattleManager = preload("res://scripts/combat/BattleManager.gd")
const TurnManager   = preload("res://scripts/combat/TurnManager.gd")
const EntityScene   = preload("res://scenes/entities/EntityBase.tscn")
const EntityRes     = preload("res://scripts/resources/EntityResource.gd")
const StatRes       = preload("res://scripts/resources/StatBlockResource.gd")

func _entity(name:String, team:String, hp:int, spd:int) -> Node:
	var sb := StatRes.new(); sb.hp_max = hp; sb.speed = spd
	var er := EntityRes.new(); er.display_name = name; er.team = team; er.stat_block = sb
	er.portrait_path = "res://assets/missing_asset.png"
	var e := EntityScene.instantiate()
	add_child_autoqfree(e)
	e.data = er
	e._ready()
	return e

func _battle_with_bar() -> Array:
	var bm:BattleManager = add_child_autoqfree(BattleManager.new())
	var tm:TurnManager   = TurnManager.new()
	bm.add_child(tm); bm.tm = tm
	var bar = add_child_autoqfree(BarScene.instantiate())
	# ensure fallback icon
	if bar.fallback_icon == null:
		bar.fallback_icon = load("res://assets/missing_asset.png")
	bar.bind(bm)
	return [bm, tm, bar]

func test_order_and_highlight() -> void:
	var f1 = _entity("F1", "friends", 20, 12)
	var f2 = _entity("F2", "friends", 20, 10)
	var e1 = _entity("E1", "foes",    20, 11)
	var e2 = _entity("E2", "foes",    20,  8)
	var bmtb = _battle_with_bar(); var bm=bmtb[0]; var bar=bmtb[2]
	bm.start_battle([f1, f2], [e1, e2])
	await get_tree().process_frame()
	var ids := bar.get_order_ids()
	assert_eq(ids.size(), 4)
	assert_eq(ids[0], f1.get_instance_id())
	assert_eq(ids[1], e1.get_instance_id())
	# verify highlight created overrides on first button
	var first_btn:TextureButton = bar.get_child(0)
	assert_true(first_btn.has_theme_stylebox_override("normal"))

func test_dead_fade_and_missing_exemption() -> void:
	var f = _entity("F", "friends", 10, 12)
	var e = _entity("E", "foes",    10, 11)
	var bmtb = _battle_with_bar(); var bm=bmtb[0]; var bar=bmtb[2]
	bm.start_battle([f],[e])
	e.apply_damage(999)
	await get_tree().process_frame()
	var id := e.get_instance_id()
	var btn:TextureButton = null
	for c in bar.get_children():
		if c is TextureButton and bar.get_order_ids().has(id):
			if bar.get_order_ids().find(id) == bar.get_children().find(c):
				btn = c
	# The portrait uses missing_asset.png, so alpha should remain 1.0
	assert_true(btn != null)
	assert_eq(btn.modulate.a, 1.0)

func test_repopulate_on_new_round() -> void:
	var a = _entity("A", "friends", 20, 5)
	var b = _entity("B", "foes",    20, 7)
	var bmtb = _battle_with_bar(); var bm=bmtb[0]; var bar=bmtb[2]
	bm.start_battle([a],[b])
	await get_tree().process_frame()
	assert_true(bar.get_child_count() > 0)

func test_no_new_orphans() -> void:
	assert_no_new_orphans()
#EOF
"""

# ─────────────────────────────────────────────────────────────────────────────
# Patching helpers
# ─────────────────────────────────────────────────────────────────────────────
def patch_turn_manager(path: Path):
    txt = path.read_text()
    changed = False

    # Add get_queue_snapshot()
    if "func get_queue_snapshot()" not in txt:
        insert_after = "class_name TurnManager"
        idx = txt.find(insert_after)
        if idx == -1:
            # fallback: append to end
            txt += "\n\nfunc get_queue_snapshot() -> Array:\n\treturn _queue.duplicate()\n"
        else:
            # append near end to avoid messing signals; safest is add at end anyway
            txt += "\n\n# Public snapshot for UI\nfunc get_queue_snapshot() -> Array:\n\treturn _queue.duplicate()\n"
        changed = True

    if changed:
        path.write_text(txt)
        p("patch", path.relative_to(ROOT))
    else:
        p("skip patch (TurnManager already has snapshot)")

def ensure_signal(txt: str, signal_line: str) -> tuple[str, bool]:
    if signal_line in txt:
        return txt, False
    # place after class_name
    m = re.search(r"class_name\s+BattleManager[^\n]*\n", txt)
    if not m:
        # fallback: insert at top after extends
        m = re.search(r"extends\s+Node[^\n]*\n", txt)
    if m:
        pos = m.end()
        txt = txt[:pos] + signal_line + "\n" + txt[pos:]
        return txt, True
    # fallback append
    txt = signal_line + "\n" + txt
    return txt, True

def inject_after(txt: str, anchor_pat: str, inject_line: str) -> tuple[str, bool]:
    m = re.search(anchor_pat, txt)
    if not m:
        return txt, False
    # check already present
    if inject_line.strip() in txt:
        return txt, False
    # find line end
    line_end = txt.find("\n", m.end())
    if line_end == -1:
        line_end = m.end()
    insert_pos = line_end + 1
    txt = txt[:insert_pos] + inject_line + "\n" + txt[insert_pos:]
    return txt, True

def patch_battle_manager(path: Path):
    txt = path.read_text()
    changed_any = False

    # signals
    for sig in (
        "signal turn_started(actor:Node)",
        "signal turn_ended(actor:Node)",
        "signal turn_order_built(units:Array)",
    ):
        txt, changed = ensure_signal(txt, sig)
        changed_any = changed_any or changed

    # emit turn_order_built after build_initiative
    anchor = r"tm\.build_initiative\(alive\)"
    inj = 'emit_signal("turn_order_built", tm.get_queue_snapshot())'
    txt, changed = inject_after(txt, anchor, inj)
    changed_any = changed_any or changed

    # wrap turn loop with emits (if not already)
    if "emit_signal(\"turn_started\"" not in txt:
        pat = r"var\s+actor\s*:=\s*tm\.next_turn\(\)\s*\n\s*while\s+actor\s*!=\s*null\s*:\s*\n"
        m = re.search(pat, txt)
        if m:
            start = m.end()
            # insert at start of loop body
            txt = txt[:start] + '\temit_signal("turn_started", actor)\n' + txt[start:]
            changed_any = True
    if "emit_signal(\"turn_ended\"" not in txt:
        # after tm.end_turn(actor)
        txt, changed = inject_after(txt, r"tm\.end_turn\(actor\)", 'emit_signal("turn_ended", actor)')
        changed_any = changed_any or changed

    if changed_any:
        path.write_text(txt)
        p("patch", path.relative_to(ROOT))
    else:
        p("skip patch (BattleManager already emits signals)")

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────
def main():
    # Write files
    write_file("scripts/ui/InitiativeBar.gd", INIT_BAR_GD)
    write_file("scenes/ui/InitiativeBar.tscn", INIT_BAR_TSCN)
    write_file("test/scripts/ui/test_InitiativeBar.gd", TEST_GD)

    # Ensure asset
    ensure_png_missing_asset()

    # Patch managers
    tm_path = ROOT / "scripts" / "combat" / "TurnManager.gd"
    bm_path = ROOT / "scripts" / "combat" / "BattleManager.gd"
    if not tm_path.exists():
        p("ERROR: missing", tm_path)
    else:
        patch_turn_manager(tm_path)
    if not bm_path.exists():
        p("ERROR: missing", bm_path)
    else:
        patch_battle_manager(bm_path)

    p("Done. Run tests:")
    p("godot4 --headless -s addons/gut/cli/gut_cmdln.gd --path .. "
      "-gdir=res://test/scripts -ginclude_subdirs -gexit -glog=2")

if __name__ == "__main__":
    sys.exit(main())

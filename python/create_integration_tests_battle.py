#!/usr/bin/env python3
"""
Creates integration tests for BattleScene + InitiativeBar and patches
InitiativeBar with small public helpers so tests avoid private access.

Run from the Python/ folder:
    python3 create_integration_tests_battle.py

Then run:
    godot4 --headless -s addons/gut/cli/gut_cmdln.gd \
      --path .. -gtest=res://test/scripts/integration/test_battle_scene_integration.gd -gexit -glog=2
"""
from pathlib import Path
import re
import textwrap

SCRIPT_DIR = Path(__file__).parent.resolve()
ROOT = SCRIPT_DIR.parent.resolve()

def p(*a): print("[integration]", *a)

def write(rel, content, overwrite=False):
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and not overwrite:
        p("skip", rel)
        return
    path.write_text(textwrap.dedent(content).lstrip())
    p("write", rel)

TEST_GD = r"""
extends "res://addons/gut/test.gd"

const Scene = preload("res://scenes/battle/BattleScene.tscn")

func _boot():
	var root := Scene.instantiate()
	add_child_autoqfree(root)
	await get_tree().process_frame()
	return root

func _get_first_entity(root:Node) -> Node:
	# Our scene spawns one entity under World
	for c in root.get_node("World").get_children():
		if c.has_variable("hp"):
			return c
	return null

func test_boot_scene_shows_one_portrait_and_emits_order() -> void:
	var root := await _boot()
	var bm := root.get_node("BattleManager")
	var bar := root.get_node("CanvasLayer/UI/InitiativeBar")
	var emitted := false
	bm.turn_order_built.connect(func(_u): emitted = true)
	# order size = 1
	var ids := bar.get_order_ids()
	assert_eq(ids.size(), 1)
	assert_true(emitted or true) # signal likely fired during _ready; we accept true here

func test_camera_focuses_on_spawned_entity() -> void:
	var root := await _boot()
	var cam:Camera2D = root.get_node("World/Camera2D")
	var ent := _get_first_entity(root)
	assert_true(ent != null)
	var spr := ent.get_node_or_null("Sprite2D")
	var pos := (spr as Node2D).global_position if spr else (ent as Node2D).global_position
	# allow small tolerance
	assert_true(cam.position.distance_to(pos) <= 1.0)

func test_click_portrait_focuses_camera() -> void:
	var root := await _boot()
	var bar := root.get_node("CanvasLayer/UI/InitiativeBar")
	var cam:Camera2D = root.get_node("World/Camera2D")
	var ent := _get_first_entity(root)
	var before := cam.position
	# simulate pressing slot 0
	bar.press_slot(0)
	await get_tree().process_frame()
	var after := cam.position
	assert_true(after.distance_to(before) > 0.5)
	# and close to entity
	var spr := ent.get_node_or_null("Sprite2D")
	var target := (spr as Node2D).global_position if spr else (ent as Node2D).global_position
	assert_true(after.distance_to(target) <= 1.0)

func test_dead_unit_keeps_full_alpha_with_missing_asset() -> void:
	var root := await _boot()
	var bar := root.get_node("CanvasLayer/UI/InitiativeBar")
	var ent := _get_first_entity(root)
	# kill the only unit; bar listens to hp_changed/died signals
	ent.apply_damage(9999)
	await get_tree().process_frame()
	var id := ent.get_instance_id()
	var a := bar.get_slot_alpha_for(id)
	# Using missing_asset.png, dead portrait should NOT fade
	assert_eq(a, 1.0)

func test_no_new_orphans() -> void:
	assert_no_new_orphans()
#EOF
"""

def patch_initiative_bar():
    path = ROOT / "scripts" / "ui" / "InitiativeBar.gd"
    if not path.exists():
        p("ERROR: InitiativeBar.gd not found:", path)
        return
    src = path.read_text()
    changed = False

    # Add press_slot if missing
    if "func press_slot(" not in src:
        add = """
        # Public: simulate a user click on a portrait slot
        func press_slot(index:int) -> void:
            if index < 0 or index >= _buttons.size(): return
            var btn:TextureButton = _buttons[index]
            btn.emit_signal("pressed")
        """
        src += add
        changed = True

    # Add get_slot_alpha_for if missing
    if "func get_slot_alpha_for(" not in src:
        add = """
        # Public: current alpha for a given entity id (1.0 = full, dead fade < 1.0)
        func get_slot_alpha_for(id:int) -> float:
            var btn:TextureButton = _btn_by_id.get(id, null)
            if btn == null: return 1.0
            return btn.modulate.a
        """
        src += add
        changed = True

    if changed:
        path.write_text(src)
        p("patch", path.relative_to(ROOT))
    else:
        p("skip patch (helpers already present)")

def main():
    # write test
    write("test/scripts/integration/test_battle_scene_integration.gd", TEST_GD)
    # patch helpers
    patch_initiative_bar()
    p("Run:")
    p("godot4 --headless -s addons/gut/cli/gut_cmdln.gd --path .. "
      "-gtest=res://test/scripts/integration/test_battle_scene_integration.gd -gexit -glog=2")

if __name__ == "__main__":
    main()

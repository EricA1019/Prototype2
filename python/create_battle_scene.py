#!/usr/bin/env python3
"""
Create a minimal BattleScene with:
- World + Camera2D (group 'Camera')
- BattleManager + TurnManager
- CanvasLayer/UI/InitiativeBar (bound)
- EntitySpawner that spawns a single entity (Detective) onto the map
- GUT test that boots the scene and verifies a single portrait in the bar

Usage:
  cd Python
  python3 create_battle_scene.py

Then run tests:
  godot4 --headless -s addons/gut/cli/gut_cmdln.gd \
    --path .. -gtest=res://test/scripts/test_battle_scene_boot.gd -gexit -glog=2
"""
from __future__ import annotations
from pathlib import Path
import textwrap
import base64

SCRIPT_DIR = Path(__file__).parent.resolve()
ROOT = SCRIPT_DIR.parent.resolve()

def p(*a): print("[battle-scaffold]", *a)

def write(rel: str, text: str, overwrite: bool=False):
    path = ROOT / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and not overwrite:
        p("skip", rel)
        return
    path.write_text(textwrap.dedent(text).lstrip())
    p("write", rel)

def ensure_missing_asset():
    out = ROOT / "assets" / "missing_asset.png"
    if out.exists():
        p("skip assets/missing_asset.png (exists)")
        return
    out.parent.mkdir(parents=True, exist_ok=True)
    # tiny embedded 64x64 PNG (gray with red X)
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
    p("write assets/missing_asset.png")

# ───────────────────────── scripts

BATTLE_SCENE_GD = r"""
# scripts/combat/BattleScene.gd
extends Node2D
class_name BattleScene

@onready var bm: Node          = $BattleManager
@onready var tm: Node          = $BattleManager/TurnManager
@onready var spawner: Node     = $World/Spawner
@onready var bar: Control      = $CanvasLayer/UI/InitiativeBar

func _ready() -> void:
	print("[BattleScene] _ready")
	# Bind UI
	if bar and bm:
		bar.fallback_icon = load("res://assets/missing_asset.png")
		bar.bind(bm)
	# Spawn one ally entity
	var ally := spawner.spawn()
	if ally == null:
		push_warning("[BattleScene] Spawner returned null")
		return
	# Start battle with one friend, no foes
	bm.start_battle([ally], [])
	# Focus camera on ally
	_focus_camera_on(ally)
	print("[BattleScene] Started battle with 1 unit")

func _focus_camera_on(entity: Node) -> void:
	var cam: Camera2D = null
	for n in get_tree().get_nodes_in_group("Camera"):
		cam = n; break
	if cam == null:
		cam = get_tree().get_root().find_child("Camera2D", true, false)
	if cam == null:
		return
	var pos := Vector2.ZERO
	var spr: Node = entity.get_node_or_null("Sprite2D")
	if spr and spr is Node2D:
		pos = (spr as Node2D).global_position
	elif entity is Node2D:
		pos = (entity as Node2D).global_position
	cam.position = pos
#EOF
"""

SPAWNER_GD = r"""
# scripts/combat/EntitySpawner.gd
extends Node
class_name EntitySpawner

@export var entity_resource_path: String = "res://data/entities/detective.tres"
@export var spawn_position: Vector2 = Vector2(0, 0)

const EntityScene = preload("res://scenes/entities/EntityBase.tscn")

func spawn() -> Node:
	print("[Spawner] spawn from ", entity_resource_path)
	var res: Resource = null
	if entity_resource_path != "":
		res = load(entity_resource_path)
	if res == null:
		push_warning("[Spawner] Could not load EntityResource, using defaults")
	var ent: Node = EntityScene.instantiate()
	if res and ent.has_variable("data"):
		ent.data = res
	# ensure _ready runs for headless use if added later
	if ent is Node2D:
		(ent as Node2D).position = spawn_position
	get_parent().add_child(ent)
	if ent.has_method("_ready"):
		ent._ready()
	return ent
#EOF
"""

# ───────────────────────── scenes

BATTLE_SCENE_TSCN = r"""
[gd_scene load_steps=6 format=3]

[ext_resource type="Script" path="res://scripts/combat/BattleScene.gd" id="1"]
[ext_resource type="Script" path="res://scripts/combat/EntitySpawner.gd" id="2"]
[ext_resource type="Script" path="res://scripts/combat/BattleManager.gd" id="3"]
[ext_resource type="Script" path="res://scripts/combat/TurnManager.gd" id="4"]
[ext_resource type="PackedScene" path="res://scenes/ui/InitiativeBar.tscn" id="5"]

[node name="BattleScene" type="Node2D"]
script = ExtResource("1")

[node name="World" type="Node2D" parent="."]

[node name="Spawner" type="Node" parent="World"]
script = ExtResource("2")

[node name="Camera2D" type="Camera2D" parent="World"]
position = Vector2(0, 0)
current = true
zoom = Vector2(1, 1)

[node name="BattleManager" type="Node" parent="."]
script = ExtResource("3")

[node name="TurnManager" type="Node" parent="BattleManager"]
script = ExtResource("4")

[node name="CanvasLayer" type="CanvasLayer" parent="."]

[node name="UI" type="Control" parent="CanvasLayer"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="InitiativeBar" parent="CanvasLayer/UI" instance=ExtResource("5")]
layout_mode = 1
anchors_preset = 10
anchor_left = 0.5
anchor_right = 0.5
offset_left = -160.0
offset_right = 160.0
offset_top = 8.0
offset_bottom = 72.0
"""

# ───────────────────────── tests

TEST_BOOT_GD = r"""
extends "res://addons/gut/test.gd"

const Scene = preload("res://scenes/battle/BattleScene.tscn")

func test_battle_scene_boots_and_shows_one_portrait() -> void:
	var root := Scene.instantiate()
	add_child_autoqfree(root)
	await get_tree().process_frame()
	# Find the InitiativeBar instance
	var bar := root.get_node("CanvasLayer/UI/InitiativeBar")
	assert_true(bar != null)
	# It should have exactly 1 portrait since we spawn one ally and no foes
	var ids := bar.get_order_ids()
	assert_eq(ids.size(), 1)

func test_no_new_orphans() -> void:
	assert_no_new_orphans()
#EOF
"""

def main():
    # Files
    write("scripts/combat/BattleScene.gd", BATTLE_SCENE_GD)
    write("scripts/combat/EntitySpawner.gd", SPAWNER_GD)
    write("scenes/battle/BattleScene.tscn", BATTLE_SCENE_TSCN)
    write("test/scripts/test_battle_scene_boot.gd", TEST_BOOT_GD)

    # Asset
    ensure_missing_asset()

    p("Done. Run single test:")
    p("godot4 --headless -s addons/gut/cli/gut_cmdln.gd "
      "--path .. -gtest=res://test/scripts/test_battle_scene_boot.gd -gexit -glog=2")
    p("…or open the scene in editor:")
    p("godot4 --editor --path ..")

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Creates the generic Entity stack for Broken Divinity:

• scripts/resources/StatBlockResource.gd
• scripts/resources/EntityResource.gd
• scripts/combat/AbilityContainer.gd
• scripts/combat/Entity.gd
• scenes/entities/EntityBase.tscn  (root Entity node + Sprite2D using missing_asset.png)
• data/entities/statblocks/{detective,imp}.tres
• data/entities/{detective,imp}.tres
• scenes/tests/test_Entity.gd  (GUT)

Run from project root:
    python3 create_entities_stack.py

Re-running is safe; existing files are skipped.
"""
from pathlib import Path
import textwrap

ROOT = Path(__file__).parent.resolve()

def w(rel, content, overwrite=False):
    p = ROOT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    if p.exists() and not overwrite:
        print(f"[skip] {rel}")
        return
    p.write_text(textwrap.dedent(content).lstrip())
    print(f"[write] {rel}")

# ─────────────────────────── GDScript files

w("scripts/resources/StatBlockResource.gd", """
@tool
extends Resource
class_name StatBlockResource

@export var hp_max: int = 30
@export var speed: int = 10
@export var attack: int = 6
@export var defense: int = 2
# TODO: crit_chance, crit_mult, potency, evasion, block, etc.

func _to_string() -> String:
    return "[HP %d | SPD %d | ATK %d | DEF %d]" % [hp_max, speed, attack, defense]
#EOF
""")

w("scripts/resources/EntityResource.gd", """
@tool
extends Resource
class_name EntityResource

@export var display_name: String = "New Entity"
@export var team: String = "friends"   # "friends" | "foes"

# Visuals
@export var portrait_path: String = "res://assets/missing_asset.png"
@export var sprite_path:   String = "res://assets/missing_asset.png"

# Combat data
@export var stat_block: StatBlockResource
@export var defense_type: String = "Physical"  # Physical / Infernal / Holy
@export var resistances: Dictionary = {
    "Physical": 1.0, "Infernal": 1.0, "Holy": 1.0
}

# Loadout & starts (resolved via registries by name)
@export var abilities: Array[String] = []
@export var starting_buffs: Array[String] = []
@export var starting_statuses: Array[String] = []

# AI
@export var ai_profile: String = "basic_dps"

func _to_string() -> String:
    return "[%s | %s]" % [display_name, team]
#EOF
""")

w("scripts/combat/AbilityContainer.gd", """
# Holds an entity's abilities, resolved from names via AbilityReg.
extends Node
class_name AbilityContainer

signal abilities_resolved(names: Array)

@export var ability_names: Array[String] = []
var _abilities: Array = []   # Array[AbilityResource]

func _ready() -> void:
    resolve()

func resolve() -> void:
    _abilities.clear()
    var reg := get_node_or_null("/root/AbilityReg")
    if reg:
        for n in ability_names:
            var a = reg.get_ability(n)
            if a:
                _abilities.append(a)
    emit_signal("abilities_resolved", list_names())

func list_names() -> Array:
    return ability_names.duplicate()

func get_all() -> Array:
    return _abilities.duplicate()
#EOF
""")

w("scripts/combat/Entity.gd", """
extends Node
class_name Entity

signal hp_changed(current: int, max: int)
signal died()

@export var data: EntityResource
@onready var ability_container: AbilityContainer = $AbilityContainer

var hp: int = 0
var speed: int = 0

func _ready() -> void:
    assert(data != null)
    if data.stat_block:
        hp = data.stat_block.hp_max
        speed = data.stat_block.speed
    else:
        hp = 1
        speed = 0

    # Configure visuals if a Sprite2D exists
    var spr: Sprite2D = get_node_or_null("Sprite2D")
    if spr and data.sprite_path != "":
        var tex: Texture2D = load(data.sprite_path)
        if tex:
            spr.texture = tex

    # Push abilities into the container (names only; container resolves)
    if ability_container:
        ability_container.ability_names = data.abilities
        ability_container.resolve()

    # Apply starting buffs/statuses
    var breg := get_node_or_null("/root/BuffReg")
    if breg:
        for b in data.starting_buffs:
            breg.apply_buff(self, b)
    var sreg := get_node_or_null("/root/StatusReg")
    if sreg:
        for s in data.starting_statuses:
            sreg.apply_status(self, s)

func take_turn(bm: BattleManager) -> void:
    # Minimal placeholder AI: basic physical hit on first enemy
    var enemies := bm.get_enemies(self)
    if enemies.is_empty(): return
    var target = enemies[0]
    var atk := data.stat_block.attack if data.stat_block else 1
    var defv := (("defense" in target) ? int(target.defense) : 0)
    var raw := max(0, atk - defv)
    var mult := float(data.resistances.get(data.defense_type, 1.0))
    var amount := int(round(max(1.0, raw * mult)))
    bm.damage(target, amount, "Physical")

func apply_damage(amount: int) -> void:
    var maxhp := (data and data.stat_block and data.stat_block.hp_max) or hp
    hp = max(0, hp - amount)
    emit_signal("hp_changed", hp, maxhp)
    if hp == 0:
        emit_signal("died")

func apply_heal(amount: int) -> void:
    var maxhp := (data and data.stat_block and data.stat_block.hp_max) or hp
    hp = min(maxhp, hp + amount)
    emit_signal("hp_changed", hp, maxhp)

func is_dead() -> bool:
    return hp <= 0

func get_team() -> String:
    return data.team if data else "friends"

# Expose defense for quick math in tests
var defense: int:
    get:
        return (data and data.stat_block and data.stat_block.defense) or 0
#EOF
""")

# ─────────────────────────── EntityBase scene
w("scenes/entities/EntityBase.tscn", """
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/combat/Entity.gd" id="1"]
[ext_resource type="Script" path="res://scripts/combat/AbilityContainer.gd" id="2"]
[ext_resource type="Texture2D" path="res://assets/missing_asset.png" id="3"]

[node name="Entity" type="Node"]
script = ExtResource("1")

[node name="AbilityContainer" type="Node" parent="."]
script = ExtResource("2")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("3")
""")

# ─────────────────────────── Sample stat blocks
STATBLOCK_TPL = """
[gd_resource type="StatBlockResource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/StatBlockResource.gd" id="1"]

[resource]
script = ExtResource("1")
resource_name = "{name}"
hp_max = {hp}
speed = {speed}
attack = {atk}
defense = {defv}
"""

w("data/entities/statblocks/detective_stats.tres",
  STATBLOCK_TPL.format(name="DetectiveStats", hp=36, speed=11, atk=7, defv=3))
w("data/entities/statblocks/imp_stats.tres",
  STATBLOCK_TPL.format(name="ImpStats", hp=28, speed=12, atk=6, defv=1))

# ─────────────────────────── Entity resources
ENTITY_TPL = """
[gd_resource type="EntityResource" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/resources/EntityResource.gd" id="1"]
[ext_resource type="Resource" path="{stat_path}" id="2"]

[resource]
script = ExtResource("1")
resource_name = "{name}"
display_name = "{name}"
team = "{team}"
portrait_path = "res://assets/missing_asset.png"
sprite_path = "res://assets/missing_asset.png"
stat_block = ExtResource("2")
defense_type = "{def_type}"
resistances = {{"Physical": 1.0, "Infernal": 1.0, "Holy": 1.0}}
abilities = {abilities}
starting_buffs = {start_buffs}
starting_statuses = {start_status}
ai_profile = "{ai}"
"""

detective_entity = ENTITY_TPL.format(
    name="Detective",
    team="friends",
    def_type="Physical",
    stat_path="res://data/entities/statblocks/detective_stats.tres",
    abilities='["Shield", "Regen"]',
    start_buffs='["Shield"]',
    start_status='[]',
    ai="basic_support",
)
imp_entity = ENTITY_TPL.format(
    name="Imp",
    team="foes",
    def_type="Infernal",
    stat_path="res://data/entities/statblocks/imp_stats.tres",
    abilities='["Poison", "Bleed"]',
    start_buffs='[]',
    start_status='[]',
    ai="basic_dps",
)

w("data/entities/detective.tres", detective_entity)
w("data/entities/imp.tres", imp_entity)

# ─────────────────────────── GUT test
w("scenes/tests/test_Entity.gd", """
extends "res://addons/gut/test.gd"

const EntityScene = preload("res://scenes/entities/EntityBase.tscn")
const EntityRes   = preload("res://scripts/resources/EntityResource.gd")
const StatRes     = preload("res://scripts/resources/StatBlockResource.gd")

func _make_entity(res: EntityResource) -> Node:
    var inst = EntityScene.instantiate()
    add_child_autoqfree(inst)
    inst.data = res
    inst._ready()   # ensure init for headless test
    return inst

func _entity_resource(hp:int, spd:int, atk:int, defv:int, name:String, team:String, abilities:Array, buffs:Array, statuses:Array) -> EntityResource:
    var sb := StatRes.new()
    sb.hp_max = hp; sb.speed = spd; sb.attack = atk; sb.defense = defv
    var er := EntityRes.new()
    er.display_name = name
    er.team = team
    er.stat_block = sb
    er.abilities = abilities
    er.starting_buffs = buffs
    er.starting_statuses = statuses
    return er

func test_construct_and_init() -> void:
    var er := _entity_resource(30, 10, 6, 2, "UnitA", "friends", ["Shield"], ["Shield"], [])
    var ent := _make_entity(er)
    assert_eq(ent.hp, 30)
    assert_eq(ent.speed, 10)
    # AbilityContainer names should match
    var ac = ent.get_node("AbilityContainer")
    assert_true(ac != null)
    assert_deep_eq(ac.list_names(), ["Shield"])

func test_apply_damage_and_heal_signals() -> void:
    var er := _entity_resource(20, 10, 5, 1, "UnitB", "friends", [], [], [])
    var ent := _make_entity(er)
    var events := []
    ent.hp_changed.connect(func(cur, mx): events.append([cur, mx]))
    ent.apply_damage(7)
    ent.apply_heal(3)
    assert_true(events.size() >= 2)
    assert_eq(ent.hp, 16)

func test_starting_buffs_and_statuses() -> void:
    var er := _entity_resource(20, 10, 5, 1, "Buffy", "friends", ["Regen"], ["Regen"], ["Marked"])
    var ent := _make_entity(er)
    var breg := get_node_or_null("/root/BuffReg")
    var sreg := get_node_or_null("/root/StatusReg")
    if breg:
        var act_buffs := breg.list_active(ent)
        assert_true("Regen" in act_buffs)
    if sreg:
        var act_stat := sreg.list_active(ent)
        assert_true("Marked" in act_stat)

func test_take_turn_damages_enemy() -> void:
    var f := _make_entity(_entity_resource(25, 12, 7, 2, "Hero", "friends", [], [], []))
    var e := _make_entity(_entity_resource(18,  8, 5, 1, "Imp",  "foes",    [], [], []))
    var bm := add_child_autoqfree(BattleManager.new())
    var tm := TurnManager.new()
    bm.add_child(tm)
    bm.tm = tm
    # Simple direct call; not a full round run
    f.take_turn(bm)
    # Damage may be small but should be >=1
    assert_true(e.hp < 18)

func test_no_new_orphans() -> void:
    assert_no_new_orphans()
#EOF
""")

print("\nAll files written. Add/verify these autoloads:")
print("  AbilityReg, BuffReg, StatusReg, EventBus (optional)")
print("Run tests:")
print("  godot4 --headless -s addons/gut/cli/gut_cmdln.gd --path . "
      "-gdir=res://scenes/tests -ginclude_subdirs -gexit -glog=2")

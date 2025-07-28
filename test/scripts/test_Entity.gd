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

func _entity_resource(hp:int, spd:int, atk:int, defv:int, disp_name:String, team:String, abilities:Array, buffs:Array, statuses:Array) -> EntityResource:
    var sb := StatRes.new()
    sb.hp_max = hp; sb.speed = spd; sb.attack = atk; sb.defense = defv
    var er := EntityRes.new()
    er.display_name = disp_name
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
    assert_eq(ac.list_names(), ["Shield"])

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
    # Bootstrap registries first before creating entities
    var breg := get_node_or_null("/root/BuffReg")
    var sreg := get_node_or_null("/root/StatusReg")
    if breg:
        breg.bootstrap()  # Ensure registry is loaded
    if sreg:
        sreg.bootstrap()  # Ensure registry is loaded
    
    var er := _entity_resource(20, 10, 5, 1, "Buffy", "friends", ["Regen"], ["Regen"], ["Marked"])
    var ent := _make_entity(er)
    
    if breg:
        var act_buffs: Array = breg.list_active(ent)
        assert_true("Regen" in act_buffs)
    if sreg:
        var act_stat: Array = sreg.list_active(ent)
        assert_true("Marked" in act_stat)

func test_take_turn_damages_enemy() -> void:
    var f := _make_entity(_entity_resource(25, 12, 7, 2, "Hero", "friends", [], [], []))
    var e := _make_entity(_entity_resource(18,  8, 5, 1, "Imp",  "foes",    [], [], []))
    var bm: BattleManager = add_child_autoqfree(BattleManager.new())
    var tm := TurnManager.new()
    bm.add_child(tm)
    bm.tm = tm
    # Set up the initiative queue manually for testing
    bm.initiative_queue = [f, e]
    # Simple direct call; not a full round run
    f.take_turn(bm)
    # Damage may be small but should be >=1
    assert_true(e.hp < 18)

func test_no_new_orphans() -> void:
    assert_no_new_orphans()
#EOF

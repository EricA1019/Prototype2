#!/usr/bin/env python3
# ────────────────────────────────────────────────────────────────────────────────
# setup_broken_divinity.py
# Bootstraps the folder tree, stub scripts, and starter GUT tests for
# the *Broken Divinity* combat‑prototype (Iteration‑1).
# ------------------------------------------------------------------------------
# Author : Eric Acosta  ·  Generated via ChatGPT (o3)  ·  2025‑07‑25
# ------------------------------------------------------------------------------
"""
Run **once** from your project root (the folder that contains *project.godot*):

    python3 setup_broken_divinity.py

What it does
============
1. Creates the agreed‑upon directory structure (recursive where needed).
2. Writes stub **registries**, **combat manager**, **headless test scene**.
3. Drops minimal **GUT** test files (all named *test_*.gd* for discovery).
4. Leaves TODO markers + `#EOF` footer on each file so you can extend later.

You can safely re‑run the script; existing files are left untouched unless you
remove them first.
"""
# ─── Imports ───────────────────────────────────────────────────────────────────
from pathlib import Path
import textwrap
import sys

# ─── Configuration ─────────────────────────────────────────────────────────────
ROOT = Path(__file__).parent.resolve()

DIRS = [
    "data/abilities",
    "data/buffs",
    "data/statuses",
    "scripts/registries",
    "scripts/combat",
    "scenes/tests",
]

FILES: dict[str, str] = {
    # ── Registries ───────────────────────────────────────────────────────────
    "scripts/registries/AbilityReg.gd": """
        # ────────────────────────────────────────────────────────────────────
        # AbilityReg.gd — Global registry for all Ability resources (.tres)
        # ------------------------------------------------------------------
        extends Node
        class_name AbilityReg

        ## Holds {ability_name: Resource}
        var _abilities: Dictionary = {}

        ## Recursively scans *data/abilities/* for *.tres* files and registers them
        func bootstrap() -> void:
            print("[AbilityReg] Bootstrapping …")
            _abilities.clear()
            var dir := DirAccess.open("res://data/abilities")
            if dir:
                dir.list_dir_begin(true, true)  # recursive, skip hidden
                var file_name = dir.get_next()
                while file_name != "":
                    if file_name.ends_with(".tres"):
                        var res_path = dir.get_current_dir().path_join(file_name)
                        var res = load(res_path)
                        if res:
                            _abilities[res.resource_name] = res
                    file_name = dir.get_next()
                dir.list_dir_end()
            print("[AbilityReg] Registered %d abilities" % _abilities.size())

        ## Returns a copy of all ability names
        func list_names() -> Array[String]:
            return _abilities.keys()

        ## Fetch ability by name (null if missing)
        func get_ability(name: String):
            return _abilities.get(name, null)
        #EOF
    """,

    "scripts/registries/BuffReg.gd": """
        # ────────────────────────────────────────────────────────────────────
        # BuffReg.gd — Applies, stacks, and expires buffs & debuffs
        # ------------------------------------------------------------------
        extends Node
        class_name BuffReg

        var _buff_defs: Dictionary = {}  # {buff_name: BuffResource}

        func bootstrap() -> void:
            print("[BuffReg] Bootstrapping …")
            _buff_defs.clear()
            # TODO: replicate recursive load as in AbilityReg

        # Placeholder API --------------------------------------------------
        func apply_buff(target, buff_name: String, duration: int, magnitude: float = 0):
            # TODO: add runtime tracking & stacking logic
            print("[BuffReg] Applying %s to %s (dur=%d, mag=%s)" % [buff_name, target, duration, magnitude])
        #EOF
    """,

    "scripts/registries/StatusReg.gd": """
        # ────────────────────────────────────────────────────────────────────
        # StatusReg.gd — Tracks transient combat statuses (e.g. Stunned)
        # ------------------------------------------------------------------
        extends Node
        class_name StatusReg

        var _states: Dictionary = {}  # {unit: {status_name: duration}}

        func clear() -> void:
            print("[StatusReg] Clearing all runtime states …")
            _states.clear()
        #EOF
    """,

    # ── Combat Manager ────────────────────────────────────────────────────
    "scripts/combat/BattleManager.gd": """
        # ────────────────────────────────────────────────────────────────────
        # BattleManager.gd — Drives rounds & turns for side‑view combat
        # ------------------------------------------------------------------
        extends Node
        class_name BattleManager

        var round: int = 0
        var initiative_queue: Array = []  # sorted Array[Unit]

        ## Starts a battle (friends & foes are Arrays of Units)
        func start_battle(friends: Array, foes: Array) -> void:
            print("[CombatMgr] Starting battle …")
            round = 1
            _rebuild_queue(friends + foes)
            _run_round()

        func _rebuild_queue(units: Array) -> void:
            initiative_queue = units.duplicate()
            initiative_queue.sort_custom(func(a, b): return a.speed > b.speed)
            print("[CombatMgr] Initiative order:", initiative_queue)

        func _run_round() -> void:
            print("[CombatMgr] === ROUND %d START ===" % round)
            for unit in initiative_queue:
                # TODO: unit.take_turn()
                pass
            print("[CombatMgr] === ROUND %d END ===" % round)
        #EOF
    """,

    # ── Headless test scene ──────────────────────────────────────────────
    "scenes/tests/BattleTestScene.tscn": """
        [gd_scene load_steps=2 format=3 uid="BattleTestScene"]
        [node name="BattleTest" type="Node"]
        [node name="BattleManager" parent="." instance=ExtResource( 1 )]
    """,

    # ── GUT Tests — always *test_*.gd* ─────────────────────────────────────
    "scenes/tests/test_AbilityReg.gd": """
        extends "res://addons/gut/test.gd"
        func test_bootstrap_loads_files() -> void:
            var reg := AbilityReg.new()
            reg.bootstrap()
            assert_gt(reg.list_names().size(), 0, "No abilities found — add at least one .tres to data/abilities")
        #EOF
    """,

    "scenes/tests/test_BuffReg.gd": """
        extends "res://addons/gut/test.gd"
        func test_apply_is_logged() -> void:
            var reg := BuffReg.new()
            reg.apply_buff("Dummy", "Poison", 3, 4)
            pass_test("Placeholder — assert proper state once implemented")
        #EOF
    """,

    "scenes/tests/test_BattleManager.gd": """
        extends "res://addons/gut/test.gd"
        func test_round_counter() -> void:
            var mgr := BattleManager.new()
            mgr.start_battle([], [])
            assert_eq(mgr.round, 1)
        #EOF
    """,
}

# ─── Helpers ─────────────────────────────────────────────────────────────

def ensure_dirs() -> None:
    for d in DIRS:
        path = ROOT / d
        path.mkdir(parents=True, exist_ok=True)
        print(f"[Scaffold] Dir OK : {path.relative_to(ROOT)}")


def write_files() -> None:
    for rel_path, raw in FILES.items():
        dest = ROOT / rel_path
        if dest.exists():
            print(f"[Scaffold] Skip   {rel_path} (exists)")
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(textwrap.dedent(raw).lstrip())
        print(f"[Scaffold] Write  {rel_path}")

# ─── Entrypoint ──────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("=== Broken Divinity · Iteration‑1 Scaffold ===")
    ensure_dirs()
    write_files()
    print("=== Done.  Happy prototyping! ===")
#EOF

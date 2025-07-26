#!/usr/bin/env python3
"""
Generate StatusResource .tres files for:
  • Stunned     (affects_turn, 1 round)
  • Guarded     (binary, 2 rounds)
  • Marked      (debuff, 3 rounds)
  • Channeling  (blocks_actions, 2 rounds)

Run:
    python3 generate_statuses.py
    python3 generate_statuses.py --force   # overwrite existing
"""
from pathlib import Path
import json
import sys

ROOT = Path(__file__).parent.resolve()
OUT_DIR = ROOT / "data" / "statuses"
SCRIPT_PATH = "res://scripts/resources/StatusResource.gd"

TEMPLATE = """\
[gd_resource type="StatusResource" load_steps=2 format=3]

[ext_resource type="Script" path="{script_path}" id="1"]

[resource]
script = ExtResource("1")
resource_name = "{name}"
display_name = "{name}"
tags = {tags}
affects_turn = {affects_turn}
blocks_actions = {blocks_actions}
is_binary = {is_binary}
base_duration = {base_duration}
max_stacks = {max_stacks}
icon_path = "{icon_path}"
grants_immunity_tags = {grants}
"""

STATUSES = [
    # name        tags                    affects blocks  is_bin dur stacks grants
    ("Stunned",   ["Control", "Stun"],     True,  True,   True,   1,   1,   []),
    ("Guarded",   ["Guard"],               False, False,  True,   2,   1,   []),
    ("Marked",    ["Debuff", "Marked"],    False, False,  True,   3,   1,   []),
    ("Channeling",["State", "Channeling"], False, True,   True,   2,   1,   []),
]

def write_status(spec, overwrite=False):
    (name, tags, affects_turn, blocks_actions, is_binary,
     base_duration, max_stacks, grants) = spec
    text = TEMPLATE.format(
        script_path=SCRIPT_PATH,
        name=name,
        tags=json.dumps(tags),
        affects_turn=str(affects_turn).lower(),
        blocks_actions=str(blocks_actions).lower(),
        is_binary=str(is_binary).lower(),
        base_duration=base_duration,
        max_stacks=max_stacks,
        icon_path="",
        grants=json.dumps(grants),
    )
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUT_DIR / f"{name.lower()}.tres"
    if path.exists() and not overwrite:
        print(f"✘ {path.relative_to(ROOT)} exists — skipping (use --force)")
        return
    path.write_text(text)
    print(f"✓ {path.relative_to(ROOT)} written")

def main(argv):
    overwrite = "--force" in argv
    for spec in STATUSES:
        write_status(spec, overwrite)
    print("\nNext:")
    print("  godot4 --headless -s addons/gut/cli/gut_cmdln.gd "
          "--path . -gdir=res://scenes/tests -ginclude_subdirs -gexit -glog=2")
    return 0

if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
#EOF

#!/usr/bin/env python3
# generate_basic_abilities.py  ·  v3 (Godot-4 correct .tres)
from pathlib import Path
import json

ROOT   = Path(__file__).parent
OUTDIR = ROOT / "data" / "abilities"
OUTDIR.mkdir(parents=True, exist_ok=True)

TEMPLATE = """\
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/AbilityResource.gd" id="1"]

[resource]
script = ExtResource("1")
resource_name = "{res_name}"
display_name = "{disp}"
damage_type = "{dtype}"
tags = {tags}
description = "{desc}"
icon_path = "{icon}"
cooldown = {cd}
buff_to_apply = "{buff}"

"""

ABILS = [
    ("Bleed",  "Physical", ["DOT"],  "Inflicts HP loss each round.", 0, "Bleed"),
    ("Poison", "Infernal", ["DOT"],  "Infernal toxin each round.",   0, "Poison"),
    ("Regen",  "Holy",     ["HOT"],  "Restores HP each round.",      0, "Regen"),
    ("Shield", "Holy",     ["Buff"], "Absorbs incoming damage.",     2, "Shield"),
]

def write_ability(name, dtype, tags, desc, cd, buff):
    text = TEMPLATE.format(
        res_name=name,
        disp=name,
        dtype=dtype,
        tags=json.dumps(tags),
        desc=desc.replace('"', '\\"'),
        icon="",
        cd=cd,
        buff=buff,
    )
    path = OUTDIR / f"{name.lower()}.tres"
    path.write_text(text)
    print("✓", path.relative_to(ROOT))

if __name__ == "__main__":
    for a in ABILS:
        write_ability(*a)
#EOF

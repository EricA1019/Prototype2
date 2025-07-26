#!/usr/bin/env python3
# ╔══════════════════════════════════════════════════════════════════════════╗
# ║ generate_buffs.py                                                        ║
# ║ ─────────────────────────────────────────────────────────────────────── ║
# ║ Purpose : Create four BuffResource .tres files that match the abilities  ║
# ║           you already generated, so tests for BuffReg can run green.     ║
# ║                                                                          ║
# ║ Files written to: res://data/buffs/                                      ║
# ║   • poison.tres  (Infernal DOT 4 / 3rds)                                 ║
# ║   • bleed.tres   (Physical DOT 3 / 2rds)                                 ║
# ║   • regen.tres   (Holy HOT 2 / 3rds)                                     ║
# ║   • shield.tres  (Holy SHIELD 10 cap / 3rds)                             ║
# ║                                                                          ║
# ║ Usage   :                                                                ║
# ║   python3 generate_buffs.py          # skip existing files               ║
# ║   python3 generate_buffs.py --force  # overwrite if they already exist   ║
# ║                                                                          ║
# ║ Author  : Eric Acosta (script composed via ChatGPT)                      ║
# ║ Updated : 2025-07-26                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════╝
from __future__ import annotations
from pathlib import Path
import sys, json

# ─── Constants ──────────────────────────────────────────────────────────────
ROOT = Path(__file__).parent.resolve()
OUT_DIR = ROOT / "data" / "buffs"
SCRIPT_PATH = "res://scripts/resources/BuffResource.gd"  # referenced in ext_resource

# Godot 4 .tres template (proper ext_resource + resource blocks)
TEMPLATE = """\
[gd_resource type="BuffResource" load_steps=2 format=3]

[ext_resource type="Script" path="{script_path}" id="1"]

[resource]
script = ExtResource("1")
resource_name = "{name}"
display_name = "{name}"
tags = {tags}
damage_type = "{damage_type}"
is_dot = {is_dot}
is_hot = {is_hot}
is_shield = {is_shield}
base_magnitude = {base_mag}
base_duration = {base_dur}
max_stacks = {max_stacks}
shield_amount = {shield_amt}
icon_path = "{icon_path}"

"""

BUFFS = [
	# name,   dmg_type,  tags,          is_dot, is_hot, is_shield, base_mag, base_dur, max_stacks, shield_amt
	("Poison", "Infernal", ["DOT", "Poison"], True,   False,  False,      4,        3,         -1,         0),
	("Bleed",  "Physical", ["DOT", "Bleed"],  True,   False,  False,      3,        2,         -1,         0),
	("Regen",  "Holy",     ["HOT", "Regen"],  False,  True,   False,      2,        3,         -1,         0),
	("Shield", "Holy",     ["Buff", "Shield"],False,  False,  True,       0,        3,         -1,        10),
]

# ─── Helpers ───────────────────────────────────────────────────────────────

def write_buff(name: str, damage_type: str, tags: list[str], is_dot: bool,
               is_hot: bool, is_shield: bool, base_mag: int, base_dur: int,
               max_stacks: int, shield_amt: int, overwrite: bool = False) -> Path:
	"""Render and write a single .tres file. Returns destination path."""
	OUT_DIR.mkdir(parents=True, exist_ok=True)
	fname = f"{name.lower()}.tres"
	dest = OUT_DIR / fname
	if dest.exists() and not overwrite:
		print(f"✘ {dest.relative_to(ROOT)} exists — skipping (use --force to overwrite)")
		return dest
	text = TEMPLATE.format(
		script_path=SCRIPT_PATH,
		name=name,
		tags=json.dumps(tags),
		damage_type=damage_type,
		is_dot=str(is_dot).lower(),
		is_hot=str(is_hot).lower(),
		is_shield=str(is_shield).lower(),
		base_mag=base_mag,
		base_dur=base_dur,
		max_stacks=max_stacks,
		shield_amt=shield_amt,
		icon_path="",
	)
	dest.write_text(text)
	print(f"✓ Wrote {dest.relative_to(ROOT)}")
	return dest

# ─── Main ──────────────────────────────────────────────────────────────────

def main(argv: list[str]) -> int:
	overwrite = "--force" in argv
	written = []
	for spec in BUFFS:
		p = write_buff(*spec, overwrite=overwrite)
		written.append(p)
	print("\nSummary:")
	for p in written:
		print("  ", p.relative_to(ROOT))
	print("\nNext:")
	print("  • Reload Godot or restart the editor")
	print("  • Run GUT: godot4 --headless -s addons/gut/cli/gut_cli.gd -gdir=res://scenes/tests")
	return 0

if __name__ == "__main__":
	sys.exit(main(sys.argv[1:]))
#EOF
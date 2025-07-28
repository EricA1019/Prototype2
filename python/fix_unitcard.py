#!/usr/bin/env python3
from pathlib import Path
import re
import textwrap

ROOT = Path(__file__).resolve().parents[1]

def p(*a): print("[fix-ui]", *a)

def replace_text(path: Path, repls: list[tuple[str,str]]):
    txt = path.read_text()
    orig = txt
    for a,b in repls:
        txt = txt.replace(a,b)
    if txt != orig:
        path.write_text(txt)
        p("patched", path.relative_to(ROOT))
        return True
    p("skip", path.relative_to(ROOT))
    return False

def ensure_unitcard_tscn():
    tscn = ROOT / "scenes/ui/UnitCard.tscn"
    if not tscn.exists():
        p("WARN: UnitCard.tscn not found")
        return
    # Write a compact, constrained card
    content = """
    [gd_scene load_steps=2 format=3]
    [ext_resource type="Script" path="res://scripts/ui/UnitCard.gd" id="1"]

    [node name="UnitCard" type="Panel"]
    script = ExtResource("1")
    layout_mode = 3
    anchors_preset = 1
    anchor_right = 0.0
    anchor_bottom = 0.0
    offset_left = 8.0
    offset_top = 8.0
    offset_right = 216.0
    offset_bottom = 88.0
    size_flags_horizontal = 0
    size_flags_vertical = 0
    custom_minimum_size = Vector2(208, 80)
    clip_contents = true

    [node name="HBox" type="HBoxContainer" parent="."]
    layout_mode = 2
    offset_left = 8.0
    offset_top = 8.0
    offset_right = 200.0
    offset_bottom = 72.0
    custom_minimum_size = Vector2(192, 64)
    theme_override_constants/separation = 8

    [node name="Portrait" type="TextureRect" parent="HBox"]
    layout_mode = 2
    custom_minimum_size = Vector2(64, 64)
    stretch_mode = 5

    [node name="Right" type="VBoxContainer" parent="HBox"]
    layout_mode = 2
    size_flags_horizontal = 3
    size_flags_vertical = 1
    theme_override_constants/separation = 4

    [node name="Name" type="Label" parent="Right"]
    layout_mode = 2
    text = "Detective"

    [node name="HP" type="ProgressBar" parent="Right"]
    layout_mode = 2
    min_value = 0.0
    max_value = 100.0
    value = 100.0
    """
    tscn.write_text(textwrap.dedent(content).lstrip())
    p("wrote compact UnitCard.tscn")

def patch_unitcard_gd():
    gd = ROOT / "scripts/ui/UnitCard.gd"
    if not gd.exists():
        p("WARN: UnitCard.gd not found")
        return
    txt = gd.read_text()
    # Ensure we respect 64px and fallback
    if "fallback_icon" not in txt:
        txt = (
            "@export var fallback_icon: Texture2D\n"
            + txt
        )
    if "_apply_portrait" not in txt:
        txt += """

func _apply_portrait(tex:Texture2D) -> void:
    var tr:TextureRect = %UnitCard.get_node("HBox/Portrait") if has_node("HBox/Portrait") else null
    if tr == null: return
    tr.texture = tex if tex != null else fallback_icon

"""
    # Try to make sure we keep aspect centered and min size
    if "Portrait" in txt:
        pass
    gd.write_text(txt)
    p("patched UnitCard.gd (added fallback_icon/_apply_portrait if missing)")

def point_detective_portrait_to_64():
    # Try to find a detective entity resource
    ent_dir = ROOT / "data" / "entities"
    if not ent_dir.exists():
        p("skip: no data/entities/")
        return
    for tres in ent_dir.glob("**/*.tres"):
        txt = tres.read_text()
        if "Detective" in txt or "detective" in tres.name.lower():
            new = re.sub(r'portrait_path\s*=\s*".*?"',
                         'portrait_path = "res://assets/portraits/detective_portrait_64.png"', txt)
            if new != txt:
                tres.write_text(new)
                p("patched portrait path -> 64px", tres.relative_to(ROOT))

def set_initbar_min_height():
    tscn = ROOT / "scenes" / "ui" / "InitiativeBar.tscn"
    if not tscn.exists():
        return
    txt = tscn.read_text()
    if "custom_minimum_size" in txt:
        p("skip InitiativeBar.tscn (min size present)")
        return
    txt = txt.replace('script = ExtResource("1")',
                      'script = ExtResource("1")\ncustom_minimum_size = Vector2(0, 64)')
    tscn.write_text(txt)
    p("patched InitiativeBar.tscn min height")

def main():
    ensure_unitcard_tscn()
    patch_unitcard_gd()
    point_detective_portrait_to_64()
    set_initbar_min_height()
    p("Done. Run and confirm the UnitCard sits top-left at ~200×80 and portrait 64×64.")

if __name__ == "__main__":
    main()

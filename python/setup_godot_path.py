#!/usr/bin/env python3
"""
Sets up a stable `godot4` command:

- Ensures Desktop binary exists and is executable
- Symlinks ~/.local/bin/godot4 -> /home/eric/Desktop/Godot_v4.5-beta3_linux.x86_64
- Adds ~/.local/bin to PATH (marked block) in common shell rc files
- Removes any previous marked block and comments out Godot-specific PATH lines

Run:
    python3 setup_godot_path.py
"""

from pathlib import Path
import re, shutil, time, os, stat

GODOT_BIN = Path("/home/eric/Desktop/Godot_v4.5-beta3_linux.x86_64")
LOCAL_BIN = Path.home() / ".local" / "bin"
SYMLINK   = LOCAL_BIN / "godot4"

RC_FILES = [
    Path.home() / ".profile",
    Path.home() / ".bashrc",
    Path.home() / ".bash_profile",
    Path.home() / ".zshrc",
]

BLOCK_START = "# >>> godot4 PATH setup >>>"
BLOCK_END   = "# <<< godot4 PATH setup <<<"
BLOCK_BODY  = f"""{BLOCK_START}
# Ensure user-local bin (where 'godot4' symlink lives) is on PATH
export PATH="$HOME/.local/bin:$PATH"
{BLOCK_END}
"""

GODOT_LINE_REGEX = re.compile(r"(?i)godot")  # lines mentioning 'godot' (any case)

def ensure_exec(p: Path):
    mode = p.stat().st_mode
    p.chmod(mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)

def setup_symlink():
    LOCAL_BIN.mkdir(parents=True, exist_ok=True)
    if SYMLINK.exists() or SYMLINK.is_symlink():
        try:
            SYMLINK.unlink()
        except Exception:
            # move aside if it's a regular file/dir
            SYMLINK.rename(SYMLINK.with_suffix(".old"))
    SYMLINK.symlink_to(GODOT_BIN)
    print(f"[OK] Symlink: {SYMLINK} -> {GODOT_BIN}")

def process_rc_file(rc: Path):
    if not rc.exists():
        # create an empty file so the block can be added
        rc.touch()
    ts = time.strftime("%Y%m%d-%H%M%S")
    backup = rc.with_suffix(rc.suffix + f".bak-{ts}")
    shutil.copy2(rc, backup)
    with rc.open("r", encoding="utf-8") as f:
        lines = f.readlines()

    new_lines = []
    in_block = False
    removed_block = False
    commented_godot_lines = 0

    for line in lines:
        # Remove our previous managed block entirely
        if line.strip().startswith(BLOCK_START):
            in_block = True
            removed_block = True
            continue
        if in_block:
            if line.strip().startswith(BLOCK_END):
                in_block = False
            continue

        # Comment out Godot-specific lines (leave general PATH lines alone)
        if GODOT_LINE_REGEX.search(line):
            if not line.lstrip().startswith("#"):
                new_lines.append("# [disabled by setup_godot_path] " + line)
                commented_godot_lines += 1
                continue

        new_lines.append(line)

    # Append our managed block if not present
    text = "".join(new_lines)
    if BLOCK_START not in text:
        if text and not text.endswith("\n"):
            text += "\n"
        text += BLOCK_BODY + ("\n" if not BLOCK_BODY.endswith("\n") else "")
    with rc.open("w", encoding="utf-8") as f:
        f.write(text)

    print(f"[OK] Updated {rc}  (backup: {backup.name})"
          f"  removed_block={removed_block}  commented_lines={commented_godot_lines}")

def main():
    if not GODOT_BIN.exists():
        print(f"[ERROR] Binary not found: {GODOT_BIN}")
        return 1
    ensure_exec(GODOT_BIN)
    print(f"[OK] Executable set: {GODOT_BIN}")

    setup_symlink()

    for rc in RC_FILES:
        process_rc_file(rc)

    print("\nNext steps:")
    print("  • Restart your terminal and VS Code, or run:")
    print("      source ~/.profile  ||  source ~/.bashrc  ||  source ~/.zshrc")
    print("  • Verify:")
    print("      which godot4")
    print("      godot4 --headless --version")
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
#EOF

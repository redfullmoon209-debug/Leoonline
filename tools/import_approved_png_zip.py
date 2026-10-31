#!/usr/bin/env python3
"""Install the ten existing, approved PNG files from a user-uploaded ZIP.
No PNG generation, recoloring, cropping, resampling, or SVG conversion.
Runs in GitHub Actions after the ZIP is uploaded to the repository root.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
from zipfile import ZipFile, BadZipFile

ROOT = Path(__file__).resolve().parents[1]
ZIP = ROOT / "Leoonline_Approved_PNG_Direct.zip"
PREFIX = "Leoonline_Approved_PNG_Direct/"
EXPECTED = {
    "luminous_blue_gold_fantasy_inventory_frame.png": "f6bd244134a10e6f039457a3b0ffe1aeffe95181a7fc2ee1579c864729d1eac2",
    "neon_winged_fantasy_equipment_slot.png": "93195fc06e83cbe4c9e2b29b77b7e2719090664db8a0b3eb294d2bd9b5990477",
    "ornate_blue_gold_action_bar.png": "2f26809f819951d1c19ba0b05f6ec2e6db4e040d4aefd5d7ec3bd449bd1a29bc",
    "ornate_blue_gold_inventory_panel_frame.png": "e89083f04508214dc4ccfa8f18877ef77f543bb0ec4b18bb5eb73818f44a7593",
    "ornate_blue_gold_inventory_ui_frame.png": "9cf8b7931db5a6a10039f38d49186ff75f66655ebc252d5bf262e10645b1c4b5",
    "ornate_fantasy_equipment_panel_template.png": "16c81395c45d0b385a6384d88b778af3bc73851336b12af15f5903da316d0b14",
    "ornate_four_row_currency_panel.png": "ede54dec8ef574f83537591517d3b183b6631f29635b7be90ea3d927f81618a4",
    "ornate_four_tab_fantasy_navigation_bar.png": "3288568cebc142ff74722159e60e654f851cd5c0e0dd067b7de083b786399988",
    "ornate_golden_crystal_inventory_slot.png": "0b5f80265180f583a67027f2c405069266ac43684b419fcbf3a37ac83f8504f1",
    "ornate_neon_locked_inventory_slot.png": "d69e094a57f1188c7005e4530464b9967324f89f91ad387c559defeedec8e725",
}


def main() -> None:
    if not (ROOT / "project.godot").exists():
        raise SystemExit("Godot project.godot missing")
    if not ZIP.is_file():
        raise SystemExit("Upload Leoonline_Approved_PNG_Direct.zip to repository ROOT first")
    if ZIP.stat().st_size > 25 * 1024 * 1024:
        raise SystemExit("Unexpected oversized inventory archive")
    try:
        with ZipFile(ZIP) as z:
            manifest = json.loads(z.read(PREFIX + "asset_manifest.json"))
            if set(manifest) != set(EXPECTED):
                raise SystemExit("Approved PNG manifest does not contain exactly ten approved files")
            blobs: dict[str, bytes] = {}
            for filename, digest in EXPECTED.items():
                archive_name = PREFIX + "assets/ui/approved/" + filename
                raw = z.read(archive_name)
                if not raw.startswith(b"\x89PNG\r\n\x1a\n"):
                    raise SystemExit("Invalid PNG: " + filename)
                actual = hashlib.sha256(raw).hexdigest()
                if actual != digest or manifest[filename]["sha256"] != digest:
                    raise SystemExit("Original approved image checksum mismatch: " + filename)
                blobs[filename] = raw
            script = z.read(PREFIX + "scripts/inventory_ui.gd")
            if not (script.startswith(b"extends PanelContainer\n")
                    and b"res://assets/ui/approved/" in script
                    and b"func _image_button(" in script):
                raise SystemExit("Approved inventory UI script mismatch")
            if len(script) > 100000:
                raise SystemExit("Unexpected inventory UI script size")
    except (BadZipFile, KeyError, ValueError) as exc:
        raise SystemExit("Cannot read approved archive: " + str(exc)) from exc
    output = ROOT / "assets/ui/approved"
    output.mkdir(parents=True, exist_ok=True)
    for filename, raw in blobs.items():
        (output / filename).write_bytes(raw)
        print("Installed original PNG:", filename, len(raw), hashlib.sha256(raw).hexdigest())
    (ROOT / "scripts/inventory_ui.gd").write_bytes(script)
    print("Installed approved Godot UI script, no PNGs were generated or cropped")


if __name__ == "__main__":
    main()

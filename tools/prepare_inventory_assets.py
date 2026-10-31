#!/usr/bin/env python3
"""Restore readable source, then generate each inventory PNG independently.

All PNGs originate from code-painted shapes. No reference screenshot is cropped.
This bootstrap exists so GitHub Actions can reconstruct the original UTF-8
generator and GDScript (including Thai labels) from checked-in compressed source.
"""
from pathlib import Path
import base64
import subprocess
import sys
import zlib

ROOT = Path(__file__).resolve().parents[1]
INPUTS = {
    "tools/generate_inventory_assets.py.zlib.b64": "tools/generate_inventory_assets.py",
    "scripts/inventory_ui.gd.zlib.b64": "scripts/inventory_ui.gd",
}
for source, destination in INPUTS.items():
    payload = (ROOT / source).read_text(encoding="ascii").strip()
    raw = zlib.decompress(base64.urlsafe_b64decode(payload))
    output = ROOT / destination
    output.parent.mkdir(parents=True, exist_ok=True)
    if not output.exists() or output.read_bytes() != raw:
        output.write_bytes(raw)
        print("Restored:", destination, len(raw), "bytes")
subprocess.run(
    [sys.executable, str(ROOT / "tools/generate_inventory_assets.py")],
    cwd=ROOT,
    check=True,
)

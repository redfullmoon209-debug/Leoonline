#!/usr/bin/env python3
"""Reconstruct the web-ready Bangkok GLB extracted from mapthai(1).blend.

Original mesh and UV layout are retained, duplicate authoring copies removed.
No Blender installation is needed at build time.
"""
from pathlib import Path
import gzip
import hashlib

ROOT = Path(__file__).resolve().parents[1]
PARTS = ROOT / "assets/maps/source_parts"
OUT = ROOT / "assets/maps/bangkok_map.glb"
SHA256_GZIP = "7d4f010056ad82448f97579d2f02d417a19528c0496f2e5ede986153dc859357"
SHA256_GLB = "18073962a384ddf511326f1bdc3fa0126d3b71606469a5462d26ce87585f7a1e"


def main():
    files = sorted(PARTS.glob("bangkok_map.glb.gz.part*"))
    if len(files) != 24:
        raise SystemExit(f"Expected 24 Bangkok map chunks, found {len(files)}")
    data = b"".join(p.read_bytes() for p in files)
    if hashlib.sha256(data).hexdigest() != SHA256_GZIP:
        raise SystemExit("Bangkok compressed map checksum failed")
    result = gzip.decompress(data)
    if hashlib.sha256(result).hexdigest() != SHA256_GLB:
        raise SystemExit("Bangkok GLB checksum failed")
    if result[:4] != b"glTF":
        raise SystemExit("Generated map is not glTF 2.0")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_bytes(result)
    print(f"Bangkok map ready: {len(result):,} bytes, original 73 unique city mesh nodes")


if __name__ == "__main__":
    main()

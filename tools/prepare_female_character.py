#!/usr/bin/env python3
"""Reassemble the exact user-uploaded FemaleLeo.fbx from versioned binary chunks.

The original source is a 14,005,040-byte Mixamo FBX with its own geometry and
two embedded textures. No assets from another game are substituted.
Split source chunks are in assets/characters/female/source_parts/ only because
this upload connector cannot attach a large binary as a single Git blob.
All bytes and the final SHA-256 are checked before Godot's import.
"""
from __future__ import annotations

import hashlib
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEST = ROOT / "assets" / "characters" / "female" / "FemaleLeo.fbx"
PARTS = ROOT / "assets" / "characters" / "female" / "source_parts"
SOURCE_SHA256 = "53fa7f6b2989b06fe71724b85f6cb0dc713c4a450c9ba97ce8e1b54cf1b17551"
SOURCE_SIZE = 14_005_040
PART_SIZE = 1_474_560
PART_COUNT = 10


def validate(path: Path) -> bool:
    if not path.is_file() or path.stat().st_size != SOURCE_SIZE:
        return False
    with path.open("rb") as fh:
        signature = fh.read(27)
    if not signature.startswith(b"Kaydara FBX Binary  "):
        return False
    digest = hashlib.sha256()
    with path.open("rb") as fh:
        for block in iter(lambda: fh.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest() == SOURCE_SHA256


def main() -> None:
    DEST.parent.mkdir(parents=True, exist_ok=True)
    if validate(DEST):
        print("FemaleLeo.fbx already matches uploaded original:", SOURCE_SHA256)
        return

    tmp_path = DEST.with_suffix(".fbx.tmp")
    try:
        with tmp_path.open("wb") as out:
            for i in range(PART_COUNT):
                part = PARTS / f"FemaleLeo.fbx.part{i:02d}"
                if not part.is_file():
                    raise FileNotFoundError(f"Missing original-model source part: {part}")
                data = part.read_bytes()
                expected = PART_SIZE if i < PART_COUNT - 1 else SOURCE_SIZE - PART_SIZE * (PART_COUNT - 1)
                if len(data) != expected:
                    raise ValueError(f"Corrupt FemaleLeo source part {i}: {len(data)} != {expected}")
                out.write(data)
        if not validate(tmp_path):
            raise RuntimeError("FemaleLeo.fbx SHA-256 mismatch; refusing to substitute a different model")
        os.replace(tmp_path, DEST)
    finally:
        if tmp_path.exists():
            tmp_path.unlink()

    print("FEMALELEO EXACT SOURCE VERIFIED:", DEST.as_posix(), SOURCE_SIZE, SOURCE_SHA256)


if __name__ == "__main__":
    main()

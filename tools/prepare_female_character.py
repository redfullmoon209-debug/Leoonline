#!/usr/bin/env python3
"""Import the user's existing Mixamo-rigged female model, with its PBR textures.

The former Female.glb from NexTgenLeo was a different Japanese/Bip001 rig
and could NOT use the uploaded Mixamo Run.fbx / Walking(8).fbx motions.
The happy-farm female is already owned by the same user and uses
mixamorig:Hips, LeftUpLeg, RightUpLeg, LeftArm, etc.
"""
from pathlib import Path
import struct
import urllib.request

SOURCE_COMMIT = "719fd1737335a9a1bfae85e2b77bb83c793ab8bd"
BASE = (
    "https://raw.githubusercontent.com/redfullmoon209-debug/"
    f"happy-farm/{SOURCE_COMMIT}/assets/characters/"
)
OUTPUT = Path("assets/characters/female")
FILES = {
    "femalefarmer.fbx": "Female.fbx",
    "female_color.png": "female_color.png",
    "female_metallic.png": "female_metallic.png",
    "female_normal.png": "female_normal.png",
    "female_roughness.png": "female_roughness.png",
}

def valid(name: str, data: bytes) -> bool:
    if name.endswith(".fbx"):
        return len(data) > 1_000_000 and data.startswith(b"Kaydara FBX Binary  ")
    return len(data) > 10_000 and data.startswith(b"\\x89PNG\\r\\n\\x1a\\n")

def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for source, target in FILES.items():
        dest = OUTPUT / target
        if dest.is_file() and valid(dest.name, dest.read_bytes()):
            print("Female source asset OK:", dest)
            continue
        req = urllib.request.Request(
            BASE + source, headers={"User-Agent": "Leoonline-Female-Mixamo-Importer"})
        with urllib.request.urlopen(req, timeout=90) as response:
            payload = response.read(40 * 1024 * 1024)
        if not valid(target, payload):
            raise RuntimeError("Invalid female source asset: " + source)
        dest.write_bytes(payload)
        print("Female Mixamo source ready:", dest, len(payload), "bytes")

if __name__ == "__main__":
    main()

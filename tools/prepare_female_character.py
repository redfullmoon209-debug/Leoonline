#!/usr/bin/env python3
"""Fetch the existing user-owned female GLB from the NexTgenLeo repository.
Run before importing Leoonline in Godot. Never generate/replace artwork.
The binary is not committed twice; the exact public source commit is pinned.
"""
from pathlib import Path
import struct
import urllib.request

SOURCE_COMMIT = "52dfb6dc7a2b1df411db093b0579d8f108e53c18"
URL = (
    "https://raw.githubusercontent.com/redfullmoon209-debug/"
    f"NexTgenLeo/{SOURCE_COMMIT}/assets/characters/female/Female.glb"
)
OUTPUT = Path("assets/characters/female/Female.glb")

def main():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    if OUTPUT.is_file() and valid_glb(OUTPUT.read_bytes()):
        print("Existing female GLB OK:", OUTPUT)
        return
    req = urllib.request.Request(URL, headers={"User-Agent": "Leoonline-Godot-Asset-Importer"})
    with urllib.request.urlopen(req, timeout=90) as response:
        data = response.read(20 * 1024 * 1024)
    if not valid_glb(data):
        raise RuntimeError("Downloaded female character is not a valid GLB v2")
    OUTPUT.write_bytes(data)
    print("Female model ready:", OUTPUT, len(data), "bytes")

def valid_glb(data: bytes):
    return (
        len(data) >= 1024 * 1024 and
        data[:4] == b"glTF" and
        struct.unpack_from("<I", data, 4)[0] == 2 and
        struct.unpack_from("<I", data, 8)[0] == len(data)
    )

if __name__ == "__main__":
    main()

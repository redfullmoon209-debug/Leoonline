#!/usr/bin/env python3
"""Draw 84 original, independent transparent skill PNGs (no cropping).

This is a reproducible source-art generator; each first-tier profession has
14 different compositions, colors and deterministic particle arrangements.
The three approved Novice PNGs are NEVER changed.
Only the image pixels are drawn: no button/background/frame/outline assets.
Uses only the Python standard library for Godot 4.4.1 GitHub runners.
"""
from __future__ import annotations

import hashlib
import math
import random
import struct
import zlib
from pathlib import Path

SIZE = 160
ART = Path(__file__).resolve().parents[1] / "assets" / "ui" / "skills"
ART.mkdir(parents=True, exist_ok=True)
PALETTES = {
    "earth_1": ((255, 135, 36), (255, 239, 161), (113, 47, 19)),
    "wind_1": ((132, 80, 251), (235, 212, 255), (47, 33, 159)),
    "water_1": ((24, 154, 255), (207, 249, 255), (4, 61, 168)),
    "fire_1": ((255, 66, 29), (255, 235, 158), (170, 25, 9)),
    "lightning_1": ((255, 191, 39), (251, 255, 218), (143, 71, 13)),
    "wood_1": ((43, 215, 107), (218, 255, 141), (12, 110, 55)),
}
EPS = 1e-7


def gauss(v: float, width: float) -> float:
    return math.exp(-((v / width) ** 2))


def mix(a: float, b: float, t: float) -> float:
    return a * (1 - t) + b * t


def clamp_byte(v: float) -> int:
    return max(0, min(255, int(v + 0.5)))


def motif(m: int, x: float, y: float, r: float, angle: float, s: float) -> float:
    """Distinct energetic silhouettes, none rendered with rectangle frames."""
    if m == 0:  # high-energy fist of light and clustered knuckles
        knuckles = max(
            gauss(math.hypot((x - xx) / 0.22, (y + 0.25) / 0.23), 1)
            for xx in (-0.37, -0.10, 0.17, 0.42)
        )
        palm = gauss(math.hypot((x + 0.02) / 0.47, (y - 0.01) / 0.43), 1.0)
        wrist = gauss(math.hypot((x + 0.03) / 0.26, (y - 0.49) / 0.34), 1)
        return max(knuckles * 0.97, palm * 0.88, wrist * 0.72)
    if m == 1:  # cutting crescent
        curve = math.hypot(x - 0.18, y + 0.06) - (0.59 + 0.10 * math.sin(angle * 2.0 + s))
        gate = max(0.0, min(1.0, 0.6 - 0.6 * (x + y) + 0.4))
        return gauss(curve, 0.088) * gate + 0.46 * gauss(y + x * 0.8 + 0.05, 0.15)
    if m == 2:  # erupting shards
        spike = max(0.0, math.cos(angle * 7.0 + 0.4 * s))
        return max(gauss(r, 0.30), gauss(r - spike * 0.82, 0.12) * (0.3 + spike * 0.72))
    if m == 3:  # radiant defensive crest
        body = max(abs(x) / max(0.09, 0.51 * (0.95 - 0.40 * max(0.0, y))), abs(y) / 0.78)
        shine = gauss(x, 0.14) * gauss(y + 0.05, 0.59)
        return max(0.83 * gauss(body, 1.2), shine * 0.83) if body <= 1.1 else 0.14 * gauss(body - 1.1, 0.2)
    if m == 4:  # diagonal dash
        path = gauss(y - 0.55 * x + 0.01, 0.13) * gauss(x, 0.83)
        companion = gauss(y - 0.55 * x - 0.28, 0.055) * gauss(x + 0.1, 0.75)
        return max(path, companion * 0.72, 0.65 * gauss(math.hypot(x + 0.35, y + 0.25), 0.22))
    if m == 5:  # explosion
        points = max(0.0, math.cos(angle * 9.0 + s))
        return max(gauss(r, 0.33), gauss(r - 0.18 - 0.62 * points, 0.12) * 0.84)
    if m == 6:  # magic cyclone
        swirl = gauss(math.sin(angle * 2.8 - r * 11.8 + s * 0.3), 0.25)
        return max(gauss(r - 0.55, 0.18) * swirl, 0.68 * gauss(r, 0.25))
    if m == 7:  # empowering ascent
        stem = gauss(x - 0.13 * math.sin(6.0 * y + s), 0.20) * gauss(y, 0.70)
        wings = gauss(abs(x) - 0.55 * max(0.08, y + 0.9), 0.14) * gauss(y + 0.26, 0.53)
        return max(stem, wings * 0.73)
    if m == 8:  # spear / energy beam
        main = gauss(y + 1.03 * x - 0.07, 0.10) * gauss(x, 0.88)
        tip = gauss(math.hypot(x - 0.42, y + 0.59), 0.19)
        return max(main, tip, 0.6 * gauss(y + 1.03 * x - 0.25, 0.09) * gauss(x, 0.70))
    if m == 9:  # spinning double slash
        curve1 = gauss(math.hypot(x + 0.2, y + 0.05) - 0.54, 0.07) * max(0.08, 0.65 - x * 0.35)
        curve2 = gauss(math.hypot(x - 0.2, y - 0.03) - 0.54, 0.06) * max(0.08, 0.65 + x * 0.35)
        return max(curve1, curve2, gauss(r, 0.23) * 0.65)
    if m == 10:  # restorative blooming magic
        lobes = max(0, math.cos(angle * 5.0 + s * 0.06))
        bloom = gauss(r - 0.44 * lobes, 0.24)
        return max(bloom * 0.90, gauss(r, 0.22))
    if m == 11:  # rune/power aura
        column = gauss(x, 0.25) * gauss(y, 0.68)
        halo = gauss(r - (0.57 + 0.08 * math.sin(angle * 5.0 + s)), 0.1)
        return max(column * 0.90, halo * 0.78, gauss(r, 0.14))
    if m == 12:  # binding tendrils
        a = gauss(y - 0.40 * math.sin(x * 7 + s * 0.31), 0.095) * gauss(x, 0.72)
        b = gauss(y + 0.39 * math.sin(x * 7 - s * 0.28), 0.085) * gauss(x, 0.72)
        return max(a, b, gauss(r, 0.19) * 0.60)
    # ultimate radial finisher
    blast = max(0, math.cos(angle * 12.0 - s * 0.13))
    return max(gauss(r, 0.43), 0.92 * gauss(r - blast * 0.88, 0.105),
               0.76 * gauss(y + x * 0.67, 0.13) * gauss(x, 0.77))


def elemental_glow(job: str, x: float, y: float, r: float, a: float, seed: int) -> float:
    if job == "earth_1":
        return gauss(r - 0.56 - 0.07 * math.cos(a * 6 + seed), 0.15) * (0.2 + 0.35 * max(0, math.cos(a * 5)))
    if job == "wind_1":
        return gauss(math.sin(a * 4.1 - r * 9.0 + seed * .12), 0.22) * gauss(r - 0.52, 0.22) * 0.45
    if job == "water_1":
        return gauss(y - 0.19 * math.sin(x * 8.5 + seed * .27), 0.11) * gauss(r - 0.49, 0.27) * 0.38
    if job == "fire_1":
        return gauss(x - .16 * math.sin(y * 13.0 + seed), .13) * gauss(y + .15, .65) * 0.30
    if job == "lightning_1":
        return gauss(y - .48 * math.sin(9.2 * x + seed * .24), 0.085) * gauss(x, .75) * .48
    return gauss(r - .42 - .15 * math.sin(a * 5 + seed * .19), .12) * .35


def chunk(tag: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def write_png(out: Path, pixels: bytearray) -> None:
    rows = b"".join(bytes([0]) + pixels[y * SIZE * 4:(y + 1) * SIZE * 4] for y in range(SIZE))
    png = bytes((137, 80, 78, 71, 13, 10, 26, 10))
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(rows, 9))
    png += chunk(b"IEND", b"")
    out.write_bytes(png)


def paint(job: str, index: int) -> bytearray:
    color, highlight, deep = PALETTES[job]
    seed = index * 37 + list(PALETTES).index(job) * 123
    rng = random.Random(seed)
    sparkle = [(rng.uniform(-0.83, 0.83), rng.uniform(-0.83, 0.83), rng.uniform(0.04, 0.09))
               for _ in range(8)]
    pixels = bytearray(SIZE * SIZE * 4)
    angle_shift = (index * .23) + (seed % 13) * .06
    for yy in range(SIZE):
        y = ((yy + 0.5) / SIZE - 0.5) * 2
        for xx in range(SIZE):
            x = ((xx + 0.5) / SIZE - 0.5) * 2
            # Keep transparent padding; none of the icons has a baked-in slot frame.
            rr = math.hypot(x, y)
            if rr > 1.15:
                continue
            ang = math.atan2(y, x)
            central = motif(index, x, y, rr, ang, angle_shift)
            elem = elemental_glow(job, x, y, rr, ang, seed)
            p = max((gauss(math.hypot(x - sx, y - sy), radius) * .95
                     for sx, sy, radius in sparkle), default=0.0)
            haze = .18 * gauss(rr, .80)
            energy = max(central, elem, p, haze)
            edge_fade = max(0.0, min(1.0, (1.15 - rr) * 5.5))
            alpha = max(0.0, min(1.0, (energy ** .75) * edge_fade))
            core = max(0.0, min(1.0, (central - .15) * 1.4 + p * .8))
            color_mix = max(0.0, min(1.0, .17 + .65 * (central + elem)))
            white_flash = core ** 2.1 * .72
            offset = (yy * SIZE + xx) * 4
            for channel in range(3):
                base = mix(deep[channel], color[channel], color_mix)
                lit = mix(base, highlight[channel], .34 + white_flash)
                pixels[offset + channel] = clamp_byte(lit)
            pixels[offset + 3] = clamp_byte(alpha * 255)
    return pixels


def main() -> None:
    hashes = set()
    for profession in PALETTES:
        for n in range(1, 15):
            target = ART / f"{profession}_{n:02d}.png"
            if not target.exists():
                write_png(target, paint(profession, n - 1))
            raw = target.read_bytes()
            assert raw.startswith(bytes((137, 80, 78, 71, 13, 10, 26, 10)))
            digest = hashlib.sha256(raw).hexdigest()
            if digest in hashes:
                raise ValueError(f"Repeated artwork detected: {target}")
            hashes.add(digest)
            print(f"Skill asset: {target.name} ({len(raw)} bytes)")
    assert len(hashes) == 84
    print("Validated 84 independent first-tier skill PNGs; no crops or shared frames.")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Build each LEOONLINE HUD PNG directly from its own original vector artwork.

Every PNG is rendered INDEPENDENTLY, from its SVG glyph with a newly authored
gold-and-oxblood frame. Nothing is sliced, sampled, cropped or extracted from
an AI mockup, combined sprite sheet, screenshot or another PNG.

Requires cairosvg (only for authoring/export, not for running the game).
"""
from __future__ import annotations

import re
from pathlib import Path
import cairosvg

ROOT = Path(__file__).resolve().parents[1]
ICONS = ROOT / "assets" / "ui" / "hud"
OUTPUT = ICONS / "premium"
ORDER = ("bag", "world", "party", "friends", "ranking",
         "settings", "guild", "quest", "mail", "events")
PALETTES = {
    "bag": ("#b7721c", "#281108", "#edaf45"),
    "world": ("#1d6e72", "#0b2331", "#4ee5ff"),
    "party": ("#315fa6", "#131c4a", "#73a7ff"),
    "friends": ("#7f416e", "#281229", "#ef9dd9"),
    "ranking": ("#9f7627", "#36200a", "#fff29e"),
    "settings": ("#2c618a", "#132a39", "#7fc8ff"),
    "guild": ("#942a2d", "#2e0b10", "#ef755d"),
    "quest": ("#886633", "#31220e", "#f9e3b3"),
    "mail": ("#594381", "#261532", "#d9c1ff"),
    "events": ("#66318e", "#231032", "#efabff"),
}
# Bag is original path art, authored for its own standalone PNG.
BAG_GLYPH = (
    '<path d="M13 24h38l-4 33H17z"/>'
    '<path d="M23 24v-8c0-7 4-10 9-10s9 3 9 10v8"/>'
    '<path d="M13 31h38M20 35h24v14H20z"/>'
    '<path d="M26 35v7c0 3 2 5 6 5s6-2 6-5v-7"/>'
    '<rect x="28" y="34" width="8" height="8" rx="1"/>'
)


def glyph_for(name: str) -> str:
    if name == "bag":
        return BAG_GLYPH
    source = (ICONS / (name + ".svg")).read_text(encoding="utf-8")
    match = re.search(r"<g\b[^>]*>(.*?)</g>", source, re.S)
    if match is None:
        raise ValueError(f"No original vector glyph for {name}")
    return match.group(1)


def svg_for(name: str) -> str:
    color, deep, spark = PALETTES[name]
    glyph = glyph_for(name)
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
    <defs>
      <linearGradient id="gold" x1="0" x2="1" y1="0" y2="1">
        <stop offset="0" stop-color="#fff8c9"/>
        <stop offset=".18" stop-color="#ffd67a"/>
        <stop offset=".42" stop-color="#9e5414"/>
        <stop offset=".68" stop-color="#efb951"/>
        <stop offset=".86" stop-color="#ffeb9d"/>
        <stop offset="1" stop-color="#7b3e0e"/>
      </linearGradient>
      <linearGradient id="bright" x1="0" y1="0" x2=".28" y2="1">
        <stop offset="0" stop-color="#fffbe6"/>
        <stop offset=".32" stop-color="#ffe392"/>
        <stop offset=".58" stop-color="#b97320"/>
        <stop offset="1" stop-color="#f9cd66"/>
      </linearGradient>
      <linearGradient id="shield" x1="0" y1="0" x2=".7" y2="1">
        <stop offset="0" stop-color="#491926"/>
        <stop offset=".48" stop-color="{deep}"/>
        <stop offset="1" stop-color="#17080e"/>
      </linearGradient>
      <radialGradient id="halo">
        <stop offset="0" stop-color="{color}" stop-opacity=".88"/>
        <stop offset=".63" stop-color="{color}" stop-opacity=".39"/>
        <stop offset="1" stop-color="#120409" stop-opacity="0"/>
      </radialGradient>
      <radialGradient id="jewel">
        <stop offset="0" stop-color="#ffffff"/>
        <stop offset=".26" stop-color="{spark}"/>
        <stop offset=".75" stop-color="#085c95"/>
        <stop offset="1" stop-color="#001a3e"/>
      </radialGradient>
      <filter id="soft" x="-40%" y="-40%" width="180%" height="180%">
        <feGaussianBlur stdDeviation="5"/>
      </filter>
    </defs>
    <!-- Transparent outer margin; the following is original SVG frame art. -->
    <ellipse cx="128" cy="226" rx="93" ry="15" fill="#000000" opacity=".38" filter="url(#soft)"/>
    <path d="M128 9 L202 34 L242 87 L238 163 L203 222 L128 248
             L53 222 L18 163 L14 87 L54 34 Z"
          fill="#080306" opacity=".47" transform="translate(0 4)"/>
    <path d="M128 8 L202 32 L244 87 L239 165 L202 226 L128 251
             L54 226 L17 165 L12 87 L54 32 Z"
          fill="url(#gold)" stroke="#7e3909" stroke-width="2"/>
    <path d="M128 17 L196 39 L233 92 L230 162 L195 217 L128 240
             L61 217 L26 162 L23 92 L60 39 Z"
          fill="#2c090f" stroke="#ffe7a1" stroke-width="2"/>
    <path d="M128 23 L192 45 L224 94 L222 159 L191 211 L128 233
             L65 211 L34 159 L32 94 L64 45 Z"
          fill="url(#shield)" stroke="#8b401a" stroke-width="3"/>
    <ellipse cx="128" cy="127" rx="88" ry="91" fill="url(#halo)"/>
    <circle cx="128" cy="127" r="76" fill="none" stroke="url(#gold)" stroke-width="3.5" opacity=".85"/>
    <circle cx="128" cy="127" r="69" fill="none" stroke="#fff5c6" stroke-width="1.5" opacity=".26"/>
    <!-- Engraved ornaments, gold corners and bevel highlights. -->
    <path d="M62 48 Q103 26 128 23 Q154 26 194 48" fill="none"
          stroke="#fff7cc" stroke-width="2" opacity=".71"/>
    <path d="M63 205 Q100 225 128 232 Q154 226 193 205" fill="none"
          stroke="#f8cf73" stroke-width="2" opacity=".70"/>
    <path d="M39 98l17-8-11 22M217 98l-17-8 11 22
             M40 158l17 7-10-22M216 158l-17 7 10-22"
          fill="url(#gold)" stroke="#8c4e18" stroke-width="1.5"/>
    <path d="M79 46l-7 11 12-4M177 46l7 11-12-4
             M79 210l-7-11 12 4M177 210l7-11-12 4"
          fill="#e6a64c" stroke="#fae3a3" stroke-width="1"/>
    <!-- Each icon is its own original vector illustration, not a crop. -->
    <g transform="translate(48,48) scale(2.5)" fill="none"
       stroke="#522a0b" stroke-width="5.0" stroke-linecap="round" stroke-linejoin="round" opacity=".95">
      {glyph}
    </g>
    <g transform="translate(48,48) scale(2.5)" fill="none"
       stroke="url(#bright)" stroke-width="3.45" stroke-linecap="round" stroke-linejoin="round">
      {glyph}
    </g>
    <!-- Two sapphire gems are ornamental, not red notification indicators. -->
    <path d="M128 11l13 14-13 13-13-13z" fill="url(#gold)" stroke="#fff6c4" stroke-width="1"/>
    <path d="M128 16l8 9-8 9-8-9z" fill="url(#jewel)" stroke="#8ceaff" stroke-width="1"/>
    <path d="M128 217l10 9-10 12-10-12z" fill="url(#gold)" stroke="#fff3a7" stroke-width="1"/>
    <path d="M128 220l6 6-6 8-6-8z" fill="url(#jewel)"/>
    <circle cx="52" cy="129" r="3" fill="#f8d981"/>
    <circle cx="204" cy="129" r="3" fill="#f8d981"/>
    </svg>'''


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name in ORDER:
        image = OUTPUT / f"{name}.png"
        # Unique SVG input for each item. No input image is cropped or edited.
        cairosvg.svg2png(bytestring=svg_for(name).encode("utf-8"),
                         write_to=str(image), output_width=256, output_height=256)
        data = image.read_bytes()
        if not data.startswith(b"\x89PNG\r\n\x1a\n"):
            raise RuntimeError(f"Invalid standalone PNG: {image}")
        print(f"Rendered native individual PNG {image.relative_to(ROOT)} ({len(data)} bytes)")
    # Receipt lists exactly the independently exported assets.
    assert len(list(OUTPUT.glob("*.png"))) == len(ORDER)


if __name__ == "__main__":
    main()

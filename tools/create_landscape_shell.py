#!/usr/bin/env python3
"""Generate a separate, playable landscape *test* entrypoint for LEOONLINE.

Production /index.html and /mobile.html remain the existing portrait game.
The same actual exported Godot game runs in a responsive 16:9 viewport on
desktop and edge-to-edge on landscape phones; this is not image scaling or
a screenshot. Browser orientation guidance is provided for portrait phones.
"""
from __future__ import annotations

import argparse
import html
import json
import re
from pathlib import Path

DOCUMENT = """<!doctype html>
<html lang="th">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <meta name="theme-color" content="#110a12">
  <meta name="color-scheme" content="dark">
  <meta name="description" content="Leoonline - playable landscape mode test">
  <title>LEOONLINE - ทดสอบแนวนอน</title>
  <style>
    :root { color-scheme: dark; }
    * { box-sizing: border-box; }
    html, body { width: 100%; height: 100%; margin: 0; padding: 0; overflow: hidden; }
    body {
      display: flex; align-items: center; justify-content: center;
      background:
        radial-gradient(ellipse 50% 70% at 50% 50%, #2a1523, transparent 80%),
        linear-gradient(145deg, #080a0e, #190912 52%, #05070b);
      font-family: system-ui, -apple-system, "Noto Sans Thai", sans-serif;
      overscroll-behavior: none;
    }
    .test-header {
      position: fixed; top: 12px; left: 18px; right: 18px;
      display: flex; justify-content: center; align-items: center; gap: 16px;
      color: #f4d391; font-size: 13px; font-weight: 600;
    }
    .test-header .test-badge {
      padding: 5px 11px; border: 1px solid #bb8640;
      border-radius: 20px; background: #260d1b; letter-spacing: .07em;
    }
    .test-header a {
      color: #ffdb9d; text-decoration: none;
      border-bottom: 1px solid #c08d47; padding-bottom: 2px;
    }
    #landscape-shell {
      position: relative; flex: none; overflow: hidden;
      width: min(1180px, calc(100vw - 36px), calc((100vh - 90px) * 16 / 9));
      width: min(1180px, calc(100vw - 36px), calc((100dvh - 90px) * 16 / 9));
      aspect-ratio: 16 / 9;
      background: #090a0c;
      border: 5px solid #35232a; border-radius: 23px;
      box-shadow: 0 0 0 1px #b88b4f, 0 0 0 4px #100a11,
                  0 20px 75px #000b;
    }
    #game-frame {
      display: block; width: 100%; height: 100%;
      border: 0; margin: 0; padding: 0;
      background: #0c0a0e; border-radius: 17px; touch-action: auto;
    }
    #rotate-prompt {
      display: none;
      position: fixed; inset: 0;
      align-items: center; justify-content: center;
      flex-direction: column; gap: 12px;
      padding: 24px; text-align: center; z-index: 5;
      background: #150915;
      color: #f2d5a0;
    }
    #rotate-prompt strong { font-size: 22px; }
    #rotate-prompt .rotate-symbol { font-size: 58px; line-height: 1.2; }
    #rotate-prompt a { color: #ffd98f; margin-top: 12px; }
    /* On a real horizontal phone, Godot occupies the actual whole
       browser viewport, with no simulated phone borders or crop. */
    @media (max-width: 1000px) and (orientation: landscape) {
      #landscape-shell {
        width: 100vw; height: 100vh; height: 100dvh;
        max-width: none; aspect-ratio: auto;
        border: 0; border-radius: 0; box-shadow: none;
      }
      #game-frame { border-radius: 0; }
      .test-header { display: none; }
    }
    /* Rotating the phone is the only action required. No forced
       screen-orientation lock permissions, no fictional rotate behavior. */
    @media (max-width: 700px) and (orientation: portrait) {
      #landscape-shell { display: none; }
      .test-header { display: none; }
      #rotate-prompt { display: flex; }
    }
  </style>
</head>
<body>
  <header class="test-header" role="note">
    <span>LEOONLINE</span><span class="test-badge">LANDSCAPE TEST</span>
    <a href="mobile.html" title="กลับหน้าเกมแนวตั้ง">กลับแนวตั้ง</a>
  </header>
  <main id="landscape-shell" aria-label="Leoonline landscape playtest">
    <iframe id="game-frame" title="Leoonline แนวนอนรุ่นทดสอบ"
            src="__GAME_FILE__?mobile_ui=1" allow="autoplay; fullscreen"
            allowfullscreen scrolling="no"></iframe>
  </main>
  <section id="rotate-prompt" aria-live="polite">
    <span class="rotate-symbol" aria-hidden="true">↻</span>
    <strong>หมุนโทรศัพท์เป็นแนวนอน</strong>
    <span>Leoonline รุ่นทดสอบแนวนอน จะแสดงเกมเต็มจอเมื่อหมุนเครื่อง</span>
    <a href="mobile.html">กลับไปเล่นแบบแนวตั้ง</a>
  </section>
</body>
</html>
"""


def build(web: Path, game: str, output: str, publish: bool) -> None:
    web = web.resolve()
    if Path(game).name != game or not (
        game == "_qa.html" or re.fullmatch(r"game-[a-f0-9]{12}\.html", game)
    ):
        raise ValueError("Invalid Godot entrypoint filename")
    if Path(output).name != output or not re.fullmatch(r"[\w-]+\.html", output):
        raise ValueError("Invalid landscape output filename")
    if not (web / game).is_file():
        raise FileNotFoundError(web / game)
    content = DOCUMENT.replace("__GAME_FILE__", html.escape(game, quote=True))
    assert 'id="landscape-shell"' in content
    assert 'mobile_ui=1' in content
    (web / output).write_text(content, encoding="utf-8")
    if publish:
        if game == "_qa.html":
            raise ValueError("QA cannot be published")
        # Do not alter index.html, mobile.html or the real game-<sha>.html.
        (web / "landscape.html").write_text(content, encoding="utf-8")
        (web / "landscape-test.html").write_text(content, encoding="utf-8")
        existing_info = web / "build-info.json"
        if existing_info.is_file():
            info = json.loads(existing_info.read_text(encoding="utf-8"))
            info["landscape_test_entrypoint"] = output
            info["landscape_test_alias"] = "landscape.html"
            existing_info.write_text(
                json.dumps(info, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
    print("Created landscape-only playtest:", output, "=>", game)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--web", type=Path, required=True)
    parser.add_argument("--game", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--publish", action="store_true")
    args = parser.parse_args()
    build(args.web, args.game, args.output, args.publish)


if __name__ == "__main__":
    main()

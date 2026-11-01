#!/usr/bin/env python3
"""Publish a genuine phone-portrait Godot Web viewport, not a scaled screenshot.

The release's *existing* game-<sha>.html remains a usable fullscreen Godot
export. The mobile-first HTML page loads it in a same-origin, responsive
iframe so Godot's Adaptive canvas policy sees a REAL portrait-sized browser
viewport. Desktop visitors see a centered portrait device; phone visitors
see an edge-to-edge screen. The iframe's dimensions (and all UI touches)
are real, rather than stretching a widescreen image.
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
  <meta name="theme-color" content="#100811">
  <meta name="color-scheme" content="dark">
  <meta name="description" content="Leoonline - mobile portrait game">
  <title>Leoonline — จอมือถือ</title>
  <style>
    :root { color-scheme: dark; }
    * { box-sizing: border-box; }
    html, body {
      width: 100%; height: 100%; margin: 0; padding: 0; overflow: hidden;
    }
    body {
      display: flex; align-items: center; justify-content: center;
      background:
        radial-gradient(ellipse 38% 54% at 50% 52%, #261322 0%, transparent 86%),
        linear-gradient(145deg, #08090c 0%, #160912 48%, #06070a 100%);
      overscroll-behavior: none;
    }
    /* The actual live game runs inside this 9:19.5 portrait viewport.
       All touch/click/keyboard events and 3D rendering are delivered to Godot. */
    #phone-shell {
      position: relative; flex: none;
      width: auto;
      height: min(900px, calc(100vh - 18px));
      height: min(900px, calc(100dvh - 18px));
      aspect-ratio: 9 / 19.5;
      max-width: calc(100vw - 12px);
      overflow: hidden;
      border: 5px solid #292027;
      border-radius: 32px;
      background: #0c0710;
      box-shadow:
        0 0 0 1px #a77636,
        0 0 0 3px #0d070d,
        0 18px 75px #000b;
    }
    #game-frame {
      display: block; width: 100%; height: 100%;
      margin: 0; padding: 0; border: 0;
      border-radius: 25px;
      background: #0c0710;
      touch-action: auto;
    }
    /* A real phone uses the whole available screen: no fake bezel,
       borders, letterboxing, horizontal scrollbar or cropped HUD. */
    @media (max-width: 600px) {
      #phone-shell {
        width: 100vw; height: 100vh; height: 100dvh;
        max-width: none; aspect-ratio: auto;
        border: 0; border-radius: 0; box-shadow: none;
      }
      #game-frame { border-radius: 0; }
    }
    @media (prefers-reduced-motion: reduce) {
      *, *::before, *::after { animation: none !important; transition: none !important; }
    }
  </style>
</head>
<body>
  <main id="phone-shell" aria-label="Leoonline mobile game viewport">
    <iframe id="game-frame" title="Leoonline - เล่นเกมในจอมือถือ"
            src="__GAME_FILE__" allow="autoplay; fullscreen"
            allowfullscreen scrolling="no"></iframe>
  </main>
</body>
</html>
"""


def build(web: Path, game_file: str, output: str, publish: bool) -> None:
    web = web.resolve()
    # Reject path traversal in a build pipeline with privileged upload access.
    if Path(game_file).name != game_file or not (
        re.fullmatch(r"game-[a-f0-9]{12}\.html", game_file) or game_file == "_qa.html"
    ):
        raise ValueError("Expected a commit-specific game-<sha>.html or _qa.html")
    if Path(output).name != output or not output.endswith(".html"):
        raise ValueError("Output must be a relative HTML filename")
    game_path = web / game_file
    if not game_path.is_file():
        raise FileNotFoundError(game_path)
    content = DOCUMENT.replace("__GAME_FILE__", html.escape(game_file, quote=True))
    (web / output).write_text(content, encoding="utf-8")
    if publish:
        if game_file == "_qa.html":
            raise ValueError("Never publish the QA page")
        (web / "index.html").write_text(content, encoding="utf-8")
        (web / "mobile.html").write_text(content, encoding="utf-8")
        commit = game_file[len("game-"):-len(".html")]
        data = {
            "version": commit,
            "entrypoint": output,
            "game_entrypoint": game_file,
            "display": "mobile-portrait",
        }
        (web / "build-info.json").write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        print("Published portrait default index.html, mobile.html and", output)
    else:
        print("Created phone-mode HTML:", output, "->", game_file)
    assert 'id="phone-shell"' in content and 'id="game-frame"' in content


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

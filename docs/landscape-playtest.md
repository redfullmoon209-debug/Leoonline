# LEOONLINE — Landscape test (separate from the portrait game)

**Portrait remains the default release.** The browser homepage `/Leoonline/`
and `/Leoonline/mobile.html` still open the original mobile-portrait
Godot game and do not change.

The new optional **landscape TEST** has these entrypoints:

- Stable test link: https://redfullmoon209-debug.github.io/Leoonline/landscape.html
- Alternative: `/Leoonline/landscape-test.html`
- Cache-independent release: `/Leoonline/landscape-<first-12-commit-characters>.html`
- The original unwrapped Godot export is still `game-<commit>.html`.

## Display and controls

- **Desktop:** the real Godot game appears inside a centered 16:9 landscape
  viewport, with a clear LANDSCAPE TEST label and a link back to portrait.
- **Phone held horizontally:** the real game fills the available landscape
  browser viewport edge-to-edge, no fake bezel, cropping or screenshot.
- **Phone held vertically:** a short message says to rotate the device, and
  offers a link back to the main portrait game.
- A standalone live Godot iframe renders the game at its **actual viewport
  size**. This is not a stretched CSS image; mouse and touch go straight to
  Godot.
- The landscape URL adds `?mobile_ui=1` to enable **real joystick, Jump,
  Pickup and Run controls even for a desktop mouse**. Normal desktop
  camera-mouse capture is disabled only when this testing flag is present.
- The approved 10 PNG menu icons, minimap, character panel, target status,
  inventory, storage, banking and drag/resize settings are reused unchanged.

## Saves

**Portrait and landscape are two views of the same prototype, not two
different user accounts.** Both run under the same GitHub Pages origin and
share existing local browser save data, including inventory and HUD layouts.
Test actions can therefore affect saved progress in the portrait version.

## Automated verification

The PR and production deploy jobs run Godot 4.4.1 headless smoke QA,
the full desktop/mobile inventory/regression suite, portrait-wrapper browser
QA, and a **new real Chromium landscape QA**:
`tools/test_landscape_shell.cjs`. It opens the game at both desktop
1440×900 (centered 16:9 test) and mobile landscape 844×390, checks the
responsive canvas, original ten buttons and mobile touch controls, taps the
real Inventory button, and verifies portrait-phone rotation guidance.

`tools/create_landscape_shell.py` produces both the stable test page and
the commit-versioned test page without touching the portrait homepage or
the Godot Web export.

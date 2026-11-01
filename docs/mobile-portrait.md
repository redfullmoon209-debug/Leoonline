# Leoonline — Default Mobile Portrait Web Presentation

## Player experience

When a player opens the normal GitHub Pages homepage **on a desktop
computer**, the actual Godot 4.4.1 game is displayed as a centered
**9:19.5 portrait phone viewport**, with dark space to the left and right
instead of filling a widescreen monitor.

When opened on an actual phone browser with a narrow display, the gameplay
fills the mobile browser screen edge-to-edge. Rotate the device to portrait
for the intended 10-icon HUD, minimap, character card and touch controls.

This is **not a screenshot and not a CSS-scaled or cropped widescreen game**.
The page loads the real Godot Web export in a same-origin iframe that is
sized like a phone. Its exported adaptive canvas policy sees that iframe as
the true browser viewport and renders 3D, inventory, HUD, and input in the
correct mobile geometry.

- Default homepage: https://redfullmoon209-debug.github.io/Leoonline/
- Stable portrait alias: /Leoonline/mobile.html
- Commit-specific portrait page: /Leoonline/phone-COMMIT12.html
- Commit-specific untouched landscape/full-browser Godot release:
  /Leoonline/game-COMMIT12.html

## Controls and saved state

The portrait view shows the exact same ten individually authored menu PNGs,
real character card, target info and circular minimap, as well as the actual
joystick, Jump, Pick Up and Run buttons — **even when the narrow phone
viewport is being previewed with a desktop mouse**. Physical phone touch
input works normally. Keyboard controls remain usable on PC after focusing
the inner game. The mouse remains visible in phone mode so users can tap
the virtual joystick, rather than being automatically captured for camera
movement.

The phone wrapper and the original export share the exact same website
origin. Character and inventory saves, bank currencies, storage, and the
editable HUD layout remain in the existing browser localStorage/user save,
unchanged. No separate account, screenshot, image-generation asset,
reupload or game restart process is needed.

## Build and regression checks

- tools/create_mobile_shell.py creates a responsive phone frame and the
  default /index.html **after** the existing native Godot QA completes
- tools/test_phone_shell.cjs opens the release's actual Godot canvas inside
  that portrait frame in Chromium at 1440×900 (desktop) and 390×844
  (touch phone), checking true game canvas dimensions, the 10 menu controls,
  player card, target/minimap, mobile joystick, and a live Inventory tap
- Existing desktop and mobile inventory, banking, storage and HUD regression
  suites are retained unchanged
- .github/workflows/publish-pages.yml publishes versioned phone and
  original Godot pages together; normal homepage now points to the phone
  presentation
- .github/workflows/hud-browser-check.yml exercises the real portrait
  shell in PR validation prior to merging

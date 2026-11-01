# Leoonline — Separate HUD Icons and Editable Touch Layout

## Main HUD

There are **nine separate icons on the playable game screen**, not hidden
under Inventory:

| Icon | Real behavior in prototype |
| --- | --- |
| แผนที่โลก | Live playable test-world map, actual player coordinates and loot, zoom controls |
| ปาร์ตี้ | Create/dissolve a local one-player party; online invites are explicitly unavailable |
| เพื่อน | Add and delete locally saved friend names; no fabricated online status |
| อันดับผู้เล่น | Live current-character stats; no fabricated global leaderboard |
| ตั้งค่าเกม | HUD touch editor, camera sensitivity, language, show labels, touch visibility |
| กิลด์ | Create or remove a locally saved guild-name draft; no false online membership |
| เควสต์ | Collect 3 actual loot drops and claim a one-time 50-gold local reward |
| จดหมาย | Claim the one-time real welcome potion into the Inventory |
| กิจกรรม | Claim a real 20-gold reward once per local device date, not server-authoritative |

The original Inventory icon is retained outside those nine and works with B.
Each new icon is an individually authored SVG vector, not a cropped image or
a screenshot. Controls use the original matte-crimson-and-gold theme with
nine-sliced button sprites.

## Mobile gameplay controls

On touchscreen devices the HUD also shows an interactive vector joystick
connected to real character movement and separate Jump, Pick Up, and Run
buttons. They are absent on desktop by default but may be shown in Settings
for layout editing. Keyboard WASD/arrows, Space, Shift, E and B remain.

## Drag, resize and save all HUD buttons

1. Open ตั้งค่าเกม → เริ่มจัดปุ่มบนหน้าจอ.
2. Tap/click a HUD icon, the original Inventory icon, the movement joystick,
   or a mobile gameplay button to select it.
3. Drag that control with your finger or mouse.
4. Adjust its size with the slider. Icons support 42–100px; joystick 90–195px.
5. Tap the editor's ย้ายแถบเครื่องมือขึ้น / ลง button to move the toolbar
   between the top and bottom edges, exposing controls underneath it.
6. Press บันทึก to save, ยกเลิก to cancel the session, or ค่าเดิม to reset it.
7. Settings also includes the restore-defaults action outside the editor.

Positions are saved in normalized screen coordinates, clamped on resize so
controls do not become inaccessible. User preferences are separate from the
real inventory save: user://leoonline_hud.json and Web localStorage
leoonline_hud_v1. Browser reload preserves layouts.

## Online limitations

This is currently a local prototype, not an authoritative multiplayer server.
Online invites, true guild membership, friends' online presence and global
rankings are unavailable. The menus explicitly disclose this instead of
displaying fictional live users, ranks, or network success.

## Source and checks

- scripts/hud_menu.gd — nine HUD icons, menu panels, editor and persistence
- scripts/hud_world_map.gd — vector test-level map
- scripts/hud_joystick.gd — interactive movement joystick
- scripts/main.gd — player movement and pickup integration
- scripts/smoke_test.gd — Godot 4.4.1 logic and UI tests
- scripts/web_ui_probe.gd — browser instrumentation
- tools/test_web_inventory.cjs — Chromium mouse and touch input QA
- .github/workflows/hud-browser-check.yml — isolated browser validation

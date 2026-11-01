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

The original Inventory button is preserved as the first of **ten compact
icons in exactly one horizontal row** (Inventory, Map, Party, Friends, Ranking,
Settings, Guild, Quests, Mail, Events). The menu row fits between a **live
character status panel in the top-left corner** and a **clickable circular
minimap at top-right** on PC. On a narrow phone, character and minimap occupy
the first line, the ten smaller icons share a separate second line, and the
honest target-info panel remains centered just below them. No icon wraps into
multiple rows or overlaps the minimap.

The ten **standalone transparent 256x256 PNG files** are in
assets/ui/hud/premium/. Every PNG is individually rendered from its OWN
original SVG illustration and an independently authored ornamental frame.
The reproducible authoring source is tools/build_premium_hud_png.py. Nothing
is cropped from the approved mockup, another PNG, screenshot or a sprite
sheet. Text labels and number/order belong to Godot controls, not baked
into the PNGs. The original B keyboard shortcut still opens Inventory.

The **center target panel** shows "no selected target" until the actual
targeting system provides a target. When a valid target Node3D is supplied
via hud_menu.set_target(node), its real name, level and HP metadata are
displayed; missing health is NEVER invented. The character corner shows
real saved name, level, class and EXP. The circular minimap shows the actual
position and dropped items of the current playable Godot test scene,
not a fake online world map.

## Event-only red notification indicators

- **Every one of the ten premium PNGs, including Mail, is permanently free
  from baked-in red-dot decorations.** Blue gems on frames are purely art.
- A separate Godot UI notification layer is created for each of the ten
  controls, **hidden by default**.
- An actual incoming friend request calls
  hud_menu.receive_friend_request(sender_id) and adds a red badge to
  **Friends ONLY**; an actual incoming mail event calls
  hud_menu.receive_mail_notification(message_id) and marks **Mail ONLY**.
  hud_menu.set_notification_count(menu_id, count) is available for other
  verified events and acknowledge_notifications(menu_id) clears a badge.
- No online server exists yet, so **no automatic friend/mail alerts are
  fabricated** by this browser prototype; the event hooks are ready for
  a future authenticated social service.


## Mobile gameplay controls

On touchscreen devices the HUD also shows an interactive vector joystick
connected to real character movement and separate Jump, Pick Up, Run and
**TARGET** buttons. TARGET is a separately authored SVG touch control above
Jump, not an eleventh top-row menu PNG and never cropped from artwork. Tap
TARGET once to lock the real training golem and show its live HP/MP in the
top-center card; tap it again to clear the lock and hide those bars. Touching
other real test monsters/players directly in the 3D world also selects their
individual portraits and live values. All five mobile gameplay controls can
be moved and resized in Settings. They are absent on desktop by default but
may be shown for layout editing. Keyboard WASD/arrows, Space, Shift, E, B
and T (target toggle) remain.

## Drag, resize and save all HUD buttons

1. Open ตั้งค่าเกม → เริ่มจัดปุ่มบนหน้าจอ.
2. Tap/click a HUD icon, the original Inventory icon, the movement joystick,
   or a mobile gameplay button to select it.
3. Drag that control with your finger or mouse.
4. Adjust its size with the slider. Top menu icons support a responsive minimum of 27px on narrow phones (30px in landscape) up to 100px; mobile action buttons support 42–100px and the joystick 90–195px.
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
- assets/ui/hud/premium/*.png — ten independently rendered gold/crimson PNGs
- tools/build_premium_hud_png.py — reproducible original vector-to-PNG authoring
- scripts/hud_top_status.gd — saved character profile, live minimap and target
- scripts/hud_minimap.gd — real circular local world projection
- scripts/hud_world_map.gd — vector test-level map
- scripts/hud_joystick.gd — interactive movement joystick
- scripts/main.gd — player movement and pickup integration
- scripts/smoke_test.gd — Godot 4.4.1 logic and UI tests
- scripts/web_ui_probe.gd — browser instrumentation
- tools/test_web_inventory.cjs — Chromium mouse and touch input QA
- .github/workflows/hud-browser-check.yml — isolated browser validation

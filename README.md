# Leoonline
Private, proprietary Godot 4.4.1 game prototype.

## Status
Playable Godot 4.4.1 prototype with GitHub Pages portrait and landscape tests. Not a networked MMORPG yet.

## Controls
WASD to move, Shift to sprint, Space to jump, E to pick up nearby loot, B to open/close bag, mouse to look.

## Inventory
200 slots (40 initially unlocked, 10 unlocked per five active hours, or a Bag +10 Scroll), sorting weapons then armor then other items, equipment slots, item trash confirmation, and 4 separate exact-decimal currency balances capped at 999999999999999999999 each. Saved locally in user://leoonline.json.

## Legal
All Rights Reserved for original source materials belonging to their respective copyright holder(s). No open-source license granted. Godot engine, editor, and third-party dependencies remain governed by their separate licenses.

## Next steps
Add genuine modular character FBX, animation, approved layered inventory PNG assets, gameplay systems, and networking. This build currently renders a functional navy-blue UI with native Godot widgets, not the approved 32-layer PNG art.


## FemaleLeo character (user-supplied original)

The female test player uses the **exact** original `FemaleLeo.fbx` uploaded by the project owner on 2026-11-02 (14,005,040 bytes, SHA-256 `53fa7f6b2989b06fe71724b85f6cb0dc713c4a450c9ba97ce8e1b54cf1b17551`). It contains the authored mesh, Mixamo bones, and embedded color/normal textures; it is **not** the old happy-farm/NexTgenLeo model.

To assemble its exact bytes from the repository's source parts before opening this checkout in Godot:

```sh
python3 tools/prepare_female_character.py
```

The GitHub Actions web/export workflows do this automatically and verify the hash before import. In the landscape playtest, GM can switch between the genuine FemaleLeo mesh and the original debug capsule without changing collision, inventory, movement, or HUD. Walk and run use the separately supplied Mixamo animation tracks; normal WASD/joystick movement walks and Shift/Run sprints.

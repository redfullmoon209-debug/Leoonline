# LEOM — Unity 3D MMORPG migration foundation

This is a **separate Unity LEOM project** living in the existing Godot repository. The original root-level Godot 4.4.1 Leoonline project, GitHub Pages playtests, scripts, and assets are intentionally untouched.

## Current implementation (local vertical slice, NOT online)
- Unity 6.3 LTS project skeleton (starting Editor version 6000.3.0f1).
- Editor command that builds a playable 3D prototype scene from Unity primitives.
- Third-person WASD movement, sprint, jump, rotating follow camera, left-click melee.
- Prototype monsters with chase, damage, death, respawn, EXP, local gold rewards, and item drops.
- E to collect nearby drops, B for a debug inventory, F5 for local save.
- 200 inventory slots / 40 initially unlocked; local four-currency exact decimal-string storage, 21 digits max per currency.
- Design documents for authoritative multiplayer, open PK, arena, guild wars, and migration.

**Not yet implemented:** network connection, online accounts, shared multiplayer, real PvP, arena, guild server, item upgrade economy, authoritative persistence, final HUD, original FBX/PNG imports, actual world map. Demo combat and local saves are non-authoritative and MUST NOT be deployed as an MMORPG server.

## Open and play
1. Install **Unity Hub** and **Unity Editor 6.3 LTS** (install the most recent 6.3 patch available; project baseline is 6000.3.0f1).
2. Clone the GitHub repository and check out branch **unity-mmorpg-foundation**.
3. In Unity Hub select **Add project from disk**, and choose the **unity/** folder (not the repository root).
4. Wait for Unity to import scripts. The prototype uses the built-in render pipeline and legacy Input Manager, so no external marketplace assets are needed.
5. In Unity choose **Tools > LEOM > Build Prototype Scene**. This creates Assets/LEOM/Scenes/Prototype.unity and makes it the first build scene.
6. Open the generated scene if needed and press Play.

If input is disabled, open **Edit > Project Settings > Player > Other Settings > Active Input Handling** and choose **Input Manager (Old)** or **Both**; restart Editor if prompted.

## Prototype controls
- WASD move / Shift sprint / Space jump
- Mouse move orbit camera / Left-click melee attack (nearby monsters, facing them)
- E loot nearest drop in range / B toggle inventory / F5 save
- Press Play to reset scene. Profile and inventory persist locally in Application.persistentDataPath/leoonline-unity-prototype.json.

## Layout
- Assets/LEOM/Scripts/Runtime/Prototype — offline gameplay proof of concept
- Assets/LEOM/Scripts/Runtime/Shared — exact-decimal currency and PvP zone rule contracts
- Assets/LEOM/Scripts/Editor — scene creation tool (Editor only)
- Assets/LEOM/Scenes — generated once with Tools > LEOM
- Docs — design, roadmap, migration, server authority contracts

## Migration boundaries
The Godot root stores the original 3D assets and GDScript, and is the source of truth for existing prototype behavior. Do not automatically overwrite it, delete originals, or assume Godot local save files can be read directly as Unity saves. See Docs/GODOT_MAPPING.md.

## Security warning
The local demo calculates drops/EXP/HP for convenience. In multiplayer, **only the dedicated server** may grant EXP, spawn owned loot, change balances or inventory, accept damage, authorize PK, or decide guild/arena match outcomes. Do not connect these local demonstration scripts directly to client-submitted networking RPCs.

## Test directly through the browser
A separate cloud GitHub Actions workflow is prepared to build Unity WebGL and host it at
https://redfullmoon209-debug.github.io/Leoonline/unity/
without changing the existing Godot home page. The URL is **not valid as a Unity build until CI + Pages deployment succeeds**. See [Docs/BROWSER_TEST.md](Docs/BROWSER_TEST.md) for Unity licensing prerequisite and deployment details.

# LEOM — Unity 3D MMORPG migration foundation

This is a **separate Unity LEOM project** living in the existing Godot repository. The original root-level Godot 4.4.1 Leoonline project, GitHub Pages playtests, scripts, and assets are intentionally untouched.

## Current implementation (local vertical slice, NOT online)

**LEOM now ports the Godot data/systems into Unity, rather than being just the initial capsule test.** See [Docs/PORT_STATUS.md](Docs/PORT_STATUS.md) for the implemented/missing matrix.

- Godot source catalogs migrated without renaming IDs: 31 items, 21 NPC shop listings, 13 professions, 171 named skills.
- Unity-local bag 200/40 unlocked, 200-slot warehouse, deposit/withdraw items and exact four-currency vault, sorting, equipment and consumables.
- Shop buy/sell and item confirmation, level/EXP/stat/skill points, passives and timed buffs; many class attacks remain catalog-only.
- Unity procedural humanoid character and island map with town/hunting/arena/guild landmarks. **No original FemaleLeo, Bangkok map GLB, or their source parts imported.**
- Mobile touch buttons and temporary RPG debug UI (bag/shop/bank/gear/stats/skills/map/PvP info). PvP and social screens are NOT networked implementations.
- Automatic farming test movement (Q), basic attack, Novice Slash/Rush/Guard, monster loot and local profile persistence.
- Check migrated source with `python3 tools/verify_leom_migration.py` and `dotnet run --project tools/leom-tests/LeomCoreTests.csproj`.

- Unity 6.3 LTS project skeleton (starting Editor version 6000.3.0f1).
- Editor command that builds a playable 3D prototype scene from Unity primitives.
- Third-person WASD movement, sprint, jump, rotating follow camera, left-click melee.
- Prototype monsters with chase, damage, death, respawn, EXP, local gold rewards, and drops using source item IDs.
- E to collect nearby drops, B for real temporary bag UI, F5 for local save.
- 200 inventory slots / 40 initially unlocked; 200 warehouse slots, four currencies exact up to 21 digits, equipment and shops.
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
- WASD move / Shift sprint / Space jump / Q auto-attack / T lock target / 1–3 Novice skills
- Mouse move orbit camera / Left-click melee attack (nearby monsters, facing them)
- E loot nearest drop / B bag / C stats / K skills / F8 touch controls / F5 save
- Press Play to reset scene. Profile and inventory persist locally in Application.persistentDataPath/leoonline-unity-prototype.json.

## Layout
- Assets/LEOM/Scripts/Runtime — offline RPG services, combat, HUD and input
- Assets/LEOM/Resources/LeomLegacyCatalog.json — imported Godot catalogs
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

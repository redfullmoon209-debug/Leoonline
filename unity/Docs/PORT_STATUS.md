# LEOM port status — Godot Leoonline -> Unity

This is a code migration in the *existing* repository. Original root Godot project stays untouched; the user explicitly requested **no original character FBX and no original map GLB**, so this migration uses purely generated Unity primitive 3D models and world geometry.

## Carried over from original scripts (data/logic)
| Original Godot | LEOM Unity replacement | Status |
| --- | --- | --- |
| store.gd DATA | Resources/LeomLegacyCatalog.json | 31 stable item IDs, names, equipment slot mappings imported |
| shop_catalog.gd | same JSON + LegacyCatalog.cs | 21 exact shop offers, 500 reserved positions, exact prices |
| job_catalog.gd | same JSON | all 13 Novice/tier1/tier2 job entries and six paths |
| skill_catalog.gd | same JSON | all 171 skill IDs, localized names, passive/buff metadata; most attacks data-only |
| store.gd inventory | LeomRpgService + LeomRpgSave | 200 slots, 40 unlocked, auto +10 per five active hours, scroll +10, sorting, equipping and trash confirmations |
| store.gd warehouse | LeomRpgService + LeomGameHUD | 200 storage slots, item deposit/withdraw and 4 currency balances |
| store.gd exact money math | LeomAmount.cs | decimal strings to 21 digits, no floats/Int64, input validation and overflow checks |
| shop_service.gd | LeomRpgService.cs | local buy/sell with ownership/capacity/balance checks and deterministic prices |
| store.gd character profile | LeomRpgSave.cs | six base stats, level/EXP, stat/skill points, PvE/PvP counts, persisted current job |
| novice_combat.gd | LeomPlayer.cs + MonsterBrain.cs | basic attack, Slash/Rush/Guard, stamina, monster chase/damage/respawn, local EXP and drops |
| skill_screen.gd | LeomGameHUD.cs | inspect skills, slot selection, passive upgrade and timed buffs (temporary UI) |
| hud/menu/map/inventory_ui.gd | LeomGameHUD + TouchGamepad | functional temporary cross-device UI; original artwork and sophisticated interactions NOT ported |
| main.gd / bangkok map | LeomProceduralScene.cs | new original primitive terrain, town, arena and guild-war landmarks |
| FemaleLeo.fbx / character_visual.gd | generated humanoid in editor | original character **intentionally not imported** |

## Remaining / not yet functional
- Unity has NOT been compiled in an actual Unity Editor in this session. Dedicated Unity CI license/Build Automation integration is still needed. The GitHub regression checks are **data and portable C# tests only**, not WebGL verification.
- No real online login, multiplayer, authoritative world server, database or MMO economy.
- Open PK, Arena, Guild War, guild/party/trading/ranking logic remain **design placeholders**, not playable features.
- Profession change in the Unity demo is a new *local testing progression* (tier 1 level 10, tier 2 level 50), not claimed as Godot's preexisting permanent feature.
- Career-specific attack abilities are catalog entries, not full combat/animation implementations; novice attacks, timed buff activation and permanent passive stat levels are functional locally.
- Original approved PNG/UI layers, NPC shop character visuals, imported map/minimap, GM panel, localization typography, mobile polish and touch-optimized production UI are unfinished.
- Local saves use Unity PlayerPrefs/JSON so WebGL/mobile can use their platform storage; Godot \`user://leoonline.json\` does **not automatically migrate**. Treat any client save as untrusted.
- The generated world is a test map and neither a recreation of the real Bangkok source nor a production 3D level.
- Online systems will be separate dedicated-server work, with server authority over currency/EXP/loot/PvP.

## How to use
1. Open \`unity/\` in Unity 6.3 LTS, or configure Unity Cloud Build Automation with legitimate license/account rights.
2. Run \`Tools > LEOM > Build Prototype Scene\` (or the pre-export hook). A scene with a temporary humanoid, world, demo monsters and a fully wired debug RPG UI is generated.
3. Play: WASD, mouse look (RMB), LMB attack, T lock target, 1/2/3 Novice skills, E pick up, B bag, C stats, K skills; for touch use on-screen controls (F8 toggles desktop preview).
4. Test item drops, bag slots, equip, buy, sell, storage money, buffs and local save.
5. Run \`python3 tools/verify_leom_migration.py\` and \`dotnet run --project tools/leom-tests/LeomCoreTests.csproj\` as source regression gates.

**WebGL preview remains unavailable until an actual Unity cloud build and web deployment succeed.**

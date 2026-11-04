# LEOM — Unity MMORPG migration from original Leoonline

**Game name: LEOM.** Old GitHub repository stays named `Leoonline` until verified migration.

This branch adds a standalone Unity project in `unity/`. It currently provides:
- 31 original item definitions, 21 original shop offers, 13 professions, 171 skill entries (stable IDs)
- 200 bag slots (40 unlocked), 200 bank slots, exact four 21-digit currencies, NPC shop, equipment and economy test
- Basic PvE/Novice combat, stat and EXP progression, skill/buff UI, local save, temporary touch UI
- **Generated character and map** from Unity primitives; no original FemaleLeo FBX or Bangkok GLB included
- Offline Unity scene builder at `Tools > LEOM > Build Prototype Scene`

**Project:** `unity/` on branch `unity-mmorpg-foundation`.
**Migration documentation:** `unity/Docs/PORT_STATUS.md`.
**Unity Cloud:** https://cloud.unity.com/organizations/18968508051495/projects/8ff585f7-c6f7-4736-a844-1db884381c30
**Source review:** https://github.com/redfullmoon209-debug/Leoonline/pull/28

**Important**: Unity Editor compilation, Play Mode and browser/WebGL deployment have not passed verification yet. GitHub cloud builds still require a valid Unity license/authorized Build Automation. Open PK, Arena, Guild War and full MMO server are NOT implemented, only their architecture placeholders. The Godot project at repository root and its existing website are preserved.

Validate imported catalogs with `python3 tools/verify_leom_migration.py`. The small .NET exact-money tests run via GitHub Actions.

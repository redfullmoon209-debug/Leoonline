# Mapping the legacy Godot Leoonline repository into Unity LEOM

Inspected source: redfullmoon209-debug/Leoonline, main branch (2026-11-04).

| Existing source | Unity destination / intended port |
| --- | --- |
| project.godot / scenes/main.tscn / scripts/main.gd | Unity/Assets/LEOM/Scenes + Editor scene builder, then world/character modules |
| scripts/novice_combat.gd / scripts/novice_touch_skills.gd | Runtime/Gameplay/Combat + server-authoritative ability commands |
| scripts/skill_catalog.gd / scripts/job_catalog.gd | ScriptableObject databases / server-backed profession and skill IDs |
| scripts/store.gd | Character inventory/equipment/currency domain + server transaction service |
| scripts/inventory_ui.gd | Unity UI Toolkit or uGUI frontend; no direct currency mutation |
| scripts/shop_catalog.gd / scripts/shop_service.gd | Shop data + authoritative buy/sell service |
| scripts/gm_test_panel.gd | Local developer tooling; never trust client-side GM permissions |
| scripts/female_character_visual.gd | Unity FBX model, bones, Animator, animation state machine |
| scripts/hud_* / scripts/skill_screen.gd | Unity responsive HUD for desktop/mobile, later |
| shaders/skill_surface.gdshader | Unity shader rewrite, not directly compatible |
| assets/characters/female/* / tools/prepare_female_character.py | Reassemble and validate FemaleLeo.fbx from original source parts; then import as model |
| assets/maps/source_parts/* / tools/prepare_bangkok_map.py | Reconstruct original map GLB, convert/import for Unity after scale and collision tests |
| assets/ui/* and Leoonline_Approved_PNG_Direct.zip | Import approved PNG sprites as Unity textures, retain source layers |

## Preserve existing behavior unless the owner changes it
- 200 bag slots; 40 initially unlocked; timed unlocks and Bag +10 Scroll mechanics.
- 200 warehouse slots and four currencies stored exactly with 21-digit cap.
- Character attributes and six planned profession paths from job catalog.
- Existing FemaleLeo original model/animation assets, not a placeholder substitute.
- Existing visual layout and approved icon art as source references.
- Test controls: keyboard/mouse and phone landscape/portrait wrappers are **Godot** implementations, requiring separate Unity UI work.

## Migration checklist
1. Keep original root Godot code and GitHub Pages pipeline untouched on main.
2. Prepare hashes of original FBX and city model from the source scripts. Do not upload a binary twice unnecessarily.
3. Build Unity model importers, resolve scale/origin, rig setup, animation mapping and material texture references.
4. Port data schema and definitions first; write compatibility fixtures for every item ID/job ID/currency and save transition.
5. Replace demo-primitive world with approved original meshes. Profile map collision and texture memory.
6. Only migrate saves with an explicit audited one-way converter and opt-in; Godot user://leoonline.json is **not** automatically an online account.
7. Replace local gameplay simulation with server-authoritative network implementation, then test adversarial scenarios.
8. Keep old Godot playtest until verified Unity builds cover all required behavior.

## Compatibility warnings
- FBX/GLB models and PNGs can usually be imported, subject to texture/rig verification.
- GDScript, Godot scenes, shader files and project settings cannot be directly opened as Unity/C#.
- Some generated asset sources use Python scripts; execute only trusted repository scripts after review.
- Proprietary original art stays in this project under its existing rights and must not be confused with permissively licensed assets.

# Stage 1 — migrate Unreal character meshes into Godot (before outfits/animations)

**Source of truth:** Hardcore Zombie Survival / Unreal Engine 5.8 project on the owner's Windows machine.
**Target:** Leoonline / Godot 4.4.1, GitHub browser playtest.
**Status:** Preparation only. The Unreal model files have **not yet been supplied or imported**.

## Scope and order

1. Export **one original player character's skeletal mesh + skeleton + materials/textures** from Unreal and prove it imports and renders correctly in Godot, including bone names and proportions.
2. Repeat for the other player characters after stage 1 passes.
3. Bring clothing, footwear, hairstyles and wearable meshes, with common skeletal binding / attachments, **after** base characters work.
4. Migrate idle/walk/run/attack animations and retarget where required, **after** clothing imports.
5. Only after these checks, connect the new visuals to existing game inventory/equipment, replace the optional player visual and run browser/mobile QA.

Do **not** overwrite `scripts/female_character_visual.gd`, `assets/characters/female/FemaleLeo.fbx`, inventory, HUD, saves, existing animations, or maps during stage 1.

## Unreal Editor export — first character (manual step, once)

1. Open the **editable source project** in Unreal Editor, not the cooked/shipping game.
2. In Content Browser, find the character's **Skeletal Mesh** asset (mesh icon, not a Blueprint actor). Before export, inspect that the asset shows the correct skin, full body and skeleton.
3. Prefer `.glb` using Unreal's **glTF Exporter** if enabled and that asset supports it. For the mesh, export with **vertex skin weights** and check materials/textures. A `.glb` packages referenced texture data more conveniently. Otherwise use `Asset Actions > Export > FBX` and **export needed texture files separately**.
4. Do **not** export just an `.uasset` or `.umap`: Godot cannot import Unreal binary packages as editable 3D models.
5. Name the first asset something meaningful (for example `PlayerCharacter01.glb`), record Unreal asset path and license/source; keep original bone/skeleton names and model orientation.
6. Do not bake multiple clothing/skin variants into this first character file. We will handle modular gear separately.
7. Verify ownership/license *before uploading raw source models*. **Leoonline is a public repository**; third-party source files often cannot be redistributed publicly. First pass them privately for review, or work in a private asset repository with suitable Git LFS access.

## Asset handoff

Provide **one** exported base-character `.glb` (or `.fbx` plus its textures) from the Unreal project, preferably as a ZIP with a short asset source/license note. For large files, Git LFS in a **private** repository is preferred. Do not provide project secrets, keystores, accounts, or Unreal cooked files.

Godot staging destination after rights are checked:
`res://assets/characters/unreal_import/<character_name>/character.glb`

Do not commit placeholder meshes or claim migration succeeded before the real Unreal asset is imported.

## Import/QA gate

After staging a real model and running a Godot 4.4.1 editor import:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tools/verify_unreal_character.gd -- res://assets/characters/unreal_import/<character_name>/character.glb
```

The verifier fails on missing/invalid scene, no visible meshes, or no skeleton/bones. Passing this **structural** check is not enough to ship: inspect visual proportions, textures, skin weights, scale, bone movement, shader import, performance and render on Chrome/mobile landscape before switching any live character.

## Known compatibility limits

- Unreal Blueprint Character, Animation Blueprint, Control Rig, sockets and clothing simulation do not convert automatically; their behavior must be recreated in Godot.
- Unreal's glTF exporter cannot export every Unreal material/feature; inspect and adjust PBR materials in Godot.
- Preserve the existing Godot FemaleLeo test avatar until the imported model is verified. Replacing it before QA risks breaking combat and the camera.
- Do not trigger Android/Google Play releases from this stage.

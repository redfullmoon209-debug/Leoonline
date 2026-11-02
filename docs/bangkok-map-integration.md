# Leoonline — Bangkok map import

Source: user-provided `mapthai(1).blend` (Blender 3D city map).

The imported scene retains 73 unique city meshes, 388,179 triangles and embedded
source textures/UVs. Duplicate overlapping Blender export objects, the source
grid, and authoring markers were excluded. The web GLB is approximately 15 MB.

## Local setup

After cloning the repository, run:

```bash
python3 tools/prepare_bangkok_map.py
```

Then open `project.godot` in Godot 4.4.1. GitHub Pages builds automatically
reconstruct the map before the Godot import phase.

## Spawn and walking

The map is rotated from Blender Z-up to Godot Y-up, scaled by 0.1, translated
so the inspected open road at Blender (X=200, Y=-780, Z=26.7) is Godot origin.
The player spawns at (0, 1.1, 0). A 210 x 245 m flat walkable StaticBody3D
collider sits at Y=0, with a terrain plane underneath. Buildings are visual
geometry; precise building/wall collisions remain a separate optimization step.

The original HUD, inventory, training targets and auto-combat are preserved.

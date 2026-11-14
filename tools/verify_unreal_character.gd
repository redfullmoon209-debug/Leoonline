extends SceneTree
## Structural QA for an Unreal-exported skeletal character in Godot 4.4.1.
## This script does not modify a project or replace the live avatar.
## Run after Godot's editor import:
## godot --headless --path . --script res://tools/verify_unreal_character.gd -- res://assets/characters/unreal_import/hero/character.glb

func _initialize() -> void:
    var args: PackedStringArray = OS.get_cmdline_user_args()
    if args.is_empty():
        push_error("Supply one imported .glb/.gltf/.fbx res:// path after --")
        quit(2)
        return
    var asset_path: String = args[0]
    if not asset_path.begins_with("res://"):
        push_error("Expected a res:// model path, got: " + asset_path)
        quit(2)
        return
    if not ResourceLoader.exists(asset_path):
        push_error("Model is not imported or path is missing: " + asset_path)
        quit(2)
        return
    var packed: PackedScene = load(asset_path) as PackedScene
    if packed == null:
        push_error("Asset did not import as PackedScene: " + asset_path)
        quit(2)
        return
    var root: Node = packed.instantiate()
    if root == null:
        push_error("Unable to instantiate imported scene: " + asset_path)
        quit(2)
        return
    var pending: Array[Node] = [root]
    var mesh_count: int = 0
    var surface_count: int = 0
    var bone_count: int = 0
    var skeleton_count: int = 0
    while not pending.is_empty():
        var current: Node = pending.pop_back()
        if current is MeshInstance3D:
            var mesh_instance: MeshInstance3D = current as MeshInstance3D
            if mesh_instance.mesh != null:
                mesh_count += 1
                surface_count += mesh_instance.mesh.get_surface_count()
        if current is Skeleton3D:
            var sk: Skeleton3D = current as Skeleton3D
            skeleton_count += 1
            bone_count += sk.get_bone_count()
        for child: Node in current.get_children():
            pending.append(child)
    root.free()
    print("UNREAL_CHARACTER_IMPORT_QA path=", asset_path,
        " meshes=", mesh_count, " surfaces=", surface_count,
        " skeletons=", skeleton_count, " bones=", bone_count)
    if mesh_count < 1 or surface_count < 1 or skeleton_count < 1 or bone_count < 1:
        push_error("Import incomplete. Expected visible meshes and at least one populated Skeleton3D.")
        quit(1)
        return
    print("UNREAL_CHARACTER_IMPORT_QA STRUCTURAL_PASS; visual, material and animation QA still required")
    quit(0)

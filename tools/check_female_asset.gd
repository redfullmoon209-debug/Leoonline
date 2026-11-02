extends SceneTree
## Headless QA: verifies the downloaded female GLB has real meshes.
func _initialize() -> void:
    call_deferred("_check")

func _check() -> void:
    var path := "res://assets/characters/female/Female.glb"
    if not ResourceLoader.exists(path):
        push_error("Female model not imported: " + path)
        quit(1)
        return
    var scene := load(path) as PackedScene
    if scene == null:
        push_error("Female GLB did not import as a PackedScene")
        quit(1)
        return
    var model := scene.instantiate()
    root.add_child(model)
    var meshes: int = 0
    var rig_count: int = 0
    for n in model.find_children("*", "MeshInstance3D", true, false):
        if n is MeshInstance3D and n.mesh != null and n.name != "Cube":
            meshes += 1
    for n in model.find_children("*", "Skeleton3D", true, false):
        if n is Skeleton3D:
            rig_count += 1
    print("FEMALE MODEL QA: meshes=", meshes, " skeletons=", rig_count)
    model.queue_free()
    if meshes < 1:
        push_error("Female GLB has no visible usable meshes")
        quit(1)
        return
    if rig_count < 1:
        push_error("Female GLB has no Skeleton3D")
        quit(1)
        return
    quit(0)

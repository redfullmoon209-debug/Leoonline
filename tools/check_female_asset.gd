extends SceneTree
## Headless QA: verifies user-uploaded FemaleLeo.fbx and functional movement.
func _initialize() -> void:
    call_deferred("_check")

func _check() -> void:
    var path := "res://assets/characters/female/FemaleLeo.fbx"
    if not ResourceLoader.exists(path):
        push_error("Female model not imported: " + path)
        quit(1)
        return
    var scene := load(path) as PackedScene
    if scene == null:
        push_error("Female FBX did not import as a PackedScene")
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
    print("FEMALELEO ORIGINAL FBX QA: meshes=", meshes, " skeletons=", rig_count)
    model.queue_free()
    if meshes < 1:
        push_error("Female FBX has no visible usable meshes")
        quit(1)
        return
    if rig_count < 1:
        push_error("Female FBX has no Skeleton3D")
        quit(1)
        return
    # Prove not just that the FBX exists: verify bones can actually be
    # matched to the sampled Mixamo walk/run animation tracks. This test
    # catches a fully rendered but completely frozen T-pose character.
    var visual: Node3D = load("res://scripts/female_character_visual.gd").new() as Node3D
    root.add_child(visual)
    var matched: Dictionary = visual.get("bone_indices")
    var walk_data: Dictionary = visual.get("walk_bone_tracks")
    var run_data: Dictionary = visual.get("bone_tracks")
    print("FEMALE ANIMATION QA: matched bones=", matched.size(),
          " walk tracks=", walk_data.size(), " run tracks=", run_data.size())
    if visual.get("visual_loaded") != true or matched.size() < 8:
        push_error("Female character animation bones did not retarget to the actual FBX rig")
        quit(1)
        return
    if walk_data.size() < 8 or run_data.size() < 8:
        push_error("Run/Walk animation curves are missing")
        quit(1)
        return
    visual.call("animate_motion", Vector3.FORWARD, false, 0.1)
    if visual.get("active_motion") != "walk":
        push_error("Female character walking state is not reachable")
        quit(1)
        return
    visual.call("animate_motion", Vector3.FORWARD, true, 0.1)
    if visual.get("active_motion") != "run":
        push_error("Female character sprinting state is not reachable")
        quit(1)
        return
    visual.call("animate_motion", Vector3.ZERO, false, 0.1)
    if visual.get("active_motion") != "idle":
        push_error("Female character idle state is not reachable")
        quit(1)
        return
    print("FEMALE ANIMATION QA PASSED: idle/walk/run")
    quit(0)

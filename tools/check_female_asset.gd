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
    # Regression: a imported T-pose is NOT an acceptable idle animation.
    # Both actual arm joint vectors should now point mainly downward.
    var skel:Skeleton3D=visual.get("skeleton") as Skeleton3D
    var right_arm:int=int(visual.get("right_arm_index"))
    var right_forearm:int=int(visual.get("right_elbow_index"))
    var right_hand:int=int(visual.get("right_hand_index"))
    var left_arm:int=int(visual.get("left_arm_index"))
    var left_forearm:int=int(visual.get("left_elbow_index"))
    var left_hand:int=int(visual.get("left_hand_index"))
    if skel==null or not bool(visual.get("rig_ready")) or [right_arm,right_forearm,right_hand,left_arm,left_forearm,left_hand].has(-1):
        push_error("Original Mixamo skeleton does not have both complete arm chains")
        quit(1)
        return
    var right_idle:Vector3=(skel.get_bone_global_pose(right_forearm).origin-skel.get_bone_global_pose(right_arm).origin).normalized()
    var left_idle:Vector3=(skel.get_bone_global_pose(left_forearm).origin-skel.get_bone_global_pose(left_arm).origin).normalized()
    print("FEMALE POSE QA: right upper-arm ",right_idle," left upper-arm ",left_idle)
    if right_idle.y > -0.48 or left_idle.y > -0.48:
        push_error("FemaleLeo is still T-posing; upper arms must hang down in idle")
        quit(1)
        return
    var socket:BoneAttachment3D=visual.get("sword_attachment") as BoneAttachment3D
    var sword:Node3D=visual.get("sword_visual") as Node3D
    if socket==null or sword==null or not bool(sword.get("mesh_ready")):
        push_error("Novice training sword was not created as actual 3D meshes")
        quit(1)
        return
    if socket.get_parent()!=skel or sword.get_parent()!=socket or socket.bone_idx!=right_hand:
        push_error("Sword must follow the actual imported RightHand Mixamo bone")
        quit(1)
        return
    for piece in ["SwordBlade","LeatherSwordGrip","GoldenCrossguard","SwordPommel"]:
        var node:MeshInstance3D=sword.get_node_or_null(piece) as MeshInstance3D
        if node==null or node.mesh==null:
            push_error("Missing real sword geometry: "+piece)
            quit(1)
            return
    # This also checks the 3D prop is full-sized and in the actual right
    # hand, not simply present somewhere in the scene tree.
    await process_frame
    var hand_world:Vector3=skel.global_transform*skel.get_bone_global_pose(right_hand).origin
    if sword.global_position.distance_to(hand_world)>0.12:
        push_error("The sword is not visually attached at the RightHand joint")
        quit(1)
        return
    var idle_tip:Vector3=sword.to_global(Vector3(0,1.05,0))
    var blade_length:float=idle_tip.distance_to(sword.global_position)
    print("FEMALE SWORD QA: grip ",sword.global_position," tip ",idle_tip," length=",blade_length)
    if blade_length<0.55 or blade_length>1.55:
        push_error("Training sword is unreasonably small/large after imported FBX scale fit")
        quit(1)
        return
    # The slash must change the ACTUAL arm pose, not just subtract monster HP.
    visual.call("play_basic_attack")
    visual.call("animate_motion",Vector3.ZERO,false,0.12)
    var windup:Vector3=(skel.get_bone_global_pose(right_forearm).origin-skel.get_bone_global_pose(right_arm).origin).normalized()
    await process_frame
    var raised_tip:Vector3=sword.to_global(Vector3(0,1.05,0))
    visual.call("animate_motion",Vector3.ZERO,false,0.21)
    var slash:Vector3=(skel.get_bone_global_pose(right_forearm).origin-skel.get_bone_global_pose(right_arm).origin).normalized()
    await process_frame
    var slash_tip:Vector3=sword.to_global(Vector3(0,1.05,0))
    print("FEMALE COMBAT QA: raised arm ",windup," swing arm ",slash," sword tip movement=",raised_tip.distance_to(slash_tip))
    if raised_tip.distance_to(slash_tip)<0.16:
        push_error("Bone-attached sword does not follow the moving hand during slash")
        quit(1)
        return
    if windup.distance_to(right_idle)<0.20 or slash.distance_to(windup)<0.18:
        push_error("The right-hand sword is not animated through a visible slash arc")
        quit(1)
        return
    visual.call("animate_motion",Vector3.ZERO,false,0.20)
    visual.call("animate_motion",Vector3.ZERO,false,0.20)
    var ready_again:Vector3=(skel.get_bone_global_pose(right_forearm).origin-skel.get_bone_global_pose(right_arm).origin).normalized()
    if ready_again.y>-0.50:
        push_error("Sword arm did not return to the lowered ready stance")
        quit(1)
        return
    visual.call("animate_motion",Vector3.FORWARD,true,0.10)
    var running_arm:Vector3=(skel.get_bone_global_pose(right_forearm).origin-skel.get_bone_global_pose(right_arm).origin).normalized()
    if running_arm.y>-0.35:
        push_error("Running restores T-pose; combat-ready arms must persist")
        quit(1)
        return
    print("FEMALE ANIMATION QA PASSED: true arms-down idle/walk/run, right-hand sword and visible slash")
    quit(0)

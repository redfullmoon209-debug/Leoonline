extends Node3D
## Displays the existing artist-owned female GLB from NexTgenLeo.
## The model is downloaded during Godot web builds, before import.
## Run cycle is sampled from the user's uploaded Run.fbx (20 frames).
const MODEL_PATH := "res://assets/characters/female/Female.glb"
const RUN_TRACKS_PATH := "res://assets/characters/female/run_tracks.json"
const WALK_TRACKS_PATH := "res://assets/characters/female/walk_tracks.json"

var target_height_m: float = 1.76
var feet_y: float = -1.05
var visual_loaded: bool = false
var rendered_mesh_count: int = 0
var model_fit: Node3D
var skeleton: Skeleton3D
var bone_tracks: Dictionary = {}
var walk_bone_tracks: Dictionary = {}
var walk_fps: float = 12.0
var run_fps: float = 30.0
var active_motion: String = "idle"
var bone_bind_pose: Dictionary = {}
var bone_indices: Dictionary = {}
var frame_count: int = 0
var stride_clock: float = 0.0

func _ready() -> void:
    if not ResourceLoader.exists(MODEL_PATH):
        push_warning("Female character GLB missing: run python3 tools/prepare_female_character.py")
        return
    var asset: PackedScene = load(MODEL_PATH) as PackedScene
    if asset == null:
        push_warning("Female GLB could not be imported")
        return
    var instance: Node3D = asset.instantiate() as Node3D
    if instance == null:
        push_warning("Female GLB root is not Node3D")
        return
    model_fit = Node3D.new()
    model_fit.name = "FemaleMeshFit"
    add_child(model_fit)
    model_fit.add_child(instance)

    # Calculate the complete mesh bounds in a shared coordinate system.
    # The source asset has an unwanted helper Cube; hide it, not the body.
    var box := AABB()
    var found := false
    var queue: Array[Node] = [instance]
    var inv: Transform3D = model_fit.global_transform.affine_inverse()
    while not queue.is_empty():
        var current: Node = queue.pop_back()
        if current is MeshInstance3D:
            var mesh: MeshInstance3D = current as MeshInstance3D
            if mesh.name == "Cube":
                mesh.visible = false
            elif mesh.mesh != null:
                var bounds: AABB = mesh.get_aabb()
                var transform: Transform3D = inv * mesh.global_transform
                for i in range(8):
                    var v: Vector3 = transform * bounds.get_endpoint(i)
                    if not found:
                        box = AABB(v, Vector3.ZERO)
                        found = true
                    else:
                        box = box.expand(v)
                rendered_mesh_count += 1
        for child in current.get_children():
            queue.append(child)

    if not found or box.size.y <= 0.001:
        model_fit.queue_free()
        push_warning("Female GLB has no usable visible meshes")
        return
    var scalar: float = clampf(target_height_m / box.size.y, 0.0001, 1000.0)
    model_fit.scale = Vector3.ONE * scalar
    model_fit.position = Vector3(
        -box.get_center().x * scalar,
        feet_y - box.position.y * scalar,
        -box.get_center().z * scalar
    )
    for n in instance.find_children("*", "Skeleton3D", true, false):
        skeleton = n as Skeleton3D
        break
    _load_uploaded_run_tracks()
    visual_loaded = true

func _load_uploaded_run_tracks() -> void:
    if skeleton == null:
        return
    var paths := [RUN_TRACKS_PATH, WALK_TRACKS_PATH]
    for path in paths:
        if not FileAccess.file_exists(path):
            push_warning("Character animation file not found: " + path)
            continue
        var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
        if not (raw is Dictionary):
            push_warning("Invalid character animation: " + path)
            continue
        var decoded: Dictionary = raw
        var tracks: Dictionary = decoded.get("bones", {})
        if path == RUN_TRACKS_PATH:
            bone_tracks = tracks
            run_fps = float(decoded.get("fps", 30.0))
        else:
            walk_bone_tracks = tracks
            walk_fps = float(decoded.get("fps", 12.0))
        for original_name in tracks:
            if bone_indices.has(original_name):
                continue
            var target_name: String = String(original_name).to_lower()
            for i in range(skeleton.get_bone_count()):
                var candidate: String = String(skeleton.get_bone_name(i)).to_lower()
                candidate = candidate.replace("mixamorig:", "").replace("mixamorig_", "")
                if candidate == target_name:
                    bone_indices[original_name] = i
                    bone_bind_pose[original_name] = skeleton.get_bone_pose_rotation(i)
                    break
    print("Female character visuals: meshes=", rendered_mesh_count,
        " bones_with_motion=", bone_indices.size(),
        " run=", bone_tracks.size(), " walk=", walk_bone_tracks.size())

func animate_motion(direction: Vector3, is_sprinting: bool, delta: float) -> void:
    if not visual_loaded:
        return
    var moving: bool = direction.length_squared() > 0.01
    if moving:
        var yaw: float = atan2(-direction.x, -direction.z)
        rotation.y = lerp_angle(rotation.y, yaw, clampf(delta * 12.0, 0.0, 1.0))
    if skeleton == null or bone_indices.is_empty():
        return
    # Stand still in the original bind pose, walk at normal movement speed,
    # and run only when Shift or mobile Run is held.
    var next_motion: String = ("run" if is_sprinting else "walk") if moving else "idle"
    if next_motion != active_motion:
        active_motion = next_motion
        stride_clock = 0.0
    var selected: Dictionary = bone_tracks if active_motion == "run" else walk_bone_tracks
    var frame_total: int = 0
    if moving:
        for name in selected:
            frame_total = maxi(frame_total, (selected[name] as Array).size())
        if frame_total > 1:
            var fps: float = run_fps if active_motion == "run" else walk_fps
            stride_clock = fposmod(stride_clock + delta * fps, float(frame_total))
    for name in bone_indices:
        var idx: int = int(bone_indices[name])
        var rest: Quaternion = bone_bind_pose[name]
        var pose: Quaternion = rest
        if moving and selected.has(name):
            var frames: Array = selected[name]
            if frames.size() > 1:
                var first: int = int(floor(stride_clock)) % frames.size()
                var second: int = (first + 1) % frames.size()
                var fraction: float = stride_clock - floor(stride_clock)
                var a: Array = frames[first]
                var b: Array = frames[second]
                if a.size() >= 3 and b.size() >= 3:
                    var euler: Vector3 = Vector3(
                        lerpf(float(a[0]), float(b[0]), fraction),
                        lerpf(float(a[1]), float(b[1]), fraction),
                        lerpf(float(a[2]), float(b[2]), fraction)
                    ) * (PI / 180.0)
                    pose = rest * Quaternion.from_euler(euler)
        var current: Quaternion = skeleton.get_bone_pose_rotation(idx)
        skeleton.set_bone_pose_rotation(idx, current.slerp(pose, clampf(delta * 12.0, 0.0, 1.0)))

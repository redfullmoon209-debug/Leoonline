extends Node3D
## Displays the existing artist-owned female GLB from NexTgenLeo.
## The model is downloaded during Godot web builds, before import.
## Run cycle is sampled from the user's uploaded Run.fbx (20 frames).
const MODEL_PATH := "res://assets/characters/female/Female.glb"
const RUN_TRACKS_PATH := "res://assets/characters/female/run_tracks.json"

var target_height_m: float = 1.76
var feet_y: float = -1.05
var visual_loaded: bool = false
var rendered_mesh_count: int = 0
var model_fit: Node3D
var skeleton: Skeleton3D
var bone_tracks: Dictionary = {}
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
    if skeleton == null or not FileAccess.file_exists(RUN_TRACKS_PATH):
        return
    var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUN_TRACKS_PATH))
    if not (raw is Dictionary):
        return
    var decoded: Dictionary = raw
    bone_tracks = decoded.get("bones", {})
    for original_name in bone_tracks:
        var target_name: String = String(original_name).to_lower()
        var idx: int = -1
        for i in range(skeleton.get_bone_count()):
            var candidate: String = String(skeleton.get_bone_name(i)).to_lower()
            candidate = candidate.replace("mixamorig:", "").replace("mixamorig_", "")
            if candidate == target_name:
                idx = i
                break
        if idx != -1:
            bone_indices[original_name] = idx
            bone_bind_pose[original_name] = skeleton.get_bone_pose_rotation(idx)
            var frames: Array = bone_tracks[original_name]
            frame_count = maxi(frame_count, frames.size())

func animate_motion(direction: Vector3, is_sprinting: bool, delta: float) -> void:
    if not visual_loaded:
        return
    var moving: bool = direction.length_squared() > 0.01
    if moving:
        # The imported GLB points toward -Z in Godot.
        var yaw: float = atan2(-direction.x, -direction.z)
        rotation.y = lerp_angle(rotation.y, yaw, clampf(delta * 12.0, 0.0, 1.0))
    if skeleton == null or frame_count < 2:
        return
    if moving:
        stride_clock = fposmod(stride_clock + delta * (22.0 if is_sprinting else 15.0), float(frame_count))
    var first: int = int(floor(stride_clock))
    var second: int = (first + 1) % frame_count
    var fraction: float = stride_clock - float(first)
    var blend: float = (0.73 if is_sprinting else 0.44) if moving else 0.0
    for name in bone_indices:
        var idx: int = int(bone_indices[name])
        var resting: Quaternion = bone_bind_pose[name]
        if not moving:
            skeleton.set_bone_pose_rotation(idx, resting)
            continue
        var frames: Array = bone_tracks[name]
        if frames.size() < 2:
            continue
        var va: Array = frames[first % frames.size()]
        var vb: Array = frames[second % frames.size()]
        var degrees: Vector3 = Vector3(
            lerpf(float(va[0]), float(vb[0]), fraction),
            lerpf(float(va[1]), float(vb[1]), fraction),
            lerpf(float(va[2]), float(vb[2]), fraction)
        ) * 0.1
        var radians: Vector3 = degrees * (PI / 180.0)
        var change: Quaternion = Quaternion.from_euler(radians)
        skeleton.set_bone_pose_rotation(idx, resting * Quaternion.IDENTITY.slerp(change, blend))

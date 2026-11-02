extends Node3D
## Displays ONLY the exact user-uploaded FemaleLeo.fbx with its embedded textures.
## Reassembled from verified source fragments before Godot imports the model.
## Run cycle is sampled from the user's uploaded Run.fbx (20 frames).
const MODEL_PATH := "res://assets/characters/female/FemaleLeo.fbx"
const RUN_TRACKS_PATH := "res://assets/characters/female/run_tracks.json"
const WALK_TRACKS_PATH := "res://assets/characters/female/walk_tracks.json"

var target_height_m: float = 1.62
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
# A brief additive swing on the actual Mixamo arm, layered over the
# user's untouched Walk/Run FBX bone tracks. No fake attack asset.
var basic_attack_time:float=0.0
const BASIC_ATTACK_DURATION:float=0.49
# All pose changes occur on the ORIGINAL imported Mixamo skeleton.
# Keep the source FBX and its embedded textures intact.
var right_arm_index:int=-1
var right_elbow_index:int=-1
var right_hand_index:int=-1
var left_arm_index:int=-1
var left_elbow_index:int=-1
var left_hand_index:int=-1
var spine_index:int=-1
var initial_pose_by_index:Dictionary={}
var sword_attachment:BoneAttachment3D
var sword_visual:Node3D
var rig_ready:bool=false

func play_basic_attack() -> void:
 basic_attack_time=BASIC_ATTACK_DURATION

func set_training_sword_visible(enabled:bool) -> void:
 if is_instance_valid(sword_visual):sword_visual.visible=enabled

func _ready() -> void:
    if not ResourceLoader.exists(MODEL_PATH):
        push_warning("Female character FBX missing: run python3 tools/prepare_female_character.py")
        return
    var asset: PackedScene = load(MODEL_PATH) as PackedScene
    if asset == null:
        push_warning("Female FBX could not be imported")
        return
    var instance: Node3D = asset.instantiate() as Node3D
    if instance == null:
        push_warning("Female FBX root is not Node3D")
        return
    model_fit = Node3D.new()
    model_fit.name = "FemaleMeshFit"
    add_child(model_fit)
    model_fit.add_child(instance)

    # Calculate the complete mesh bounds in a shared coordinate system.
    # Keep every original mesh and the material/texture data authored in FemaleLeo.fbx.
    var box := AABB()
    var found := false
    var queue: Array[Node] = [instance]
    var inv: Transform3D = model_fit.global_transform.affine_inverse()
    while not queue.is_empty():
        var current: Node = queue.pop_back()
        if current is MeshInstance3D:
            var mesh: MeshInstance3D = current as MeshInstance3D
            if mesh.mesh != null:
                # No material overrides: use the exact FBX embedded artwork.
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
        push_warning("FemaleLeo.fbx has no usable visible meshes")
        return

    # FemaleLeo.fbx's source mesh and its Mixamo armature use different
    # coordinate units (the FBX mesh node has an explicit 100x transform).
    # A skinned mesh can therefore be visually much larger than the static
    # MeshInstance3D AABB. Fit the larger of mesh and bone extents so the
    # camera cannot end up inside an oversized leg.
    for n in instance.find_children("*", "Skeleton3D", true, false):
        skeleton = n as Skeleton3D
        break
    var bone_box := AABB()
    var bones_found := false
    if skeleton != null:
        var bone_to_fit: Transform3D = inv * skeleton.global_transform
        for i in range(skeleton.get_bone_count()):
            var bone_point: Vector3 = bone_to_fit * skeleton.get_bone_global_pose(i).origin
            if not bone_point.is_finite():
                continue
            if not bones_found:
                bone_box = AABB(bone_point, Vector3.ZERO)
                bones_found = true
            else:
                bone_box = bone_box.expand(bone_point)

    var fit_box: AABB = box
    if bones_found and bone_box.size.y > box.size.y * 1.10:
        fit_box = bone_box
    elif bones_found and bone_box.size.y > box.size.y * 0.70:
        # When both representations agree, preserve both feet and head tips.
        fit_box = fit_box.expand(bone_box.position)
        fit_box = fit_box.expand(bone_box.end)

    if fit_box.size.y <= 0.001:
        model_fit.queue_free()
        push_warning("FemaleLeo.fbx has no usable avatar height")
        return
    var scalar: float = clampf(target_height_m / fit_box.size.y, 0.000001, 1000.0)
    model_fit.scale = Vector3.ONE * scalar
    model_fit.position = Vector3(
        -fit_box.get_center().x * scalar,
        feet_y - fit_box.position.y * scalar,
        -fit_box.get_center().z * scalar
    )
    print("FemaleLeo visual fit: mesh=", box.size,
        " skeleton=", bone_box.size if bones_found else Vector3.ZERO,
        " selected=", fit_box.size, " scale=", scalar,
        " final_height=", fit_box.size.y * scalar)
    _load_uploaded_run_tracks()
    _prepare_idle_and_weapon_rig()
    visual_loaded = true
    # The imported FBX is authored in T-pose. Apply a real standing pose
    # BEFORE the first frame is displayed, rather than exposing T-pose idle.
    animate_motion(Vector3.ZERO,false,0.20)
    _attach_training_sword_to_right_hand()

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
                # Godot GLB imports often rename "mixamorig:Hips" to
                # "mixamorigHips" (no colon), or mixamorig1:Hips.
                # The previous mapping handled only colon/underscore names,
                # causing zero matching bones and a frozen avatar.
                candidate = candidate.replace("mixamorig", "")
                for separator in [":", "_", "|", "-", " ", ".", "/"]:
                    candidate = candidate.replace(separator, "")
                if candidate == target_name or candidate.ends_with(target_name):
                    bone_indices[original_name] = i
                    bone_bind_pose[original_name] = skeleton.get_bone_pose_rotation(i)
                    break
    if bone_indices.is_empty():
        var first_bones := PackedStringArray()
        for i in range(mini(25, skeleton.get_bone_count())):
            first_bones.append(String(skeleton.get_bone_name(i)))
        push_warning("Unable to map avatar animation bones. Actual rig names: " + str(first_bones))
    print("FemaleLeo original model: meshes=", rendered_mesh_count,
        " bones_with_motion=", bone_indices.size(),
        " run=", bone_tracks.size(), " walk=", walk_bone_tracks.size())

# Find both imported and colon-stripped Mixamo names without changing them.
func _find_rig_bone(short_name:String) -> int:
 if skeleton==null:return -1
 var required:String=short_name.to_lower()
 for idx in range(skeleton.get_bone_count()):
  var candidate:String=str(skeleton.get_bone_name(idx)).to_lower().replace("mixamorig","")
  for separator in [":","_","|","-"," ",".","/"]:
   candidate=candidate.replace(separator,"")
  if candidate==required or candidate.ends_with(required):
   return idx
 return -1

func _bone_direction(from_index:int,to_index:int) -> Vector3:
 if skeleton==null or from_index<0 or to_index<0:return Vector3.DOWN
 var difference:Vector3=skeleton.get_bone_global_rest(to_index).origin-skeleton.get_bone_global_rest(from_index).origin
 if difference.length_squared()<0.000001:return Vector3.DOWN
 return difference.normalized()

func _prepare_idle_and_weapon_rig() -> void:
 if skeleton==null:return
 for idx in range(skeleton.get_bone_count()):
  initial_pose_by_index[idx]=skeleton.get_bone_pose_rotation(idx)
 right_arm_index=_find_rig_bone("RightArm")
 right_elbow_index=_find_rig_bone("RightForeArm")
 right_hand_index=_find_rig_bone("RightHand")
 left_arm_index=_find_rig_bone("LeftArm")
 left_elbow_index=_find_rig_bone("LeftForeArm")
 left_hand_index=_find_rig_bone("LeftHand")
 spine_index=_find_rig_bone("Spine")
 rig_ready=right_arm_index>=0 and right_elbow_index>=0 and right_hand_index>=0 and left_arm_index>=0 and left_elbow_index>=0 and left_hand_index>=0
 if not rig_ready:push_warning("FemaleLeo missing full upper-arm chain; cannot safely pose the hands")
 else:print("FemaleLeo sword-ready Mixamo rig: right arm=",right_arm_index," hand=",right_hand_index," left arm=",left_arm_index)

# Align the actual joint segment from the authored T-pose to a desired
# direction in skeleton coordinates. Converting through global REST
# orientation avoids guessing Blender/Mixamo local bone axes.
func _aim_joint_local(bone:int,child:int,desired:Vector3,parent_correction:Quaternion) -> Quaternion:
 if bone<0 or child<0:return Quaternion.IDENTITY
 var base_direction:Vector3=_bone_direction(bone,child)
 var current_direction:Vector3=(parent_correction*base_direction).normalized()
 var correction:Quaternion=Quaternion(current_direction,desired.normalized())
 var world_rest:Quaternion=skeleton.get_bone_global_rest(bone).basis.orthonormalized().get_rotation_quaternion()
 var oriented_rest:Quaternion=(parent_correction*world_rest).normalized()
 return (oriented_rest.inverse()*correction*oriented_rest).normalized()

func _arm_pose_offsets(upper:int,forearm:int,hand:int,elbow_direction:Vector3,hand_direction:Vector3) -> Dictionary:
 var result:Dictionary={}
 if upper<0 or forearm<0 or hand<0:return result
 var source_direction:Vector3=_bone_direction(upper,forearm)
 var upper_world_correction:Quaternion=Quaternion(source_direction,elbow_direction.normalized())
 result[upper]=_aim_joint_local(upper,forearm,elbow_direction,Quaternion.IDENTITY)
 result[forearm]=_aim_joint_local(forearm,hand,hand_direction,upper_world_correction)
 return result

func _attach_training_sword_to_right_hand() -> void:
 if not rig_ready or not is_instance_valid(skeleton):return
 if is_instance_valid(sword_attachment):return
 sword_attachment=BoneAttachment3D.new()
 sword_attachment.name="RightHandSwordSocket"
 # BoneAttachment3D finds its Skeleton3D WHEN it enters the tree.
 # Resolve the actual RightHand bone only after parenting the socket.
 skeleton.add_child(sword_attachment)
 sword_attachment.bone_idx=right_hand_index
 sword_attachment.bone_name=str(skeleton.get_bone_name(right_hand_index))
 sword_attachment.on_skeleton_update()
 sword_visual=load("res://scripts/novice_sword_visual.gd").new() as Node3D
 sword_visual.name="NoviceTrainingSword"
 sword_attachment.add_child(sword_visual)
 # The blade origin sits at the real hand joint. Point its tip slightly
 # forward and down in the CHARACTER's skeleton frame at resting pose,
 # then let BoneAttachment3D follow the wrist through the slash animation.
 var resting_hand:Transform3D=skeleton.get_bone_global_pose(right_hand_index)
 var forward_down:Vector3=Vector3(0.22,-0.52,-0.82).normalized()
 var hand_local_direction:Vector3=(resting_hand.basis.inverse()*forward_down).normalized()
 sword_visual.quaternion=Quaternion(Vector3.UP,hand_local_direction)
 # FBX import scales the skeleton to 1.62m in world space. Keep sword
 # world-size consistent regardless of that auto-fit factor.
 var rig_scale:Vector3=skeleton.global_transform.basis.get_scale()
 # The sword must shrink with the avatar as a whole. Previously the inverse
 # rig scale forced a full-sized weapon on a half-sized Bangkok NPC.
 var avatar_parent_scale:float=global_transform.basis.get_scale().x
 var avatar_scale_ratio:float=(target_height_m/1.62)*avatar_parent_scale
 sword_visual.scale=Vector3.ONE*avatar_scale_ratio/maxf(0.001,rig_scale.x)
 print("FemaleLeo sword attached to RightHand: ",sword_attachment.bone_name," world sword scale=",sword_visual.scale.x)

func _attack_phase_value() -> float:
 if basic_attack_time<=0.0:return 0.0
 return clampf(1.0-basic_attack_time/BASIC_ATTACK_DURATION,0.0,1.0)

func _attack_arm_targets(phase:float) -> Dictionary:
 # Three real sword phases: raise sword, strike forward/down, recover to
 # the ready guard. Elbow and wrist follow the same authored skeleton.
 var rest_elbow:=Vector3(0.18,-0.89,-0.35).normalized()
 var rest_hand:=Vector3(0.10,-0.62,-0.79).normalized()
 var raised_elbow:=Vector3(0.19,0.45,-0.87).normalized()
 var raised_hand:=Vector3(0.03,0.28,-0.96).normalized()
 var cutting_elbow:=Vector3(0.24,-0.82,-0.52).normalized()
 var cutting_hand:=Vector3(0.02,-0.89,-0.46).normalized()
 var elbow:Vector3=rest_elbow
 var hand:Vector3=rest_hand
 if phase<0.29:
  var t:float=smoothstep(0.0,0.29,phase)
  elbow=rest_elbow.lerp(raised_elbow,t).normalized()
  hand=rest_hand.lerp(raised_hand,t).normalized()
 elif phase<0.70:
  var t:float=smoothstep(0.29,0.70,phase)
  elbow=raised_elbow.lerp(cutting_elbow,t).normalized()
  hand=raised_hand.lerp(cutting_hand,t).normalized()
 else:
  var t:float=smoothstep(0.70,1.0,phase)
  elbow=cutting_elbow.lerp(rest_elbow,t).normalized()
  hand=cutting_hand.lerp(rest_hand,t).normalized()
 return {"elbow":elbow,"hand":hand}

func animate_motion(direction: Vector3, is_sprinting: bool, delta: float) -> void:
 if not visual_loaded:return
 basic_attack_time=maxf(0.0,basic_attack_time-delta)
 var moving:bool=direction.length_squared()>0.01
 if moving:
  var yaw:float=atan2(-direction.x,-direction.z)
  rotation.y=lerp_angle(rotation.y,yaw,clampf(delta*12.0,0.0,1.0))
 if skeleton==null:return
 var next_motion:String=("run" if is_sprinting else "walk") if moving else "idle"
 if next_motion!=active_motion:
  active_motion=next_motion
  stride_clock=0.0
 var selected:Dictionary=bone_tracks if active_motion=="run" else walk_bone_tracks
 var frame_total:int=0
 if moving:
  for name in selected:
   frame_total=maxi(frame_total,(selected[name] as Array).size())
  if frame_total>1:
   var fps:float=run_fps if active_motion=="run" else walk_fps
   stride_clock=fposmod(stride_clock+delta*fps,float(frame_total))
 var poses:Dictionary={}
 # Preserve every uploaded Walk/Run keyframe on the original Mixamo bones.
 for name in bone_indices:
  var idx:int=int(bone_indices[name])
  var rest:Quaternion=bone_bind_pose[name]
  var pose:Quaternion=rest
  if moving and selected.has(name):
   var frames:Array=selected[name]
   if frames.size()>1:
    var first:int=int(floor(stride_clock))%frames.size()
    var second:int=(first+1)%frames.size()
    var fraction:float=stride_clock-floor(stride_clock)
    var a:Array=frames[first]
    var b:Array=frames[second]
    if a.size()>=3 and b.size()>=3:
     var euler:=Vector3(
      lerpf(float(a[0]),float(b[0]),fraction),
      lerpf(float(a[1]),float(b[1]),fraction),
      lerpf(float(a[2]),float(b[2]),fraction)
     )*(PI/180.0)
     pose=rest*Quaternion.from_euler(euler)
  poses[idx]=pose
 # The authored FBX is T-posed. In ALL three locomotion states, relax
 # both arms down into a ready stance, instead of preserving the T-pose.
 if rig_ready:
  var left_offsets:Dictionary=_arm_pose_offsets(
   left_arm_index,left_elbow_index,left_hand_index,
   Vector3(-0.16,-0.97,-0.19).normalized(),
   Vector3(-0.06,-0.95,-0.26).normalized()
  )
  var phase:float=_attack_phase_value()
  var right_elbow:=Vector3(0.18,-0.89,-0.35).normalized()
  var right_hand:=Vector3(0.10,-0.62,-0.79).normalized()
  if basic_attack_time>0.0:
   var attack_targets:Dictionary=_attack_arm_targets(phase)
   right_elbow=attack_targets["elbow"]
   right_hand=attack_targets["hand"]
  var right_offsets:Dictionary=_arm_pose_offsets(right_arm_index,right_elbow_index,right_hand_index,right_elbow,right_hand)
  for idx in left_offsets:
   var base:Quaternion=poses.get(idx,initial_pose_by_index.get(idx,Quaternion.IDENTITY))
   poses[idx]=(left_offsets[idx] as Quaternion)*base
  for idx in right_offsets:
   var base:Quaternion=poses.get(idx,initial_pose_by_index.get(idx,Quaternion.IDENTITY))
   poses[idx]=(right_offsets[idx] as Quaternion)*base
  if basic_attack_time>0.0 and spine_index>=0:
   var torso_base:Quaternion=poses.get(spine_index,initial_pose_by_index.get(spine_index,Quaternion.IDENTITY))
   poses[spine_index]=Quaternion(Vector3.UP,0.18*sin(phase*PI))*torso_base
 var speed:float=24.0 if basic_attack_time>0.0 else 13.0
 for idx in poses:
  var current:Quaternion=skeleton.get_bone_pose_rotation(idx)
  var target:Quaternion=poses[idx]
  skeleton.set_bone_pose_rotation(idx,current.slerp(target,clampf(delta*speed,0.0,1.0)))
 # Match the sword socket to the fully updated right-hand transform in
 # this same movement frame (do not rely on a deferred skin update).
 if is_instance_valid(sword_attachment):
  sword_attachment.on_skeleton_update()

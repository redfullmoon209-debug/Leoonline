extends RefCounted
## Controlled step-up for quarter-size characters on real Blender stair treads.
## Never step through a high wall: the upward clearance AND the horizontal
## motion at step height must both be collision-free before changing position.
const WORLD_LAYER:int=1
const STEP_HEIGHT:float=0.18

static func try_climb(character:CharacterBody3D,from_pos:Vector3,requested_motion:Vector3) -> bool:
 if requested_motion.length_squared()<0.000004:return false
 var capsule_node:CollisionShape3D=character.get_node_or_null("CollisionShape3D") as CollisionShape3D
 if capsule_node==null or not (capsule_node.shape is CapsuleShape3D):return false
 var capsule:CapsuleShape3D=capsule_node.shape as CapsuleShape3D
 var start:Transform3D=character.global_transform
 start.origin=from_pos
 var up:=Vector3(0,STEP_HEIGHT,0)
 if character.test_move(start,up):return false
 var raised:Transform3D=start.translated(up)
 if character.test_move(raised,requested_motion):return false
 var destination:Vector3=raised.origin+requested_motion
 # Query ONLY real world geometry; NPC hitboxes can never become "stairs".
 var from_ray:=destination+Vector3.UP*0.04
 var to_ray:=destination-Vector3.UP*(STEP_HEIGHT+capsule.height*0.5+0.20)
 var ray:=PhysicsRayQueryParameters3D.create(from_ray,to_ray,WORLD_LAYER)
 ray.hit_back_faces=true
 ray.exclude=[character.get_rid()]
 var hit:Dictionary=character.get_world_3d().direct_space_state.intersect_ray(ray)
 if hit.is_empty():return false
 var normal:Vector3=hit["normal"]
 if normal.dot(Vector3.UP)<cos(character.floor_max_angle):return false
 var center_y:float=(hit["position"] as Vector3).y+capsule.height*0.5+0.007
 # Step UP a maximum of 18 cm. Large holes, roofs and walls are not stairs.
 if center_y>from_pos.y+STEP_HEIGHT+0.01 or center_y<from_pos.y-0.07:
  return false
 character.global_position=Vector3(destination.x,center_y,destination.z)
 character.velocity.y=0.0
 character.apply_floor_snap()
 return true

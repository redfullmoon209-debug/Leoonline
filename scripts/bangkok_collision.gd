extends RefCounted
## Build exact static collision from the meshes in the owner's Bangkok GLB.
## The old 210x245 flat box hid slopes, stair treads, descending streets and
## building walls. Godot's native ConcavePolygonShape3D preserves that geometry.
##
## Each source mesh gets its own StaticBody3D, with its CollisionShape3D as a
## DIRECT child of the body. Nothing here changes the rendered mesh or UVs.
const WORLD_LAYER:int=1
const NPC_LAYER:int=2
const PLAYER_LAYER:int=4

static func install(city:Node3D) -> int:
 var installed:int=0
 for node in city.find_children("*","MeshInstance3D",true,false):
  var mesh:MeshInstance3D=node as MeshInstance3D
  if mesh==null or mesh.mesh==null or mesh.mesh.get_surface_count()==0:
   continue
  var shape:ConcavePolygonShape3D=mesh.mesh.create_trimesh_shape()
  if shape==null:
   continue
  # World export contains both winding orders; physical stairs and walls
  # must block from either side, not let an actor fall through backfaces.
  shape.backface_collision=true
  var solid:=StaticBody3D.new()
  solid.name="BangkokSolid_%02d" % installed
  solid.collision_layer=WORLD_LAYER
  solid.collision_mask=0
  solid.add_to_group("bangkok_world_collision")
  mesh.add_child(solid)
  var collider:=CollisionShape3D.new()
  collider.name="CollisionShape3D"
  collider.shape=shape
  solid.add_child(collider)
  installed+=1
 return installed

static func ground_hit(world:World3D,point:Vector3,up:float=0.9,down:float=3.5) -> Dictionary:
 var from:=point+Vector3.UP*up
 var to:=point-Vector3.UP*down
 var query:=PhysicsRayQueryParameters3D.create(from,to,WORLD_LAYER)
 query.hit_back_faces=true
 return world.direct_space_state.intersect_ray(query)

extends SceneTree
## World-space regressions for the original Blender map, not decorative planes.
func _initialize() -> void:
 call_deferred("_check_map")

func _fail(message:String) -> void:
 push_error("BANGKOK_MAP_QA_FAIL: "+message)
 quit(1)

func _check_map() -> void:
 if not ResourceLoader.exists("res://assets/maps/bangkok_map.glb"):
  _fail("Bangkok GLB was not imported")
  return
 var scene:PackedScene=load("res://scenes/main.tscn") as PackedScene
 if scene==null:
  _fail("Main scene missing")
  return
 var game:Node3D=scene.instantiate() as Node3D
 get_root().add_child(game)
 await process_frame
 var city:Node3D=game.get_node_or_null("BangkokCityMap") as Node3D
 if city==null or city.get_child_count()==0:
  _fail("Bangkok city missing from live game")
  return
 var collisions:Array[Node]=get_nodes_in_group("bangkok_world_collision")
 if collisions.size()<60 or int(game.world_collision_count)!=collisions.size():
  _fail("Not enough real city mesh colliders: "+str(collisions.size()))
  return
 if game.has_node("BangkokGroundCollision") or game.has_node("PrototypeFallbackGround"):
  _fail("The old flat collision slab is still masking hills and stairs")
  return
 for body in collisions:
  if not (body is StaticBody3D):
   _fail("A city collider is not a StaticBody3D")
   return
  var solid:StaticBody3D=body as StaticBody3D
  var collision:CollisionShape3D=solid.get_node_or_null("CollisionShape3D") as CollisionShape3D
  if collision==null or not (collision.shape is ConcavePolygonShape3D) or solid.collision_layer!=1:
   _fail("Building/floor lacks true concave mesh collider: "+body.name)
   return
 await physics_frame
 # The real mesh has significantly different elevations at these locations.
 var origin_hit:Dictionary=game._ground_surface_at(0.0,0.0,0.0)
 var road_hit:Dictionary=game._ground_surface_at(3.0,-13.0,0.0)
 if origin_hit.is_empty() or road_hit.is_empty():
  _fail("Physical raycasts cannot find the real ground at street level")
  return
 var street:Vector3=origin_hit["position"]
 var lower:Vector3=road_hit["position"]
 if absf(street.y)>0.16 or not (lower.y<street.y-0.45 and lower.y>street.y-1.25):
  _fail("Street and lower slope have lost their original height difference")
  return
 var hero:CharacterBody3D=game.character
 var collider:CollisionShape3D=hero.get_node("CollisionShape3D") as CollisionShape3D
 if not (collider.shape is CapsuleShape3D):
  _fail("Player physical capsule missing")
  return
 if not is_equal_approx((collider.shape as CapsuleShape3D).height,0.525):
  _fail("Quarter-size character collision height incorrect")
  return
 if not is_equal_approx(game.training_target.scale.x,0.25):
  _fail("NPC body was not reduced another 50 percent")
  return
 print("BANGKOK_MAP_QA_OK: ",collisions.size(),
  " accurate 3D mesh colliders; street Y=",street.y,
  " lower-road Y=",lower.y,"; quarter-size player and NPC")
 game.queue_free()
 await process_frame
 quit()

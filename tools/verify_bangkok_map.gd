extends SceneTree

func _initialize() -> void:
 call_deferred("_check_map")

func _check_map() -> void:
 if not ResourceLoader.exists("res://assets/maps/bangkok_map.glb"):
  push_error("Bangkok GLB not imported")
  quit(1)
  return
 var scene: PackedScene = load("res://scenes/main.tscn") as PackedScene
 if scene == null:
  push_error("Main scene missing")
  quit(1)
  return
 var game: Node3D = scene.instantiate() as Node3D
 if game == null:
  push_error("Main scene is not Node3D")
  quit(1)
  return
 get_root().add_child(game)
 await process_frame
 var city: Node3D = game.get_node_or_null("BangkokCityMap") as Node3D
 var ground: CollisionShape3D = game.get_node_or_null("BangkokGroundCollision/CollisionShape3D") as CollisionShape3D
 var character: CharacterBody3D = game.get("character") as CharacterBody3D
 if city == null or city.get_child_count() == 0:
  push_error("Bangkok city was not instantiated")
  quit(1)
  return
 if ground == null or ground.shape == null or ground.disabled:
  push_error("Walkable ground collision missing")
  quit(1)
  return
 if character == null or character.position.distance_to(Vector3(0,1.1*0.50,0)) > 0.2:
  push_error("Player was not placed at the new Bangkok spawn")
  quit(1)
  return
 print("BANGKOK_MAP_QA_OK: map loaded, street spawn active, StaticBody3D ground present")
 quit()

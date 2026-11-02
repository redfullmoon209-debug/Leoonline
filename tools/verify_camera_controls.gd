extends SceneTree
## Deterministic headless regression for real RMB/touch camera input and city scale.
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
 call_deferred("_validate")
 call_deferred("_watchdog")

func _watchdog() -> void:
 await create_timer(35.0).timeout
 push_error("BANGKOK_CAMERA_QA_TIMEOUT: camera validation never finished")
 quit(1)

func _check(ok:bool, reason:String) -> void:
 checks+=1
 if not ok:
  failures.append(reason)

func _validate() -> void:
 root.size=Vector2i(1280,720)
 var game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 print("BANGKOK_CAMERA_QA_STAGE: SCENE_READY")
 var hero_shape:CollisionShape3D=game.character.get_node("CollisionShape3D") as CollisionShape3D
 var female:Node3D=game.character.get_node("FemalePlayerVisual") as Node3D
 _check(hero_shape.shape is CapsuleShape3D and is_equal_approx((hero_shape.shape as CapsuleShape3D).height,1.05),
  "Scaled player's physical capsule stays aligned with Bangkok ground")
 _check(is_equal_approx(float(female.get("target_height_m")),0.81) and is_equal_approx(game.training_target.scale.x,0.50),
  "Player/monster world geometry uses the same 50% size factor")
 for target in game.test_targets:
  _check(is_equal_approx(target.scale.x,0.50),"All test NPCs and monsters are scaled: "+target.name)
 _check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"Desktop pointer is not captured permanently")
 _check(is_equal_approx(game.camera.position.z,5.4),"Follow camera starts with street-friendly zoom")
 var original_yaw:float=game.camera_arm.rotation.y
 var original_pitch:float=game.pitch
 var motion:=InputEventMouseMotion.new()
 motion.relative=Vector2(95,22)
 game._unhandled_input(motion)
 _check(is_equal_approx(original_yaw,game.camera_arm.rotation.y),
  "Moving the mouse WITHOUT RMB must never orbit")
 print("BANGKOK_CAMERA_QA_STAGE: MOUSE_CHECK")
 var mouse_down:=InputEventMouseButton.new()
 mouse_down.button_index=MOUSE_BUTTON_RIGHT
 mouse_down.pressed=true
 game._unhandled_input(mouse_down)
 game._unhandled_input(motion)
 _check(game.camera_dragging and absf(game.camera_arm.rotation.y-original_yaw)>0.10
  and not is_equal_approx(game.pitch,original_pitch),
  "Holding RMB and dragging orbits horizontally and vertically")
 var mouse_up:=InputEventMouseButton.new()
 mouse_up.button_index=MOUSE_BUTTON_RIGHT
 mouse_up.pressed=false
 game._input(mouse_up)
 var stopped_yaw:float=game.camera_arm.rotation.y
 game._unhandled_input(motion)
 _check(not game.camera_dragging and is_equal_approx(stopped_yaw,game.camera_arm.rotation.y),
  "Releasing RMB preserves the exact last orbit angle")
 print("BANGKOK_CAMERA_QA_STAGE: TOUCH_CHECK")
 var start:=InputEventScreenTouch.new()
 start.index=0
 start.pressed=true
 start.position=Vector2(345,416)
 game._unhandled_input(start)
 var drag:=InputEventScreenDrag.new()
 drag.index=0
 drag.position=Vector2(401,440)
 game._unhandled_input(drag)
 _check(game.camera_touches.size()==1 and not is_equal_approx(stopped_yaw,game.camera_arm.rotation.y),
  "One world-space finger rotates the mobile camera")
 print("BANGKOK_CAMERA_QA_STAGE: PINCH_CHECK")
 var second:=InputEventScreenTouch.new()
 second.index=1
 second.pressed=true
 second.position=Vector2(550,440)
 game._unhandled_input(second)
 var old_zoom:float=game.camera_distance
 var spread:=InputEventScreenDrag.new()
 spread.index=1
 spread.position=Vector2(645,440)
 game._unhandled_input(spread)
 _check(game.camera_touches.size()==2 and game.camera_distance<old_zoom,
  "Two fingers spreading must zoom camera in")
 var zoomed_in:float=game.camera_distance
 spread.position=Vector2(500,440)
 game._unhandled_input(spread)
 _check(game.camera_distance>zoomed_in,"Two fingers closing together must zoom camera out")
 start.pressed=false
 second.pressed=false
 game._input(start)
 game._input(second)
 _check(game.camera_touches.is_empty(),"All touch pointers release cleanly")
 game._camera_zoom(0.01)
 _check(is_equal_approx(game.camera_distance,2.2),"Pinch cannot cross minimum zoom")
 game._camera_zoom(99.0)
 _check(is_equal_approx(game.camera_distance,18.0),"Pinch cannot cross maximum zoom")
 game.open=true
 var modal_angle:float=game.camera_arm.rotation.y
 game._camera_rotate(Vector2(400,400),true)
 _check(is_equal_approx(modal_angle,game.camera_arm.rotation.y),
  "Opening inventory blocks camera rotation")
 game.open=false
 print("BANGKOK_CAMERA_QA_STAGE: FINISH_CHECK")
 game.queue_free()
 await process_frame
 for failure in failures:
  push_error("CAMERA QA FAIL: "+failure)
 if failures.is_empty():
  print("BANGKOK_CAMERA_QA_OK ",checks," checks: scaled actors, RMB hold/release, touch drag, pinch, zoom bounds, UI block")
 quit(0 if failures.is_empty() else 1)

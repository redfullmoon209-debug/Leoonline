extends Node3D
const StoreScript = preload("res://scripts/store.gd")
var store: Node
var character: CharacterBody3D
var camera_arm: Node3D
var camera: Camera3D
var hud: CanvasLayer
var inventory: PanelContainer
var grid: GridContainer
var equip_grid: GridContainer
var money_box: VBoxContainer
var page_label: Label
var capacity_label: Label
var notice_label: Label
var page := 0
var open := false
var pitch := -0.2
var loot: Array[Area3D] = []
var trash_dialog: ConfirmationDialog
var hud_menu: Control
var training_target: StaticBody3D

func _ready() -> void:
 _register_keys()
 store = StoreScript.new()
 add_child(store)
 store.changed.connect(_refresh)
 store.notice.connect(_notice)
 _make_world()
 _make_character()
 _make_training_target()
 _make_ui()
 var ui911: Node = load("res://scripts/ui911.gd").new()
 add_child(ui911)
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if OS.has_feature("web") else Input.MOUSE_MODE_CAPTURED
 if OS.has_feature("web") and "--inventory-qa" in OS.get_cmdline_user_args():
  add_child(load("res://scripts/web_ui_probe.gd").new())

func _register_keys() -> void:
 var keys := {"forward":[KEY_W,KEY_UP],"back":[KEY_S,KEY_DOWN],"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE],"run":[KEY_SHIFT],"bag":[KEY_B],"pickup":[KEY_E],"target":[KEY_T]}
 for action in keys:
  InputMap.add_action(action)
  for code in keys[action]:
   var event := InputEventKey.new()
   event.physical_keycode = code
   InputMap.action_add_event(action,event)

func _mat(c: Color) -> StandardMaterial3D:
 var material := StandardMaterial3D.new()
 material.albedo_color = c
 return material

func _box(pos: Vector3, size: Vector3, color: Color) -> void:
 var body := StaticBody3D.new()
 body.position = pos
 add_child(body)
 var mesh := MeshInstance3D.new()
 var bm := BoxMesh.new()
 bm.size = size
 mesh.mesh = bm
 mesh.material_override = _mat(color)
 body.add_child(mesh)
 var col := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = size
 col.shape = shape
 body.add_child(col)

func _make_world() -> void:
 var world := WorldEnvironment.new()
 var env := Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color("80b4d8")
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color.WHITE
 world.environment = env
 add_child(world)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-45,-25,0)
 add_child(sun)
 _box(Vector3(0,-0.5,0),Vector3(80,1,80),Color("47735d"))
 for x in range(-3,4):
  for z in range(-3,4):
   if (x+z)%3 == 0:
    _box(Vector3(x*7,0.3,z*7-12),Vector3(2,0.6,2),Color("7b93a0"))
 _spawn_loot("sword",Vector3(-3,0.65,0),Color.GOLD)
 _spawn_loot("boots",Vector3(3,0.65,0),Color.DEEP_SKY_BLUE)
 _spawn_loot("potion",Vector3(0,0.65,-5),Color.HOT_PINK)
 _spawn_loot("scroll",Vector3(-4,0.65,-5),Color.MEDIUM_PURPLE)
 _spawn_loot("shirt",Vector3(5,0.65,-4),Color.WHITE)

func _spawn_loot(id: String,pos: Vector3,color: Color) -> void:
 var item := Area3D.new()
 item.position = pos
 item.set_meta("id",id)
 var mesh := MeshInstance3D.new()
 mesh.mesh = SphereMesh.new()
 mesh.scale = Vector3(0.4,0.4,0.4)
 mesh.material_override = _mat(color)
 item.add_child(mesh)
 var label := Label3D.new()
 label.text = id + " [E]"
 label.position.y = 1.0
 label.font_size = 36
 label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 item.add_child(label)
 add_child(item)
 loot.append(item)

func _make_character() -> void:
 character = CharacterBody3D.new()
 character.position = Vector3(0,1.1,5)
 add_child(character)
 var col := CollisionShape3D.new()
 var shape := CapsuleShape3D.new()
 shape.height = 2.1
 shape.radius = 0.35
 col.shape = shape
 character.add_child(col)
 var mesh := MeshInstance3D.new()
 var body := CapsuleMesh.new()
 body.height = 1.6
 body.radius = 0.35
 mesh.mesh = body
 mesh.material_override = _mat(Color("4bb9ec"))
 character.add_child(mesh)
 camera_arm = Node3D.new()
 add_child(camera_arm)
 camera = Camera3D.new()
 camera.position = Vector3(0,2.0,6.5)
 camera.current = true
 camera_arm.add_child(camera)

func _make_training_target() -> void:
 # An actual selectable entity so that the HP/MP portrait panel can display
 # live data rather than a fictional screenshot of a monster.
 training_target=StaticBody3D.new()
 training_target.name="TrainingStoneGolem"
 training_target.position=Vector3(3.0,1.35,-8.0)
 training_target.set_meta("target_name","อสูรหินฝึก")
 training_target.set_meta("target_type","Monster")
 training_target.set_meta("level",12)
 training_target.set_meta("hp",3240.0)
 training_target.set_meta("max_hp",3240.0)
 training_target.set_meta("mp",670.0)
 training_target.set_meta("max_mp",670.0)
 training_target.set_meta("target_portrait","res://assets/ui/hud/target_training_golem.svg")
 add_child(training_target)
 var hit:=CollisionShape3D.new()
 hit.name="TargetHitbox"
 var hitbox:=BoxShape3D.new()
 hitbox.size=Vector3(1.4,2.45,1.05)
 hit.shape=hitbox
 training_target.add_child(hit)
 var torso:=MeshInstance3D.new()
 torso.name="GolemStoneArmor"
 var torso_mesh:=BoxMesh.new()
 torso_mesh.size=Vector3(1.15,1.35,0.85)
 torso.mesh=torso_mesh
 torso.material_override=_mat(Color("#5c7182"))
 torso.position=Vector3(0.0,-0.1,0.0)
 training_target.add_child(torso)
 var head:=MeshInstance3D.new()
 head.name="GolemHead"
 var head_mesh:=SphereMesh.new()
 head_mesh.radius=0.45
 head_mesh.height=0.82
 head.mesh=head_mesh
 head.material_override=_mat(Color("#b2bfc9"))
 head.position=Vector3(0.0,0.8,0.0)
 training_target.add_child(head)
 for x in [-0.18,0.18]:
  var eye:=MeshInstance3D.new()
  var orb:=SphereMesh.new()
  orb.radius=0.09
  orb.height=0.16
  eye.mesh=orb
  eye.material_override=_mat(Color("#41d8f8"))
  eye.position=Vector3(x,0.85,0.38)
  training_target.add_child(eye)
 var crest:=MeshInstance3D.new()
 var crest_mesh:=SphereMesh.new()
 crest_mesh.radius=0.15
 crest_mesh.height=0.24
 crest.mesh=crest_mesh
 crest.material_override=_mat(Color("#ead17b"))
 crest.position=Vector3(0,1.3,0)
 training_target.add_child(crest)
 var tag:=Label3D.new()
 tag.name="TrainingTargetHint"
 tag.text="อสูรหินฝึก Lv.12 [T]"
 tag.position.y=1.85
 tag.font_size=31
 tag.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 training_target.add_child(tag)

func _toggle_target_lock() -> void:
 if not is_instance_valid(hud_menu) or not is_instance_valid(training_target):return
 if hud_menu.is_gameplay_blocked():return
 if hud_menu.top_status.current_target==training_target:
  hud_menu.clear_target()
 elif character.global_position.distance_to(training_target.global_position)<30.0:
  hud_menu.set_target(training_target)

func _select_target_at(screen_point: Vector2) -> bool:
 if not is_instance_valid(hud_menu) or hud_menu.is_gameplay_blocked():return false
 if not is_instance_valid(training_target):return false
 if character.global_position.distance_to(training_target.global_position)>=30.0:return false
 var ray_from:Vector3=camera.project_ray_origin(screen_point)
 var ray_to:Vector3=ray_from+camera.project_ray_normal(screen_point)*100.0
 var query:=PhysicsRayQueryParameters3D.create(ray_from,ray_to)
 var result:Dictionary=get_world_3d().direct_space_state.intersect_ray(query)
 if result.get("collider",null)!=training_target:return false
 hud_menu.set_target(training_target)
 return true

func _style(bg: String,border: String) -> StyleBoxFlat:
 var box := StyleBoxFlat.new()
 box.bg_color = Color(bg)
 box.border_color = Color(border)
 box.set_border_width_all(2)
 box.set_corner_radius_all(8)
 box.content_margin_left = 8
 box.content_margin_right = 8
 box.content_margin_top = 6
 box.content_margin_bottom = 6
 return box

func _button(label: String,call: Callable,parent: Node) -> Button:
 var b := Button.new()
 b.text = label
 b.add_theme_stylebox_override("normal",_style("#102e52","#43b5e9"))
 b.add_theme_stylebox_override("hover",_style("#225685","#f4ca70"))
 b.add_theme_color_override("font_color",Color.WHITE)
 b.add_theme_font_size_override("font_size",14)
 b.pressed.connect(call)
 parent.add_child(b)
 return b

func _text(label: String,parent: Node,sz: int=16) -> Label:
 var l := Label.new()
 l.text = label
 l.add_theme_font_size_override("font_size",sz)
 l.add_theme_color_override("font_color",Color("#e9f2ff"))
 parent.add_child(l)
 return l

func _make_ui() -> void:
 hud = CanvasLayer.new()
 add_child(hud)
 inventory = load("res://scripts/inventory_ui.gd").new() as PanelContainer
 hud.add_child(inventory)
 inventory.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 inventory.call("initialize",store,Callable(self,"_toggle"),Callable(self,"_starter"))
 inventory.visible = false
 # A real touch target is required to open the bag without a keyboard.
 var bag_button := TextureButton.new()
 bag_button.name = "OpenInventory"
 bag_button.texture_normal = load("res://assets/ui/inventory/icon_inventory.png")
 bag_button.ignore_texture_size = true
 bag_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
 bag_button.custom_minimum_size = Vector2(56,56)
 bag_button.tooltip_text = "กระเป๋า / Inventory [B]"
 hud.add_child(bag_button)
 bag_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 bag_button.position = Vector2(get_viewport().get_visible_rect().size.x-72,16)
 bag_button.size = Vector2(56,56)
 bag_button.pressed.connect(_toggle)
 inventory.visibility_changed.connect(func():
  bag_button.visible = not inventory.visible
 )
 # Keep existing Inventory texture untouched; all other HUD icon assets are
 # freshly-authored SVGs. A single HUD manager owns saved drag/resize geometry.
 hud_menu = load("res://scripts/hud_menu.gd").new() as Control
 hud_menu.name = "WorldHUDMenu"
 hud.add_child(hud_menu)
 hud_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 hud_menu.call("initialize",self,store,inventory,bag_button)
 get_viewport().size_changed.connect(func():
  if is_instance_valid(hud_menu): hud_menu.call("_reflow")
 )

func _starter() -> void:
 for id in ["sword","shirt","boots","potion","scroll","wood","fashion_blade","fashion_dagger","fashion_mask","fashion_cape"]:
  store.add_item(id)
 store.add_currency("gold","1200")

func _notice(message: String) -> void:
 if is_instance_valid(inventory) and inventory.has_method("set_notice"):
  inventory.call("set_notice",message)

func _refresh() -> void:
 if is_instance_valid(inventory) and inventory.has_method("refresh"):
  inventory.call("refresh")

func _toggle() -> void:
 if is_instance_valid(hud_menu) and hud_menu.edit_mode: return
 if is_instance_valid(hud_menu) and hud_menu.popup.visible: hud_menu.call("_hide_popup")
 open = not open
 if open:
  inventory.call("_switch_tab",0)
 inventory.visible = open
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open or OS.has_feature("web") or DisplayServer.is_touchscreen_available() else Input.MOUSE_MODE_CAPTURED

func _collect_nearest() -> void:
 if open or (is_instance_valid(hud_menu) and hud_menu.is_gameplay_blocked()): return
 var nearest: Area3D
 var distance: float=3.0
 for item in loot:
  if is_instance_valid(item) and item.global_position.distance_to(character.global_position)<distance:
   nearest=item
   distance=item.global_position.distance_to(character.global_position)
 if nearest != null:
  var item_id: String=str(nearest.get_meta("id"))
  if store.add_item(item_id):
   loot.erase(nearest)
   nearest.queue_free()
   if is_instance_valid(hud_menu): hud_menu.call("record_pickup",item_id)

func _physics_process(delta: float) -> void:
 var blocked: bool=open or (is_instance_valid(hud_menu) and hud_menu.is_gameplay_blocked())
 var touch_jump: bool=false
 if is_instance_valid(hud_menu): touch_jump=bool(hud_menu.call("consume_jump"))
 var vel: Vector3=character.velocity
 if not character.is_on_floor():
  vel.y-=19.6*delta
 elif (Input.is_action_just_pressed("jump") or touch_jump) and not blocked:
  vel.y=7.5
 var v: Vector2=Vector2.ZERO if blocked else Input.get_vector("left","right","forward","back")
 if not blocked and is_instance_valid(hud_menu):
  var touch_move: Vector2=hud_menu.call("get_movement_vector")
  if touch_move.length()>0.08: v=touch_move
 var dir: Vector3=camera_arm.global_basis.x*v.x+camera_arm.global_basis.z*v.y
 dir.y=0
 dir=dir.normalized()
 var sprinting: bool=Input.is_action_pressed("run") or (is_instance_valid(hud_menu) and hud_menu.run_pressed)
 var speed: float=8.0 if sprinting else 5.0
 vel.x=dir.x*speed
 vel.z=dir.z*speed
 character.velocity=vel
 character.move_and_slide()
 camera_arm.global_position=character.global_position+Vector3(0,0.5,0)

func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("target") and not event.is_echo():
  _toggle_target_lock()
  get_viewport().set_input_as_handled()
 elif event is InputEventScreenTouch and event.pressed:
  if _select_target_at(event.position):get_viewport().set_input_as_handled()
 elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE:
  if _select_target_at(event.position):get_viewport().set_input_as_handled()
 elif event.is_action_pressed("bag") and not event.is_echo():
  if not is_instance_valid(hud_menu) or not hud_menu.edit_mode: _toggle()
  get_viewport().set_input_as_handled()
 elif event.is_action_pressed("pickup") and not open and not event.is_echo():
  _collect_nearest()
 elif event is InputEventMouseButton and event.pressed and not open and not DisplayServer.is_touchscreen_available():
  if not is_instance_valid(hud_menu) or (not hud_menu.is_gameplay_blocked() and hud_menu.size.x>=600.0 and not hud_menu.force_touch_preview):
   # Keep mouse pointer usable for landscape-test mobile controls,
   # even when a landscape viewport is wider than 600 pixels.
   Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
 elif event is InputEventMouseMotion and not open and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
  if not is_instance_valid(hud_menu) or not hud_menu.is_gameplay_blocked():
   var sensitivity: float=hud_menu.camera_sensitivity if is_instance_valid(hud_menu) else 0.003
   camera_arm.rotation.y-=event.relative.x*sensitivity
   pitch=clampf(pitch-event.relative.y*sensitivity,-0.7,0.5)
   camera.rotation.x=pitch
 elif event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  if open: _toggle()
  elif is_instance_valid(hud_menu) and hud_menu.is_gameplay_blocked():
   if hud_menu.edit_mode: hud_menu.call("_finish_edit",false)
   else: hud_menu.call("_hide_popup")
  else: Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

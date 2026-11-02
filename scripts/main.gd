extends Node3D
const RedButtonStyle = preload("res://scripts/ui_button_style.gd")
const StoreScript = preload("res://scripts/store.gd")
# World-scale actor height: map buildings and roads are substantially smaller than the original 80m prototype.
const ACTOR_SCALE: float = 0.50
var store: Node
var character: CharacterBody3D
var player_placeholder: MeshInstance3D
var player_female_enabled: bool = true
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
var pitch: float = -0.29
var camera_distance: float = 5.4
const CAMERA_MIN_DISTANCE: float = 2.2
const CAMERA_MAX_DISTANCE: float = 18.0
var camera_dragging: bool = false
var camera_touches: Dictionary = {}
var camera_pinch_distance: float = 0.0
var loot: Array[Area3D] = []
var trash_dialog: ConfirmationDialog
var hud_menu: Control
var training_target: StaticBody3D
var test_targets: Array[StaticBody3D]=[]
var additional_test_targets: Array[StaticBody3D]=[]
var test_spawn_count: int=0
# A physical touchscreen tap may arrive as mouse THEN touch, or the
# reverse, depending on browser. Deduplicate only cross-source input;
# two separate touches (or two mouse clicks) must still lock/unlock.
var last_target_pointer_msec: int = -10000
var last_target_pointer_position: Vector2 = Vector2(-1000.0,-1000.0)
var last_target_pointer_kind: int = 0
var gm_menu: Control
var combat:Node
var novice_touch_bar:Control

func _ready() -> void:
 _register_keys()
 store = StoreScript.new()
 add_child(store)
 store.changed.connect(_refresh)
 store.notice.connect(_notice)
 _make_world()
 _make_character()
 _make_training_target()
 _make_demo_targets()
 # Local Novice combat is initialized before HUD, so the original status
 # cards and skill hotbar may observe real health, stamina and cooldowns.
 combat=load("res://scripts/novice_combat.gd").new()
 combat.name="NoviceCombat"
 add_child(combat)
 combat.initialize(self,store)
 store.novice_combat=combat
 _make_ui()
 var ui911: Node = load("res://scripts/ui911.gd").new()
 add_child(ui911)
 # Pointer always stays visible. RMB dragging rotates; releasing RMB keeps the exact angle.
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
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
 # The Bangkok map is reconstructed from the owner's .blend before Godot imports it.
 # Its geometry is at 1:10 scale; original road Z=26.7 becomes Godot ground Y=0.
 var map_path := "res://assets/maps/bangkok_map.glb"
 if ResourceLoader.exists(map_path):
  var packed_map: PackedScene = load(map_path) as PackedScene
  if packed_map != null:
   var city: Node3D = packed_map.instantiate() as Node3D
   if city != null:
    city.name = "BangkokCityMap"
    add_child(city)
 # Keep one reliable, broad collision floor even before detailed city collisions.
 # This is an actual StaticBody3D, not a visual-only mesh.
 var ground := StaticBody3D.new()
 ground.name = "BangkokGroundCollision"
 ground.position = Vector3(0.0,-0.5,0.0)
 add_child(ground)
 var ground_collision := CollisionShape3D.new()
 ground_collision.name = "CollisionShape3D"
 var ground_shape := BoxShape3D.new()
 ground_shape.size = Vector3(210.0,1.0,245.0)
 ground_collision.shape = ground_shape
 ground.add_child(ground_collision)
 var terrain := MeshInstance3D.new()
 terrain.name = "BangkokWalkableTerrain"
 var plane := PlaneMesh.new()
 plane.size = Vector2(210.0,245.0)
 terrain.mesh = plane
 terrain.position.y = -0.04
 terrain.material_override = _mat(Color("405a47"))
 add_child(terrain)
 if not has_node("BangkokCityMap"):
  # Local fallback for environments where the map has not yet been reconstructed.
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
 character.position = Vector3(0,1.1*ACTOR_SCALE,0) if has_node("BangkokCityMap") else Vector3(0,1.1*ACTOR_SCALE,5)
 character.set_meta("world_actor_scale",ACTOR_SCALE)
 add_child(character)
 var col := CollisionShape3D.new()
 col.name = "CollisionShape3D"
 var shape := CapsuleShape3D.new()
 shape.height = 2.1*ACTOR_SCALE
 shape.radius = 0.35*ACTOR_SCALE
 col.shape = shape
 character.add_child(col)
 var mesh := MeshInstance3D.new()
 var body := CapsuleMesh.new()
 body.height = 1.6*ACTOR_SCALE
 body.radius = 0.35*ACTOR_SCALE
 mesh.mesh = body
 mesh.material_override = _mat(Color("4bb9ec"))
 character.add_child(mesh)
 player_placeholder = mesh
 # Replace the placeholder capsule with an actual rigged female visual.
 # The collision capsule stays as a physics-only controller.
 var female_visual := load("res://scripts/female_character_visual.gd").new() as Node3D
 female_visual.name = "FemalePlayerVisual"
 # Scale the actual rig before it enters the scene, keeping its feet aligned
 # with the smaller physical capsule (not a visual-only floating avatar).
 female_visual.set("target_height_m",1.62*ACTOR_SCALE)
 female_visual.set("feet_y",-1.05*ACTOR_SCALE)
 character.add_child(female_visual)
 # Enable the real female model by default once it has been imported.
 # The GM test menu can switch back to the old placeholder on demand.
 set_female_character_enabled(true)
 camera_arm = Node3D.new()
 camera_arm.name = "OrbitCameraPivot"
 camera_arm.rotation.x = pitch
 add_child(camera_arm)
 camera = Camera3D.new()
 camera.name = "OrbitCamera"
 camera.position = Vector3(0,0,camera_distance)
 camera.current = true
 camera_arm.add_child(camera)

func set_female_character_enabled(enabled: bool) -> bool:
 if not is_instance_valid(character):
  return false
 var model: Node3D = character.get_node_or_null("FemalePlayerVisual") as Node3D
 if model == null:
  return false
 var ready: bool = model.get("visual_loaded") == true
 if enabled and not ready:
  return false
 player_female_enabled = enabled and ready
 model.visible = player_female_enabled
 if is_instance_valid(player_placeholder):
  player_placeholder.visible = not player_female_enabled
 return true

func _make_training_target() -> void:
 # An actual selectable entity so that the HP/MP portrait panel can display
 # live data rather than a fictional screenshot of a monster.
 training_target=StaticBody3D.new()
 training_target.name="TrainingStoneGolem"
 # Place the training golem far enough from the new Bangkok road spawn
 # to keep the ATK chase/stop regression realistic and deterministic.
 training_target.position=Vector3(3.0,1.35*ACTOR_SCALE,-13.0)
 training_target.scale=Vector3.ONE*ACTOR_SCALE
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
 test_targets.append(training_target)

func _build_test_entity(
 key: String,caption: String,kind: String,level: int,
 health: float,mana: float,location: Vector3,
 picture_path: String,body_color: Color
) -> StaticBody3D:
 var target:=StaticBody3D.new()
 target.name=key
 # Scale the complete entity: art, target collider and over-head label stay aligned.
 target.position=Vector3(location.x,(1.05 if kind=="player" else (0.60 if kind=="slime" else 0.65))*ACTOR_SCALE,location.z)
 target.scale=Vector3.ONE*ACTOR_SCALE
 target.set_meta("test_target",true)
 target.set_meta("target_name",caption)
 target.set_meta("target_type","Player Bot" if kind=="player" else "Monster")
 target.set_meta("level",level)
 target.set_meta("hp",health)
 target.set_meta("max_hp",health)
 target.set_meta("mp",mana)
 target.set_meta("max_mp",mana)
 target.set_meta("target_portrait",picture_path)
 add_child(target)
 var collision:=CollisionShape3D.new()
 collision.name="ClickableTargetCollider"
 if kind=="slime":
  var ball:=SphereShape3D.new()
  ball.radius=0.6
  collision.shape=ball
 elif kind=="wolf":
  var wolf_box:=BoxShape3D.new()
  wolf_box.size=Vector3(1.2,1.3,0.9)
  collision.shape=wolf_box
 else:
  var capsule:=CapsuleShape3D.new()
  capsule.radius=0.4
  capsule.height=2.0
  collision.shape=capsule
 target.add_child(collision)
 var body:=MeshInstance3D.new()
 body.name="SelectableEntityBody"
 if kind=="slime":
  var slime_mesh:=SphereMesh.new()
  slime_mesh.radius=0.57
  slime_mesh.height=1.12
  body.mesh=slime_mesh
 elif kind=="wolf":
  var wolf_mesh:=BoxMesh.new()
  wolf_mesh.size=Vector3(1.15,0.9,0.7)
  body.mesh=wolf_mesh
 else:
  var humanoid:=CapsuleMesh.new()
  humanoid.radius=0.36
  humanoid.height=1.35
  body.mesh=humanoid
  body.position.y=-0.17
 body.material_override=_mat(body_color)
 target.add_child(body)
 # Do not allocate an unattached MeshInstance3D for slime. An orphaned
 # rendering RID would leak at Godot shutdown even if its mesh is unused.
 if kind!="slime":
  var head:=MeshInstance3D.new()
  head.name="Head"
  var head_shape:=SphereMesh.new()
  head_shape.radius=0.30 if kind=="player" else 0.27
  head_shape.height=0.59 if kind=="player" else 0.50
  head.mesh=head_shape
  head.position.y=0.72 if kind=="player" else 0.44
  head.material_override=_mat(Color("#f2cba8") if kind=="player" else Color("#c0bfce"))
  target.add_child(head)
 if kind=="player":
  var hair:=MeshInstance3D.new()
  hair.name="HairOrHelmet"
  var crown:=SphereMesh.new()
  crown.radius=0.33
  crown.height=0.26
  hair.mesh=crown
  hair.position.y=1.02
  hair.material_override=_mat(Color("#393459"))
  target.add_child(hair)
 if kind=="wolf":
  for x in [-0.27,0.27]:
   var ear:=MeshInstance3D.new()
   var ear_mesh:=BoxMesh.new()
   ear_mesh.size=Vector3(0.17,0.34,0.18)
   ear.mesh=ear_mesh
   ear.position=Vector3(x,0.81,0.0)
   ear.material_override=_mat(Color("#76849d"))
   target.add_child(ear)
 for x in [-0.15,0.15]:
  var eye:=MeshInstance3D.new()
  eye.name="GlowingEye"
  var eye_mesh:=SphereMesh.new()
  eye_mesh.radius=0.08
  eye_mesh.height=0.14
  eye.mesh=eye_mesh
  eye.position=Vector3(x,0.30 if kind=="slime" else (0.76 if kind=="player" else 0.45),0.53 if kind=="slime" else (0.26 if kind=="player" else 0.35))
  eye.material_override=_mat(Color("#95fff4") if kind=="slime" else Color("#ffbd7b"))
  target.add_child(eye)
 var title:=Label3D.new()
 title.name="TargetNameInWorld"
 title.text=caption+"  Lv."+str(level)
 title.position.y=1.16 if kind=="slime" else 1.57
 title.font_size=34
 title.billboard=BaseMaterial3D.BILLBOARD_ENABLED
 target.add_child(title)
 test_targets.append(target)
 return target

func _make_demo_targets() -> void:
 _build_test_entity(
  "TestGreenSlime","สไลม์มรกต","slime",4,430.0,80.0,
  Vector3(-3.2,1.1,-4.0),"res://assets/ui/hud/target_slime.svg",Color("#35ce91"))
 _build_test_entity(
  "TestNightWolf","หมาป่าทมิฬ","wolf",9,1760.0,260.0,
  Vector3(5.3,1.1,-4.0),"res://assets/ui/hud/target_wolf.svg",Color("#5d688a"))
 _build_test_entity(
  "TestPlayerAster","Aster [BOT]","player",16,2400.0,1200.0,
  Vector3(-5.2,1.1,0.2),"res://assets/ui/hud/target_bot_male.svg",Color("#487cb7"))
 _build_test_entity(
  "TestPlayerLuna","Luna [BOT]","player",24,3800.0,2250.0,
  Vector3(5.3,1.1,0.3),"res://assets/ui/hud/target_bot_female.svg",Color("#9c57ab"))
 # Visual replacement for female test bot, preserving its HP, targeting,
 # world collision and the other demo entities.
 var luna: StaticBody3D = test_targets.back()
 if luna != null and luna.name == "TestPlayerLuna":
  for node in luna.get_children():
   if node is MeshInstance3D: node.visible = false
  var preview := load("res://scripts/female_character_visual.gd").new() as Node3D
  preview.name = "FemaleBotVisual"
  preview.set("feet_y", -1.05)
  luna.add_child(preview)
  if preview.get("visual_loaded") != true:
   for node in luna.get_children():
    if node is MeshInstance3D: node.visible = true

func _spawn_gm_test_entity(kind: String) -> StaticBody3D:
 if not is_instance_valid(gm_menu) or not gm_menu.active:return null
 if additional_test_targets.size()>=12:return null
 if kind!="player" and kind!="monster":return null
 test_spawn_count+=1
 var is_player:bool=kind=="player"
 var variant:String="player" if is_player else ("slime" if test_spawn_count%2==0 else "wolf")
 var nickname:String=("ผู้เล่นจำลอง %d [BOT]" if is_player else "มอนทดสอบ %d") % test_spawn_count
 var image:String="target_bot_male.svg" if is_player else ("target_slime.svg" if variant=="slime" else "target_wolf.svg")
 var x:float=-5.0+float(test_spawn_count%6)*2.0
 var z:float=character.global_position.z-7.0-float(test_spawn_count/6)*3.0
 var entity:StaticBody3D=_build_test_entity(
  "GMTestTarget"+str(test_spawn_count),nickname,variant,18 if is_player else 6,
  2100.0 if is_player else 900.0,950.0 if is_player else 150.0,
  Vector3(x,1.1,z),"res://assets/ui/hud/"+image,
  Color("#547bd0") if is_player else Color("#6ad0b3"))
 additional_test_targets.append(entity)
 return entity

func _set_test_target(entity:StaticBody3D) -> void:
 if not is_instance_valid(entity) or not test_targets.has(entity):return
 if is_instance_valid(hud_menu):hud_menu.set_target(entity)

func _reset_gm_test_entities() -> void:
 if not is_instance_valid(gm_menu) or not gm_menu.active:return
 if is_instance_valid(hud_menu):hud_menu.clear_target()
 for target in additional_test_targets:
  test_targets.erase(target)
  if is_instance_valid(target):target.queue_free()
 additional_test_targets.clear()
 for target in test_targets:
  if not is_instance_valid(target):continue
  if target.has_meta("max_hp"):target.set_meta("hp",target.get_meta("max_hp"))
  if target.has_meta("max_mp"):target.set_meta("mp",target.get_meta("max_mp"))
 if is_instance_valid(combat):combat.reset_training_targets()

func _toggle_target_lock() -> void:
 if not is_instance_valid(hud_menu) or hud_menu.is_gameplay_blocked():return
 # Both keyboard T and touch TARGET cancel ANY currently selected entity.
 var active:Node3D=hud_menu.top_status.current_target as Node3D
 if is_instance_valid(active):
  hud_menu.clear_target()
  return
 if is_instance_valid(training_target) and is_instance_valid(character):
  if character.global_position.distance_to(training_target.global_position)<30.0:
   hud_menu.set_target(training_target)

func _select_target_at(screen_point: Vector2) -> bool:
 if not is_instance_valid(hud_menu) or hud_menu.is_gameplay_blocked():return false
 var ray_from:Vector3=camera.project_ray_origin(screen_point)
 var ray_to:Vector3=ray_from+camera.project_ray_normal(screen_point)*100.0
 var query:=PhysicsRayQueryParameters3D.create(ray_from,ray_to)
 var result:Dictionary=get_world_3d().direct_space_state.intersect_ray(query)
 var selected:StaticBody3D=result.get("collider",null) as StaticBody3D
 if not is_instance_valid(selected) or not test_targets.has(selected):return false
 if character.global_position.distance_to(selected.global_position)>30.0:return false
 # Retapping a selected physical target unlocks it; another one switches.
 if hud_menu.top_status.current_target==selected:
  hud_menu.clear_target()
 else:
  hud_menu.set_target(selected)
 return true

func _target_pointer_input(screen_point: Vector2,kind: int) -> bool:
 var elapsed:int=Time.get_ticks_msec()-last_target_pointer_msec
 if last_target_pointer_kind!=0 and last_target_pointer_kind!=kind:
  if elapsed>=0 and elapsed<450 and screen_point.distance_to(last_target_pointer_position)<28.0:
   # The browser's emulated event for the SAME physical tap. Do not
   # change lock state twice or cancel a fresh mobile target.
   return true
 if not _select_target_at(screen_point):return false
 last_target_pointer_msec=Time.get_ticks_msec()
 last_target_pointer_position=screen_point
 last_target_pointer_kind=kind
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
 RedButtonStyle.apply(b)
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
 novice_touch_bar=load("res://scripts/novice_touch_skills.gd").new() as Control
 novice_touch_bar.name="NoviceWorldSkillHotbar"
 hud.add_child(novice_touch_bar)
 novice_touch_bar.call("initialize",self,store,hud_menu)
 # GM remains a completely separate button. It exists only when the
 # opt-in landscape TEST page sets gm_test=1; it is not an online role.
 gm_menu=load("res://scripts/gm_test_panel.gd").new() as Control
 gm_menu.name="SeparateGMTestUI"
 hud.add_child(gm_menu)
 gm_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 gm_menu.call("initialize",self,hud_menu)
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
 # A temporary local training sword belongs to Novice only. GM previewing
 # different classes should not falsely display their unreleased weapons.
 if is_instance_valid(character):
  var female_visual:Node3D=character.get_node_or_null("FemalePlayerVisual") as Node3D
  if female_visual!=null and female_visual.has_method("set_training_sword_visible"):
   female_visual.call("set_training_sword_visible",str(store.effective_job_info().get("id","Novice"))=="Novice")
 if is_instance_valid(inventory) and inventory.has_method("refresh"):
  inventory.call("refresh")

func _toggle() -> void:
 if is_instance_valid(gm_menu) and gm_menu.is_open():gm_menu._close()
 if is_instance_valid(hud_menu) and hud_menu.edit_mode: return
 if is_instance_valid(hud_menu) and hud_menu.popup.visible: hud_menu.call("_hide_popup")
 open = not open
 if open:
  inventory.call("_switch_tab",0)
 inventory.visible = open
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

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
 var in_rush:bool=is_instance_valid(combat) and combat.rush_active
 var v:Vector2=Vector2.ZERO if blocked or in_rush else Input.get_vector("left","right","forward","back")
 if not blocked and is_instance_valid(hud_menu):
  var touch_move:Vector2=hud_menu.call("get_movement_vector")
  if touch_move.length()>0.08 and not in_rush:v=touch_move
 var manual_moving:bool=v.length_squared()>0.015
 # Player input takes priority: no forced auto-run against WASD/joystick.
 if is_instance_valid(combat):
  if blocked:combat.stop_auto_attack()
  elif manual_moving and not in_rush:combat.cancel_auto_for_manual_input()
 var auto_dir:Vector3=Vector3.ZERO
 if not blocked and not manual_moving and not in_rush and is_instance_valid(combat):
  auto_dir=combat.auto_run_direction()
 var auto_running:bool=auto_dir.length_squared()>0.01
 # Travel uses yaw only: tilting the camera must not change walking speed.
 var walking_basis:Basis=Basis(Vector3.UP,camera_arm.rotation.y)
 var dir:Vector3=walking_basis.x*v.x+walking_basis.z*v.y
 dir.y=0.0
 dir=auto_dir if auto_running else dir.normalized()
 var sprinting:bool=Input.is_action_pressed("run") or (is_instance_valid(hud_menu) and hud_menu.run_pressed) or auto_running
 var visual_direction:Vector3=dir
 if in_rush and is_instance_valid(combat.rush_target):
  visual_direction=combat.rush_target.global_position-character.global_position
  visual_direction.y=0.0
  visual_direction=visual_direction.normalized()
 var speed:float=8.0 if auto_running else (8.0 if sprinting else 5.0)
 vel.x=dir.x*speed
 vel.z=dir.z*speed
 character.velocity=vel
 # Auto-running uses exactly the same CharacterBody3D collision + slide
 # as ordinary movement, never teleporting or ignoring a blocked path.
 character.move_and_slide()
 if in_rush:combat.advance_rush(delta)
 if is_instance_valid(combat):combat.advance_auto_attack(delta,blocked)
 var female_visual:Node3D=character.get_node_or_null("FemalePlayerVisual") as Node3D
 if female_visual!=null and female_visual.visible and female_visual.has_method("animate_motion"):
  female_visual.call("animate_motion",visual_direction,sprinting or in_rush,delta)
  # Face a nearby locked target while STANDING, without falsely playing
  # the locomotion cycle when the sword is swinging in place.
  if is_instance_valid(combat) and combat.is_auto_attacking() and not auto_running and not manual_moving and not in_rush:
   var face:Vector3=combat.auto_target.global_position-character.global_position
   face.y=0.0
   if face.length_squared()>0.05:
    female_visual.rotation.y=lerp_angle(female_visual.rotation.y,atan2(-face.x,-face.z),clampf(delta*15.0,0.0,1.0))
 camera_arm.global_position=character.global_position+Vector3(0,0.2*ACTOR_SCALE,0)

func _cast_hotbar_slot(slot_index:int) -> bool:
 if slot_index<0 or slot_index>=3:return false
 if open or (is_instance_valid(hud_menu) and hud_menu.is_gameplay_blocked()):return false
 return bool(store.activate_hotbar_slot(slot_index))

func _normal_attack() -> bool:
 # ATK (or J) toggles auto-run + repeating real sword swings; it is NOT
 # skill slot 4, and still does not consume skill cooldown or stamina.
 if open or (is_instance_valid(hud_menu) and hud_menu.is_gameplay_blocked()):return false
 if not is_instance_valid(combat):return false
 return bool(combat.toggle_basic_auto_attack())

# The camera consumes only unhandled world-space gestures. Native HUD buttons,
# inventory, minimap and the movement joystick receive their own touches first.
func _camera_is_blocked() -> bool:
 return open or (is_instance_valid(hud_menu) and hud_menu.is_gameplay_blocked())

func _camera_rotate(delta:Vector2, touch:bool=false) -> void:
 if not is_instance_valid(camera_arm) or _camera_is_blocked():return
 var sensitivity:float=float(hud_menu.camera_sensitivity) if is_instance_valid(hud_menu) else 0.003
 if touch:sensitivity*=1.25
 camera_arm.rotation.y-=delta.x*sensitivity
 pitch=clampf(pitch-delta.y*sensitivity,-1.20,-0.055)
 camera_arm.rotation.x=pitch

func _camera_zoom(new_distance:float) -> void:
 camera_distance=clampf(new_distance,CAMERA_MIN_DISTANCE,CAMERA_MAX_DISTANCE)
 if is_instance_valid(camera):
  camera.position.z=camera_distance

func _camera_touch_distance() -> float:
 if camera_touches.size()!=2:return 0.0
 var positions:Array=camera_touches.values()
 return (positions[0] as Vector2).distance_to(positions[1] as Vector2)

func _camera_touch_start(index:int,point:Vector2) -> void:
 if camera_touches.has(index) or camera_touches.size()>=2:return
 camera_touches[index]=point
 camera_pinch_distance=_camera_touch_distance()

func _camera_touch_end(index:int) -> void:
 camera_touches.erase(index)
 camera_pinch_distance=_camera_touch_distance()

func _camera_touch_move(index:int,point:Vector2) -> bool:
 if not camera_touches.has(index) or _camera_is_blocked():return false
 var previous:Vector2=camera_touches[index]
 camera_touches[index]=point
 if camera_touches.size()==2:
  var next_distance:float=_camera_touch_distance()
  if next_distance>8.0 and camera_pinch_distance>8.0:
   # Fingers spread => smaller camera distance; fingers together => zoom out.
   _camera_zoom(camera_distance*camera_pinch_distance/next_distance)
  camera_pinch_distance=next_distance
 else:
  _camera_rotate(point-previous,true)
 return true

func _input(event:InputEvent) -> void:
 # Release gestures even if the cursor/finger finishes above a HUD control.
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and not event.pressed:
  camera_dragging=false
 elif event is InputEventScreenTouch and not event.pressed:
  _camera_touch_end(event.index)
 if _camera_is_blocked():
  camera_dragging=false
  camera_touches.clear()
  camera_pinch_distance=0.0

func _unhandled_input(event: InputEvent) -> void:
 # RMB is an explicit drag gesture, never permanent mouse capture.
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT:
  if event.pressed and not _camera_is_blocked():
   camera_dragging=true
   get_viewport().set_input_as_handled()
  else:
   camera_dragging=false
  return
 if event is InputEventMouseMotion and camera_dragging:
  _camera_rotate(event.relative)
  get_viewport().set_input_as_handled()
  return
 # Desktop mouse wheel is a companion to mobile pinch zoom.
 if event is InputEventMouseButton and event.pressed and not _camera_is_blocked():
  if event.button_index==MOUSE_BUTTON_WHEEL_UP:
   _camera_zoom(camera_distance*0.88)
   get_viewport().set_input_as_handled()
   return
  if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
   _camera_zoom(camera_distance*1.12)
   get_viewport().set_input_as_handled()
   return
 if event is InputEventScreenDrag:
  if _camera_touch_move(event.index,event.position):
   get_viewport().set_input_as_handled()
  return
 if event is InputEventScreenTouch:
  if event.pressed and not _camera_is_blocked():
   _camera_touch_start(event.index,event.position)
   if _target_pointer_input(event.position,1):
    get_viewport().set_input_as_handled()
  else:
   _camera_touch_end(event.index)
  return
 # Existing inputs: ordinary ATK, hotbar, target selection, inventory, pickup.
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_J:
   _normal_attack()
   get_viewport().set_input_as_handled()
   return
  var key_slots:Array=[KEY_1,KEY_2,KEY_3]
  var skill_index:int=key_slots.find(event.keycode)
  if skill_index>=0:
   if not open and (not is_instance_valid(hud_menu) or not hud_menu.is_gameplay_blocked()):
    _cast_hotbar_slot(skill_index)
   get_viewport().set_input_as_handled()
   return
 if event.is_action_pressed("target") and not event.is_echo():
  _toggle_target_lock()
  get_viewport().set_input_as_handled()
 elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE:
  if _target_pointer_input(event.position,2):
   get_viewport().set_input_as_handled()
 elif event.is_action_pressed("bag") and not event.is_echo():
  if not is_instance_valid(hud_menu) or not hud_menu.edit_mode: _toggle()
  get_viewport().set_input_as_handled()
 elif event.is_action_pressed("pickup") and not open and not event.is_echo():
  _collect_nearest()
 elif event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  if open:_toggle()
  elif is_instance_valid(hud_menu) and hud_menu.is_gameplay_blocked():
   if hud_menu.edit_mode:hud_menu.call("_finish_edit",false)
   else:hud_menu.call("_hide_popup")
  else:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

extends Node3D
const StoreScript = preload("res://scripts/store.gd")
var store: Node
var character: CharacterBody3D
var camera_arm: Node3D
var camera: Camera3D
var hud: CanvasLayer
var inventory: PanelContainer
var bag_menu: PanelContainer
var bag_menu_inventory_button: Button
var bag_menu_storage_button: Button
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

func _ready() -> void:
 _register_keys()
 store = StoreScript.new()
 add_child(store)
 store.changed.connect(_refresh)
 store.notice.connect(_notice)
 _make_world()
 _make_character()
 _make_ui()
 var ui911: Node = load("res://scripts/ui911.gd").new()
 add_child(ui911)
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if OS.has_feature("web") else Input.MOUSE_MODE_CAPTURED
 if OS.has_feature("web") and "--inventory-qa" in OS.get_cmdline_user_args():
  add_child(load("res://scripts/web_ui_probe.gd").new())

func _register_keys() -> void:
 var keys := {"forward":[KEY_W,KEY_UP],"back":[KEY_S,KEY_DOWN],"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE],"run":[KEY_SHIFT],"bag":[KEY_B],"pickup":[KEY_E]}
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
 # The only HUD inventory icon opens one red-and-gold list.
 # Storage is the SECOND row of that list, not an independent HUD icon
 # and not a floating button inside the Inventory equipment view.
 bag_button.pressed.connect(_toggle_bag_menu)
 bag_menu = PanelContainer.new()
 bag_menu.name = "InventoryMenu"
 bag_menu.mouse_filter = Control.MOUSE_FILTER_STOP
 var menu_background := StyleBoxTexture.new()
 menu_background.texture = load("res://assets/ui/red_matte/inner_panel.png")
 menu_background.texture_margin_left = 28.0
 menu_background.texture_margin_right = 28.0
 menu_background.texture_margin_top = 28.0
 menu_background.texture_margin_bottom = 28.0
 menu_background.content_margin_left = 10.0
 menu_background.content_margin_right = 10.0
 menu_background.content_margin_top = 10.0
 menu_background.content_margin_bottom = 10.0
 bag_menu.add_theme_stylebox_override("panel",menu_background)
 hud.add_child(bag_menu)
 var menu_list := VBoxContainer.new()
 menu_list.name = "InventoryList"
 menu_list.add_theme_constant_override("separation",4)
 bag_menu.add_child(menu_list)
 bag_menu_inventory_button = _inventory_list_button(menu_list,"inventory",_open_inventory_from_menu)
 bag_menu_storage_button = _inventory_list_button(menu_list,"storage",_open_storage_from_menu)
 bag_menu.size = Vector2(260,136)
 bag_menu.position = Vector2(maxf(8.0,get_viewport().get_visible_rect().size.x-276.0),80)
 bag_menu.visible = false
 _refresh_bag_menu_locale()
 inventory.visibility_changed.connect(func():
  bag_button.visible = not inventory.visible
  if inventory.visible:
   bag_menu.visible = false
 )
 get_viewport().size_changed.connect(func():
  var width: float = get_viewport().get_visible_rect().size.x
  bag_button.position = Vector2(width-72,16)
  bag_menu.position = Vector2(maxf(8.0,width-276.0),80)
 )
 
func _inventory_list_button(parent: VBoxContainer, icon_name: String, action: Callable) -> Button:
 var button := Button.new()
 button.name = "InventoryMenu" + icon_name.capitalize()
 button.custom_minimum_size = Vector2(234,52)
 button.mouse_filter = Control.MOUSE_FILTER_STOP
 button.focus_mode = Control.FOCUS_NONE
 button.pressed.connect(action)
 if ResourceLoader.exists("res://assets/fonts/NotoSansThai.ttf"):
  button.add_theme_font_override("font",load("res://assets/fonts/NotoSansThai.ttf"))
 button.add_theme_font_size_override("font_size",19)
 button.add_theme_color_override("font_color",Color("#ffde93"))
 button.add_theme_color_override("font_hover_color",Color.WHITE)
 button.add_theme_color_override("font_pressed_color",Color.WHITE)
 for state in ["normal","hover","pressed"]:
  var box := StyleBoxTexture.new()
  var asset: String = "tab_idle" if state=="normal" else ("button_hover" if state=="hover" else "button_pressed")
  box.texture = load("res://assets/ui/red_matte/"+asset+".png")
  box.texture_margin_left=24.0
  box.texture_margin_right=24.0
  box.texture_margin_top=14.0
  box.texture_margin_bottom=14.0
  button.add_theme_stylebox_override(state,box)
 button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
 parent.add_child(button)
 var icon := TextureRect.new()
 icon.name = "OriginalIcon"
 icon.texture = load("res://assets/ui/inventory/icon_"+icon_name+".png")
 icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
 button.add_child(icon)
 icon.position = Vector2(12,9)
 icon.size = Vector2(34,34)
 return button

func _refresh_bag_menu_locale() -> void:
 if not is_instance_valid(bag_menu_inventory_button): return
 var thai: bool = str(inventory.get("locale"))=="th"
 bag_menu_inventory_button.text = "กระเป๋า / Inventory" if thai else "Inventory"
 bag_menu_storage_button.text = "คลังเก็บของ" if thai else "Storage"

func _toggle_bag_menu() -> void:
 if open: return
 bag_menu.visible = not bag_menu.visible
 if bag_menu.visible:
  _refresh_bag_menu_locale()
  Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _open_inventory_from_menu() -> void:
 bag_menu.visible = false
 if not open:
  _toggle()
 else:
  inventory.call("_switch_tab",0)

func _open_storage_from_menu() -> void:
 bag_menu.visible = false
 if not open:
  open = true
  inventory.visible = true
 inventory.call("open_storage")
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

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
 if is_instance_valid(bag_menu): bag_menu.visible = false
 open = not open
 if open:
  inventory.call("_switch_tab",0)
 inventory.visible = open
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open or OS.has_feature("web") or DisplayServer.is_touchscreen_available() else Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
 var vel := character.velocity
 if not character.is_on_floor():
  vel.y -= 19.6*delta
 elif Input.is_action_just_pressed("jump") and not open:
  vel.y = 7.5
 var v := Vector2.ZERO if open else Input.get_vector("left","right","forward","back")
 var dir := camera_arm.global_basis.x*v.x+camera_arm.global_basis.z*v.y
 dir.y = 0
 dir = dir.normalized()
 var speed := 8.0 if Input.is_action_pressed("run") else 5.0
 vel.x = dir.x*speed
 vel.z = dir.z*speed
 character.velocity = vel
 character.move_and_slide()
 camera_arm.global_position = character.global_position+Vector3(0,0.5,0)

func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("bag") and not event.is_echo():
  _toggle()
  get_viewport().set_input_as_handled()
 elif event.is_action_pressed("pickup") and not open and not event.is_echo():
  var nearest: Area3D
  var distance := 3.0
  for item in loot:
   if is_instance_valid(item) and item.global_position.distance_to(character.global_position)<distance:
    nearest = item
    distance = item.global_position.distance_to(character.global_position)
  if nearest != null and store.add_item(str(nearest.get_meta("id"))):
   loot.erase(nearest)
   nearest.queue_free()
 elif event is InputEventMouseButton and event.pressed and not open and not DisplayServer.is_touchscreen_available():
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 elif event is InputEventMouseMotion and not open and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
  camera_arm.rotation.y -= event.relative.x*0.003
  pitch = clampf(pitch-event.relative.y*0.003,-0.7,0.5)
  camera.rotation.x = pitch
 elif event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  if open:
   _toggle()
  elif is_instance_valid(bag_menu) and bag_menu.visible:
   bag_menu.visible=false
  else:
   Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

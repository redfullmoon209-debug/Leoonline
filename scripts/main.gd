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
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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
 var controls := _text("LEOONLINE  |  WASD Move   SHIFT Run   SPACE Jump   E Loot   B Inventory",hud,16)
 controls.position = Vector2(18,12)
 inventory = PanelContainer.new()
 inventory.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 inventory.add_theme_stylebox_override("panel",_style("#06172f","#e1b65b"))
 hud.add_child(inventory)
 var outer := VBoxContainer.new()
 outer.add_theme_constant_override("separation",12)
 inventory.add_child(outer)
 var heading := _text("✦  LEOONLINE   /   INVENTORY",outer,27)
 heading.add_theme_color_override("font_color",Color("#f7d48c"))
 var separator := HSeparator.new()
 outer.add_child(separator)
 var horizontal := HBoxContainer.new()
 horizontal.add_theme_constant_override("separation",18)
 horizontal.size_flags_vertical = Control.SIZE_EXPAND_FILL
 outer.add_child(horizontal)
 var left := VBoxContainer.new()
 left.custom_minimum_size.x = 350
 left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 left.add_theme_constant_override("separation",9)
 horizontal.add_child(left)
 var equip_title := _text("✦  EQUIPMENT",left,22)
 equip_title.add_theme_color_override("font_color",Color("#f7d48c"))
 equip_grid = GridContainer.new()
 equip_grid.columns = 2
 equip_grid.add_theme_constant_override("h_separation",8)
 equip_grid.add_theme_constant_override("v_separation",8)
 left.add_child(equip_grid)
 var tip := _text("WEAPONS  ›  ARMOR  ›  OTHER ITEMS",left,13)
 tip.add_theme_color_override("font_color",Color("#89c9e8"))
 var right := VBoxContainer.new()
 right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 right.add_theme_constant_override("separation",9)
 horizontal.add_child(right)
 capacity_label = _text("BAG 40 / 200",right,22)
 capacity_label.add_theme_color_override("font_color",Color("#f7d48c"))
 grid = GridContainer.new()
 grid.columns = 10
 grid.add_theme_constant_override("h_separation",5)
 grid.add_theme_constant_override("v_separation",5)
 grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
 right.add_child(grid)
 var nav := HBoxContainer.new()
 nav.alignment = BoxContainer.ALIGNMENT_CENTER
 nav.add_theme_constant_override("separation",8)
 right.add_child(nav)
 _button("≪",func(): page=0; _refresh(),nav)
 _button("‹",func(): page=maxi(0,page-1); _refresh(),nav)
 page_label = _text("PAGE 1 / 4",nav,17)
 _button("›",func(): page=mini(3,page+1); _refresh(),nav)
 _button("≫",func(): page=3; _refresh(),nav)
 var separator2 := HSeparator.new()
 outer.add_child(separator2)
 var toolbar := HBoxContainer.new()
 toolbar.add_theme_constant_override("separation",18)
 outer.add_child(toolbar)
 money_box = VBoxContainer.new()
 money_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 toolbar.add_child(money_box)
 var actions := HBoxContainer.new()
 actions.add_theme_constant_override("separation",8)
 toolbar.add_child(actions)
 _button("⟳ AUTO SORT",func(): store.sort_items(),actions)
 _button("EQUIP",func(): store.equip_selected(),actions)
 _button("+10 SLOTS",func(): store.use_scroll(),actions)
 _button("TRASH",func(): trash_dialog.popup_centered(),actions)
 var footer := HBoxContainer.new()
 footer.add_theme_constant_override("separation",10)
 outer.add_child(footer)
 _button("+ DEMO ITEMS",func(): _starter(),footer)
 _button("SAVE",func(): store.save_data(); _notice("Saved"),footer)
 _button("CLOSE [B]",func(): _toggle(),footer)
 notice_label = _text("",footer,13)
 trash_dialog = ConfirmationDialog.new()
 trash_dialog.dialog_text = "Permanently discard selected item?"
 trash_dialog.confirmed.connect(func(): store.trash_selected())
 hud.add_child(trash_dialog)
 inventory.visible = false
 _refresh()

func _starter() -> void:
 for id in ["sword","shirt","boots","potion","scroll","wood"]:
  store.add_item(id)
 store.add_currency("gold","1200")

func _notice(message: String) -> void:
 if is_instance_valid(notice_label):
  notice_label.text = message

func _refresh() -> void:
 if not is_instance_valid(grid):
  return
 for child in grid.get_children():
  child.queue_free()
 for idx in range(50):
  var abs_idx := page*50+idx
  var locked: bool = abs_idx >= store.unlocked
  var item: String = store.slots[abs_idx]
  var title: String = "LOCK" if locked else (str(abs_idx+1) if item == "" else str(StoreScript.DATA.get(item,{}).get("name",item)))
  var slot := _button(title,func(index=abs_idx): store.choose(index),grid)
  slot.custom_minimum_size = Vector2(62,62)
  slot.disabled = locked
  if abs_idx == store.selected:
   slot.add_theme_stylebox_override("normal",_style("#294f81","#f7c96a"))
 for child in equip_grid.get_children():
  child.queue_free()
 for key in StoreScript.EQUIPMENT:
  var title: String = String(key).replace("_"," ").capitalize()
  var value: String = store.equipped.get(key,"")
  var b := _button(title+"\n"+(value if value!="" else "[EMPTY]"),func(k=key): store.unequip(k),equip_grid)
  b.custom_minimum_size = Vector2(150,47)
 for child in money_box.get_children():
  child.queue_free()
 for key in ["gold","blue","purple","green"]:
  var money_line := _text("◆  "+key.to_upper()+"   "+store.pretty(store.currency[key]),money_box,15)
  money_line.add_theme_color_override("font_color",Color("#f7d48c"))
 page_label.text = "PAGE "+str(page+1)+" / 4"
 capacity_label.text = "BAG "+str(store.unlocked)+" / 200"

func _toggle() -> void:
 open = not open
 inventory.visible = open
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED

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
 elif event is InputEventMouseMotion and not open and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
  camera_arm.rotation.y -= event.relative.x*0.003
  pitch = clampf(pitch-event.relative.y*0.003,-0.7,0.5)
  camera.rotation.x = pitch
 elif event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  if open:
   _toggle()
  else:
   Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

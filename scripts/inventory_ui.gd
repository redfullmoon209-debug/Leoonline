extends PanelContainer
## LEOONLINE UI: original approved PNG files displayed directly as Godot layers.
## NO art generation, screenshot crops, or baked-in text. Text/interaction are native Controls.
const Approved = "res://assets/ui/approved/"
const Icons = "res://assets/ui/inventory/"
const StoreScript = preload("res://scripts/store.gd")
const W := 1448.0
const H := 1086.0
const MAIN_EQUIPMENT = ["hat", "shirt", "gloves", "pants", "shoes"]
const RIGHT_EQUIPMENT = ["weapon_right", "weapon_left", "pet", "mount"]
const JEWELRY = ["bracelet_left", "ring_left", "necklace", "ring_right", "bracelet_right"]
const FASHION = ["fashion_hat", "fashion_shirt", "fashion_gloves", "fashion_pants", "fashion_shoes"]
const FASHION_WEAPONS = ["fashion_weapon_right", "fashion_weapon_left"]
const FASHION_SIDES = ["fashion_mask", "fashion_cape"]
const MONEY = ["gold", "blue", "purple", "green"]
const LABELS = {
 "Inventory":"กระเป๋า", "Character":"ตัวละคร", "Skill":"สกิล", "Shop":"ร้านค้า",
 "Equipment":"อุปกรณ์สวมใส่", "Bag":"กระเป๋าเก็บของ", "Fashion Weapons":"อาวุธแฟชั่น",
 "Accessories":"เครื่องประดับ", "Fashion":"ชุดแฟชั่น", "Demo Items":"ไอเทมทดลอง",
 "Save":"บันทึก", "Auto Sort":"เรียงไอเทม", "Trash":"ทิ้ง", "Equip":"สวมใส่",
 "Close":"ปิด", "Gold":"ทอง", "Blue":"เพชรฟ้า", "Purple":"เพชรม่วง", "Green":"เพชรเขียว"
}
const SLOT_NAMES = {
 "hat":"Hat", "shirt":"Shirt", "gloves":"Gloves", "pants":"Pants", "shoes":"Shoes",
 "weapon_right":"Right Weapon", "weapon_left":"Left Weapon", "pet":"Pet", "mount":"Mount",
 "bracelet_left":"Left Bracelet", "ring_left":"Left Ring", "necklace":"Necklace",
 "ring_right":"Right Ring", "bracelet_right":"Right Bracelet",
 "fashion_hat":"Fashion Hat", "fashion_shirt":"Fashion Shirt", "fashion_gloves":"Fashion Gloves",
 "fashion_pants":"Fashion Pants", "fashion_shoes":"Fashion Shoes",
 "fashion_weapon_right":"Fashion Weapon Right", "fashion_weapon_left":"Fashion Weapon Left",
 "fashion_mask":"Mask", "fashion_cape":"Cape"
}
var game_store: Node
var close_callback: Callable
var demo_callback: Callable
var stage: Control
var current_page: int = 0
var current_tab: int = 0
var locale: String = "en"
var ui_font: Font
var language_button: Button
var tab_buttons: Array[Button] = []
var text_nodes: Dictionary = {}
var equipment_panel: Control
var bag_panel: Control
var waiting_panel: Control
var bag_grid: GridContainer
var main_equip_list: Control
var extra_equip_list: Control
var fashion_weapon_row: HBoxContainer
var fashion_side_row: HBoxContainer
var accessory_row: HBoxContainer
var fashion_row: HBoxContainer
var capacity_text: Label
var page_text: Label
var money_labels: Dictionary = {}
var detail_layer: CanvasLayer
var detail_panel: PanelContainer
var detail_heading: Label
var detail_description: Label
var detail_icon: TextureRect
var notice_text: Label
var trash_dialog: ConfirmationDialog
var is_built := false

func initialize(p_store: Node, p_close: Callable, p_demo: Callable) -> void:
 game_store = p_store
 close_callback = p_close
 demo_callback = p_demo
 if ResourceLoader.exists("res://assets/fonts/NotoSansThai.ttf"):
  ui_font = load("res://assets/fonts/NotoSansThai.ttf") as Font
 _build()
 is_built = true
 refresh()
 _adapt_layout()

func _texture(name: String, approved: bool = false) -> Texture2D:
 var path: String = (Approved if approved else Icons) + name + ".png"
 if ResourceLoader.exists(path):
  return load(path) as Texture2D
 return null

func _rect(node: Control, x: float, y: float, w: float, h: float) -> void:
 node.position = Vector2(x,y)
 node.size = Vector2(w,h)

func _art(name: String, parent: Node, x: float, y: float, w: float, h: float, approved: bool = true) -> TextureRect:
 var img := TextureRect.new()
 img.texture = _texture(name,approved)
 img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 img.stretch_mode = TextureRect.STRETCH_SCALE
 img.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(img)
 _rect(img,x,y,w,h)
 return img

func _label(s: String, parent: Node, x: float, y: float, w: float, h: float, size: int = 17, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER, gold: bool = true) -> Label:
 var l := Label.new()
 l.text = _tr(s)
 if LABELS.has(s): l.set_meta("l10n",s)
 l.horizontal_alignment = align
 l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 l.add_theme_font_size_override("font_size",size)
 l.add_theme_color_override("font_color",Color("#ffde93") if gold else Color("#e8f5ff"))
 l.add_theme_color_override("font_shadow_color",Color(0,0,0,0.85))
 l.add_theme_constant_override("shadow_offset_y",2)
 if ui_font != null: l.add_theme_font_override("font",ui_font)
 l.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(l)
 _rect(l,x,y,w,h)
 return l

func _tr(s: String) -> String:
 return str(LABELS.get(s,s)) if locale == "th" else s

func _hitbox(parent: Node, x: float,y: float,w: float,h: float, click: Callable) -> Button:
 var b := Button.new()
 b.flat = true
 b.text = ""
 for state in ["normal","hover","pressed","focus","disabled"]:
  b.add_theme_stylebox_override(state,StyleBoxEmpty.new())
 b.focus_mode = Control.FOCUS_NONE
 parent.add_child(b)
 _rect(b,x,y,w,h)
 b.pressed.connect(click)
 return b

func _build() -> void:
 # One existing user-approved PNG forms the exact, undistorted frame.
 # Only dynamic icons, text, overlays and clickable Controls are layered above it.
 mouse_filter = Control.MOUSE_FILTER_STOP
 var backdrop := StyleBoxFlat.new()
 backdrop.bg_color = Color("#020917e8")
 backdrop.set_content_margin_all(0)
 add_theme_stylebox_override("panel",backdrop)
 var viewport_wrapper := Control.new()
 viewport_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(viewport_wrapper)
 viewport_wrapper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 stage = Control.new()
 stage.mouse_filter = Control.MOUSE_FILTER_PASS
 viewport_wrapper.add_child(stage)
 _rect(stage,0,0,W,H)
 _art("ornate_blue_gold_inventory_ui_frame",stage,0,0,W,H)
 _label("LEOONLINE",stage,493,46,454,60,40)
 language_button = _hitbox(stage,1232,71,107,37,func(): set_language("th" if locale=="en" else "en"))
 _label("TH / EN",stage,1235,72,104,36,16)
 var tab_x: Array[float] = [140.0,460.0,744.0,1019.0]
 var tab_width: Array[float] = [291.0,265.0,258.0,248.0]
 var titles: Array[String] = ["Inventory","Character","Skill","Shop"]
 var icons: Array[String] = ["inventory","character","skill","shop"]
 for idx in range(4):
  var tx: float = tab_x[idx]
  var tw: float = tab_width[idx]
  var tab := _hitbox(stage,tx,123,tw,62,_switch_tab.bind(idx))
  tab.text = _tr(titles[idx])
  tab.set_meta("l10n",titles[idx])
  tab.add_theme_font_size_override("font_size",1)
  for col in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
   tab.add_theme_color_override(col,Color(0,0,0,0))
  tab_buttons.append(tab)
  _art("icon_"+icons[idx],stage,tx+22,133,42,42,false)
  _label(titles[idx],stage,tx+66,126,tw-85,55,24)
 equipment_panel = Control.new()
 equipment_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage.add_child(equipment_panel)
 _rect(equipment_panel,0,0,W,H)
 _label("Equipment",equipment_panel,132,211,224,44,22)
 _art("character_silhouette",equipment_panel,255,262,194,282,false)
 main_equip_list = Control.new()
 equipment_panel.add_child(main_equip_list)
 _rect(main_equip_list,103,263,64,314)
 extra_equip_list = Control.new()
 equipment_panel.add_child(extra_equip_list)
 _rect(extra_equip_list,474,239,144,288)
 _label("Fashion Weapons",equipment_panel,197,563,343,33,17)
 fashion_weapon_row = HBoxContainer.new()
 fashion_weapon_row.add_theme_constant_override("separation",14)
 equipment_panel.add_child(fashion_weapon_row)
 _rect(fashion_weapon_row,185,604,144,56)
 fashion_side_row = HBoxContainer.new()
 fashion_side_row.add_theme_constant_override("separation",14)
 equipment_panel.add_child(fashion_side_row)
 _rect(fashion_side_row,408,604,144,56)
 _label("Accessories",equipment_panel,236,669,243,31,18)
 accessory_row = HBoxContainer.new()
 accessory_row.add_theme_constant_override("separation",39)
 equipment_panel.add_child(accessory_row)
 _rect(accessory_row,127,700,479,63)
 _label("Fashion",equipment_panel,277,789,167,30,18)
 # The approved background contains six decorative slots; cover only that
 # lower row with a native Godot panel, then display exactly five active slots.
 # No PNG files are cropped, repainted or regenerated.
 var fashion_back := Panel.new()
 fashion_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var fashion_style := StyleBoxFlat.new()
 fashion_style.bg_color = Color("#051b35")
 fashion_style.border_color = Color("#2167a4")
 fashion_style.set_border_width_all(1)
 fashion_style.set_corner_radius_all(8)
 fashion_back.add_theme_stylebox_override("panel",fashion_style)
 equipment_panel.add_child(fashion_back)
 _rect(fashion_back,114,822,505,63)
 fashion_row = HBoxContainer.new()
 fashion_row.add_theme_constant_override("separation",36)
 equipment_panel.add_child(fashion_row)
 _rect(fashion_row,131,825,461,57)
 bag_panel = Control.new()
 bag_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage.add_child(bag_panel)
 _rect(bag_panel,0,0,W,H)
 _label("Bag",bag_panel,697,208,207,47,23)
 capacity_text = _label("40 / 50 Slots (40/200)",bag_panel,1017,214,280,44,17)
 bag_grid = GridContainer.new()
 bag_grid.columns = 10
 bag_grid.add_theme_constant_override("h_separation",4)
 bag_grid.add_theme_constant_override("v_separation",3)
 bag_panel.add_child(bag_grid)
 _rect(bag_grid,678,268,637,309)
 _hitbox(bag_panel,728,584,72,49,_page_button.bind(0))
 _hitbox(bag_panel,810,584,70,49,_page_button.bind(1))
 _hitbox(bag_panel,1120,584,74,49,_page_button.bind(3))
 _hitbox(bag_panel,1200,584,75,49,_page_button.bind(4))
 page_text = _label("PAGE 1 / 4",bag_panel,905,584,190,49,19)
 for i in range(4):
  var money: String = MONEY[i]
  var row_y: float = 673.0 + float(i) * 42.0
  _label(money.capitalize(),bag_panel,761,row_y,148,39,20,HORIZONTAL_ALIGNMENT_LEFT)
  money_labels[money] = _label("0",bag_panel,935,row_y,294,39,19,HORIZONTAL_ALIGNMENT_RIGHT,false)
  _hitbox(bag_panel,1247,row_y,49,38,func(): set_notice("Cash Shop is not available yet"))
 var foot_names: Array[String] = ["Demo Items","Save","Auto Sort","Trash","Equip","Close"]
 var foot_x: Array[float] = [84.0,306.0,488.0,734.0,921.0,1116.0]
 var foot_w: Array[float] = [216.0,174.0,235.0,187.0,190.0,212.0]
 for i in range(6):
  var fx: float = foot_x[i]
  var fw: float = foot_w[i]
  _label(foot_names[i],stage,fx,927,fw,49,20)
  var action: Callable
  match i:
   0: action = func(): demo_callback.call()
   1: action = _save_game
   2: action = func(): game_store.call("sort_items")
   3: action = _request_trash
   4: action = func(): game_store.call("equip_selected")
   _: action = func(): close_callback.call()
  _hitbox(stage,fx,924,fw,58,action)
 waiting_panel = Control.new()
 waiting_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage.add_child(waiting_panel)
 _rect(waiting_panel,80,202,1280,702)
 waiting_panel.visible = false
 notice_text = _label("",stage,393,884,680,30,15)
 trash_dialog = ConfirmationDialog.new()
 trash_dialog.title = "Discard item?"
 trash_dialog.dialog_text = "Discard selected item permanently?"
 trash_dialog.confirmed.connect(func(): game_store.call("trash_selected"))
 add_child(trash_dialog)
 _create_details()

func _equip_icon(key: String, active: String) -> String:
 if active != "": return active
 if key.begins_with("fashion_"):
  var suffix = key.trim_prefix("fashion_")
  if suffix in ["hat","shirt","gloves","pants","shoes"]: return suffix
  return key
 if key.begins_with("ring"): return "ring"
 if key.begins_with("bracelet"): return "bracelet"
 return key

func _image_button(parent: Node, x: float,y: float,wh: float, key: String, state: String, height: float = -1.0) -> TextureButton:
 var b := TextureButton.new()
 b.ignore_texture_size = true
 b.stretch_mode = TextureButton.STRETCH_SCALE
 b.focus_mode = Control.FOCUS_NONE
 var selected_png := _texture("ornate_golden_crystal_inventory_slot",true)
 var locked_png := _texture("ornate_neon_locked_inventory_slot",true)
 if state == "selected" or state == "fashion" or state == "unlocked_last_row":
  b.texture_normal = selected_png
 elif state == "locked":
  b.texture_normal = locked_png
  b.texture_disabled = locked_png
  b.disabled = true
 elif state == "locked_base":
  # The already-approved full frame draws these 10 locks. Do not double-render.
  b.disabled = true
  b.texture_disabled = null
 else:
  # The already-approved full frame has the exact slot backgrounds.
  # Show a separately approved PNG only on hover/press, not twice at rest.
  b.texture_hover = selected_png
  b.texture_pressed = selected_png
 parent.add_child(b)
 var hh: float = wh if height < 0.0 else height
 _rect(b,x,y,wh,hh)
 b.custom_minimum_size = Vector2(wh,hh)
 if key != "" and state != "locked" and state != "locked_base":
  var art: Texture2D = _texture("icon_"+key)
  if art != null:
   var icon := TextureRect.new()
   icon.texture = art
   icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
   b.add_child(icon)
   _rect(icon,8,7,wh-16,hh-14)
 return b

func _clear_container(container: Node) -> void:
 for c in container.get_children():
  container.remove_child(c)
  c.queue_free()

func _refresh_equipment(container: Control, keys: Array, width: float, space: float, direction: String = "v") -> void:
 _clear_container(container)
 for i in range(keys.size()):
  var key: String = str(keys[i])
  var active: String = str(game_store.get("equipped").get(key,""))
  var bx: float = 0.0
  var by: float = 0.0
  var bw: float = width
  var bh: float = width
  var state := "normal"
  if container == main_equip_list:
   by = float(i) * 62.0
   bw = 61.0
   bh = 57.0
  elif container == extra_equip_list:
   if i < 2:
    by = float(i) * 64.0
    bw = 61.0
    bh = 57.0
   else:
    bx = 8.0
    by = 132.0 if i == 2 else 219.0
    bw = 129.0
    bh = 58.0
  elif direction == "h":
   bw = width
   bh = width
   state = "fashion" if container == fashion_row else "normal"
  else:
   by = float(i) * (width+space)
  var b := _image_button(container,bx,by,bw,_equip_icon(key,active),state,bh)
  b.mouse_entered.connect(func(): _show_details(active,key,false))
  b.mouse_exited.connect(_hide_details)
  b.pressed.connect(func():
   _show_details(active,key,false)
   if active != "": game_store.call("unequip",key)
  )

func _fill_bag() -> void:
 _clear_container(bag_grid)
 var items: Array = game_store.get("slots")
 var unlocked: int = int(game_store.get("unlocked"))
 var selected: int = int(game_store.get("selected"))
 for i in range(50):
  var index: int = current_page*50+i
  var is_locked: bool = index >= unlocked
  var item_id: String = str(items[index])
  var state: String = "normal"
  if is_locked:
   state = "locked_base" if current_page == 0 and i >= 40 else "locked"
  elif index == selected:
   state = "selected"
  elif current_page == 0 and i >= 40:
   state = "unlocked_last_row"
  var b := _image_button(bag_grid,0,0,60,item_id,state,59)
  if not is_locked:
   b.mouse_entered.connect(func(): _show_details(item_id,"",false))
   b.mouse_exited.connect(_hide_details)
   b.pressed.connect(_pick_item.bind(index))
  else:
   b.mouse_entered.connect(func(): _show_details("", "", true))
   b.mouse_exited.connect(_hide_details)
 var shown: int = maxi(0,mini(50,unlocked-current_page*50))
 capacity_text.text = str(shown)+" / 50 Slots  ("+str(unlocked)+"/200)"
 page_text.text = ("หน้า " if locale=="th" else "PAGE ")+str(current_page+1)+" / 4"
 var c: Dictionary = game_store.get("currency")
 for k in MONEY:
  var l: Label = money_labels[k]
  l.text = str(game_store.call("pretty",str(c.get(k,"0"))))

func _pick_item(index: int) -> void:
 game_store.call("choose",index)
 var items: Array = game_store.get("slots")
 _show_details(str(items[index]),"",false)

func _page_button(index: int) -> void:
 match index:
  0: current_page=0
  1: current_page=maxi(0,current_page-1)
  3: current_page=mini(3,current_page+1)
  4: current_page=3
 refresh()

func _change_page(page: int) -> void:
 current_page=clampi(page,0,3)
 refresh()

func _switch_tab(index: int) -> void:
 current_tab=clampi(index,0,3)
 if is_built: _adapt_layout()

func _adapt_layout() -> void:
 if is_built:
  var ratio: float = minf(size.x/W,size.y/H)
  stage.scale = Vector2(ratio,ratio)
  stage.position = Vector2((size.x-W*ratio)*0.5,(size.y-H*ratio)*0.5)
  equipment_panel.visible = current_tab in [0,1]
  bag_panel.visible = current_tab==0
  waiting_panel.visible = current_tab>=2
  if waiting_panel.visible:
   for ch in waiting_panel.get_children(): ch.queue_free()
   _label("SKILL · Coming soon" if current_tab==2 else "SHOP · Coming soon",waiting_panel,450,300,560,90,30)

func refresh() -> void:
 if not is_built or game_store==null: return
 _refresh_equipment(main_equip_list,MAIN_EQUIPMENT,62,3,"v")
 _refresh_equipment(extra_equip_list,RIGHT_EQUIPMENT,62,5,"v")
 _refresh_equipment(fashion_weapon_row,FASHION_WEAPONS,67,7,"h")
 _refresh_equipment(fashion_side_row,FASHION_SIDES,67,7,"h")
 _refresh_equipment(accessory_row,JEWELRY,67,7,"h")
 _refresh_equipment(fashion_row,FASHION,67,7,"h")
 _fill_bag()

func set_language(value: String) -> void:
 locale="th" if value.begins_with("th") else "en"
 _translate(self)
 if is_built: _fill_bag()
 _hide_details()

func _translate(node: Node) -> void:
 if node.has_meta("l10n"):
  node.set("text",_tr(str(node.get_meta("l10n"))))
 for ch in node.get_children(): _translate(ch)

func set_notice(msg: String) -> void:
 if is_instance_valid(notice_text): notice_text.text=msg

func _request_trash() -> void:
 var selected: int = int(game_store.get("selected"))
 var items: Array = game_store.get("slots")
 if selected<0 or selected>=items.size() or str(items[selected])=="":
  set_notice("Select an item first")
 else:
  trash_dialog.popup_centered()

func _save_game() -> void:
 game_store.call("save_data")
 set_notice("Saved")

func _create_details() -> void:
 detail_layer = CanvasLayer.new()
 detail_layer.layer=20
 add_child(detail_layer)
 detail_panel=PanelContainer.new()
 var st := StyleBoxFlat.new()
 st.bg_color=Color("#061a33")
 st.border_color=Color("#facb66")
 st.set_border_width_all(2)
 st.set_corner_radius_all(10)
 st.set_content_margin_all(12)
 detail_panel.add_theme_stylebox_override("panel",st)
 detail_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 detail_layer.add_child(detail_panel)
 detail_panel.custom_minimum_size=Vector2(340,140)
 detail_panel.size=Vector2(340,140)
 var r:=HBoxContainer.new()
 r.mouse_filter=Control.MOUSE_FILTER_IGNORE
 detail_panel.add_child(r)
 detail_icon=TextureRect.new()
 detail_icon.custom_minimum_size=Vector2(65,65)
 detail_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 detail_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 detail_icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
 r.add_child(detail_icon)
 var col:=VBoxContainer.new()
 col.mouse_filter=Control.MOUSE_FILTER_IGNORE
 col.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 r.add_child(col)
 detail_heading=Label.new()
 detail_heading.add_theme_font_size_override("font_size",19)
 detail_heading.add_theme_color_override("font_color",Color("#ffe1a0"))
 if ui_font != null: detail_heading.add_theme_font_override("font",ui_font)
 detail_heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 detail_heading.mouse_filter=Control.MOUSE_FILTER_IGNORE
 col.add_child(detail_heading)
 detail_description=Label.new()
 detail_description.add_theme_font_size_override("font_size",14)
 detail_description.add_theme_color_override("font_color",Color("#d6e9f9"))
 if ui_font != null: detail_description.add_theme_font_override("font",ui_font)
 detail_description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 detail_description.mouse_filter=Control.MOUSE_FILTER_IGNORE
 col.add_child(detail_description)
 detail_panel.visible=false

func _show_details(item: String, equipment_key: String = "", locked: bool = false) -> void:
 if not is_instance_valid(detail_panel) or not is_visible_in_tree(): return
 if locked:
  detail_heading.text = "ช่องถูกล็อก" if locale=="th" else "Locked slot"
  detail_description.text = "ใช้ไอเทมขยายกระเป๋าเพื่อปลดล็อก" if locale=="th" else "Unlock by expanding your bag."
  detail_icon.texture = _texture("icon_lock")
 elif item!="":
  var info: Dictionary = StoreScript.DATA.get(item,{})
  detail_heading.text = str(info.get("name",item))
  detail_description.text = str(info.get("kind","other"))+"   "+str(info.get("slot",""))
  detail_icon.texture=_texture("icon_"+item)
 else:
  detail_heading.text = str(SLOT_NAMES.get(equipment_key,"Empty slot"))
  detail_description.text = "ช่องอุปกรณ์ว่าง" if locale=="th" else "Empty equipment slot"
  detail_icon.texture=_texture("icon_"+_equip_icon(equipment_key,""))
 var mouse_pos: Vector2=get_viewport().get_mouse_position()
 var view: Vector2=get_viewport_rect().size
 detail_panel.position = Vector2(clampf(mouse_pos.x+16,4.0,maxf(4.0,view.x-352)),clampf(mouse_pos.y+16,4.0,maxf(4.0,view.y-152)))
 detail_panel.visible=true

func _hide_details() -> void:
 if is_instance_valid(detail_panel): detail_panel.visible=false

func _notification(what: int) -> void:
 if what==NOTIFICATION_RESIZED and is_built: _adapt_layout()

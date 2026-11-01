extends PanelContainer
## LEOONLINE: standalone original matte crimson-and-gold PNGs, 9-slice layered UI.
## No screenshot crops, no glow effects, no writing baked into PNG textures.
## The approved originals are unchanged; game data/inputs/translation preserved.
const Approved = "res://assets/ui/approved/"
const Icons = "res://assets/ui/inventory/"
const RedAssets = "res://assets/ui/red_matte/"
const StoreScript = preload("res://scripts/store.gd")
const W := 1448.0
const H := 910.0
const MAIN_EQUIPMENT = ["hat", "shirt", "gloves", "pants", "shoes"]
const RIGHT_EQUIPMENT = ["weapon_right", "weapon_left", "pet", "mount"]
const JEWELRY = ["bracelet_left", "ring_left", "necklace", "ring_right", "bracelet_right"]
const FASHION = ["fashion_hat", "fashion_shirt", "fashion_gloves", "fashion_pants", "fashion_shoes"]
const FASHION_WEAPONS = ["fashion_weapon_right", "fashion_weapon_left"]
const FASHION_SIDES = ["fashion_mask", "fashion_cape"]
const MONEY = ["gold", "blue", "purple", "green"]
const LABELS = {
 "Unequip":"ถอดอุปกรณ์",
 "Skills are not available yet":"ระบบสกิลยังไม่เปิดให้ใช้งาน",
 "Shop is not available yet":"ระบบร้านค้ายังไม่เปิดให้ใช้งาน",
 "Cash Shop is not available yet":"ร้านค้าแคชยังไม่เปิดให้ใช้งาน",
 "Saved":"บันทึกแล้ว",
 "Save failed":"บันทึกไม่สำเร็จ",
 "Select an item first":"กรุณาเลือกไอเทมก่อน",
 "Discard item?":"ยืนยันทิ้งไอเทม",
 "Discard selected item permanently?":"ต้องการทิ้งไอเทมที่เลือกอย่างถาวรหรือไม่?",
 "Cancel":"ยกเลิก",
 "Locked slot":"ช่องถูกล็อก",
 "Unlock by expanding your bag.":"ปลดล็อกด้วยการขยายกระเป๋า",
 "Empty slot":"ช่องว่าง",
 "Empty equipment slot":"ช่องอุปกรณ์ว่าง",
 "No stats or description in item data.":"ระบบยังไม่มีข้อมูลค่าสถานะหรือคำอธิบาย",
 "Item Level":"ระดับไอเทม",
 "weapon":"อาวุธ",
 "armor":"ชุดเกราะ",
 "other":"อื่น ๆ",
 "fashion":"แฟชั่น",
 "Bronze Sword":"ดาบสำริด",
 "Cloth Shirt":"เสื้อผ้า",
 "Blue Boots":"รองเท้าสีน้ำเงิน",
 "HP Potion":"ยาฟื้นพลังชีวิต",
 "Bag +10 Scroll":"ใบขยายกระเป๋า +10 ช่อง",
 "Wood":"ไม้",
 "Moonlight Fashion Sword":"ดาบแฟชั่นแสงจันทร์",
 "Crystal Fashion Dagger":"มีดแฟชั่นคริสตัล",
 "Moonlight Mask":"หน้ากากแสงจันทร์",
 "Azure Cape":"ผ้าคลุมสีฟ้า",
 "Bag full":"กระเป๋าเต็ม",
 "This slot is locked":"ช่องนี้ถูกล็อก",
 "Not equippable":"ไอเทมนี้สวมใส่ไม่ได้",
 "10 bag slots unlocked":"ปลดล็อกกระเป๋าเพิ่ม 10 ช่อง",
 "Bag +10 Scroll required":"ต้องใช้ใบขยายกระเป๋า +10 ช่อง",
 "Hat":"หมวก",
 "Shirt":"เสื้อ",
 "Gloves":"ถุงมือ",
 "Pants":"กางเกง",
 "Shoes":"รองเท้า",
 "Right Weapon":"อาวุธมือขวา",
 "Left Weapon":"อาวุธมือซ้าย",
 "Pet":"สัตว์เลี้ยง",
 "Mount":"พาหนะ",
 "Left Bracelet":"กำไลซ้าย",
 "Left Ring":"แหวนซ้าย",
 "Necklace":"สร้อยคอ",
 "Right Ring":"แหวนขวา",
 "Right Bracelet":"กำไลขวา",
 "Fashion Hat":"หมวกแฟชั่น",
 "Fashion Shirt":"เสื้อแฟชั่น",
 "Fashion Gloves":"ถุงมือแฟชั่น",
 "Fashion Pants":"กางเกงแฟชั่น",
 "Fashion Shoes":"รองเท้าแฟชั่น",
 "Fashion Weapon Right":"อาวุธแฟชั่นมือขวา",
 "Fashion Weapon Left":"อาวุธแฟชั่นมือซ้าย",
 "Mask":"หน้ากากแฟชั่น",
 "Cape":"ผ้าคลุมแฟชั่น",

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
var locale: String = "th"
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
var viewport_wrapper: Control
var detail_content: Control
var detail_art: Control
var detail_dismiss: Button
var scroller: ScrollContainer
var scroll_content: Control
var currency_panel: Control
var waiting_text: Label
var page_buttons: Array[Button] = []
var footer_buttons: Array[Button] = []
var selected_equipment := ""
var details_pinned := false
var pending_trash_index := -1
var pending_trash_item := ""

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

func _red_texture(name: String) -> Texture2D:
 var p := RedAssets + name + ".png"
 return load(p) as Texture2D if ResourceLoader.exists(p) else null

func _red_panel(parent: Node, x: float, y: float, w: float, h: float, name: String = "inner_panel") -> NinePatchRect:
 var panel := NinePatchRect.new()
 panel.name = "RedMattePanel_" + name
 panel.texture = _red_texture(name)
 panel.patch_margin_left = 29
 panel.patch_margin_right = 29
 panel.patch_margin_top = 29
 panel.patch_margin_bottom = 29
 panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(panel)
 _rect(panel,x,y,w,h)
 return panel

func _red_style(asset: String, margin_x: float = 24.0, margin_y: float = 14.0) -> StyleBoxTexture:
 var st := StyleBoxTexture.new()
 st.texture = _red_texture(asset)
 st.texture_margin_left = margin_x
 st.texture_margin_right = margin_x
 st.texture_margin_top = margin_y
 st.texture_margin_bottom = margin_y
 st.content_margin_left = 6
 st.content_margin_right = 6
 st.content_margin_top = 3
 st.content_margin_bottom = 3
 return st

func _red_button(button: Button, asset: String = "action_button", pager: bool = false) -> void:
 var x_margin: float = 10.0 if pager else 24.0
 var y_margin: float = 9.0 if pager else 14.0
 button.flat = false
 var normal_name: String = asset
 var hover_name: String = "tab_active" if asset == "tab_idle" else asset
 button.add_theme_stylebox_override("normal",_red_style(normal_name,x_margin,y_margin))
 button.add_theme_stylebox_override("hover",_red_style(hover_name,x_margin,y_margin))
 button.add_theme_stylebox_override("pressed",_red_style("tab_active",x_margin,y_margin))
 button.add_theme_stylebox_override("disabled",_red_style(normal_name,x_margin,y_margin))
 button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
 button.add_theme_color_override("font_disabled_color",Color("#8b7162"))



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
 b.mouse_filter = Control.MOUSE_FILTER_PASS
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
 # All visual surfaces are original standalone red-matte PNGs.
 # Nine-patch preserves corners, while native Buttons/Labels stay interactive and translatable.
 mouse_filter = Control.MOUSE_FILTER_STOP
 var backdrop := StyleBoxFlat.new()
 backdrop.bg_color = Color(0,0,0,0.17)
 backdrop.set_content_margin_all(0)
 add_theme_stylebox_override("panel",backdrop)
 viewport_wrapper = Control.new()
 viewport_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(viewport_wrapper)
 scroller = ScrollContainer.new()
 scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
 scroller.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
 viewport_wrapper.add_child(scroller)
 scroll_content = Control.new()
 scroll_content.mouse_filter = Control.MOUSE_FILTER_PASS
 scroller.add_child(scroll_content)
 stage = Control.new()
 stage.mouse_filter = Control.MOUSE_FILTER_PASS
 scroll_content.add_child(stage)
 _rect(stage,0,0,W,H)
 _red_panel(stage,23,10,W-46,H-20,"outer_panel")
 _label("LEOONLINE",stage,491,33,466,52,32)
 var tab_x := [101.0,407.0,713.0,1019.0]
 var titles := ["Inventory","Character","Skill","Shop"]
 var tab_icons := ["inventory","character","skill","shop"]
 for idx in range(4):
  var tab := _hitbox(stage,tab_x[idx],100,278,57,_switch_tab.bind(idx))
  tab.text = _tr(titles[idx])
  tab.set_meta("l10n",titles[idx])
  _style_text_button(tab,23)
  _red_button(tab,"tab_active" if idx==current_tab else "tab_idle")
  _art("icon_"+tab_icons[idx],tab,19,11,35,35,false)
  tab_buttons.append(tab)
 language_button = _hitbox(stage,1257,41,121,41,func(): set_language("th" if locale=="en" else "en"))
 language_button.text = "ไทย / EN"
 _style_text_button(language_button,17)
 _red_button(language_button,"action_button")
 _label("LEOONLINE · INVENTORY",stage,475,165,499,32,22)
 equipment_panel = Control.new()
 equipment_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage.add_child(equipment_panel)
 _rect(equipment_panel,0,0,W,H)
 _red_panel(equipment_panel,72,200,581,566)
 _label("Equipment",equipment_panel,195,211,330,29,21)
 _art("character_silhouette",equipment_panel,262,249,211,247,false)
 main_equip_list = Control.new()
 main_equip_list.mouse_filter = Control.MOUSE_FILTER_PASS
 equipment_panel.add_child(main_equip_list)
 _rect(main_equip_list,122,247,54,278)
 extra_equip_list = Control.new()
 extra_equip_list.mouse_filter = Control.MOUSE_FILTER_PASS
 equipment_panel.add_child(extra_equip_list)
 _rect(extra_equip_list,548,247,54,224)
 _label("Fashion Weapons",equipment_panel,177,507,370,25,18)
 fashion_weapon_row = HBoxContainer.new()
 fashion_weapon_row.mouse_filter = Control.MOUSE_FILTER_PASS
 fashion_weapon_row.add_theme_constant_override("separation",18)
 equipment_panel.add_child(fashion_weapon_row)
 _rect(fashion_weapon_row,179,535,129,55)
 fashion_side_row = HBoxContainer.new()
 fashion_side_row.mouse_filter = Control.MOUSE_FILTER_PASS
 fashion_side_row.add_theme_constant_override("separation",18)
 equipment_panel.add_child(fashion_side_row)
 _rect(fashion_side_row,357,535,129,55)
 _label("Accessories",equipment_panel,195,586,330,24,18)
 accessory_row = HBoxContainer.new()
 accessory_row.mouse_filter = Control.MOUSE_FILTER_PASS
 accessory_row.add_theme_constant_override("separation",23)
 equipment_panel.add_child(accessory_row)
 _rect(accessory_row,139,614,374,55)
 _label("Fashion",equipment_panel,194,669,330,23,18)
 fashion_row = HBoxContainer.new()
 fashion_row.mouse_filter = Control.MOUSE_FILTER_PASS
 fashion_row.add_theme_constant_override("separation",23)
 equipment_panel.add_child(fashion_row)
 _rect(fashion_row,139,692,374,55)
 bag_panel = Control.new()
 bag_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage.add_child(bag_panel)
 _rect(bag_panel,0,0,W,H)
 _red_panel(bag_panel,677,200,698,397)
 _label("Bag",bag_panel,733,211,228,30,22)
 capacity_text = _label("",bag_panel,1031,211,300,30,18)
 bag_grid = GridContainer.new()
 bag_grid.mouse_filter = Control.MOUSE_FILTER_PASS
 bag_grid.columns = 10
 bag_grid.add_theme_constant_override("h_separation",6)
 bag_grid.add_theme_constant_override("v_separation",5)
 bag_panel.add_child(bag_grid)
 _rect(bag_grid,729,249,600,295)
 for i in range(4):
  var x: float = [780.0,854.0,1169.0,1243.0][i]
  var button := _hitbox(bag_panel,x,546,57,44,_page_button.bind([0,1,3,4][i]))
  button.text = ["<<","<",">",">>"][i]
  _style_text_button(button,25)
  _red_button(button,"pager_button",true)
  page_buttons.append(button)
 page_text = _label("",bag_panel,931,545,224,45,20)
 currency_panel = Control.new()
 currency_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 bag_panel.add_child(currency_panel)
 _rect(currency_panel,0,0,W,H)
 _red_panel(currency_panel,677,605,698,160)
 for i in range(4):
  var money: String = MONEY[i]
  var row_y: float = 620.0 + float(i)*34.0
  _red_panel(currency_panel,717,row_y,621,34,"currency_row")
  _art("icon_"+money,currency_panel,741,row_y+5,23,23,false)
  _label(money.capitalize(),currency_panel,773,row_y,118,33,16,HORIZONTAL_ALIGNMENT_LEFT)
  money_labels[money] = _label("0",currency_panel,944,row_y,297,33,17,HORIZONTAL_ALIGNMENT_RIGHT,false)
  var money_button := _hitbox(currency_panel,1270,row_y+1,47,32,func(): set_notice("Cash Shop is not available yet"))
  money_button.text = "+"
  _style_text_button(money_button,18)
  _red_button(money_button,"pager_button",true)
 _red_panel(stage,74,782,1301,104,"inner_panel")
 var foot_names := ["Demo Items","Save","Auto Sort","Trash","Equip","Close"]
 var foot_x := [105.0,315.0,525.0,735.0,945.0,1155.0]
 for i in range(6):
  var action: Callable
  match i:
   0: action = func(): demo_callback.call()
   1: action = _save_game
   2: action = func(): _hide_details(); game_store.call("sort_items")
   3: action = _request_trash
   4: action = _equip_action
   _: action = func(): _hide_details(); close_callback.call()
  var button := _hitbox(stage,foot_x[i],807,185,53,action)
  button.text = _tr(foot_names[i])
  button.set_meta("l10n",foot_names[i])
  _style_text_button(button,18)
  _red_button(button,"close_button" if i==5 else "action_button")
  footer_buttons.append(button)
 waiting_panel = Control.new()
 waiting_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 stage.add_child(waiting_panel)
 _rect(waiting_panel,679,200,693,563)
 _red_panel(waiting_panel,0,0,693,563)
 waiting_text = _label("",waiting_panel,39,115,615,180,24)
 waiting_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 waiting_panel.visible = false
 notice_text = _label("",stage,317,750,814,27,16)
 trash_dialog = ConfirmationDialog.new()
 if ui_font != null:
  var dialog_theme := Theme.new()
  dialog_theme.default_font = ui_font
  trash_dialog.theme = dialog_theme
 trash_dialog.confirmed.connect(_confirm_trash)
 add_child(trash_dialog)
 _create_details()
 visibility_changed.connect(func():
  if not is_visible_in_tree():
   _hide_details()
   trash_dialog.hide()
 )


func _style_text_button(button: Button, font_size: int) -> void:
 if ui_font != null: button.add_theme_font_override("font",ui_font)
 button.add_theme_font_size_override("font_size",font_size)
 button.add_theme_color_override("font_color",Color("#ffde93"))
 button.add_theme_color_override("font_hover_color",Color.WHITE)
 button.add_theme_color_override("font_pressed_color",Color("#67e9ff"))

func _equip_action() -> void:
 if selected_equipment != "":
  game_store.call("unequip",selected_equipment)
 else:
  game_store.call("equip_selected")
 _hide_details()

func _equip_icon(key: String, active: String) -> String:
 if active != "": return active
 if key.begins_with("fashion_"):
  var suffix = key.trim_prefix("fashion_")
  if suffix in ["hat","shirt","gloves","pants","shoes"]: return suffix
  return key
 if key.begins_with("ring"): return "ring"
 if key.begins_with("bracelet"): return "bracelet"
 return key

func _image_button(parent: Node, x: float, y: float, wh: float, key: String, state: String, height: float = -1.0) -> TextureButton:
 var b := TextureButton.new()
 b.mouse_filter = Control.MOUSE_FILTER_PASS
 b.ignore_texture_size = true
 b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
 b.focus_mode = Control.FOCUS_ALL
 # One separate matte-red PNG per slot state, without baked text.
 var background: String = "slot_locked" if state == "locked" else ("slot_selected" if state == "selected" else "slot_empty")
 b.texture_normal = _red_texture(background)
 b.set_meta("locked",state=="locked")
 parent.add_child(b)
 var hh: float = wh if height < 0.0 else height
 _rect(b,x,y,wh,hh)
 b.custom_minimum_size = Vector2(wh,hh)
 if key != "" and state != "locked":
  var art: Texture2D = _texture("icon_"+key)
  if art != null:
   var icon := TextureRect.new()
   icon.texture = art
   icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
   b.add_child(icon)
   _rect(icon,wh*0.18,hh*0.18,wh*0.64,hh*0.64)
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
  var by: float = float(i)*54.0 if direction == "v" else 0.0
  var b := _image_button(container,0,by,width,active,"selected" if selected_equipment==key else "normal")
  b.set_meta("equipment_key",key)
  b.mouse_entered.connect(func():
   if not DisplayServer.is_touchscreen_available(): _show_details(active,key,false)
  )
  b.mouse_exited.connect(_hide_hover_details)
  b.pressed.connect(func():
   selected_equipment = key
   game_store.set("selected",-1)
   details_pinned = true
   refresh()
   _show_details(active,key,false)
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
  var state: String = "locked" if is_locked else ("selected" if index == selected else "normal")
  var b := _image_button(bag_grid,0,0,54,item_id,state)
  b.set_meta("slot_index",index)
  b.mouse_entered.connect(func():
   if not DisplayServer.is_touchscreen_available(): _show_details(item_id,"",is_locked)
  )
  b.mouse_exited.connect(_hide_hover_details)
  if not is_locked:
   b.pressed.connect(_pick_item.bind(index))
  else:
   b.pressed.connect(func():
    details_pinned = true
    _show_details("","",true)
   )
 var shown: int = maxi(0,mini(50,unlocked-current_page*50))
 capacity_text.text = str(shown)+" / 50 · "+str(unlocked)+" / 200"
 page_text.text = ("หน้า " if locale=="th" else "PAGE ")+str(current_page+1)+" / 4"
 for i in range(page_buttons.size()):
  page_buttons[i].disabled = current_page==0 if i<2 else current_page==3
 var c: Dictionary = game_store.get("currency")
 for k in MONEY:
  var l: Label = money_labels[k]
  l.text = str(game_store.call("pretty",str(c.get(k,"0"))))

func _pick_item(index: int) -> void:
 # Inspecting a second item must not silently swap two inventory entries.
 selected_equipment = ""
 game_store.set("selected",-1)
 game_store.call("choose",index)
 details_pinned = true
 var items: Array = game_store.get("slots")
 _show_details(str(items[index]),"",false)
 _reveal_slot(bag_grid.get_child(index%50))

func _reveal_slot(button: Control) -> void:
 if size.x >= 1000 and size.y >= 700: return
 await get_tree().process_frame
 if is_instance_valid(button): scroller.ensure_control_visible(button)

func _page_button(index: int) -> void:
 _hide_details()
 match index:
  0: current_page=0
  1: current_page=maxi(0,current_page-1)
  3: current_page=mini(3,current_page+1)
  4: current_page=3
 refresh()

func _change_page(page: int) -> void:
 _hide_details()
 current_page=clampi(page,0,3)
 refresh()

func _switch_tab(index: int) -> void:
 _hide_details()
 current_tab=clampi(index,0,3)
 if is_built: _adapt_layout()

func _adapt_layout() -> void:
 if not is_built: return
 # Desktop / laptop landscape: inventory floats in the middle, about 75% of width.
 # On narrow touch screens, preserve at least 44px tap targets and allow panning.
 var desktop: bool = size.x >= 1050.0 and size.y >= 680.0
 var ratio: float
 if desktop:
  ratio = minf(size.x*0.75/W,size.y*0.84/H)
 else:
  ratio = maxf(0.82,minf(size.x/W,size.y/H))
 stage.scale = Vector2(ratio,ratio)
 scroll_content.custom_minimum_size = Vector2(W,H)*ratio
 stage.position = Vector2(maxf(0.0,(size.x-W*ratio)*0.5),maxf(0.0,(size.y-H*ratio)*0.5))
 equipment_panel.visible = current_tab in [0,1]
 bag_panel.visible = current_tab==0
 waiting_panel.visible = current_tab>=2
 if waiting_panel.visible:
  waiting_text.text = _tr("Skills are not available yet" if current_tab==2 else "Shop is not available yet")
 for i in range(tab_buttons.size()):
  tab_buttons[i].add_theme_color_override("font_color",Color.WHITE if i==current_tab else Color("#ffde93"))
  _red_button(tab_buttons[i],"tab_active" if i==current_tab else "tab_idle")
 if current_tab != 0:
  _hide_details()
 _layout_details()

func refresh() -> void:
 if not is_built or game_store==null: return
 _refresh_equipment(main_equip_list,MAIN_EQUIPMENT,54,0,"v")
 _refresh_equipment(extra_equip_list,RIGHT_EQUIPMENT,54,0,"v")
 _refresh_equipment(fashion_weapon_row,FASHION_WEAPONS,61,17,"h")
 _refresh_equipment(fashion_side_row,FASHION_SIDES,61,17,"h")
 _refresh_equipment(accessory_row,JEWELRY,61,17,"h")
 _refresh_equipment(fashion_row,FASHION,61,17,"h")
 _fill_bag()
 footer_buttons[4].text = _tr("Unequip" if selected_equipment != "" else "Equip")

func set_language(value: String) -> void:
 locale="th" if value.begins_with("th") else "en"
 _translate(self)
 if is_built:
  refresh()
  _adapt_layout()
 _hide_details()

func _translate(node: Node) -> void:
 if node.has_meta("l10n"):
  node.set("text",_tr(str(node.get_meta("l10n"))))
 for ch in node.get_children(): _translate(ch)

func set_notice(msg: String) -> void:
 if is_instance_valid(notice_text): notice_text.text=_tr(msg)

func _request_trash() -> void:
 var selected: int = int(game_store.get("selected"))
 var items: Array = game_store.get("slots")
 if selected<0 or selected>=items.size() or str(items[selected])=="":
  set_notice("Select an item first")
 else:
  pending_trash_index = selected
  pending_trash_item = str(items[selected])
  trash_dialog.title = _tr("Discard item?")
  trash_dialog.dialog_text = _tr("Discard selected item permanently?")
  trash_dialog.get_ok_button().text = _tr("Trash")
  trash_dialog.get_cancel_button().text = _tr("Cancel")
  _hide_details()
  trash_dialog.popup_centered(Vector2i(360,170))

func _save_game() -> void:
 if game_store.call("save_data"):
  set_notice("Saved")
 else:
  set_notice("Save failed")

func _confirm_trash() -> void:
 var items: Array = game_store.get("slots")
 if pending_trash_index >= 0 and pending_trash_index < items.size() and str(items[pending_trash_index]) == pending_trash_item:
  game_store.set("selected",pending_trash_index)
  game_store.call("trash_selected")
 pending_trash_index = -1

func _create_details() -> void:
 # Details replace the currency area, never overlap the item grid or slots.
 detail_panel = PanelContainer.new()
 detail_panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
 detail_panel.mouse_filter = Control.MOUSE_FILTER_STOP
 stage.add_child(detail_panel)
 _rect(detail_panel,680,605,692,160)
 detail_content = Control.new()
 var content := detail_content
 detail_panel.add_child(content)
 detail_art = _red_panel(content,0,0,692,160)
 detail_icon = _art("",content,108,48,58,58,false)
 detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 detail_heading = _label("",content,184,18,385,30,20,HORIZONTAL_ALIGNMENT_LEFT)
 detail_description = _label("",content,184,49,385,90,16,HORIZONTAL_ALIGNMENT_LEFT,false)
 detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 detail_description.vertical_alignment = VERTICAL_ALIGNMENT_TOP
 detail_description.clip_text = true
 var dismiss := _hitbox(content,620,19,47,43,_hide_details)
 detail_dismiss = dismiss
 dismiss.text = "X"
 _style_text_button(dismiss,20)
 _red_button(dismiss,"close_button",true)
 detail_panel.visible = false

func _show_details(item: String, equipment_key: String = "", locked: bool = false) -> void:
 if not is_instance_valid(detail_panel) or not is_visible_in_tree(): return
 if locked:
  detail_heading.text = _tr("Locked slot")
  detail_description.text = _tr("Unlock by expanding your bag.")
  detail_icon.texture = _texture("icon_lock")
 elif item!="":
  var info: Dictionary = StoreScript.DATA.get(item,{})
  detail_heading.text = _tr(str(info.get("name",item)))
  var lines: PackedStringArray = []
  if info.has("kind"): lines.append(_tr(str(info.kind)))
  if info.has("slot"): lines.append(_tr(str(SLOT_NAMES.get(info.slot,info.slot))))
  if info.has("level"): lines.append(_tr("Item Level")+": "+str(info.level))
  if info.has("stats"):
   for stat in info.stats: lines.append(_tr(str(stat))+": "+str(info.stats[stat]))
  if info.has("description"): lines.append(_tr(str(info.description)))
  if not info.has("stats") and not info.has("description"):
   lines.append(_tr("No stats or description in item data."))
  detail_description.text = "\n".join(lines)
  detail_icon.texture = _texture("icon_"+item)
 else:
  detail_heading.text = _tr(str(SLOT_NAMES.get(equipment_key,"Empty slot")))
  detail_description.text = _tr("Empty equipment slot" if equipment_key!="" else "Empty slot")
  detail_icon.texture = null
 detail_panel.visible = true
 currency_panel.visible = false
 _layout_details()

func _hide_hover_details() -> void:
 if not details_pinned: _hide_details()

func _hide_details() -> void:
 details_pinned = false
 if is_instance_valid(detail_panel): detail_panel.visible = false
 if is_instance_valid(currency_panel): currency_panel.visible = true
 if is_built: _layout_details()

func _layout_details() -> void:
 if not is_instance_valid(detail_panel): return
 var compact: bool = size.x < 1050.0 or size.y < 680.0
 var dock_height: float = minf(270.0,size.y*0.6) if compact and detail_panel.visible else 0.0
 _rect(scroller,0,0,size.x,maxf(0.0,size.y-dock_height))
 var target: Node = viewport_wrapper if compact else stage
 if detail_panel.get_parent() != target:
  detail_panel.reparent(target,false)
 if compact:
  var dw: float = minf(692.0,size.x)
  var dh: float = maxf(210.0,dock_height)
  _rect(detail_panel,(size.x-dw)*0.5,size.y-dh,dw,dh)
  _rect(detail_art,0,0,dw,dh)
  var left: float = dw*0.12
  var text_x: float = left+58.0
  var text_width: float = maxf(80.0,dw*0.87-text_x)
  _rect(detail_icon,left,dh*0.31,48,48)
  _rect(detail_heading,text_x,dh*0.16,text_width,52)
  detail_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  _rect(detail_description,text_x,dh*0.16+57,text_width,dh*0.68-57)
  _rect(detail_dismiss,dw*0.87,dh*0.11,44,44)
 else:
  _rect(detail_panel,680,605,692,160)
  _rect(detail_art,0,0,692,160)
  _rect(detail_icon,108,48,58,58)
  _rect(detail_heading,184,18,385,30)
  _rect(detail_description,184,49,385,90)
  _rect(detail_dismiss,620,19,47,43)

func _notification(what: int) -> void:
 if what==NOTIFICATION_RESIZED and is_built: _adapt_layout()

# Handle real screen drags independently of Web mouse-emulation routing.
var pan_finger: int = -1
var pan_origin := Vector2.ZERO
var pan_scroll := Vector2.ZERO
var pan_active := false

func _input(event: InputEvent) -> void:
 if not is_built or not is_visible_in_tree(): return
 if event is InputEventScreenTouch:
  if event.pressed and pan_finger == -1 and scroller.get_global_rect().has_point(event.position):
   pan_finger = event.index
   pan_origin = event.position
   pan_scroll = Vector2(scroller.scroll_horizontal,scroller.scroll_vertical)
   pan_active = false
  elif not event.pressed and event.index == pan_finger:
   if pan_active:
    scroller.propagate_notification(Control.NOTIFICATION_SCROLL_END)
    get_viewport().set_input_as_handled()
   pan_finger = -1
   pan_active = false
 elif event is InputEventScreenDrag and event.index == pan_finger:
  var delta: Vector2 = pan_origin-event.position
  if not pan_active and delta.length() > 12.0:
   pan_active = true
   scroller.propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
   _hide_details()
  if pan_active:
   scroller.scroll_horizontal = int(pan_scroll.x+delta.x)
   scroller.scroll_vertical = int(pan_scroll.y+delta.y)
   get_viewport().set_input_as_handled()

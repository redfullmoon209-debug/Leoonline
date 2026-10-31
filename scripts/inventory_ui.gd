extends PanelContainer
## Real responsive Godot UI assembled from independently drawn transparent PNG textures.
## No screenshot crops and no labels baked into images.
const ASSETS := "res://assets/ui/inventory/"
const FONT_PATH := "res://assets/fonts/NotoSansThai.ttf"
const THAI := {
 "Inventory":"กระเป๋า","Character":"ตัวละคร","Skill":"สกิล","Shop":"ร้านค้า",
 "EQUIPMENT":"อุปกรณ์สวมใส่","BAG":"กระเป๋าเก็บของ",
 "FASHION WEAPONS · MASK · CAPE":"อาวุธแฟชั่น · หน้ากาก · ผ้าคลุม",
 "ACCESSORIES":"เครื่องประดับ","FASHION":"ชุดแฟชั่น",
 "DEMO ITEMS":"ไอเทมตัวอย่าง","SAVE":"บันทึก","AUTO SORT":"เรียงไอเทม",
 "TRASH":"ทิ้ง","EQUIP":"สวมใส่","CLOSE":"ปิด","BACK TO INVENTORY":"กลับกระเป๋า",
 "Gold":"ทอง","Blue":"เพชรฟ้า","Purple":"เพชรม่วง","Green":"เพชรเขียว"
}
const StoreScript = preload("res://scripts/store.gd")
const EQUIP_NAMES := {
 "hat":"Hat", "shirt":"Shirt", "gloves":"Gloves", "pants":"Pants", "shoes":"Shoes",
 "weapon_right":"Right Weapon", "weapon_left":"Left Weapon", "pet":"Pet", "mount":"Mount",
 "bracelet_left":"Left Bracelet", "ring_left":"Left Ring", "necklace":"Necklace",
 "ring_right":"Right Ring", "bracelet_right":"Right Bracelet",
 "fashion_hat":"Fashion Hat", "fashion_shirt":"Fashion Shirt", "fashion_gloves":"Fashion Gloves",
 "fashion_pants":"Fashion Pants", "fashion_shoes":"Fashion Shoes",
 "fashion_weapon_right":"Fashion Right", "fashion_weapon_left":"Fashion Left",
 "fashion_mask":"Fashion Mask", "fashion_cape":"Fashion Cape"
}
const EQ_MAIN := ["hat","shirt","gloves","pants","shoes"]
const EQ_RIGHT := ["weapon_right","weapon_left","pet","mount"]
const EQ_JEWELRY := ["bracelet_left","ring_left","necklace","ring_right","bracelet_right"]
const EQ_FASHION := ["fashion_hat","fashion_shirt","fashion_gloves","fashion_pants","fashion_shoes"]
const EQ_FASHION_WEAPON := ["fashion_weapon_right","fashion_weapon_left"]
const EQ_FASHION_SIDE := ["fashion_mask","fashion_cape"]
const MONEY := ["gold","blue","purple","green"]
var game_store: Node
var close_callback: Callable
var demo_callback: Callable
var current_page := 0
var current_tab := 0
var tab_buttons: Array[Button] = []
var equipment_panel: PanelContainer
var bag_panel: PanelContainer
var waiting_panel: PanelContainer
var waiting_title: Label
var waiting_message: Label
var body_row: HBoxContainer
var main_equip_list: VBoxContainer
var extra_equip_list: VBoxContainer
var accessory_row: HBoxContainer
var fashion_row: HBoxContainer
var fashion_weapon_row: HBoxContainer
var fashion_side_row: HBoxContainer
var detail_layer: CanvasLayer
var detail_panel: PanelContainer
var detail_icon: TextureRect
var detail_heading: Label
var detail_description: Label
var ui_font: Font
var locale: String = "en"
var language_button: Button
var bag_grid: GridContainer
var page_text: Label
var capacity_text: Label
var money_labels: Dictionary = {}
var notice_text: Label
var trash_dialog: ConfirmationDialog
var is_built := false

func initialize(p_store: Node, p_close: Callable, p_demo: Callable) -> void:
 game_store = p_store
 close_callback = p_close
 demo_callback = p_demo
 if ResourceLoader.exists(FONT_PATH):
  ui_font = load(FONT_PATH) as Font
 _make_interface()
 is_built = true
 refresh()
 _adapt_layout()

func _tr_ui(label: String) -> String:
 return str(THAI.get(label,label)) if locale == "th" else label

func set_language(value: String) -> void:
 locale = "th" if value.begins_with("th") else "en"
 _translate_node(self)
 if is_instance_valid(language_button):
  language_button.text = "EN" if locale == "th" else "TH"
 if is_built:
  _fill_bag()
  _hide_details()

func _translate_node(node: Node) -> void:
 if node.has_meta("localization_key"):
  node.set("text",_tr_ui(str(node.get_meta("localization_key"))))
 for child in node.get_children():
  _translate_node(child)

func _texture(name: String) -> Texture2D:
 var path := ASSETS + name + ".png"
 if ResourceLoader.exists(path):
  return load(path) as Texture2D
 return null

func _flat_style(color: Color = Color("#091e3d"), edge: Color = Color("#e7bd72")) -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color = color
 style.border_color = edge
 style.set_border_width_all(2)
 style.set_corner_radius_all(8)
 style.set_content_margin_all(6)
 return style

func _skin(name: String, margin: int = 20, content: int = 6) -> StyleBox:
 var t := _texture(name)
 if t == null:
  return _flat_style()
 var s := StyleBoxTexture.new()
 s.texture = t
 s.texture_margin_left = margin
 s.texture_margin_top = margin
 s.texture_margin_right = margin
 s.texture_margin_bottom = margin
 s.content_margin_left = content
 s.content_margin_top = content
 s.content_margin_right = content
 s.content_margin_bottom = content
 return s

func _text(value: String, parent: Node, sz: int = 16, gold: bool = false) -> Label:
 var l := Label.new()
 l.text = _tr_ui(value)
 if THAI.has(value):
  l.set_meta("localization_key",value)
 if ui_font != null:
  l.add_theme_font_override("font",ui_font)
 l.add_theme_font_size_override("font_size", sz)
 l.add_theme_color_override("font_color", Color("#ffe3a2") if gold else Color("#e9f5ff"))
 l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.88))
 l.add_theme_constant_override("shadow_offset_x", 1)
 l.add_theme_constant_override("shadow_offset_y", 1)
 parent.add_child(l)
 return l

func _vbox(parent: Node, spacing: int = 4) -> VBoxContainer:
 var v := VBoxContainer.new()
 v.add_theme_constant_override("separation", spacing)
 parent.add_child(v)
 return v

func _hbox(parent: Node, spacing: int = 5) -> HBoxContainer:
 var h := HBoxContainer.new()
 h.add_theme_constant_override("separation", spacing)
 parent.add_child(h)
 return h

func _panel(parent: Node, skin: String = "frame_panel", margin: int = 28) -> PanelContainer:
 var p := PanelContainer.new()
 p.add_theme_stylebox_override("panel", _skin(skin,margin,12))
 p.size_flags_vertical = Control.SIZE_EXPAND_FILL
 parent.add_child(p)
 return p

func _button(text_value: String, parent: Node, icon_name: String = "", skin: String = "button_blue", minimum: Vector2 = Vector2(110,42)) -> Button:
 var b := Button.new()
 b.text = _tr_ui(text_value)
 if THAI.has(text_value):
  b.set_meta("localization_key",text_value)
 b.custom_minimum_size = minimum
 if ui_font != null:
  b.add_theme_font_override("font",ui_font)
 b.add_theme_stylebox_override("normal",_skin(skin,21,5))
 b.add_theme_stylebox_override("hover",_skin("button_gold",21,5))
 b.add_theme_stylebox_override("pressed",_skin("tab_gold",21,5))
 b.add_theme_stylebox_override("disabled",_skin("button_blue",21,5))
 b.add_theme_color_override("font_color",Color("#fff1d0"))
 b.add_theme_color_override("font_hover_color",Color("#ffffff"))
 b.add_theme_color_override("font_pressed_color",Color("#ffffff"))
 b.add_theme_font_size_override("font_size",14)
 b.alignment = HORIZONTAL_ALIGNMENT_CENTER
 parent.add_child(b)
 if icon_name != "":
  var icon_resource := _texture("icon_"+icon_name)
  if icon_resource != null:
   var icon_rect := TextureRect.new()
   icon_rect.texture = icon_resource
   icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
   b.add_child(icon_rect)
   icon_rect.anchor_top = 0.5
   icon_rect.anchor_bottom = 0.5
   icon_rect.offset_left = 12
   icon_rect.offset_right = 38
   icon_rect.offset_top = -13
   icon_rect.offset_bottom = 13
   icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 return b

func _make_interface() -> void:
 add_theme_stylebox_override("panel",_skin("frame_main",32,12))
 var outer := _vbox(self,3)
 outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
 # Decorative crest is an independently generated PNG; lettering is Godot text.
 var banner_holder := Control.new()
 banner_holder.custom_minimum_size.y = 76
 banner_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 outer.add_child(banner_holder)
 var banner := TextureRect.new()
 banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 banner.texture = _texture("banner")
 banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
 banner_holder.add_child(banner)
 var name_label := Label.new()
 name_label.text = "✦ LEOONLINE ✦"
 name_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 if ui_font != null:
  name_label.add_theme_font_override("font",ui_font)
 name_label.add_theme_font_size_override("font_size",32)
 name_label.add_theme_color_override("font_color",Color("#ffdb8a"))
 name_label.add_theme_color_override("font_shadow_color",Color("#000000"))
 name_label.add_theme_constant_override("shadow_offset_y",2)
 name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 banner_holder.add_child(name_label)
 language_button = _button("TH",banner_holder,"","button_blue",Vector2(62,34))
 language_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 language_button.offset_left = -74
 language_button.offset_right = -10
 language_button.offset_top = 20
 language_button.offset_bottom = 54
 language_button.pressed.connect(func(): set_language("th" if locale == "en" else "en"))
 var tabs := _hbox(outer,8)
 tabs.custom_minimum_size.y = 58
 for idx in range(4):
  var names := ["Inventory","Character","Skill","Shop"]
  var icons := ["inventory","character","skill","shop"]
  var t := _button(names[idx],tabs,icons[idx],"tab_blue",Vector2(135,55))
  t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  t.pressed.connect(_switch_tab.bind(idx))
  tab_buttons.append(t)
 var space := Control.new()
 space.custom_minimum_size.y = 2
 outer.add_child(space)
 body_row = _hbox(outer,9)
 body_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
 body_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 equipment_panel = _panel(body_row)
 equipment_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 equipment_panel.size_flags_stretch_ratio = 0.88
 _create_equipment_panel()
 bag_panel = _panel(body_row)
 bag_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 bag_panel.size_flags_stretch_ratio = 1.12
 _create_bag_panel()
 waiting_panel = _panel(body_row)
 waiting_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 _create_waiting_panel()
 waiting_panel.visible = false
 var footer := HFlowContainer.new()
 footer.alignment = FlowContainer.ALIGNMENT_CENTER
 footer.add_theme_constant_override("h_separation",6)
 footer.add_theme_constant_override("v_separation",3)
 footer.custom_minimum_size.y = 51
 outer.add_child(footer)
 _button("DEMO ITEMS",footer,"inventory","button_blue",Vector2(124,46)).pressed.connect(func(): demo_callback.call())
 _button("SAVE",footer,"","button_blue",Vector2(100,46)).pressed.connect(_save_game)
 _button("AUTO SORT",footer,"","button_gold",Vector2(128,46)).pressed.connect(func(): game_store.call("sort_items"))
 _button("TRASH",footer,"","button_blue",Vector2(102,46)).pressed.connect(_request_trash)
 _button("EQUIP",footer,"weapon_right","button_blue",Vector2(108,46)).pressed.connect(func(): game_store.call("equip_selected"))
 _button("CLOSE",footer,"","button_red",Vector2(105,46)).pressed.connect(func(): close_callback.call())
 notice_text = _text("",outer,12)
 notice_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 notice_text.custom_minimum_size.y = 16
 trash_dialog = ConfirmationDialog.new()
 trash_dialog.title = "Confirm discard"
 trash_dialog.dialog_text = "Discard selected item permanently?"
 trash_dialog.confirmed.connect(func(): game_store.call("trash_selected"))
 add_child(trash_dialog)
 _create_details()

func _create_equipment_panel() -> void:
 var scroll := ScrollContainer.new()
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 equipment_panel.add_child(scroll)
 var column := _vbox(scroll,5)
 column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var title := _text("EQUIPMENT",column,20,true)
 title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var upper := _hbox(column,12)
 upper.alignment = BoxContainer.ALIGNMENT_CENTER
 upper.custom_minimum_size.y = 250
 main_equip_list = _vbox(upper,2)
 main_equip_list.custom_minimum_size.x = 74
 var portrait := TextureRect.new()
 portrait.texture = _texture("character_silhouette")
 portrait.custom_minimum_size = Vector2(230,250)
 portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
 upper.add_child(portrait)
 extra_equip_list = _vbox(upper,3)
 extra_equip_list.custom_minimum_size.x = 74
 _text("FASHION WEAPONS · MASK · CAPE",column,13,true).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var weapon_panel := _panel(column,"frame_fashion",28)
 weapon_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
 var cosmetic_line := _hbox(weapon_panel,8)
 cosmetic_line.alignment = BoxContainer.ALIGNMENT_CENTER
 fashion_weapon_row = _hbox(cosmetic_line,6)
 fashion_side_row = _hbox(cosmetic_line,6)
 _text("ACCESSORIES",column,15,true).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 accessory_row = _hbox(column,6)
 accessory_row.alignment = BoxContainer.ALIGNMENT_CENTER
 _text("FASHION",column,15,true).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 fashion_row = _hbox(column,6)
 fashion_row.alignment = BoxContainer.ALIGNMENT_CENTER

func _create_bag_panel() -> void:
 var column := _vbox(bag_panel,7)
 column.size_flags_vertical = Control.SIZE_EXPAND_FILL
 column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var header := _hbox(column,8)
 var title := _text("BAG",header,20,true)
 title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 capacity_text = _text("40 / 50 Slots · 1/4",header,16,true)
 var scroller := ScrollContainer.new()
 scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 column.add_child(scroller)
 bag_grid = GridContainer.new()
 bag_grid.columns = 10
 bag_grid.add_theme_constant_override("h_separation",3)
 bag_grid.add_theme_constant_override("v_separation",3)
 bag_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
 scroller.add_child(bag_grid)
 var nav := _hbox(column,5)
 nav.alignment = BoxContainer.ALIGNMENT_CENTER
 _button("≪",nav,"","button_blue",Vector2(56,38)).pressed.connect(func(): _change_page(0))
 _button("‹",nav,"","button_blue",Vector2(48,38)).pressed.connect(func(): _change_page(current_page-1))
 page_text = _text("PAGE 1 / 4",nav,16,true)
 page_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 _button("›",nav,"","button_blue",Vector2(48,38)).pressed.connect(func(): _change_page(current_page+1))
 _button("≫",nav,"","button_blue",Vector2(56,38)).pressed.connect(func(): _change_page(3))
 var separator := TextureRect.new()
 separator.texture = _texture("divider")
 separator.custom_minimum_size.y = 12
 separator.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 separator.stretch_mode = TextureRect.STRETCH_SCALE
 column.add_child(separator)
 for money in MONEY:
  var row := _hbox(column,8)
  row.custom_minimum_size.y = 34
  var badge := TextureRect.new()
  badge.texture = _texture("icon_"+money)
  badge.custom_minimum_size = Vector2(28,28)
  badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  row.add_child(badge)
  var mlabel := _text(money.capitalize(),row,15,true)
  mlabel.custom_minimum_size.x = 72
  var amount := _text("0",row,15)
  amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
  amount.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  money_labels[money] = amount

func _create_waiting_panel() -> void:
 var column := _vbox(waiting_panel,14)
 column.alignment = BoxContainer.ALIGNMENT_CENTER
 waiting_title = _text("",column,26,true)
 waiting_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 waiting_message = _text("",column,17)
 waiting_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 waiting_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 _button("BACK TO INVENTORY",column,"inventory","button_gold",Vector2(190,52)).pressed.connect(func(): _switch_tab(0))

func _asset_for_key(key: String) -> String:
 if key.begins_with("fashion_"):
  var short_key := key.trim_prefix("fashion_")
  if short_key in ["hat","shirt","gloves","pants","shoes"]:
   return short_key
  if short_key in ["mask","cape"]:
   return "fashion_" + short_key
 if key.begins_with("ring_"):
  return "ring"
 if key.begins_with("bracelet_"):
  return "bracelet"
 return key

func _image_slot(parent: Node, icon_name: String, skin: String, dimensions: Vector2, locked: bool = false) -> TextureButton:
 var button := TextureButton.new()
 button.ignore_texture_size = true
 button.stretch_mode = TextureButton.STRETCH_SCALE
 button.custom_minimum_size = dimensions
 button.texture_normal = _texture(skin)
 button.texture_hover = _texture("slot_selected")
 button.texture_pressed = _texture("slot_selected")
 button.texture_disabled = _texture("slot_locked")
 button.disabled = locked
 button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
 parent.add_child(button)
 if icon_name != "" and not locked:
  var icon_image := _texture("icon_" + icon_name)
  if icon_image != null:
   var icon_rect := TextureRect.new()
   icon_rect.texture = icon_image
   icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
   button.add_child(icon_rect)
   icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
   icon_rect.offset_left = 9
   icon_rect.offset_top = 9
   icon_rect.offset_right = -9
   icon_rect.offset_bottom = -9
   icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
   icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 return button

func _equip_slot(parent: Node, key: String, width: int = 70, icon_only: bool = true, purple: bool = false) -> void:
 var equipped: Dictionary = game_store.get("equipped")
 var active: String = str(equipped.get(key,""))
 var chosen_icon: String = active if active != "" else _asset_for_key(key)
 var slot_skin := "slot_fashion" if purple else "slot_equipment"
 var b := _image_slot(parent, chosen_icon, slot_skin, Vector2(width,width))
 b.mouse_entered.connect(func(): _show_details(active,key,false))
 b.mouse_exited.connect(_hide_details)
 b.pressed.connect(func():
  _show_details(active,key,false)
  if active != "":
   game_store.call("unequip",key)
 )

func _refresh_equip_container(parent: Node, keys: Array, width: int, icon_only: bool = false, purple: bool = false) -> void:
 for child in parent.get_children():
  parent.remove_child(child)
  child.queue_free()
 for key in keys:
  _equip_slot(parent,key,width,icon_only,purple)

func _fill_bag() -> void:
 for child in bag_grid.get_children():
  bag_grid.remove_child(child)
  child.queue_free()
 var items: Array = game_store.get("slots")
 var unlocked: int = int(game_store.get("unlocked"))
 var selected: int = int(game_store.get("selected"))
 for i in range(50):
  var index: int = current_page * 50 + i
  var locked: bool = index >= unlocked
  var item: String = str(items[index])
  var slot_skin: String = "slot_locked" if locked else ("slot_selected" if selected == index else "slot_normal")
  var button: TextureButton = _image_slot(bag_grid,item if not locked else "",slot_skin,Vector2(56,56),locked)
  button.mouse_entered.connect(func(): _show_details(item,"",locked))
  button.mouse_exited.connect(_hide_details)
  if not locked:
   button.pressed.connect(_bag_pressed.bind(index))
 var shown: int = maxi(0,mini(50,unlocked-current_page*50))
 capacity_text.text = str(shown)+" / 50    ("+str(unlocked)+"/200)"
 page_text.text = ("หน้า " if locale=="th" else "PAGE ")+str(current_page+1)+" / 4"
 var currency: Dictionary = game_store.get("currency")
 for money in MONEY:
  var label: Label = money_labels[money]
  label.text = str(game_store.call("pretty",str(currency.get(money,"0"))))

func _bag_pressed(index: int) -> void:
 game_store.call("choose",index)
 var items: Array = game_store.get("slots")
 _show_details(str(items[index]),"",false)

func _change_page(next_page: int) -> void:
 current_page = clampi(next_page,0,3)
 refresh()

func _switch_tab(index: int) -> void:
 current_tab = clampi(index,0,3)
 _adapt_layout()
 for i in range(tab_buttons.size()):
  tab_buttons[i].add_theme_stylebox_override("normal",_skin("tab_gold" if i==current_tab else "tab_blue",20,5))

func _adapt_layout() -> void:
 if not is_built:
  return
 var narrow: bool = size.x < 950.0
 var compact: bool = size.x < 640.0
 bag_grid.columns = 5 if compact else (7 if narrow else 10)
 if current_tab == 0:
  equipment_panel.visible = not narrow
  bag_panel.visible = true
  waiting_panel.visible = false
 elif current_tab == 1:
  equipment_panel.visible = true
  bag_panel.visible = false
  waiting_panel.visible = false
 else:
  equipment_panel.visible = false
  bag_panel.visible = false
  waiting_panel.visible = true
  waiting_title.text = "SKILL" if current_tab == 2 else "SHOP"
  waiting_message.text = "Skill system is not implemented in this prototype yet." if current_tab == 2 else "Shop is not implemented in this prototype yet."

func refresh() -> void:
 if not is_built or game_store == null:
  return
 _refresh_equip_container(main_equip_list,EQ_MAIN,58,true)
 _refresh_equip_container(extra_equip_list,EQ_RIGHT,62,true)
 _refresh_equip_container(fashion_weapon_row,EQ_FASHION_WEAPON,73,true,true)
 _refresh_equip_container(fashion_side_row,EQ_FASHION_SIDE,73,true,true)
 _refresh_equip_container(accessory_row,EQ_JEWELRY,69,true)
 _refresh_equip_container(fashion_row,EQ_FASHION,69,true)
 _fill_bag()

func set_notice(msg: String) -> void:
 if is_instance_valid(notice_text):
  notice_text.text = msg

func _request_trash() -> void:
 var index: int = int(game_store.get("selected"))
 var items: Array = game_store.get("slots")
 if index < 0 or index >= items.size() or str(items[index]) == "":
  set_notice("Select an item before discarding")
  return
 trash_dialog.popup_centered()

func _save_game() -> void:
 game_store.call("save_data")
 set_notice("Game saved")

func _create_details() -> void:
 detail_layer = CanvasLayer.new()
 detail_layer.layer = 12
 add_child(detail_layer)
 detail_panel = PanelContainer.new()
 detail_panel.add_theme_stylebox_override("panel",_skin("frame_inner",28,13))
 detail_panel.custom_minimum_size = Vector2(310,132)
 detail_panel.size = Vector2(310,132)
 detail_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 detail_layer.add_child(detail_panel)
 var row := _hbox(detail_panel,9)
 row.mouse_filter = Control.MOUSE_FILTER_IGNORE
 detail_icon = TextureRect.new()
 detail_icon.custom_minimum_size = Vector2(64,64)
 detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 detail_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
 row.add_child(detail_icon)
 var column := _vbox(row,7)
 column.mouse_filter = Control.MOUSE_FILTER_IGNORE
 column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 detail_heading = _text("",column,16,true)
 detail_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 detail_heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
 detail_description = _text("",column,12)
 detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 detail_description.mouse_filter = Control.MOUSE_FILTER_IGNORE
 detail_panel.visible = false

func _show_details(item: String, equipment_key: String = "", locked: bool = false) -> void:
 if not is_instance_valid(detail_panel) or not is_visible_in_tree():
  return
 var information: Dictionary = StoreScript.DATA.get(item,{})
 if locked:
  detail_heading.text = "ช่องถูกล็อก" if locale=="th" else "Locked slot"
  detail_description.text = "ใช้ไอเทมขยายกระเป๋าเพื่อปลดล็อก" if locale=="th" else "Unlock using an inventory expansion item."
  detail_icon.texture = _texture("icon_lock")
 elif item != "":
  detail_heading.text = str(information.get("name",item))
  var kind: String = str(information.get("kind","other"))
  var slot: String = str(information.get("slot",""))
  detail_description.text = (("ประเภท: " if locale=="th" else "Type: ")+kind+"\n"+("ตำแหน่ง: " if locale=="th" else "Equip slot: ")+slot) if slot != "" else (("ประเภท: " if locale=="th" else "Type: ")+kind)
  detail_icon.texture = _texture("icon_"+item)
 else:
  var display_name: String = str(EQUIP_NAMES.get(equipment_key,"Empty bag slot"))
  detail_heading.text = (("ช่องว่าง: " if locale=="th" else "Empty: ")+display_name) if equipment_key != "" else ("ช่องว่าง" if locale=="th" else "Empty slot")
  detail_description.text = "คลิกไอเทมเพื่อเลือก หรือสวมใส่" if locale=="th" else "Select an item to view or equip it."
  detail_icon.texture = _texture("icon_"+_asset_for_key(equipment_key)) if equipment_key != "" else null
 var cursor: Vector2 = get_viewport().get_mouse_position()
 var viewport_size: Vector2 = get_viewport_rect().size
 detail_panel.position = Vector2(
  clampf(cursor.x+18,8.0,maxf(8.0,viewport_size.x-322.0)),
  clampf(cursor.y+18,8.0,maxf(8.0,viewport_size.y-144.0))
 )
 detail_panel.visible = true

func _hide_details() -> void:
 if is_instance_valid(detail_panel):
  detail_panel.visible = false

func _notification(what: int) -> void:
 if what == NOTIFICATION_RESIZED and is_built:
  _adapt_layout()

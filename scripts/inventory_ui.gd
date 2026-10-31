extends PanelContainer
## Real responsive Godot UI assembled from independently drawn transparent PNG textures.
## No screenshot crops and no labels baked into images.
const ASSETS := "res://assets/ui/inventory/"
const StoreScript = preload("res://scripts/store.gd")
const EQUIP_NAMES := {
 "hat":"Hat", "shirt":"Shirt", "gloves":"Gloves", "pants":"Pants", "shoes":"Shoes",
 "weapon_right":"Right Weapon", "weapon_left":"Left Weapon", "pet":"Pet", "mount":"Mount",
 "bracelet_left":"Left Bracelet", "ring_left":"Left Ring", "necklace":"Necklace",
 "ring_right":"Right Ring", "bracelet_right":"Right Bracelet",
 "fashion_hat":"Fashion Hat", "fashion_shirt":"Fashion Shirt", "fashion_gloves":"Fashion Gloves",
 "fashion_pants":"Fashion Pants", "fashion_shoes":"Fashion Shoes",
 "fashion_weapon_right":"Fashion Right", "fashion_weapon_left":"Fashion Left"
}
const EQ_MAIN := ["hat","shirt","gloves","pants","shoes"]
const EQ_RIGHT := ["weapon_right","weapon_left","pet","mount"]
const EQ_JEWELRY := ["bracelet_left","ring_left","necklace","ring_right","bracelet_right"]
const EQ_FASHION := ["fashion_hat","fashion_shirt","fashion_gloves","fashion_pants","fashion_shoes"]
const EQ_FASHION_WEAPON := ["fashion_weapon_right","fashion_weapon_left"]
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
 _make_interface()
 is_built = true
 refresh()
 _adapt_layout()

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
 l.text = value
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
 b.text = text_value
 b.custom_minimum_size = minimum
 b.add_theme_stylebox_override("normal",_skin(skin,21,5))
 b.add_theme_stylebox_override("hover",_skin("button_gold",21,5))
 b.add_theme_stylebox_override("pressed",_skin("tab_gold",21,5))
 b.add_theme_stylebox_override("disabled",_skin("button_blue",21,5))
 b.add_theme_color_override("font_color",Color("#fff1d0"))
 b.add_theme_color_override("font_hover_color",Color("#ffffff"))
 b.add_theme_color_override("font_pressed_color",Color("#ffffff"))
 b.add_theme_font_size_override("font_size",14)
 b.alignment = HORIZONTAL_ALIGNMENT_CENTER
 if icon_name != "":
  b.icon = _texture("icon_"+icon_name)
  b.expand_icon = true
 parent.add_child(b)
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
 name_label.add_theme_font_size_override("font_size",32)
 name_label.add_theme_color_override("font_color",Color("#ffdb8a"))
 name_label.add_theme_color_override("font_shadow_color",Color("#000000"))
 name_label.add_theme_constant_override("shadow_offset_y",2)
 name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 banner_holder.add_child(name_label)
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

func _create_equipment_panel() -> void:
 var scroll := ScrollContainer.new()
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 equipment_panel.add_child(scroll)
 var column := _vbox(scroll,5)
 column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var title := _text("✦  EQUIPMENT",column,19,true)
 title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var upper := _hbox(column,7)
 upper.alignment = BoxContainer.ALIGNMENT_CENTER
 main_equip_list = _vbox(upper,3)
 main_equip_list.custom_minimum_size.x = 128
 var portrait := TextureRect.new()
 portrait.texture = _texture("character_silhouette")
 portrait.custom_minimum_size = Vector2(140,242)
 portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
 upper.add_child(portrait)
 extra_equip_list = _vbox(upper,3)
 extra_equip_list.custom_minimum_size.x = 122
 _text("อาวุธแฟชั่น  ·  FASHION WEAPON",column,14,true).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var weapon_panel := _panel(column,"frame_fashion",27)
 weapon_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
 fashion_weapon_row = _hbox(weapon_panel,8)
 fashion_weapon_row.alignment = BoxContainer.ALIGNMENT_CENTER
 _text("✧ ACCESSORIES ✧",column,14,true).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 accessory_row = _hbox(column,3)
 accessory_row.alignment = BoxContainer.ALIGNMENT_CENTER
 _text("✧ FASHION ✧",column,14,true).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 fashion_row = _hbox(column,3)
 fashion_row.alignment = BoxContainer.ALIGNMENT_CENTER

func _create_bag_panel() -> void:
 var column := _vbox(bag_panel,7)
 column.size_flags_vertical = Control.SIZE_EXPAND_FILL
 column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var header := _hbox(column,8)
 var title := _text("✦ BAG",header,20,true)
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
 bag_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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

func _equip_slot(parent: Node, key: String, width: int = 120, icon_only: bool = false, purple: bool = false) -> void:
 var active: String = str(game_store.get("equipped").get(key,""))
 var skin := "slot_fashion" if purple else "slot_equipment"
 var display := EQUIP_NAMES.get(key,key)
 var b := _button("" if icon_only else str(display),parent,"",skin,Vector2(width,47 if not icon_only else 54))
 b.tooltip_text = str(display) + (" : " + active if active != "" else " · Empty") + " · Click to unequip"
 b.add_theme_font_size_override("font_size",12)
 b.icon = _texture("icon_" + (active if active != "" else key))
 if b.icon == null:
  if key.contains("ring"): b.icon = _texture("icon_ring")
  elif key.contains("bracelet"): b.icon = _texture("icon_bracelet")
  elif key.contains("fashion"): b.icon = _texture("icon_fashion")
 if icon_only:
  b.custom_minimum_size = Vector2(width,62)
 b.expand_icon = true
 if active != "":
  b.add_theme_stylebox_override("normal",_skin("slot_selected",19,4))
 b.pressed.connect(func(): game_store.call("unequip",key))

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
  var index := current_page*50+i
  var locked := index >= unlocked
  var item: String = str(items[index])
  var skin := "slot_locked" if locked else ("slot_selected" if selected == index else "slot_normal")
  var b := _button("",bag_grid,"",skin,Vector2(49,48))
  b.disabled = locked
  b.tooltip_text = ("Slot locked" if locked else (str(index+1) + " · Empty" if item == "" else str(index+1) + " · " + str(StoreScript.DATA.get(item,{}).get("name",item))))
  if item != "" and not locked:
   b.icon = _texture("icon_"+item)
   b.expand_icon = true
  if not locked:
   b.pressed.connect(func(): game_store.call("choose",index))
 var shown: int = maxi(0,mini(50,unlocked-current_page*50))
 capacity_text.text = str(shown)+" / 50 Slots   ("+str(unlocked)+"/200)"
 page_text.text = "PAGE "+str(current_page+1)+" / 4"
 var currency: Dictionary = game_store.get("currency")
 for money in MONEY:
  var label: Label = money_labels[money]
  label.text = str(game_store.call("pretty",str(currency.get(money,"0"))))

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
 _refresh_equip_container(main_equip_list,EQ_MAIN,127)
 _refresh_equip_container(extra_equip_list,EQ_RIGHT,123)
 _refresh_equip_container(fashion_weapon_row,EQ_FASHION_WEAPON,190,false,true)
 _refresh_equip_container(accessory_row,EQ_JEWELRY,76,true)
 _refresh_equip_container(fashion_row,EQ_FASHION,76,true)
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

func _notification(what: int) -> void:
 if what == NOTIFICATION_RESIZED and is_built:
  _adapt_layout()

extends Control
## LEOONLINE main-world HUD: nine separate, genuine menu buttons; drag/resize
## and restore per-device layout; native vector icons and original red/gold sprites.
## Online-only systems are explicitly presented as offline local prototypes.
const MENU_IDS: Array[String] = ["world","party","friends","ranking","settings","guild","quest","mail","events"]
# The actual 10-icon row, left to right, includes the existing Inventory button.
const MENU_ORDER: Array[String] = ["bag","world","party","friends","ranking","settings","guild","quest","mail","events"]
const LAYOUT_VERSION: int = 2
const PREMIUM_ROOT: String = "res://assets/ui/hud/premium/"
const TopStatusScript = preload("res://scripts/hud_top_status.gd")
const ALL_IDS: Array[String] = ["bag","world","party","friends","ranking","settings","guild","quest","mail","events","joystick","jump","pickup","run"]
const MENU_LABELS: Dictionary = {
 "bag":"กระเป๋า","world":"แผนที่โลก","party":"ปาร์ตี้","friends":"เพื่อน",
 "ranking":"อันดับผู้เล่น","settings":"ตั้งค่าเกม","guild":"กิลด์",
 "quest":"เควสต์","mail":"จดหมาย","events":"กิจกรรม",
 "joystick":"จอยเคลื่อนที่","jump":"กระโดด","pickup":"เก็บของ","run":"วิ่ง"
}
const EN_LABELS: Dictionary = {
 "bag":"Inventory","world":"World Map","party":"Party","friends":"Friends",
 "ranking":"Rankings","settings":"Settings","guild":"Guild",
 "quest":"Quests","mail":"Mail","events":"Events",
 "joystick":"Move","jump":"Jump","pickup":"Pick Up","run":"Run"
}
const HUD_FILE: String = "user://leoonline_hud.json"
const WEB_KEY: String = "leoonline_hud_v1"
const RED_ROOT: String = "res://assets/ui/red_matte/"
const ICON_ROOT: String = "res://assets/ui/hud/"
const MapScript = preload("res://scripts/hud_world_map.gd")
const StickScript = preload("res://scripts/hud_joystick.gd")

var game: Node3D
var game_store: Node
var inventory: Control
var bag_button: TextureButton
var controls: Dictionary = {}
var notification_badges: Dictionary = {}
var unread_counts: Dictionary = {}
var top_status: Control
var layout_state: Dictionary = {}
var friends_list: Array[String] = []
var guild_draft: String = ""
var local_party: bool = false
var pickups: int = 0
var quest_claimed: bool = false
var mail_claimed: bool = false
var last_event_date: String = ""
var display_names: bool = true
var display_mobile_controls: bool = false
var camera_sensitivity: float = 0.003
var jump_requested: bool = false
var run_pressed: bool = false
var edit_mode: bool = false
var edit_snapshot: Dictionary = {}
var selected_id: String = "world"
var moving_id: String = ""
var moving_offset: Vector2 = Vector2.ZERO
var moving_touch: int = -1
var moving_mouse: bool = false
var touch_has_priority: bool = false

var dimmer: ColorRect
var popup: PanelContainer
var popup_title: Label
var page_body: VBoxContainer
var page_scroll: ScrollContainer
var popup_key: String = ""
var popup_notice: Label
var popup_map: Control
var map_coords: Label
var toolbar: PanelContainer
var select_name: Label
var size_slider: HSlider
var toolbar_hint: Label
var toolbar_swap_button: Button
var toolbar_on_top: bool = false
var message_toast: Label

func initialize(p_game: Node3D, p_store: Node, p_inventory: Control, p_bag: TextureButton) -> void:
 game=p_game
 game_store=p_store
 inventory=p_inventory
 bag_button=p_bag
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _load_local()
 _build_top_status()
 _build_buttons()
 _build_popup()
 _build_toolbar()
 _build_toast()
 _reflow()
 resized.connect(_reflow)
 inventory.visibility_changed.connect(_on_inventory_visibility)
 if is_instance_valid(bag_button):
  bag_button.tooltip_text = MENU_LABELS["bag"]+" [B]"

func _build_top_status() -> void:
 top_status=TopStatusScript.new() as Control
 top_status.name="CharacterTargetAndMinimap"
 add_child(top_status)
 top_status.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 top_status.call("initialize",game,game_store)
 top_status.minimap_button.pressed.connect(_open_page.bind("world"))

# UI-only notifications are never part of an icon PNG. They begin hidden and
# can only be raised by an actual incoming event from a future social server.
func set_notification_count(key: String,count: int) -> void:
 if not MENU_ORDER.has(key): return
 if count>0:
  unread_counts[key]=mini(count,99)
 else:
  unread_counts.erase(key)
 if not notification_badges.has(key): return
 var badge: Label=notification_badges[key]
 badge.visible=count>0
 badge.text="" if count<=1 else str(mini(count,99))

func receive_friend_request(sender_id: String) -> void:
 # No locally added 'friend' can fake an incoming request.
 if sender_id.strip_edges().is_empty(): return
 set_notification_count("friends",int(unread_counts.get("friends",0))+1)

func receive_mail_notification(message_id: String) -> void:
 if message_id.strip_edges().is_empty(): return
 set_notification_count("mail",int(unread_counts.get("mail",0))+1)

func acknowledge_notifications(key: String) -> void:
 set_notification_count(key,0)

func _make_notification_badge(button: Control,key: String) -> void:
 var badge:=Label.new()
 badge.name="DynamicNotification"
 badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
 badge.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 badge.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 badge.add_theme_font_size_override("font_size",11)
 badge.add_theme_color_override("font_color",Color.WHITE)
 var circle:=StyleBoxFlat.new()
 circle.bg_color=Color("#e1172b")
 circle.border_color=Color("#ffe5a0")
 circle.set_border_width_all(2)
 circle.set_corner_radius_all(16)
 badge.add_theme_stylebox_override("normal",circle)
 button.add_child(badge)
 badge.visible=false
 notification_badges[key]=badge

func set_target(target: Node3D) -> void:
 if is_instance_valid(top_status): top_status.call("set_target",target)

func clear_target() -> void:
 if is_instance_valid(top_status): top_status.call("clear_target")

func _label_for(id: String) -> String:
 return str(EN_LABELS.get(id,id)) if inventory.get("locale")=="en" else str(MENU_LABELS.get(id,id))

func _font() -> Font:
 var path: String = "res://assets/fonts/NotoSansThai.ttf"
 return load(path) as Font if ResourceLoader.exists(path) else null

func _style(texture_name: String, margin: float = 17.0) -> StyleBoxTexture:
 var s:=StyleBoxTexture.new()
 s.texture=load(RED_ROOT+texture_name+".png") as Texture2D
 s.texture_margin_left=margin
 s.texture_margin_right=margin
 s.texture_margin_top=margin
 s.texture_margin_bottom=margin
 s.content_margin_left=7.0
 s.content_margin_right=7.0
 s.content_margin_top=4.0
 s.content_margin_bottom=4.0
 return s

func _dress(button: Button, active: bool = false) -> void:
 button.flat=false
 button.focus_mode=Control.FOCUS_NONE
 button.add_theme_stylebox_override("normal",_style("tab_lit" if active else "tab_idle"))
 button.add_theme_stylebox_override("hover",_style("button_hover"))
 button.add_theme_stylebox_override("pressed",_style("button_pressed"))
 button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
 button.add_theme_stylebox_override("disabled",_style("tab_idle"))
 button.add_theme_color_override("font_color",Color("#ffdda2"))
 button.add_theme_color_override("font_hover_color",Color.WHITE)
 button.add_theme_color_override("font_disabled_color",Color("#ab8d72"))
 if _font()!=null: button.add_theme_font_override("font",_font())

func _build_buttons() -> void:
 controls["bag"]=bag_button
 bag_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
 # The original bag control stays functional; only its art changes to its
 # OWN native PNG, never extracted from a combined screenshot.
 bag_button.texture_normal=load(PREMIUM_ROOT+"bag.png") as Texture2D
 bag_button.texture_hover=bag_button.texture_normal
 bag_button.texture_pressed=bag_button.texture_normal
 bag_button.ignore_texture_size=true
 var bag_caption:=Label.new()
 bag_caption.name="Caption"
 bag_caption.text=_label_for("bag")
 bag_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 bag_caption.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 bag_caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
 bag_caption.add_theme_color_override("font_color",Color("#ffe6b3"))
 if _font()!=null: bag_caption.add_theme_font_override("font",_font())
 bag_button.add_child(bag_caption)
 _make_notification_badge(bag_button,"bag")
 for key in MENU_IDS:
  var icon_button:=Button.new()
  icon_button.name="HUD_"+key
  icon_button.mouse_filter=Control.MOUSE_FILTER_STOP
  icon_button.tooltip_text=str(MENU_LABELS[key])
  _dress(icon_button)
  # The premium PNG includes its own gold frame. No double frame/sprite crop.
  for mode in ["normal","hover","pressed","disabled"]:
   icon_button.add_theme_stylebox_override(mode,StyleBoxEmpty.new())
  add_child(icon_button)
  controls[key]=icon_button
  var icon:=TextureRect.new()
  icon.name="Glyph"
  var icon_path: String=PREMIUM_ROOT+key+".png"
  if ResourceLoader.exists(icon_path): icon.texture=load(icon_path) as Texture2D
  icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
  icon_button.add_child(icon)
  var caption:=Label.new()
  caption.name="Caption"
  caption.text=_label_for(key)
  caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  caption.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
  caption.add_theme_color_override("font_color",Color("#fff0c6"))
  caption.add_theme_color_override("font_shadow_color",Color(0,0,0,0.92))
  caption.add_theme_constant_override("shadow_offset_y",1)
  if _font()!=null: caption.add_theme_font_override("font",_font())
  icon_button.add_child(caption)
  _make_notification_badge(icon_button,key)
  icon_button.pressed.connect(_open_page.bind(key))
 var joystick: Control=StickScript.new()
 joystick.name="MobileJoystick"
 add_child(joystick)
 controls["joystick"]=joystick
 for key in ["jump","pickup","run"]:
  var button:=Button.new()
  button.name="Touch_"+key
  button.mouse_filter=Control.MOUSE_FILTER_STOP
  _dress(button)
  add_child(button)
  controls[key]=button
  var image:=TextureRect.new()
  image.name="Glyph"
  image.texture=load(ICON_ROOT+key+".svg") as Texture2D
  image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  image.mouse_filter=Control.MOUSE_FILTER_IGNORE
  button.add_child(image)
  var label:=Label.new()
  label.name="Caption"
  label.text=_label_for(key)
  label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  label.mouse_filter=Control.MOUSE_FILTER_IGNORE
  label.add_theme_color_override("font_color",Color("#fff4d9"))
  if _font()!=null: label.add_theme_font_override("font",_font())
  button.add_child(label)
  match key:
   "jump": button.pressed.connect(func(): if not edit_mode: jump_requested=true)
   "pickup": button.pressed.connect(func(): if not edit_mode: game.call("_collect_nearest"))
   "run":
    button.button_down.connect(func(): if not edit_mode: run_pressed=true)
    button.button_up.connect(func(): run_pressed=false)

func _row_metrics() -> Dictionary:
 var w:float=maxf(320.0,size.x)
 var item_size:float=54.0
 var gap:float=7.0
 var y:float=21.0
 var left_reserve:float=282.0
 var right_reserve:float=165.0
 if w<600.0:
  # Ten icons remain ONE row on a narrow phone. The player and minimap
  # occupy the first row above; captions hide, full labels remain tooltips.
  item_size=clampf((w-16.0-27.0)/10.0,27.0,37.0)
  gap=3.0
  y=104.0
  left_reserve=7.0
  right_reserve=7.0
 elif w<1100.0:
  item_size=clampf((w-60.0)/16.0,42.0,49.0)
  gap=5.0
  y=119.0
  left_reserve=8.0
  right_reserve=8.0
 else:
  item_size=clampf(w*0.037,48.0,57.0)
  gap=7.0
 var total:float=float(MENU_ORDER.size())*item_size+float(MENU_ORDER.size()-1)*gap
 var usable:float=maxf(total,w-left_reserve-right_reserve)
 var start_x:float=left_reserve+(usable-total)*0.5
 return {"size":item_size,"gap":gap,"y":y,"start":start_x,"total":total}

func _default_positions() -> Dictionary:
 var w:float=maxf(320.0,size.x)
 var h:float=maxf(320.0,size.y)
 var metrics:Dictionary=_row_metrics()
 var result: Dictionary={}
 for i in range(MENU_ORDER.size()):
  result[MENU_ORDER[i]]=Vector2(float(metrics["start"])+float(i)*(float(metrics["size"])+float(metrics["gap"])),float(metrics["y"]))
 result["joystick"]=Vector2(22.0,h-160.0)
 result["run"]=Vector2(w-209.0,h-118.0)
 result["pickup"]=Vector2(w-140.0,h-118.0)
 result["jump"]=Vector2(w-71.0,h-118.0)
 return result

func _default_size(id: String) -> float:
 if id=="joystick": return 132.0
 if MENU_ORDER.has(id): return float(_row_metrics()["size"])
 if ["jump","pickup","run"].has(id): return 58.0
 return 59.0

func _max_size(id: String) -> float:
 return 195.0 if id=="joystick" else 100.0

func _min_size(id: String) -> float:
 if id=="joystick": return 90.0
 # Responsive small PNGs must be allowed below 42px to keep all ten
 # icons in one row on a 320-390px phone with zero overlap.
 if MENU_ORDER.has(id) and size.x<600.0: return 27.0
 return 42.0

func _size_of(id: String) -> float:
 var setting: Variant=layout_state.get(id,{})
 if setting is Dictionary:
  return clampf(float(setting.get("size",_default_size(id))),_min_size(id),_max_size(id))
 return _default_size(id)

func _reflow() -> void:
 if controls.is_empty(): return
 var defaults:Dictionary=_default_positions()
 for id in ALL_IDS:
  var control: Control=controls.get(id) as Control
  if not is_instance_valid(control): continue
  var wh:float=_size_of(id)
  control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
  # The old Inventory TextureButton starts with a 56px custom minimum.
  # Clear it BEFORE resizing or Godot keeps the 56px hitbox on phones,
  # overlapping the next icon and the centered target panel.
  control.custom_minimum_size=Vector2.ZERO
  control.size=Vector2(wh,wh)
  var coordinates:Vector2=defaults.get(id,Vector2.ZERO)
  var entry:Variant=layout_state.get(id,{})
  if entry is Dictionary and entry.has("x") and entry.has("y"):
   coordinates=Vector2(clampf(float(entry.get("x",0.0)),0.0,1.0)*maxf(0.0,size.x-wh),clampf(float(entry.get("y",0.0)),0.0,1.0)*maxf(0.0,size.y-wh))
  control.position=Vector2(clampf(coordinates.x,5.0,maxf(5.0,size.x-wh-5.0)),clampf(coordinates.y,5.0,maxf(5.0,size.y-wh-5.0)))
  if MENU_ORDER.has(id):
   var caption:Label=control.get_node("Caption") as Label
   caption.text=_label_for(id)
   if id!="bag":
    var icon:TextureRect=control.get_node("Glyph") as TextureRect
    # The approved ornament already includes its OWN frame and nameplate;
    # show the ENTIRE standalone PNG without clipping, cropping or inset.
    icon.position=Vector2.ZERO
    icon.size=Vector2(wh,wh)
   # Keep each Thai/English caption as live text on the blank nameplate.
   # No label text is baked into any of the ten transparent PNG files.
   caption.position=Vector2(-wh*0.07,wh*0.70)
   caption.size=Vector2(wh*1.14,wh*0.22)
   caption.add_theme_font_size_override("font_size",clampi(int(wh*0.158),7,10))
   caption.visible=display_names and size.x>=700.0
   if notification_badges.has(id):
    var badge:Label=notification_badges[id]
    var badge_size:float=clampf(wh*0.34,12.0,19.0)
    badge.position=Vector2(wh-badge_size*0.82,-badge_size*0.08)
    badge.size=Vector2(badge_size,badge_size)
  elif id!="joystick":
   var glyph:TextureRect=control.get_node("Glyph") as TextureRect
   var caption_touch:Label=control.get_node("Caption") as Label
   glyph.position=Vector2(wh*0.19,wh*0.08)
   glyph.size=Vector2(wh*0.62,wh*0.60)
   caption_touch.position=Vector2(1.0,wh*0.66)
   caption_touch.size=Vector2(wh-2.0,wh*0.28)
   caption_touch.add_theme_font_size_override("font_size",clampi(int(wh*0.16),9,14))
   caption_touch.visible=display_names
  if id=="joystick": control.queue_redraw()
  control.tooltip_text=_label_for(id)
 if is_instance_valid(top_status): top_status.call("_layout")
 _refresh_touch_visibility()
 _place_popup()
 _place_toolbar()

func _refresh_touch_visibility() -> void:
 var show_touch:bool=DisplayServer.is_touchscreen_available() or display_mobile_controls or edit_mode
 for id in ["joystick","jump","pickup","run"]:
  controls[id].visible=show_touch and not inventory.visible
 for key in MENU_IDS: controls[key].visible=not inventory.visible
 if is_instance_valid(bag_button): bag_button.visible=not inventory.visible
 if is_instance_valid(top_status): top_status.visible=not inventory.visible

func _on_inventory_visibility() -> void:
 if inventory.visible:
  _hide_popup()
  if edit_mode: _finish_edit(false)
 _refresh_touch_visibility()

func _build_popup() -> void:
 dimmer=ColorRect.new()
 dimmer.color=Color(0,0,0,0.58)
 dimmer.mouse_filter=Control.MOUSE_FILTER_STOP
 add_child(dimmer)
 dimmer.visible=false
 dimmer.gui_input.connect(func(event:InputEvent):
  if event is InputEventMouseButton and event.pressed: _hide_popup()
 )
 popup=PanelContainer.new()
 popup.name="HUDMenuWindow"
 popup.mouse_filter=Control.MOUSE_FILTER_STOP
 var popup_frame:=_style("outer_panel",29.0)
 popup_frame.content_margin_left=26.0
 popup_frame.content_margin_right=26.0
 popup_frame.content_margin_top=22.0
 popup_frame.content_margin_bottom=22.0
 popup.add_theme_stylebox_override("panel",popup_frame)
 add_child(popup)
 var content:=VBoxContainer.new()
 content.add_theme_constant_override("separation",10)
 popup.add_child(content)
 var header:=HBoxContainer.new()
 content.add_child(header)
 popup_title=Label.new()
 popup_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 popup_title.add_theme_color_override("font_color",Color("#ffdd99"))
 popup_title.add_theme_font_size_override("font_size",24)
 if _font()!=null: popup_title.add_theme_font_override("font",_font())
 header.add_child(popup_title)
 var close:=_action_button(header,"ปิด",_hide_popup)
 close.name="CloseHUDPanel"
 close.custom_minimum_size=Vector2(86,40)
 popup_notice=Label.new()
 popup_notice.add_theme_font_size_override("font_size",13)
 if _font()!=null: popup_notice.add_theme_font_override("font",_font())
 popup_notice.add_theme_color_override("font_color",Color("#e9cfaa"))
 popup_notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 content.add_child(popup_notice)
 page_scroll=ScrollContainer.new()
 page_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 page_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 content.add_child(page_scroll)
 page_body=VBoxContainer.new()
 page_body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 page_body.add_theme_constant_override("separation",10)
 page_scroll.add_child(page_body)
 popup.visible=false
 _place_popup()

func _place_popup() -> void:
 if not is_instance_valid(dimmer): return
 dimmer.position=Vector2.ZERO
 dimmer.size=size
 var w:float=minf(690.0,maxf(300.0,size.x-22.0))
 var h:float=minf(660.0,maxf(290.0,size.y-28.0))
 popup.position=Vector2(maxf(7.0,(size.x-w)*0.5),maxf(9.0,(size.y-h)*0.5))
 popup.size=Vector2(w,h)

func _build_toast() -> void:
 message_toast=Label.new()
 message_toast.name="HUDStatusToast"
 message_toast.visible=false
 message_toast.mouse_filter=Control.MOUSE_FILTER_IGNORE
 message_toast.add_theme_color_override("font_color",Color("#ffdc98"))
 message_toast.add_theme_color_override("font_shadow_color",Color.BLACK)
 message_toast.add_theme_constant_override("shadow_offset_y",2)
 message_toast.add_theme_font_size_override("font_size",17)
 if _font()!=null: message_toast.add_theme_font_override("font",_font())
 add_child(message_toast)

func _toast(text: String) -> void:
 if not is_instance_valid(message_toast): return
 message_toast.text=text
 message_toast.position=Vector2(18.0,maxf(40.0,size.y-205.0))
 message_toast.size=Vector2(minf(size.x-30.0,450.0),40.0)
 message_toast.visible=true
 var current:String=text
 get_tree().create_timer(3.5).timeout.connect(func():
  if is_instance_valid(message_toast) and message_toast.text==current: message_toast.visible=false
 )

func _open_page(id: String) -> void:
 if edit_mode or inventory.visible: return
 popup_key=id
 dimmer.visible=true
 popup.visible=true
 _render_page()
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func _hide_popup() -> void:
 if is_instance_valid(dimmer): dimmer.visible=false
 if is_instance_valid(popup): popup.visible=false
 popup_key=""
 popup_map=null
 map_coords=null

func is_gameplay_blocked() -> bool:
 return edit_mode or (is_instance_valid(popup) and popup.visible) or inventory.visible

func _render_page() -> void:
 if popup_key.is_empty(): return
 popup_title.text=_label_for(popup_key)
 popup_notice.text="LEOONLINE - "+("แผงข้อมูลในเกม" if inventory.get("locale")=="th" else "In-game panel")
 for child in page_body.get_children():
  page_body.remove_child(child)
  child.queue_free()
 popup_map=null
 match popup_key:
  "world": _world_page()
  "party": _party_page()
  "friends": _friends_page()
  "ranking": _ranking_page()
  "guild": _guild_page()
  "quest": _quest_page()
  "mail": _mail_page()
  "events": _events_page()
  "settings": _settings_page()

func _text(parent: Node, value: String, font_size: int = 16, bright: bool=false) -> Label:
 var label:=Label.new()
 label.text=value
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_color",Color("#fbdc9f") if bright else Color("#ece1d4"))
 if _font()!=null: label.add_theme_font_override("font",_font())
 parent.add_child(label)
 return label

func _section(label: String) -> void:
 var h:=_text(page_body,label,19,true)
 h.custom_minimum_size.y=28.0

func _description(value: String) -> void:
 _text(page_body,value,15)

func _line(parent: Node) -> HBoxContainer:
 var row:=HBoxContainer.new()
 row.add_theme_constant_override("separation",8)
 parent.add_child(row)
 return row

func _action_button(parent: Node, label: String, action: Callable) -> Button:
 var button:=Button.new()
 button.text=label
 button.mouse_filter=Control.MOUSE_FILTER_STOP
 button.custom_minimum_size=Vector2(115.0,42.0)
 button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 button.add_theme_font_size_override("font_size",16)
 _dress(button)
 parent.add_child(button)
 button.pressed.connect(action)
 return button

func _input_field(parent: Node, hint: String) -> LineEdit:
 var input:=LineEdit.new()
 input.placeholder_text=hint
 input.max_length=24
 input.custom_minimum_size.y=46.0
 input.add_theme_font_size_override("font_size",17)
 if _font()!=null: input.add_theme_font_override("font",_font())
 input.add_theme_color_override("font_color",Color("#f9e7c7"))
 var base:=StyleBoxFlat.new()
 base.bg_color=Color("#250e1a")
 base.set_border_width_all(1)
 base.border_color=Color("#916535")
 base.set_content_margin_all(9)
 input.add_theme_stylebox_override("normal",base)
 parent.add_child(input)
 return input

func _world_page() -> void:
 _description("แผนที่พื้นที่ทดสอบปัจจุบัน แสดงตำแหน่งตัวละครกับไอเทมที่ยังเก็บได้จริง ไม่มีการสร้างตำแหน่งโลกออนไลน์ปลอม")
 popup_map=MapScript.new() as Control
 popup_map.custom_minimum_size=Vector2(220,260)
 popup_map.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 page_body.add_child(popup_map)
 var row:=_line(page_body)
 _action_button(row,"− ย่อ",func():
  if is_instance_valid(popup_map):
   popup_map.zoom=maxf(0.7,popup_map.zoom-0.15)
   popup_map.queue_redraw()
 )
 _action_button(row,"+ ขยาย",func():
  if is_instance_valid(popup_map):
   popup_map.zoom=minf(1.5,popup_map.zoom+0.15)
   popup_map.queue_redraw()
 )
 _action_button(row,"ตำแหน่งฉัน",_update_map)
 map_coords=_text(page_body,"",16,true)
 _update_map()

func _update_map() -> void:
 if not is_instance_valid(popup_map): return
 popup_map.update_world(game.character.global_position,game.loot)
 var pos:Vector3=game.character.global_position
 if is_instance_valid(map_coords):
  map_coords.text="ตำแหน่ง X: %.1f  Z: %.1f  |  ไอเทมบนแผนที่: %d" % [pos.x,pos.z,popup_map.loot_points.size()]

func _party_page() -> void:
 _section("ปาร์ตี้")
 _description("ระบบจัดทีมออนไลน์ต้องมีเซิร์ฟเวอร์ ในต้นแบบนี้สร้างและยุบปาร์ตี้เฉพาะในเครื่องได้จริง โดยไม่แสดงเพื่อนออนไลน์ปลอม")
 _text(page_body,"สถานะ: "+("ปาร์ตี้ส่วนตัว (ผู้เล่น 1 คน)" if local_party else "ยังไม่มีปาร์ตี้"),17,true)
 var row:=_line(page_body)
 if not local_party:
  _action_button(row,"สร้างปาร์ตี้",func():
   local_party=true
   _save_local()
   _render_page()
  )
 else:
  _action_button(row,"ยุบปาร์ตี้",func():
   local_party=false
   _save_local()
   _render_page()
  )
 _action_button(row,"การเชิญออนไลน์",func(): _toast("ยังไม่มีเซิร์ฟเวอร์สำหรับส่งคำเชิญปาร์ตี้"))
 _section("สมาชิก")
 _text(page_body,str(game_store.profile.get("name","Adventurer"))+"  •  Lv."+str(game_store.profile.get("level",1)))

func _friends_page() -> void:
 _section("รายชื่อเพื่อนในเครื่อง")
 _description("เพิ่มหรือลบชื่อเพื่อนเพื่อเตรียมรายชื่อได้ ระบบตรวจออนไลน์และส่งคำเชิญจริงยังไม่เปิดจนกว่าจะมีเซิร์ฟเวอร์")
 var input:=_input_field(page_body,"ชื่อเพื่อน")
 var add:=_action_button(page_body,"+ เพิ่มรายชื่อ",func():
  var name:String=input.text.strip_edges()
  if name.is_empty(): _toast("กรุณาระบุชื่อ"); return
  if friends_list.has(name): _toast("มีชื่อนี้แล้ว"); return
  if friends_list.size()>=30: _toast("รายชื่อเต็ม 30 คน"); return
  friends_list.append(name.substr(0,24))
  _save_local()
  _render_page()
 )
 add.name="AddFriend"
 _section("รายชื่อที่บันทึก: "+str(friends_list.size()))
 if friends_list.is_empty(): _description("ยังไม่มีรายชื่อ")
 for member in friends_list:
  var line:=_line(page_body)
  var title:=_text(line,member+"  •  ไม่เชื่อมต่อออนไลน์",15)
  title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  _action_button(line,"ลบ",func():
   friends_list.erase(member)
   _save_local()
   _render_page()
  )

func _ranking_page() -> void:
 _section("สถิติตัวละครปัจจุบัน")
 _description("อันดับเทียบผู้เล่นทั่วโลกยังไม่มีฐานข้อมูลออนไลน์ จึงแสดงเฉพาะสถิติจริงของตัวละครนี้ ไม่มีการสร้างอันดับปลอม")
 var profile:Dictionary=game_store.profile
 for entry in [
  "ตัวละคร: "+str(profile.get("name","Adventurer")),
  "เลเวล: "+str(profile.get("level",1)),
  "EXP: "+str(profile.get("experience",0)),
  "PvE Kills: "+str(profile.get("pve_kills",0)),
  "PvP Wins: "+str(profile.get("pvp_wins",0)),
  "ทองในกระเป๋า: "+str(game_store.call("pretty",str(game_store.currency.get("gold","0"))))
 ]:
  _text(page_body,str(entry),16,true)
 _action_button(page_body,"รีเฟรชสถิติ",_render_page)

func _guild_page() -> void:
 _section("ข้อมูลกิลด์ส่วนตัว")
 _description("สร้างชื่อแบบร่างกิลด์บนอุปกรณ์นี้ได้ แต่การเชิญผู้เล่น/เข้ากิลด์ออนไลน์ต้องรอระบบบัญชีและเซิร์ฟเวอร์")
 if guild_draft.is_empty():
  var name:=_input_field(page_body,"ตั้งชื่อกิลด์")
  _action_button(page_body,"สร้างแบบร่างกิลด์",func():
   var text_name:String=name.text.strip_edges()
   if text_name.is_empty(): _toast("กรุณาตั้งชื่อกิลด์"); return
   guild_draft=text_name.substr(0,24)
   _save_local()
   _render_page()
  )
 else:
  _text(page_body,"ชื่อกิลด์ (แบบร่าง): "+guild_draft,19,true)
  _action_button(page_body,"ลบแบบร่าง",func():
   guild_draft=""
   _save_local()
   _render_page()
  )

func _quest_page() -> void:
 _section("เควสต์เริ่มต้น — นักสำรวจ")
 _description("เก็บไอเทมบนพื้นจริง 3 ชิ้นด้วยปุ่ม E หรือปุ่มเก็บของบนมือถือ เพื่อรับ 50 ทอง (รางวัลทดสอบในเครื่อง)")
 var progress_label:=_text(page_body,"ความคืบหน้า: "+str(mini(pickups,3))+" / 3",21,true)
 progress_label.name="QuestProgress"
 _text(page_body,"รับรางวัลแล้ว" if quest_claimed else "ยังไม่ได้รับรางวัล",16)
 var b:=_action_button(page_body,"รับรางวัล 50 ทอง",func():
  if quest_claimed or pickups<3: return
  quest_claimed=true
  _save_local()
  game_store.add_currency("gold","50")
  _render_page()
 )
 b.disabled=quest_claimed or pickups<3

func _mail_page() -> void:
 _section("จดหมายต้อนรับ")
 _description("จดหมายระบบสำหรับทดลองออฟไลน์ ไม่มีการดึงจดหมายจริงจากผู้เล่นคนอื่น")
 _text(page_body,"ยินดีต้อนรับสู่ LEOONLINE — มีของขวัญทดลอง: ยาฟื้น HP 1 ชิ้น",17,true)
 var claim:=_action_button(page_body,"รับของขวัญ",func():
  if mail_claimed: return
  if not bool(game_store.call("add_item","potion")):
   _toast("กระเป๋าเต็ม กรุณาเคลียร์ช่อง")
   return
  mail_claimed=true
  _save_local()
  _render_page()
 )
 claim.disabled=mail_claimed
 _text(page_body,"รับแล้ว" if mail_claimed else "ยังไม่ได้รับ",15)

func _events_page() -> void:
 _section("กิจกรรมล็อกอินรายวัน (ทดลองในเครื่อง)")
 _description("รับรางวัลวันละ 20 ทองตามวันของอุปกรณ์ ยังไม่ใช่กิจกรรมออนไลน์ที่ตรวจสอบจากเซิร์ฟเวอร์")
 var today:String=Time.get_date_string_from_system()
 var claimed:bool=last_event_date==today
 _text(page_body,"วันที่: "+today,17,true)
 var claim:=_action_button(page_body,"รับรางวัล 20 ทอง",func():
  if last_event_date==today: return
  last_event_date=today
  _save_local()
  game_store.add_currency("gold","20")
  _render_page()
 )
 claim.disabled=claimed
 _text(page_body,"รับวันนี้แล้ว" if claimed else "ยังไม่ได้รับวันนี้",15)

func _settings_page() -> void:
 _section("ปรับแต่ง HUD")
 _description("ลากปุ่มบนหน้าจอเพื่อย้ายตำแหน่งด้วยนิ้วหรือเมาส์ เลือกปุ่มแล้วเลื่อนสไลเดอร์เพื่อเปลี่ยนขนาด บันทึกตำแหน่งแยกตามอุปกรณ์ได้")
 var action:=_action_button(page_body,"เริ่มจัดปุ่มบนหน้าจอ",_begin_edit)
 action.name="EditHUDLayout"
 var check:=CheckBox.new()
 check.text="แสดงชื่อใต้ไอคอน"
 check.button_pressed=display_names
 check.add_theme_color_override("font_color",Color("#f4d69c"))
 if _font()!=null: check.add_theme_font_override("font",_font())
 check.toggled.connect(func(value:bool):
  display_names=value
  _reflow()
  _save_local()
 )
 page_body.add_child(check)
 var mobile_check:=CheckBox.new()
 mobile_check.text="แสดงจอยและปุ่มมือถือบน PC"
 mobile_check.button_pressed=display_mobile_controls
 mobile_check.add_theme_color_override("font_color",Color("#f4d69c"))
 if _font()!=null: mobile_check.add_theme_font_override("font",_font())
 mobile_check.toggled.connect(func(value:bool):
  display_mobile_controls=value
  _refresh_touch_visibility()
  _save_local()
 )
 page_body.add_child(mobile_check)
 _section("การควบคุมและภาษา")
 var row:=_line(page_body)
 _action_button(row,"ภาษาไทย",func(): inventory.call("set_language","th"); _reflow(); _render_page())
 _action_button(row,"English",func(): inventory.call("set_language","en"); _reflow(); _render_page())
 _text(page_body,"ความไวกล้อง (เมาส์)",16)
 var sensitivity:=HSlider.new()
 sensitivity.min_value=0.001
 sensitivity.max_value=0.010
 sensitivity.step=0.0005
 sensitivity.value=camera_sensitivity
 sensitivity.custom_minimum_size.y=38
 sensitivity.value_changed.connect(func(value:float): camera_sensitivity=value; _save_local())
 page_body.add_child(sensitivity)
 _section("เครื่องมือ")
 var restore_button:=_action_button(page_body,"คืนตำแหน่งและขนาด HUD เดิม",func():
  layout_state.clear()
  _reflow()
  _save_local()
  _toast("คืนตำแหน่งเดิมแล้ว")
 )
 restore_button.name="ResetHUDLayout"

func _process(_delta: float) -> void:
 if popup_key=="world" and is_instance_valid(popup_map) and popup.visible:
  _update_map()

func record_pickup(_item_id: String) -> void:
 if quest_claimed: return
 pickups=mini(3,pickups+1)
 _save_local()
 if popup_key=="quest" and popup.visible: _render_page()

func get_movement_vector() -> Vector2:
 if is_gameplay_blocked(): return Vector2.ZERO
 var stick:Control=controls.get("joystick") as Control
 if is_instance_valid(stick): return stick.movement
 return Vector2.ZERO

func consume_jump() -> bool:
 var value:bool=jump_requested
 jump_requested=false
 return value and not is_gameplay_blocked()

func _build_toolbar() -> void:
 toolbar=PanelContainer.new()
 toolbar.name="HUDEditToolbar"
 toolbar.mouse_filter=Control.MOUSE_FILTER_STOP
 var edit_frame:=_style("outer_panel",26.0)
 edit_frame.content_margin_left=17.0
 edit_frame.content_margin_right=17.0
 edit_frame.content_margin_top=19.0
 edit_frame.content_margin_bottom=16.0
 toolbar.add_theme_stylebox_override("panel",edit_frame)
 add_child(toolbar)
 var col:=VBoxContainer.new()
 col.add_theme_constant_override("separation",4)
 toolbar.add_child(col)
 toolbar_hint=_text(col,"จัดตำแหน่ง HUD - แตะเลือก แล้วลากด้วยนิ้วหรือเมาส์",15,true)
 toolbar_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 select_name=_text(col,"",15)
 select_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 size_slider=HSlider.new()
 size_slider.custom_minimum_size.y=31
 size_slider.min_value=42.0
 size_slider.max_value=100.0
 size_slider.step=1.0
 size_slider.value_changed.connect(_resize_selected)
 col.add_child(size_slider)
 var buttons:=_line(col)
 var save_btn:=_action_button(buttons,"บันทึก",func(): _finish_edit(true))
 save_btn.name="SaveHUDLayout"
 var cancel_btn:=_action_button(buttons,"ยกเลิก",func(): _finish_edit(false))
 cancel_btn.name="CancelHUDLayout"
 var defaults_btn:=_action_button(buttons,"ค่าเดิม",_reset_edit_layout)
 defaults_btn.name="DefaultHUDLayout"
 for entry in [save_btn,cancel_btn,defaults_btn]:
  entry.custom_minimum_size.x=70.0
 toolbar_swap_button=_action_button(col,"ย้ายแถบเครื่องมือขึ้น",_toggle_toolbar_position)
 toolbar_swap_button.name="SwapHUDToolbar"
 toolbar_swap_button.custom_minimum_size=Vector2(0,34)
 toolbar_swap_button.add_theme_font_size_override("font_size",14)
 toolbar.visible=false
 _place_toolbar()

func _place_toolbar() -> void:
 if not is_instance_valid(toolbar): return
 var w:float=minf(540.0,maxf(304.0,size.x-12.0))
 toolbar.position=Vector2(maxf(2.0,(size.x-w)*0.5),9.0 if toolbar_on_top else maxf(8.0,size.y-220.0))
 toolbar.size=Vector2(w,210.0)

func _toggle_toolbar_position() -> void:
 toolbar_on_top=not toolbar_on_top
 toolbar_swap_button.text="ย้ายแถบเครื่องมือลง" if toolbar_on_top else "ย้ายแถบเครื่องมือขึ้น"
 _place_toolbar()

func _begin_edit() -> void:
 toolbar_on_top=false
 if is_instance_valid(toolbar_swap_button): toolbar_swap_button.text="ย้ายแถบเครื่องมือขึ้น"
 _hide_popup()
 edit_snapshot=layout_state.duplicate(true)
 edit_mode=true
 toolbar.visible=true
 var stick:Control=controls.get("joystick") as Control
 if is_instance_valid(stick): stick.set_edit_mode(true)
 _reflow()
 _select_control("world")
 _toast("แตะปุ่มที่ต้องการ แล้วย้ายด้วยนิ้วหรือเมาส์")

func _select_control(id: String) -> void:
 if not ALL_IDS.has(id): return
 selected_id=id
 for key in ALL_IDS:
  var control:Control=controls.get(key) as Control
  if is_instance_valid(control):
   control.modulate=Color("#ffe4a3") if key==id else Color.WHITE
 select_name.text="กำลังปรับ: "+str(MENU_LABELS[id])
 size_slider.min_value=_min_size(id)
 size_slider.max_value=_max_size(id)
 size_slider.set_value_no_signal(_size_of(id))

func _resize_selected(value: float) -> void:
 if not edit_mode: return
 var control:Control=controls.get(selected_id) as Control
 if not is_instance_valid(control): return
 var old_position:Vector2=control.position
 _update_layout(selected_id,old_position,value)
 _reflow()

func _update_layout(id: String,position: Vector2,wh:float) -> void:
 var w:float=maxf(1.0,size.x-wh)
 var h:float=maxf(1.0,size.y-wh)
 layout_state[id]={
  "x":clampf(position.x/w,0.0,1.0),
  "y":clampf(position.y/h,0.0,1.0),
  "size":wh
 }

func _reset_edit_layout() -> void:
 if not edit_mode:return
 layout_state.clear()
 _reflow()
 _select_control(selected_id)

func _finish_edit(save: bool) -> void:
 if not edit_mode:return
 if not save: layout_state=edit_snapshot.duplicate(true)
 edit_mode=false
 moving_id=""
 moving_touch=-1
 moving_mouse=false
 touch_has_priority=false
 run_pressed=false
 toolbar.visible=false
 var stick:Control=controls.get("joystick") as Control
 if is_instance_valid(stick): stick.set_edit_mode(false)
 for id in ALL_IDS:
  var control:Control=controls.get(id) as Control
  if is_instance_valid(control): control.modulate=Color.WHITE
 _reflow()
 if save: _save_local()
 _toast("บันทึกตำแหน่งปุ่มแล้ว" if save else "ยกเลิกการแก้ไข HUD")

func _drag_start(point: Vector2,index: int,from_touch:bool) -> void:
 if not edit_mode or not toolbar.visible: return
 if toolbar.get_global_rect().has_point(point): return
 for i in range(ALL_IDS.size()-1,-1,-1):
  var id:String=ALL_IDS[i]
  var c:Control=controls.get(id) as Control
  if not is_instance_valid(c) or not c.visible: continue
  if c.get_global_rect().has_point(point):
   moving_id=id
   moving_offset=point-c.global_position
   moving_touch=index if from_touch else -1
   moving_mouse=not from_touch
   touch_has_priority=from_touch
   _select_control(id)
   get_viewport().set_input_as_handled()
   return

func _drag_move(point: Vector2) -> void:
 if moving_id.is_empty(): return
 var control:Control=controls.get(moving_id) as Control
 if not is_instance_valid(control): return
 var pos:Vector2=point-moving_offset
 var wh:float=_size_of(moving_id)
 pos.x=clampf(pos.x,5.0,maxf(5.0,size.x-wh-5.0))
 pos.y=clampf(pos.y,5.0,maxf(5.0,size.y-wh-5.0))
 _update_layout(moving_id,pos,wh)
 _reflow()
 get_viewport().set_input_as_handled()

func _input(event:InputEvent) -> void:
 if not edit_mode: return
 if event is InputEventScreenTouch:
  if event.pressed and moving_id.is_empty():
   _drag_start(event.position,event.index,true)
  elif not event.pressed and moving_touch==event.index:
   moving_id=""
   moving_touch=-1
   touch_has_priority=false
   get_viewport().set_input_as_handled()
 elif event is InputEventScreenDrag and moving_touch==event.index and not moving_id.is_empty():
  _drag_move(event.position)
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  if touch_has_priority: return
  if event.pressed and moving_id.is_empty():
   _drag_start(event.position,-1,false)
  elif not event.pressed and moving_mouse:
   moving_mouse=false
   moving_id=""
   get_viewport().set_input_as_handled()
 elif event is InputEventMouseMotion and moving_mouse and not moving_id.is_empty():
  _drag_move(event.position)

func _save_local() -> void:
 var data:Dictionary={
  "hud_layout_version":LAYOUT_VERSION,
  "layout":layout_state,
  "friends":friends_list,
  "guild_draft":guild_draft,
  "local_party":local_party,
  "pickups":pickups,
  "quest_claimed":quest_claimed,
  "mail_claimed":mail_claimed,
  "last_event_date":last_event_date,
  "display_names":display_names,
  "display_mobile_controls":display_mobile_controls,
  "camera_sensitivity":camera_sensitivity
 }
 var payload:String=JSON.stringify(data)
 var file:=FileAccess.open(HUD_FILE,FileAccess.WRITE)
 if file!=null:
  file.store_string(payload)
  file.close()
 if OS.has_feature("web"):
  var script:String="(function(){try{localStorage.setItem('"+WEB_KEY+"',"+JSON.stringify(payload)+");return true;}catch(e){return false;}})()"
  JavaScriptBridge.eval(script,true)

func _load_local() -> void:
 var data:Variant=null
 if OS.has_feature("web"):
  var raw:Variant=JavaScriptBridge.eval("(function(){try{return localStorage.getItem('"+WEB_KEY+"')||'';}catch(e){return '';}})()",true)
  if raw is String and not raw.is_empty(): data=JSON.parse_string(raw)
 if not (data is Dictionary) and FileAccess.file_exists(HUD_FILE):
  var file:=FileAccess.open(HUD_FILE,FileAccess.READ)
  if file!=null:data=JSON.parse_string(file.get_as_text())
 if not (data is Dictionary):return
 var from_layout:Variant=data.get("layout",{})
 if from_layout is Dictionary:layout_state=from_layout.duplicate(true)
 # Upgrading from the old 3x3 HUD should show the new 10-item row immediately
 # even if an old per-button layout was stored. Retain custom touch gameplay.
 if int(data.get("hud_layout_version",1))<LAYOUT_VERSION:
  for old_menu_id in MENU_ORDER: layout_state.erase(old_menu_id)
 var names:Variant=data.get("friends",[])
 if names is Array:
  for n in names:
   if n is String and not n.strip_edges().is_empty() and friends_list.size()<30:
    friends_list.append(n.substr(0,24))
 guild_draft=str(data.get("guild_draft","")).substr(0,24)
 local_party=bool(data.get("local_party",false))
 pickups=clampi(int(data.get("pickups",0)),0,3)
 quest_claimed=bool(data.get("quest_claimed",false))
 mail_claimed=bool(data.get("mail_claimed",false))
 last_event_date=str(data.get("last_event_date","")).substr(0,12)
 display_names=bool(data.get("display_names",true))
 display_mobile_controls=bool(data.get("display_mobile_controls",false))
 camera_sensitivity=clampf(float(data.get("camera_sensitivity",0.003)),0.001,0.010)

func _unhandled_input(event:InputEvent) -> void:
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  if edit_mode: _finish_edit(false); get_viewport().set_input_as_handled()
  elif popup.visible: _hide_popup(); get_viewport().set_input_as_handled()

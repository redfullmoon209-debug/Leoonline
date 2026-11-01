extends Control
## Separate GM TEST control for the local playtest, not an online privilege.
## The menu changes ONLY this client-side demo scene. A real GM account
## must be authorized server-side before any multiplayer deployment.
var game: Node3D
var menu: Control
var gm_button: Button
var gm_popup: PanelContainer
var target_picker: OptionButton
var target_picker_refs: Array[StaticBody3D]=[]
var status_label: Label
var active: bool=false

func initialize(p_game: Node3D,p_menu: Control) -> void:
 game=p_game
 menu=p_menu
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _build()
 _layout()
 resized.connect(_layout)
 _set_test_mode(_query_allows_gm())

func _query_allows_gm() -> bool:
 if not OS.has_feature("web"): return false
 return bool(JavaScriptBridge.eval("(function(){try{return new URLSearchParams(window.location.search).get('gm_test')==='1';}catch(e){return false;}})()",true))

func _style(base: Color,border: Color,radius: int=10) -> StyleBoxFlat:
 var style:=StyleBoxFlat.new()
 style.bg_color=base
 style.border_color=border
 style.set_border_width_all(2)
 style.set_corner_radius_all(radius)
 return style

func _make_action(parent: Node,text_value: String,fn: Callable) -> Button:
 var button:=Button.new()
 button.text=text_value
 button.focus_mode=Control.FOCUS_NONE
 button.custom_minimum_size=Vector2(108,39)
 button.add_theme_font_size_override("font_size",12)
 button.add_theme_color_override("font_color",Color("#ffe8ba"))
 # Godot's default Button font lacks Thai glyphs on Linux/Web.
 # Apply the packaged Thai font to every separate GM action.
 if ResourceLoader.exists("res://assets/fonts/NotoSansThai.ttf"):
  button.add_theme_font_override("font",load("res://assets/fonts/NotoSansThai.ttf"))
 button.add_theme_stylebox_override("normal",_style(Color("#2c0b13"),Color("#c78a3e")))
 button.add_theme_stylebox_override("hover",_style(Color("#5c1d24"),Color("#ffe0a0")))
 button.add_theme_stylebox_override("pressed",_style(Color("#851d28"),Color("#ffe0a0")))
 parent.add_child(button)
 button.pressed.connect(fn)
 return button

func _label(parent: Node,value: String,font_size: int=13) -> Label:
 var result:=Label.new()
 result.text=value
 result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 result.add_theme_font_size_override("font_size",font_size)
 result.add_theme_color_override("font_color",Color("#f9dd9f"))
 if ResourceLoader.exists("res://assets/fonts/NotoSansThai.ttf"):
  result.add_theme_font_override("font",load("res://assets/fonts/NotoSansThai.ttf"))
 parent.add_child(result)
 return result

func _build() -> void:
 gm_button=Button.new()
 gm_button.name="SeparateGMTestButton"
 gm_button.text="GM"
 gm_button.tooltip_text="GM ทดลอง - เฉพาะฉากทดสอบในเครื่อง"
 gm_button.focus_mode=Control.FOCUS_NONE
 gm_button.add_theme_font_size_override("font_size",16)
 gm_button.add_theme_color_override("font_color",Color("#fff5be"))
 gm_button.add_theme_stylebox_override("normal",_style(Color("#a31727"),Color("#ffce70"),24))
 gm_button.add_theme_stylebox_override("hover",_style(Color("#e53236"),Color("#fff0bc"),24))
 gm_button.add_theme_stylebox_override("pressed",_style(Color("#640e22"),Color("#f5d690"),24))
 add_child(gm_button)
 gm_button.pressed.connect(_toggle)
 gm_popup=PanelContainer.new()
 gm_popup.name="GMTestPanel"
 gm_popup.mouse_filter=Control.MOUSE_FILTER_STOP
 var panel_style:=_style(Color("#230910"),Color("#f4c679"),16)
 panel_style.content_margin_left=11
 panel_style.content_margin_top=11
 panel_style.content_margin_right=11
 panel_style.content_margin_bottom=11
 gm_popup.add_theme_stylebox_override("panel",panel_style)
 add_child(gm_popup)
 var scroll:=ScrollContainer.new()
 scroll.name="GMScrollableControls"
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 gm_popup.add_child(scroll)
 var content:=VBoxContainer.new()
 content.name="GMTools"
 content.add_theme_constant_override("separation",6)
 content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 scroll.add_child(content)
 var header:=HBoxContainer.new()
 content.add_child(header)
 var heading:=_label(header,"GM • ทดสอบเป้าหมาย",17)
 heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var close:=_make_action(header,"ปิด",_close)
 close.name="GMCloseButton"
 close.custom_minimum_size=Vector2(58,35)
 _label(content,"เฉพาะตัวทดสอบในเครื่อง · ไม่ใช่ผู้เล่นออนไลน์จริง",11)
 target_picker=OptionButton.new()
 target_picker.name="GMTargetPicker"
 target_picker.custom_minimum_size=Vector2(0,40)
 target_picker.add_theme_font_size_override("font_size",12)
 target_picker.add_theme_color_override("font_color",Color("#fff0c5"))
 if ResourceLoader.exists("res://assets/fonts/NotoSansThai.ttf"):
  var thai_font:Font=load("res://assets/fonts/NotoSansThai.ttf") as Font
  target_picker.add_theme_font_override("font",thai_font)
  target_picker.get_popup().add_theme_font_override("font",thai_font)
 target_picker.add_theme_stylebox_override("normal",_style(Color("#341823"),Color("#bd8746")))
 content.add_child(target_picker)
 var choose:=_make_action(content,"เลือกเป้าหมายที่ชี้",_choose_target)
 choose.name="GMSelectTarget"
 choose.custom_minimum_size=Vector2(0,38)
 var spawn_row:=HBoxContainer.new()
 spawn_row.add_theme_constant_override("separation",8)
 content.add_child(spawn_row)
 var monster:=_make_action(spawn_row,"เพิ่มมอนสเตอร์",_spawn_monster)
 monster.name="GMSpawnMonster"
 monster.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var player:=_make_action(spawn_row,"เพิ่มผู้เล่นจำลอง",_spawn_player)
 player.name="GMSpawnPlayerBot"
 player.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var combat_row:=HBoxContainer.new()
 combat_row.add_theme_constant_override("separation",8)
 content.add_child(combat_row)
 var damage:=_make_action(combat_row,"HP -25%",_damage)
 damage.name="GMDamageTarget"
 damage.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var drain:=_make_action(combat_row,"MP -25%",_drain_mana)
 drain.name="GMDrainMana"
 drain.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var heal:=_make_action(combat_row,"ฟื้นเต็ม",_heal)
 heal.name="GMHealTarget"
 heal.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var reset:=_make_action(content,"ล้างตัวที่เรียกเพิ่ม / คืน HP-MP / ปลดเป้า",_reset_world)
 reset.name="GMResetTestTargets"
 reset.custom_minimum_size.y=40
 status_label=_label(content,"แตะมอนสเตอร์หรือผู้เล่นจำลองในฉากเพื่อเลือกเป้าหมาย",12)
 status_label.name="GMStatusMessage"
 gm_popup.visible=false

func _set_test_mode(enabled: bool) -> void:
 # A client query parameter is NOT authentication. These controls must
 # never change a multiplayer server, currency, or a remote player.
 active=enabled
 gm_button.visible=enabled
 if not enabled:gm_popup.visible=false
 _layout()

func _toggle() -> void:
 if not active:return
 gm_popup.visible=not gm_popup.visible
 if gm_popup.visible:
  if is_instance_valid(menu.popup) and menu.popup.visible:menu._hide_popup()
  if is_instance_valid(menu.inventory) and menu.inventory.visible:
   gm_popup.visible=false
   return
  _refresh_picker()
  Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func _close() -> void:
 gm_popup.visible=false

func is_open() -> bool:
 return active and gm_popup.visible

func _layout() -> void:
 if not is_instance_valid(gm_button):return
 var w:float=maxf(size.x,320.0)
 var h:float=maxf(size.y,280.0)
 var portrait:bool=w<760.0
 var button_y:float=264.0 if portrait else (100.0 if w<1100.0 else 119.0)
 gm_button.position=Vector2(8.0,button_y)
 gm_button.size=Vector2(46.0,42.0)
 var pop_w:float=minf(372.0,w-14.0)
 var pop_h:float=minf(384.0,h-18.0)
 gm_popup.position=Vector2(7.0,maxf(9.0,(h-pop_h)*0.5))
 gm_popup.size=Vector2(pop_w,pop_h)

func _refresh_picker() -> void:
 if not is_instance_valid(target_picker):return
 var last_selected:Node3D=menu.top_status.current_target
 target_picker_refs.clear()
 target_picker.clear()
 for entity in game.test_targets:
  if not is_instance_valid(entity):continue
  if entity.is_queued_for_deletion():continue
  var index:int=target_picker.item_count
  target_picker.add_item(str(entity.get_meta("target_name",entity.name))+"  Lv."+str(entity.get_meta("level",1)))
  target_picker_refs.append(entity)
  if entity==last_selected:target_picker.select(index)
 if target_picker.item_count>0 and target_picker.selected<0: target_picker.select(0)

func _choose_target() -> void:
 var index:int=target_picker.selected
 if index<0 or index>=target_picker_refs.size():return
 var node:StaticBody3D=target_picker_refs[index]
 if not is_instance_valid(node):return
 game._set_test_target(node)
 status_label.text="กำลังแสดงข้อมูล: "+str(node.get_meta("target_name",node.name))

func _spawn_monster() -> void:
 var node:StaticBody3D=game._spawn_gm_test_entity("monster")
 _post_spawn(node,"มอนสเตอร์")

func _spawn_player() -> void:
 var node:StaticBody3D=game._spawn_gm_test_entity("player")
 _post_spawn(node,"ผู้เล่นจำลอง")

func _post_spawn(node:StaticBody3D,kind: String) -> void:
 if not is_instance_valid(node):
  status_label.text="จำนวนตัวทดสอบเต็มแล้ว (สูงสุด 12 ตัวเพิ่ม)"
  return
 _refresh_picker()
 status_label.text="เรียก"+kind+"สำเร็จ: "+str(node.get_meta("target_name",node.name))
 game._set_test_target(node)
 _refresh_picker()

func _selected() -> StaticBody3D:
 var node:Node3D=menu.top_status.current_target
 return node as StaticBody3D if is_instance_valid(node) else null

func _change_percent(stat: String,amount: float) -> void:
 var node:StaticBody3D=_selected()
 if not is_instance_valid(node):
  status_label.text="กรุณาเลือกเป้าหมายก่อน"
  return
 var max_stat:String="max_"+stat
 var max_value:float=float(node.get_meta(max_stat,0.0))
 var current:float=float(node.get_meta(stat,0.0))
 var new_value:float=clampf(current+max_value*amount,0.0,max_value)
 node.set_meta(stat,new_value)
 menu.top_status._refresh_target()
 status_label.text=str(node.get_meta("target_name",node.name))+" "+stat.to_upper()+": %.0f / %.0f" % [new_value,max_value]

func _damage() -> void:_change_percent("hp",-0.25)
func _drain_mana() -> void:_change_percent("mp",-0.25)

func _heal() -> void:
 var node:StaticBody3D=_selected()
 if not is_instance_valid(node):
  status_label.text="กรุณาเลือกเป้าหมายก่อน"
  return
 for key in ["hp","mp"]:
  node.set_meta(key,node.get_meta("max_"+key,0.0))
 menu.top_status._refresh_target()
 status_label.text="ฟื้น HP/MP ของเป้าหมายแล้ว"

func _reset_world() -> void:
 game._reset_gm_test_entities()
 _refresh_picker()
 status_label.text="รีเซ็ตตัวทดสอบและข้อมูลเป้าหมายแล้ว"

extends Control
## Three existing starter PNGs plus one standalone, text-only ATK control.
## The three skill PNGs and ALL existing HUD controls stay in place.
## Ordinary ATK is also clickable on PC; J is its keyboard alternative.
const SkillCatalog=preload("res://scripts/skill_catalog.gd")
var game:Node3D
var store:Node
var hud_menu:Control
var skill_buttons:Array[TextureButton]=[]
var skill_labels:Array[Label]=[]
var atk_button:Button
var _selected_ids:Array[String]=["","",""]

func initialize(p_game:Node3D,p_store:Node,p_menu:Control) -> void:
 game=p_game
 store=p_store
 hud_menu=p_menu
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for i in range(3):
  var button:=TextureButton.new()
  button.name="NoviceWorldSkill"+str(i+1)
  button.mouse_filter=Control.MOUSE_FILTER_STOP
  button.focus_mode=Control.FOCUS_NONE
  button.ignore_texture_size=true
  button.stretch_mode=TextureButton.STRETCH_KEEP_ASPECT_CENTERED
  add_child(button)
  button.pressed.connect(_press_skill.bind(i))
  skill_buttons.append(button)
  var caption:=Label.new()
  caption.name="SkillCooldownNumber"+str(i+1)
  caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
  caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  caption.add_theme_color_override("font_color",Color.WHITE)
  caption.add_theme_color_override("font_shadow_color",Color.BLACK)
  caption.add_theme_constant_override("shadow_offset_y",1)
  caption.add_theme_font_size_override("font_size",13)
  if ResourceLoader.exists("res://assets/fonts/NotoSansThai.ttf"):
   caption.add_theme_font_override("font",load("res://assets/fonts/NotoSansThai.ttf"))
  button.add_child(caption)
  skill_labels.append(caption)
 # No generated PNG, base icon ring or decorative frame. The text remains
 # translatable, crisp and independent from the existing skill artwork.
 atk_button=Button.new()
 atk_button.name="NoviceNormalATK"
 atk_button.text="ATK"
 atk_button.tooltip_text="ตีปกติ ไม่ใช้สตามินา · ปุ่ม J"
 atk_button.focus_mode=Control.FOCUS_NONE
 atk_button.mouse_filter=Control.MOUSE_FILTER_STOP
 atk_button.add_theme_stylebox_override("normal",_atk_style(Color("#501018")))
 atk_button.add_theme_stylebox_override("hover",_atk_style(Color("#a52431")))
 atk_button.add_theme_stylebox_override("pressed",_atk_style(Color("#e52b3e")))
 atk_button.add_theme_stylebox_override("hover_pressed",_atk_style(Color("#e52b3e")))
 atk_button.add_theme_stylebox_override("disabled",_atk_style(Color("#32151b")))
 atk_button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
 atk_button.add_theme_color_override("font_color",Color.WHITE)
 atk_button.add_theme_color_override("font_hover_color",Color.WHITE)
 atk_button.add_theme_color_override("font_pressed_color",Color.WHITE)
 atk_button.add_theme_color_override("font_disabled_color",Color("#bda0a5"))
 if ResourceLoader.exists("res://assets/fonts/NotoSansThai.ttf"):
  atk_button.add_theme_font_override("font",load("res://assets/fonts/NotoSansThai.ttf"))
 add_child(atk_button)
 atk_button.pressed.connect(_press_atk)
 resized.connect(_layout)
 _layout()
 _process(0.0)

func _atk_style(fill:Color) -> StyleBoxFlat:
 var style:=StyleBoxFlat.new()
 style.bg_color=fill
 style.set_border_width_all(0)
 style.set_corner_radius_all(5)
 return style

func _layout() -> void:
 if skill_buttons.is_empty():return
 var w:float=maxf(320.0,size.x)
 var h:float=maxf(320.0,size.y)
 var icon_size:float=47.0 if w<600.0 else 53.0
 var gap:float=7.0
 # Directly ABOVE existing Run/Pickup buttons and LEFT of TARGET:
 # no change to existing joystick, action-button or minimap positions.
 var right:float=w-(77.0 if w<600.0 else 83.0)
 var left:float=right-3.0*icon_size-2.0*gap
 var y:float=h-193.0
 if h<370.0:y=h-167.0
 for i in range(3):
  var button:TextureButton=skill_buttons[i]
  button.position=Vector2(maxf(5.0,left+float(i)*(icon_size+gap)),maxf(8.0,y))
  button.size=Vector2(icon_size,icon_size)
  var caption:Label=skill_labels[i]
  caption.position=Vector2(0,icon_size-16)
  caption.size=Vector2(icon_size,17)
 # Keep the complete right-hand HUD column: ATK sits one row ABOVE the
 # existing TARGET key. For low landscape windows, move to the LEFT of
 # the skill trio so that the top-right minimap is never covered.
 if is_instance_valid(atk_button):
  var atk_size:float=52.0 if w<600.0 else 58.0
  var atk_x:float=w-71.0+(58.0-atk_size)*0.5
  var atk_y:float=h-188.0-atk_size-10.0
  if h<392.0 and w>=600.0:
   atk_x=left-atk_size-9.0
   atk_y=y
  atk_button.position=Vector2(maxf(5.0,atk_x),maxf(7.0,atk_y))
  atk_button.size=Vector2(atk_size,atk_size)
  atk_button.add_theme_font_size_override("font_size",17 if w<600.0 else 19)

func _press_atk() -> void:
 if not is_instance_valid(game) or not visible:return
 game.call("_normal_attack")

func _press_skill(slot:int) -> void:
 if game==null or store==null or not visible:return
 game.call("_cast_hotbar_slot",slot)

func _process(_delta:float) -> void:
 if not is_instance_valid(hud_menu) or not is_instance_valid(store) or not is_instance_valid(game):return
 var touch:bool=DisplayServer.is_touchscreen_available() or hud_menu.display_mobile_controls or hud_menu.force_touch_preview or (OS.has_feature("web") and size.x<=600.0)
 var is_novice:bool=str(store.effective_job_info().get("id","Novice"))=="Novice"
 visible=is_novice and not game.open and not hud_menu.is_gameplay_blocked()
 if not visible:return
 var combat:Node=game.combat
 if is_instance_valid(atk_button):
  atk_button.visible=true
  # A half-second physical swing is NOT any of the three skill cooldowns.
  atk_button.disabled=not is_instance_valid(combat) or float(combat.basic_attack_left())>0.01
 for i in range(3):
  skill_buttons[i].visible=touch
  if not touch:continue
  var skill_id:String=store.skill_hotbar[i]
  var changed_id:bool=_selected_ids[i]!=skill_id
  var button:TextureButton=skill_buttons[i]
  var caption:Label=skill_labels[i]
  if changed_id:
   _selected_ids[i]=skill_id
   var item:Dictionary=SkillCatalog.info(skill_id) if SkillCatalog.is_equippable("Novice",skill_id) else {}
   var path:String=str(item.get("icon",""))
   var art:Texture2D=load(path) as Texture2D if path!="" and ResourceLoader.exists(path) else null
   button.texture_normal=art
   button.texture_hover=art
   button.texture_pressed=art
   button.texture_disabled=art
   button.tooltip_text=str(item.get("th","ช่องสกิลว่าง"))+" ["+str(i+1)+"]"
  var cooldown:float=float(combat.cooldown_left(skill_id)) if is_instance_valid(combat) else 0.0
  caption.text=str(i+1) if cooldown<0.05 else "%.1f" % cooldown
  button.disabled=skill_id=="" or cooldown>0.01

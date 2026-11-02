extends Control
## Three original standalone starter PNGs on lightweight world touch hitboxes.
## The existing HUD controls, approved icon art and positions are unchanged.
## Hidden on desktop keyboard play, during modal UI, and for non-Novice jobs.
const SkillCatalog=preload("res://scripts/skill_catalog.gd")
var game:Node3D
var store:Node
var hud_menu:Control
var skill_buttons:Array[TextureButton]=[]
var skill_labels:Array[Label]=[]
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
 resized.connect(_layout)
 _layout()
 _process(0.0)

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

func _press_skill(slot:int) -> void:
 if game==null or store==null or not visible:return
 game.call("_cast_hotbar_slot",slot)

func _process(_delta:float) -> void:
 if not is_instance_valid(hud_menu) or not is_instance_valid(store) or not is_instance_valid(game):return
 var touch:bool=DisplayServer.is_touchscreen_available() or hud_menu.display_mobile_controls or hud_menu.force_touch_preview or (OS.has_feature("web") and size.x<=600.0)
 var is_novice:bool=str(store.effective_job_info().get("id","Novice"))=="Novice"
 visible=touch and is_novice and not game.open and not hud_menu.is_gameplay_blocked()
 if not visible:return
 for i in range(3):
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
  var combat:Node=game.combat
  var cooldown:float=float(combat.cooldown_left(skill_id)) if is_instance_valid(combat) else 0.0
  caption.text=str(i+1) if cooldown<0.05 else "%.1f" % cooldown
  button.disabled=skill_id=="" or cooldown>0.01

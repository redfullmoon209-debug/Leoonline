extends Control
## Lightweight responsive overlays for the player, real-world minimap and target.
## Values come only from the current save, live game or an explicit target node.
const MiniMapScript = preload("res://scripts/hud_minimap.gd")
const TargetDecorationScript = preload("res://scripts/hud_target_decoration.gd")
const ROOT_UI: String = "res://assets/ui/red_matte/"
const CHAR_ICON: String = "res://assets/ui/inventory/icon_character.png"

var game: Node3D
var game_store: Node
var player_panel: PanelContainer
var portrait: TextureRect
var player_name: Label
var player_class: Label
var player_job: Label
var player_exp: Label
var exp_bar: ProgressBar
var minimap_button: Button
var minimap: Control
var zoom_in: Button
var zoom_out: Button
var north: Label
var target_panel: PanelContainer
var target_label: Label
var target_level_label: Label
var target_type_label: Label
var target_health_label: Label
var target_health_value: Label
var target_bar: ProgressBar
var target_mana_label: Label
var target_mana_value: Label
var target_mana_bar: ProgressBar
var target_portrait: TextureRect
var target_portrait_placeholder: Label
var target_hint: Label
var target_decor: Control
var target_body: Control
var current_target: Node3D
var previous_portrait: Variant = null
var last_world_update: float = 0.0

func initialize(p_game: Node3D,p_store: Node) -> void:
 game=p_game
 game_store=p_store
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _make_player()
 _make_map()
 _make_target()
 game_store.changed.connect(_refresh_player)
 _refresh_player()
 _layout()
 resized.connect(_layout)

func _frame() -> StyleBoxFlat:
 # A quiet single outer border; the old texture painted distracting rules
 # directly across character data, so there is no inner frame image.
 var frame:=StyleBoxFlat.new()
 frame.bg_color=Color("#280c19")
 frame.border_color=Color("#efbb68")
 frame.set_border_width_all(2)
 frame.set_corner_radius_all(13)
 frame.set_content_margin_all(5)
 frame.shadow_color=Color(0.0,0.0,0.0,0.42)
 frame.shadow_size=4
 return frame

func _label(parent: Node,name: String,text_value: String,font_size: int) -> Label:
 var control:=Label.new()
 control.name=name
 control.text=text_value
 control.mouse_filter=Control.MOUSE_FILTER_IGNORE
 control.add_theme_color_override("font_color",Color("#fff3d9"))
 control.add_theme_color_override("font_outline_color",Color("#150912"))
 control.add_theme_constant_override("outline_size",1)
 control.add_theme_color_override("font_shadow_color",Color(0,0,0,0.82))
 control.add_theme_constant_override("shadow_offset_y",1)
 control.add_theme_font_size_override("font_size",font_size)
 if ResourceLoader.exists("res://assets/fonts/NotoSansThai.ttf"):
  control.add_theme_font_override("font",load("res://assets/fonts/NotoSansThai.ttf"))
 parent.add_child(control)
 return control

func _make_player() -> void:
 player_panel=PanelContainer.new()
 player_panel.name="RealCharacterHUD"
 player_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 player_panel.add_theme_stylebox_override("panel",_frame())
 add_child(player_panel)
 var layout:=Control.new()
 layout.name="PortraitContent"
 layout.mouse_filter=Control.MOUSE_FILTER_IGNORE
 player_panel.add_child(layout)
 portrait=TextureRect.new()
 portrait.name="CharacterIcon"
 portrait.texture=load(CHAR_ICON) as Texture2D
 portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
 portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 layout.add_child(portrait)
 player_name=_label(layout,"NameAndLevel","",16)
 player_name.add_theme_color_override("font_color",Color.WHITE)
 player_class=_label(layout,"Class","",12)
 player_job=_label(layout,"Job","",11)
 player_exp=_label(layout,"Exp","",11)
 exp_bar=ProgressBar.new()
 exp_bar.name="CharacterExp"
 exp_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
 exp_bar.show_percentage=false
 exp_bar.min_value=0.0
 exp_bar.max_value=100.0
 var bg:=StyleBoxFlat.new()
 bg.bg_color=Color("#26121a")
 bg.border_color=Color("#8b6034")
 bg.set_border_width_all(1)
 bg.set_corner_radius_all(3)
 var filled:=StyleBoxFlat.new()
 filled.bg_color=Color("#7bce6c")
 filled.set_corner_radius_all(3)
 exp_bar.add_theme_stylebox_override("background",bg)
 exp_bar.add_theme_stylebox_override("fill",filled)
 layout.add_child(exp_bar)

func _make_map() -> void:
 minimap_button=Button.new()
 minimap_button.name="MiniMapButton"
 minimap_button.tooltip_text="มินิแมพ - กดเพื่อเปิดแผนที่โลก"
 minimap_button.mouse_filter=Control.MOUSE_FILTER_STOP
 minimap_button.focus_mode=Control.FOCUS_NONE
 minimap_button.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
 minimap_button.add_theme_stylebox_override("hover",StyleBoxEmpty.new())
 minimap_button.add_theme_stylebox_override("pressed",StyleBoxEmpty.new())
 minimap_button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
 add_child(minimap_button)
 minimap=MiniMapScript.new()
 minimap.name="LiveMiniMap"
 minimap.mouse_filter=Control.MOUSE_FILTER_IGNORE
 minimap_button.add_child(minimap)
 north=_label(minimap_button,"CompassN","N",13)
 north.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 for key in ["in","out"]:
  var button:=Button.new()
  button.name="MiniZoom"+key
  button.text="+" if key=="in" else "−"
  button.focus_mode=Control.FOCUS_NONE
  button.mouse_filter=Control.MOUSE_FILTER_STOP
  button.add_theme_font_size_override("font_size",19)
  button.add_theme_color_override("font_color",Color("#ffdda1"))
  var style:=StyleBoxFlat.new()
  style.bg_color=Color("#270d19")
  style.border_color=Color("#e4b45e")
  style.set_border_width_all(2)
  style.set_corner_radius_all(16)
  button.add_theme_stylebox_override("normal",style)
  button.add_theme_stylebox_override("hover",style)
  button.add_theme_stylebox_override("pressed",style)
  minimap_button.add_child(button)
  button.pressed.connect(_change_zoom.bind(0.15 if key=="in" else -0.15))
  if key=="in": zoom_in=button
  else: zoom_out=button

func _change_zoom(amount: float) -> void:
 minimap.zoom=clampf(minimap.zoom+amount,0.65,1.7)
 minimap.queue_redraw()

func _target_progress(parent: Node,name: String,fill_color: Color) -> ProgressBar:
 var bar:=ProgressBar.new()
 bar.name=name
 bar.min_value=0
 bar.max_value=100
 bar.show_percentage=false
 bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var backdrop:=StyleBoxFlat.new()
 backdrop.bg_color=Color("#15060c")
 backdrop.border_color=Color("#bd8242")
 backdrop.set_border_width_all(1)
 backdrop.set_corner_radius_all(8)
 var fill:=StyleBoxFlat.new()
 fill.bg_color=fill_color
 fill.set_corner_radius_all(7)
 bar.add_theme_stylebox_override("background",backdrop)
 bar.add_theme_stylebox_override("fill",fill)
 parent.add_child(bar)
 return bar

func _make_target() -> void:
 # All UI pieces are independent Godot controls, with a hand-drawn ornament
 # layer behind the portrait and real HP/MP bars. No reference-image crop.
 target_panel=PanelContainer.new()
 target_panel.name="LiveTargetHUD"
 target_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var frame:=StyleBoxFlat.new()
 frame.bg_color=Color("#2b0913")
 frame.border_color=Color("#f0b765")
 frame.set_border_width_all(2)
 frame.set_corner_radius_all(16)
 frame.content_margin_left=7.0
 frame.content_margin_right=7.0
 frame.content_margin_top=6.0
 frame.content_margin_bottom=6.0
 frame.shadow_color=Color(0.0,0.0,0.0,0.4)
 frame.shadow_size=4
 target_panel.add_theme_stylebox_override("panel",frame)
 add_child(target_panel)
 target_body=Control.new()
 target_body.name="TargetContent"
 target_body.mouse_filter=Control.MOUSE_FILTER_IGNORE
 target_panel.add_child(target_body)
 target_decor=TargetDecorationScript.new() as Control
 target_decor.name="HandDrawnOrnament"
 target_body.add_child(target_decor)
 target_portrait=TextureRect.new()
 target_portrait.name="LiveTargetPortrait"
 target_portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
 target_portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 target_portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 target_body.add_child(target_portrait)
 target_portrait_placeholder=_label(target_body,"UnselectedPortrait","?",29)
 target_portrait_placeholder.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 target_portrait_placeholder.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 target_portrait_placeholder.add_theme_color_override("font_color",Color("#b5cfda"))
 target_label=_label(target_body,"TargetName","เป้าหมาย: ยังไม่ได้เลือก",16)
 target_label.add_theme_color_override("font_color",Color("#fff8e6"))
 target_label.clip_text=true
 target_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 target_level_label=_label(target_body,"TargetLevel","",12)
 target_level_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 target_type_label=_label(target_body,"TargetType","",11)
 target_type_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 target_health_label=_label(target_body,"TargetHPLabel","HP",13)
 target_health_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 target_bar=_target_progress(target_body,"TargetHealth",Color("#d53647"))
 target_health_value=_label(target_body,"TargetHPValue","",12)
 target_health_value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 target_health_value.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 target_health_value.add_theme_color_override("font_color",Color.WHITE)
 target_mana_label=_label(target_body,"TargetMPLabel","MP",13)
 target_mana_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 target_mana_bar=_target_progress(target_body,"TargetMana",Color("#1984cf"))
 target_mana_value=_label(target_body,"TargetMPValue","",12)
 target_mana_value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 target_mana_value.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 target_mana_value.add_theme_color_override("font_color",Color.WHITE)
 target_hint=_label(target_body,"TargetHint","แตะเป้าหมาย หรือกด T",13)
 target_hint.add_theme_color_override("font_color",Color("#c8af87"))
 _refresh_target()

func _set_target_rect(control: Control,p: Vector2,wh: Vector2) -> void:
 control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
 control.position=p
 control.size=wh

func _refresh_player() -> void:
 if not is_instance_valid(player_name) or game_store==null:return
 var data:Dictionary=game_store.get("profile")
 var level:int=int(data.get("level",1))
 var name:String=str(data.get("name","Adventurer"))
 var job:String=str(data.get("job","Novice"))
 player_job.text=job
 var tier:int=int(data.get("class_tier",0))
 var exp:int=int(data.get("experience",0))
 var required:int=int(game_store.call("experience_required",level))
 var narrow:bool=size.y>size.x and size.x<620.0
 if narrow:
  # A compressed THREE-column portrait layout still exposes name, level,
  # class and EXP with readable type instead of clipping two long rows.
  player_name.text=name
  player_class.text="Lv.%d  C%d" % [level,tier]
  player_exp.text="EXP %d/%d" % [exp,required]
 else:
  player_name.text="Lv.%d  %s" % [level,name]
  player_class.text=job+"  |  Class "+str(tier)
  player_exp.text="EXP "+str(exp)+" / "+str(required)
 player_panel.tooltip_text="Lv.%d %s | %s Class %d | EXP %d/%d" % [level,name,job,tier,exp,required]
 exp_bar.value=100.0*float(exp)/maxf(float(required),1.0)

func set_target(target: Node3D) -> void:
 current_target=target if is_instance_valid(target) else null
 _refresh_target()

func clear_target() -> void:
 current_target=null
 _refresh_target()

func _target_portrait_texture() -> Texture2D:
 if not is_instance_valid(current_target): return null
 if not current_target.has_meta("target_portrait"): return null
 var image: Variant=current_target.get_meta("target_portrait")
 if image is Texture2D: return image as Texture2D
 if image is String:
  var file_path:String=str(image)
  # The asset must be an existing local standalone image, not a screenshot
  # or a portion cropped out of the approved design reference.
  if file_path.begins_with("res://assets/ui/hud/") and ResourceLoader.exists(file_path):
   return load(file_path) as Texture2D
 return null

func _refresh_target() -> void:
 if not is_instance_valid(target_label): return
 if not is_instance_valid(current_target):
  current_target=null
  target_label.text="เป้าหมาย: ยังไม่ได้เลือก"
  target_hint.text="แตะ / TARGET" if size.y>size.x and size.x<620.0 else "แตะเป้าหมาย หรือกด T"
  target_portrait.texture=null
  target_portrait.visible=false
  target_portrait_placeholder.visible=true
  target_level_label.visible=false
  target_type_label.visible=false
  target_health_label.visible=false
  target_health_value.visible=false
  target_bar.visible=false
  target_mana_label.visible=false
  target_mana_value.visible=false
  target_mana_bar.visible=false
  target_hint.visible=true
  previous_portrait=null
  return
 var display_name:String=str(current_target.get_meta("target_name",current_target.name))
 if display_name.strip_edges().is_empty(): display_name="เป้าหมาย"
 target_label.text=display_name
 var level:int=int(current_target.get_meta("level",0))
 target_level_label.text="Lv."+str(level) if level>0 else ""
 target_level_label.visible=level>0
 var category:String=str(current_target.get_meta("target_type","")).strip_edges()
 target_type_label.text=category
 target_type_label.visible=not category.is_empty() and not (size.y>size.x and size.x<620.0)
 target_hint.visible=false
 var portrait_image:Texture2D=_target_portrait_texture()
 if target_portrait.texture!=portrait_image:
  target_portrait.texture=portrait_image
 target_portrait.visible=portrait_image!=null
 target_portrait_placeholder.visible=portrait_image==null
 target_portrait_placeholder.text="?" if portrait_image==null else ""
 var max_hp:float=float(current_target.get_meta("max_hp",-1.0))
 var hp:float=float(current_target.get_meta("hp",-1.0))
 var has_hp:bool=max_hp>0.0 and hp>=0.0
 target_health_label.visible=has_hp
 target_bar.visible=has_hp
 target_health_value.visible=has_hp
 if has_hp:
  var health_ratio:float=clampf(hp/max_hp,0.0,1.0)
  target_bar.value=health_ratio*100.0
  target_health_value.text=("%.0f/%.0f" % [hp,max_hp]) if size.y>size.x and size.x<620.0 else ("%.0f / %.0f  (%.0f%%)" % [hp,max_hp,health_ratio*100.0])
 var max_mp:float=float(current_target.get_meta("max_mp",-1.0))
 var mp:float=float(current_target.get_meta("mp",-1.0))
 var has_mp:bool=max_mp>0.0 and mp>=0.0
 target_mana_label.visible=has_mp
 target_mana_bar.visible=has_mp
 target_mana_value.visible=has_mp
 if has_mp:
  var mana_ratio:float=clampf(mp/max_mp,0.0,1.0)
  target_mana_bar.value=mana_ratio*100.0
  target_mana_value.text=("%.0f/%.0f" % [mp,max_mp]) if size.y>size.x and size.x<620.0 else ("%.0f / %.0f  (%.0f%%)" % [mp,max_mp,mana_ratio*100.0])

func _layout() -> void:
 if not is_instance_valid(player_panel):return
 var w:float=maxf(320.0,size.x)
 var portrait_mode:bool=size.y>size.x
 var compact:bool=portrait_mode and w<620.0
 var tablet:bool=w>=600.0 and w<1100.0
 var profile_w:float=165.0 if w<600.0 else (214.0 if tablet else 265.0)
 var profile_h:float=80.0 if w<600.0 else (84.0 if tablet else 103.0)
 var map_w:float=88.0 if w<600.0 else (118.0 if tablet else 151.0)
 var player_x:float=7.0
 var player_y:float=6.0
 var map_x:float=w-map_w-9.0
 var map_y:float=6.0
 var target_w:float=minf(w-22.0,367.0)
 var target_h:float=108.0
 var target_x:float=(w-target_w)*0.5
 var target_y:float=71.0
 var metrics:Dictionary={}
 if get_parent()!=null:metrics=get_parent().call("_row_metrics")
 var bottom_icons:float=float(metrics.get("y",9.0))+float(metrics.get("size",37.0))
 var label_row_end:float=bottom_icons+19.0
 if portrait_mode:
  # The one-row top menu is followed by exactly three side-by-side panels:
  # player LEFT, selected target CENTER and the live minimap RIGHT.
  profile_w=clampf(w*0.285,89.0,198.0)
  profile_h=100.0 if compact else 107.0
  map_w=clampf(w*0.205,68.0,146.0)
  player_x=7.0
  player_y=label_row_end+9.0
  map_x=w-map_w-7.0
  map_y=player_y
  var available:float=w-26.0-profile_w-map_w
  target_w=minf(430.0,maxf(125.0,available))
  target_h=104.0 if compact else 110.0
  var min_target_x:float=player_x+profile_w+6.0
  var max_target_x:float=map_x-6.0-target_w
  target_x=clampf((w-target_w)*0.5,min_target_x,maxf(min_target_x,max_target_x))
  target_y=player_y
 else:
  target_y=label_row_end+8.0
  target_x=maxf(target_x,player_x+profile_w+8.0)
  target_x=minf(target_x,map_x-8.0-target_w)
 player_panel.position=Vector2(player_x,player_y)
 player_panel.size=Vector2(profile_w,profile_h)
 var body:Control=player_panel.get_node("PortraitContent") as Control
 body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 body.position=Vector2.ZERO
 body.size=player_panel.size-Vector2(10.0,10.0)
 if compact:
  # Text no longer sits behind drawn lines or an oversized avatar.
  portrait.position=Vector2(4.0,5.0)
  portrait.size=Vector2(31.0,49.0)
  player_name.position=Vector2(39.0,5.0)
  player_name.size=Vector2(maxf(35.0,profile_w-46.0),17.0)
  player_name.add_theme_font_size_override("font_size",10)
  player_class.position=Vector2(39.0,27.0)
  player_class.size=Vector2(maxf(35.0,profile_w-46.0),17.0)
  player_class.add_theme_font_size_override("font_size",9)
  player_job.position=Vector2(7.0,53.0)
  player_job.size=Vector2(profile_w-14.0,14.0)
  player_job.add_theme_font_size_override("font_size",9)
  player_job.visible=true
  player_exp.position=Vector2(7.0,68.0)
  player_exp.size=Vector2(profile_w-14.0,15.0)
  player_exp.add_theme_font_size_override("font_size",9)
  exp_bar.position=Vector2(7.0,85.0)
  exp_bar.size=Vector2(profile_w-14.0,8.0)
 else:
  player_job.visible=false
  var portrait_w:float=57.0 if tablet or portrait_mode else 75.0
  if portrait_mode:portrait_w=minf(63.0,profile_w*0.32)
  portrait.position=Vector2(6.0,5.0)
  portrait.size=Vector2(portrait_w,profile_h-16.0)
  var txt_x:float=portrait_w+11.0
  var txt_w:float=profile_w-txt_x-11.0
  player_name.position=Vector2(txt_x,4.0)
  player_name.size=Vector2(txt_w,24.0)
  player_name.add_theme_font_size_override("font_size",13 if tablet or portrait_mode else 16)
  player_class.position=Vector2(txt_x,30.0)
  player_class.size=Vector2(txt_w,20.0)
  player_class.add_theme_font_size_override("font_size",11 if tablet or portrait_mode else 12)
  player_exp.position=Vector2(txt_x,55.0)
  player_exp.size=Vector2(txt_w,18.0)
  player_exp.add_theme_font_size_override("font_size",11)
  exp_bar.position=Vector2(txt_x,77.0 if profile_h>=100.0 else 70.0)
  exp_bar.size=Vector2(txt_w,8.0)
 for t in [player_name,player_class,player_job,player_exp]:
  t.clip_text=true
  t.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 minimap_button.position=Vector2(map_x,map_y)
 minimap_button.size=Vector2(map_w,map_w)
 minimap.position=Vector2.ZERO
 minimap.size=Vector2(map_w,map_w)
 north.position=Vector2(map_w*0.37,-3.0)
 north.size=Vector2(map_w*0.26,20.0)
 north.add_theme_font_size_override("font_size",10 if compact else 13)
 var zoom_size:float=18.0 if compact else 25.0
 zoom_in.position=Vector2(map_w-zoom_size-3.0,map_w*0.30)
 zoom_out.position=Vector2(map_w-zoom_size-3.0,map_w*0.56)
 zoom_in.size=Vector2(zoom_size,zoom_size)
 zoom_out.size=Vector2(zoom_size,zoom_size)
 target_panel.position=Vector2(target_x,target_y)
 target_panel.size=Vector2(target_w,target_h)
 var inner_w:float=target_w-14.0
 var inner_h:float=target_h-12.0
 target_body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 target_body.size=Vector2(inner_w,inner_h)
 _set_target_rect(target_decor,Vector2.ZERO,Vector2(inner_w,inner_h))
 target_decor.queue_redraw()
 if compact:
  var image_size:float=38.0 if inner_w>140.0 else 31.0
  var img_center_x:float=26.0 if inner_w>140.0 else 23.0
  _set_target_rect(target_portrait,Vector2(img_center_x-image_size*0.5,inner_h*0.5-image_size*0.5),Vector2(image_size,image_size))
  _set_target_rect(target_portrait_placeholder,Vector2(img_center_x-17.0,inner_h*0.5-20.0),Vector2(34.0,40.0))
  target_portrait_placeholder.add_theme_font_size_override("font_size",24)
  var text_start:float=50.0 if inner_w>140.0 else 42.0
  # Full target name gets its own line: do not cram it beside Lv.
  _set_target_rect(target_label,Vector2(text_start,6.0),Vector2(maxf(55.0,inner_w-text_start-4.0),22.0))
  target_label.add_theme_font_size_override("font_size",10)
  _set_target_rect(target_level_label,Vector2(text_start,27.0),Vector2(44.0,15.0))
  target_level_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
  target_level_label.add_theme_font_size_override("font_size",9)
  _set_target_rect(target_type_label,Vector2(inner_w-59.0,9.0),Vector2(55.0,18.0))
  var bar_left:float=text_start+15.0
  var bar_width:float=maxf(45.0,inner_w-bar_left-4.0)
  _set_target_rect(target_health_label,Vector2(text_start,41.0),Vector2(15.0,18.0))
  _set_target_rect(target_bar,Vector2(bar_left,41.0),Vector2(bar_width,18.0))
  _set_target_rect(target_health_value,Vector2(bar_left,41.0),Vector2(bar_width,18.0))
  _set_target_rect(target_mana_label,Vector2(text_start,68.0),Vector2(15.0,18.0))
  _set_target_rect(target_mana_bar,Vector2(bar_left,68.0),Vector2(bar_width,18.0))
  _set_target_rect(target_mana_value,Vector2(bar_left,68.0),Vector2(bar_width,18.0))
  for t in [target_health_label,target_mana_label,target_health_value,target_mana_value]:
   t.add_theme_font_size_override("font_size",9)
  _set_target_rect(target_hint,Vector2(text_start,39.0),Vector2(maxf(44.0,inner_w-text_start-3.0),29.0))
  target_hint.add_theme_font_size_override("font_size",10)
 else:
  var portrait_size:float=68.0
  _set_target_rect(target_portrait,Vector2(46.0-portrait_size*0.5,inner_h*0.5-portrait_size*0.5),Vector2(portrait_size,portrait_size))
  _set_target_rect(target_portrait_placeholder,Vector2(17.0,inner_h*0.5-26.0),Vector2(58.0,52.0))
  target_portrait_placeholder.add_theme_font_size_override("font_size",29)
  var text_start:float=99.0
  var text_right:float=inner_w-8.0
  _set_target_rect(target_label,Vector2(text_start,6.0),Vector2(maxf(55.0,inner_w-text_start-104.0),26.0))
  target_label.add_theme_font_size_override("font_size",15)
  _set_target_rect(target_level_label,Vector2(inner_w-106.0,8.0),Vector2(46.0,22.0))
  target_level_label.add_theme_font_size_override("font_size",12)
  _set_target_rect(target_type_label,Vector2(inner_w-64.0,8.0),Vector2(56.0,22.0))
  target_type_label.add_theme_font_size_override("font_size",10)
  var bar_left:float=text_start+43.0
  var bar_width:float=maxf(72.0,text_right-bar_left-5.0)
  _set_target_rect(target_health_label,Vector2(text_start,36.0),Vector2(39.0,20.0))
  _set_target_rect(target_bar,Vector2(bar_left,36.0),Vector2(bar_width,20.0))
  _set_target_rect(target_health_value,Vector2(bar_left,36.0),Vector2(bar_width,20.0))
  _set_target_rect(target_mana_label,Vector2(text_start,67.0),Vector2(39.0,20.0))
  _set_target_rect(target_mana_bar,Vector2(bar_left,67.0),Vector2(bar_width,20.0))
  _set_target_rect(target_mana_value,Vector2(bar_left,67.0),Vector2(bar_width,20.0))
  for t in [target_health_label,target_mana_label,target_health_value,target_mana_value]:
   t.add_theme_font_size_override("font_size",12)
  _set_target_rect(target_hint,Vector2(text_start,44.0),Vector2(maxf(0.0,inner_w-text_start-10.0),30.0))
  target_hint.add_theme_font_size_override("font_size",13)
 _refresh_player()
 _refresh_target()

func _process(delta: float) -> void:
 last_world_update+=delta
 if last_world_update<0.16: return
 last_world_update=0.0
 if is_instance_valid(minimap) and is_instance_valid(game) and is_instance_valid(game.character):
  minimap.update_world(game.character.global_position,game.loot,game.camera_arm.rotation.y)
 if is_instance_valid(current_target): _refresh_target()
 elif current_target!=null: clear_target()

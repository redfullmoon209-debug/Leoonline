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

func _frame() -> StyleBoxTexture:
 var box:=StyleBoxTexture.new()
 box.texture=load(ROOT_UI+"outer_panel.png") as Texture2D
 box.texture_margin_left=29.0
 box.texture_margin_right=29.0
 box.texture_margin_top=29.0
 box.texture_margin_bottom=29.0
 box.content_margin_left=8.0
 box.content_margin_top=7.0
 box.content_margin_right=8.0
 box.content_margin_bottom=7.0
 return box

func _label(parent: Node,name: String,text_value: String,font_size: int) -> Label:
 var control:=Label.new()
 control.name=name
 control.text=text_value
 control.mouse_filter=Control.MOUSE_FILTER_IGNORE
 control.add_theme_color_override("font_color",Color("#fbe2aa"))
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
 player_class=_label(layout,"Class","",12)
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
 if not is_instance_valid(player_name) or game_store==null: return
 var data: Dictionary=game_store.get("profile")
 var level: int=int(data.get("level",1))
 var name: String=str(data.get("name","Adventurer"))
 player_name.text="Lv.%d  %s" % [level,name]
 player_class.text=str(data.get("job","Novice"))+"  |  Class "+str(data.get("class_tier",0))
 var exp: int=int(data.get("experience",0))
 var required: int=int(game_store.call("experience_required",level))
 player_exp.text="EXP "+str(exp)+" / "+str(required)
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
 target_type_label.visible=not category.is_empty()
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
  target_health_value.text="%.0f / %.0f  (%.0f%%)" % [hp,max_hp,health_ratio*100.0]
 var max_mp:float=float(current_target.get_meta("max_mp",-1.0))
 var mp:float=float(current_target.get_meta("mp",-1.0))
 var has_mp:bool=max_mp>0.0 and mp>=0.0
 target_mana_label.visible=has_mp
 target_mana_bar.visible=has_mp
 target_mana_value.visible=has_mp
 if has_mp:
  var mana_ratio:float=clampf(mp/max_mp,0.0,1.0)
  target_mana_bar.value=mana_ratio*100.0
  target_mana_value.text="%.0f / %.0f  (%.0f%%)" % [mp,max_mp,mana_ratio*100.0]

func _layout() -> void:
 if not is_instance_valid(player_panel): return
 var width: float=maxf(320.0,size.x)
 var phone: bool=width<600.0
 var tablet: bool=width>=600.0 and width<1100.0
 var profile_w: float=165.0 if phone else (214.0 if tablet else 265.0)
 var profile_h: float=80.0 if phone else (84.0 if tablet else 103.0)
 var map_w: float=88.0 if phone else (118.0 if tablet else 151.0)
 var map_x: float=width-map_w-9.0
 player_panel.position=Vector2(7.0,6.0)
 player_panel.size=Vector2(profile_w,profile_h)
 var body: Control=player_panel.get_node("PortraitContent") as Control
 body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 body.position=Vector2.ZERO
 body.size=player_panel.size-Vector2(16.0,14.0)
 var portrait_w:float=49.0 if phone else (57.0 if tablet else 75.0)
 portrait.position=Vector2(7.0,4.0)
 portrait.size=Vector2(portrait_w,profile_h-15.0)
 var text_x:float=portrait_w+11.0
 var text_w:float=profile_w-text_x-12.0
 player_name.position=Vector2(text_x,2.0)
 player_name.size=Vector2(text_w,23.0)
 player_name.add_theme_font_size_override("font_size",10 if phone else (14 if tablet else 16))
 player_name.clip_text=true
 player_name.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 player_class.position=Vector2(text_x,26.0 if not phone else 23.0)
 player_class.size=Vector2(text_w,18.0)
 player_class.add_theme_font_size_override("font_size",10 if phone else 12)
 player_exp.position=Vector2(text_x,45.0 if not phone else 42.0)
 player_exp.size=Vector2(text_w,18.0)
 player_exp.add_theme_font_size_override("font_size",9 if phone else 11)
 exp_bar.position=Vector2(text_x,63.0 if not phone else 57.0)
 exp_bar.size=Vector2(text_w,9.0 if not phone else 7.0)
 minimap_button.position=Vector2(map_x,6.0)
 minimap_button.size=Vector2(map_w,map_w)
 minimap.position=Vector2.ZERO
 minimap.size=Vector2(map_w,map_w)
 north.position=Vector2(map_w*0.37,-3.0)
 north.size=Vector2(map_w*0.26,20.0)
 north.add_theme_font_size_override("font_size",10 if phone else 13)
 var zoom_size:float=18.0 if phone else 25.0
 zoom_in.position=Vector2(map_w-zoom_size-3.0,map_w*0.30)
 zoom_out.position=Vector2(map_w-zoom_size-3.0,map_w*0.56)
 zoom_in.size=Vector2(zoom_size,zoom_size)
 zoom_out.size=Vector2(zoom_size,zoom_size)
 # Keep the card at the very top center on landscape. On portrait phones
 # the 10-item menu occupies the second line; the target sits below it.
 var target_w:float=minf(width-22.0,330.0 if phone else 367.0)
 var target_h:float=98.0 if phone else 108.0
 var target_y:float=151.0 if width<760.0 else 58.0
 target_panel.position=Vector2((width-target_w)*0.5,target_y)
 target_panel.size=Vector2(target_w,target_h)
 var inner_w:float=target_w-14.0
 var inner_h:float=target_h-12.0
 target_body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 target_body.size=Vector2(inner_w,inner_h)
 _set_target_rect(target_decor,Vector2.ZERO,Vector2(inner_w,inner_h))
 target_decor.queue_redraw()
 var portrait_size:float=58.0 if phone else 68.0
 _set_target_rect(target_portrait,Vector2(46.0-portrait_size*0.5,inner_h*0.5-portrait_size*0.5),Vector2(portrait_size,portrait_size))
 _set_target_rect(target_portrait_placeholder,Vector2(17.0,inner_h*0.5-26.0),Vector2(58.0,52.0))
 var text_start:float=99.0
 var text_right:float=inner_w-8.0
 _set_target_rect(target_label,Vector2(text_start,5.0),Vector2(maxf(55.0,inner_w-text_start-104.0),26.0))
 target_label.add_theme_font_size_override("font_size",13 if phone else 15)
 _set_target_rect(target_level_label,Vector2(inner_w-106.0,7.0),Vector2(46.0,22.0))
 _set_target_rect(target_type_label,Vector2(inner_w-64.0,7.0),Vector2(56.0,22.0))
 target_type_label.add_theme_font_size_override("font_size",10)
 var bar_left:float=text_start+43.0
 var bar_width:float=maxf(72.0,text_right-bar_left-5.0)
 var bar_height:float=19.0 if phone else 20.0
 var hp_y:float=32.0
 var mp_y:float=57.0
 _set_target_rect(target_health_label,Vector2(text_start,hp_y),Vector2(39.0,bar_height))
 _set_target_rect(target_bar,Vector2(bar_left,hp_y),Vector2(bar_width,bar_height))
 _set_target_rect(target_health_value,Vector2(bar_left,hp_y),Vector2(bar_width,bar_height))
 _set_target_rect(target_mana_label,Vector2(text_start,mp_y),Vector2(39.0,bar_height))
 _set_target_rect(target_mana_bar,Vector2(bar_left,mp_y),Vector2(bar_width,bar_height))
 _set_target_rect(target_mana_value,Vector2(bar_left,mp_y),Vector2(bar_width,bar_height))
 _set_target_rect(target_hint,Vector2(text_start,41.0),Vector2(maxf(0.0,inner_w-text_start-10.0),30.0))
 target_hint.add_theme_font_size_override("font_size",11 if phone else 13)
 _refresh_target()

func _process(delta: float) -> void:
 last_world_update+=delta
 if last_world_update<0.16: return
 last_world_update=0.0
 if is_instance_valid(minimap) and is_instance_valid(game) and is_instance_valid(game.character):
  minimap.update_world(game.character.global_position,game.loot,game.camera_arm.rotation.y)
 if is_instance_valid(current_target): _refresh_target()
 elif current_target!=null: clear_target()

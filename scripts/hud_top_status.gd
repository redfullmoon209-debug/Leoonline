extends Control
## Lightweight responsive overlays for the player, real-world minimap and target.
## Values come only from the current save, live game or an explicit target node.
const MiniMapScript = preload("res://scripts/hud_minimap.gd")
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
var target_health_label: Label
var target_bar: ProgressBar
var current_target: Node3D
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

func _make_target() -> void:
 target_panel=PanelContainer.new()
 target_panel.name="LiveTargetHUD"
 target_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 # A slim frame for a slim target bar: reusing the thick 29px outer frame
 # at 40px height makes its borders collide with the target text.
 var slim:=StyleBoxFlat.new()
 slim.bg_color=Color("#240912")
 slim.border_color=Color("#e1ad61")
 slim.set_border_width_all(2)
 slim.set_corner_radius_all(13)
 slim.content_margin_left=8
 slim.content_margin_right=8
 slim.content_margin_top=5
 slim.content_margin_bottom=5
 target_panel.add_theme_stylebox_override("panel",slim)
 add_child(target_panel)
 var body:=Control.new()
 body.name="TargetContent"
 body.mouse_filter=Control.MOUSE_FILTER_IGNORE
 target_panel.add_child(body)
 target_label=_label(body,"TargetName","เป้าหมาย: ยังไม่ได้เลือก",14)
 target_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 target_health_label=_label(body,"TargetHP","",11)
 target_health_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 target_bar=ProgressBar.new()
 target_bar.name="TargetHealth"
 target_bar.show_percentage=false
 target_bar.min_value=0
 target_bar.max_value=100
 target_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var bg:=StyleBoxFlat.new()
 bg.bg_color=Color("#24080a")
 bg.border_color=Color("#bb713c")
 bg.set_border_width_all(1)
 var fill:=StyleBoxFlat.new()
 fill.bg_color=Color("#d14151")
 target_bar.add_theme_stylebox_override("background",bg)
 target_bar.add_theme_stylebox_override("fill",fill)
 body.add_child(target_bar)
 _refresh_target()

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

func _refresh_target() -> void:
 if not is_instance_valid(target_label): return
 if not is_instance_valid(current_target):
  current_target=null
  target_label.text="เป้าหมาย: ยังไม่ได้เลือก"
  target_label.position.y=10.0 if target_panel.size.y<=50.0 else 17.0
  target_health_label.text=""
  target_bar.visible=false
  return
 var display_name: String=str(current_target.get_meta("target_name",current_target.name))
 if display_name.strip_edges().is_empty(): display_name="เป้าหมาย"
 var level: int=int(current_target.get_meta("level",0))
 target_label.text=display_name+("  Lv."+str(level) if level>0 else "")
 target_label.position.y=2.0
 var max_hp: float=float(current_target.get_meta("max_hp",-1.0))
 var hp: float=float(current_target.get_meta("hp",-1.0))
 if max_hp<=0.0 or hp<0.0:
  target_health_label.text="HP: ไม่มีข้อมูล"
  target_bar.visible=false
 else:
  target_bar.visible=true
  target_bar.value=100.0*clampf(hp/max_hp,0.0,1.0)
  target_health_label.text="HP: %.0f / %.0f" % [hp,max_hp]

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
 var target_w:float=minf(width-24.0,260.0 if phone else 300.0)
 var target_h:float=50.0 if phone else (56.0 if tablet else 59.0)
 target_panel.position=Vector2((width-target_w)*0.5,156.0 if phone else (188.0 if tablet else 109.0))
 target_panel.size=Vector2(target_w,target_h)
 var target_body: Control=target_panel.get_node("TargetContent") as Control
 target_body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 target_body.size=Vector2(target_w-16.0,target_h-14.0)
 target_label.position=Vector2(1.0,2.0)
 target_label.size=Vector2(target_w-18.0,24.0)
 target_label.add_theme_font_size_override("font_size",12 if phone else 14)
 target_health_label.position=Vector2(1.0,25.0)
 target_health_label.size=Vector2(target_w-18.0,15.0)
 target_health_label.add_theme_font_size_override("font_size",10 if phone else 11)
 target_bar.position=Vector2(5.0,target_h-12.0)
 target_bar.size=Vector2(target_w-26.0,6.0)
 _refresh_target()

func _process(delta: float) -> void:
 last_world_update+=delta
 if last_world_update<0.16: return
 last_world_update=0.0
 if is_instance_valid(minimap) and is_instance_valid(game) and is_instance_valid(game.character):
  minimap.update_world(game.character.global_position,game.loot,game.camera_arm.rotation.y)
 if is_instance_valid(current_target): _refresh_target()
 elif current_target!=null: clear_target()

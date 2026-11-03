extends Control
## Two independently layered PNG textures: stationary base and moving thumb knob.
const BASE_PNG: String = "res://assets/ui/hud/premium/joystick_base.png"
const KNOB_PNG: String = "res://assets/ui/hud/premium/joystick_knob.png"
var base_texture: Texture2D
var knob_texture: Texture2D
var display_movement: Vector2 = Vector2.ZERO
var movement: Vector2 = Vector2.ZERO
var edit_mode: bool = false
var active_touch: int = -1
var active_mouse: bool = false

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_STOP
 if ResourceLoader.exists(BASE_PNG): base_texture = load(BASE_PNG) as Texture2D
 if ResourceLoader.exists(KNOB_PNG): knob_texture = load(KNOB_PNG) as Texture2D
 queue_redraw()

func set_edit_mode(enabled: bool) -> void:
 edit_mode = enabled
 movement = Vector2.ZERO
 active_touch = -1
 active_mouse = false
 display_movement = Vector2.ZERO
 queue_redraw()

func _point_to_vector(local_point: Vector2) -> void:
 var origin: Vector2 = size*0.5
 var radius: float = minf(size.x,size.y)*0.32
 movement = ((local_point-origin)/maxf(radius,1.0)).limit_length(1.0)
 queue_redraw()

func _gui_input(event: InputEvent) -> void:
 if edit_mode: return
 if event is InputEventScreenTouch:
  if event.pressed and active_touch<0:
   active_touch=event.index
   _point_to_vector(event.position)
   accept_event()
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  if active_touch>=0: return
  active_mouse=event.pressed
  if active_mouse:
   _point_to_vector(event.position)
  else:
   movement=Vector2.ZERO
   queue_redraw()
  accept_event()

func _input(event: InputEvent) -> void:
 if edit_mode: return
 if event is InputEventScreenDrag and event.index==active_touch:
  _point_to_vector(get_global_transform_with_canvas().affine_inverse()*event.position)
  get_viewport().set_input_as_handled()
 elif event is InputEventScreenTouch and event.index==active_touch and not event.pressed:
  active_touch=-1
  movement=Vector2.ZERO
  queue_redraw()
  get_viewport().set_input_as_handled()
 elif event is InputEventMouseMotion and active_mouse and active_touch<0:
  _point_to_vector(get_global_transform_with_canvas().affine_inverse()*event.position)
  get_viewport().set_input_as_handled()
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed and active_mouse:
  active_mouse=false
  movement=Vector2.ZERO
  queue_redraw()
  get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
 var target: Vector2 = movement
 var alpha: float = 1.0 - exp(-18.0 * delta)
 display_movement = display_movement.lerp(target, alpha)
 if display_movement.distance_squared_to(target) > 0.00001 or movement.length_squared() > 0.0:
  queue_redraw()

func _draw() -> void:
 var center: Vector2 = size*0.5
 var r: float = minf(size.x,size.y)*0.44
 if base_texture != null:
  draw_texture_rect(base_texture, Rect2(center-Vector2.ONE*r,Vector2.ONE*r*2.0),false)
 else:
  draw_circle(center,r,Color(0.08,0.02,0.075,0.67))
 if base_texture == null: draw_arc(center,r,0.0,TAU,64,Color(0.85,0.61,0.29,0.84),3.0,true)
 if base_texture == null: draw_arc(center,r*0.72,0.0,TAU,64,Color(0.98,0.80,0.47,0.22),1.7,true)
 var hand: Vector2 = center+display_movement*r*0.54
 if knob_texture != null:
  var knob_r: float = r*0.43
  draw_texture_rect(knob_texture,Rect2(hand-Vector2.ONE*knob_r,Vector2.ONE*knob_r*2.0),false)
 else:
  draw_circle(hand,r*0.37,Color("#692235"))
 if knob_texture == null: draw_arc(hand,r*0.37,0.0,TAU,48,Color("#f9d58b"),2.5,true)
 if knob_texture == null: draw_circle(hand,r*0.14,Color("#f2c777"))

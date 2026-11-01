extends Control
## Native draw/canvas joystick. Does not require screenshots or PNG crops.
var movement: Vector2 = Vector2.ZERO
var edit_mode: bool = false
var active_touch: int = -1
var active_mouse: bool = false

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_STOP
 queue_redraw()

func set_edit_mode(enabled: bool) -> void:
 edit_mode = enabled
 movement = Vector2.ZERO
 active_touch = -1
 active_mouse = false
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

func _draw() -> void:
 var center: Vector2 = size*0.5
 var r: float = minf(size.x,size.y)*0.44
 draw_circle(center,r,Color(0.08,0.02,0.075,0.67))
 draw_arc(center,r,0.0,TAU,64,Color(0.85,0.61,0.29,0.84),3.0,true)
 draw_arc(center,r*0.72,0.0,TAU,64,Color(0.98,0.80,0.47,0.22),1.7,true)
 var hand: Vector2 = center+movement*r*0.54
 draw_circle(hand,r*0.37,Color("#692235"))
 draw_arc(hand,r*0.37,0.0,TAU,48,Color("#f9d58b"),2.5,true)
 draw_circle(hand,r*0.14,Color("#f2c777"))

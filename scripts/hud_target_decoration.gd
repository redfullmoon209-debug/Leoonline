extends Control
## Original frame drawn in Godot. No part of the approved mockup is cropped,
## sliced or used as an in-game screenshot.
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)

func _diamond(center: Vector2, x_radius: float, y_radius: float, color: Color) -> void:
 var vertices:=PackedVector2Array([
  center+Vector2(0,-y_radius),
  center+Vector2(x_radius,0),
  center+Vector2(0,y_radius),
  center+Vector2(-x_radius,0)
 ])
 draw_colored_polygon(vertices,color)
 draw_polyline(PackedVector2Array([
  vertices[0],vertices[1],vertices[2],vertices[3],vertices[0]
 ]),Color("#ffecb2"),1.35,true)

func _draw() -> void:
 var w:float=size.x
 var h:float=size.y
 if w<110.0 or h<45.0:return
 # Only the portrait medallion remains inside the outer gold frame:
 # NO horizontal dividers, diagonal rules, separators or floating gems.
 var compact:bool=w<230.0
 var center_x:float=26.0 if compact and w>140.0 else (23.0 if compact else 46.0)
 var c:=Vector2(center_x,h*0.5)
 var radius:float=minf(22.0,h*0.32) if compact else minf(39.0,h*0.43)
 draw_circle(c+Vector2(0.0,1.5),radius+3.0,Color(0.0,0.0,0.0,0.48))
 draw_circle(c,radius+2.5,Color("#704015"))
 draw_arc(c,radius+1.2,0.0,TAU,64,Color("#ffde88"),2.3,true)
 draw_circle(c,radius-2.0,Color("#172231"))
 draw_arc(c,radius-4.0,0.0,TAU,64,Color("#76909a"),1.0,true)

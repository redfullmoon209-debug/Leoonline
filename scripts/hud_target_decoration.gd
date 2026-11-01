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
 if w<120.0 or h<45.0:return
 var gold:=Color("#e3a64d")
 var pale:=Color("#fff1b8")
 var copper:=Color("#794019")
 # Fine hand-drawn inner bezel, with independent ornamental corners.
 draw_line(Vector2(85.0,9.0),Vector2(w-12.0,9.0),gold,1.4,true)
 draw_line(Vector2(85.0,h-9.0),Vector2(w-12.0,h-9.0),gold,1.4,true)
 draw_line(Vector2(94.0,13.0),Vector2(w-18.0,13.0),Color("#fff2bd",0.28),0.8,true)
 draw_line(Vector2(94.0,h-13.0),Vector2(w-18.0,h-13.0),Color("#eabc70",0.25),0.8,true)
 _diamond(Vector2(w*0.5,8.0),10.0,7.0,copper)
 _diamond(Vector2(w*0.5,8.0),5.0,5.0,Color("#bf2334"))
 _diamond(Vector2(w*0.5,h-8.0),8.0,5.0,Color("#95602a"))
 _diamond(Vector2(w*0.5,h-8.0),3.5,3.2,Color("#42b9e7"))
 # The portrait medallion has a real transparent icon layered above it.
 var c:=Vector2(46.0,h*0.5)
 var radius:float=minf(39.5,h*0.45)
 draw_circle(c+Vector2(0,2),radius+4.5,Color(0,0,0,0.56))
 draw_circle(c,radius+4.5,Color("#63320d"))
 draw_arc(c,radius+4.0,0.0,TAU,64,pale,2.2,true)
 draw_arc(c,radius+0.2,0.0,TAU,64,gold,2.2,true)
 draw_circle(c,radius-3.0,Color("#24141c"))
 draw_circle(c,radius-5.0,Color("#19222d"))
 draw_arc(c,radius-7.0,0.0,TAU,64,Color("#5c7b89"),1.0,true)
 # Crescent and tiny jewels are decorative. They are NOT alert badges.
 _diamond(c+Vector2(0,-radius-2.5),5.0,5.5,Color("#2f9bd5"))
 _diamond(c+Vector2(0,radius+2.5),5.0,5.5,Color("#2f9bd5"))
 draw_line(Vector2(93.0,21.0),Vector2(93.0,h-20.0),gold,1.15,true)
 for sx in [102.0,w-13.0]:
  draw_circle(Vector2(sx,17.0),1.45,pale)
  draw_circle(Vector2(sx,h-17.0),1.45,pale)

extends Control
## Real circular local-world minimap for the current 80x80 Godot test map.
## No remote player positions, fabricated geography, or cropped screenshot.
var hero: Vector3 = Vector3.ZERO
var heading: float = 0.0
var items: Array[Vector3] = []
var zoom: float = 1.0

func update_world(position: Vector3, loot: Array, yaw: float) -> void:
 hero = position
 heading = yaw
 items.clear()
 for entry in loot:
  if is_instance_valid(entry):
   items.append(entry.global_position)
 queue_redraw()

func _to_map(position: Vector3, center: Vector2, radius: float) -> Vector2:
 # The center is the player: items move relative to current player position.
 return center + Vector2(position.x - hero.x, position.z - hero.z) * radius * zoom / 28.0

func _draw() -> void:
 var center: Vector2 = size * 0.5
 var radius: float = minf(size.x,size.y)*0.455
 if radius <= 0: return
 draw_circle(center,radius+6.0,Color("#11040a"))
 draw_circle(center,radius+3.0,Color("#b67530"))
 draw_circle(center,radius,Color("#271d24"))
 draw_circle(center,radius-4.0,Color("#2c3e3e"))
 # Actual prototype grid and two tracks, kept within the circular boundary.
 for i in range(-4,5):
  var n: float=float(i)*radius/4.0
  var extent: float=sqrt(maxf(0.0,(radius-6.0)*(radius-6.0)-n*n))
  draw_line(center+Vector2(n,-extent),center+Vector2(n,extent),Color("#4f6660",0.65),1.0,true)
  draw_line(center+Vector2(-extent,n),center+Vector2(extent,n),Color("#4f6660",0.65),1.0,true)
 draw_line(center+Vector2(-radius+8.0,0.0),center+Vector2(radius-8.0,0.0),Color("#c09b63",0.48),6.0,true)
 draw_line(center+Vector2(0.0,-radius+8.0),center+Vector2(0.0,radius-8.0),Color("#c09b63",0.48),6.0,true)
 for drop in items:
  var p:Vector2=_to_map(drop,center,radius-7.0)
  if p.distance_to(center)<radius-9.0:
   draw_circle(p,3.3,Color("#fbd98d"))
   draw_circle(p,1.5,Color.WHITE)
 # Player marker with real camera facing direction, not fake enemy pins.
 var forward:=Vector2(sin(heading),-cos(heading))
 var right:=Vector2(forward.y,-forward.x)
 var arrow:=PackedVector2Array([
  center+forward*9.0,
  center-forward*5.0+right*5.0,
  center-forward*2.5,
  center-forward*5.0-right*5.0
 ])
 draw_colored_polygon(arrow,Color("#55e8ff"))
 draw_polyline(PackedVector2Array([arrow[0],arrow[1],arrow[3],arrow[0]]),Color("#ffffff"),1.5,true)
 draw_arc(center,radius+2.5,0.0,TAU,80,Color("#ffdf8b"),2.0,true)
 draw_arc(center,radius-1.0,0.0,TAU,80,Color("#634222"),1.2,true)

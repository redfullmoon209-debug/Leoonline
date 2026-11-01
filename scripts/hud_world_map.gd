extends Control
## An actual local-world overview, drawn from the playable 80x80 prototype.
## Never shows invented online locations or imported/cropped screenshots.
var hero: Vector3 = Vector3.ZERO
var loot_points: Array[Vector3] = []
var zoom: float = 1.0

func update_world(position: Vector3, drops: Array) -> void:
 hero = position
 loot_points.clear()
 for entry in drops:
  if is_instance_valid(entry):
   loot_points.append(entry.global_position)
 queue_redraw()

func _world_to_map(world: Vector3, rect: Rect2) -> Vector2:
 var center: Vector2 = rect.get_center()
 var radius: float = minf(rect.size.x,rect.size.y)*0.41*zoom
 return center + Vector2(world.x,-world.z)*radius/40.0

func _draw() -> void:
 var rect: Rect2 = Rect2(Vector2.ZERO,size)
 draw_rect(rect,Color("#190b17"),true)
 draw_rect(rect.grow(-4.0),Color("#2d1826"),true)
 var center: Vector2 = rect.get_center()
 var radius: float = minf(rect.size.x,rect.size.y)*0.41*zoom
 # Stylized current level grid / paths; this is not an online world map.
 for i in range(-4,5):
  var step: float = float(i)*radius/4.0
  draw_line(center+Vector2(step,-radius),center+Vector2(step,radius),Color(0.76,0.54,0.33,0.22),1.0)
  draw_line(center+Vector2(-radius,step),center+Vector2(radius,step),Color(0.76,0.54,0.33,0.22),1.0)
 draw_rect(Rect2(center-Vector2(radius,radius),Vector2(radius*2.0,radius*2.0)),Color("#9e7953"),false,2.0)
 draw_line(center+Vector2(-radius,0),center+Vector2(radius,0),Color(0.85,0.61,0.35,0.38),7.0)
 draw_line(center+Vector2(0,-radius),center+Vector2(0,radius),Color(0.85,0.61,0.35,0.38),7.0)
 for drop in loot_points:
  var spot: Vector2 = _world_to_map(drop,rect)
  if rect.grow(-10.0).has_point(spot):
   draw_circle(spot,5.5,Color("#fcce74"))
   draw_circle(spot,2.0,Color("#fff8dc"))
 var hero_at: Vector2 = _world_to_map(hero,rect)
 draw_circle(hero_at,10.0,Color(0.17,0.62,0.95,0.19))
 draw_circle(hero_at,6.0,Color("#55dcf7"))
 draw_circle(hero_at,2.8,Color.WHITE)

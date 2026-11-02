extends RefCounted
## Clean Leoonline button states. All pages use the same flat red square;
## no internal stripes, glowing strokes or image-based hover artwork.
const BASE := Color("#26090e")
const ACTIVE := Color("#501018")
const GOLD := Color("#c99c60")
const HOVER := Color("#af2630")
const DOWN := Color("#89151e")
const CLEAR := Color(0.87,0.05,0.13,0.0)
const HOVER_IMAGE := Color(0.87,0.05,0.13,0.36)
const DOWN_IMAGE := Color(0.87,0.05,0.13,0.62)

static func rectangle(fill: Color, border: bool = false) -> StyleBoxFlat:
 var box := StyleBoxFlat.new()
 box.bg_color = fill
 box.border_color = GOLD if border else Color.TRANSPARENT
 box.set_border_width_all(2 if border else 0)
 box.set_corner_radius_all(0)
 box.set_content_margin_all(4.0)
 return box

static func hover_style() -> StyleBoxFlat:
 return rectangle(HOVER)

static func pressed_style() -> StyleBoxFlat:
 return rectangle(DOWN)

static func apply(button: Button, selected: bool = false, image_base: bool = false) -> void:
 button.flat = false
 button.add_theme_stylebox_override("normal",StyleBoxEmpty.new() if image_base else rectangle(ACTIVE if selected else BASE,true))
 button.add_theme_stylebox_override("hover",hover_style())
 button.add_theme_stylebox_override("pressed",pressed_style())
 button.add_theme_stylebox_override("hover_pressed",pressed_style())
 button.add_theme_stylebox_override("disabled",StyleBoxEmpty.new() if image_base else rectangle(Color("#180a0c"),true))
 button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
 button.add_theme_color_override("font_color",Color("#ffdfab"))
 button.add_theme_color_override("font_hover_color",Color.WHITE)
 button.add_theme_color_override("font_pressed_color",Color.WHITE)
 button.add_theme_color_override("font_hover_pressed_color",Color.WHITE)
 button.add_theme_color_override("font_disabled_color",Color("#a58c7d"))
 button.set_meta("leo_red_square_button",true)

static func _tint(rect: ColorRect,color: Color) -> void:
 if is_instance_valid(rect):rect.color=color

static func image_overlay(button: BaseButton) -> void:
 # Preserve each existing icon/slot PNG. The only active decoration
 # is a simple transparent red rectangle that never intercepts taps.
 if button.get_node_or_null("RedHoverRectangle")!=null:return
 var red:=ColorRect.new()
 red.name="RedHoverRectangle"
 red.color=CLEAR
 red.mouse_filter=Control.MOUSE_FILTER_IGNORE
 button.add_child(red)
 red.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 button.mouse_entered.connect(func():
  if not button.disabled:_tint(red,HOVER_IMAGE)
 )
 button.mouse_exited.connect(func():_tint(red,CLEAR))
 button.button_down.connect(func():
  if not button.disabled:_tint(red,DOWN_IMAGE)
 )
 button.button_up.connect(func():
  if button.disabled:
   _tint(red,CLEAR)
  elif button.get_global_rect().has_point(button.get_global_mouse_position()):
   _tint(red,HOVER_IMAGE)
  else:
   _tint(red,CLEAR)
 )

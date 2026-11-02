extends RefCounted
## Clean Leoonline button states. All pages use the same flat red square;
## no internal stripes, glowing strokes or image-based hover artwork.
const BASE := Color("#26090e")
const ACTIVE := Color("#501018")
const GOLD := Color("#c99c60")
const HOVER := Color("#af2630")
const DOWN := Color("#89151e")
const CLEAR := Color(0.87,0.05,0.13,0.0)
# Icon-only controls must remain untinted while the cursor hovers.
const DOWN_IMAGE := Color(0.91,0.07,0.14,0.56)
# Bright scarlet while actively pressing the bag. Unlike hover,
# this visual lasts only while the button is held/touched.
const BAG_DOWN_IMAGE := Color(1.0,0.035,0.09,0.84)
const BAG_SELECTED := Color("#ed1741")

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

static func bag_selected_style() -> StyleBoxFlat:
 return rectangle(BAG_SELECTED,true)

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

static func image_overlay(button: BaseButton, down_color: Color = DOWN_IMAGE) -> void:
 # Icon imagery is NEVER washed red on pointer hover. A square red
 # overlay is shown only while the button is actively pressed/touched.
 # No new ring, gold base, decorative border or animated effect.
 if button.get_node_or_null("RedHoverRectangle")!=null:return
 var red:=ColorRect.new()
 red.name="RedHoverRectangle"
 red.color=CLEAR
 red.mouse_filter=Control.MOUSE_FILTER_IGNORE
 button.add_child(red)
 red.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 button.mouse_entered.connect(func():
  # Do not tint on hover, even if this is a touch/mouse hybrid.
  if not button.button_pressed:_tint(red,CLEAR)
 )
 button.mouse_exited.connect(func():_tint(red,CLEAR))
 button.button_down.connect(func():
  if not button.disabled:_tint(red,down_color)
 )
 button.button_up.connect(func():_tint(red,CLEAR))

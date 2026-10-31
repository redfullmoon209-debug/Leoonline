extends Node
# Browser-local UI configuration shared with the 911 PWA on the same origin.
const STORAGE_KEY := "leo911_ui_v1"
var host: Node3D
var layer: CanvasLayer
var pages: Dictionary = {}

func _ready() -> void:
 host = get_parent() as Node3D
 if not OS.has_feature("web"):
  return
 var raw: String = str(JavaScriptBridge.eval("localStorage.getItem('leo911_ui_v1') || ''", true))
 if raw.is_empty():
  return
 var parsed: Variant = JSON.parse_string(raw)
 if not (parsed is Dictionary) or not (parsed.get("items", null) is Array):
  return
 layer = CanvasLayer.new()
 layer.layer = 2
 host.add_child.call_deferred(layer)
 # Wait until layer is attached before creating child Controls.
 call_deferred("_build", parsed["items"])

func _build(items: Array) -> void:
 if not is_instance_valid(layer):
  return
 var count := 0
 for entry in items:
  if count >= 100:
   break
  if not (entry is Dictionary):
   continue
  var kind: String = str(entry.get("kind", ""))
  if kind != "button" and kind != "page":
   continue
  count += 1
  var x: float = clampf(float(entry.get("x", 0)), 0.0, 95.0) / 100.0
  var y: float = clampf(float(entry.get("y", 0)), 0.0, 95.0) / 100.0
  var w: float = clampf(float(entry.get("w", 10)), 5.0, 100.0) / 100.0
  var h: float = clampf(float(entry.get("h", 10)), 5.0, 100.0) / 100.0
  var title: String = str(entry.get("title", "UI")).substr(0, 80)
  var element: Control
  if kind == "page":
   var panel := PanelContainer.new()
   var style := StyleBoxFlat.new()
   style.bg_color = Color("#102844e8")
   style.border_color = Color("#d9ae58")
   style.set_border_width_all(2)
   panel.add_theme_stylebox_override("panel", style)
   var label := Label.new()
   label.text = title
   label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
   panel.add_child(label)
   panel.visible = false
   pages[str(entry.get("id", ""))] = panel
   element = panel
  else:
   var button := Button.new()
   button.text = title
   button.add_theme_stylebox_override("normal", _style())
   var action: String = str(entry.get("action", "none"))
   var target: String = str(entry.get("target", ""))
   button.pressed.connect(func(): _activate(action, target))
   element = button
  element.anchor_left = x
  element.anchor_top = y
  element.anchor_right = minf(1.0, x + w)
  element.anchor_bottom = minf(1.0, y + h)
  element.offset_left = 0
  element.offset_top = 0
  element.offset_right = 0
  element.offset_bottom = 0
  layer.add_child(element)

func _style() -> StyleBoxFlat:
 var s := StyleBoxFlat.new()
 s.bg_color = Color("#17365c")
 s.border_color = Color("#d9ae58")
 s.set_border_width_all(2)
 s.set_corner_radius_all(7)
 return s

func _activate(action: String, target: String) -> void:
 match action:
  "inventory":
   host.call("_toggle")
  "sort":
   host.get("store").call("sort_items")
  "equip":
   host.get("store").call("equip_selected")
  "save":
   host.get("store").call("save_data")
  "page":
   if pages.has(target):
    var panel: Control = pages[target]
    panel.visible = not panel.visible

extends Node
## Read-only instrumentation enabled only by the test HTML's CLI flag.
## No commands, save mutation, or remote endpoints are exposed.
var host: Node
var elapsed := 0.0
func _ready() -> void:
 host = get_parent()
func bounds(control: Control, offset: Vector2 = Vector2.ZERO) -> Array:
 var r := control.get_global_rect()
 return [r.position.x+offset.x,r.position.y+offset.y,r.size.x,r.size.y]
func buttons(controls: Array) -> Array:
 var result: Array = []
 for control in controls: result.append(bounds(control))
 return result
func _process(delta: float) -> void:
 elapsed += delta
 if elapsed < 0.1 or not OS.has_feature("web"): return
 elapsed=0.0
 var ui = host.get("inventory")
 var store = host.get("store")
 var locked := 0
 for button in ui.bag_grid.get_children():
  if button.get_meta("locked",false): locked+=1
 var state := {
  "open":ui.visible,"page":ui.current_page,"locale":ui.locale,"tab":ui.current_tab,
  "slots":store.slots,"equipped":store.equipped,"unlocked":store.unlocked,
  "selected":store.selected,"currency":store.currency,"notice":ui.notice_text.text,
  "locked":locked,"columns":ui.bag_grid.columns,"cells":ui.bag_grid.get_child_count(),
  "fashion":ui.fashion_row.get_child_count(),"accessories":ui.accessory_row.get_child_count(),
  "fashion_weapons":ui.fashion_weapon_row.get_child_count()+ui.fashion_side_row.get_child_count(),
  "detail_visible":ui.detail_panel.visible,"detail_name":ui.detail_heading.text,
  "detail_text":ui.detail_description.text,"detail_bounds":bounds(ui.detail_panel),
  "detail_close":bounds(ui.detail_dismiss),"scroller":bounds(ui.scroller),
  "scroll":[ui.scroller.scroll_horizontal,ui.scroller.scroll_vertical],
  "bag":buttons(ui.bag_grid.get_children()),"right_equipment":buttons(ui.extra_equip_list.get_children()),
  "footer":buttons(ui.footer_buttons),"tabs":buttons(ui.tab_buttons),
  "pages":buttons(ui.page_buttons),"language":bounds(ui.language_button),
  "opener":bounds(host.get("hud").get_node("OpenInventory")),
  "waiting":ui.waiting_text.text,"trash_visible":ui.trash_dialog.visible
 }
 if ui.trash_dialog.visible:
  var offset := Vector2(ui.trash_dialog.position)
  state["trash_ok"]=bounds(ui.trash_dialog.get_ok_button(),offset)
  state["trash_cancel"]=bounds(ui.trash_dialog.get_cancel_button(),offset)
 JavaScriptBridge.eval("window.__leoQA="+JSON.stringify(state),true)

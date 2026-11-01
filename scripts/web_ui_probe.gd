extends Node
## Read-only instrumentation enabled only by the test HTML's CLI flag.
## No commands, save mutation, or remote endpoints are exposed.
var host: Node
var elapsed := 0.0
var input_counts: Dictionary = {}
func _input(event: InputEvent) -> void:
 var kind: String = event.get_class()
 input_counts[kind] = int(input_counts.get(kind,0))+1
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
  "input_counts":input_counts,"touchscreen":DisplayServer.is_touchscreen_available(),
  "pan":[ui.pan_finger,ui.pan_active],"h_range":[ui.scroller.get_h_scroll_bar().max_value,ui.scroller.get_h_scroll_bar().page],
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
  "storage_icon":bounds(ui.storage_menu_button),
  "storage_icon_visible":ui.storage_menu_button.is_visible_in_tree(),
  "storage_icon_tooltip":ui.storage_menu_button.tooltip_text,
  "storage_icon_in_bag":ui.storage_menu_button.get_parent()==ui.bag_panel,
  "has_storage_hud":host.get("hud").has_node("OpenStorage"),
  "storage_mode":ui.storage_mode,"storage_visible":ui.storage_panel.visible,
  "storage_slots":store.storage_slots,"storage_selected":store.storage_selected,
  "storage_page":ui.storage_page,"storage_cells":ui.storage_grid.get_child_count(),
  "storage_grid":buttons(ui.storage_grid.get_children()),
  "storage_pages":buttons(ui.storage_page_buttons),
  "storage_count":ui.storage_capacity_label.text,
  "storage_bag_right":ui.bag_panel.visible and ui.bag_panel.position==Vector2.ZERO,
  "storage_equipment_hidden":not ui.equipment_panel.visible,
  "storage_deposit":bounds(ui.storage_deposit_button),
  "storage_withdraw":bounds(ui.storage_withdraw_button),
  "storage_deposit_disabled":ui.storage_deposit_button.disabled,
  "storage_withdraw_disabled":ui.storage_withdraw_button.disabled,
  "waiting":ui.waiting_text.text,"trash_visible":ui.trash_dialog.visible,
  "char_visible":ui.character_panel.visible,
  "char_values":{},
  "char_equipment_left":ui.equipment_panel.visible,
  "shop_visible":ui.shop_panel.visible,"shop_left_inventory":ui.bag_panel.visible,"shop_left_border":ui.shop_left_frame.visible,
  "shop_left_shift":ui.bag_panel.position.x,"shop_page":ui.shop_page,
  "shop_cells":ui.shop_grid.get_child_count(),"shop_stock_label":ui.shop_stock_label.text,
  "shop_selected_id":ui.shop_selected_id,"shop_info":ui.shop_product_label.text,
  "shop_price":ui.shop_price_label.text,"shop_status":ui.shop_status_label.text,
  "shop_slots":buttons(ui.shop_grid.get_children()),
  "shop_buy":bounds(ui.shop_buy_button),"shop_sell":bounds(ui.shop_sell_button),
  "shop_pages":buttons(ui.shop_page_buttons),"shop_sell_visible":ui.shop_sell_dialog.visible,
  "shop_buy_disabled":ui.shop_buy_button.disabled,"shop_sell_disabled":ui.shop_sell_button.disabled
 }
 var character_data: Dictionary = {}
 for key in ui.character_values:
  character_data[str(key)] = str(ui.character_values[key].text)
 state["char_values"]=character_data
 if ui.trash_dialog.visible:
  var offset := Vector2(ui.trash_dialog.position)
  state["trash_ok"]=bounds(ui.trash_dialog.get_ok_button(),offset)
  state["trash_cancel"]=bounds(ui.trash_dialog.get_cancel_button(),offset)
 if ui.shop_sell_dialog.visible:
  var shop_offset := Vector2(ui.shop_sell_dialog.position)
  state["shop_sell_ok"]=bounds(ui.shop_sell_dialog.get_ok_button(),shop_offset)
  state["shop_sell_cancel"]=bounds(ui.shop_sell_dialog.get_cancel_button(),shop_offset)
 JavaScriptBridge.eval("window.__leoQA="+JSON.stringify(state),true)

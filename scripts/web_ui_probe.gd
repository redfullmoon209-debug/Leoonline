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
 var menu: Control=host.get("hud_menu")
 var hud_icons: Dictionary={}
 for id in ["world","party","friends","ranking","settings","guild","quest","mail","events"]:
  hud_icons[id]=bounds(menu.controls[id])
 var ten_ids: Array[String]=["bag","world","party","friends","ranking","settings","guild","quest","mail","events"]
 var ten_bounds: Array=[]
 var ten_textures: Array=[]
 var alert_state: Dictionary={}
 for id in ten_ids:
  var control: Control=menu.controls[id] as Control
  ten_bounds.append(bounds(control))
  var art: Texture2D=control.texture_normal if id=="bag" else (control.get_node("Glyph") as TextureRect).texture
  ten_textures.append(art.resource_path if art!=null else "")
  alert_state[id]=menu.notification_badges[id].visible
 var close_hud: Control=menu.popup.find_child("CloseHUDPanel",true,false) as Control
 var save_hud: Control=menu.toolbar.find_child("SaveHUDLayout",true,false) as Control
 var cancel_hud: Control=menu.toolbar.find_child("CancelHUDLayout",true,false) as Control
 var swap_hud: Control=menu.toolbar.find_child("SwapHUDToolbar",true,false) as Control
 var restore_hud: Control=menu.page_body.find_child("ResetHUDLayout",true,false) as Control
 var start_hud: Control=menu.page_body.find_child("EditHUDLayout",true,false) as Control
 var state := {
  "hud_close_button":bounds(close_hud) if close_hud!=null else [],
  "hud_save_button":bounds(save_hud) if save_hud!=null else [],
  "hud_cancel_button":bounds(cancel_hud) if cancel_hud!=null else [],
  "hud_swap_toolbar":bounds(swap_hud) if swap_hud!=null else [],
  "hud_toolbar_on_top":menu.toolbar_on_top,
  "hud_reset_button":bounds(restore_hud) if restore_hud!=null else [],
  "hud_start_editor":bounds(start_hud) if start_hud!=null else [],
  "hud_icons":hud_icons,
  "hud_icon_count":hud_icons.size(),
  "hud_row_order":ten_ids,
  "hud_row":ten_bounds,
  "hud_png_paths":ten_textures,
  "hud_notification_badges":alert_state,
  "hud_profile_bounds":bounds(menu.top_status.player_panel),
  "hud_profile_label":menu.top_status.player_name.text,
  "hud_profile_experience":menu.top_status.player_exp.text,
  "hud_minimap_bounds":bounds(menu.top_status.minimap_button),
  "hud_minimap_items":menu.top_status.minimap.items.size(),
  "hud_target_bounds":bounds(menu.top_status.target_panel),
  "hud_target_name":menu.top_status.target_label.text,
  "hud_target_health_visible":menu.top_status.target_bar.visible,
  "hud_target_level":menu.top_status.target_level_label.text,
  "hud_target_type":menu.top_status.target_type_label.text,
  "hud_target_hp_text":menu.top_status.target_health_value.text,
  "hud_target_hp_percent":menu.top_status.target_bar.value,
  "hud_target_mp_visible":menu.top_status.target_mana_bar.visible,
  "hud_target_mp_text":menu.top_status.target_mana_value.text,
  "hud_target_mp_percent":menu.top_status.target_mana_bar.value,
  "hud_target_portrait_visible":menu.top_status.target_portrait.visible,
  "hud_target_portrait_asset":menu.top_status.target_portrait.texture.resource_path if menu.top_status.target_portrait.texture!=null else "",
  "hud_target_frame_custom":menu.top_status.target_decor.get_script()!=null,
  "hud_training_target_present":is_instance_valid(host.get("training_target")),
  "hud_training_target_name":str(host.get("training_target").get_meta("target_name","")) if is_instance_valid(host.get("training_target")) else "",
  "hud_panel_open":menu.popup.visible,
  "hud_panel_key":menu.popup_key,
  "hud_panel_bounds":bounds(menu.popup),
  "hud_panel_children":menu.page_body.get_child_count(),
  "hud_editing":menu.edit_mode,
  "hud_toolbar":bounds(menu.toolbar),
  "hud_editor_slider":bounds(menu.size_slider),
  "hud_selected":menu.selected_id,
  "hud_show_touch":menu.display_mobile_controls,
  "hud_landscape_preview":menu.force_touch_preview,
  "hud_layout":menu.layout_state,
  "hud_settings_button":bounds(menu.controls["settings"]),
  "hud_world_button":bounds(menu.controls["world"]),
  "hud_party_button":bounds(menu.controls["party"]),
  "hud_joystick":bounds(menu.controls["joystick"]),
  "hud_joystick_visible":menu.controls["joystick"].visible,
  "hud_touch_jump_visible":menu.controls["jump"].visible,
  "hud_touch_pickup_visible":menu.controls["pickup"].visible,
  "hud_touch_run_visible":menu.controls["run"].visible,
  "hud_touch_jump":bounds(menu.controls["jump"]),
  "hud_touch_pickup":bounds(menu.controls["pickup"]),
  "hud_touch_run":bounds(menu.controls["run"]),
  "hud_joystick_value":menu.controls["joystick"].movement,
  "hud_quest_pickups":menu.pickups,
  "hud_mail_claimed":menu.mail_claimed,
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
  "storage_tab":bounds(ui.tab_buttons[4]),
  "storage_tab_text":ui.tab_buttons[4].text,
  "storage_tab_visible":ui.tab_buttons[4].is_visible_in_tree(),
  "has_storage_hud":host.get("hud").has_node("OpenStorage"),
  "storage_mode":ui.storage_mode,"storage_visible":ui.storage_panel.visible,
  "storage_money_visible":ui.storage_money_panel.visible,
  "storage_money_mode":ui.storage_money_mode,
  "storage_items_tab":bounds(ui.storage_item_view_button),
  "storage_money_tab":bounds(ui.storage_money_view_button),
  "storage_currency":store.storage_currency,"storage_money_kind":ui.storage_money_kind,
  "storage_money_rows":buttons([ui.storage_money_currency_buttons["gold"],ui.storage_money_currency_buttons["blue"],ui.storage_money_currency_buttons["purple"],ui.storage_money_currency_buttons["green"]]),
  "storage_money_wallet_text":ui.storage_money_wallet_labels["gold"].text,
  "storage_money_vault_text":ui.storage_money_vault_labels["gold"].text,
  "storage_money_amount":bounds(ui.storage_money_amount_input),
  "storage_money_value":ui.storage_money_amount_input.text,
  "storage_money_deposit":bounds(ui.storage_money_deposit_button),
  "storage_money_withdraw":bounds(ui.storage_money_withdraw_button),
  "storage_money_deposit_disabled":ui.storage_money_deposit_button.disabled,
  "storage_money_withdraw_disabled":ui.storage_money_withdraw_button.disabled,
  "storage_money_all_wallet":bounds(ui.storage_money_panel.get_node("AllWalletMoney")),
  "storage_money_all_vault":bounds(ui.storage_money_panel.get_node("AllVaultMoney")),
  "storage_money_notice":ui.storage_money_notice.text,
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
  "shop_visible":ui.shop_panel.visible,"shop_left_inventory":ui.bag_panel.visible,
  "shop_left_border":ui.stage.get_children().any(func(n): return n is NinePatchRect and n.name=="RedMattePanel_inner_panel"),
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

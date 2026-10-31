extends SceneTree
var failures: Array[String] = []
var checks := 0
var backup: PackedByteArray
var had_save := false
func _initialize() -> void:
 call_deferred("validate")
func check(value: bool, message: String) -> void:
 checks += 1
 if not value: failures.append(message)
func click(button: Control) -> void:
 var pos := button.get_global_rect().get_center()
 var motion := InputEventMouseMotion.new()
 motion.position = pos
 root.push_input(motion)
 await process_frame
 for pressed in [true,false]:
  var event := InputEventMouseButton.new()
  event.button_index = MOUSE_BUTTON_LEFT
  event.pressed = pressed
  event.position = pos
  root.push_input(event)
 await process_frame
func validate() -> void:
 root.size = Vector2i(1440,1100)
 root.content_scale_size = Vector2i.ZERO
 had_save = FileAccess.file_exists("user://leoonline.json")
 if had_save: backup = FileAccess.get_file_as_bytes("user://leoonline.json")
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 var ui = game.inventory
 var store = game.store
 store.slots.fill("")
 store.unlocked = 40
 store.selected = -1
 for key in store.equipped: store.equipped[key] = ""
 game._toggle()
 ui.refresh()
 await process_frame
 check(ui.visible,"Bag opens")
 check(store.slots.size()==200,"200 storage entries")
 check(ui.bag_grid.columns==10 and ui.bag_grid.get_child_count()==50,"10 by 5 grid")
 for row in [ui.main_equip_list,ui.extra_equip_list,ui.fashion_weapon_row,ui.fashion_side_row,ui.accessory_row,ui.fashion_row]:
  for button in row.get_children():
   check(button is TextureButton,"Equipment uses PNG button")
   check(button.get_child_count()==0,"Empty equipment has no fake item icons or text")
 check(ui.main_equip_list.get_child_count()==5,"Five body slots")
 check(ui.extra_equip_list.get_child_count()==4,"Two weapons, pet, mount")
 check(ui.fashion_row.get_child_count()==5,"Exactly five fashion slots")
 check(ui.fashion_weapon_row.get_child_count()+ui.fashion_side_row.get_child_count()==4,"Four fashion weapon/mask/cape slots")
 check(ui.accessory_row.get_child_count()==5,"Five accessory slots")
 var locked := 0
 for button in ui.bag_grid.get_children():
  if button.get_meta("locked"): locked+=1
  check(button.size.x==button.size.y,"Bag cell is square")
  check(button.texture_normal!=null,"Every slot has a background without baked base slots")
 check(locked==10,"Only last ten slots initially locked")
 for page in range(1,4):
  ui._change_page(page)
  for button in ui.bag_grid.get_children(): check(button.get_meta("locked"),"Later page locked")
 ui._change_page(0)
 await process_frame
 for language in ["th","en"]:
  ui.set_language(language)
  check(ui.tab_buttons[0].text==("กระเป๋า" if language=="th" else "Inventory"),"Tabs translated")
  ui._show_details("sword")
  check(ui.detail_heading.text==("ดาบสำริด" if language=="th" else "Bronze Sword"),"Existing item translated")
  check(not ui.detail_description.text.contains("Attack"),"No fabricated stats")
  ui._hide_details()
 ui.set_language("th")
 check(ui.ui_font.has_char(0x0e01),"Thai glyph exists")
 await click(ui.footer_buttons[0])
 check(store.slots.count("sword")==1,"Demo button routed through viewport")
 ui._pick_item(0)
 ui._pick_item(1)
 check(store.slots[0]=="sword" and store.slots[1]=="shirt","Inspect does not swap items")
 ui._pick_item(0)
 await click(ui.footer_buttons[4])
 check(store.equipped.weapon_right=="sword","Equip button works")
 var right = ui.extra_equip_list.get_child(0)
 await click(right)
 check(ui.detail_panel.visible,"Tap equipment shows details")
 check(store.equipped.weapon_right=="sword","Inspection does not unequip")
 await click(ui.footer_buttons[4])
 check(store.equipped.weapon_right=="","Unequip button works")
 check(store.slots.has("sword"),"Unequipped item returned")
 ui.selected_equipment=""
 ui._pick_item(store.slots.find("wood"))
 await click(ui.footer_buttons[3])
 check(ui.trash_dialog.visible,"Trash asks for confirmation")
 ui.trash_dialog.hide()
 check(store.slots.has("wood"),"Cancel retains item")
 ui._request_trash()
 ui.trash_dialog.confirmed.emit()
 ui.trash_dialog.hide()
 check(not store.slots.has("wood"),"Confirmed trash removes intended item")
 await click(ui.footer_buttons[2])
 check(store.slots[0]=="sword","Sort weapons before armor")
 store.add_currency("gold",store.MAX_MONEY)
 store.add_currency("gold","1")
 check(store.currency.gold==store.MAX_MONEY,"21 digit cap exact")
 await click(ui.footer_buttons[1])
 check(ui.notice_text.text=="บันทึกแล้ว","Save reports success")
 var saved_slots = store.slots.duplicate()
 store.slots.fill("")
 store.currency.gold="0"
 store.load_data()
 check(store.slots==saved_slots and store.currency.gold==store.MAX_MONEY,"Save/load preserves inventory and exact currency")
 store.unlock_ten()
 ui.refresh()
 for button in ui.bag_grid.get_children(): check(not button.get_meta("locked"),"Unlock removes all first-page locks")
 ui._show_details("fashion_cape")
 await process_frame
 var popup: Rect2 = ui.detail_panel.get_global_rect()
 for row in [ui.bag_grid,ui.main_equip_list,ui.extra_equip_list,ui.fashion_weapon_row,ui.fashion_side_row,ui.accessory_row,ui.fashion_row]:
  for button in row.get_children(): check(not popup.intersects(button.get_global_rect()),"Details never cover a slot")
 ui._switch_tab(2)
 check(ui.waiting_panel.visible and ui.waiting_text.text.contains("ยังไม่"),"Skill unavailable truthfully")
 ui._switch_tab(3)
 check(ui.waiting_panel.visible and not ui.bag_panel.visible,"Shop unavailable truthfully")
 ui._switch_tab(0)
 ui._show_details("sword")
 for viewport_size in [Vector2i(390,844),Vector2i(844,390)]:
  root.size = viewport_size
  await process_frame
  await process_frame
  ui._pick_item(0)
  await process_frame
  await process_frame
  var bounds := Rect2(Vector2.ZERO,Vector2(viewport_size))
  check(bounds.encloses(ui.detail_panel.get_global_rect()),"Mobile details stay inside viewport")
  check(ui.scroller.get_global_rect().end.y <= ui.detail_panel.get_global_rect().position.y+1,"Mobile details reserve space instead of covering slots")
  check(ui.bag_grid.get_child(0).get_global_rect().size.x >= 44,"Mobile targets at least 44 pixels")
  ui._hide_details()
 root.size = Vector2i(1440,1100)
 await process_frame
 await process_frame
 ui.scroller.scroll_horizontal=0
 ui.scroller.scroll_vertical=0
 await process_frame
 await click(ui.footer_buttons[5])
 check(not ui.visible and not ui.detail_panel.visible,"Close hides details too")
 if had_save:
  var file = FileAccess.open("user://leoonline.json",FileAccess.WRITE)
  file.store_buffer(backup)
  file.close()
 else:
  DirAccess.remove_absolute(ProjectSettings.globalize_path("user://leoonline.json"))
 for failure in failures: push_error(failure)
 print("LEOONLINE QA: ",checks," checks, ",failures.size()," failures")
 quit(0 if failures.is_empty() else 1)

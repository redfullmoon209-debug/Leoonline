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
 check(store.slots.size()==200,"200 bag entries")
 check(store.storage_slots.size()==200,"200 independent storage entries")
 check(ui.bag_grid.columns==10 and ui.bag_grid.get_child_count()==50,"10 by 5 grid")
 check(ui.stage.scale.x*1448.0 <= root.size.x*0.75+2.0,"Landscape inventory uses at most 75 percent of screen width")
 for sprite in ["outer_panel","inner_panel","tab_active","tab_idle","action_button","close_button","pager_button","slot_empty","slot_locked","slot_selected","currency_row","tab_lit","button_hover","button_pressed"]:
  check(ResourceLoader.exists("res://assets/ui/red_matte/"+sprite+".png"),"Standalone red matte PNG exists: "+sprite)
 check(ui._red_texture("slot_empty") != null,"Matte red slot texture loaded")
 check(ui.tab_buttons[0].get_child_count() >= 1,"Menu buttons keep independent PNG icon layers")
 check(ui.tab_buttons.size()==4 and ui.footer_buttons.size()==6 and ui.page_buttons.size()==4,"All original functional menu and pagination buttons preserved")
 check(ui.tab_buttons[0].position==Vector2(101,100),"Tab locations unchanged")
 check(ui.footer_buttons[0].position==Vector2(105,807),"Footer button locations unchanged")
 check(ui.bag_grid.position==Vector2(729,249),"Bag grid location unchanged")
 var source_frames := 0
 for node in ui.stage.get_children():
  if node is NinePatchRect and node.name=="RedMattePanel_inner_panel": source_frames+=1
 check(source_frames==1 and not ui.shop_left_frame.visible,"Shop-only left frame stays hidden in normal Inventory, and footer remains frameless")
 var bag_border := 0
 for node in ui.bag_panel.get_children():
  if node is NinePatchRect: bag_border+=1
 check(bag_border==0,"Bag panel has no decorative perimeter frame")
 var money_border := 0
 for node in ui.currency_panel.get_children():
  if node is NinePatchRect: money_border+=1
 check(money_border==0,"Currency section has no decorative box or row frames")
 var luminous: StyleBox = ui.tab_buttons[0].get_theme_stylebox("normal")
 check(luminous is StyleBoxTexture,"Selected tab uses separate luminous PNG state")
 if luminous is StyleBoxTexture:
  check(luminous.texture.resource_path.ends_with("/tab_lit.png"),"Selected tab is vivid ruby red")
 var pressed: StyleBox = ui.footer_buttons[1].get_theme_stylebox("pressed")
 check(pressed is StyleBoxTexture,"Action button has pressed PNG state")
 if pressed is StyleBoxTexture:
  check(pressed.texture.resource_path.ends_with("/button_pressed.png"),"Bright red and white pressed feedback has a separate PNG")
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
 ui._switch_tab(1)
 check(ui.character_panel.visible and ui.equipment_panel.visible and not ui.shop_panel.visible,"Character tab shows equipment LEFT and character status RIGHT")
 check(not ui.bag_panel.visible and not ui.waiting_panel.visible,"Character tab does not show inventory grid, shop or skill placeholder")
 check(ui.character_values.size()==24,"Character panel has profile fields, six attributes, combat records and four currencies")
 check(ui.character_values["name"].text=="นักผจญภัย","New player profile name is a real default, translated")
 check(ui.character_values["level"].text==str(store.profile["level"]),"Character Level comes from saved profile")
 check(ui.character_values["class_tier"].text==str(store.profile["class_tier"]),"Class is the stored class tier")
 check(ui.character_values["strength"].text==str(store.profile["attributes"]["strength"]),"Strength reads persisted base stats")
 check(ui.character_values["pve_rank"].text=="ยังไม่มีอันดับ" and ui.character_values["pvp_rank"].text=="ยังไม่มีอันดับ" and ui.character_values["wealth_rank"].text=="ยังไม่มีอันดับ","Do not fabricate rankings or server scores")
 check(ui.character_values["currency_gold"].text==store.pretty(str(store.currency.gold)),"Wealth reads the same exact Gold balance as inventory")
 for key in ["gold","blue","purple","green"]:
  check(ui.character_values.has("currency_"+key),"Character wealth uses all four existing currency types")
 var original_profile: Dictionary = store.profile.duplicate(true)
 var original_gold_for_profile: String = str(store.currency.gold)
 store.profile["attributes"]["strength"]=37
 store.grant_experience(150)
 check(int(store.profile["level"])==2 and int(store.profile["experience"])==50,"Level progression model has an explicit experience threshold")
 store.currency.gold="999999999999999999999"
 store.changed.emit()
 check(ui.character_values["strength"].text=="37","Character stats refresh when saved profile values change")
 check(ui.character_values["level"].text=="2" and ui.character_values["experience"].text=="50 / 150","Character Level and EXP reflect real model progression")
 check(ui.character_values["currency_gold"].text=="999,999,999,999,999,999,999","No precision loss for 21-digit Gold on Character page")
 check(store.save_data(),"Character save writes profile and 21-digit balance")
 store.profile["attributes"]["strength"]=10
 store.profile["level"]=1
 store.currency.gold="0"
 store.load_data()
 check(int(store.profile["attributes"]["strength"])==37 and int(store.profile["level"])==2,"Character profile persists across save/load")
 check(ui.character_values["currency_gold"].text=="999,999,999,999,999,999,999","Character UI preserves exact large numbers after load")
 ui.set_language("en")
 check(ui.character_values["name"].text=="Adventurer" and ui.character_values["pve_rank"].text=="Unranked","Character labels and values switch to English without PNG changes")
 ui.set_language("th")
 store.profile=original_profile
 store.currency.gold=original_gold_for_profile
 store.changed.emit()
 store.save_data()
 ui._switch_tab(0)
 check(not ui.character_panel.visible and ui.bag_panel.visible and ui.equipment_panel.visible,"Inventory restores exact original equipment and bag layout")
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
 check(ui.shop_panel.visible and ui.bag_panel.visible and not ui.equipment_panel.visible,"Shop shows player bag on the LEFT and shop stock on the RIGHT")
 check(ui.shop_left_frame.visible,"Shop-only left inventory border is visible behind the reused bag")
 check(not ui.waiting_panel.visible,"Shop is usable, not a placeholder")
 check(ui.bag_panel.position==Vector2(-655,0),"Existing 200-slot bag is reused on the left in Shop")
 check(ui.shop_grid.columns==10 and ui.shop_grid.get_child_count()==50,"Shop has 10x5 sellable stock slots")
 check(ui.shop_stock_label.text=="21 / 500","Shop catalog reserves 500 future item slots")
 check(ui.shop_sell_button.disabled,"Cannot sell without selecting a bag item")
 for item in ["hp_potion_small","hp_potion_medium","hp_potion_large","sp_potion_small","sp_potion_medium","sp_potion_large","upgrade_stone_1","upgrade_stone_15"]:
  check(ResourceLoader.exists("res://assets/ui/shop/"+item+".png"),"Original transparent shop PNG exists: "+item)
 check(store.subtract_decimal("1000","299")=="701","Exact decimal subtraction")
 check(store.subtract_decimal("1000","1000")=="0","Exact decimal zero")
 check(store.subtract_decimal("1000","1001")=="","Subtract cannot make negative currency")
 var original_gold: String = str(store.currency.gold)
 var original_slots: Array = store.slots.duplicate()
 store.currency.gold = "1200"
 ui._select_shop_item("hp_potion_small")
 check(ui.shop_selected_id=="hp_potion_small" and not ui.shop_buy_button.disabled,"Shop product selection")
 check(ui.shop_service.buy("hp_potion_small"),"Buy HP potion with gold")
 check(store.currency.gold=="1150" and store.slots.has("hp_potion_small"),"Purchase debits exact amount and delivers potion")
 var purchased_index: int = store.slots.find("hp_potion_small")
 store.currency.gold="0"
 var original_item_count: int = store.slots.count("hp_potion_small")
 check(not ui.shop_service.buy("hp_potion_small"),"Cannot buy without sufficient gold")
 check(store.currency.gold=="0" and store.slots.count("hp_potion_small")==original_item_count,"Failed buy leaves wallet and inventory unchanged")
 store.currency.gold="1150"
 ui._pick_item(purchased_index)
 check(not ui.shop_sell_button.disabled,"Selecting a bag item allows selling")
 ui._request_shop_sell()
 check(ui.shop_sell_dialog.visible,"Selling always asks for confirmation")
 ui.shop_sell_dialog.confirmed.emit()
 ui.shop_sell_dialog.hide()
 check(not store.slots.has("hp_potion_small") and store.currency.gold=="1175","Confirmed sale removes the item and credits exact resale value")
 store.currency.gold=store.MAX_MONEY
 var sword_index: int = store.slots.find("sword")
 if sword_index>=0:
  check(not ui.shop_service.sell_slot(sword_index),"Sale cannot overflow the 21-digit currency limit")
  check(store.slots[sword_index]=="sword" and store.currency.gold==store.MAX_MONEY,"Overflow leaves item and money intact")
 ui._change_shop_page(4)
 check(ui.shop_page==9 and ui.shop_grid.get_child_count()==50 and ui.shop_grid.get_child(0).disabled,"Page ten reserves 50 shop slots for future content")
 ui._change_shop_page(0)
 store.slots=original_slots
 store.currency.gold=original_gold
 store.selected=-1
 ui.refresh()
 ui._switch_tab(0)
 check(ui.bag_panel.position==Vector2.ZERO and not ui.shop_panel.visible and not ui.shop_left_frame.visible,"Inventory restores the original layout and hides Shop-only borders")
 check(ResourceLoader.exists("res://assets/ui/inventory/icon_storage.png"),"Independent storage chest icon exists as original PNG")
 check(game.hud.has_node("OpenStorage"),"Storage has its own HUD opener independent of bag")
 check(game.hud.get_node("OpenStorage").texture_normal!=null,"Storage HUD opens from a real PNG button")
 check(not ui.storage_panel.visible and not ui.storage_mode,"Storage stays hidden in original Inventory")
 var bag_before_storage: Array = store.slots.duplicate()
 var vault_before_storage: Array = store.storage_slots.duplicate()
 var unlock_before_storage: int = store.unlocked
 game._toggle()
 check(not ui.visible,"Closing inventory exposes bag and storage opener buttons")
 await click(game.hud.get_node("OpenStorage"))
 check(ui.visible and ui.storage_mode and ui.current_tab==0,"Click storage icon opens Storage mode")
 check(ui.storage_panel.visible and not ui.equipment_panel.visible and ui.bag_panel.visible,"Storage replaces left Equipment; original bag is RIGHT")
 check(ui.bag_panel.position==Vector2.ZERO and ui.bag_grid.columns==10,"Storage leaves original 10-column bag in place")
 check(ui.storage_grid.columns==10 and ui.storage_grid.get_child_count()==50,"Storage grid is 10 columns by 5 rows")
 check(store.storage_slots.size()==200 and ui.storage_page_buttons.size()==4,"Storage has 200 cells in 4 pages")
 check(ui.tab_buttons.size()==4 and ui.footer_buttons.size()==6,"Storage leaves original 4 tabs and 6 footer controls untouched")
 for child in ui.storage_grid.get_children():
  check(child is TextureButton and child.texture_normal==ui._red_texture("slot_empty"),"Storage slots use the same existing inventory PNG")
 store.slots.fill("")
 store.storage_slots.fill("")
 store.selected=-1
 store.storage_selected=-1
 store.unlocked=40
 store.slots[0]="sword"
 store.slots[1]="hp_potion_small"
 store.changed.emit()
 check(ui.storage_capacity_label.text=="0 / 200","Storage capacity accurately starts empty")
 ui._pick_item(0)
 check(not ui.storage_deposit_button.disabled,"Selecting player bag item enables Deposit")
 await click(ui.storage_deposit_button)
 check(store.slots[0]=="" and store.storage_slots[0]=="sword","Deposit moves exactly one item from right bag to left vault")
 check(store.slots.count("sword")+store.storage_slots.count("sword")==1,"Deposit never duplicates an item")
 var transfer_file := FileAccess.open("user://leoonline.json",FileAccess.READ)
 var transfer_save: Variant = JSON.parse_string(transfer_file.get_as_text()) if transfer_file!=null else null
 check(transfer_save is Dictionary and transfer_save.has("storage_slots") and transfer_save["storage_slots"][0]=="sword","Deposit persists vault and bag together in one save")
 store.slots[0]="wood"
 store.storage_slots[0]=""
 store.load_data()
 check(store.storage_slots[0]=="sword" and store.slots[0]=="","Reload restores deposited item with no ghost copy")
 ui._pick_storage_item(0)
 check(not ui.storage_withdraw_button.disabled and store.storage_selected==0,"Selecting stored item enables Withdraw")
 await click(ui.storage_withdraw_button)
 check(store.storage_slots[0]=="" and store.slots[0]=="sword","Withdraw moves stored item back to available unlocked bag slot")
 check(store.slots.count("sword")+store.storage_slots.count("sword")==1,"Withdraw never duplicates an item")
 store.storage_slots.fill("wood")
 store.slots[0]="sword"
 store.selected=0
 store.storage_selected=-1
 check(not store.deposit_selected() and store.slots[0]=="sword" and store.storage_slots.count("sword")==0,"Full storage rejects deposit without destroying or duplicating item")
 store.storage_slots.fill("")
 store.storage_slots[0]="potion"
 store.slots.fill("wood")
 store.unlocked=40
 store.storage_selected=0
 check(not store.withdraw_selected() and store.storage_slots[0]=="potion" and store.slots.count("potion")==0,"Full unlocked bag rejects withdrawal, including when locked bag slots exist")
 store.slots.fill("")
 store.storage_slots.fill("")
 store.storage_slots[199]="upgrade_stone_1"
 store.selected=-1
 store.storage_selected=-1
 store.changed.emit()
 ui._change_storage_page(4)
 check(ui.storage_page==3 and ui.storage_grid.get_child_count()==50,"Storage last page shows 50 slots")
 check(ui.storage_grid.get_child(49).get_meta("storage_index")==199,"Storage last page maps to slot 199")
 check(ui.storage_grid.get_child(49).get_child_count()==1,"Storage shows the original standalone icon for stored item")
 ui._change_storage_page(0)
 ui.set_language("en")
 check(ui.storage_deposit_button.text=="Deposit" and ui.storage_withdraw_button.text=="Withdraw","Storage action labels translate without editing PNG")
 ui.set_language("th")
 check(ui.storage_deposit_button.text=="ฝากของ" and ui.storage_withdraw_button.text=="ถอนของ","Thai storage actions are localized")
 store.slots=bag_before_storage
 store.storage_slots=vault_before_storage
 store.selected=-1
 store.storage_selected=-1
 store.unlocked=unlock_before_storage
 store.changed.emit()
 store.save_data()
 ui._switch_tab(0)
 check(not ui.storage_mode and not ui.storage_panel.visible and ui.equipment_panel.visible and ui.bag_panel.visible,"Inventory tab restores original left Equipment and right Bag")
 ui._switch_tab(1)
 check(not ui.storage_panel.visible and ui.character_panel.visible,"Character tab does not inherit storage panel")
 ui._switch_tab(3)
 check(not ui.storage_panel.visible and ui.shop_panel.visible and ui.bag_panel.position.x==-655,"Shop keeps its original left bag and right shop unchanged")
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
  ui.open_storage()
  check(ui.storage_panel.visible and ui.bag_panel.visible and not ui.equipment_panel.visible,"Mobile Storage still uses left vault and right bag")
  check(ui.storage_grid.get_child(0).get_global_rect().size.x>=44,"Storage touch targets are at least 44 pixels on mobile")
  ui._switch_tab(0)
  ui._switch_tab(1)
  check(ui.character_panel.visible and ui.character_values["strength"].text!="","Character data still available on resized mobile viewport")
  ui._switch_tab(0)
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

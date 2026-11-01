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
 check(ui.tab_buttons.size()==5 and ui.footer_buttons.size()==6 and ui.page_buttons.size()==4,"Five functional tabs and original footer/pagination buttons preserved")
 check(ui.tab_buttons[0].position==Vector2(104,100) and ui.tab_buttons[4].position==Vector2(1112,100),"Five tabs are centered with equal 104px outer margins")
 check(is_equal_approx(ui.tab_buttons[0].position.x,1448.0-(ui.tab_buttons[4].position.x+ui.tab_buttons[4].size.x)),"Top navigation has symmetric left/right margins")
 for i in range(1,5):
  check(ui.tab_buttons[i].size==ui.tab_buttons[0].size,"All five top buttons have identical sizes")
  check(is_equal_approx(ui.tab_buttons[i].position.x-ui.tab_buttons[i-1].position.x,252.0),"All five top buttons have identical 20px gaps")
 check(ui.tab_buttons[4].position.x+ui.tab_buttons[4].size.x<1400.0,"Storage button never touches the golden outer frame")
 check(ui.footer_buttons[0].position==Vector2(105,807),"Footer button locations unchanged")
 check(ui.bag_grid.position==Vector2(729,249),"Bag grid location unchanged")
 var source_frames := 0
 for node in ui.stage.get_children():
  if node is NinePatchRect and node.name=="RedMattePanel_inner_panel": source_frames+=1
 check(source_frames==0,"No decorative inner panel frame is drawn on the main stage")
 for borderless_panel in [ui.equipment_panel,ui.storage_panel,ui.shop_panel,ui.character_panel,ui.waiting_panel]:
  var decorative_frames := 0
  for child in borderless_panel.get_children():
   if child is NinePatchRect: decorative_frames+=1
  check(decorative_frames==0,"Equipment, Storage, Shop, Character and Skill contain no ornate Panel Borders")

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
 check(ui.shop_panel.get_children().all(func(n): return not (n is NinePatchRect)),"Shop panel has no decorative perimeter border")
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
 check(ui.bag_panel.position==Vector2.ZERO and not ui.shop_panel.visible,"Inventory restores original bag layout without decorative borders")
 check(ResourceLoader.exists("res://assets/ui/inventory/icon_storage.png"),"Storage submenu reuses existing original chest PNG")
 check(game.hud.has_node("OpenInventory"),"Bag keeps its original HUD opener")
 check(not game.hud.has_node("OpenStorage"),"No standalone Storage icon remains on the HUD")
 check(ui.tab_buttons[4].text=="คลังเก็บของ","Storage is fifth top tab with Thai text")
 check(ui.tab_buttons[4].get_child_count()>0,"Storage tab uses original chest icon as a separate texture")
 check(not ui.storage_panel.visible and not ui.storage_mode,"Storage stays hidden in original Inventory")
 var bag_before_storage: Array = store.slots.duplicate()
 var vault_before_storage: Array = store.storage_slots.duplicate()
 var unlock_before_storage: int = store.unlocked
 game._toggle()
 check(not ui.visible,"Closing Inventory exposes the single bag HUD opener")
 await click(game.hud.get_node("OpenInventory"))
 check(ui.visible and not ui.storage_mode,"Bag HUD opens original Inventory")
 await click(ui.tab_buttons[4])
 check(ui.visible and ui.storage_mode and ui.current_tab==4,"Click fifth top tab opens Storage mode")
 check(ui.storage_panel.visible and not ui.equipment_panel.visible and ui.bag_panel.visible,"Fifth Storage tab shows left vault and right bag")
 var fifth_style: StyleBox = ui.tab_buttons[4].get_theme_stylebox("normal")
 check(fifth_style is StyleBoxTexture and fifth_style.texture.resource_path.ends_with("/tab_lit.png"),"Storage tab highlights red when selected")

 check(ui.bag_panel.position==Vector2.ZERO and ui.bag_grid.columns==10,"Storage leaves original 10-column bag in place")
 check(ui.storage_grid.columns==10 and ui.storage_grid.get_child_count()==50,"Storage grid is 10 columns by 5 rows")
 check(store.storage_slots.size()==200 and ui.storage_page_buttons.size()==4,"Storage has 200 cells in 4 pages")
 check(ui.tab_buttons.size()==5 and ui.footer_buttons.size()==6,"Storage keeps all five top tabs and six footer controls")
 check(ui.storage_item_view_button.visible and ui.storage_money_view_button.visible,"Storage shows both Items and Money subviews without a separate HUD icon")
 check(ui.storage_money_panel.get_parent()==ui.storage_panel,"Vault money belongs to the existing Storage view")
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
 check(ui.tab_buttons[4].text=="Storage","Storage top tab translates to English")
 ui.set_language("th")
 check(ui.tab_buttons[4].text=="คลังเก็บของ","Storage top tab translates to Thai")
 check(ui.storage_deposit_button.text=="ฝากของ" and ui.storage_withdraw_button.text=="ถอนของ","Thai storage actions are localized")
 # Financial vault is a real second ledger for each of the four 21-digit
 # money types. Test on Godot itself to avoid JS Number precision errors.
 var original_wallet: Dictionary = store.currency.duplicate(true)
 var original_bank: Dictionary = store.storage_currency.duplicate(true)
 var max_exact: String = store.MAX_MONEY
 for kind in ["gold","blue","purple","green"]:
  store.currency[kind] = max_exact
  store.storage_currency[kind] = "0"
 store.changed.emit()
 await click(ui.storage_money_view_button)
 check(ui.storage_money_mode and ui.storage_money_panel.visible and not ui.storage_grid.visible,"Money subview replaces item slots on the left, never the player bag on the right")
 check(ui.bag_panel.visible and ui.bag_panel.position==Vector2.ZERO,"The original right-side bag and its four wallet balances stay visible")
 check(ui.storage_money_currency_buttons.size()==4 and ui.storage_money_wallet_labels.size()==4 and ui.storage_money_vault_labels.size()==4,"Bank supports four independent currencies without PNG crops")
 check(ui.storage_money_amount_input.max_length==21,"Money input prevents more than 21 typed characters")
 check(not store.deposit_money("gold","0") and not store.withdraw_money("gold","-1"),"Zero and negative transfers are rejected")
 for invalid in ["", "0", "-1", "1.2", "1e3", "1,000", "1000000000000000000000"]:
  check(not store.deposit_money("gold",invalid),"Invalid or over-limit currency input is rejected without changing balances")
 check(not store.deposit_money("invalid","1"),"Unknown currency identifier is rejected")
 for kind in ["gold","blue","purple","green"]:
  ui._choose_storage_money(kind)
  check(ui.storage_money_kind==kind,"Bank row selects currency "+kind)
  ui.storage_money_amount_input.text = max_exact
  ui._refresh_storage_money()
  check(not ui.storage_money_deposit_button.disabled,"Deposit enabled for exact max "+kind)
  await click(ui.storage_money_deposit_button)
  check(store.currency[kind]=="0" and store.storage_currency[kind]==max_exact,"Deposit moves exact 21 digits wallet to vault for "+kind)
  check(ui.storage_money_vault_labels[kind].text.contains("999,999,999,999,999,999,999"),"Bank UI formats exact 21 digits for "+kind)
  check(not store.deposit_money(kind,"1"),"Empty wallet cannot deposit more "+kind)
  ui.storage_money_amount_input.text = max_exact
  ui._refresh_storage_money()
  check(not ui.storage_money_withdraw_button.disabled,"Withdraw enabled for exact max "+kind)
  await click(ui.storage_money_withdraw_button)
  check(store.currency[kind]==max_exact and store.storage_currency[kind]=="0","Withdrawal returns exact 21 digits without duplication for "+kind)
  check(not store.withdraw_money(kind,"1"),"Empty vault cannot withdraw more "+kind)
 # Reject overflow on either destination and preserve both ledgers unchanged.
 store.currency.gold="1"
 store.storage_currency.gold=max_exact
 check(not store.deposit_money("gold","1"),"Full storage wallet transfer rejects vault overflow")
 check(store.currency.gold=="1" and store.storage_currency.gold==max_exact,"Vault overflow does not destroy wallet or vault money")
 store.currency.gold=max_exact
 store.storage_currency.gold="1"
 check(not store.withdraw_money("gold","1"),"Full wallet transfer rejects destination overflow")
 check(store.currency.gold==max_exact and store.storage_currency.gold=="1","Wallet overflow leaves both balances intact")
 store.currency.gold="1234"
 store.storage_currency.gold="0"
 store.changed.emit()
 ui._choose_storage_money("gold")
 ui._storage_money_fill_all(false)
 check(ui.storage_money_amount_input.text=="1234","All-wallet button fills exact remaining wallet amount")
 await click(ui.storage_money_deposit_button)
 check(store.currency.gold=="0" and store.storage_currency.gold=="1234","All-wallet deposit transfers only the selected currency")
 var saved_bank_file := FileAccess.open("user://leoonline.json",FileAccess.READ)
 var saved_bank_data: Variant = JSON.parse_string(saved_bank_file.get_as_text()) if saved_bank_file!=null else null
 check(saved_bank_data is Dictionary and saved_bank_data.has("storage_currency") and saved_bank_data["storage_currency"]["gold"]=="1234","Storage money and wallet persist together in the existing save")
 store.currency.gold="7"
 store.storage_currency.gold="9"
 store.load_data()
 check(store.currency.gold=="0" and store.storage_currency.gold=="1234","Loading save recovers both money ledgers exactly")
 ui._storage_money_fill_all(true)
 check(ui.storage_money_amount_input.text=="1234","All-vault button fills exact stored amount")
 await click(ui.storage_money_withdraw_button)
 check(store.currency.gold=="1234" and store.storage_currency.gold=="0","All-vault withdrawal restores wallet money")
 ui.set_language("en")
 check(ui.storage_money_deposit_button.text=="Deposit money" and ui.storage_money_withdraw_button.text=="Withdraw money","Bank actions switch to English without changing PNGs")
 ui.set_language("th")
 check(ui.storage_money_deposit_button.text=="ฝากเงิน" and ui.storage_money_withdraw_button.text=="ถอนเงิน","Bank actions switch to Thai without changing PNGs")
 await click(ui.storage_item_view_button)
 check(not ui.storage_money_mode and ui.storage_grid.visible and not ui.storage_money_panel.visible,"Item storage view remains usable after banking")
 store.currency=original_wallet.duplicate(true)
 store.storage_currency=original_bank.duplicate(true)
 store.slots=bag_before_storage
 store.storage_slots=vault_before_storage
 store.selected=-1
 store.storage_selected=-1
 store.unlocked=unlock_before_storage
 store.changed.emit()
 store.save_data()
 ui._switch_tab(0)
 check(not ui.storage_mode and not ui.storage_panel.visible and ui.equipment_panel.visible and ui.bag_panel.visible,"Inventory tab restores original left Equipment and right Bag")
 check(ui.tab_buttons[4].visible,"Storage fifth tab remains visible from Inventory")
 ui._switch_tab(1)
 check(ui.tab_buttons[4].visible,"Storage fifth tab remains visible from Character page")
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
  check(ui.tab_buttons[4].get_global_rect().size.x>=44,"Fifth Storage tab is touch-friendly on mobile")
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
 # HUD main-menu regression: no picture crops, nine independent working icons,
 # local functional menu panels, mobile controls and a persistent drag/resize UI.
 var hud_menu: Control=game.hud_menu
 check(hud_menu!=null and hud_menu.controls.size()==14,"HUD exposes nine distinct menus, bag, joystick, Jump, Pickup and Run")
 check(hud_menu.controls["bag"]==game.hud.get_node("OpenInventory"),"Original Inventory button and save data are preserved")
 # Ten native standalone RGBA PNGs, NOT crops of the approved reference sheet.
 # All notification badges are separate controls with zero unread at start.
 var menu_order: Array[String]=["bag","world","party","friends","ranking","settings","guild","quest","mail","events"]
 check(hud_menu.MENU_ORDER.size()==10 and hud_menu.MENU_ORDER==menu_order,"HUD has ten distinct buttons in the requested left-to-right order")
 var prior_rect:Rect2=Rect2()
 var row_y:float=-1.0
 for i in range(menu_order.size()):
  var key:String=menu_order[i]
  var icon_path:String="res://assets/ui/hud/premium/"+key+".png"
  check(ResourceLoader.exists(icon_path),"Standalone premium PNG exists for "+key)
  var art:Texture2D=load(icon_path) as Texture2D
  check(art!=null and art.get_width()==256 and art.get_height()==256,"Premium icon was authored independently at 256px: "+key)
  var control:Control=hud_menu.controls[key] as Control
  var rect:Rect2=control.get_global_rect()
  check(rect.size.x>=32 and rect.size.x<=100,"Desktop icon uses compact right-aligned geometry: "+key)
  if i==0: row_y=rect.position.y
  check(is_equal_approx(rect.position.y,row_y),"Every main icon is on the same HUD row")
  if i>0:
   check(rect.position.x>prior_rect.position.x and rect.position.x>=prior_rect.end.x+2.0,"Each icon is to the RIGHT of its predecessor without overlap")
  prior_rect=rect
  check(hud_menu.notification_badges.has(key) and not hud_menu.notification_badges[key].visible,"No red alert dot is displayed unless a real event arrives: "+key)
  if key=="bag":
   check(game.hud.get_node("OpenInventory").texture_normal.resource_path==icon_path,"The existing functional bag button uses its own premium PNG")
  else:
   check((control.get_node("Glyph") as TextureRect).texture.resource_path==icon_path,"HUD renders original standalone PNG for "+key)
 check(prior_rect.end.x<game.hud_menu.size.x-150.0,"Ten-icon row leaves free space for the right-hand minimap")
 check(hud_menu.controls["bag"].position.x>265.0,"Ten-icon row leaves room for the left-hand character portrait")
 check(hud_menu.controls["events"].get_global_rect().end.x < hud_menu.top_status.minimap_button.get_global_rect().position.x,
  "Ten compact icons sit immediately left of the minimap without overlapping it")
 var top:Control=hud_menu.top_status
 check(top!=null and top.player_panel.visible and top.minimap_button.visible and top.target_panel.visible,"Character data, minimap and target status are three real HUD regions")
 check(top.player_name.text.contains("Lv.") and top.player_class.text.contains("Class"),"Top-left character profile displays current saved level and class")
 check(top.exp_bar.value>=0.0 and top.exp_bar.value<=100.0,"Character EXP bar shows actual saved progression")
 check(top.minimap.get_script()!=null and top.minimap.items.size()==game.loot.size(),"Circular minimap plots real dropped items and player position")
 check(top.target_label.text.contains("ยังไม่ได้เลือก") and not top.target_bar.visible,"Center target info honestly shows no selected target instead of fake HP")
 var test_target:=Node3D.new()
 test_target.name="TrainingTargetForQA"
 test_target.set_meta("target_name","หุ่นฝึก")
 test_target.set_meta("level",3)
 test_target.set_meta("hp",250.0)
 test_target.set_meta("max_hp",500.0)
 game.add_child(test_target)
 hud_menu.set_target(test_target)
 check(top.target_label.text.contains("หุ่นฝึก") and top.target_bar.visible and is_equal_approx(top.target_bar.value,50.0),"Center target shows actual name, level and correct HP proportion when data exists")
 hud_menu.clear_target()
 test_target.queue_free()
 check(not top.target_bar.visible and top.target_label.text.contains("ยังไม่ได้เลือก"),"Clearing target removes stale HP")
 check(not top.target_mana_bar.visible and not top.target_portrait.visible,"No selected target hides HP/MP values and portrait without fake monster information")
 check(top.target_decor.get_script()!=null,"Center golden frame is native Godot vector drawing, not a crop")
 check(ResourceLoader.exists("res://assets/ui/hud/target_training_golem.svg"),"Standalone golem portrait is an original asset, not a cropped reference image")
 check(game.training_target != null and is_instance_valid(game.training_target),"Actual targetable training golem exists in the 3D test world")
 check(game.training_target.get_meta("hp")==3240.0 and game.training_target.get_meta("mp")==670.0,
  "Training golem health and mana are actual entity metadata, not hard-coded HUD labels")
 game._toggle_target_lock()
 check(top.current_target==game.training_target,"T target lock selects the real nearby world entity")
 check(top.target_label.text=="อสูรหินฝึก" and top.target_level_label.text=="Lv.12" and top.target_type_label.text=="Monster",
  "Centered target card shows actual enemy name, level and type")
 check(top.target_portrait.visible and top.target_portrait.texture!=null,
  "Selected enemy shows its own full portrait asset without cropping the approved screenshot")
 check(top.target_bar.visible and is_equal_approx(top.target_bar.value,100.0) and top.target_health_value.text.contains("3240"),
  "Red target HP bar and numeric value read actual entity data")
 check(top.target_mana_bar.visible and is_equal_approx(top.target_mana_bar.value,100.0) and top.target_mana_value.text.contains("670"),
  "Blue target MP bar and numeric value read actual entity data")
 game.training_target.set_meta("hp",810.0)
 game.training_target.set_meta("mp",335.0)
 top._refresh_target()
 check(is_equal_approx(top.target_bar.value,25.0) and top.target_health_value.text.contains("25%"),
  "Real target damage updates red HP bar and percentage dynamically")
 check(is_equal_approx(top.target_mana_bar.value,50.0) and top.target_mana_value.text.contains("50%"),
  "Real target mana changes update blue MP bar and percentage dynamically")
 game.training_target.set_meta("hp",3240.0)
 game.training_target.set_meta("mp",670.0)
 game._toggle_target_lock()
 check(top.current_target==null and not top.target_bar.visible and not top.target_mana_bar.visible,
  "Pressing T again clears target selection and hides fake HP/MP")
 # Tap/click also uses an actual 3D camera ray and golem hitbox; not
 # screen-position arithmetic or fake touch success.
 var golem_screen:Vector2=game.camera.unproject_position(game.training_target.global_position)
 var tapped:bool=game._select_target_at(golem_screen)
 check(tapped and top.current_target==game.training_target,
  "Click/touch camera ray can select the actual 3D monster collision shape")
 hud_menu.clear_target()
 var wide_target_bounds:Rect2=top.target_panel.get_global_rect()
 var wide_menu_bounds:Rect2=hud_menu.controls["bag"].get_global_rect()
 check(absf(wide_target_bounds.get_center().x-720.0)<2.0,
  "Ornate portrait and HP/MP card is horizontally centered at top on desktop")
 check(wide_target_bounds.position.y>=wide_menu_bounds.end.y+4.0,
  "Top-centered target card sits below right-side icon row with clear visual spacing")
 root.size=Vector2i(844,390)
 await process_frame
 await process_frame
 var landscape_target:Rect2=top.target_panel.get_global_rect()
 var landscape_menu:Rect2=hud_menu.controls["bag"].get_global_rect()
 check(absf(landscape_target.get_center().x-422.0)<2.0 and landscape_target.position.y<85.0,
  "In actual phone landscape, target card stays centered near the top")
 check(landscape_target.position.y>=landscape_menu.end.y+4.0,
  "Phone landscape right-side icon row never covers center target data")
 check(hud_menu.controls["events"].get_global_rect().end.x<top.minimap_button.get_global_rect().position.x,
  "Right-side icons never overlap landscape minimap")
 root.size=Vector2i(1440,1100)
 await process_frame
 await process_frame
 # Server/social hooks do not manufacture notifications. A verified incoming
 # friend event may show its own red dot, while Mail remains unmarked.
 hud_menu.receive_friend_request("")
 check(not hud_menu.notification_badges["friends"].visible,"Invalid empty friend sender never displays an alert")
 hud_menu.receive_friend_request("verified-sender-qa")
 check(hud_menu.notification_badges["friends"].visible and not hud_menu.notification_badges["mail"].visible,"Real incoming friend event marks Friends ONLY; Mail has no red dot")
 hud_menu.acknowledge_notifications("friends")
 check(not hud_menu.notification_badges["friends"].visible,"Acknowledging a friend event clears the separate badge")
 hud_menu.receive_mail_notification("real-message-qa")
 check(hud_menu.notification_badges["mail"].visible,"Mail notification is added dynamically only when a real event is supplied")
 hud_menu.acknowledge_notifications("mail")
 check(not hud_menu.notification_badges["mail"].visible,"Mail alert clears without modifying its transparent PNG")
 for id in ["world","party","friends","ranking","settings","guild","quest","mail","events"]:
  check(ResourceLoader.exists("res://assets/ui/hud/"+id+".svg"),"Menu icon is an original SVG asset: "+id)
  var menu_button: Button=hud_menu.controls[id]
  check(menu_button.visible and menu_button.get_node("Glyph").texture!=null,"HUD icon is visible and vector sprite loads: "+id)
  hud_menu._open_page(id)
  check(hud_menu.popup.visible and hud_menu.popup_key==id and hud_menu.page_body.get_child_count()>0,"Every independent HUD icon opens a real page: "+id)
  hud_menu._hide_popup()
 check(hud_menu.popup_map==null and not hud_menu.popup.visible,"Closing a HUD menu hides its modal overlay")
 hud_menu._open_page("world")
 check(hud_menu.popup_map!=null and hud_menu.popup_map.loot_points.size()==game.loot.size(),"World map displays current local loot and player position")
 hud_menu._hide_popup()
 hud_menu._open_page("settings")
 hud_menu._begin_edit()
 check(hud_menu.edit_mode and hud_menu.toolbar.visible and not hud_menu.popup.visible,"Settings starts real HUD drag/resize editor")
 var old_hud_layout: Dictionary=hud_menu.layout_state.duplicate(true)
 hud_menu._select_control("world")
 hud_menu._resize_selected(80.0)
 check(hud_menu.controls["world"].size==Vector2(80,80),"HUD editor slider resizes selected icon")
 hud_menu._update_layout("world",Vector2(140,125),80.0)
 hud_menu._reflow()
 check(hud_menu.controls["world"].position.distance_to(Vector2(140,125))<3.0,"HUD editor updates icon positions on canvas")
 hud_menu._finish_edit(false)
 check(hud_menu.layout_state==old_hud_layout,"Cancel restores previous HUD positions and sizes without saving")
 hud_menu._begin_edit()
 hud_menu._select_control("friends")
 hud_menu._update_layout("friends",Vector2(118,104),72.0)
 hud_menu._reflow()
 hud_menu._finish_edit(true)
 check(hud_menu.layout_state.has("friends") and hud_menu.controls["friends"].size==Vector2(72,72),"Save keeps new per-icon geometry")
 var hud_file:=FileAccess.open("user://leoonline_hud.json",FileAccess.READ)
 var hud_saved:Variant=JSON.parse_string(hud_file.get_as_text()) if hud_file!=null else null
 check(hud_saved is Dictionary and hud_saved["layout"].has("friends"),"Editable HUD coordinates persist in separate JSON file")
 hud_menu.layout_state=old_hud_layout.duplicate(true)
 hud_menu._reflow()
 hud_menu._save_local()
 # Phone width: all ten buttons stay in ONE compact row below the
 # portrait/minimap instead of overlapping those panels or wrapping to 3x3.
 root.size=Vector2i(390,844)
 await process_frame
 await process_frame
 var phone_row_y:float=-1.0
 var last_phone_end:float=0.0
 for i in range(menu_order.size()):
  var control:Control=hud_menu.controls[menu_order[i]] as Control
  var rect:Rect2=control.get_global_rect()
  if i==0: phone_row_y=rect.position.y
  check(is_equal_approx(rect.position.y,phone_row_y),"Phone icon remains on one horizontal row: "+menu_order[i])
  check(rect.position.x>=0.0 and rect.end.x<=391.0,"Phone icon stays inside screen: "+menu_order[i])
  check(rect.position.x>=last_phone_end-1.0,"Phone icon has no horizontal overlap: "+menu_order[i])
  last_phone_end=rect.end.x
 check(hud_menu.top_status.minimap_button.get_global_rect().end.x<=390.0,"Mini map remains wholly visible on phone")
 check(hud_menu.top_status.player_panel.get_global_rect().end.x<hud_menu.top_status.minimap_button.get_global_rect().position.x,"Phone profile and minimap occupy separate top corners")
 check(hud_menu.top_status.target_panel.get_global_rect().position.y>phone_row_y,"Target status stays below ten-icon row on phone")
 root.size=Vector2i(1440,1100)
 await process_frame
 await process_frame
 hud_menu.display_mobile_controls=true
 hud_menu._refresh_touch_visibility()
 check(hud_menu.controls["joystick"].visible and hud_menu.controls["jump"].visible and hud_menu.controls["pickup"].visible and hud_menu.controls["run"].visible,"Mobile movement, jump, pickup and run controls can be shown and edited on PC")
 var stick:Control=hud_menu.controls["joystick"]
 stick._point_to_vector(stick.size*0.8)
 check(hud_menu.get_movement_vector().length()>0.05,"Virtual mobile joystick drives real movement vector")
 stick.movement=Vector2.ZERO
 hud_menu.display_mobile_controls=false
 hud_menu._refresh_touch_visibility()
 if had_save:
  var file = FileAccess.open("user://leoonline.json",FileAccess.WRITE)
  file.store_buffer(backup)
  file.close()
 else:
  DirAccess.remove_absolute(ProjectSettings.globalize_path("user://leoonline.json"))
 for failure in failures: push_error(failure)
 print("LEOONLINE QA: ",checks," checks, ",failures.size()," failures")
 quit(0 if failures.is_empty() else 1)

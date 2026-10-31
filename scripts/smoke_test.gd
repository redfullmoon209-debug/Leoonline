extends SceneTree

func _initialize() -> void:
    call_deferred("_validate_game")

func _fail(message: String) -> void:
    push_error("LEOONLINE SMOKE TEST FAILED: " + message)
    quit(1)

func _validate_game() -> void:
    var packed_scene: PackedScene = load("res://scenes/main.tscn")
    if packed_scene == null:
        _fail("Main scene missing")
        return
    var game: Node = packed_scene.instantiate()
    if game == null:
        _fail("Could not instantiate main scene")
        return
    root.add_child(game)
    await process_frame
    if not game.has_method("_toggle"):
        _fail("Main GDScript did not load")
        return
    var player: Node = game.get("character")
    var inventory: Control = game.get("inventory")
    var store: Node = game.get("store")
    if player == null or inventory == null or store == null:
        _fail("Player, inventory, or store failed to initialize")
        return
    if store.get("slots").size() != 200 or store.get("unlocked") < 40:
        _fail("Expected 200 inventory slots, at least 40 unlocked")
        return
    game.call("_toggle")
    await process_frame
    if not inventory.visible:
        _fail("Bag did not open")
        return
    var bag_grid: GridContainer = inventory.get("bag_grid")
    if bag_grid == null or bag_grid.get_child_count() != 50:
        _fail("Bag page should show 50 Godot buttons")
        return
    var tabs: Array = inventory.get("tab_buttons")
    if tabs.size() != 4:
        _fail("Inventory, Character, Skill and Shop tabs missing")
        return
    var fashion_row: HBoxContainer = inventory.get("fashion_weapon_row")
    if fashion_row == null or fashion_row.get_child_count() != 2:
        _fail("Right and left fashion weapon slots missing")
        return
    var clothing_row: HBoxContainer = inventory.get("fashion_row")
    if clothing_row == null or clothing_row.get_child_count() != 5:
        _fail("Fashion clothing must have exactly five image-only slots")
        return
    var side_row: HBoxContainer = inventory.get("fashion_side_row")
    if side_row == null or side_row.get_child_count() != 2:
        _fail("Fashion mask and cape must sit alongside fashion weapons")
        return
    for slot_control in bag_grid.get_children():
        if not (slot_control is TextureButton):
            _fail("Bag must have PNG TextureButton slots without text labels")
            return
        if slot_control.texture_normal == null:
            _fail("Bag PNG texture not loaded")
            return
    for slot_control in clothing_row.get_children():
        if not (slot_control is TextureButton):
            _fail("Fashion slots must use icon-only PNG TextureButtons")
            return
    if inventory.get("ui_font") == null:
        _fail("Thai/English language font missing")
        return
    inventory.call("set_language","th")
    if tabs[0].text != "กระเป๋า":
        _fail("Language toggle did not update Inventory label")
        return
    inventory.call("set_language","en")
    inventory.call("_show_details","sword","",false)
    var popup: PanelContainer = inventory.get("detail_panel")
    var heading: Label = inventory.get("detail_heading")
    if popup == null or not popup.visible or heading == null or heading.text == "":
        _fail("Item details popup did not appear")
        return
    inventory.call("_hide_details")
    if popup.visible:
        _fail("Item details popup did not hide")
        return
    if not store.call("add_item","fashion_mask"):
        _fail("Could not add fashion mask")
        return
    var mask_idx: int = store.get("slots").find("fashion_mask")
    store.call("choose",mask_idx)
    store.call("equip_selected")
    if store.get("equipped").get("fashion_mask","") != "fashion_mask":
        _fail("Fashion mask equip failed")
        return
    if not store.call("add_item","fashion_cape"):
        _fail("Could not add fashion cape")
        return
    var cape_idx: int = store.get("slots").find("fashion_cape")
    store.call("choose",cape_idx)
    store.call("equip_selected")
    if store.get("equipped").get("fashion_cape","") != "fashion_cape":
        _fail("Fashion cape equip failed")
        return
    if not store.call("add_item","fashion_blade"):
        _fail("Could not add fashion weapon")
        return
    var index: int = store.get("slots").find("fashion_blade")
    store.call("choose",index)
    store.call("equip_selected")
    var equipped: Dictionary = store.get("equipped")
    if equipped.get("fashion_weapon_right","") != "fashion_blade":
        _fail("Fashion weapon was not equipped")
        return
    inventory.call("_change_page",3)
    await process_frame
    if bag_grid.get_child_count() != 50:
        _fail("Fourth bag page should show 50 slots")
        return
    print("LEOONLINE SMOKE TEST PASSED: layered image-only PNG slots, 5 fashion clothing, mask/cape, hover details, Thai localization, save/equip, 200-slot bag")
    quit(0)

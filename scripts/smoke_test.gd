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
    var stage: Control = inventory.get("stage")
    if stage == null or stage.get_child_count() == 0:
        _fail("Approved full-frame UI art layer missing")
        return
    var frame_art: TextureRect = stage.get_child(0) as TextureRect
    if frame_art == null or frame_art.texture == null:
        _fail("Approved inventory frame PNG not loaded as first layer")
        return
    if not str(frame_art.texture.resource_path).ends_with("ornate_blue_gold_inventory_ui_frame.png"):
        _fail("Must use the exact approved full-frame PNG")
        return
    if frame_art.size != Vector2(1448,1086):
        _fail("Approved 1448x1086 PNG must not be cropped or distorted")
        return
    if bag_grid.position.distance_to(Vector2(678,268)) > 1.0 or bag_grid.columns != 10:
        _fail("Bag grid does not align to pre-drawn PNG slots")
        return
    for slot_control in bag_grid.get_children():
        if not (slot_control is TextureButton):
            _fail("Bag must have clickable image-only TextureButton slots")
            return
        if not slot_control.disabled and slot_control.texture_normal == null and slot_control.texture_hover == null:
            _fail("Clickable slots must have an approved PNG hover texture")
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
    print("LEOONLINE SMOKE TEST PASSED: approved full-frame PNG aligned, no overlapping panels, 50 clickable slots, 5 fashion clothing, mask/cape, hover details, Thai localization, equip, 200-slot bag")
    quit(0)

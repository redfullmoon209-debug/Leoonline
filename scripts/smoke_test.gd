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
    print("LEOONLINE SMOKE TEST PASSED: game, 200-slot bag, 4 tabs, fashion weapons and page navigation")
    quit(0)

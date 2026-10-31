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
    if game.get("grid").get_child_count() != 50:
        _fail("Bag page should show 50 slots")
        return
    print("LEOONLINE SMOKE TEST PASSED: scene, player, bag and 50 visible slots")
    quit(0)

extends SceneTree
var game: Node
var output := "/tmp/leo-qa"
func _initialize() -> void:
 call_deferred("capture")
func snap(name: String) -> void:
 for i in range(8): await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_jpg(output+"/"+name+".jpg",0.95)
 print("CAPTURE ",name," ",root.size)
func capture() -> void:
 if not OS.get_cmdline_user_args().is_empty(): output=OS.get_cmdline_user_args()[0]
 DirAccess.make_dir_recursive_absolute(output)
 game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.store.slots.fill("")
 game.store.selected=-1
 game.store.unlocked=40
 for key in game.store.equipped: game.store.equipped[key]=""
 for i in range(10): game.store.slots[i]=game.store.DATA.keys()[i]
 for key in game.store.currency: game.store.currency[key]="999999999999999999999"
 game._toggle()
 game.inventory.refresh()
 game.inventory.set_language("th")
 await snap("desktop-th")
 game.inventory.set_language("en")
 await snap("desktop-en")
 game.inventory._switch_tab(1)
 await snap("desktop-character-en")
 game.inventory.set_language("th")
 await snap("desktop-character-th")
 game.inventory._switch_tab(0)
 game.inventory.set_language("en")
 game.inventory._pick_item(0)
 await snap("desktop-details")
 game.inventory._hide_details()
 game.inventory._change_page(3)
 await snap("page-four")
 game.inventory._change_page(0)
 game.inventory.set_language("th")
 root.size=Vector2i(390,844)
 await snap("mobile-portrait")
 game.inventory.scroller.scroll_horizontal=610
 await snap("mobile-bag")
 game.inventory._pick_item(0)
 await snap("mobile-details")
 game.inventory._hide_details()
 root.size=Vector2i(844,390)
 await snap("mobile-landscape")
 game.inventory._pick_item(0)
 await snap("landscape-details")
 print("CAPTURE COMPLETE")
 quit()

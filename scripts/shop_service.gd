extends Node
## Standalone local NPC shop logic; only this module transfers items and money.
## Gameplay inventory, equipment, original bottom buttons and save remain unchanged.
signal notice(message: String)
signal changed

const Catalog = preload("res://scripts/shop_catalog.gd")
const StoreScript = preload("res://scripts/store.gd")
var store: Node

func setup(p_store: Node) -> void:
 store = p_store

func offer(item_id: String) -> Dictionary:
 return Catalog.get_offer(item_id)

func sell_price(item_id: String) -> String:
 return Catalog.get_sell_price(item_id)

func buy(item_id: String) -> bool:
 if store == null: return false
 var listing: Dictionary = Catalog.get_offer(item_id)
 if listing.is_empty() or not StoreScript.DATA.has(item_id):
  notice.emit("This product is not for sale")
  return false
 var currency: String = str(listing.get("currency","gold"))
 var price: String = str(listing.get("price","0"))
 if not store.currency.has(currency) or store.compare(store.currency[currency],price) < 0:
  notice.emit("Not enough currency")
  return false
 var empty_slot: int = -1
 for index in range(int(store.unlocked)):
  if str(store.slots[index]) == "":
   empty_slot=index
   break
 if empty_slot < 0:
  notice.emit("Bag full")
  return false
 var old_balance: String = str(store.currency[currency])
 var old_selected: int = int(store.selected)
 var after: String = str(store.subtract_decimal(old_balance,price))
 if after == "":
  notice.emit("Not enough currency")
  return false
 store.currency[currency] = after
 store.slots[empty_slot] = item_id
 store.selected = -1
 if not store.save_data():
  store.currency[currency] = old_balance
  store.slots[empty_slot] = ""
  store.selected = old_selected
  notice.emit("Save failed")
  return false
 store.emit_signal("changed")
 changed.emit()
 notice.emit("Purchase completed")
 return true

func sell_slot(index: int) -> bool:
 if store == null or index < 0 or index >= int(store.unlocked):
  notice.emit("Select an item first")
  return false
 var item_id: String = str(store.slots[index])
 var price: String = Catalog.get_sell_price(item_id)
 if item_id == "" or price == "0" or not StoreScript.DATA.has(item_id):
  notice.emit("This item cannot be sold")
  return false
 var old_balance: String = str(store.currency["gold"])
 var new_balance: String = str(store.add_decimal(old_balance,price))
 if store.compare(new_balance,StoreScript.MAX_MONEY)>0:
  notice.emit("Currency limit reached")
  return false
 var old_selected: int = int(store.selected)
 store.slots[index] = ""
 store.currency["gold"] = new_balance
 store.selected = -1
 if not store.save_data():
  store.slots[index] = item_id
  store.currency["gold"] = old_balance
  store.selected = old_selected
  notice.emit("Save failed")
  return false
 store.emit_signal("changed")
 changed.emit()
 notice.emit("Sale completed")
 return true

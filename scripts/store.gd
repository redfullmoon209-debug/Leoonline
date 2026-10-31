extends Node
signal changed
signal notice(message: String)
const CAPACITY = 200
const MAX_MONEY = "999999999999999999999"
const DATA = {
 "sword": {"name":"Bronze Sword","kind":"weapon","slot":"weapon_right"},
 "shirt":{"name":"Cloth Shirt","kind":"armor","slot":"shirt"},
 "boots":{"name":"Blue Boots","kind":"armor","slot":"shoes"},
 "potion":{"name":"HP Potion","kind":"other"},
 "scroll":{"name":"Bag +10 Scroll","kind":"other"},
 "wood":{"name":"Wood","kind":"other"},
 "fashion_blade":{"name":"Moonlight Fashion Sword","kind":"fashion","slot":"fashion_weapon_right"},
 "fashion_dagger":{"name":"Crystal Fashion Dagger","kind":"fashion","slot":"fashion_weapon_left"},
 "fashion_mask":{"name":"Moonlight Mask","kind":"fashion","slot":"fashion_mask"},
 "fashion_cape":{"name":"Azure Cape","kind":"fashion","slot":"fashion_cape"}
}
const EQUIPMENT = ["hat","shirt","gloves","pants","shoes","weapon_right","weapon_left","bracelet_left","ring_left","necklace","ring_right","bracelet_right","pet","mount","fashion_hat","fashion_shirt","fashion_gloves","fashion_pants","fashion_shoes","fashion_weapon_right","fashion_weapon_left","fashion_mask","fashion_cape"]
var slots: Array = []
var equipped: Dictionary = {}
var currency: Dictionary = {"gold":"0","blue":"0","purple":"0","green":"0"}
var unlocked := 40
var selected := -1
var seconds_online := 0.0
var next_reward := 18000.0

func _ready() -> void:
 for i in range(CAPACITY):
  slots.append("")
 for k in EQUIPMENT:
  equipped[k] = ""
 load_data()

func _process(delta: float) -> void:
 seconds_online += delta
 if seconds_online >= next_reward and unlocked < CAPACITY:
  unlock_ten()
  next_reward += 18000.0

func add_item(id: String) -> bool:
 if not DATA.has(id):
  return false
 for i in range(unlocked):
  if slots[i] == "":
   slots[i] = id
   changed.emit()
   save_data()
   return true
 notice.emit("Bag full")
 return false

func choose(index: int) -> void:
 if index < 0 or index >= unlocked:
  notice.emit("This slot is locked")
  return
 if selected >= 0 and selected != index:
  var temp: String = slots[selected]
  slots[selected] = slots[index]
  slots[index] = temp
  selected = -1
 else:
  selected = index
 changed.emit()

func equip_selected() -> void:
 if selected < 0 or slots[selected] == "":
  return
 var info: Dictionary = DATA.get(slots[selected],{})
 var key: String = info.get("slot","")
 if key == "":
  notice.emit("Not equippable")
  return
 var old: String = equipped[key]
 equipped[key] = slots[selected]
 slots[selected] = old
 selected = -1
 changed.emit()
 save_data()

func unequip(key: String) -> void:
 if equipped.get(key,"") == "":
  return
 var previous: String = equipped[key]
 if add_item(previous):
  equipped[key] = ""
  changed.emit()
  save_data()

func trash_selected() -> void:
 if selected >= 0 and selected < unlocked:
  slots[selected] = ""
  selected = -1
  changed.emit()
  save_data()

func _less(a: String, b: String) -> bool:
 var weights := {"weapon":0,"armor":1,"other":2}
 var aa: Dictionary = DATA.get(a,{})
 var bb: Dictionary = DATA.get(b,{})
 var aw: int = weights.get(aa.get("kind","other"),2)
 var bw: int = weights.get(bb.get("kind","other"),2)
 if aw != bw:
  return aw < bw
 return a < b

func sort_items() -> void:
 var filled: Array[String] = []
 for i in range(unlocked):
  if slots[i] != "":
   filled.append(slots[i])
 filled.sort_custom(_less)
 for i in range(unlocked):
  slots[i] = filled[i] if i < filled.size() else ""
 selected = -1
 changed.emit()
 save_data()

func unlock_ten() -> void:
 unlocked = mini(CAPACITY,unlocked + 10)
 notice.emit("10 bag slots unlocked")
 changed.emit()
 save_data()

func use_scroll() -> void:
 for i in range(unlocked):
  if slots[i] == "scroll":
   slots[i] = ""
   unlock_ten()
   return
 notice.emit("Bag +10 Scroll required")

func decimal(value: String) -> String:
 var result := ""
 for c in value:
  if c >= "0" and c <= "9":
   result += c
 result = result.lstrip("0")
 return "0" if result == "" else result

func compare(a: String,b: String) -> int:
 a = decimal(a)
 b = decimal(b)
 if a.length() != b.length():
  return 1 if a.length() > b.length() else -1
 if a == b:
  return 0
 return 1 if a > b else -1

func add_decimal(a: String,b: String) -> String:
 a = decimal(a)
 b = decimal(b)
 var i := a.length()-1
 var j := b.length()-1
 var carry := 0
 var result := ""
 while i >= 0 or j >= 0 or carry > 0:
  var aa := a.unicode_at(i)-48 if i >= 0 else 0
  var bb := b.unicode_at(j)-48 if j >= 0 else 0
  var sum := aa+bb+carry
  result = str(sum % 10)+result
  carry = int(sum/10)
  i -= 1
  j -= 1
 return decimal(result)

func add_currency(kind: String,amount: String) -> void:
 if not currency.has(kind):
  return
 var result := add_decimal(currency[kind],amount)
 currency[kind] = MAX_MONEY if compare(result,MAX_MONEY) > 0 else result
 changed.emit()
 save_data()

func pretty(value: String) -> String:
 var output := ""
 for i in range(value.length()):
  if i > 0 and (value.length()-i) % 3 == 0:
   output += ","
  output += value.substr(i,1)
 return output

func save_data() -> bool:
 var data := {"slots":slots,"equipped":equipped,"currency":currency,"unlocked":unlocked,"online":seconds_online,"reward":next_reward}
 var file := FileAccess.open("user://leoonline.json",FileAccess.WRITE)
 if file:
  file.store_string(JSON.stringify(data))
  file.flush()
  return file.get_error() == OK
 return false

func load_data() -> void:
 if not FileAccess.file_exists("user://leoonline.json"):
  return
 var file := FileAccess.open("user://leoonline.json",FileAccess.READ)
 if file == null:
  return
 var data = JSON.parse_string(file.get_as_text())
 if not (data is Dictionary):
  return
 var loaded: Array = data.get("slots",[])
 if loaded.size() == CAPACITY:
  slots = loaded
 var eq: Dictionary = data.get("equipped",{})
 for key in EQUIPMENT:
  if eq.has(key) and (eq[key] is String):
   equipped[key] = eq[key]
 var saved: Dictionary = data.get("currency",{})
 for key in currency.keys():
  var value := decimal(str(saved.get(key,"0")))
  currency[key] = MAX_MONEY if compare(value,MAX_MONEY) > 0 else value
 unlocked = clampi(int(data.get("unlocked",40)),40,CAPACITY)
 seconds_online = maxf(0.0,float(data.get("online",0.0)))
 next_reward = maxf(18000.0,float(data.get("reward",18000.0)))
 changed.emit()

extends Node
signal changed
signal notice(message: String)
# Character profile is a real saved model. Initial base attributes are the first
# playable Novice values, not a leaderboard calculation or combat claim.
# PvE/PvP tracking and rankings become authoritative when server systems exist.
const PROFILE_DEFAULTS: Dictionary = {
 "name":"Adventurer","level":1,"experience":0,"class_tier":0,
 "job":"Novice","path":"Unchosen","faction":"None","stat_points":0,
 "attributes":{"strength":10,"vitality":10,"agility":10,"intelligence":10,"dexterity":10,"luck":10},
 "pve_kills":0,"pvp_wins":0,"pvp_losses":0
}
const CAPACITY = 200
const STORAGE_CAPACITY = 200
const STORAGE_PAGE_SIZE = 50
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
 "fashion_cape":{"name":"Azure Cape","kind":"fashion","slot":"fashion_cape"},
 "hp_potion_small":{"name":"HP Potion (Small)","kind":"consumable","description":"Shop consumable; HP recovery is reserved for the future combat system."},
 "hp_potion_medium":{"name":"HP Potion (Medium)","kind":"consumable","description":"Shop consumable; HP recovery is reserved for the future combat system."},
 "hp_potion_large":{"name":"HP Potion (Large)","kind":"consumable","description":"Shop consumable; HP recovery is reserved for the future combat system."},
 "sp_potion_small":{"name":"SP Potion (Small)","kind":"consumable","description":"Shop consumable; SP recovery is reserved for the future combat system."},
 "sp_potion_medium":{"name":"SP Potion (Medium)","kind":"consumable","description":"Shop consumable; SP recovery is reserved for the future combat system."},
 "sp_potion_large":{"name":"SP Potion (Large)","kind":"consumable","description":"Shop consumable; SP recovery is reserved for the future combat system."},
 "upgrade_stone_1":{"name":"Upgrade Stone +1","kind":"upgrade","description":"Upgrade material; equipment enhancement is not enabled yet."},
 "upgrade_stone_2":{"name":"Upgrade Stone +2","kind":"upgrade","description":"Upgrade material; equipment enhancement is not enabled yet."},
 "upgrade_stone_3":{"name":"Upgrade Stone +3","kind":"upgrade","description":"Upgrade material; equipment enhancement is not enabled yet."},
 "upgrade_stone_4":{"name":"Upgrade Stone +4","kind":"upgrade","description":"Upgrade material; equipment enhancement is not enabled yet."},
 "upgrade_stone_5":{"name":"Upgrade Stone +5","kind":"upgrade","description":"Upgrade material; equipment enhancement is not enabled yet."},
 "upgrade_stone_6":{"name":"Upgrade Stone +6","kind":"upgrade","description":"Upgrade material; equipment enhancement is not enabled yet."},
 "upgrade_stone_7":{"name":"Upgrade Stone +7","kind":"upgrade","description":"Upgrade material; equipment enhancement is not enabled yet."},
 "upgrade_stone_8":{"name":"Upgrade Stone +8","kind":"upgrade","description":"Upgrade material; equipment enhancement is not enabled yet."},
 "upgrade_stone_9":{"name":"Upgrade Stone +9","kind":"upgrade","description":"Upgrade material; equipment enhancement is not enabled yet."},
 "upgrade_stone_10":{"name":"Upgrade Stone +10","kind":"upgrade","description":"Upgrade material; equipment enhancement is not enabled yet."},
 "upgrade_stone_11":{"name":"Upgrade Stone +11","kind":"upgrade","description":"Upgrade material; equipment enhancement is not enabled yet."},
 "upgrade_stone_12":{"name":"Upgrade Stone +12","kind":"upgrade","description":"Upgrade material; equipment enhancement is not enabled yet."},
 "upgrade_stone_13":{"name":"Upgrade Stone +13","kind":"upgrade","description":"Upgrade material; equipment enhancement is not enabled yet."},
 "upgrade_stone_14":{"name":"Upgrade Stone +14","kind":"upgrade","description":"Upgrade material; equipment enhancement is not enabled yet."},
 "upgrade_stone_15":{"name":"Upgrade Stone +15","kind":"upgrade","description":"Upgrade material; equipment enhancement is not enabled yet."}
}
const EQUIPMENT = ["hat","shirt","gloves","pants","shoes","weapon_right","weapon_left","bracelet_left","ring_left","necklace","ring_right","bracelet_right","pet","mount","fashion_hat","fashion_shirt","fashion_gloves","fashion_pants","fashion_shoes","fashion_weapon_right","fashion_weapon_left","fashion_mask","fashion_cape"]
var slots: Array = []
var storage_slots: Array = []
var storage_selected: int = -1
var equipped: Dictionary = {}
var currency: Dictionary = {"gold":"0","blue":"0","purple":"0","green":"0"}
# Four independent exact-decimal 21-digit vault balances; never use floats/ints for funds.
var storage_currency: Dictionary = {"gold":"0","blue":"0","purple":"0","green":"0"}
var profile: Dictionary = PROFILE_DEFAULTS.duplicate(true)
var unlocked := 40
var selected := -1
var seconds_online := 0.0
var next_reward := 18000.0

func _ready() -> void:
 for i in range(CAPACITY):
  slots.append("")
 for i in range(STORAGE_CAPACITY):
  storage_slots.append("")
 for k in EQUIPMENT:
  equipped[k] = ""
 load_data()

func _process(delta: float) -> void:
 seconds_online += delta
 if seconds_online >= next_reward and unlocked < CAPACITY:
  unlock_ten()
  next_reward += 18000.0

func choose_storage(index: int) -> void:
 # One selected item per window; clicking Storage never swaps bag contents.
 if index < 0 or index >= STORAGE_CAPACITY:
  notice.emit("Invalid storage slot")
  return
 storage_selected = index
 selected = -1
 changed.emit()

func deposit_selected() -> bool:
 # Move an item from an UNLOCKED bag slot to the first empty storage slot.
 # Both lists are persisted together in one game save (never duplicate items).
 var from: int = selected
 if from < 0 or from >= unlocked or from >= slots.size():
  notice.emit("Select a bag item to deposit")
  return false
 var item_id: String = str(slots[from])
 if item_id == "":
  notice.emit("Select a bag item to deposit")
  return false
 var target: int = storage_slots.find("")
 if target < 0:
  notice.emit("Storage full")
  return false
 var old_selected: int = selected
 var old_storage_selected: int = storage_selected
 slots[from] = ""
 storage_slots[target] = item_id
 selected = -1
 storage_selected = -1
 if not save_data():
  slots[from] = item_id
  storage_slots[target] = ""
  selected = old_selected
  storage_selected = old_storage_selected
  notice.emit("Save failed")
  return false
 changed.emit()
 notice.emit("Item deposited")
 return true

func withdraw_selected() -> bool:
 # Withdraw only from the selected occupied storage cell; the locked bag
 # capacity is enforced, so Storage cannot bypass bag-unlock progression.
 var from: int = storage_selected
 if from < 0 or from >= STORAGE_CAPACITY:
  notice.emit("Select a storage item to withdraw")
  return false
 var item_id: String = str(storage_slots[from])
 if item_id == "":
  notice.emit("Select a storage item to withdraw")
  return false
 var target: int = -1
 for i in range(unlocked):
  if str(slots[i]) == "":
   target = i
   break
 if target < 0:
  notice.emit("Bag full")
  return false
 var old_selected: int = selected
 var old_storage_selected: int = storage_selected
 storage_slots[from] = ""
 slots[target] = item_id
 storage_selected = -1
 selected = -1
 if not save_data():
  storage_slots[from] = item_id
  slots[target] = ""
  selected = old_selected
  storage_selected = old_storage_selected
  notice.emit("Save failed")
  return false
 changed.emit()
 notice.emit("Item withdrawn")
 return true

func experience_required(level: int) -> int:
 # Data/UI progression hook only; no experience source is wired yet.
 return 100 + maxi(0,level-1)*50

func grant_experience(amount: int) -> void:
 if amount <= 0: return
 var level: int = clampi(int(profile.get("level",1)),1,999)
 var exp: int = maxi(0,int(profile.get("experience",0))) + amount
 while level < 999 and exp >= experience_required(level):
  exp -= experience_required(level)
  level += 1
 if level == 999: exp = mini(exp,experience_required(level)-1)
 profile["level"] = level
 profile["experience"] = exp
 changed.emit()
 save_data()

func character_snapshot() -> Dictionary:
 # Snapshot only; wealth shows each exact 21-digit currency independently.
 # Rankings are intentionally NOT fabricated from client-side counters.
 return {
  "profile": profile.duplicate(true),
  "currency": currency.duplicate(true),
  "experience_required": experience_required(int(profile.get("level",1))),
  "pve_rank": -1, "pvp_rank": -1, "wealth_rank": -1
 }

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

func subtract_decimal(a: String,b: String) -> String:
 # Exact, nonnegative subtraction for amounts up to 21 digits. Empty = insufficient.
 a=decimal(a)
 b=decimal(b)
 if compare(a,b)<0: return ""
 var out: String = ""
 var borrow: int = 0
 for i in range(a.length()-1,-1,-1):
  var ai: int = a.unicode_at(i)-48-borrow
  var j: int = i-a.length()+b.length()
  var bi: int = b.unicode_at(j)-48 if j>=0 else 0
  if ai<bi:
   ai+=10
   borrow=1
  else:
   borrow=0
  out=str(ai-bi)+out
 return decimal(out)

func add_currency(kind: String,amount: String) -> void:
 if not currency.has(kind):
  return
 var result := add_decimal(currency[kind],amount)
 currency[kind] = MAX_MONEY if compare(result,MAX_MONEY) > 0 else result
 changed.emit()
 save_data()

func normalized_transfer_amount(raw: String) -> String:
 # Reject non-ASCII digits, zero, fractions, signs and amounts above 21 digits.
 # Never convert 21-digit balances to an int, float or JavaScript Number.
 var value: String = raw.strip_edges()
 if value.is_empty(): return ""
 for digit in value:
  if digit < "0" or digit > "9": return ""
 value = decimal(value)
 if value == "0" or compare(value,MAX_MONEY) > 0: return ""
 return value

func deposit_money(kind: String, amount: String) -> bool:
 return _move_currency_to_storage(kind,amount,false)

func withdraw_money(kind: String, amount: String) -> bool:
 return _move_currency_to_storage(kind,amount,true)

func _move_currency_to_storage(kind: String, amount_text: String, withdraw: bool) -> bool:
 # Atomic money transfer between wallet and vault. Both balances are saved
 # in the existing player save and rolled back together on a failed save.
 if not currency.has(kind) or not storage_currency.has(kind):
  notice.emit("Invalid currency")
  return false
 var amount: String = normalized_transfer_amount(amount_text)
 if amount.is_empty():
  notice.emit("Enter a valid money amount")
  return false
 var origin: Dictionary = storage_currency if withdraw else currency
 var target: Dictionary = currency if withdraw else storage_currency
 var before_origin: String = str(origin[kind])
 var before_target: String = str(target[kind])
 if compare(before_origin,amount) < 0:
  notice.emit("Not enough stored money" if withdraw else "Not enough wallet money")
  return false
 var after_target: String = add_decimal(before_target,amount)
 if compare(after_target,MAX_MONEY) > 0:
  notice.emit("Wallet money limit reached" if withdraw else "Storage money limit reached")
  return false
 origin[kind] = subtract_decimal(before_origin,amount)
 target[kind] = after_target
 if not save_data():
  origin[kind] = before_origin
  target[kind] = before_target
  notice.emit("Save failed")
  return false
 changed.emit()
 notice.emit("Money withdrawn" if withdraw else "Money deposited")
 return true

func pretty(value: String) -> String:
 var output := ""
 for i in range(value.length()):
  if i > 0 and (value.length()-i) % 3 == 0:
   output += ","
  output += value.substr(i,1)
 return output

const WEB_SAVE_KEY = "leoonline_save_v1"

func save_data() -> bool:
 var data := {"slots":slots,"storage_slots":storage_slots,"storage_currency":storage_currency,"equipped":equipped,"currency":currency,"unlocked":unlocked,"online":seconds_online,"reward":next_reward,"profile":profile}
 var payload: String = JSON.stringify(data)
 var file_saved: bool = false
 var file := FileAccess.open("user://leoonline.json",FileAccess.WRITE)
 if file != null:
  file.store_string(payload)
  file.flush()
  file_saved = file.get_error() == OK
  file.close()
 # Godot Web's virtual filesystem can flush to IndexedDB asynchronously.
 # Mirror each completed transaction into same-origin localStorage synchronously,
 # so an immediate reload cannot resurrect previously sold items.
 var web_saved: bool = false
 if OS.has_feature("web"):
  var escaped: String = JSON.stringify(payload)
  var js: String = "(function(){try{localStorage.setItem('"+WEB_SAVE_KEY+"',"+escaped+");return true;}catch(e){return false;}})()"
  web_saved = bool(JavaScriptBridge.eval(js,true))
 return file_saved or web_saved

func load_data() -> void:
 var data: Variant = null
 if OS.has_feature("web"):
  var js: String = "(function(){try{return localStorage.getItem('"+WEB_SAVE_KEY+"')||'';}catch(e){return '';}})()"
  var raw: Variant = JavaScriptBridge.eval(js,true)
  if raw is String and not raw.is_empty():
   data = JSON.parse_string(raw)
 if not (data is Dictionary):
  if not FileAccess.file_exists("user://leoonline.json"):
   return
  var file := FileAccess.open("user://leoonline.json",FileAccess.READ)
  if file == null:
   return
  data = JSON.parse_string(file.get_as_text())
 if not (data is Dictionary):
  return
 var loaded: Array = data.get("slots",[])
 if loaded.size() == CAPACITY:
  slots = loaded
 # Backwards-compatible: existing Leoonline saves have no storage key.
 # Do not erase a saved bank during a reload of older inventory-only data.
 var stored: Variant = data.get("storage_slots",[])
 if stored is Array and stored.size() == STORAGE_CAPACITY:
  for i in range(STORAGE_CAPACITY):
   storage_slots[i] = str(stored[i]) if stored[i] is String else ""
 storage_selected = -1
 var eq: Dictionary = data.get("equipped",{})
 for key in EQUIPMENT:
  if eq.has(key) and (eq[key] is String):
   equipped[key] = eq[key]
 var saved: Dictionary = data.get("currency",{})
 for key in currency.keys():
  var value := decimal(str(saved.get(key,"0")))
  currency[key] = MAX_MONEY if compare(value,MAX_MONEY) > 0 else value
 # Legacy saves contain no storage_currency; initialize each vault currency to 0.
 # Ignore malformed entries rather than silently inventing or duplicating money.
 var bank_saved: Variant = data.get("storage_currency",{})
 for key in storage_currency.keys():
  var value: String = "0"
  if bank_saved is Dictionary:
   var candidate: Variant = bank_saved.get(key,"0")
   if candidate is String and not candidate.is_empty():
    var valid: bool = true
    for digit in candidate:
     if digit < "0" or digit > "9":
      valid = false
      break
    if valid:
     value = decimal(candidate)
  storage_currency[key] = MAX_MONEY if compare(value,MAX_MONEY) > 0 else value
 unlocked = clampi(int(data.get("unlocked",40)),40,CAPACITY)
 seconds_online = maxf(0.0,float(data.get("online",0.0)))
 next_reward = maxf(18000.0,float(data.get("reward",18000.0)))
 var profile_saved: Variant = data.get("profile",{})
 if profile_saved is Dictionary:
  var saved_profile: Dictionary = profile_saved
  profile["name"] = str(saved_profile.get("name","Adventurer")).substr(0,24)
  if str(profile["name"]).strip_edges()=="":
   profile["name"]="Adventurer"
  profile["level"] = clampi(int(saved_profile.get("level",1)),1,999)
  profile["experience"] = clampi(int(saved_profile.get("experience",0)),0,experience_required(int(profile["level"]))-1)
  profile["class_tier"] = clampi(int(saved_profile.get("class_tier",0)),0,10)
  profile["stat_points"] = clampi(int(saved_profile.get("stat_points",0)),0,99999)
  for key in ["job","path","faction"]:
   profile[key]=str(saved_profile.get(key,PROFILE_DEFAULTS[key])).substr(0,36)
  var attributes: Dictionary = profile["attributes"]
  var saved_attributes: Variant = saved_profile.get("attributes",{})
  if saved_attributes is Dictionary:
   for key in attributes.keys():
    attributes[key]=clampi(int(saved_attributes.get(key,10)),0,99999)
  for key in ["pve_kills","pvp_wins","pvp_losses"]:
   profile[key]=clampi(int(saved_profile.get(key,0)),0,2147483647)
 changed.emit()

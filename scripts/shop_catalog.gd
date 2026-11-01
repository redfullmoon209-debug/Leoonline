extends RefCounted
## NPC shop product catalog. Add new items to Store.DATA and entries here.
## The grid reserves 500 slots (10 pages x 50) without changing the UI layout.
## stock = -1 means unlimited NPC stock. For real multiplayer stores, enforce
## balances, transactions and stock through a trusted backend before launch.
const PAGE_SIZE: int = 50
const PAGE_COUNT: int = 10
const MAX_ITEMS: int = PAGE_SIZE * PAGE_COUNT
const OFFERS: Array = [
 {
 "id": "hp_potion_small",
 "price": "50",
 "currency": "gold",
 "sell": "25",
 "stock": -1
 },
 {
 "id": "hp_potion_medium",
 "price": "220",
 "currency": "gold",
 "sell": "110",
 "stock": -1
 },
 {
 "id": "hp_potion_large",
 "price": "750",
 "currency": "gold",
 "sell": "375",
 "stock": -1
 },
 {
 "id": "sp_potion_small",
 "price": "60",
 "currency": "gold",
 "sell": "30",
 "stock": -1
 },
 {
 "id": "sp_potion_medium",
 "price": "230",
 "currency": "gold",
 "sell": "115",
 "stock": -1
 },
 {
 "id": "sp_potion_large",
 "price": "760",
 "currency": "gold",
 "sell": "380",
 "stock": -1
 },
 {
 "id": "upgrade_stone_1",
 "price": "150",
 "currency": "gold",
 "sell": "75",
 "stock": -1
 },
 {
 "id": "upgrade_stone_2",
 "price": "300",
 "currency": "gold",
 "sell": "150",
 "stock": -1
 },
 {
 "id": "upgrade_stone_3",
 "price": "600",
 "currency": "gold",
 "sell": "300",
 "stock": -1
 },
 {
 "id": "upgrade_stone_4",
 "price": "1200",
 "currency": "gold",
 "sell": "600",
 "stock": -1
 },
 {
 "id": "upgrade_stone_5",
 "price": "2400",
 "currency": "gold",
 "sell": "1200",
 "stock": -1
 },
 {
 "id": "upgrade_stone_6",
 "price": "4800",
 "currency": "gold",
 "sell": "2400",
 "stock": -1
 },
 {
 "id": "upgrade_stone_7",
 "price": "9600",
 "currency": "gold",
 "sell": "4800",
 "stock": -1
 },
 {
 "id": "upgrade_stone_8",
 "price": "19200",
 "currency": "gold",
 "sell": "9600",
 "stock": -1
 },
 {
 "id": "upgrade_stone_9",
 "price": "38400",
 "currency": "gold",
 "sell": "19200",
 "stock": -1
 },
 {
 "id": "upgrade_stone_10",
 "price": "76800",
 "currency": "gold",
 "sell": "38400",
 "stock": -1
 },
 {
 "id": "upgrade_stone_11",
 "price": "153600",
 "currency": "gold",
 "sell": "76800",
 "stock": -1
 },
 {
 "id": "upgrade_stone_12",
 "price": "307200",
 "currency": "gold",
 "sell": "153600",
 "stock": -1
 },
 {
 "id": "upgrade_stone_13",
 "price": "614400",
 "currency": "gold",
 "sell": "307200",
 "stock": -1
 },
 {
 "id": "upgrade_stone_14",
 "price": "1228800",
 "currency": "gold",
 "sell": "614400",
 "stock": -1
 },
 {
 "id": "upgrade_stone_15",
 "price": "2457600",
 "currency": "gold",
 "sell": "1228800",
 "stock": -1
 }
]

const BASE_SELL_PRICES: Dictionary = {
 "sword":"35","shirt":"12","boots":"18","potion":"5","scroll":"120",
 "wood":"2","fashion_blade":"85","fashion_dagger":"85",
 "fashion_mask":"55","fashion_cape":"65"
}

static func get_offer(item_id: String) -> Dictionary:
 for item in OFFERS:
  if str(item.get("id","")) == item_id:
   return item
 return {}

static func get_sell_price(item_id: String) -> String:
 var offer := get_offer(item_id)
 if not offer.is_empty():
  return str(offer.get("sell","0"))
 return str(BASE_SELL_PRICES.get(item_id,"0"))

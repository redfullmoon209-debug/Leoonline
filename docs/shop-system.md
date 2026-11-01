# Leoonline Shop System — Extensible NPC Store (Godot 4.4.1)

## Implemented
- Open **Shop** from the existing four top tabs. The same 200-slot player inventory moves to the left; the NPC **Shop Panel** occupies the right. No original footer/menu buttons are removed or re-mapped.
- Shop reserves **500 listing positions**, 50 per page and 10 pages. The starter catalog has **21 purchasable items**: HP (3 sizes), SP (3 sizes), Upgrade Stones +1 through +15.
- Every product has its own transparent 96×96 PNG under `assets/ui/shop/`. These sprites are original drawings built by `tools/generate_shop_icons.py`, **not screenshot crops**. The item names and prices are Godot labels, never baked into PNG art.
- Buy: check catalog, validate exact **string-based currency**, check for an unlocked empty inventory slot, subtract the price, add one item, persist, emit inventory updates.
- Sell: select an owned item in the **left** inventory, press the **right-panel Sell** button, confirm the exact quoted resale amount. Selling verifies the slot still contains the same item before removing it, checks the 21-digit currency ceiling, credits the balance, and persists.
- Save: Godot `user://leoonline.json`, plus a synchronous `localStorage` mirror on web to protect rapid-reload transactions. These local saves are client-side and **not secure authoritative multiplayer data**.
- Existing bottom row remains Demo Items, Save, Auto Sort, Trash, Equip, Close. Skill remains a truthful not-yet-available screen.

## Source of truth / safe expansion
| File | Responsibility |
|---|---|
| `scripts/shop_catalog.gd` | Listing order, price, resale price, currency, reserved 500-position catalog |
| `scripts/store.gd` | Item type/name/description, 200-slot player inventory, exact 21-digit currency values, save/load |
| `scripts/shop_service.gd` | Validated local NPC shop Buy/Sell transactions; never let UI mutate currency directly |
| `scripts/inventory_ui.gd` | Shop tab, reused player bag, item icon grids, Buy/Sell buttons, page navigation, confirmation |
| `tools/generate_shop_icons.py` | Generates *individual* original transparent icons for 21 starter products |
| `assets/ui/shop/` | Separate HP/SP and upgrade-stone PNG files |
| `scripts/smoke_test.gd`, `tools/test_web_inventory.cjs` | Shop transactions and desktop/mobile browser regression tests |

### Adding an item for sale
1. Assign it a unique stable `id` (ASCII/underscores), define `name`, `kind`, and a truthful description in `Store.DATA`.
2. Add an `OFFERS` entry in `shop_catalog.gd` with `id`, **decimal-string** `price`, `currency` (currently one of gold/blue/purple/green), **decimal-string** `sell`, and `stock=-1` (unlimited NPC catalog). Do not exceed the reserved 500 positions without increasing `MAX_ITEMS` and testing the UI.
3. Add `assets/ui/shop/<id>.png` as an **individual transparent icon**; text must remain localized Labels. Add translations in `inventory_ui.gd`'s `LABELS` mapping.
4. Run the Godot smoke checks, browser tests, and verify the deployed Shop page on both landscape desktop and mobile.

## Not yet implemented / future design
- **Actual HP/SP restorative effects** and **weapon-enhancement success/chances** are not yet wired into combat. The items can be purchased, stored and sold; do not claim gameplay effects before those systems exist.
- `stock=-1` is a catalog placeholder for unlimited NPC stock. Actual shared stock, player-owned stalls, player-to-player trades or live prices require a **server-authoritative backend**, authentication, validation, and atomic transactions; do not trust localStorage/JavaScript for production money or entitlement checks.
- Future server API idea: `GET /shops/{shop_id}/offers?page=`, `POST /shops/{shop_id}/buy`, `POST /shops/{shop_id}/sell`, with unique idempotency keys, transaction logs, optimistic stock locks, GM authorization, and reconciled character currency/inventory.
- Only authorized GM accounts should add/edit worldwide product listings. **Do not put an unprotected GM "create offer" form into a public GitHub Pages build**.
- Local NPC resale credits **Gold**; if a future shop pays out in other currencies, extend both UI quotes and `shop_service.gd` rules before enabling it.

## Regression tests
- 500 offer positions, 10x5 grid, 21 original icons and catalog items
- Shop reuses the existing bag at left while Inventory tab restores it to the right
- Buying HP debits the exact amount and adds one owned item
- Insufficient funds, full inventory and currency overflow never duplicate items
- Selling requires a confirmation dialog, removes exactly the selected item and credits the quoted price
- Save/load, reload after sell, locale, 200 original bag slots, 4 top tabs and the original six footer buttons

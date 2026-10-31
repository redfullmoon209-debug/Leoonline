# 911 TASK 002 — Premium Fantasy Inventory UI

Priority: HIGH
Status: QUEUED — not automatically executed by an external GPT agent
Target: redfullmoon209-debug/Leoonline (Godot 4.4.1)

## User order
Restyle the existing Leoonline inventory to match the previously approved fantasy blue-and-gold inventory reference. Preserve real gameplay interactions. Do not substitute a flat screenshot for functional UI. Build independent, transparent PNG assets for every frame, ornament, button, tab, and slot treatment; place text separately in Godot Control nodes for Thai localization. Avoid cropping the whole design into pieces.

## Required layout and behaviors
- Premium deep navy / sapphire / gold visual hierarchy, readable contrast, refined fantasy ornamentation
- Left character/equipment panel, right inventory grid, four currency displays
- Equipment slots: hat, shirt, gloves, pants, shoes, two weapon slots, jewelry, mount/pet, separate fashion row
- Bag capacity 200 slots, 40 initially available, 50 per page; clear locked/selected/empty states
- Functional equip/unequip, sort, item selection, trash confirmation, unlock slots, save
- Responsive desktop and mobile browser; no clipped labels or overlapping controls
- Thai-capable font and editable localized labels; no text baked into PNG
- Each UI control uses real Godot buttons with normal/hover/pressed/disabled visual states

## Delivery and validation
Commit asset files and Godot scene/scripts to GitHub. Run Godot parser, smoke test, and web export; inspect actual UI and fix visual defects before claiming completion. Keep game playable, and provide commit and live URL.

## Agent status
911 currently records tasks and provides a browser-local UI editor. There is no autonomous GPT execution connection. This order is a queued specification, NOT proof that the redesign has been implemented.

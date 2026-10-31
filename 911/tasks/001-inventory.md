# 911 TASK 001 — LEOONLINE INVENTORY

Status: QUEUED (manual GPT agent connection required)
Priority: HIGH
Target repository: redfullmoon209-debug/Leoonline

## Order
Build and integrate the approved fantasy blue-and-gold inventory UI in Godot. DO NOT crop the whole reference image and paste it as a single texture. Produce independent transparent PNG layers for frames, ornaments, slot states, buttons and tabs; use Godot Control nodes for interactive labels, slots and layout. Preserve gameplay and save/load.

## Acceptance criteria
- Equipment slots: hat, shirt, gloves, pants, shoes, right/left weapons, jewelry, pet, fashion
- 200 bag slots, 40 initially unlocked, 50 per page
- Four currency types, exact 21-digit integer handling via strings or equivalent
- Auto sort weapons > armor > other, equip/unequip, trash confirmation
- Thai-capable fonts, no tofu glyphs, PC/mobile responsive layout
- Independent UI layers and button normal/hover/pressed/disabled states
- Working Godot 4.4.1 web export and successful GitHub Actions checks
- Verify deployed game visually and functionally; do not report success without evidence

## Automation status
The 911 PWA is currently a command drafting interface, not an autonomous GPT agent. This task file records the order in GitHub, but no independent GPT worker is connected to execute it. Do not mark completed until implementation and testing actually succeed.

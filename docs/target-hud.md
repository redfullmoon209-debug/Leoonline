# Leoonline target HUD — approved independent UI implementation

The top-center **Target** card is NOT a crop of the approved reference
image. It is built from independent, real Godot controls:

- \`scripts/hud_top_status.gd\`: responsive position, target avatar texture
  display, dynamic labels, exact visible HP/MP progress bars and percentages
- \`scripts/hud_target_decoration.gd\`: gold trim, gem details and circular
  portrait-medallion decorations, drawn directly with Godot CanvasItem
- \`assets/ui/hud/target_training_golem.svg\`: an individually authored local
  golem portrait (not extracted from a combined screenshot)
- \`scripts/main.gd\`: a real selectable 3D training golem with collision,
  level, name, category, HP, MP and local portrait metadata

## Expected visual composition

On landscape PC and phone: **top-left** player portrait/name/EXP,
**top-center** gold-bordered target below the icon caption row,
**top-right** ten separate icons immediately LEFT of the circular minimap.
On portrait screens the TEN ICONS sit at the TOP on one line. The character
card LEFT, live target card CENTER and minimap RIGHT all sit on the next
aligned row. The gold outer borders and target portrait medallion remain,
but all distracting interior horizontal/vertical divider lines are removed.
The narrow target card shows actual compact HP/MP counts; landscape retains
full counts and percentage text. All labels are live Godot text, not image
crops.

The target card contains a left circular portrait, name, optional level and
category at top, a live **red HP** progress bar with numeric current/max and
percentage, and a live **blue MP** progress bar with numeric current/max and
percentage when available.

## Test the UI in the current playable prototype

- Press **T** while playing to select/lock the training golem; press T
  again to clear. Or **tap/click the physical golem** in the 3D world.
- The real golem (named อสูรหินฝึก, Lv.12) is a test encounter positioned
  near the starter scene. HP/MP are attributes on that actual object, not
  hard-coded decoration on the HUD.
- Without a selected entity, the portrait is a question mark and **no fake
  health or mana bars** are visible.
- With a selected entity, calling \`set_meta("hp",new_value)\` or
  \`set_meta("mp",new_value)\` on the target updates the visible bars.
- Unknown HP/MP fields are hidden: they are never invented.

## Hook another monster/NPC into the UI

Any real \`Node3D\` may be passed to
\`hud_menu.set_target(selected_node)\`. Relevant metadata:

| Metadata key | Meaning |
| --- | --- |
| \`target_name\` | Display name, otherwise the node name |
| \`level\` | Level badge, hidden when not defined |
| \`target_type\` | Type e.g. Monster, NPC, Boss, hidden when absent |
| \`hp\`, \`max_hp\` | Current/max health; both required to show HP |
| \`mp\`, \`max_mp\` | Current/max mana; both required to show MP |
| \`target_portrait\` | A **standalone Texture2D** or existing local image path in \`res://assets/ui/hud/\` |

Do not use a composite artwork crop for \`target_portrait\`; provide
individual artwork matching the real selected monster. \`clear_target()\`
immediately hides the previous values. The HUD also clears itself when the
target node is freed.

## Quality checks

\`scripts/smoke_test.gd\` validates portrait loading, actual metadata,
HP/MP updates, no target fallback and PC/phone landscape geometry. The
Chromium \`tools/test_web_inventory.cjs\` suite selects the actual golem
using keyboard T, captures a screenshot with both bars visible, then
clears the lock while preserving the original menu, inventory, banking,
portrait browser release and landscape test.


## Additional real selection targets

Five physically present selectable 3D entities are in the start scene:

| Entity | Type shown in target HUD | Level | HP / MP |
| --- | --- | ---: | ---: |
| อสูรหินฝึก | Monster | 12 | 3240 / 670 |
| สไลม์มรกต | Monster | 4 | 430 / 80 |
| หมาป่าทมิฬ | Monster | 9 | 1760 / 260 |
| Aster [BOT] | Player Bot | 16 | 2400 / 1200 |
| Luna [BOT] | Player Bot | 24 | 3800 / 2250 |

Every target has a real collider, its own 3D mesh and an individually
authored SVG portrait. The player entities are **offline, simulated bots**,
not actual accounts, online presence, or multiplayer connections. The
portrait, label, level, category, red HP and blue MP change when the
player clicks/taps a different target in the real 3D view.

## Separate local GM TEST menu

The **GM** button is an independent native-red/gold Godot Button, never
part of the ten original PNG menu icons. In this prototype it is enabled
only inside the separate **landscape TEST** page by the local opt-in
\`gm_test=1\` flag. The production portrait homepage does not show it.

Its real local-scene tools:

- Choose any spawned entity as the current target
- Spawn a monster (slime / wolf) and automatically select it
- Spawn a clearly marked simulated Player [BOT] and select it
- Subtract 25% of max HP from the selected real node
- Subtract 25% of max MP from the selected real node
- Restore selected target HP/MP
- Delete only GM-spawned extras, heal initial test entities, clear target

The total number of GM-spawned extra entities is capped at 12, avoiding
unbounded browser-memory use. Reset does not alter inventory, game money,
saved progress or a remote service.

**Security note:** A query parameter and hidden UI are NOT GM account
authentication. This temporary menu only changes a local demo scene.
Real GM authorization requires a server-side authenticated owner role and
server-validated actions before enabling a live multiplayer game. Do not
reuse this public test control for real privileged online functions.

**QA:** \`scripts/smoke_test.gd\` exercises five target portraits, 3D
ray selection, the distinct GM icon, spawning a monster and a Player BOT,
real HP/MP changes and reset, and ensures the control is hidden by default.
\`tools/test_landscape_shell.cjs\` touches the GM button in real Chromium
desktop/phone landscape and confirms the same actions operate in the
released browser runtime.

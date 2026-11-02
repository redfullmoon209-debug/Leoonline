extends Control
## Empty, noninteractive overlay retained to keep existing HUD bindings stable.
## The user requested NO portrait medallion, inner ring, lines, separators,
## or other decoration inside the target information card.
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
 pass

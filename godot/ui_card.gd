extends PanelContainer
const Kit = preload("res://godot/ui_kit.gd")
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    theme = Kit.theme()
    add_theme_stylebox_override("panel",Kit.panel())


extends Node2D
const Terrain = preload("res://godot/terrain_painter.gd")
var entries: Array[Dictionary] = []
var camera := 0.0
var factor := 1.0
var base_y := 896.0
var opacity := 1.0
var theme := "highland"
func _ready() -> void:
    texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
func _draw() -> void:
    Terrain.seabed(self,get_viewport_rect().size,camera*factor,theme,base_y,opacity)
    for entry in entries:
        var sprite: Sprite2D = entry["sprite"]
        if sprite.visible:
            Terrain.contact(self,sprite.position-Vector2(0,5),sprite.texture.get_width()*sprite.scale.x,.23*opacity)

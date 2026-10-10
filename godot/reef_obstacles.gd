extends Node2D
## Original HTML collision rectangles, now rendered by native Sprite2D with
## directional relief materials. Geometry remains owned by HighlandData.
const Terrain = preload("res://godot/terrain_painter.gd")
const Highland = preload("res://godot/highland_data.gd")
const Art = preload("res://godot/environment_art.gd")
var materials: Array[ShaderMaterial] = []
const RELIEF_SHADER: Shader = preload("res://godot/shaders/reef_rock_relief.gdshader")
var sprites: Array[Sprite2D] = []
var positions: Array[Rect2] = []
var camera_x := 0.0
var view_width := 1400.0

func _ready() -> void:
    z_index = -1
    texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
    positions = preload("res://godot/chapter_data.gd").obstacles_for("highland")
    for i in range(positions.size()):
        var r := positions[i]
        var overhead := r.position.y < 340.0
        var frame := (i % 2) if overhead else (2 + i % 2)
        var sprite := Sprite2D.new()
        sprite.name = "ReliefReef_%02d" % i
        sprite.texture = Terrain.formation((i%2) if overhead else (2+i%2))
        sprite.centered = false
        sprite.flip_v = false
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
        var material := ShaderMaterial.new()
        material.shader = RELIEF_SHADER
        material.set_shader_parameter("ceiling_rock", 1.0 if overhead else 0.0)
        var region: Rect2 = Terrain.REGIONS[frame]
        var tex_size := Vector2(Terrain.FORMATIONS.get_width(), Terrain.FORMATIONS.get_height())
        material.set_shader_parameter("atlas_bounds", Vector4(region.position.x / tex_size.x, region.position.y / tex_size.y, region.end.x / tex_size.x, region.end.y / tex_size.y))
        sprite.material = material
        materials.append(material)
        sprite.scale = Vector2((r.size.x+12)/sprite.texture.get_width(),(r.size.y+12)/sprite.texture.get_height())
        add_child(sprite)
        sprites.append(sprite)
    get_viewport().size_changed.connect(_resize)
    _resize()

func _resize() -> void:
    view_width = get_viewport_rect().size.x
    set_camera(camera_x, visible)

func set_camera(next_x: float, show_rocks: bool) -> void:
    camera_x = next_x
    queue_redraw()
    visible = show_rocks
    if not show_rocks:
        return
    for i in range(sprites.size()):
        var r := positions[i]
        var sx := r.position.x - camera_x - 6.0
        var sprite := sprites[i]
        sprite.position = Vector2(sx, r.position.y - 6.0)
        sprite.visible = sx > -350.0 and sx < view_width + 350.0

func set_quality(high: bool) -> void:
    for material in materials:
        material.set_shader_parameter("high_quality", high)

func _draw() -> void:
    Terrain.seabed(self,get_viewport_rect().size,camera_x,"highland")
    for i in range(positions.size()):
        var r := positions[i]
        var rect := Rect2(r.position-Vector2(camera_x,0),r.size)
        if rect.end.x < -40 or rect.position.x > view_width+40: continue
        var floor_rock := r.position.y>450
        if floor_rock:
            var foot := maxf(r.end.y,Terrain.GROUND_Y+10)
            sprites[i].scale.y = (foot-r.position.y+6)/sprites[i].texture.get_height()
            Terrain.contact(self,Vector2(rect.get_center().x,Terrain.GROUND_Y+3),r.size.x,.4)
        else:
            Terrain.support(self,rect,"highland")

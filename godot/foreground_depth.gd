extends Node2D
## Sparse close-plane foreground silhouettes. The outer edges provide depth cues
## without painting over Sarah, the HUD or the original gameplay targets.
const Terrain = preload("res://godot/terrain_painter.gd")
const Art = preload("res://godot/environment_art.gd")
const REEF_SHADER: Shader = preload("res://godot/shaders/reef_material.gdshader")
var entries: Array[Dictionary] = []
var camera_x := 0.0
var screen_size := Vector2(1400, 960)
var reduced_motion := false
var active := true
var last_camera := -999999.0
var sway_clock := 0.0
var sway_accumulator := 0.0
var placement_updates := 0

func _ready() -> void:
    z_index = 2
    screen_size = get_viewport_rect().size
    var material := ShaderMaterial.new()
    material.shader = REEF_SHADER
    material.set_shader_parameter("water_tint", Color("#1b535b"))
    material.set_shader_parameter("distance_fog", 0.06)
    material.set_shader_parameter("relief", 0.17)
    for i in range(18):
        var sprite := Sprite2D.new()
        sprite.name = "Foreground_%02d" % i
        sprite.texture = Art.garden(i * 3)
        sprite.scale = Vector2.ONE * (210.0 + float(i % 4) * 24.0) / sprite.texture.get_width()
        sprite.offset.y = -sprite.texture.get_height() * 0.5
        sprite.material = material
        sprite.modulate.a = 0.82 + float(i % 3) * 0.025
        sprite.flip_h = i % 2 == 0
        add_child(sprite)
        entries.append({"sprite": sprite, "x": 290.0 + float(i) * 1170.0, "phase": float(i) * 0.77})
    get_viewport().size_changed.connect(_update_size)
    _update_size()

func _update_size() -> void:
    screen_size = get_viewport_rect().size
    last_camera = -999999.0
    set_camera(camera_x, active, reduced_motion)

func _process(dt: float) -> void:
    if not active or reduced_motion:
        return
    sway_clock += minf(dt, 0.05)
    sway_accumulator += minf(dt, 0.05)
    if sway_accumulator < 1.0 / 24.0:
        return
    sway_accumulator = 0.0
    for entry in entries:
        var sprite: Sprite2D = entry["sprite"]
        if sprite.visible:
            sprite.rotation = sin(sway_clock * 0.7 + float(entry["phase"])) * 0.017

func set_camera(world_camera: float, enabled: bool, reduce_motion: bool) -> void:
    camera_x = world_camera
    active = enabled
    if reduce_motion != reduced_motion:
        last_camera = -999999.0
    reduced_motion = reduce_motion
    visible = active
    if not active:
        return
    if absf(camera_x - last_camera) < 2.0:
        return
    last_camera = camera_x
    placement_updates += 1
    queue_redraw()
    for entry in entries:
        var sprite: Sprite2D = entry["sprite"]
        var world_x := float(entry["x"])
        var factor := 1.13
        var sx := (world_x - camera_x) * factor + screen_size.x * 0.5 * (1.0 - factor)
        sprite.position = Vector2(sx,Terrain.ground_y(world_x,909.0)+6.0)
        sprite.visible = sx > -160.0 and sx < screen_size.x + 160.0
        if reduced_motion:
            sprite.rotation = 0.0

func _draw() -> void:
    for entry in entries:
        var sprite: Sprite2D = entry["sprite"]
        if sprite.visible: Terrain.contact(self,sprite.position-Vector2(0,5),sprite.texture.get_width()*sprite.scale.x,.24)

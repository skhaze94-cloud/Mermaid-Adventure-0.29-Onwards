extends Node2D
## Level 1 2.5D compositor: opaque painted world + separately shaded garden planes.
## One opaque painted foundation; each biome has its own artwork.
const BACKGROUND: Texture2D = preload("res://godot/assets/environment-lake-v011.webp")
const GROTTO: Texture2D = preload("res://godot/assets/environment-grotto-v011.webp")
const GroundPlane = preload("res://godot/reef_ground_plane.gd")
const Terrain = preload("res://godot/terrain_painter.gd")
const Art = preload("res://godot/environment_art.gd")
const PAINTED_SHADER: Shader = preload("res://godot/shaders/painted_depth.gdshader")
const REEF_SHADER: Shader = preload("res://godot/shaders/reef_material.gdshader")
const LEVEL_WIDTH := 20748.0
const WATER_LINE := 280.0
var background: TextureRect
var background_material: ShaderMaterial
var far_gardens: Node2D
var middle_gardens: Node2D
var far_entries: Array[Dictionary] = []
var middle_entries: Array[Dictionary] = []
var screen_size := Vector2(1400, 960)
var camera_x := 0.0
var grotto := false
var reduced_motion := false
var tone := 0.0
var last_camera := -100000.0
var last_grotto := false
var last_reduced := false
var animation_accumulator := 0.0
var animation_clock := 0.0
var placement_updates := 0
var sway_updates := 0

func _ready() -> void:
    z_index = -3
    screen_size = get_viewport_rect().size
    background = TextureRect.new()
    background.name = "SingleOpaquePaintedBackdrop"
    background.texture = BACKGROUND
    background.stretch_mode = TextureRect.STRETCH_SCALE
    background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    background_material = ShaderMaterial.new()
    background_material.shader = PAINTED_SHADER
    background.material = background_material
    add_child(background)
    far_gardens = Node2D.new()
    far_gardens.name = "FarReefPlane_0_58Parallax"
    add_child(far_gardens)
    middle_gardens = Node2D.new()
    middle_gardens.name = "MidReefPlane_0_83Parallax"
    add_child(middle_gardens)
    _make_plane(far_gardens, far_entries, 25, 775.0, 0.58, 0.22, Color("#77bfc8"), 0.58)
    _make_plane(middle_gardens, middle_entries, 33, 590.0, 0.83, 0.13, Color("#6bcab8"), 0.88)
    get_viewport().size_changed.connect(_resize)
    _resize()
    set_camera(0.0, false, false)

func _make_plane(parent: Node2D, entries: Array[Dictionary], count: int,
        spacing: float, factor: float, fog: float, colour: Color, opacity: float) -> void:
    var material := ShaderMaterial.new()
    material.shader = REEF_SHADER
    material.set_shader_parameter("water_tint", colour)
    material.set_shader_parameter("distance_fog", fog)
    var ground := GroundPlane.new()
    ground.name = "RootedReefTerrace"
    ground.factor = factor
    ground.base_y = 844.0 if factor < .7 else 879.0
    ground.opacity = .30 if factor < .7 else .60
    ground.entries = entries
    parent.add_child(ground)
    parent.set_meta("ground_plane",ground)
    for i in range(count):
        # Hand-aligned gentle distribution instead of stacked transparent scenery.
        var atlas := Art.garden(i * 5 + 2)
        var cell_size := atlas.region.size
        var sprite := Sprite2D.new()
        sprite.name = "Garden_%02d" % i
        sprite.texture = atlas
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
        sprite.material = material
        var width := (178.0 + float(i % 5) * 31.0) * (0.78 if factor < 0.7 else 1.0)
        var height := (205.0 + float(i % 4) * 28.0) * (0.78 if factor < 0.7 else 1.0)
        sprite.scale = Vector2.ONE * minf(width / cell_size.x, height / cell_size.y)
        sprite.offset.y = -cell_size.y * 0.5
        sprite.modulate.a = opacity
        sprite.flip_h = i % 3 == 1
        parent.add_child(sprite)
        var source_world := 520.0 + float(i) * spacing + float((i * 47) % 103)
        entries.append({"sprite": sprite, "source_x": source_world,
            "base_y": ground.base_y,
            "factor": factor, "phase": float(i) * 0.73})

func _resize() -> void:
    screen_size = get_viewport_rect().size
    # Overscan avoids exposing the right edge during maximum 2.5D travel.
    background.position = Vector2(-50.0, 0.0)
    background.size = screen_size + Vector2(120.0, 0.0)
    background_material.set_shader_parameter("surface_y", clampf(WATER_LINE / maxf(screen_size.y, 1.0), 0.0, 0.7))
    last_camera = -100000.0
    set_camera(camera_x, grotto, reduced_motion)

func _process(delta: float) -> void:
    if reduced_motion:
        return
    animation_clock += minf(delta, 0.05)
    animation_accumulator += minf(delta, 0.05)
    if animation_accumulator < 1.0 / 24.0:
        return
    animation_accumulator = 0.0
    sway_updates += 1
    # Animate only visible plants, never the full 58-sprite level.
    for entry in far_entries:
        var sprite: Sprite2D = entry["sprite"]
        if sprite.visible:
            sprite.rotation = sin(animation_clock * 1.16 + float(entry["phase"])) * 0.015
    for entry in middle_entries:
        var sprite: Sprite2D = entry["sprite"]
        if sprite.visible:
            sprite.rotation = sin(animation_clock * 1.27 + float(entry["phase"])) * 0.026

func set_camera(world_camera: float, is_grotto: bool, reduce_motion: bool) -> void:
    camera_x = world_camera
    grotto = is_grotto
    reduced_motion = reduce_motion
    var profile_changed := last_grotto != grotto or last_reduced != reduced_motion
    if profile_changed:
        background.texture = GROTTO if grotto else BACKGROUND
        if reduced_motion:
            for entry in far_entries + middle_entries:
                entry["sprite"].rotation = 0.0
        background_material.set_shader_parameter("grotto_mix", 1.0 if grotto else 0.0)
        background_material.set_shader_parameter("motion_enabled", 0.0 if reduced_motion else 1.0)
        last_grotto = grotto
        last_reduced = reduced_motion
    # Ignore subpixel camera changes: the current scene already moves smoothly.
    if absf(camera_x - last_camera) < 2.0:
        return
    last_camera = camera_x
    placement_updates += 1
    background_material.set_shader_parameter("camera_progress",
        clampf(camera_x / maxf(1.0, LEVEL_WIDTH - screen_size.x), 0.0, 1.0))
    background.position.x = -50.0 - camera_x / LEVEL_WIDTH * 24.0
    for plane in [far_gardens,middle_gardens]:
        var ground: Node2D = plane.get_meta("ground_plane")
        ground.camera = camera_x
        ground.queue_redraw()
    for entry in far_entries:
        _position_entry(entry)
    for entry in middle_entries:
        _position_entry(entry)

func _position_entry(entry: Dictionary) -> void:
    var sprite: Sprite2D = entry["sprite"]
    var x := float(entry["source_x"])
    var factor := float(entry["factor"])
    var screen_x := (x - camera_x) * factor + screen_size.x * 0.5 * (1.0 - factor)
    sprite.position = Vector2(screen_x,Terrain.ground_y(screen_x+camera_x*factor,float(entry["base_y"]))+5.0)
    sprite.visible = screen_x > -300.0 and screen_x < screen_size.x + 300.0

func set_quality(high: bool) -> void:
    background_material.set_shader_parameter("high_quality", high)


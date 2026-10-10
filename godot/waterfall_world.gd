extends Node2D
## Single opaque painting, restrained depth and phase-aware crossfades.
const ART: Texture2D = preload("res://godot/assets/waterfall-cavern-v07.webp")
const SHADER: Shader = preload("res://godot/shaders/waterfall_cavern.gdshader")
var background: TextureRect
var material_resource: ShaderMaterial
var last_progress := -1.0
var last_reduced := false
var last_quality := true

func _ready() -> void:
    z_index = -2
    background = TextureRect.new()
    background.name = "DedicatedPaintedWaterfall"
    background.texture = ART
    # Stretch the composition, rather than cropping away a whole cliff face
    # on ultrawide phones. Gameplay keeps its independent collision bounds.
    background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background.stretch_mode = TextureRect.STRETCH_SCALE
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    material_resource = ShaderMaterial.new()
    material_resource.shader = SHADER
    background.material = material_resource
    add_child(background)
    get_viewport().size_changed.connect(_resize)
    _resize()
    visible = false

func _resize() -> void:
    background.size = get_viewport_rect().size

func set_phase(phase: String, elapsed: float, reduced: bool, high_quality: bool) -> void:
    visible = not phase.is_empty()
    if not visible:
        return
    var progress := clampf(elapsed / 17.0, 0.0, 1.0) if phase == "descent" else (1.0 if phase == "outflow" else 0.0)
    if absf(progress - last_progress) > 0.001:
        material_resource.set_shader_parameter("descent_progress", progress)
        last_progress = progress
    material_resource.set_shader_parameter("motion_enabled", 0.0 if reduced else 1.0)
    material_resource.set_shader_parameter("effect_strength", 1.0 if high_quality else 0.0)
    var opacity := 1.0
    if phase == "pull":
        opacity = smoothstep(0.0, 1.8, elapsed)
    elif phase == "outflow":
        opacity = 1.0 - smoothstep(0.0, 1.6, elapsed)
    modulate.a = opacity
    material_resource.set_shader_parameter("phase_opacity", opacity)


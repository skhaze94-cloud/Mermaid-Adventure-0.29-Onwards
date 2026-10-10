extends Node2D
## Native 2.5D compositor: refraction -> caustics -> volumetric mist -> impact feedback.
## Screen-space overlays render after terrain but before Sarah and Carlo.
const CAUSTICS: Shader = preload("res://godot/shaders/underwater_caustics.gdshader")
const REFRACTION: Shader = preload("res://godot/shaders/subtle_refraction.gdshader")
const MIST: Shader = preload("res://godot/shaders/depth_mist.gdshader")
const CINEMATIC: Shader = preload("res://godot/shaders/cinematic_grade.gdshader")
var refract_overlay: ColorRect
var refract_material: ShaderMaterial
var mist_overlay: ColorRect
var mist_material: ShaderMaterial
var cinematic_overlay: ColorRect
var cinematic_material: ShaderMaterial
var caustics_material: ShaderMaterial
var high_quality := true
var water_overlay: ColorRect
var flash_tween: Tween
var impact_overlay: ColorRect
var trail: CPUParticles2D
var bubble_texture: Texture2D
var reduced_motion := false
var viewport_size := Vector2.ZERO
const BURST_POOL_SIZE := 10
var burst_pool: Array[CPUParticles2D] = []
var burst_cursor := 0
var burst_events := 0
var last_grotto := false
var depth_profile_initialized := false

func _ready() -> void:
    bubble_texture = _make_bubble_texture()
    # Screen refraction is placed first to sample only world elements.
    refract_overlay = ColorRect.new()
    refract_overlay.name = "SubtleScreenSpaceRefraction"
    refract_overlay.color = Color.WHITE
    refract_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    refract_material = ShaderMaterial.new()
    refract_material.shader = REFRACTION
    refract_overlay.material = refract_material
    add_child(refract_overlay)

    water_overlay = ColorRect.new()
    water_overlay.name = "RealtimeUnderwaterCaustics"
    water_overlay.color = Color.WHITE
    water_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    caustics_material = ShaderMaterial.new()
    caustics_material.shader = CAUSTICS
    caustics_material.set_shader_parameter("caustic_strength", 0.10)
    water_overlay.material = caustics_material
    add_child(water_overlay)
    mist_overlay = ColorRect.new()
    mist_overlay.name = "DepthMistAndSoftLightBeams"
    mist_overlay.color = Color.WHITE
    mist_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    mist_material = ShaderMaterial.new()
    mist_material.shader = MIST
    mist_overlay.material = mist_material
    add_child(mist_overlay)
    cinematic_overlay = ColorRect.new()
    cinematic_overlay.name = "CinematicDepthEdgeGrade"
    cinematic_overlay.color = Color.WHITE
    cinematic_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    cinematic_material = ShaderMaterial.new()
    cinematic_material.shader = CINEMATIC
    cinematic_overlay.material = cinematic_material
    add_child(cinematic_overlay)
    impact_overlay = ColorRect.new()
    impact_overlay.name = "TweenedHitFlash"
    impact_overlay.color = Color("#ffe7ca")
    impact_overlay.modulate.a = 0.0
    impact_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(impact_overlay)
    trail = CPUParticles2D.new()
    trail.name = "SwimBubbleParticles"
    trail.texture = bubble_texture
    trail.amount = 26
    trail.lifetime = 1.3
    trail.speed_scale = 1.0
    trail.explosiveness = 0.0
    trail.direction = Vector2(-1, -0.45)
    trail.spread = 28.0
    trail.gravity = Vector2(0.0, -42.0)
    trail.initial_velocity_min = 8.0
    trail.initial_velocity_max = 46.0
    trail.scale_amount_min = 0.35
    trail.scale_amount_max = 0.95
    trail.color = Color(0.73, 1.0, 0.96, 0.45)
    trail.emitting = false
    add_child(trail)
    # Reuse a fixed pool: neither bursts nor one-shot timers allocate during play.
    for i in range(BURST_POOL_SIZE):
        var burst := CPUParticles2D.new()
        burst.name = "PooledImpact_%02d" % i
        burst.texture = bubble_texture
        burst.one_shot = true
        burst.amount = 20
        burst.lifetime = 0.65
        burst.explosiveness = 1.0
        burst.direction = Vector2.UP
        burst.spread = 180.0
        burst.initial_velocity_min = 45.0
        burst.initial_velocity_max = 160.0
        burst.gravity = Vector2(0.0, -28.0)
        burst.scale_amount_min = 0.45
        burst.scale_amount_max = 1.25
        burst.emitting = false
        add_child(burst)
        burst_pool.append(burst)
    get_viewport().size_changed.connect(_fit_viewport)
    _fit_viewport()

func _fit_viewport() -> void:
    viewport_size = get_viewport_rect().size
    water_overlay.size = viewport_size
    refract_overlay.size = viewport_size
    mist_overlay.size = viewport_size
    cinematic_overlay.size = viewport_size
    impact_overlay.size = viewport_size
    var line := clampf(280.0 / maxf(1.0, viewport_size.y), 0.0, 0.7)
    refract_material.set_shader_parameter("surface_y", line)
    mist_material.set_shader_parameter("surface_y", line)
    cinematic_material.set_shader_parameter("surface_y", line)
    caustics_material.set_shader_parameter("water_surface", line)

func _make_bubble_texture() -> Texture2D:
    var im := Image.create(16, 16, false, Image.FORMAT_RGBA8)
    im.fill(Color.TRANSPARENT)
    for y in range(16):
        for x in range(16):
            var dist := Vector2(float(x) - 7.5, float(y) - 7.5).length()
            if dist <= 6.9:
                var rim := smoothstep(4.6, 6.8, dist)
                var highlight := maxf(0.0, 1.0 - Vector2(float(x)-5.1, float(y)-4.9).length() / 4.5)
                im.set_pixel(x, y, Color(0.67 + 0.28 * highlight, 0.90 + 0.1 * highlight,
                    1.0, minf(1.0, rim * 0.64 + highlight * 0.58 + 0.03)))
    return ImageTexture.create_from_image(im)

func set_motion(screen_position: Vector2, velocity: Vector2, in_water: bool) -> void:
    trail.position = screen_position - velocity.normalized() * 50.0
    trail.direction = (-velocity.normalized() + Vector2(0, -0.45)).normalized()
    trail.emitting = not reduced_motion and in_water and velocity.length() > 55.0

func splash(screen_position: Vector2, tint: Color = Color("#b8ffef"), count: int = 20) -> void:
    if reduced_motion:
        return
    # Round-robin particle pool is bounded even during heavy collision chains.
    var burst: CPUParticles2D = burst_pool[burst_cursor]
    burst_cursor = (burst_cursor + 1) % BURST_POOL_SIZE
    burst.amount = mini(maxi(count, 1), 48)
    burst.position = screen_position
    burst.color = tint
    burst.emitting = false
    burst.restart()
    burst.emitting = true
    burst_events += 1

func flash(tint: Color = Color("#ffb3c0"), intensity: float = 0.22, duration: float = 0.28) -> void:
    if reduced_motion:
        return
    impact_overlay.color = tint
    impact_overlay.modulate.a = intensity
    if flash_tween and flash_tween.is_running():
        flash_tween.kill()
    flash_tween = create_tween()
    flash_tween.tween_property(impact_overlay, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func set_depth_profile(is_grotto: bool) -> void:
    if depth_profile_initialized and last_grotto == is_grotto:
        return
    last_grotto = is_grotto
    depth_profile_initialized = true
    mist_material.set_shader_parameter("grotto_mix", 1.0 if is_grotto else 0.0)
    cinematic_material.set_shader_parameter("cavern_mix", 1.0 if is_grotto else 0.0)
    mist_material.set_shader_parameter("mist_amount", 0.095 if is_grotto else 0.065)
    refract_material.set_shader_parameter("distortion_px", 1.0 if is_grotto else 1.25)

func set_quality(high: bool) -> void:
    high_quality = high
    refract_overlay.visible = high_quality and not reduced_motion
    mist_overlay.visible = high_quality and not reduced_motion
    cinematic_overlay.visible = high_quality
    water_overlay.visible = not reduced_motion
    caustics_material.set_shader_parameter("caustic_strength", 0.10 if high_quality else 0.06)

func set_reduced_motion(enabled: bool) -> void:
    reduced_motion = enabled
    water_overlay.visible = not enabled
    refract_overlay.visible = not enabled and high_quality
    mist_overlay.visible = not enabled and high_quality
    cinematic_overlay.visible = high_quality
    caustics_material.set_shader_parameter("speed", 0.0 if enabled else 0.65)
    refract_material.set_shader_parameter("motion_enabled", 0.0 if enabled else 1.0)
    mist_material.set_shader_parameter("motion_enabled", 0.0 if enabled else 1.0)
    trail.emitting = not enabled and trail.emitting

func reset_transients() -> void:
    if flash_tween and flash_tween.is_running():
        flash_tween.kill()
    impact_overlay.modulate.a = 0.0
    trail.emitting = false
    for burst in burst_pool:
        burst.emitting = false
        burst.restart()
        burst.emitting = false

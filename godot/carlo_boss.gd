extends Node2D
## Articulated Carlo with two opposed jaw hinges, legs and native combat cues.
const CreatureSkin = preload("res://godot/creature_skin.gd")
const Art = preload("res://godot/creature_art.gd")
var surface: ShaderMaterial
var last_pose := -1
var sprite: MeshInstance2D
var light: PointLight2D
var sparkle: Sprite2D
var clock := 0.0
var active := false
var vulnerable := false
var life := 5
var defeating := false
var defeat_tween: Tween
var hit_tween: Tween
var boss_scale := Vector2.ONE
var reduced_motion := false
var previous_clock := 0.0
var pose_started := -1.0

func _ready() -> void:
    sprite = CreatureSkin.new()
    sprite.name = "PaintedCarlo"
    sprite.configure("carlo")
    surface = sprite.surface
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    add_child(sprite)
    light = PointLight2D.new()
    light.name = "VulnerabilityLight"
    light.texture = _light_texture()
    light.texture_scale = 2.3
    light.energy = 0.20
    light.color = Color("#ff8775")
    add_child(light)
    visible = false

func _light_texture() -> Texture2D:
    var img := Image.create(96, 96, false, Image.FORMAT_RGBA8)
    img.fill(Color.TRANSPARENT)
    for y in range(96):
        for x in range(96):
            var dist := Vector2(float(x) - 47.5, float(y) - 47.5).length() / 47.5
            if dist < 1.0:
                var falloff := pow(1.0 - smoothstep(0.0, 1.0, dist), 1.6)
                img.set_pixel(x, y, Color(1.0, 1.0, 1.0, falloff))
    return ImageTexture.create_from_image(img)

func set_boss_state(hp: int, can_hit: bool, global_clock: float, screen_x: float, screen_y: float, screen_width: float, mode: String = "windup", pattern: int = 0) -> void:
    life = hp
    vulnerable = can_hit
    clock = global_clock
    var dt := clampf(clock-previous_clock,0.0,.05)
    previous_clock = clock
    position = Vector2(screen_x, screen_y)
    visible = (hp > 0 or defeating) and screen_x > -320.0 and screen_x < screen_width + 320.0
    light.color = Color("#7cffad") if vulnerable else Color("#ff9d92")
    light.energy = (0.9 if vulnerable else 0.22) * (1.0 if reduced_motion else 0.85 + 0.15 * sin(clock * 3.8))
    var pose := Art.pose(mode)
    if pose != last_pose:
        pose_started = clock
        last_pose = pose
    sprite.animate(mode,clock,dt,0.0,reduced_motion,true,true,maxf(0.0,clock-pose_started))
    if not defeating:
        var target_rotation := sin(clock * 1.8) * 0.025
        if pose == 2: target_rotation += 0.09 if pattern == 0 else -0.06
        sprite.rotation = 0.0 if reduced_motion else lerp_angle(sprite.rotation,target_rotation,1.0-exp(-dt*12.0))
        sprite.position = Vector2.ZERO if reduced_motion else Vector2(0, sin(clock * 2.3) * 3.0)

func play_hit() -> void:
    if hit_tween and hit_tween.is_running():
        hit_tween.kill()
    sprite.self_modulate = Color("#fffae2")
    var base := Art.region("carlo",0).size*Art.base_scale("carlo")
    hit_tween = create_tween()
    hit_tween.tween_property(sprite, "scale", base if reduced_motion else base * 1.12, 0.08).set_trans(Tween.TRANS_CUBIC)
    hit_tween.tween_property(sprite, "scale", base, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    hit_tween.parallel().tween_property(sprite, "self_modulate", Color.WHITE, 0.3)

func defeat() -> void:
    defeating = true
    if hit_tween and hit_tween.is_running():
        hit_tween.kill()
    defeat_tween = create_tween()
    defeat_tween.tween_property(sprite, "modulate:a", 0.0, 0.7).set_trans(Tween.TRANS_CUBIC)
    if not reduced_motion: defeat_tween.parallel().tween_property(sprite, "rotation", 0.25, 0.7)
    defeat_tween.tween_callback(func() -> void:
        visible = false
        defeating = false
    )

func reset_boss() -> void:
    if defeat_tween and defeat_tween.is_running():
        defeat_tween.kill()
    if hit_tween and hit_tween.is_running():
        hit_tween.kill()
    defeating = false
    sprite.modulate = Color.WHITE
    sprite.self_modulate = Color.WHITE
    sprite.rotation = 0.0
    previous_clock = 0.0
    pose_started = -1.0
    last_pose = -1
    sprite.reset_motion()
    sprite.scale = Art.region("carlo",0).size*Art.base_scale("carlo")
    visible = false

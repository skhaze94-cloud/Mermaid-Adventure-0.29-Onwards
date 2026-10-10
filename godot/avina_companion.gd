extends Node2D
## A protected baby follower. Bubble is her only gameplay action.
const PORTRAIT = preload("res://godot/assets/characters-v027/avina-baby.png")
var follow_enabled := true
var level: Node2D
var world_position := Vector2.ZERO
var clock := 0.0
var cooldown := 0.0
var bubble_pending := false
var speech := ""
var speech_time := 0.0
var reaction := 0.0
var sprite: Sprite2D
var bubbles_cast := 0
var last_retry := -1
var joy_blend := 0.0
var follow_bank := 0.0

func _ready() -> void:
    z_index = 4
    sprite = Sprite2D.new()
    sprite.texture = PORTRAIT
    sprite.scale = Vector2.ONE * (120.0 / PORTRAIT.get_height())
    var material := ShaderMaterial.new()
    material.shader = preload("res://godot/shaders/baby_body.gdshader")
    sprite.material = material
    add_child(sprite)

func bind(owner_level: Node2D) -> void:
    level = owner_level
    reset_follow()

func reset_follow() -> void:
    if not is_instance_valid(level): return
    world_position = level.player + Vector2(-level.facing*115,45)
    cooldown = 0.0
    bubble_pending = false
    speech_time = 0.0
    joy_blend = 0.0
    follow_bank = 0.0
    last_retry = level.retry_serial

func say(line: String, duration := 3.0) -> void:
    speech = line
    speech_time = duration
    reaction = 0.65

func request_bubble() -> void:
    bubble_pending = true

func tick(dt: float) -> void:
    if not is_instance_valid(level): return
    clock += dt
    cooldown = maxf(0,cooldown-dt)
    speech_time = maxf(0,speech_time-dt)
    reaction = maxf(0,reaction-dt)
    if last_retry != level.retry_serial: reset_follow()
    var desired: Vector2 = level.player + Vector2(-level.facing*115,45)
    desired.y = clampf(desired.y,level._water_line()+82,820)
    desired.x = clampf(desired.x,level._left_bound()+30,level._level_length()-60)
    if follow_enabled and world_position.distance_to(desired)>900: world_position = desired
    var previous := world_position
    if follow_enabled: world_position = world_position.lerp(desired,1-exp(-dt*4.8))
    position = world_position-Vector2(level.camera,0)
    if level.waterfall_phase != "":
        position = level._hero_screen_position()+Vector2(-level.facing*105,66)
    var gentle: bool = level.reduced_fx
    var ease := 1.0-exp(-minf(dt,.05)*12.0)
    joy_blend = lerpf(joy_blend,reaction,ease)
    var bank := clampf((world_position.x-previous.x)/maxf(dt,.001)/3000.0,-.06,.06)
    follow_bank = lerpf(follow_bank,bank,ease)
    sprite.flip_h = level.facing < 0
    sprite.position.y = 0 if gentle else sin(clock*2.4)*3
    sprite.rotation = 0 if gentle else sin(clock*2.4)*0.025 + joy_blend*0.06 + follow_bank
    sprite.material.set_shader_parameter("wiggle",0.0 if gentle else sin(clock*4.0)*0.018)
    sprite.material.set_shader_parameter("clock",clock)
    sprite.material.set_shader_parameter("joy",joy_blend)
    sprite.material.set_shader_parameter("strength",0.0 if gentle else 1.0)
    # Babies never ram, jump, take damage, collide, collect or touch bosses.
    if follow_enabled and cooldown<=0 and level.state=="playing" and level.waterfall_phase=="":
        var target_near := false
        for enemy in level.enemies:
            var offset: Vector2 = Vector2(enemy.x,enemy.y)-world_position
            if int(enemy.hp)>0 and offset.x*level.facing>30 and offset.x*level.facing<430 and absf(offset.y)<55:
                target_near = true
                break
        if bubble_pending or target_near:
            _little_bubble()
    queue_redraw()

func _little_bubble() -> void:
    if level.bubble_shots.size()>=8: return
    cooldown = 2.8
    bubble_pending = false
    bubbles_cast += 1
    level.bubble_shots.append({"pos":world_position+Vector2(level.facing*36,-7),"direction":level.facing,"life":1.3,"baby":true})
    level.native_fx.splash(position+Vector2(level.facing*36,-7),Color("f3cbff"),4)
    level._sfx("bubble",0)
    if bubbles_cast%4==1: say("Buh-buh!",1.8)
    reaction = 0.8

func _draw() -> void:
    if speech_time<=0: return
    var font := ThemeDB.fallback_font
    var width := font.get_string_size(speech,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
    var rect := Rect2(-width*.5-10,-92,width+20,30)
    draw_style_box(_speech_style(),rect)
    draw_string(font,Vector2(-width*.5,-71),speech,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("503d6e"))

func _speech_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("fff6ff")
    style.set_corner_radius_all(13)
    return style

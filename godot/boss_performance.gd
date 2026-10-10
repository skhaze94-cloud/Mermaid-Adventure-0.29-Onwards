extends Node2D
## Visual performance only. Combat owns the true boss position and hit radius.
const CreatureSkin = preload("res://godot/creature_skin.gd")
var body: MeshInstance2D
var previous_clock := -1.0
var surface: ShaderMaterial
var base_size := Vector2.ONE
var last_life := -1
var hit_age := 10.0
var defeat_age := -1.0
var last_position := Vector2.ZERO
var reduced := false
var pose := "windup"
var motion_clock := 0.0
var profile := ""
var source_art: Texture2D
var windup_mix := 0.0
var attack_mix := 0.0
var detail_strength := 1.0

func _ready() -> void:
    z_index = 2
    body = CreatureSkin.new()
    body.mesh = CreatureSkin.geometry()
    add_child(body)
    visible = false

func configure(art: Texture2D, bounds: Vector2, kind: String) -> void:
    profile = kind
    source_art = art
    body.configure(kind,art,bounds)
    surface = body.surface
    base_size = body.scale

func set_state(life: int, mode: String, at: Vector2, clock: float, gentle: bool) -> void:
    reduced = gentle
    pose = mode
    var dt := 0.0 if previous_clock<0 else clampf(clock-previous_clock,0.0,.10)
    previous_clock = clock
    motion_clock = clock
    body.animate(mode,clock,dt,0.0,gentle)
    if last_life >= 0 and life < last_life:
        hit_age = 0
        if life <= 0: defeat_age = 0
    elif life > last_life:
        hit_age = 10
        defeat_age = -1
    last_life = life
    if life > 0: last_position = at
    position = last_position
    visible = (life > 0 or (defeat_age >= 0 and defeat_age < 0.85)) and at.x > -600 and at.x < get_viewport_rect().size.x+600
    _apply_pose()

func _process(dt: float) -> void:
    hit_age += dt
    if defeat_age >= 0: defeat_age += dt
    var ease := 1.0-exp(-minf(dt,.05)*12.0)
    windup_mix = lerpf(windup_mix,1.0 if pose=="windup" else 0.0,ease)
    attack_mix = lerpf(attack_mix,1.0 if pose=="attack" else 0.0,ease)
    detail_strength = lerpf(detail_strength,0.45 if pose=="recover" else 1.0,ease)
    _apply_pose()

func _apply_pose() -> void:
    if not body or not surface: return
    var pulse := maxf(0,1-hit_age/0.28)
    var breath := 0.0 if reduced else sin(motion_clock*1.8)*0.018
    var anticipation := 0.0 if reduced else windup_mix*(0.020+sin(motion_clock*4)*0.010)
    body.scale = base_size*Vector2(1+breath+anticipation+pulse*.065,1-breath-anticipation-pulse*.04)
    body.rotation = 0.0 if reduced else sin(motion_clock*1.4)*0.020+(attack_mix*.06 if profile in ["nessie","blackwater","flip"] else 0.0)
    surface.set_shader_parameter("strength",0.0 if reduced else detail_strength)
    surface.set_shader_parameter("attack_mix",attack_mix)
    surface.set_shader_parameter("hit",pulse)
    if defeat_age >= 0:
        modulate.a = maxf(0,1-defeat_age/0.85)
        body.position.y = 0 if reduced else -defeat_age*45
        visible = visible and defeat_age < 0.85
    else:
        modulate.a = 1
        body.position = Vector2.ZERO

func set_region(region: Rect2) -> void:
    body.set_region(region)

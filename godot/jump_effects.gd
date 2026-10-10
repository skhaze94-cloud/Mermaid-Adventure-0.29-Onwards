extends Node2D
## Bounded native Line2D ribbons, ripple crowns and ballistic surface droplets.
const POOL_SIZE := 4
const TRAIL_LIMIT := 20
var ribbon: Line2D
var accent: Line2D
var droplets: Array[CPUParticles2D] = []
var ripples: Array[Line2D] = []
var origins: Array[Vector2] = []
var ages: Array[float] = []
var world_points := PackedVector2Array()
var cursor := 0
var camera_x := 0.0
var elapsed := 0.0
var last_sample := -1.0
var last_air_clock := -10.0
var reduced_motion := false
var high_quality := true
var surface_events := 0
var last_surface := Vector2.ZERO

func _ready() -> void:
    ribbon = _line("AirborneFinRibbon",5.0,Color("#b4fff5"))
    accent = _line("AirbornePearlAccent",2.0,Color("#ffbde9"))
    var gradient := Gradient.new()
    gradient.set_color(0,Color(0.6,1.0,0.95,0.0))
    gradient.set_color(1,Color(0.6,1.0,0.95,0.48))
    ribbon.gradient = gradient
    var width := Curve.new()
    width.add_point(Vector2(0,0))
    width.add_point(Vector2(0.75,0.8))
    width.add_point(Vector2(1,0.2))
    ribbon.width_curve = width
    accent.width_curve = width
    var texture := _drop_texture()
    for i in range(POOL_SIZE):
        var spray := CPUParticles2D.new()
        spray.name = "SurfaceSpray_%d" % i
        spray.texture = texture
        spray.local_coords = true
        spray.one_shot = true
        spray.explosiveness = 1.0
        spray.amount = 32
        spray.lifetime = 0.65
        spray.direction = Vector2.UP
        spray.spread = 60.0
        spray.initial_velocity_min = 170.0
        spray.initial_velocity_max = 300.0
        spray.gravity = Vector2(0,850)
        spray.scale_amount_min = 0.32
        spray.scale_amount_max = 0.70
        var fade := Gradient.new()
        fade.set_color(0,Color(0.72,1.0,1.0,0.88))
        fade.set_color(1,Color(0.72,1.0,1.0,0.0))
        spray.color_ramp = fade
        spray.emitting = false
        add_child(spray)
        droplets.append(spray)
        ripples.append(_line("SurfaceRipple_%d" % i,2.5,Color("#d5fffc")))
        origins.append(Vector2.ZERO)
        ages.append(10.0)

func _line(label: String, width: float, tint: Color) -> Line2D:
    var line := Line2D.new()
    line.name = label
    line.width = width
    line.default_color = tint
    line.antialiased = true
    line.begin_cap_mode = Line2D.LINE_CAP_ROUND
    line.end_cap_mode = Line2D.LINE_CAP_ROUND
    add_child(line)
    return line

func _drop_texture() -> Texture2D:
    var image := Image.create(16,16,false,Image.FORMAT_RGBA8)
    image.fill(Color.TRANSPARENT)
    for y in range(16):
        for x in range(16):
            var radius := Vector2((x-7.5)/3.8,(y-7.5)/6.8).length()
            if radius < 1.0:
                image.set_pixel(x,y,Color(0.78,1.0,1.0,1.0-smoothstep(0.7,1.0,radius)))
    return ImageTexture.create_from_image(image)

func emit_surface(world_position: Vector2, chain: int, landing: bool) -> void:
    if reduced_motion: return
    last_surface = world_position
    surface_events += 1
    var slot := cursor
    cursor = (cursor+1)%POOL_SIZE
    origins[slot] = world_position
    ages[slot] = 0.0
    var spray := droplets[slot]
    spray.position = world_position - Vector2(camera_x,0)
    spray.amount = (32 if landing else 22) + mini(chain,3) * 4 if high_quality else 12
    spray.initial_velocity_max = 320.0 if landing else 250.0
    spray.emitting = false
    spray.restart()
    spray.emitting = true

func update_jump(world_position: Vector2, camera: float, phase: String, clock: float,
        reduced: bool, quality: bool) -> void:
    if phase == "airborne": last_air_clock = clock
    var camera_delta := camera_x-camera
    camera_x = camera
    reduced_motion = reduced
    high_quality = quality
    for spray in droplets:
        # Particle coordinates follow camera pans, never Sarah's later motion.
        spray.position.x += camera_delta
        if reduced: spray.emitting = false
    if reduced or phase != "airborne":
        if reduced: world_points.clear()
        elif world_points.size() > 0 and clock-last_sample >= 1.0/30.0:
            world_points.remove_at(0)
            last_sample = clock
    elif clock-last_sample >= 1.0/30.0 or clock < last_sample:
        world_points.append(world_position)
        if world_points.size() > TRAIL_LIMIT: world_points.remove_at(0)
        last_sample = clock
    var points := PackedVector2Array()
    var accents := PackedVector2Array()
    # Four Catmull-Rom samples per segment soften the old angular trail.
    # Source history remains capped; Economy retains the simpler polyline.
    var samples := 4 if quality else 1
    for i in range(maxi(0,world_points.size()-1)):
        var a := world_points[maxi(0,i-1)]
        var b := world_points[i]
        var c := world_points[i+1]
        var d := world_points[mini(world_points.size()-1,i+2)]
        var normal := (c-b).normalized().orthogonal()
        for j in range(samples):
            var u := float(j)/samples
            var point := 0.5*((2.0*b)+(-a+c)*u+(2.0*a-5.0*b+4.0*c-d)*u*u+(-a+3.0*b-3.0*c+d)*u*u*u)
            point -= Vector2(camera_x,0)
            points.append(point)
            var along := (float(i)+u)/maxf(1.0,world_points.size()-1)
            var twist := sin(along*TAU*1.5-clock*3.0)*sin(along*PI)*7.0
            accents.append(point+normal*twist)
    if world_points.size() > 0:
        points.append(world_points[-1]-Vector2(camera_x,0))
        accents.append(points[-1])
    ribbon.points = points
    accent.points = accents
    var fade := 1.0 if phase == "airborne" else clampf(1.0-(clock-last_air_clock)/0.22,0.0,1.0)
    ribbon.modulate.a = fade
    accent.modulate.a = fade*0.60
    ribbon.visible = not reduced and points.size()>1 and fade > 0.0
    accent.visible = ribbon.visible and quality
    visible = not reduced

func _process(dt: float) -> void:
    elapsed += dt
    for i in range(POOL_SIZE):
        ages[i] += dt
        var age := ages[i]
        ripples[i].visible = age < 0.58 and not reduced_motion
        if not ripples[i].visible: continue
        var points := PackedVector2Array()
        var radius := 20.0+age*145.0
        for point in range(25):
            var angle := float(point)/24.0*TAU
            points.append(origins[i]-Vector2(camera_x,0)+Vector2(cos(angle)*radius,sin(angle)*radius*0.15))
        ripples[i].points = points
        ripples[i].modulate.a = (1.0-age/0.58)*0.7

func reset_jump() -> void:
    world_points.clear()
    ribbon.clear_points()
    accent.clear_points()
    for i in range(POOL_SIZE):
        droplets[i].emitting = false
        droplets[i].restart()
        droplets[i].emitting = false
        ages[i] = 10.0
        ripples[i].visible = false
    last_sample = -1.0
    last_air_clock = -10.0

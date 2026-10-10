extends Node2D
## Menu-reference face, continuous tail skin and articulated native painted limbs.
## Pose blending and anchored UVs preserve identity throughout every performance.
const TailSkin = preload("res://godot/sarah_tail_skin.gd")
const Cycles = preload("res://godot/sarah_pose_cycles.gd")
const NEW_TAIL = preload("res://godot/assets/sarah-tail-v019.webp")
const EXPRESSIONS = preload("res://godot/assets/sarah-expressions-v019.webp")
const FACE_REGIONS := [Rect2(15,80,710,570),Rect2(735,80,700,570),Rect2(1445,80,710,570)]
var face_sprite: Sprite2D
const FaceDetails = preload("res://godot/sarah_face_details.gd")
var face_details: Polygon2D
var detail_gaze := Vector2.ZERO
var expression_blend := 0.0
var blink_blend := 0.0
const SpineMotion = preload("res://godot/sarah_spine_motion.gd")
var spine_motion = SpineMotion.new()
const DefinitiveMotion = preload("res://godot/sarah_definitive_motion.gd")
var definitive_motion = DefinitiveMotion.new()
const TorsoMotion = preload("res://godot/sarah_torso_motion.gd")
var torso_motion = TorsoMotion.new()
var faces: Array[Texture2D] = []
var tail_skin: Polygon2D
var cycle_pose := Vector4.ZERO
var tail_tuck := 0.0
var pose_set := "idle"
var depth_bank := 0.0
var settle_blend := 0.0
var expression_index := 0

const ArmCycles = preload("res://godot/sarah_arm_cycles.gd")
const SwimStyles = preload("res://godot/sarah_swim_styles.gd")
var swim_style := "breaststroke"
var swim_style_override := "" # Deterministic previews/tests; gameplay uses direction.
var stroke_weights: Dictionary = {"breaststroke":1.0}
var stroke_candidate := "breaststroke"
var stroke_candidate_time := 0.0
var stroke_frequency := 2.9
var waterfall_context := ""
var visual_travel := Vector2.ZERO
var arm_pose_near := Vector3.ZERO
var arm_pose_far := Vector3.ZERO
var bodice: Polygon2D
const BODICE_BOUNDS := Rect2(-3,-40,60,60)
const BODICE_REGION := Rect2(8,19,240,218)
const ArmMesh = preload("res://godot/sarah_arm_mesh.gd")
const Ribbon = preload("res://godot/sarah_ribbon_mesh.gd")
const PERFORMANCE: AnimationLibrary = preload("res://godot/animations/sarah_magnifique.tres")
const VOLUME: Shader = preload("res://godot/shaders/sarah_volume.gdshader")
const SCALES: Shader = preload("res://godot/shaders/sarah_scales.gdshader")
const ATLAS: Texture2D = preload("res://dist/assets/sarah-parts-v81.webp")
const JUMP_LIBRARY: AnimationLibrary = preload("res://godot/animations/sarah_jump.tres")
const ARMS: Texture2D = preload("res://dist/assets/sarah-arms-refined-v81.webp")
const BODY_CROPS := [
    [0.0078125,0.0185546875,0.234375,0.212890625],
    [0.2578125,0.0107421875,0.234375,0.2275390625],
    [0.5078125,0.044921875,0.234375,0.16015625],
    [0.7578125,0.013671875,0.234375,0.2216796875],
    [0.0078125,0.30859375,0.234375,0.1318359375],
    [0.2578125,0.3173828125,0.234375,0.115234375],
    [0.51171875,0.296875,0.2265625,0.1552734375],
    [0.7578125,0.306640625,0.234375,0.1357421875],
    [0.0078125,0.56640625,0.234375,0.1171875],
    [0.2578125,0.544921875,0.234375,0.16015625],
    [0.5078125,0.56640625,0.234375,0.1171875],
    [0.7578125,0.5634765625,0.234375,0.123046875],
    [0.0078125,0.7783203125,0.234375,0.1923828125],
    [0.2578125,0.7744140625,0.234375,0.201171875],
    [0.5078125,0.822265625,0.234375,0.10546875],
    [0.7578125,0.7998046875,0.234375,0.150390625]
]
const ARM_CROPS := [
    [0.015625,0.201171875,0.46875,0.59765625],
    [0.515625,0.193359375,0.46875,0.611328125]
]
var back_hair: Node2D
var hair_strand: Node2D
var torso: Node2D
var head_joint: Node2D
var near_arm: Node2D
var far_arm: Node2D
var hero_light: PointLight2D
var velocity_value := Vector2.ZERO
var facing_value := 1.0
var boosting := false
var leaping := false
var alpha_value := 1.0
var clock := 0.0
var reduced_motion := false
# Blend weights are state, not extra textures or allocations per frame.
var swim_blend := 0.0
var boost_blend := 0.0
var leap_blend := 0.0
var turn_kick := 0.0
var hit_kick := 0.0
var smoothed_speed := 0.0
var animation_mode := "idle"
var last_facing := 1.0

# Timeline poses are independent of collision and input timing.
var jump_player: AnimationPlayer
var launch_curl := 0.0
var launch_stretch := 0.0
var landing_compress := 0.0
var jump_phase := ""
var jump_air_time := 0.0
var jump_chain := 0
var jump_direction := 1.0
var jump_pose_blend := 0.0
var spin_curve: Curve
var hair_drag := 0.0
var hair_drag_speed := 0.0
var previous_vertical_speed := 0.0
var body_pitch := 0.0

# Anchored hair/tail skins and additive, interruptible native gestures.
var ribbons: Array[Polygon2D] = []
var arm_meshes: Array[Polygon2D] = []
var ribbon_materials: Array[ShaderMaterial] = []
var gesture_player: AnimationPlayer
var gesture_wave := 0.0
var gesture_nod := 0.0
var gesture_reach := 0.0
var gesture_arch := 0.0
var high_quality := true
var swim_clock := 0.0
var mesh_was_active := false
var turn_elapsed := 1.0
var brake_blend := 0.0
var steering_value := Vector2.ZERO
var previous_speed := 0.0
var horizontal_drag := 0.0
var horizontal_drag_speed := 0.0
var idle_elapsed := 0.0
var last_gesture := ""
var jump_style := 0
var jump_style_cursor := 0
var jump_joy_near := 0.0
var jump_joy_far := 0.0
var corkscrew := 0.0
var depth_turn := 0.0
var volume_materials: Array[ShaderMaterial] = []
var painted_parts: Array[Node2D] = []

func set_steering(direction: Vector2) -> void:
    steering_value = direction.limit_length(1.0)

func set_waterfall_context(phase: String) -> void:
    waterfall_context = phase

func _update_stroke(dt: float, speed: float) -> void:
    visual_travel = visual_travel.lerp(velocity_value,1.0-exp(-dt*12.0))
    var requested := SwimStyles.choose(speed,visual_travel.y,swim_clock,boosting,waterfall_context)
    if swim_style_override in SwimStyles.NAMES: requested = swim_style_override
    if requested != stroke_candidate:
        stroke_candidate = requested
        stroke_candidate_time = 0.0
    stroke_candidate_time += dt
    # Direction noise must persist before changing strokes. Boost responds at once.
    if boosting or stroke_candidate_time >= .18:
        swim_style = stroke_candidate
    var blend := 1.0-exp(-dt*10.0)
    for style in SwimStyles.NAMES:
        stroke_weights[style] = lerpf(float(stroke_weights.get(style,0.0)),1.0 if style==swim_style else 0.0,blend)
    var frequency := 2.9+3.0*swim_blend+2.0*boost_blend
    if swim_style=="sidestroke": frequency *= .78
    elif swim_style=="dive_spear": frequency *= .82
    elif swim_style=="waterfall_scull": frequency = 4.5
    var cadence_decay := exp(-dt*7.0)
    var previous_frequency := stroke_frequency
    stroke_frequency = frequency+(previous_frequency-frequency)*cadence_decay
    # Integrate the eased cadence, rather than using its end-of-frame value.
    swim_clock += frequency*dt+(previous_frequency-frequency)*(1.0-cadence_decay)/7.0

func _blended_stroke(far: bool) -> Vector3:
    var result := Vector3.ZERO
    for style in SwimStyles.NAMES:
        var weight: float = stroke_weights.get(style,0.0)
        if weight > .00001:
            result += SwimStyles.sample(style,swim_clock,far)*weight
    return result

func set_quality(high: bool) -> void:
    high_quality = high
    for material in ribbon_materials:
        material.set_shader_parameter("motion_enabled", high and not reduced_motion)
    for material in volume_materials:
        material.set_shader_parameter("volume_enabled", high)

func play_gesture(action: String) -> void:
    if not gesture_player or not gesture_player.has_animation(action):
        return
    # Greeting/reward cannot interrupt a cast, impact or victory performance.
    if action in ["greet","reward"] and gesture_player.is_playing():
        return
    _clear_gesture_values()
    last_gesture = action
    gesture_player.play(action)
    gesture_player.advance(0.0)

func _clear_gesture_values() -> void:
    gesture_wave = 0.0
    gesture_nod = 0.0
    gesture_reach = 0.0
    gesture_arch = 0.0

func reset_performance() -> void:
    if gesture_player:
        gesture_player.stop()
    _clear_gesture_values()
    last_gesture = ""
    idle_elapsed = 0.0
    jump_style_cursor = 0
    jump_style = 0
    swim_clock = 0.0
    swim_style = "breaststroke"
    stroke_candidate = "breaststroke"
    stroke_candidate_time = 0.0
    stroke_frequency = 2.9
    stroke_weights = {"breaststroke":1.0}
    waterfall_context = ""
    visual_travel = Vector2.ZERO
    turn_elapsed = 1.0
    brake_blend = 0.0
    steering_value = Vector2.ZERO
    previous_speed = 0.0
    horizontal_drag = 0.0
    horizontal_drag_speed = 0.0
    hit_kick = 0.0
    turn_kick = 0.0
    swim_blend = 0.0
    boost_blend = 0.0
    leap_blend = 0.0
    smoothed_speed = 0.0
    velocity_value = Vector2.ZERO
    facing_value = 1.0
    last_facing = 1.0
    scale = Vector2.ONE
    rotation = 0.0
    for joint in [back_hair,hair_strand,torso,head_joint,near_arm,far_arm]:
        joint.rotation = 0.0
    _reset_depth_pose()
    torso.position = Vector2(12,24)
    for ribbon in ribbons + arm_meshes:
        ribbon.reset_shape()
    cycle_pose = Vector4.ZERO
    tail_tuck = 0
    pose_set = "idle"
    depth_bank = 0.0
    settle_blend = 0.0
    arm_pose_near = Vector3.ZERO
    arm_pose_far = Vector3.ZERO
    expression_index = 0
    spine_motion.reset()
    definitive_motion.reset()
    torso_motion.reset()
    tail_skin.root_bend=0.0
    near_arm.position=Vector2(22,-28)
    far_arm.position=Vector2(34,-25)
    if bodice: bodice.reset_shape()
    if head_joint:
        head_joint.position = Vector2(35.5,-28)
        head_joint.rotation = 0.0
    detail_gaze = Vector2.ZERO
    expression_blend = 0.0
    blink_blend = 0.0
    if face_details: face_details.reset_details()
    if face_sprite: face_sprite.texture = faces[0]

func _arm(index: int, parent: Node2D, length: float, height: float) -> void:
    var crop: Array = ARM_CROPS[index]
    var size := Vector2(ARMS.get_width(),ARMS.get_height())
    var region := Rect2(Vector2(crop[0],crop[1])*size,Vector2(crop[2],crop[3])*size)
    var mesh := ArmMesh.new()
    mesh.name = "ContinuousArmSkin_%d" % index
    mesh.configure(ARMS,region,Rect2(-5.0,-height*0.28,length,height),32,9)
    # Fuller upper arm with a gently tapered wrist; retain painted hands and UVs.
    for i in range(mesh.rest.size()):
        var u := (mesh.rest[i].x+5.0)/length
        var center_y := -height*.28+height*(.30+u*.38)
        var fullness := 1.0+sin(clampf(u/.76,0,1)*PI)*.16
        mesh.rest[i].y = center_y+(mesh.rest[i].y-center_y)*fullness
    mesh.reset_shape()
    mesh.material = _volume_material(crop)
    parent.add_child(mesh)
    arm_meshes.append(mesh)
    painted_parts.append(mesh)

func _volume_material(crop: Array) -> ShaderMaterial:
    var material := ShaderMaterial.new()
    material.shader = VOLUME
    material.set_shader_parameter("atlas_bounds",Vector4(crop[0],crop[1],crop[0]+crop[2],crop[1]+crop[3]))
    volume_materials.append(material)
    return material

func _reset_depth_pose() -> void:
    depth_turn = 0.0
    corkscrew = 0.0
    jump_joy_near = 0.0
    jump_joy_far = 0.0
    torso.skew = 0.0
    torso.scale = Vector2.ONE
    near_arm.scale = Vector2.ONE
    far_arm.scale = Vector2.ONE
    near_arm.z_index = 1
    far_arm.z_index = -1
    near_arm.modulate = Color.WHITE
    far_arm.modulate = Color(0.84,0.88,0.94,1.0)
    for material in volume_materials + ribbon_materials:
        material.set_shader_parameter("depth_turn",0.0)

func _ribbon(index: int, parent: Node2D, destination: Rect2, shining: bool) -> void:
    var crop: Array = BODY_CROPS[index]
    var region := Rect2(Vector2(crop[0],crop[1]) * Vector2(ATLAS.get_width(),ATLAS.get_height()), Vector2(crop[2],crop[3]) * Vector2(ATLAS.get_width(),ATLAS.get_height()))
    var mesh := Ribbon.new()
    mesh.name = "FlexiblePaintedPart_%d" % index
    mesh.configure(ATLAS,region,destination,16,5)
    if shining:
        var material := ShaderMaterial.new()
        material.shader = SCALES
        material.set_shader_parameter("atlas_bounds", Vector4(crop[0],crop[1],crop[0]+crop[2],crop[1]+crop[3]))
        mesh.material = material
        ribbon_materials.append(material)
    parent.add_child(mesh)
    ribbons.append(mesh)
    painted_parts.append(mesh)

func _update_ribbons(_dt: float, phase: float, swim_amount: float) -> void:
    var active := high_quality and not reduced_motion
    if not active:
        if mesh_was_active:
            for ribbon in ribbons + arm_meshes:
                ribbon.reset_shape()
        mesh_was_active = false
        return
    mesh_was_active = true
    # Articulated limbs follow every rendered frame, including 120 Hz screens.
    # The old 45 Hz gate skipped alternating frames on a 60 Hz display.
    # Fixed attachment edges and bounded curvature protect the head/hip seams.
    var strength := 0.35 + swim_amount * 3.0 + boost_blend * 0.5
    var shared_wave := cycle_pose.y*.45
    ribbons[0].deform(phase*.5-.4,2.3+strength*.35,hair_drag*6.0+horizontal_drag*4.0+shared_wave)
    ribbons[1].deform(phase*.5-1.1,1.5+strength*.55,hair_drag*4.0+horizontal_drag*5.0+shared_wave*.7)
    var expression := 0.25 if leaping or boosting else 1.0
    # Array order is far then near. Keep each elbow/wrist on its own shoulder.
    arm_meshes[1].skin(arm_pose_near.y+gesture_wave*expression*.12, arm_pose_near.z+gesture_wave*expression*.14-gesture_reach*expression*.08+jump_joy_near*sin(jump_air_time*18)*.10)
    arm_meshes[0].skin(arm_pose_far.y, arm_pose_far.z-gesture_wave*expression*.10+jump_joy_far*sin(jump_air_time*16+.8)*.10)
    for material in ribbon_materials:
        material.set_shader_parameter("motion_clock", clock)
        material.set_shader_parameter("charge_mix", boost_blend)
        material.set_shader_parameter("motion_enabled", not reduced_motion)

func start_jump(chain: int, direction: float) -> void:
    # Six performances: opposing corkscrews, roll, soaring arc, twirl and wave.
    jump_style = jump_style_cursor % 6
    jump_style_cursor += 1
    jump_chain = chain
    jump_direction = direction
    landing_compress = 0.0
    jump_player.play("launch")
    jump_player.advance(0.0)

func land_jump() -> void:
    launch_curl = 0.0
    launch_stretch = 0.0
    jump_player.play("land")
    jump_player.advance(0.0)

func set_jump_state(phase: String, air_time: float, chain: int, direction: float) -> void:
    jump_phase = phase
    jump_air_time = air_time
    jump_chain = chain
    jump_direction = direction

func _jump_roll(progress: float) -> float:
    if jump_style == 2:
        return spin_curve.sample_baked(progress)*TAU*jump_direction
    if jump_style == 3:
        return sin(progress*PI)*.20*jump_direction
    if jump_style == 4:
        return sin(progress*TAU*1.5)*sin(progress*PI)*.24*jump_direction
    if jump_style == 5:
        return -sin(progress*TAU)*sin(progress*PI)*.32*jump_direction
    var handedness := 1.0 if jump_style == 0 else -1.0
    return sin(progress*TAU*1.15)*sin(progress*PI)*0.30*handedness*jump_direction

func _joy_envelope(progress: float, delay: float) -> float:
    return smoothstep(0.12+delay,0.30+delay,progress)*(1.0-smoothstep(0.62+delay,0.88,progress))

func airborne_clearance(screen_y: float) -> float:
    if jump_phase != "airborne" or reduced_motion:
        return 0.0
    var angle := body_pitch * facing_value + _jump_roll(clampf(jump_air_time/0.88,0.0,1.0))
    var top := 0.0
    # Conservative painted-rig bounds protect fins/hair throughout the turn.
    for corner in [Vector2(-185,-125),Vector2(150,-125),Vector2(-185,95),Vector2(150,95)]:
        top = minf(top,Vector2(corner.x*facing_value,corner.y).rotated(angle).y)
    # Articulated fins can leave the root rectangle during a tight curl.
    # Include current painted geometry, without moving the physics body.
    for part in painted_parts:
        var transform: Transform2D = part.get_global_transform()
        if part is Polygon2D:
            for point in part.polygon:
                top = minf(top,(transform * point).y-global_position.y)
        elif part is Sprite2D:
            var rect: Rect2 = part.get_rect()
            for point in [rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)]:
                top = minf(top,(transform * point).y-global_position.y)
    return maxf(0.0,40.0-screen_y-top)

func reset_jump() -> void:
    jump_player.stop()
    _reset_depth_pose()
    launch_curl = 0.0
    launch_stretch = 0.0
    landing_compress = 0.0
    jump_phase = ""
    jump_air_time = 0.0
    jump_pose_blend = 0.0
    hair_drag = 0.0
    hair_drag_speed = 0.0
    previous_vertical_speed = 0.0
    body_pitch = 0.0
    rotation = 0.0
    scale = Vector2(facing_value,1.0)

func _joint(name: String, parent: Node2D, where: Vector2) -> Node2D:
    var node := Node2D.new()
    node.name = name
    node.position = where
    parent.add_child(node)
    return node

func _part(index: int, parent: Node2D, x: float, y: float, w: float, h: float, arm: bool = false) -> Sprite2D:
    var texture: Texture2D = ARMS if arm else ATLAS
    var crop: Array = ARM_CROPS[index] if arm else BODY_CROPS[index]
    var region := Rect2(float(crop[0]) * float(texture.get_width()),
        float(crop[1]) * float(texture.get_height()),
        float(crop[2]) * float(texture.get_width()),
        float(crop[3]) * float(texture.get_height()))
    var atlas := AtlasTexture.new()
    atlas.atlas = texture
    atlas.region = region
    atlas.filter_clip = true
    var sprite := Sprite2D.new()
    sprite.texture = atlas
    sprite.centered = false
    sprite.position = Vector2(x,y)
    sprite.scale = Vector2(w / region.size.x, h / region.size.y)
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    parent.add_child(sprite)
    painted_parts.append(sprite)
    return sprite

func _ready() -> void:
    # Reserve rear/body/front layers above scenery, including standalone previews.
    z_index = 3
    jump_player = AnimationPlayer.new()
    jump_player.name = "JumpAnimationPlayer"
    add_child(jump_player)
    jump_player.add_animation_library("", JUMP_LIBRARY)
    spin_curve = Curve.new()
    spin_curve.add_point(Vector2(0.0,0.0),0.0,0.0)
    spin_curve.add_point(Vector2(0.18,0.02),0.3,0.3)
    spin_curve.add_point(Vector2(0.46,0.48),0.25,0.25)
    spin_curve.add_point(Vector2(0.65,0.55),0.35,0.35)
    spin_curve.add_point(Vector2(0.92,0.99),0.25,0.25)
    spin_curve.add_point(Vector2(1.0,1.0),0.0,0.0)
    gesture_player = AnimationPlayer.new()
    gesture_player.name = "MagnifiquePerformancePlayer"
    add_child(gesture_player)
    gesture_player.add_animation_library("", PERFORMANCE)
    gesture_player.animation_finished.connect(func(_action: StringName): _clear_gesture_values())
    # Draw order is intentionally far to near, matching the HTML 8.1 rig.
    back_hair = _joint("BackHair", self, Vector2(46, -23))
    _ribbon(2, back_hair, Rect2(-125,-46,138,80),false)
    back_hair.scale = Vector2.ONE
    hair_strand = _joint("BackHairStrand", back_hair, Vector2.ZERO)
    _ribbon(15, hair_strand, Rect2(-109,-18,109,28),false)

    tail_skin = TailSkin.new()
    tail_skin.name = "ContinuousMenuTail"
    # Seat the painted hip beneath the bodice's lower waist, with overlap.
    tail_skin.setup(NEW_TAIL,Rect2(24,28,2126,669),Rect2(-150,-33,184,80))
    tail_skin.material = _volume_material([24.0/2172,28.0/724,2126.0/2172,669.0/724])
    add_child(tail_skin)
    # Tail skin has its own anchored mesh; hair still uses its two flutter strips.
    ribbons.append(tail_skin)
    painted_parts.append(tail_skin)

    torso = _joint("Torso", self, Vector2(12, 24))
    far_arm = _joint("FarArm", torso, Vector2(34, -25))
    _arm(1, far_arm, 78, 44)
    bodice = Ribbon.new()
    bodice.name = "ShapedBodice"
    bodice.configure(ATLAS,BODICE_REGION,BODICE_BOUNDS,24,13)
    # Keep collar/shoulders fixed and taper the lower body toward the hip.
    # UVs retain the painting; this replaces uniform squash with a waist shape.
    var shaped: PackedVector2Array = bodice.rest.duplicate()
    for i in range(shaped.size()):
        var t := (shaped[i].y-BODICE_BOUNDS.position.y)/BODICE_BOUNDS.size.y
        var waist := smoothstep(.42,1.0,t)*.24
        shaped[i].x = lerpf(shaped[i].x,29.0,waist)
    bodice.rest = shaped
    bodice.reset_shape()
    bodice.material = _volume_material(BODY_CROPS[0])
    torso.add_child(bodice)
    painted_parts.append(bodice)

    head_joint = _joint("HeadNeck", torso, Vector2(35.5, -28))
    head_joint.scale = Vector2.ONE
    for region in FACE_REGIONS:
        var frame := AtlasTexture.new()
        frame.atlas = EXPRESSIONS
        frame.region = region
        frame.filter_clip = true
        faces.append(frame)
    face_sprite = Sprite2D.new()
    face_sprite.centered = false
    face_sprite.texture = faces[0]
    face_sprite.position = Vector2(-51,-69)
    face_sprite.scale = Vector2(.116,.116)
    head_joint.add_child(face_sprite)
    painted_parts.append(face_sprite)
    # Keep the original sprite as the face registration transform for tools/tests.
    # Self modulation hides its own quad without hiding the connected child mesh.
    face_sprite.self_modulate=Color(1,1,1,0)
    face_details=FaceDetails.new()
    face_details.name="ConnectedFaceHairDetails"
    face_details.configure(EXPRESSIONS,FACE_REGIONS)
    face_sprite.add_child(face_details)
    painted_parts.append(face_details)

    # Seat the sleeve within opaque bodice paint throughout the backward sweep.
    near_arm = _joint("NearArm", torso, Vector2(22, -28))
    _arm(0, near_arm, 88, 49)

    # One attachment hierarchy keeps the painted sockets closed during yaw/pitch.
    # The neck overlaps the collar; hair follows the skull rather than the world.
    back_hair.reparent(head_joint, false)
    back_hair.position = Vector2(-3, -13)
    back_hair.z_index = -2
    tail_skin.reparent(torso, false)
    tail_skin.z_index = -2
    _reset_depth_pose()

    # A real Godot 2D light subtly lifts Sarah away from deep blue scenery.
    # This is an independent light, not a blurry duplicate of her painted face.
    hero_light = PointLight2D.new()
    hero_light.name = "MermaidSoftKeyLight"
    hero_light.texture = _radial_texture()
    hero_light.texture_scale = 2.4
    hero_light.color = Color("#8ef8dc")
    hero_light.energy = 0.24
    hero_light.position = Vector2(21.0, -12.0)
    add_child(hero_light)
    play_gesture("greet")

func _radial_texture() -> Texture2D:
    var image := Image.create(96, 96, false, Image.FORMAT_RGBA8)
    image.fill(Color.TRANSPARENT)
    for y in range(96):
        for x in range(96):
            var u := (float(x) - 47.5) / 47.5
            var v := (float(y) - 47.5) / 47.5
            var d := sqrt(u * u + v * v)
            if d < 1.0:
                image.set_pixel(x, y, Color(1.0, 1.0, 1.0,
                    pow(maxf(0.0, 1.0 - d), 2.1) * 0.74))
    return ImageTexture.create_from_image(image)

func set_motion(velocity: Vector2, direction: float, is_boosting: bool, is_leaping: bool, opacity: float) -> void:
    velocity_value = velocity
    facing_value = -1.0 if direction < 0.0 else 1.0
    if facing_value != last_facing:
        # Quick turn recoil without mirroring through an ugly zero-width pose.
        turn_kick = -0.22 * facing_value
        turn_elapsed = 0.0
        last_facing = facing_value
    boosting = is_boosting
    leaping = is_leaping
    alpha_value = opacity

func play_impact() -> void:
    hit_kick = 1.0
    play_gesture("impact")

func _process(delta: float) -> void:
    var dt := minf(delta, 0.05)
    clock += dt
    var ease := 1.0 - exp(-dt * 9.0)
    var fast_ease := 1.0 - exp(-dt * 16.0)
    var speed := velocity_value.length()
    smoothed_speed = lerpf(smoothed_speed, speed, ease)
    var swim_target := clampf(smoothed_speed / 310.0, 0.0, 1.0)
    swim_blend = lerpf(swim_blend, swim_target, ease)
    boost_blend = lerpf(boost_blend, 1.0 if boosting else 0.0, fast_ease)
    leap_blend = lerpf(leap_blend, 1.0 if leaping else 0.0, ease)
    turn_kick = lerpf(turn_kick, 0.0, fast_ease)
    hit_kick = lerpf(hit_kick, 0.0, 1.0 - exp(-dt * 12.0))
    animation_mode = "boost" if boost_blend > 0.6 else ("leap" if leap_blend > 0.6 else ("swim" if swim_blend > 0.22 else "idle"))
    # Integrate frequency instead of multiplying all elapsed time by changing speed.
    _update_stroke(dt,smoothed_speed)
    var swim_phase := swim_clock
    turn_elapsed = minf(1.0,turn_elapsed + dt)
    var turn_pose := sin(clampf(turn_elapsed/0.30,0.0,1.0)*PI) if not reduced_motion else 0.0
    var braking := steering_value.length_squared() < 0.02 and speed > 30.0 and previous_speed > speed
    brake_blend = lerpf(brake_blend,1.0 if braking else 0.0,fast_ease)
    previous_speed = speed
    var gesture_amount := (0.20 if reduced_motion else 1.0) * (0.25 if leaping or boosting else 1.0)
    var wave := gesture_wave * gesture_amount
    var reach := gesture_reach * gesture_amount
    var arch := gesture_arch * gesture_amount
    var nod := gesture_nod * gesture_amount
    idle_elapsed = idle_elapsed + dt if speed < 20.0 and not leaping and not boosting else 0.0
    if idle_elapsed > 8.0 and not gesture_player.is_playing():
        play_gesture("greet")
        idle_elapsed = 0.0
    var slow_phase := clock * 1.6
    var bank_target := clampf(steering_value.y*.10+horizontal_drag*.24,-.12,.12)
    depth_bank = 0.0 if reduced_motion else lerpf(depth_bank,bank_target,ease)
    settle_blend = lerpf(settle_blend,1.0 if speed<35 and smoothed_speed>55 else 0.0,ease)
    var amount := (0.04 + 0.135 * swim_blend) * (1.0 - boost_blend * 0.65) * (1.0 - leap_blend * 0.62)
    if reduced_motion:
        amount = 0.0
    var active_jump := jump_phase != ""
    jump_pose_blend = lerpf(jump_pose_blend, 1.0 if active_jump else 0.0, fast_ease)
    var air_progress := clampf(jump_air_time / 0.88,0.0,1.0)
    var playful_air := jump_phase == "airborne" and not reduced_motion
    var handedness := 1.0 if jump_style == 0 else -1.0
    corkscrew = sin(air_progress*TAU*1.35)*sin(air_progress*PI)*handedness if playful_air and jump_style != 2 else 0.0
    jump_joy_near = _joy_envelope(air_progress,0.0)*jump_pose_blend if playful_air else 0.0
    jump_joy_far = _joy_envelope(air_progress,0.07)*jump_pose_blend if playful_air else 0.0
    if playful_air:
        if jump_style==3:
            jump_joy_near *= .40
            jump_joy_far *= .25
        elif jump_style==4:
            jump_joy_near *= .70+.30*sin(air_progress*TAU)
            jump_joy_far *= .70-.30*sin(air_progress*TAU)
        elif jump_style==5:
            jump_joy_far *= .45
    var tuck := sin(air_progress * PI) * jump_pose_blend if jump_phase == "airborne" else 0.0
    if jump_style==3: tuck *= .55
    elif jump_style==4: tuck *= .85
    elif jump_style==5: tuck *= .75
    var dive := smoothstep(0.60,0.93,air_progress) * jump_pose_blend if jump_phase == "airborne" else 0.0
    var lift := jump_pose_blend if jump_phase == "ascent" else (1.0 - dive) * jump_pose_blend
    var curl := launch_curl * 0.22 + tuck * (0.42 + minf(jump_chain,3) * 0.035)
    var stretch := launch_stretch * 0.065 - landing_compress * 0.085
    var vertical_acceleration := clampf((velocity_value.y - previous_vertical_speed) / maxf(dt,0.001), -1800.0,1800.0)
    previous_vertical_speed = velocity_value.y
    # Damped secondary motion follows launches, apex and re-entry.
    var drag_target := clampf(velocity_value.y / 3600.0 - vertical_acceleration / 20000.0,-0.24,0.24)
    hair_drag_speed += ((drag_target - hair_drag) * 95.0 - hair_drag_speed * 17.0) * dt
    hair_drag += hair_drag_speed * dt
    var drag_x_target := clampf((velocity_value.x*facing_value-smoothed_speed)/1800.0,-0.22,0.22)
    horizontal_drag_speed += ((drag_x_target-horizontal_drag)*75.0-horizontal_drag_speed*15.0)*dt
    horizontal_drag += horizontal_drag_speed*dt
    if reduced_motion:
        horizontal_drag = 0.0
        horizontal_drag_speed = 0.0
    var pitch_limit := 0.22 if reduced_motion else 0.36
    var pitch_target := clampf(atan2(visual_travel.y,absf(visual_travel.x)+180.0)*0.38,-pitch_limit,pitch_limit)
    body_pitch = lerp_angle(body_pitch,pitch_target,ease)
    if reduced_motion:
        body_pitch = clampf(body_pitch,-0.22,0.22)
    rotation = body_pitch * facing_value
    if jump_phase == "airborne" and not reduced_motion:
        rotation += _jump_roll(air_progress)
    if reduced_motion:
        curl = 0.0
        stretch = 0.0
        hair_drag = 0.0
        hair_drag_speed = 0.0
        lift *= 0.3
        dive *= 0.3
    # All motion is local to joints; collision location and face stay stable.
    scale = Vector2(facing_value * (1.0 + stretch) * (1.0 - turn_pose*0.12), 1.0 - stretch * 0.65)
    var current := 0.0 if reduced_motion else sin(slow_phase) * 0.035
    back_hair.rotation = lerpf(back_hair.rotation, current + turn_kick * 0.5 + swim_blend * 0.018 + hair_drag + horizontal_drag - depth_bank*.22, ease)
    hair_strand.rotation = lerpf(hair_strand.rotation, -current * 1.6 + turn_kick * 0.85 + hair_drag * 0.75, ease)
    var rise := 0.0 if reduced_motion else sin(slow_phase * 1.2) * 1.6
    torso.position = Vector2(12.0, 24.0 + rise * (1.0 - boost_blend) + landing_compress * 2.0 - arch*2.0)
    var arm_sweep := 0.0 if reduced_motion else sin(swim_phase * 0.74 + 0.65) * amount
    # Opposed crawl/scull, symmetric butterfly/scoop, and streamlined boost.
    # Blend full joint tracks at the same phase, including direction changes.
    var stroke_amount := maxf(swim_blend,.65 if waterfall_context!="" else 0.0)*(1.0-leap_blend)
    stroke_amount *= 1.0-clampf(absf(wave)+absf(reach)+hit_kick,0,1)
    if reduced_motion or not high_quality: stroke_amount = 0.0
    var stroke_near := _blended_stroke(false)
    var stroke_far := _blended_stroke(true)
    var near_target := Vector3(.0,.10,0).lerp(stroke_near,stroke_amount)
    var far_target := Vector3(.0,.09,0).lerp(stroke_far*Vector3(.91,.92,.9),stroke_amount)
    # Gentle motion keeps a quiet, readable forward boost pose.
    if reduced_motion or not high_quality:
        near_target = near_target.lerp(Vector3(-.42,.035,-.06),boost_blend)
        far_target = far_target.lerp(Vector3(-.34,.025,-.04),boost_blend)
    arm_pose_near = arm_pose_near.lerp(near_target,fast_ease)
    arm_pose_far = arm_pose_far.lerp(far_target,fast_ease)
    near_arm.rotation = lerpf(near_arm.rotation-spine_motion.shoulder_near.x-torso_motion.rib_angle,
        arm_pose_near.x + arm_sweep * .35 - 0.13 * leap_blend - lift * 0.34 + tuck * 0.08 - dive * 0.10 + hit_kick * 0.14 + wave*0.32 - reach*0.22 - brake_blend*0.18 - jump_joy_near*0.95 + definitive_motion.shoulder_near.y*.045, fast_ease)
    far_arm.rotation = lerpf(far_arm.rotation-spine_motion.shoulder_far.x-torso_motion.rib_angle,
        arm_pose_far.x - arm_sweep * .3 + 0.12 * leap_blend - lift * 0.24 - tuck * 0.07 - dive * 0.20 - hit_kick * 0.12 - wave*0.34 - reach*0.18 + brake_blend*0.14 - jump_joy_far*1.20 + definitive_motion.shoulder_far.y*.045, fast_ease)
    # A readable faux yaw: foreshortening, overlap and lighting agree on depth.
    var roll := sin(air_progress*TAU-0.45)*sin(air_progress*PI) if jump_phase == "airborne" else 0.0
    var yaw_target := clampf((corkscrew*0.95 if jump_style != 2 and playful_air else roll*0.82) + turn_pose*0.45 + sin(swim_phase*0.5)*swim_blend*0.13 + depth_bank*.9,-0.9,0.9)
    depth_turn = 0.0 if reduced_motion else lerpf(depth_turn,yaw_target,fast_ease)
    var depth := absf(depth_turn)
    torso.skew = depth_turn*0.065
    torso.scale = Vector2(1.0-depth*0.10,1.0+(0.0 if reduced_motion else tuck*0.025))
    near_arm.scale = Vector2(1.0-maxf(depth_turn,0.0)*0.20,1.0)
    far_arm.scale = Vector2(1.0-maxf(-depth_turn,0.0)*0.20,1.0)
    near_arm.z_index = -1 if depth_turn > 0.38 else 1
    far_arm.z_index = 1 if depth_turn > 0.38 else -1
    near_arm.modulate = Color.WHITE.lerp(Color(0.77,0.84,0.94,1.0),maxf(depth_turn,0.0))
    far_arm.modulate = Color(0.84,0.88,0.94,1.0).lerp(Color.WHITE,maxf(depth_turn,0.0))
    for material in volume_materials + ribbon_materials:
        material.set_shader_parameter("depth_turn",depth_turn)
    pose_set = "boost" if boosting else ("rise" if velocity_value.y < -90 else ("playful" if jump_pose_blend>.25 or wave>.15 else ("glide" if brake_blend>.12 else ("swim" if swim_blend>.22 else "idle"))))
    # Twelve additional contextual loops complement the six original poses.
    # Action priority prevents decorative motion from fighting a cast or jump.
    if gesture_player.is_playing() and last_gesture in ["greet","cast","celebrate","impact","reward"]:
        pose_set = {"greet":"greet","cast":"cast","celebrate":"celebrate","impact":"recover","reward":"reach"}[last_gesture]
    elif jump_pose_blend<=.25 and not boosting:
        if turn_pose>.12: pose_set = "bank"
        elif settle_blend>.14: pose_set = "settle"
        elif velocity_value.y>90: pose_set = "descend"
        elif brake_blend>.12: pose_set = "drift"
        elif speed<20: pose_set = "hover"
        elif speed>365: pose_set = "sprint"
        elif speed>100 and speed<240 and absf(velocity_value.y)<90: pose_set = "cruise"
    elif boosting and speed>650:
        pose_set = "sprint"
    if not gesture_player.is_playing() and jump_pose_blend <= .25:
        if waterfall_context == "pull": pose_set = "waterfall_pull"
        elif waterfall_context == "outflow": pose_set = "waterfall_outflow"
        elif waterfall_context == "descent":
            if boosting: pose_set = "waterfall_boost"
            elif swim_style.begins_with("rise"): pose_set = "waterfall_rise"
            elif swim_style.begins_with("dive"): pose_set = "waterfall_dive"
            else: pose_set = "waterfall_scull"
        elif boosting:
            if visual_travel.y < -speed*.32: pose_set = "boost_rise"
            elif visual_travel.y > speed*.32: pose_set = "boost_dive"
            else: pose_set = SwimStyles.body_loop(swim_style)
        elif pose_set in ["swim","rise","descend","sprint"]:
            pose_set = SwimStyles.body_loop(swim_style)
        elif pose_set=="bank" and turn_elapsed>.15: pose_set = "turn_carve"
    var desired_pose := Cycles.sample(pose_set,swim_phase)
    # Paired base/context loops provide organic variation without hard state swaps.
    if pose_set=="hover": desired_pose = desired_pose.lerp(Cycles.sample("idle",swim_phase),.35)
    elif pose_set=="drift": desired_pose = desired_pose.lerp(Cycles.sample("glide",swim_phase),.35)
    desired_pose.x += turn_kick*.25 - arch*.12 + landing_compress*.08
    desired_pose.z += corkscrew*.12 - dive*.10 + depth_bank*.14
    cycle_pose = cycle_pose.lerp(desired_pose,fast_ease)
    var tuck_target := clampf(launch_curl*.7+tuck*.88+brake_blend*.32+absf(turn_kick)*.8,0,1)
    tail_tuck = lerpf(tail_tuck,tuck_target,fast_ease)
    # Shared stroke wave passes through the back before the neck settles.
    definitive_motion.update(self,dt)
    spine_motion.apply(self,dt,arch,nod,swim_phase)
    tail_skin.position = Vector2(1,6)
    if reduced_motion or not high_quality:
        tail_skin.reset_shape()
    else:
        tail_skin.skin(cycle_pose,tail_tuck,turn_kick)
    # Face, ear, nose and hair share the body's clocks, current, yaw and effort.
    blink_blend = FaceDetails.blink_at(clock)
    var joy := clampf(boost_blend*.65+jump_joy_near*.45+absf(wave)*.40+absf(reach)*.12,0,1)
    expression_blend = lerpf(expression_blend,joy,1.0-exp(-dt*7.0))
    var look := Vector2(clampf(visual_travel.x*facing_value/760.0,-1,1),clampf(visual_travel.y/760.0,-1,1))
    look += Vector2(depth_turn*.2,cycle_pose.x*.12)
    detail_gaze = detail_gaze.lerp(look.limit_length(1.0),1.0-exp(-dt*8.0))
    face_details.set_response(Vector2(visual_travel.x*facing_value,visual_travel.y)/760.0,
        depth_turn,boost_blend,torso_motion.breath.x/.0065,cycle_pose.y,hair_drag+horizontal_drag,
        swim_phase,detail_gaze,expression_blend,blink_blend,high_quality and not reduced_motion)
    expression_index = 2 if blink_blend>.55 else (1 if expression_blend>.35 else 0)
    face_sprite.texture = faces[expression_index]
    _update_ribbons(dt,swim_phase,swim_blend)
    self_modulate.a = alpha_value
    if is_instance_valid(hero_light):
        var target_energy := 0.0 if reduced_motion else (0.24 + 0.24 * boost_blend)
        hero_light.energy = lerpf(hero_light.energy, target_energy, ease)
        hero_light.color = Color("#b6f8ff") if boost_blend > 0.4 else Color("#8ef8dc")


func fin_anchor_global() -> Vector2:
    return tail_skin.to_global(tail_skin.tip_center)

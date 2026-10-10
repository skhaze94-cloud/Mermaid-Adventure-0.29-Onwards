extends RefCounted
const Points = preload("res://godot/sarah_performance_points.gd")
const Spine = preload("res://godot/sarah_spine_motion.gd")
var shoulder_near := Vector2.ZERO
var shoulder_far := Vector2.ZERO
var previous_shoulders := Vector4.ZERO
var expression := Vector3.ZERO
var head_spring := Vector2.ZERO
var jaw_spring := Vector2.ZERO
var chest_spring := Vector2.ZERO

func reset() -> void:
    shoulder_near=Vector2.ZERO; shoulder_far=Vector2.ZERO
    previous_shoulders=Vector4.ZERO
    expression=Vector3.ZERO
    head_spring=Vector2.ZERO; jaw_spring=Vector2.ZERO; chest_spring=Vector2.ZERO

func update(rig, dt: float) -> void:
    var shoulders := Vector4.ZERO
    var face := Vector3.ZERO
    var idle := Points.sample("idle",rig.swim_clock)
    var activity: float = maxf(rig.swim_blend,.65 if rig.waterfall_context!="" else 0.0)
    shoulders=idle[0]*(1.0-activity); face=idle[1]*(1.0-activity)
    for name in rig.stroke_weights:
        var weight: float = rig.stroke_weights[name]*activity
        if weight<.00001: continue
        var point := Points.sample(name,rig.swim_clock)
        shoulders+=point[0]*weight; face+=point[1]*weight
    var action := ""
    var amount := 0.0
    if rig.jump_phase!="":
        action="jump_airborne" if rig.jump_phase=="airborne" else ("jump_landing" if rig.jump_phase=="reentry" else "jump_ascent")
        amount=rig.jump_pose_blend
    elif rig.landing_compress>.01 or (rig.jump_player.is_playing() and rig.jump_player.current_animation=="land"):
        action="jump_landing"; amount=maxf(rig.landing_compress,.45)
    elif rig.gesture_player.is_playing():
        action={"greet":"greet","cast":"cast","celebrate":"celebrate","impact":"impact","reward":"celebrate"}.get(rig.last_gesture,"")
        amount=.75
    elif absf(rig.turn_kick)>.01:
        action="turn"; amount=minf(absf(rig.turn_kick)*2.0,.8)
    elif rig.brake_blend>.10:
        action="recover"; amount=rig.brake_blend
    if action!="":
        var point := Points.sample(action,rig.swim_clock)
        shoulders=shoulders.lerp(point[0],amount)
        face=face.lerp(point[1],amount)
    var enabled: bool = rig.high_quality and not rig.reduced_motion
    if not enabled:
        reset()
        rig.near_arm.position=Vector2(22,-28)
        rig.far_arm.position=Vector2(34,-25)
        return
    # Roll softly accompanies socket glide; no arbitrary independent ticking.
    var decay := exp(-dt*11.0)
    var near_target := Vector2(shoulders.x,shoulders.y)
    var far_target := Vector2(shoulders.z,shoulders.w)
    var near_start := Vector2(previous_shoulders.x,previous_shoulders.y)
    var far_start := Vector2(previous_shoulders.z,previous_shoulders.w)
    var near_rate := (near_target-near_start)/maxf(dt,.001)
    var far_rate := (far_target-far_start)/maxf(dt,.001)
    # Exact filter for targets interpolated through a frame, avoiding refresh-rate lead.
    shoulder_near=near_target-near_rate/11.0+(shoulder_near-near_start+near_rate/11.0)*decay
    shoulder_far=far_target-far_rate/11.0+(shoulder_far-far_start+far_rate/11.0)*decay
    previous_shoulders=shoulders
    head_spring=Spine.spring(head_spring,face.x,14.0,dt)
    jaw_spring=Spine.spring(jaw_spring,face.y,11.0,dt)
    chest_spring=Spine.spring(chest_spring,face.z,12.0,dt)
    expression=Vector3(head_spring.x,jaw_spring.x,chest_spring.x)
    rig.near_arm.position=Vector2(22,-28)+shoulder_near
    rig.far_arm.position=Vector2(34,-25)+shoulder_far

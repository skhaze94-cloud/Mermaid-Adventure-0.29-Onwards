extends RefCounted
## Presentation only. Owns stroke timing, stopping residue and intention-led turns.
## Physics, action priority, painted sockets and the shared pelvis keep their owners.
var presentation_facing := 1.0
var previous_speed := 0.0
var stop_energy := 0.0
var brake := 0.0
var settle := 0.0
var cruise := 0.0
var glide := 0.0
var gaze_lead := Vector2.ZERO
var phase := 0.0

func reset() -> void:
    presentation_facing=1.0;previous_speed=0.0;stop_energy=0.0
    brake=0.0;settle=0.0;cruise=0.0;glide=0.0;phase=0.0;gaze_lead=Vector2.ZERO

func begin(rig,dt: float) -> void:
    var speed: float=rig.velocity_value.length()
    var important: bool=rig.boosting or rig.leaping or rig.jump_phase!="" or rig.hit_kick>.08 or rig.bubble_hold_goal>.01 or (rig.gesture_player.is_playing() and rig.last_gesture=="cast")
    # Ignore a small opposite stick nudge until the swimmer actually reverses.
    # Deliberate steering and the velocity-only API still turn immediately.
    var decisive: bool=absf(rig.steering_value.x)>.34 or absf(rig.velocity_value.x)>24.0 and signf(rig.velocity_value.x)==rig.facing_value
    if important or decisive or speed<12.0 and rig.steering_value.length_squared()<.002:
        presentation_facing=rig.facing_value
    var no_drive: bool=rig.steering_value.length_squared()<.02
    var loss: float=maxf(0.0,previous_speed-speed)
    stop_energy*=exp(-dt*(12.0 if important or not no_drive else 4.2))
    if no_drive and not important:
        stop_energy=clampf(stop_energy+loss/345.0,0.0,1.0)
    var ease: float=1.0-exp(-dt*12.0)
    brake=lerpf(brake,stop_energy if not important else 0.0,ease)
    settle=lerpf(settle,stop_energy*(1.0-smoothstep(20,120,speed)) if not important else 0.0,1.0-exp(-dt*8.0))
    previous_speed=speed
    var gaze: Vector2=rig.steering_value
    if gaze.length_squared()<.02:gaze=rig.velocity_value/345.0
    gaze.x*=rig.definitive_21.render_heading()
    gaze_lead=gaze_lead.lerp(gaze.limit_length(1.0),1.0-exp(-dt*18.0))

func update_phase(rig,dt: float) -> void:
    var ordinary: bool=not rig.boosting and not rig.leaping and rig.jump_phase=="" and rig.waterfall_context=="" and absf(rig.visual_travel.y)<maxf(90.0,rig.smoothed_speed*.32)
    var target: float=rig.swim_blend if ordinary else 0.0
    cruise=lerpf(cruise,target,1.0-exp(-dt*7.0))
    # Monotonic periodic retiming: a longer extension, a purposeful quicker pull.
    # The style registry keeps its original cadence; every joint samples this phase.
    phase=rig.swim_clock-.52*sin(rig.swim_clock)*cruise
    var extension: float=exp(-pow(sin(phase*.5)/.38,2.0))
    glide=extension*cruise*(1.0-rig.boost_blend)*(1.0-rig.leap_blend)

func quietness() -> float:
    return 1.0-glide*.68

extends RefCounted
## Independent elbow/wrist settling; painting and shoulder sockets stay fixed.
var elbows := [Vector2.ZERO,Vector2.ZERO] # Far, near: angle / angular velocity.
var wrists := [Vector2.ZERO,Vector2.ZERO]
var previous_targets := [Vector2.ZERO,Vector2.ZERO]
var previous_pose_targets := [Vector3.ZERO,Vector3.ZERO]
var previous_shoulders := Vector2.ZERO
var shoulder_speed := Vector2.ZERO
var applied := [Vector2.ZERO,Vector2.ZERO]

func reset() -> void:
    elbows=[Vector2.ZERO,Vector2.ZERO]
    wrists=[Vector2.ZERO,Vector2.ZERO]
    previous_targets=[Vector2.ZERO,Vector2.ZERO]
    previous_pose_targets=[Vector3.ZERO,Vector3.ZERO]
    applied=[Vector2.ZERO,Vector2.ZERO]
    previous_shoulders=Vector2.ZERO
    shoulder_speed=Vector2.ZERO

func filter_pose(index: int, state: Vector3, target: Vector3, dt: float) -> Vector3:
    if dt<=0.0: return state
    var previous: Vector3 = previous_pose_targets[index]
    var slope := (target-previous)/maxf(dt,.00001)
    previous_pose_targets[index]=target
    return target-slope/16.0+(state-previous+slope/16.0)*exp(-16.0*dt)

static func spring_linear(state: Vector2, previous: float, target: float, frequency: float, dt: float) -> Vector2:
    # Exact critically damped solution for a target moving linearly through
    # this frame. Endpoint-held targets add different lag at 30 and 120 Hz.
    var slope := (target-previous)/maxf(dt,.00001)
    var offset := state.x-previous+2.0*slope/frequency
    var impulse := state.y-slope+frequency*offset
    var decay := exp(-frequency*dt)
    return Vector2(target-2.0*slope/frequency+(offset+impulse*dt)*decay,
        slope+(state.y-slope-frequency*impulse*dt)*decay)

func update(rig, dt: float) -> void:
    if dt<=0.0: return
    if not rig.high_quality or rig.reduced_motion:
        reset()
        return
    var shoulders := Vector2(rig.arm_pose_far.x,rig.arm_pose_near.x)
    var speed := (shoulders-previous_shoulders)/maxf(dt,.00001)
    previous_shoulders=shoulders
    shoulder_speed=shoulder_speed.lerp(speed,1.0-exp(-dt*12.0))
    var poses := [rig.arm_pose_far,rig.arm_pose_near]
    var expression: float = .25 if rig.leaping or rig.boosting else 1.0
    var compact: float = 1.0-rig.boost_blend*.90
    for i in range(2):
        var pose: Vector3 = poses[i]
        # A moving shoulder loads the elbow. The wrist responds more slowly
        # to the pull, with a small counter-flex rather than rigid hand rotation.
        var elbow_target := pose.y-clampf(shoulder_speed[i]*.025,-.045,.045)*compact
        var wrist_target := pose.z
        if i==1:
            elbow_target+=rig.gesture_wave*expression*.12-rig.gesture_reach*expression*.10
            wrist_target+=rig.gesture_wave*expression*.23-rig.gesture_reach*expression*.16
            wrist_target+=rig.jump_joy_near*sin(rig.jump_air_time*18)*.10
        else:
            wrist_target-=rig.gesture_wave*expression*.12
            wrist_target+=rig.jump_joy_far*sin(rig.jump_air_time*16+.8)*.10
        elbow_target=clampf(elbow_target,-1.16,.20)
        elbows[i]=spring_linear(elbows[i],previous_targets[i].x,elbow_target,22.0,dt)
        wrist_target-=clampf(elbows[i].y*.025,-.07,.07)*compact
        wrist_target=clampf(wrist_target,-.38,.38)
        wrists[i]=spring_linear(wrists[i],previous_targets[i].y,wrist_target,18.0,dt)
        previous_targets[i]=Vector2(elbow_target,wrist_target)
        applied[i]=Vector2(elbows[i].x,wrists[i].x)

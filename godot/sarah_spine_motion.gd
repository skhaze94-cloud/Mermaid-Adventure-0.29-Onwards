extends RefCounted
## Critically damped back/neck response with fixed painted attachment bands.
var back := Vector2.ZERO # Angle and angular velocity.
var neck := Vector2.ZERO
var shoulder_near := Vector2.ZERO
var shoulder_far := Vector2.ZERO
var jaw := Vector2.ZERO
var bend := Vector2.ZERO

static func spring(state: Vector2, target: float, frequency: float, dt: float) -> Vector2:
    # Exact critically damped solution for a constant target, stable at any dt.
    var offset := state.x-target
    var impulse := state.y+frequency*offset
    var decay := exp(-frequency*dt)
    return Vector2(target+(offset+impulse*dt)*decay,
        (state.y-frequency*impulse*dt)*decay)

func reset() -> void:
    back=Vector2.ZERO
    neck=Vector2.ZERO
    bend=Vector2.ZERO
    shoulder_near=Vector2.ZERO
    shoulder_far=Vector2.ZERO
    jaw=Vector2.ZERO

func apply(rig, dt: float, arch: float, nod: float, phase: float = 0.0) -> void:
    var enabled: bool = rig.high_quality and not rig.reduced_motion
    var activity: float = lerpf(.28,1.0,rig.swim_blend)
    # Faster strokes keep a compact line; the ripple persists through boosts.
    var wave: float = rig.cycle_pose.x*.14+rig.cycle_pose.y*.035
    var target: float = -rig.visual_travel.y/1400.0*.12+rig.turn_kick*.18+rig.depth_bank*.18
    if enabled:
        target += wave*activity*(1.0-rig.boost_blend*.35)-arch*.018+rig.definitive_motion.expression.z*.025
    back=spring(back,clampf(target,-.13,.13),12.0,dt)
    rig.torso.rotation=back.x
    rig.torso_motion.update(rig,dt)
    # Remove last frame's roll in the rig before interpolating the base arm pose.
    var amplitude: float = activity*(1.0-rig.boost_blend*.55)
    var near_target: float = (sin(rig.arm_pose_near.x)*.045+rig.definitive_motion.shoulder_near.y*.055)*amplitude if enabled else 0.0
    var far_target: float = (sin(rig.arm_pose_far.x)*.045+rig.definitive_motion.shoulder_far.y*.055)*amplitude if enabled else 0.0
    if enabled:
        # The inward catch loads the shoulder; wrist release follows the elbow.
        var loading: float = rig.swim_blend*(1.0-rig.boost_blend*.85)
        near_target+=(-rig.arm_pose_near.y*.026+rig.arm_pose_near.z*.025)*loading
        far_target+=(-rig.arm_pose_far.y*.023-rig.arm_pose_far.z*.020)*loading
        near_target=clampf(near_target,-.11,.11)
        far_target=clampf(far_target,-.11,.11)
    shoulder_near=spring(shoulder_near,near_target,14.0,dt)
    shoulder_far=spring(shoulder_far,far_target,13.0,dt)
    rig.near_arm.rotation+=shoulder_near.x+rig.torso_motion.rib_angle
    rig.near_arm.position=rig.torso_motion.chest_point(rig.near_arm.position)
    rig.far_arm.rotation+=shoulder_far.x+rig.torso_motion.rib_angle
    rig.far_arm.position=rig.torso_motion.chest_point(rig.far_arm.position)
    jaw=Vector2(rig.definitive_motion.expression.y,rig.definitive_motion.jaw_spring.y) if enabled else Vector2.ZERO
    rig.face_details.surface.set_shader_parameter("jaw_open",jaw.x)
    var neck_target: float = -back.x*.32+nod*.055-rig.depth_bank*.055
    if enabled:
        neck_target += rig.visual_travel.y/760.0*.018+rig.depth_turn*.014
        # Inertia lets the chest lead while the eyes settle into the new heading.
        neck_target -= back.y*.014
        neck_target += wave*activity*.20+rig.definitive_motion.expression.x
        neck_target -= clampf(rig.body_pitch*.08,-.025,.025)
        neck_target += rig.detail_gaze.y*.022+rig.turn_kick*.025
        neck_target -= rig.torso_motion.rib_angle*.35
    neck=spring(neck,clampf(neck_target,-.10,.10),10.0,dt)
    rig.head_joint.rotation=neck.x+rig.torso_motion.rib_angle
    rig.face_details.surface.set_shader_parameter("neck_follow",neck.x if enabled else 0.0)
    # Rotate around the painted collar, rather than swinging it away from the body.
    var collar := Vector2(3.52,-4.04)
    var chest_collar: Vector2 = rig.torso_motion.chest_point(Vector2(35.5,-28)+collar)
    rig.head_joint.position=chest_collar-collar.rotated(rig.head_joint.rotation)
    var bend_target: float = (wave*activity+arch*.025+rig.hair_drag*.045) if enabled else 0.0
    bend=spring(bend,clampf(bend_target,-.075,.075),13.0,dt)
    if not enabled:
        rig.bodice.reset_shape()
        return
    var points: PackedVector2Array = rig.bodice.rest.duplicate()
    for i in range(points.size()):
        var t: float = (rig.bodice.rest[i].y-rig.BODICE_BOUNDS.position.y)/rig.BODICE_BOUNDS.size.y
        # Back ripple pins the upper band; the separate shoulder pass keeps collar/hip fixed.
        var envelope := smoothstep(.36,.55,t)*(1.0-smoothstep(.78,.94,t))
        points[i].x += bend.x*18.0*envelope
        points[i].y += bend.x*(points[i].x-29.0)*.12*envelope
    # Shoulder painting glides with the sockets; collar and hip stay pinned.
    for i in range(points.size()):
        var p: Vector2 = rig.bodice.rest[i]
        var t: float = (p.y-rig.BODICE_BOUNDS.position.y)/rig.BODICE_BOUNDS.size.y
        var band := smoothstep(.18,.25,t)*(1.0-smoothstep(.45,.58,t))
        var near_weight := exp(-pow((p.x-22.0)/11.0,2.0))
        var far_weight := exp(-pow((p.x-34.0)/9.0,2.0))
        var total := maxf(1.0,near_weight+far_weight)
        points[i]+=(rig.definitive_motion.shoulder_near*near_weight+rig.definitive_motion.shoulder_far*far_weight)*band/total
    rig.bodice.polygon=rig.torso_motion.deform(points,rig.bodice.rest)
    rig.bodice.mesh_updates+=1

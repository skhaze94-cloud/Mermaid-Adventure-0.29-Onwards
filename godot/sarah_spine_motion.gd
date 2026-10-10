extends RefCounted
## Critically damped back/neck response with fixed painted attachment bands.
var back := Vector2.ZERO # Angle and angular velocity.
var neck := Vector2.ZERO
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

func apply(rig, dt: float, arch: float, nod: float) -> void:
    var enabled: bool = rig.high_quality and not rig.reduced_motion
    var activity: float = lerpf(.28,1.0,rig.swim_blend)
    # Faster strokes keep a compact line; the ripple persists through boosts.
    var wave: float = rig.cycle_pose.x*.14+rig.cycle_pose.y*.035
    var target: float = -rig.visual_travel.y/1400.0*.12+rig.turn_kick*.18+rig.depth_bank*.18
    if enabled:
        target += wave*activity*(1.0-rig.boost_blend*.35)-arch*.018
    back=spring(back,clampf(target,-.13,.13),12.0,dt)
    rig.torso.rotation=back.x
    var neck_target: float = -back.x*.32+nod*.055-rig.depth_bank*.055
    if enabled:
        neck_target += rig.visual_travel.y/760.0*.018+rig.depth_turn*.014
        # Inertia lets the chest lead while the eyes settle into the new heading.
        neck_target -= back.y*.014
        neck_target += wave*activity*.20
    neck=spring(neck,clampf(neck_target,-.10,.10),10.0,dt)
    rig.head_joint.rotation=neck.x
    # Rotate around the painted collar, rather than swinging it away from the body.
    var collar := Vector2(3.52,-4.04)
    rig.head_joint.position=Vector2(35.5,-28)+collar-collar.rotated(neck.x)
    var bend_target: float = (wave*activity+arch*.025+rig.hair_drag*.045) if enabled else 0.0
    bend=spring(bend,clampf(bend_target,-.075,.075),13.0,dt)
    if not enabled:
        rig.bodice.reset_shape()
        return
    var points: PackedVector2Array = rig.bodice.rest.duplicate()
    for i in range(points.size()):
        var t: float = (rig.bodice.rest[i].y-rig.BODICE_BOUNDS.position.y)/rig.BODICE_BOUNDS.size.y
        # Upper shoulder/collar and lower hip bands are exactly pinned.
        var envelope := smoothstep(.36,.55,t)*(1.0-smoothstep(.78,.94,t))
        points[i].x += bend.x*18.0*envelope
        points[i].y += bend.x*(points[i].x-29.0)*.12*envelope
    rig.bodice.polygon=points
    rig.bodice.mesh_updates+=1

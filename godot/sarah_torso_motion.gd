extends RefCounted
## Independent ribcage and waist responses, blended through one connected painted skin.
const Spring = preload("res://godot/sarah_spine_motion.gd")
const RIB_PIVOT := Vector2(29,-14)
const HIP_PIVOT := Vector2(35,13)
var ribs := Vector2.ZERO
var waist := Vector2.ZERO
var breath := Vector2.ZERO
var lift := Vector2.ZERO
var breath_clock := 0.0
var rib_angle := 0.0
var rib_transform := Transform2D.IDENTITY

func reset() -> void:
    ribs=Vector2.ZERO;waist=Vector2.ZERO;breath=Vector2.ZERO;lift=Vector2.ZERO
    breath_clock=0.0
    rib_angle=0.0;rib_transform=Transform2D.IDENTITY

func update(rig, dt: float) -> void:
    if not rig.high_quality or rig.reduced_motion:
        reset()
        rig.tail_skin.root_bend=0.0
        return
    breath_clock+=dt
    var activity: float = lerpf(.35,1.0,maxf(rig.swim_blend,.65 if rig.waterfall_context!="" else 0.0))
    var compact: float = 1.0-rig.boost_blend*.35
    # Ribs respond to the middle wave; the waist follows the hip wave at another delay.
    var rib_target: float = (rig.cycle_pose.y*.065-rig.cycle_pose.x*.04)*activity*compact
    rib_target+=rig.definitive_motion.expression.z*.03-rig.gesture_arch*.012
    var waist_target: float = (rig.cycle_pose.x*.08+rig.cycle_pose.y*.035)*activity
    ribs=Spring.spring(ribs,clampf(rib_target,-.055,.055),11.0,dt)
    waist=Spring.spring(waist,clampf(waist_target,-.045,.045),9.0,dt)
    # Tiny volume change uses a separate slow clock, without implying gasping underwater.
    var breath_target: float = sin(breath_clock*1.45)*.0065*(1.0-rig.boost_blend*.60)
    breath=Spring.spring(breath,breath_target,7.0,dt)
    var lift_target: float = rig.definitive_motion.expression.z*.85+sin(breath_clock*1.45-.25)*.16
    lift=Spring.spring(lift,clampf(lift_target,-.40,.40),10.0,dt)
    rib_angle=ribs.x
    var basis := Transform2D(rib_angle,Vector2.ZERO)
    basis.x*=1.0+breath.x
    basis.y*=1.0-breath.x*.40
    basis.origin=RIB_PIVOT-basis.basis_xform(RIB_PIVOT)+Vector2(0,lift.x)
    rib_transform=basis
    rig.tail_skin.root_bend=waist.x

func chest_point(point: Vector2) -> Vector2:
    return rib_transform*point

func deform(points: PackedVector2Array, rest: PackedVector2Array) -> PackedVector2Array:
    for i in range(points.size()):
        var t := (rest[i].y+40.0)/60.0
        # Collar/shoulders move together with the ribs; the lower seam stays anchored.
        var rib_weight := 1.0-smoothstep(.45,.87,t)
        points[i]=points[i].lerp(chest_point(points[i]),rib_weight)
        var waist_weight := smoothstep(.50,.70,t)*(1.0-smoothstep(.82,.94,t))
        var curled := HIP_PIVOT+(rest[i]-HIP_PIVOT).rotated(waist.x)
        points[i]+=(curled-rest[i])*waist_weight
    return points

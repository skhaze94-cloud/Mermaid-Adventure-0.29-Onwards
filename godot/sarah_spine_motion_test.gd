extends SceneTree
const Spine = preload("res://godot/sarah_spine_motion.gd")
var checks := 0
var failures := 0
func check(ok: bool, why: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error("SARAH SPINE: "+why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    # The spring must not explode at low frame rates or change its constant-target result.
    var reference := Spine.spring(Vector2.ZERO,.10,12,1.0)
    for hz in [15,30,60,120]:
        var state := Vector2.ZERO
        for tick in range(hz): state=Spine.spring(state,.10,12,1.0/hz)
        check(state.distance_to(reference)<.00001,"Spring depends on refresh rate")
    var rig = load("res://godot/sarah_rig.gd").new()
    root.add_child(rig)
    rig.set_process(false)
    rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.jump_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    var rest: PackedVector2Array = rig.bodice.rest.duplicate()
    var uv: PackedVector2Array = rig.bodice.uv.duplicate()
    var movement := 0.0
    for facing in [-1.0,1.0]:
        for context in ["","pull","descent","outflow"]:
            for velocity in [Vector2.ZERO,Vector2(310,0),Vector2(20,-430),Vector2(20,430),Vector2(760,90)]:
                rig.reset_performance()
                rig.set_waterfall_context(context)
                rig.set_motion(Vector2(velocity.x*facing,velocity.y),facing,velocity.length()>650,false,1)
                for frame in range(150):
                    var previous: float = rig.head_joint.rotation
                    rig._process(1.0/60)
                    check(absf(rig.torso.rotation)<=.131 and absf(rig.head_joint.rotation)<=.101,"Unbounded back or neck")
                    check(absf(rig.head_joint.rotation-previous)<.025,"Neck snaps during transition")
                    var collar: Vector2 = rig.head_joint.position+Vector2(3.52,-4.04).rotated(rig.head_joint.rotation)
                    check(collar.distance_to(Vector2(39.02,-32.04))<.0001,"Collar pivot separates")
                    check(rig.bodice.uv==uv and rig.bodice.rest==rest,"Paint registration changes")
                    if frame%15==0:
                        for i in range(rest.size()):
                            var t: float = (rest[i].y+40)/60
                            var distance: float = rig.bodice.polygon[i].distance_to(rest[i])
                            movement=maxf(movement,distance)
                            check(distance<1.5,"Back overstretches painting")
                            if t<=.18 or t>=.94: check(distance<.00001,"Collar/hip band moves")
    check(movement>.10,"Back remains rigid")
    rig.set_quality(true)
    rig.reduced_motion=true
    rig._process(1.0/60)
    check(rig.bodice.polygon==rest,"Gentle Motion leaves mesh ripple")
    rig.set_quality(false)
    rig.reduced_motion=false
    rig._process(1.0/60)
    check(rig.bodice.polygon==rest,"Economy leaves mesh ripple")
    rig.reset_performance()
    check(rig.spine_motion.back==Vector2.ZERO and rig.spine_motion.neck==Vector2.ZERO,"Restart retains neck momentum")
    check(rig.head_joint.position==Vector2(35.5,-28) and rig.bodice.polygon==rest,"Restart retains deformation")
    rig.free()
    print("SARAH SPINE: %d checks, %d failures" % [checks,failures])
    quit(0 if failures==0 else 1)

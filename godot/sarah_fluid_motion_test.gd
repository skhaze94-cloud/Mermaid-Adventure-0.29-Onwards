extends SceneTree
const Cycles = preload("res://godot/sarah_pose_cycles.gd")
var checks := 0
var failures := 0
func check(ok: bool, reason: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("SARAH FLUID MOTION: "+reason)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var level = load("res://godot/highland_level.tscn").instantiate()
    root.add_child(level)
    level.set_physics_process(false)
    var rig = level.native_rig
    rig.set_process(false)
    rig.reset_performance()
    var skin = rig.tail_skin
    var original_uv: PackedVector2Array = skin.uv.duplicate()
    for name in Cycles.NAMES:
        check(Cycles.sample(name,0).distance_to(Cycles.sample(name,TAU))<.00001,"Cycle seam pops: "+name)
        var left := (Cycles.sample(name,0)-Cycles.sample(name,-.001))/.001
        var right := (Cycles.sample(name,.001)-Cycles.sample(name,0))/.001
        check(left.distance_to(right)<.01,"Loop tangent is discontinuous: "+name)
        for frame in range(48):
            skin.skin(Cycles.sample(name,float(frame)*TAU/48),0,0)
            var length := 0.0
            for i in range(1,skin.centers.size()):
                length += skin.centers[i].distance_to(skin.centers[i-1])
            check(absf(length-skin.tail_length)<.002,"Tail changes length during "+name)
            var anchored := true
            for i in range(skin.rest.size()):
                if skin.weights[i]==0 and skin.polygon[i].distance_to(skin.rest[i])>.001: anchored=false
                if not skin.polygon[i].is_finite(): anchored=false
            check(anchored,"Hip seam drifts or tail mesh contains invalid points")
    check(skin.uv==original_uv,"Curvature moves the painted UVs")
    skin.skin(Vector4.ZERO,0,0)
    var straight: Vector2 = skin.tip_center
    skin.skin(Vector4.ZERO,1,0)
    check(skin.tip_center.distance_to(straight)>45,"Tail cannot tuck through its middle")
    check(skin.tip_center.distance_to(skin.socket)<skin.tail_length*.9,"Tuck only rotates a rigid tail")
    var face_position: Vector2 = rig.face_sprite.position
    rig.set_motion(Vector2(300,0),1,false,false,1)
    for i in range(120):
        rig._process(1.0/60)
        check(rig.face_sprite.position==face_position,"Tail motion displaces the face registration")
    var before: Vector2 = skin.tip_center
    rig.set_motion(Vector2(700,-100),1,true,false,1)
    for i in range(24):
        rig._process(1.0/60)
        check(skin.tip_center.distance_to(before)<12,"State blending snaps the fin")
        before=skin.tip_center
    rig.clock=4.52
    rig.set_motion(Vector2.ZERO,1,false,false,1)
    rig.boost_blend=0
    rig._process(0)
    check(rig.expression_index==2,"Natural blink expression missing")
    rig.reduced_motion=true
    rig._process(1.0/60)
    check(skin.polygon==skin.rest,"Reduced motion retains tail deformation")
    rig.reset_performance()
    check(rig.tail_tuck==0 and rig.cycle_pose==Vector4.ZERO,"Restart retains a curled pose")
    root.remove_child(level)
    level.free()
    print("SARAH FLUID MOTION: %s checks, %s failures" % [checks,failures])
    quit(0 if failures==0 else 1)

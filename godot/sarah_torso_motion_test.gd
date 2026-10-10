extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error("SARAH TORSO: "+message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var rig = load("res://godot/sarah_rig.gd").new()
    root.add_child(rig)
    rig.set_process(false)
    rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.jump_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    var uv: PackedVector2Array = rig.bodice.uv.duplicate()
    var tail_uv: PackedVector2Array = rig.tail_skin.uv.duplicate()
    var maximum_ribs := 0.0
    var maximum_waist := 0.0
    var maximum_breath := 0.0
    var signature_low := INF
    var signature_high := -INF
    for fps in [30,60,120]:
        for facing in [-1.0,1.0]:
            rig.reset_jump();rig.reset_performance()
            for style in rig.SwimStyles.NAMES:
                rig.swim_style_override=style
                rig.set_waterfall_context("descent" if style.begins_with("waterfall") else "")
                var vertical := -330.0 if style.begins_with("rise") else (330.0 if style.begins_with("dive") else 0.0)
                rig.set_motion(Vector2(345*facing,vertical),facing,style.begins_with("boost"),false,1)
                for i in range(fps*2):
                    var prior: Vector2 = rig.torso_motion.ribs
                    rig._process(1.0/fps)
                    var motion = rig.torso_motion
                    check(absf(motion.rib_angle)<=.0551 and absf(motion.waist.x)<=.0451,"Torso joint exceeds bounded range")
                    check(absf(motion.breath.x)<=.0066 and absf(motion.lift.x)<=.401,"Rib volume/lift overstretches painting")
                    check(absf(motion.ribs.x-prior.x)<.012,"Rib transition snaps")
                    var collar := Vector2(3.52,-4.04)
                    var neck: Vector2 = rig.head_joint.position+collar.rotated(rig.head_joint.rotation)
                    check(neck.distance_to(motion.chest_point(Vector2(39.02,-32.04)))<.0001,"Neck loses moving chest socket")
                    check(rig.near_arm.position.distance_to(motion.chest_point(Vector2(22,-28)+rig.definitive_motion.shoulder_near))<.0001,"Shoulder misses ribcage motion")
                    check(is_equal_approx(rig.tail_skin.root_bend,motion.waist.x),"Waist and proximal tail use different signals")
                    check(rig.bodice.uv==uv and rig.tail_skin.uv==tail_uv,"Torso/tail UV registration slides")
                    check(is_equal_approx(rig.face_details.surface.get_shader_parameter("neck_follow"),rig.spine_motion.neck.x),"Neck skin misses cervical response")
                    check(rig.tail_skin.position==Vector2(1,6),"Hip socket drifts")
                    maximum_ribs=maxf(maximum_ribs,absf(motion.ribs.x))
                    maximum_waist=maxf(maximum_waist,absf(motion.waist.x))
                    maximum_breath=maxf(maximum_breath,absf(motion.breath.x))
                    signature_low=minf(signature_low,motion.ribs.x-motion.waist.x)
                    signature_high=maxf(signature_high,motion.ribs.x-motion.waist.x)
                    if i%15==0:
                        var length := 0.0
                        for segment in range(1,rig.tail_skin.centers.size()): length+=rig.tail_skin.centers[segment].distance_to(rig.tail_skin.centers[segment-1])
                        check(absf(length-rig.tail_skin.tail_length)<.002,"Waist bend stretches tail length")
                        for point in range(rig.bodice.rest.size()):
                            var rest: Vector2 = rig.bodice.rest[point]
                            var t: float = (rest.y+40)/60
                            check(rig.bodice.polygon[point].is_finite(),"Torso geometry invalid")
                            if t>=.94: check(rig.bodice.polygon[point].distance_to(rest)<.0001,"Bottom hip band separates")
                            elif t<=.18: check(rig.bodice.polygon[point].distance_to(motion.chest_point(rest))<.0001,"Painted collar misses ribs")
    check(maximum_ribs>.015 and maximum_waist>.012 and maximum_breath>.004,"Ribs/waist/volume remain rigid")
    check(signature_high-signature_low>.02,"Ribcage and waist are one rigid response")
    for gentle in [true,false]:
        rig.reduced_motion=gentle;rig.set_quality(gentle)
        rig._process(1.0/60)
        check(rig.torso_motion.rib_transform==Transform2D.IDENTITY and rig.tail_skin.root_bend==0,"Motion settings leave torso deformation")
        check(rig.bodice.polygon==rig.bodice.rest,"Fallback does not restore bodice")
    rig.set_quality(true);rig.reduced_motion=false;rig.reset_performance()
    check(rig.torso_motion.ribs==Vector2.ZERO and rig.torso_motion.waist==Vector2.ZERO and rig.tail_skin.root_bend==0,"Restart retains torso momentum")
    var endpoints := []
    for fps in [30,60,120]:
        rig.reset_jump();rig.reset_performance()
        rig.swim_style_override="front_crawl"
        rig.set_motion(Vector2(345,-120),1,false,false,1)
        for tick in range(fps*3): rig._process(1.0/fps)
        endpoints.append([rig.torso_motion.ribs.x,rig.torso_motion.waist.x,rig.torso_motion.breath.x,rig.torso_motion.chest_point(Vector2(39.02,-32.04))])
    check(absf(endpoints[0][0]-endpoints[2][0])<.003,"Ribs differ across refresh rates")
    check(absf(endpoints[0][1]-endpoints[2][1])<.003,"Waist differs across refresh rates")
    check(absf(endpoints[0][2]-endpoints[2][2])<.00015,"Rib volume differs across refresh rates")
    check(endpoints[0][3].distance_to(endpoints[2][3])<.08,"Moving collar differs across refresh rates")
    rig.free()
    print("SARAH TORSO: %d checks, %d failures" % [checks,failures])
    quit(0 if failures==0 else 1)

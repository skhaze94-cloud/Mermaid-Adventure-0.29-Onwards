extends SceneTree
const Points = preload("res://godot/sarah_performance_points.gd")
const Cycles = preload("res://godot/sarah_pose_cycles.gd")
const Styles = preload("res://godot/sarah_swim_styles.gd")
const Arms = preload("res://godot/sarah_arm_cycles.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error("DEFINITIVE REVIEW: "+message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    Points.build(); Arms.build(); Cycles.build()
    for name in Cycles.NAMES:
        for point in Cycles.cycles[name]:
            check(point.is_finite() and absf(point.y)<1.0,"Invalid dense body control point")
        check(Cycles.sample(name,0).distance_to(Cycles.sample(name,TAU))<.00001,"Dense body loop seam")
    check(Cycles.POSES>=144*3 and Styles.SAMPLES>=144*3,"Movement points not tripled")
    check(Arms.KEYS.size()>=8*3,"Breaststroke controls not tripled")
    check(Points.tracks.size()==22 and Points.SAMPLES>=432,"New coordinated performance tracks missing")
    for name in Points.tracks:
        check(Points.tracks[name][0].size()==432 and Points.tracks[name][1].size()==432,"Incomplete performance point library")
        for i in range(432):
            var point := Points.sample(name,float(i)*TAU/432)
            var a: Vector4 = point[0]
            var b: Vector3 = point[1]
            check(a.is_finite() and b.is_finite(),"Non-finite control point")
            check(absf(a.x)<1 and absf(a.y)<1 and absf(a.z)<1 and absf(a.w)<1,"Socket travel too large")
            check(absf(b.x)<.08 and b.y>=0 and b.y<.56,"Head/jaw point outside safe range")
        var left := Points.sample(name,-.0001)
        var right := Points.sample(name,.0001)
        check(left[0].distance_to(right[0])<.001 and left[1].distance_to(right[1])<.001,"Performance loop seam")
    var rig = load("res://godot/sarah_rig.gd").new()
    root.add_child(rig)
    rig.set_process(false)
    rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.jump_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    var uv: PackedVector2Array = rig.bodice.uv.duplicate()
    var max_near := 0.0
    var max_head := 0.0
    var max_jaw := 0.0
    for fps in [30,60,120]:
        rig.reset_jump(); rig.reset_performance()
        for name in Styles.NAMES:
            rig.swim_style_override=name
            rig.set_motion(Vector2(345,-120 if name.begins_with("rise") else 0),1,name.begins_with("boost"),false,1)
            for i in range(fps*2):
                var previous: Vector2 = rig.near_arm.position
                var old_head: float = rig.head_joint.rotation
                var old_jaw: float = rig.spine_motion.jaw.x
                rig._process(1.0/fps)
                check(rig.near_arm.position.distance_to(previous)<.30,"Shoulder socket transition snaps")
                check(absf(rig.head_joint.rotation-old_head)<.025,"Head transition snaps")
                check(absf(rig.spine_motion.jaw.x-old_jaw)<.06,"Jaw transition snaps")
                check(rig.near_arm.position.distance_to(Vector2(22,-28))<1.0,"Shoulder leaves overlap band")
                check(rig.far_arm.position.distance_to(Vector2(34,-25))<1.0,"Far shoulder leaves overlap band")
                check(rig.bodice.uv==uv,"Shoulder painting slips in its UVs")
                check(is_equal_approx(rig.face_details.surface.get_shader_parameter("jaw_open"),rig.spine_motion.jaw.x),"Jaw shader misses performance signal")
                max_near=maxf(max_near,rig.near_arm.position.distance_to(Vector2(22,-28)))
                max_head=maxf(max_head,absf(rig.head_joint.rotation))
                max_jaw=maxf(max_jaw,rig.spine_motion.jaw.x)
        for action in ["greet","cast","celebrate","impact","reward"]:
            rig.reset_performance(); rig.play_gesture(action)
            for i in range(fps):
                rig.gesture_player.advance(1.0/fps);rig._process(1.0/fps)
                check(absf(rig.head_joint.rotation)<=.101 and rig.spine_motion.jaw.x<=.56,"Gesture fights bounded head/jaw motion")
        for style in range(6):
            rig.reset_jump();rig.reset_performance()
            rig.jump_style=style
            rig.set_motion(Vector2(310,-120),1,false,true,1)
            for i in range(fps):
                rig.set_jump_state("airborne",float(i)/fps*.88,style,1)
                rig._process(1.0/fps)
                check(rig.near_arm.position.is_finite() and rig.spine_motion.jaw.is_finite(),"Aerial details invalid")
        rig.reduced_motion=true; rig._process(1.0/fps)
        check(rig.near_arm.position==Vector2(22,-28) and rig.spine_motion.jaw==Vector2.ZERO,"Gentle Motion retains dynamic detail")
        rig.reduced_motion=false; rig.set_quality(false);rig._process(1.0/fps)
        check(rig.far_arm.position==Vector2(34,-25) and rig.definitive_motion.expression==Vector3.ZERO,"Economy retains new tracks")
        rig.set_quality(true);rig.reset_performance()
        check(rig.definitive_motion.expression==Vector3.ZERO and rig.definitive_motion.head_spring==Vector2.ZERO,"Restart retains detail momentum")
    check(max_near>.30 and max_head>.025 and max_jaw>.20,"Performance remains static")
    var endpoints := []
    for fps in [30,60,120]:
        rig.reset_jump();rig.reset_performance()
        rig.swim_style_override="front_crawl"
        rig.set_motion(Vector2(345,-120),1,false,false,1)
        for tick in range(fps*3): rig._process(1.0/fps)
        endpoints.append([rig.near_arm.position,rig.head_joint.rotation,rig.spine_motion.jaw.x])
    check(endpoints[0][0].distance_to(endpoints[2][0])<.08,"Shoulder response differs across refresh rates")
    check(absf(endpoints[0][1]-endpoints[2][1])<.008,"Head response differs across refresh rates")
    check(absf(endpoints[0][2]-endpoints[2][2])<.02,"Jaw response differs across refresh rates")
    rig.free()
    print("DEFINITIVE REVIEW: %d checks, %d failures" % [checks,failures])
    quit(0 if failures==0 else 1)

extends SceneTree
const Styles = preload("res://godot/sarah_swim_styles.gd")
const Cycles = preload("res://godot/sarah_pose_cycles.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, why: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("ULTIMATE SARAH: "+why)
func advance(rig, seconds: float, fps: int = 60) -> void:
    for i in range(int(seconds*fps)): rig._process(1.0/fps)
func hand(rig) -> Vector2:
    return rig.arm_meshes[1].to_global(rig.arm_meshes[1].polygon[164])
func run() -> void:
    Styles.build()
    Cycles.build()
    check(Cycles.NAMES.size()==36 and Cycles.POSES==432,"Tripled movement sampling missing")
    var signatures: Array[Vector3] = []
    for style in Styles.NAMES:
        check(Styles.tracks[style][0].size()==432,"Dense arm tracks missing")
        var signature := Styles.sample(style,.7)+Styles.sample(style,2.2)*.5
        for other in signatures: check(signature.distance_to(other)>.01,"Duplicated swim stroke: "+style)
        signatures.append(signature)
        for far in [false,true]:
            var seam := Styles.sample(style,0,far)
            check(seam.distance_to(Styles.sample(style,TAU,far))<.00001,"Loop seam: "+style)
            var left := (seam-Styles.sample(style,-.001,far))/.001
            var right := (Styles.sample(style,.001,far)-seam)/.001
            check(left.distance_to(right)<.02,"Loop velocity seam: "+style)
            for tick in range(Styles.SAMPLES):
                var pose := Styles.sample(style,float(tick)*TAU/Styles.SAMPLES,far)
                check(pose.is_finite() and pose.y > -1.30 and absf(pose.z)<.3,"Joint range: "+style)
    var level = load("res://godot/highland_level.tscn").instantiate()
    root.add_child(level)
    level.set_process(false)
    level.set_physics_process(false)
    var rig = level.native_rig
    rig.set_process(false)
    rig.gesture_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.jump_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    var node_count: int = rig.get_child_count()
    var uv: PackedVector2Array = rig.arm_meshes[1].uv.duplicate()
    var tail_uv: PackedVector2Array = rig.tail_skin.uv.duplicate()
    # Real input contexts must choose actual different strokes, without overrides.
    for state in [[Vector2(280,0),false,"","breaststroke"],
            [Vector2(345,0),false,"","front_crawl"],
            [Vector2(160,0),false,"","sidestroke"],
            [Vector2(30,-330),false,"","rise_scoop"],
            [Vector2(30,330),false,"","dive_spear"],
            [Vector2(760,0),true,"","boost_dolphin"],
            [Vector2.ZERO,false,"descent","waterfall_scull"],
            [Vector2(760,0),true,"descent","waterfall_surge"]]:
        rig.reset_performance()
        rig.set_waterfall_context(state[2])
        rig.set_motion(state[0],1,state[1],false,1)
        advance(rig,1.5)
        check(rig.swim_style==state[3],"Wrong automatic stroke: "+state[3])
    # Extended swimming selects a second distinct stroke with no player menu.
    rig.reset_performance()
    rig.set_motion(Vector2(345,0),1,false,false,1)
    var seen := {}
    for tick in range(720):
        rig._process(1.0/60)
        seen[rig.swim_style] = true
    check(seen.has("front_crawl") and seen.has("butterfly"),"Sustained speed lacks stroke variety")
    for state in [[345.0,0.0,false,"","butterfly"], [345.0,-330.0,false,"","rise_alternate"],
            [345.0,330.0,false,"","dive_sweep"], [760.0,0.0,true,"","boost_drive"]]:
        check(Styles.choose(state[0],state[1],TAU*3.2,state[2],state[3])==state[4],"Second stroke unreachable: "+state[4])
    # Direction/boost/current transitions preserve the real painted geometry.
    var previous_hand := hand(rig)
    var previous_fin: Vector2 = rig.tail_skin.tip_center
    for state in [[Vector2(280,0),false,""],[Vector2(0,-345),false,""],
            [Vector2(0,345),false,""],[Vector2(0,-760),true,""],
            [Vector2(0,760),true,""],[Vector2.ZERO,false,"pull"],
            [Vector2.ZERO,false,"descent"],[Vector2(120,-430),false,"descent"],
            [Vector2(-120,430),false,"descent"],[Vector2(760,0),true,"descent"],
            [Vector2.ZERO,false,"outflow"],[Vector2.ZERO,false,""]]:
        rig.set_waterfall_context(state[2])
        rig.set_motion(state[0],1,state[1],false,1)
        for tick in range(120):
            rig._process(1.0/120)
            var current_hand := hand(rig)
            check(current_hand.distance_to(previous_hand)<14,"Hand snaps between contexts")
            check(rig.tail_skin.tip_center.distance_to(previous_fin)<14,"Fluke snaps between contexts")
            previous_hand=current_hand
            previous_fin=rig.tail_skin.tip_center
            for mesh in rig.arm_meshes:
                check(mesh.polygon[0]==mesh.rest[0],"Shoulder seam moves")
                check(mesh.polygon[164].is_finite(),"Hand geometry invalid")
    check(rig.arm_meshes[1].uv==uv and rig.tail_skin.uv==tail_uv,"Painting shifts during strokes")
    check(rig.get_child_count()==node_count,"Animation allocates rig nodes")
    # Six independently reachable aerial performances, with bounded rotation.
    rig.reset_performance()
    var jumps := {}
    for i in range(6):
        rig.start_jump(0,1)
        jumps[rig.jump_style] = rig._jump_roll(.38)
        check(is_zero_approx(rig._jump_roll(0)),"Jump begins with a rotation snap")
        check(absf(rig._jump_roll(1))<.001 or rig.jump_style==2,"Jump ends with a rotation snap")
    check(jumps.size()==6,"Aerial library was not doubled")
    check(absf(jumps[3]-jumps[4])>.05 and absf(jumps[4]-jumps[5])>.05,"New jumps duplicate each other")
    rig.reset_jump()
    # Compare continuous phase and joints after equal real time at each refresh rate.
    var endpoints := []
    for fps in [30,60,120]:
        rig.reset_performance()
        rig.set_motion(Vector2(280,0),1,false,false,1)
        advance(rig,2,fps)
        rig.set_motion(Vector2(60,-330),1,false,false,1)
        advance(rig,2,fps)
        endpoints.append([rig.swim_clock,rig.arm_pose_near,rig.cycle_pose])
    check(absf(endpoints[0][0]-endpoints[2][0])<.12,"Cadence varies by refresh rate")
    check(endpoints[0][1].distance_to(endpoints[2][1])<.14,"Arm motion varies by refresh rate")
    check(endpoints[0][2].distance_to(endpoints[2][2])<.08,"Tail motion varies by refresh rate")
    # Actual waterfall integration uses viewport width, including small screens.
    root.size=Vector2i(844,390)
    root.content_scale_size=Vector2i(844,390)
    await process_frame
    level.waterfall_phase="descent"
    level.waterfall_velocity=Vector2(.6,-260)
    level._sync_native_visuals()
    check(rig.waterfall_context=="descent","Waterfall does not reach animation system")
    check(is_equal_approx(rig.velocity_value.x,.6*minf(level.get_viewport_rect().size.x*.4,520.0)),"Waterfall visual speed ignores viewport")
    level._set_paused(true)
    check(not rig.can_process(),"Animation continues while paused")
    level._set_paused(false)
    rig.reduced_motion=true
    advance(rig,1)
    check(rig.tail_skin.polygon==rig.tail_skin.rest and rig.arm_meshes[1].polygon==rig.arm_meshes[1].rest,"Gentle motion deforms meshes")
    rig.reduced_motion=false
    rig.set_quality(false)
    advance(rig,1)
    check(rig.arm_meshes[1].polygon==rig.arm_meshes[1].rest,"Economy retains expensive skin")
    rig.set_quality(true)
    level._restart()
    check(rig.waterfall_context=="" and rig.swim_style=="breaststroke" and rig.visual_travel==Vector2.ZERO,"Restart retains stroke/current state")
    level.free()
    print("ULTIMATE SARAH: %d checks, %d failures" % [checks,failures])
    quit(1 if failures else 0)

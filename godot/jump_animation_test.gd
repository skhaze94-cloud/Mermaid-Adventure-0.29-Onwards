extends SceneTree
var failures := 0
func _initialize() -> void:
    call_deferred("_run")
func check(ok: bool, reason: String) -> void:
    if not ok:
        failures += 1
        push_error("JUMP ANIMATION TEST: " + reason)
func _run() -> void:
    var level = load("res://godot/highland_level.tscn").instantiate()
    root.add_child(level)
    level.set_process(false)
    level.set_physics_process(false)
    var rig = level.native_rig
    var fx = level.jump_effects
    rig.set_process(false)
    fx.set_process(false)
    rig.jump_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    check(rig.jump_player.has_animation("launch") and rig.jump_player.has_animation("land"), "Native timelines missing")
    var node_count: int = fx.get_child_count()
    level.player = Vector2(220,830)
    level.facing = -1.0
    level._jump()
    check(rig.jump_player.current_animation == "launch", "Launch animation did not start")
    rig.jump_player.advance(0.07)
    rig._process(1.0/60.0)
    check(rig.launch_curl > 0.9, "Takeoff anticipation key not applied")
    rig.set_jump_state("airborne",0.32,0,-1.0)
    check(rig.airborne_clearance(80.0) > 0.0, "Turn must keep painted fins inside viewport")
    var saw_joy := false
    var saw_left := false
    var saw_right := false
    var saw_depth := false
    var saw_overlap := false
    var saw_air := false
    var previous_progress := 0.0
    for i in range(20):
        var progress: float = rig.spin_curve.sample_baked(float(i)/19.0)
        check(progress >= previous_progress-0.001 and progress >= 0 and progress <= 1.001, "Flip curve overshoots or reverses")
        previous_progress = progress
    for i in range(220):
        level._physics_process(1.0/60.0)
        level._sync_native_visuals()
        rig.jump_player.advance(1.0/60.0)
        rig._process(1.0/60.0)
        fx._process(1.0/60.0)
        if level.leap_phase == "airborne":
            saw_air = true
            saw_joy = saw_joy or (rig.jump_joy_near > 0.8 and rig.jump_joy_far > 0.8)
            saw_left = saw_left or rig.corkscrew < -0.1
            saw_right = saw_right or rig.corkscrew > 0.1
            check(absf(rig.rotation-rig.body_pitch*rig.facing_value) < 0.35, "Small corkscrew became a full somersault")
            saw_depth = saw_depth or absf(rig.depth_turn) > 0.15
            saw_overlap = saw_overlap or rig.far_arm.z_index > rig.near_arm.z_index
            check(rig.torso.scale.x >= 0.88 and rig.near_arm.scale.x >= 0.80, "Depth projection collapses the painted body")
            check(rig.jump_direction == -1.0, "Flip direction must remain locked")
        if saw_air and level.leap_phase == "": break
    check(saw_joy and saw_left and saw_right, "Corkscrew needs opposing turns and independent raised arms")
    check(saw_depth and saw_overlap, "Airborne roll needs perspective and changing limb overlap")
    check(saw_air and fx.surface_events == 2, "Exactly one breach and one landing spray required")
    check(fx.last_surface.y == level.WATER_SURFACE, "Splash must be at waterline, not Sarah centre")
    check(rig.jump_player.current_animation == "land", "Landing timeline did not start")
    rig.jump_player.advance(0.06)
    rig._process(1.0/60.0)
    check(rig.landing_compress > 0.9, "Landing spring key missing")
    level._jump()
    check(rig.jump_style == 1, "Second jump should reverse corkscrew handedness")
    check(level.splash_chain == 1 and rig.jump_player.current_animation == "launch", "Chained jump must replace landing cleanly")
    check(rig.landing_compress == 0.0, "Chain inherits old landing squash")
    for i in range(100): fx.update_jump(Vector2(i*10,200),float(i),"airborne",i/30.0,false,true)
    check(fx.world_points.size() <= fx.TRAIL_LIMIT and fx.get_child_count() == node_count, "Effects must stay bounded")
    fx.emit_surface(Vector2(1200,280),3,true)
    var slot: int = (fx.cursor-1+fx.POOL_SIZE)%fx.POOL_SIZE
    var before: float = fx.droplets[slot].position.x
    var old_camera: float = fx.camera_x
    fx.update_jump(Vector2(1200,200),old_camera+50,"airborne",4,false,true)
    check(is_equal_approx(fx.droplets[slot].position.x,before-50), "Surface particles must follow camera pan")
    rig.reduced_motion = true
    rig.set_jump_state("airborne",0.44,1,-1)
    rig._process(1.0/60.0)
    check(rig.jump_joy_near == 0.0 and rig.jump_joy_far == 0.0 and rig.corkscrew == 0.0, "Gentle motion retains playful gestures")
    check(rig.depth_turn == 0.0 and rig.torso.scale == Vector2.ONE, "Gentle motion retains depth distortion")
    check(absf(rig.rotation) < 0.3, "Gentle motion must omit full spin")
    fx.update_jump(Vector2.ZERO,0,"airborne",5,true,false)
    var events: int = fx.surface_events
    fx.emit_surface(Vector2(1000,280),0,true)
    check(not fx.visible and fx.world_points.is_empty() and fx.surface_events == events, "Gentle motion must clear ribbons and suppress spray")
    level._set_paused(true)
    check(not rig.jump_player.can_process() and not fx.can_process(), "Jump choreography continues while paused")
    level._set_paused(false)
    level._restart()
    check(rig.jump_phase == "" and rig.launch_curl == 0 and rig.landing_compress == 0, "Restart leaves jump pose")
    check(rig.jump_style_cursor == 0 and rig.jump_joy_near == 0 and rig.torso.skew == 0, "Restart keeps corkscrew state")
    check(fx.world_points.is_empty(), "Restart leaves previous ribbon")
    root.remove_child(level)
    level.free()
    if failures == 0: print("GODOT JUMP ANIMATION TEST PASSED")
    quit(0 if failures == 0 else 1)

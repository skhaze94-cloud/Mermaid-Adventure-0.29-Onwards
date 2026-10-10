extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var out := OS.get_environment("ADVENTURE_CAPTURE_DIR")
    if out.is_empty(): quit(1); return
    DirAccess.make_dir_recursive_absolute(out)
    root.get_node("OceanAudio").playback_enabled=false
    root.get_node("AppPreferences").persist_enabled=false
    var level = load("res://godot/highland_level.tscn").instantiate()
    root.add_child(level)
    level.set_process(false)
    level.set_physics_process(false)
    var rig = level.native_rig
    rig.set_process(false)
    rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.jump_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.reset_jump()
    rig.reset_performance()
    level._start_waterfall()
    level.invulnerable=0
    level.message_time=0
    for case in [["climb",Vector2(.15,-430),false], ["dive",Vector2(.15,430),false], ["boost",Vector2(.8,-100),true]]:
        level.waterfall_phase="descent"
        level.waterfall_time=8.0
        level.waterfall_velocity=case[1]
        level.waterfall_boost=1.0 if case[2] else 0.0
        level._sync_native_visuals()
        for tick in range(90): rig._process(1.0/60)
        level.queue_redraw()
        await process_frame
        await RenderingServer.frame_post_draw
        if root.get_texture().get_image().save_png(out+"/gameplay-waterfall-"+case[0]+".png")!=OK: quit(1); return
    print("ULTIMATE SARAH WATERFALL GAMEPLAY RENDERS PASSED")
    quit()

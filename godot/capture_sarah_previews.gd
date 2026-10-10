extends SceneTree
## Real Godot viewport renders; manual clocks make poses reproducible.
var output := "res://godot/sarah-previews"
func _initialize() -> void:
    call_deferred("_capture")
func _capture() -> void:
    var requested := OS.get_environment("ADVENTURE_CAPTURE_DIR")
    if not requested.is_empty(): output = requested
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
    root.get_node("OceanAudio").playback_enabled = false
    var level = load("res://godot/highland_level.tscn").instantiate()
    root.add_child(level)
    level.set_process(false)
    level.set_physics_process(false)
    var rig = level.native_rig
    rig.set_process(false)
    rig.gesture_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.jump_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    level.player = Vector2(1000,575)
    level.camera = 360.0
    level.message_time = 0.0
    for frame in range(4):
        await process_frame
    var poses := [
        {"name":"01-greeting","v":Vector2.ZERO,"gesture":"greet","at":0.35},
        {"name":"02-swim","v":Vector2(300,90)},
        {"name":"03-rise","v":Vector2(100,-260)},
        {"name":"04-turn","v":Vector2(210,0),"direction":-1.0,"ticks":6},
        {"name":"05-boost","v":Vector2(760,-80),"boost":true},
        {"name":"06-cast","v":Vector2(100,0),"gesture":"cast","at":0.105},
        {"name":"07-impact","v":Vector2(-200,60),"gesture":"impact","at":0.05},
        {"name":"08-reward","v":Vector2.ZERO,"gesture":"reward","at":0.12},
        {"name":"09-celebrate","v":Vector2.ZERO,"gesture":"celebrate","at":0.25},
        {"name":"10-gentle","v":Vector2(100,-260),"gentle":true},
        {"name":"11-economy","v":Vector2(300,0),"economy":true}
    ]
    for pose in poses:
        rig.reset_jump()
        rig.reset_performance()
        rig.reduced_motion = pose.get("gentle",false)
        rig.set_quality(not pose.get("economy",false))
        level.player_velocity = pose["v"]
        level.facing = pose.get("direction",1.0)
        level.boost_time = 1.0 if pose.get("boost",false) else 0.0
        level._sync_native_visuals()
        if pose.has("gesture"):
            rig.play_gesture(pose["gesture"])
            rig.gesture_player.advance(pose["at"])
        for tick in range(pose.get("ticks",28)):
            rig._process(1.0/60.0)
        level.queue_redraw()
        await process_frame
        await RenderingServer.frame_post_draw
        var image := root.get_texture().get_image()
        if image.save_png(output+"/"+pose["name"]+"-full.png") != OK:
            push_error("Sarah capture failed")
            quit(1)
            return
        image.get_region(Rect2i(460,415,380,280)).save_png(output+"/"+pose["name"]+".png")
        print("SARAH PREVIEW CAPTURED: "+pose["name"])
    # A 2.4-second native animation loop shows fluidity, rather than only still poses.
    rig.reduced_motion = false
    rig.set_quality(true)
    rig.reset_performance()
    rig.set_motion(Vector2(260,20),1.0,false,false,1.0)
    for frame in range(24):
        if frame == 6:
            rig.play_gesture("greet")
        rig.gesture_player.advance(1.0/12.0)
        rig._process(1.0/12.0)
        level.queue_redraw()
        await process_frame
        await RenderingServer.frame_post_draw
        var image := root.get_texture().get_image()
        image.get_region(Rect2i(460,415,380,280)).save_png(output+"/loop-%02d.png" % frame)
    root.remove_child(level)
    level.free()
    print("GODOT SARAH MAGNIFIQUE RENDER TEST PASSED")
    quit(0)

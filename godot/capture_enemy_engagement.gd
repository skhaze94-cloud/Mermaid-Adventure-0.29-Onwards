extends SceneTree
func _initialize() -> void:
    call_deferred("_capture")
func _capture() -> void:
    var output := "res://godot/enemy-previews"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
    var level = load("res://godot/highland_level.tscn").instantiate()
    root.add_child(level)
    level.set_process(false)
    level.set_physics_process(false)
    level.native_rig.set_process(false)
    level._start_waterfall()
    level.waterfall_phase = "descent"
    level.waterfall_time = 5.65
    level.time = 5.65
    level.invulnerable = 100.0
    level.message_time = 0.0
    for frame in range(48):
        for tick in range(4):
            level._physics_process(1.0/60.0)
            level._sync_native_visuals()
            level.native_rig._process(1.0/60.0)
        level.waterfall_enemies.animate_visible(0.0,level.time,false,1.0/15.0,true,true)
        level.queue_redraw()
        await process_frame
        await RenderingServer.frame_post_draw
        var image := root.get_texture().get_image()
        image.resize(700,480,Image.INTERPOLATE_LANCZOS)
        image.save_png(output+"/engagement-%02d.png" % frame)
    root.remove_child(level)
    level.free()
    print("GODOT ENEMY ENGAGEMENT RENDER TEST PASSED")
    quit(0)

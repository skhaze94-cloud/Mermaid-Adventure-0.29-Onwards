extends SceneTree
## Actual native rig poses sampled along the real fixed-tick jump trajectory.
var output := "res://godot/jump-previews"
func _initialize() -> void:
    call_deferred("_capture")
func _capture() -> void:
    var level = load("res://godot/highland_level.tscn").instantiate()
    root.add_child(level)
    level.set_process(false)
    level.set_physics_process(false)
    level.native_rig.set_process(false)
    level.jump_effects.set_process(false)
    level.native_rig.jump_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    level.player = Vector2(1000,460)
    level.camera = 350.0
    level.obstacles.clear() # Capture staging only; production geometry is unchanged.
    level.health = 5
    level.invulnerable = 10.0
    level.message_time = 0.0
    if "--reverse" in OS.get_cmdline_user_args():
        level.native_rig.jump_style_cursor = 1
        output += "/reverse"
    level._jump()
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
    var indices := [4,12,17,25,33,43,54,67,78,89]
    var shot := 0
    for tick in range(96):
        level._physics_process(1.0/60.0)
        level.camera = 350.0
        level.message_time = 0.0
        level._sync_native_visuals()
        level.native_rig.jump_player.advance(1.0/60.0)
        level.native_rig._process(1.0/60.0)
        level.jump_effects._process(1.0/60.0)
        level.queue_redraw()
        if tick % 2 == 0 or tick in indices:
            await process_frame
            await RenderingServer.frame_post_draw
            var image := root.get_texture().get_image()
            if image.is_empty():
                push_error("Jump preview empty")
                quit(1)
                return
            if tick % 2 == 0:
                var motion_image := image.duplicate()
                motion_image.resize(700,480,Image.INTERPOLATE_LANCZOS)
                motion_image.save_png(ProjectSettings.globalize_path(output+"/motion-%02d.png" % (tick/2)))
            if tick not in indices:
                continue
            image.save_png(ProjectSettings.globalize_path(output+"/jump-%02d.png" % shot))
            print("JUMP PREVIEW %02d phase=%s air=%.2f" % [shot,level.leap_phase,level.leap_air_time])
            shot += 1
    root.remove_child(level)
    level.free()
    print("GODOT JUMP RENDER TEST PASSED")
    quit(0)

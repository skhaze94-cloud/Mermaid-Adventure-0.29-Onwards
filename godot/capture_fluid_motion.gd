extends SceneTree
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
    root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
    root.content_scale_size = Vector2i(800,450)
    root.size = Vector2i(800,450)
    var out := OS.get_environment("ADVENTURE_CAPTURE_DIR")
    assert(not out.is_empty())
    DirAccess.make_dir_recursive_absolute(out)
    var background := TextureRect.new()
    background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background.texture = preload("res://godot/assets/environment-lake-v011.webp")
    background.size = Vector2(800,450)
    background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    root.add_child(background)
    var rig = load("res://godot/sarah_rig.gd").new()
    root.add_child(rig)
    rig.set_process(false)
    rig.position = Vector2(458,255)
    rig.gesture_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.jump_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    var label := Label.new()
    label.position = Vector2(24,20)
    label.add_theme_font_size_override("font_size",24)
    root.add_child(label)
    var serial := 0
    rig.reset_jump()
    rig.reset_performance()
    for mode in ["idle","swim","boost","tuck"]:
        var v := Vector2.ZERO if mode=="idle" else Vector2(300,20)
        rig.set_motion(Vector2(700,0) if mode=="boost" else v,1,mode=="boost",mode=="tuck",1)
        label.text = {"idle":"Sarah Maria · Gentle idle","swim":"Sarah Maria · Breaststroke","boost":"Sarah Maria · Dash reach","tuck":"Sarah Maria · Tail tuck"}[mode]
        if mode=="idle":
            for i in range(30): rig._process(1.0/60)
        var count: int = 96 if mode=="swim" else (48 if mode=="boost" else 36)
        for frame in range(count):
            if mode=="tuck":
                var progress := float(frame)/(count-1)
                rig.set_jump_state("airborne",progress*.88,0,1)
            for i in range(2):
                rig.gesture_player.advance(1.0/48)
                rig.jump_player.advance(1.0/48)
                rig._process(1.0/48)
            # Preserve the performance's world scale while framing a close-up.
            rig.scale *= 1.8
            await process_frame
            await RenderingServer.frame_post_draw
            assert(root.get_texture().get_image().save_png(out+"/frame-%03d.png" % serial)==OK)
            serial += 1
    print("NATIVE FLUID MOTION PREVIEW PASSED: 216 frames")
    quit()

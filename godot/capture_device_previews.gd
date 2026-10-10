extends SceneTree
const Profiles = preload("res://godot/device_profiles.gd")
var failures := 0

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.content_scale_size = Vector2i(1400, 960)
    root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
    var level = load("res://godot/highland_level.tscn").instantiate()
    root.add_child(level)
    level.set_process(false)
    level.set_physics_process(false)
    level.simulated_touch = true
    var output := "res://godot/device-qa"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
    var metrics: Array[Dictionary] = []
    for profile in Profiles.cases():
        paused = false
        level.state = "playing"
        root.size = profile["size"]
        for frame in range(3):
            await process_frame
        level._restart()
        level.premium_hud.configure_layout(root.get_visible_rect().size, Vector2(root.size), profile["safe"])
        var portrait := String(profile["name"]) == "phone-portrait"
        var modes := ["portrait"] if portrait else ["waterfall", "pause"]
        for mode in modes:
            paused = false
            level.state = "playing"
            level.player = Vector2(level.Highland.WATERFALL_START, 450)
            level.waterfall_phase = "descent"
            level.waterfall_time = 8.5
            level.time = 8.5
            level.waterfall_hazards = level.Highland.waterfall_hazards()
            level.waterfall_gold = level.Highland.waterfall_gold()
            level.waterfall_x = 0.0
            level.waterfall_y = 0.0
            level.message_time = 0.0
            level._sync_native_visuals()
            if mode in ["pause", "portrait"]:
                level._set_paused(true)
            level.queue_redraw()
            for frame in range(4):
                await process_frame
            await RenderingServer.frame_post_draw
            var image := root.get_texture().get_image()
            var name: String = String(profile["name"]) + "-" + mode
            if image.is_empty() or image.save_png(output + "/" + name + ".png") != OK:
                failures += 1
                push_error("DEVICE RENDER FAILED: " + name)
                continue
            var thumbnail := image.duplicate()
            var height := int(round(560.0 * float(image.get_height()) / float(image.get_width())))
            thumbnail.resize(560, height, Image.INTERPOLATE_LANCZOS)
            thumbnail.save_jpg(output + "/" + name + "-review.jpg", 0.70)
            var record := {"profile": name, "render_width": image.get_width(),
                "render_height": image.get_height(), "ui_scale": level.premium_hud.ui_scale,
                "render_type": "CI software OpenGL; not physical-device performance"}
            metrics.append(record)
            print("DEVICE PREVIEW CAPTURED: " + JSON.stringify(record))
    paused = false
    var file := FileAccess.open(output + "/render-report.json", FileAccess.WRITE)
    file.store_string(JSON.stringify({"failures": failures, "renders": metrics}, "  "))
    file.close()
    root.remove_child(level)
    level.free()
    print("GODOT DEVICE RENDER TEST " + ("PASSED" if failures == 0 else "FAILED"))
    quit(0 if failures == 0 else 1)

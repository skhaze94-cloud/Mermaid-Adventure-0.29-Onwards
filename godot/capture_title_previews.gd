extends SceneTree
var failures := 0

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var prefs = root.get_node("AppPreferences")
    prefs.persist_enabled = false
    prefs.intro_seen = true
    prefs.reduced_motion = false
    prefs.economy = false
    root.content_scale_size = Vector2i(1400,960)
    root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
    var menu = load("res://godot/title_screen.tscn").instantiate()
    root.add_child(menu)
    var output := "res://godot/title-previews"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
    var shots := [
        ["desktop-menu", Vector2i(1400,960), "menu"],
        ["desktop-opening", Vector2i(1400,960), "intro"],
        ["desktop-options", Vector2i(1400,960), "options"],
        ["desktop-credits", Vector2i(1400,960), "credits"],
        ["phone-menu", Vector2i(640,360), "menu"],
        ["phone-options", Vector2i(640,360), "options"],
        ["tablet-menu", Vector2i(1024,768), "menu"],
        ["portrait-menu", Vector2i(390,844), "menu"]
    ]
    for shot in shots:
        root.size = shot[1]
        for i in range(4):
            await process_frame
        if shot[2] == "intro":
            menu.play_intro()
            menu._set_intro_card(1)
            menu.intro_clock = 4.0
        else:
            menu.show_page(shot[2])
        for i in range(4):
            await process_frame
        await create_timer(0.7).timeout
        await RenderingServer.frame_post_draw
        var image := root.get_texture().get_image()
        if image.is_empty() or image.save_png(output + "/" + shot[0] + ".png") != OK:
            failures += 1
            push_error("TITLE PREVIEW FAILED: " + shot[0])
        else:
            var thumb := image.duplicate()
            thumb.resize(700, int(700.0 * image.get_height() / image.get_width()), Image.INTERPOLATE_LANCZOS)
            thumb.save_jpg(output + "/" + shot[0] + "-review.jpg", 0.8)
            print("TITLE PREVIEW CAPTURED: " + shot[0])
    root.remove_child(menu)
    menu.free()
    print("GODOT TITLE RENDER TEST " + ("PASSED" if failures == 0 else "FAILED"))
    quit(0 if failures == 0 else 1)

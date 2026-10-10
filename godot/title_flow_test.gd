extends SceneTree
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, reason: String) -> void:
    if not ok:
        failures += 1
        push_error("TITLE FLOW: " + reason)

func frames(count := 4) -> void:
    for i in range(count):
        await process_frame

func _run() -> void:
    var preferences = root.get_node("AppPreferences")
    preferences.persist_enabled = false
    preferences.intro_seen = false
    preferences.reduced_motion = false
    preferences.economy = false
    preferences.music_volume = 0.8
    preferences.apply_audio()
    root.content_scale_size = Vector2i(1400, 960)
    root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
    var menu = load("res://godot/title_screen.tscn").instantiate()
    root.add_child(menu)
    current_scene = menu
    await frames()
    check(menu.page == "intro" and menu.skip.visible, "first launch does not show skippable intro")
    menu.intro_clock = 3.5
    menu._process(0.01)
    check(menu.intro_card == 1, "intro credits do not advance")
    menu.skip.pressed.emit()
    await frames()
    check(menu.page == "menu" and preferences.intro_seen, "skip does not reach menu")
    check(menu.primary.has_focus(), "primary play button has no keyboard/controller focus")
    # Exercise native controller navigation and activation, not only callbacks.
    var down := InputEventJoypadButton.new()
    down.button_index = JOY_BUTTON_DPAD_DOWN
    down.pressed = true
    Input.parse_input_event(down)
    await frames()
    down.pressed = false
    Input.parse_input_event(down)
    var focused := root.gui_get_focus_owner()
    check(focused is Button and focused.text == "Choose a chapter", "controller D-pad does not navigate to chapter selection")
    var accept := InputEventJoypadButton.new()
    accept.button_index = JOY_BUTTON_A
    accept.pressed = true
    Input.parse_input_event(accept)
    await frames()
    accept.pressed = false
    Input.parse_input_event(accept)
    await frames()
    check(menu.page == "chapters", "controller A does not activate chapter selection")
    menu.show_page("menu")
    await frames()
    var options = menu.content.get_children().filter(func(node): return node is Button and node.text == "Options")[0]
    var mouse := InputEventMouseButton.new()
    mouse.button_index = MOUSE_BUTTON_LEFT
    mouse.position = options.get_global_rect().get_center()
    mouse.pressed = true
    root.push_input(mouse, true)
    await frames()
    mouse.pressed = false
    root.push_input(mouse, true)
    await frames()
    check(menu.page == "options", "mouse does not activate the native Options button")
    for pixels in [Vector2i(640,360), Vector2i(844,390), Vector2i(1024,768), Vector2i(1920,1080), Vector2i(390,844)]:
        root.size = pixels
        await frames()
        for page in ["menu", "options", "controls", "credits"]:
            menu.show_page(page)
            await frames()
            var safe := Rect2(Vector2.ZERO, menu.ui_size)
            check(safe.encloses(Rect2(menu.scroll.position, menu.scroll.size)), str(pixels) + " " + page + " content outside safe area")
            check(menu.scroll.size.y > 100, "page has no usable scrolling area")
            var physical_scale: float = float(pixels.y) / root.get_visible_rect().size.y * menu.ui_scale
            check(menu.primary.size.y * physical_scale >= 44.0, str(pixels) + " action is too small to tap")
    menu.show_page("options")
    await frames()
    menu.music_slider.value = 25
    check(is_equal_approx(preferences.music_volume, 0.25), "volume slider does not update shared preference")
    menu.motion_toggle.button_pressed = true
    menu.quality_toggle.button_pressed = true
    check(preferences.reduced_motion and preferences.economy, "options do not update shared preferences")
    var back := InputEventKey.new()
    back.keycode = KEY_ESCAPE
    back.pressed = true
    menu._unhandled_input(back)
    check(menu.page == "menu", "Escape does not return from options")
    menu.play_intro()
    menu.intro_clock = 10.3
    menu._process(0.01)
    check(menu.page == "menu", "intro does not finish automatically")
    menu.start_adventure()
    menu.start_adventure()
    await frames(12)
    var level = current_scene
    check(is_instance_valid(level) and level.name == "FamilyTrainingLagoon", "Play does not load Avina tutorial")
    check(root.get_node("AdventureRun").active, "Begin adventure must activate the full adventure run")
    if is_instance_valid(level) and level.name == "FamilyTrainingLagoon":
        check(level.reduced_fx and not level.high_depth_quality, "level ignores menu graphics preferences")
        check(level.music_player.bus == "Music", "gameplay music does not use the shared bus")
        level.premium_hud.configure_layout(Vector2(1400,960), Vector2(1400,960))
        level._set_paused(true)
        check(paused and level.premium_hud.menu_button.visible, "pause has no return-to-menu control")
        level.premium_hud.menu_button.pressed.emit()
        await frames(12)
        check(not paused and current_scene.name == "SarahStorybookOpening", "return-to-menu leaves the scene tree paused")
        check(current_scene.page == "menu", "return-to-menu repeats the first-run intro")
    print("GODOT TITLE FLOW TEST " + ("PASSED" if failures == 0 else "FAILED"))
    quit(0 if failures == 0 else 1)


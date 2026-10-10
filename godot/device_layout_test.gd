extends SceneTree
const Profiles = preload("res://godot/device_profiles.gd")
const Controls = preload("res://godot/control_layout.gd")
var failures := 0
var report: Array[Dictionary] = []

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, reason: String) -> void:
    if not ok:
        failures += 1
        push_error("DEVICE QA: " + reason)

func touch(level, index: int, point: Vector2, pressed := true) -> void:
    var event := InputEventScreenTouch.new()
    event.index = index
    event.position = point
    event.pressed = pressed
    level._input(event)

func _run() -> void:
    var level = load("res://godot/highland_level.tscn").instantiate()
    root.add_child(level)
    level.set_process(false)
    level.set_physics_process(false)
    level.simulated_touch = true
    for profile in Profiles.cases():
        var name: String = profile["name"]
        var pixels := Vector2(profile["size"])
        var pixel_scale := minf(pixels.x / 1400.0, pixels.y / 960.0)
        var view := pixels / pixel_scale
        level._restart()
        level.premium_hud.configure_layout(view, pixels, profile["safe"])
        var hud = level.premium_hud
        if name == "phone-portrait":
            level._set_paused(true)
            check(hud.portrait and paused, "portrait rotation guard missing")
            level._touch_action("resume")
            check(paused, "portrait allows play behind rotate instruction")
            report.append({"profile": name, "rotation_guard": true})
            # Reset test override to a landscape layout before restarting.
            hud.configure_layout(Vector2(1400, 960), Vector2(1400, 960))
            continue
        var full := Rect2(Vector2.ZERO, view)
        var pad: Rect2 = level._pad_rect()
        check(full.encloses(pad) and hud.safe_frame.encloses(pad), name + " pad outside safe area")
        var minimum_touch := 9999.0
        level.bubble_unlocked = true
        for action in ["boost", "jump", "bubble", "pause", "resume", "restart"]:
            var rect: Rect2 = level._touch_rect(action, view)
            check(hud.safe_frame.encloses(rect), name + " " + action + " outside safe area")
            minimum_touch = minf(minimum_touch, minf(rect.size.x, rect.size.y) * pixel_scale)
            if action in ["boost", "jump", "bubble"]:
                check(not pad.intersects(rect), name + " overlapping pad and " + action)
                check(level._touch_target(rect.get_center()) == action, name + " input/art disagreement for " + action)
        check(minimum_touch >= 44.0, name + " physical touch target below 44 px")
        # A touch pair steers diagonally and boosts; release stops movement.
        touch(level, 2, pad.get_center() + Vector2(45, -45) * hud.ui_scale)
        touch(level, 5, level._touch_rect("boost", view).get_center())
        var direction: Vector2 = level._input_vector()
        check(direction.x > 0.6 and direction.y < -0.6 and level.boost_time > 0, name + " multitouch boost fails")
        touch(level, 2, Vector2.ZERO, false)
        touch(level, 5, Vector2.ZERO, false)
        check(level._input_vector() == Vector2.ZERO, name + " release leaves input stuck")
        # Sliding never transfers an action finger to another button.
        touch(level, 9, level._touch_rect("boost", view).get_center())
        var drag := InputEventScreenDrag.new()
        drag.index = 9
        drag.position = level._touch_rect("jump", view).get_center()
        level._input(drag)
        check(not level.touches.has(9) and level.leap_phase == "", name + " action drag triggers jump")
        touch(level, 9, Vector2.ZERO, false)
        touch(level, 10, level._touch_rect("pause", view).get_center())
        check(paused, name + " touch pause fails")
        touch(level, 11, level._touch_rect("resume", view).get_center())
        check(not paused, name + " touch resume fails")
        # Display/input reconfiguration invalidates old fingers.
        touch(level, 2, pad.get_center() + Vector2(60, 0) * hud.ui_scale)
        level._on_viewport_resized()
        check(level.touches.is_empty() and level.touch_vectors.is_empty(), name + " resize leaves held input")
        hud.configure_layout(view, pixels, profile["safe"])
        report.append({"profile": name, "window_px": pixels, "logical_view": view,
            "ui_scale": hud.ui_scale, "minimum_touch_px": minimum_touch,
            "multitouch_pause_resize": "passed"})
    level._restart()
    level.waterfall_world.set_phase("descent", 8.5, false, true)
    check(level.waterfall_world.visible and is_equal_approx(level.waterfall_world.modulate.a, 1.0), "descent painting must be opaque")
    check(is_equal_approx(float(level.waterfall_world.material_resource.get_shader_parameter("descent_progress")), 0.5), "shaft shader depth mismatch")
    level.waterfall_world.set_phase("pull", 0, false, true)
    check(is_zero_approx(level.waterfall_world.modulate.a), "inlet transition starts abruptly")
    level.waterfall_world.set_phase("outflow", 1.6, true, false)
    check(is_zero_approx(level.waterfall_world.modulate.a), "outflow transition does not clear")
    check(is_zero_approx(float(level.waterfall_world.material_resource.get_shader_parameter("motion_enabled"))), "reduced-motion waterfall remains animated")
    level.waterfall_world.set_phase("", 0, false, true)
    check(not level.waterfall_world.visible, "shaft remains outside waterfall")
    var output := "res://godot/device-qa"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
    var file := FileAccess.open(output + "/layout-report.json", FileAccess.WRITE)
    file.store_string(JSON.stringify({"test_type": "simulated viewport and input", "failures": failures, "profiles": report}, "  "))
    file.close()
    print("GODOT DEVICE LAYOUT TEST " + ("PASSED" if failures == 0 else "FAILED: " + str(failures)))
    paused = false
    root.remove_child(level)
    level.free()
    quit(0 if failures == 0 else 1)

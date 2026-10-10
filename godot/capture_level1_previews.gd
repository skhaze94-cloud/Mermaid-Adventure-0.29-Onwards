extends SceneTree
## Windowed GPU/LLVMpipe screenshot smoke test; never alters production scenes.
## Outputs are CI artifacts for actual visual inspection, not a gameplay substitute.
const Highland = preload("res://godot/highland_data.gd")

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var level = load("res://godot/highland_level.tscn").instantiate()
    root.add_child(level)
    var output := "res://godot/visual-previews"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
    for frame in range(5):
        await process_frame
    var shots := [
        {"name":"01-highland-entry", "x":950.0, "y":575.0, "fallen":false,
            "boss":0.0, "phase":""},
        {"name":"02-underwater-grotto", "x":Highland.route_x(9400.0), "y":545.0,
            "fallen":true, "boss":0.0, "phase":""},
        {"name":"03-waterfall-descent", "x":Highland.WATERFALL_START,
            "y":450.0, "fallen":false, "boss":0.0, "phase":"descent"},
        {"name":"04-carlo-court", "x":Highland.BOSS_X - 420.0,
            "y":570.0, "fallen":true, "boss":2.8, "phase":""}
    ]
    for shot in shots:
        level.fallen = bool(shot["fallen"])
        level.player = Vector2(float(shot["x"]), float(shot["y"]))
        level.camera = clampf(level.player.x - 480.0, 0.0,
            maxf(0.0, Highland.LEVEL_LENGTH - 1400.0))
        level.waterfall_phase = String(shot["phase"])
        level.boss_clock = float(shot["boss"])
        if level.waterfall_phase == "descent":
            level.waterfall_time = 5.0
            level.waterfall_hazards = Highland.waterfall_hazards()
            level.waterfall_gold = Highland.waterfall_gold()
        level._sync_native_visuals()
        level.queue_redraw()
        for frame in range(3):
            await process_frame
        # Avoid carrying an unrelated previous checkpoint caption into the
        # waterfall/Carlos' scene capture when reusing this one level instance.
        level.message_time = 0.0
        level.premium_hud.update_hud(level._hud_snapshot())
        level.queue_redraw()
        await process_frame
        await RenderingServer.frame_post_draw
        var image := root.get_texture().get_image()
        if image.is_empty():
            push_error("VISUAL PREVIEW FAILED: viewport screenshot empty")
            break
        var path := ProjectSettings.globalize_path(output + "/" + String(shot["name"]) + ".png")
        var saved := image.save_png(path)
        if saved != OK:
            push_error("VISUAL PREVIEW FAILED: cannot write " + path)
        else:
            print("VISUAL PREVIEW CAPTURED: " + path)
            # Small actual-render JPGs can be inspected directly in CI logs;
            # full-resolution lossless PNGs remain available as artifacts.
            var thumbnail := image.duplicate()
            thumbnail.resize(560, 384, Image.INTERPOLATE_LANCZOS)
            var jpg_path := ProjectSettings.globalize_path(
                output + "/" + String(shot["name"]) + "-review.jpg")
            thumbnail.save_jpg(jpg_path, 0.55)

    level.get_parent().remove_child(level)
    level.free()
    quit(0)

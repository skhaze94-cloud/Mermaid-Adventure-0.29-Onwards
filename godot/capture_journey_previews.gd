extends SceneTree
## Real native renders. Staging freezes physics only; production scenes are unchanged.
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
    root.size = Vector2i(1400,960)
    var out := OS.get_environment("JOURNEY_CAPTURE_DIR")
    if out.is_empty(): out = ProjectSettings.globalize_path("res://godot/journey-previews")
    DirAccess.make_dir_recursive_absolute(out)
    for path in ["res://godot/shadow_kingdom.tscn","res://godot/miguel_lagoon.tscn"]:
        var level = load(path).instantiate()
        root.add_child(level)
        level.set_physics_process(false)
        for frame in range(4): await process_frame
        var shots: Array = [["shadow-market",7100,500],["shadow-duo",13200,470]] if level.shadow else [["miguel-gardens",4000,570],["miguel-new-enemies",12500,520],["miguel-arena",21100,500]]
        for shot in shots:
            level.player = Vector2(shot[1],shot[2])
            level.camera = clampf(level.player.x-480,0,level._level_length()-1400)
            level.boss_clock = 4.5
            level._update_boss(0)
            level.message_time = 0
            level._sync_native_visuals()
            level.queue_redraw()
            for frame in range(5): await process_frame
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png(out+"/"+shot[0]+".png")
        root.remove_child(level)
        level.queue_free()
        await process_frame
    quit()

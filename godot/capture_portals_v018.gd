extends SceneTree
func _initialize() -> void: call_deferred("capture")
func frames() -> void:
    for i in range(3): await process_frame
func capture() -> void:
    root.size = Vector2i(1400,960)
    var out := OS.get_environment("ADVENTURE_CAPTURE_DIR")
    DirAccess.make_dir_recursive_absolute(out)
    root.get_node("AppPreferences").persist_enabled = false
    root.get_node("AppPreferences").intro_seen = true
    var catalog = root.get_node("AdventureRun")
    for index in range(1,catalog.SCENES.size()):
        var level = load(catalog.SCENES[index]).instantiate()
        root.add_child(level)
        level.set_physics_process(false)
        level.fallen = true
        level.boss_hp = 0
        level.player = Vector2(level._portal_x()-200,540)
        level.camera = clampf(level.player.x-550,0,level._level_length()-1400)
        level.message_time = 0
        level._sync_native_visuals()
        level.queue_redraw()
        await frames()
        await RenderingServer.frame_post_draw
        assert(root.get_texture().get_image().save_png(out+"/%s-portal.png" % index)==OK)
        root.remove_child(level)
        level.free()
        await frames()
    print("NATIVE PAINTED PORTAL CAPTURES PASSED: 7 chapters")
    quit()

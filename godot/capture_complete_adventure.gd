extends SceneTree
func _initialize() -> void: call_deferred("capture")
func frames(count := 5) -> void:
    for i in range(count): await process_frame
func capture() -> void:
    root.size = Vector2i(1400,960)
    var out := OS.get_environment("ADVENTURE_CAPTURE_DIR")
    if out.is_empty(): out = ProjectSettings.globalize_path("res://godot/complete-previews")
    DirAccess.make_dir_recursive_absolute(out)
    root.get_node("OceanAudio").playback_enabled = false
    var catalog = root.get_node("AdventureRun")
    root.get_node("AppPreferences").persist_enabled = false
    root.get_node("AppPreferences").intro_seen = true
    for index in range(catalog.SCENES.size()):
        var level = load(catalog.SCENES[index]).instantiate()
        root.add_child(level)
        level.set_physics_process(false)
        level.invulnerable = 100
        await frames()
        for spot in ["entry","rocks","boss"]:
            if spot=="rocks":
                level.fallen = true
                if not level.obstacles.is_empty():
                    level.player = Vector2(level.obstacles[1 if index==1 else 0].position.x-180,560)
            if spot=="boss":
                level.fallen = true
                level.player = Vector2(level._boss_home()-300,540)
                level.boss_clock = 4.3
                level._update_boss(0)
            level.camera = clampf(level.player.x-550,0,maxf(0,level._level_length()-1400))
            level.message_time = 0
            level._sync_native_visuals()
            level.queue_redraw()
            await frames()
            await RenderingServer.frame_post_draw
            var image := root.get_texture().get_image()
            assert(not image.is_empty())
            assert(image.save_png(out+"/%s-%s.png" % [index,spot])==OK)
        root.remove_child(level)
        level.free()
        await frames(2)
    var menu = load("res://godot/title_screen.tscn").instantiate()
    root.add_child(menu)
    await frames()
    menu.show_page("chapters")
    for size in [Vector2i(1400,960),Vector2i(640,360),Vector2i(390,844)]:
        root.size = size
        await frames(10)
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(out+"/chapters-%s.png" % size.x)
    root.remove_child(menu)
    menu.free()
    await frames(2)
    print("NATIVE COMPLETE ADVENTURE CAPTURES PASSED: 24 stage + 3 menu frames")
    var audio := root.get_node("OceanAudio")
    for voice in audio.voices:
        voice.stop()
        voice.stream = null
    audio.ambience.stop()
    audio.ambience.stream = null
    await frames(4)
    quit()

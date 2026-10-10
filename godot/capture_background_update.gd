extends SceneTree
## Record the real native renderer, with full world height and original game audio.
var output := ""
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
    for i in range(count): await process_frame
func still(name: String) -> void:
    if output.is_empty(): return
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(output+"/"+name+".png")
func run() -> void:
    output = OS.get_environment("ADVENTURE_CAPTURE_DIR")
    if not output.is_empty(): DirAccess.make_dir_recursive_absolute(output)
    var prefs := root.get_node("AppPreferences")
    prefs.persist_enabled = false
    prefs.intro_seen = true
    prefs.reduced_motion = false
    var catalog := root.get_node("AdventureRun")
    for index in range(catalog.SCENES.size()):
        change_scene_to_file(catalog.SCENES[index])
        await frames(3)
        var level = current_scene
        level.set_physics_process(false)
        level.invulnerable = 100
        level.fallen = true
        level.message_time = 0
        level.music_player.play()
        var camera_start: float = maxf(0,level.obstacles[0].position.x-730) if not level.obstacles.is_empty() else level._boss_home()-850
        for frame in range(72):
            level.time = frame/24.0
            level.camera = clampf(camera_start+frame*.65,0,maxf(0,level._level_length()-1400))
            level.player = Vector2(level.camera+530,555)
            level.player_velocity = Vector2(100,0)
            level._sync_native_visuals()
            level.queue_redraw()
            await frames(1)
            if frame == 35: await still("chapter-%s-reef" % index)
        level.boss_hp = 0
        for frame in range(24):
            level.time += 1.0/24.0
            level.camera = maxf(0,level._level_length()-1400)
            level.player = Vector2(level._portal_x()-180,560)
            level._sync_native_visuals()
            level.queue_redraw()
            await frames(1)
            if frame == 12: await still("chapter-%s-portal" % index)
    current_scene.music_player.stop()
    current_scene.music_player.stream = null
    var audio := root.get_node("OceanAudio")
    for voice in audio.voices:
        voice.stop()
        voice.stream = null
    audio.ambience.stop()
    audio.ambience.stream = null
    await frames(4)
    print("BACKGROUND UPDATE MOVIE PASSED: eight chapters and eight portals")
    quit()

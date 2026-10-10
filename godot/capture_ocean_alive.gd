extends SceneTree
## Native movie recording: real in-game artwork, shaders and mixed audio.
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
    for index in [0,2,4,6]:
        change_scene_to_file(catalog.SCENES[index])
        await frames(3)
        var level = current_scene
        level.set_physics_process(false)
        level.invulnerable = 100
        level.fallen = true
        level.player = Vector2(level._boss_home()-270,560)
        level.camera = level._boss_home()-620
        level.message_time = 0
        level.music_player.play()
        for frame in range(84):
            level.time = frame/24.0
            level.boss_clock = level.time
            level.boss_phase = "windup" if frame<22 else ("attack" if frame<48 else "recover")
            level.boss_position = Vector2(level._boss_home()+sin(level.time)*25,540)
            level.player_velocity = Vector2(130,0)
            if frame == 12: level._ocean_event("pearl",level.player)
            if frame == 26: level._ocean_event("boost",level.player,Vector2.RIGHT)
            if frame == 48:
                level.boss_hp -= 1
                level._ocean_event("boss_hit",level.boss_position)
            if frame == 68:
                if index == 6:
                    level.boss_hp = 0
                    level._ocean_event("boss_defeat",level.boss_position)
                else: level._ocean_event("treasure",level.player)
            level._sync_native_visuals()
            level.queue_redraw()
            await frames(1)
            if frame == 54: await still("chapter-%s" % index)
    root.get_node("OceanAudio").play("victory",3)
    await frames(48)
    current_scene.music_player.stop()
    current_scene.music_player.stream = null
    var audio := root.get_node("OceanAudio")
    for voice in audio.voices:
        voice.stop()
        voice.stream = null
    audio.ambience.stop()
    audio.ambience.stream = null
    await frames(4)
    print("OCEAN ALIVE MOVIE CAPTURE PASSED")
    quit()

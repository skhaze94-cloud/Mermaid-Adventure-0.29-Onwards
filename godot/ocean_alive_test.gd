extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("OCEAN ALIVE: "+message)
func frames(count := 3) -> void:
    for i in range(count): await process_frame
func run() -> void:
    var prefs := root.get_node("AppPreferences")
    prefs.persist_enabled = false
    prefs.intro_seen = true
    var audio := root.get_node("OceanAudio")
    for effect in audio.EFFECTS:
        check(audio.streams[effect] is AudioStreamWAV,"effect imported: "+effect)
        check(audio.streams[effect].get_length() > 0.1,"effect has playable samples: "+effect)
    check(audio.voices.size() == 10,"bounded voice pool")
    var old_music: float = prefs.music_volume
    prefs.sound_volume = 0
    prefs.ambience_volume = 0
    prefs.apply_audio()
    check(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")),"sound can be muted")
    check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Ambience")),"ambience can be muted")
    check(prefs.music_volume == old_music,"sound controls do not change music preference")
    prefs.sound_volume = 0.8
    prefs.ambience_volume = 0.65
    prefs.apply_audio()
    var catalog := root.get_node("AdventureRun")
    for index in range(8):
        change_scene_to_file(catalog.SCENES[index])
        await frames()
        var level = current_scene
        level.set_physics_process(false)
        check(level.ocean_life != null and level.ocean_feedback.pool.size() == 20,"shared life and feedback in chapter "+str(index))
        check(audio.ambient_kind == ("deep" if index in [1,3] else "reef"),"chapter ambience selection")
        check(audio.ambience.stream.loop_end > audio.ambience.stream.loop_begin,"ambience loops valid sample range")
        level.player = Vector2(850,540)
        level.energy = 1
        level.boost_cooldown = 0
        level.jump_time = 0
        audio.last_played.clear()
        var before: int = audio.events.get("boost",0)
        level._boost()
        level._boost()
        check(int(audio.events.get("boost",0)) == before+1,"accepted boost plays once; rejected repeat silent")
        level.boost_time = 0
        audio.last_played.clear()
        before = audio.events.get("boss_hit",0)
        level._award("ocean-feedback-test","Boss",200,level.player,false)
        level._award("ocean-feedback-test","Boss",200,level.player,false)
        check(int(audio.events.get("boss_hit",0)) == before+1,"duplicate score award cannot replay hit sound")
        var start_clock: float = level.ocean_life.clock
        level.ocean_life.reduced = true
        level.ocean_life._process(1)
        check(level.ocean_life.clock == start_clock,"reduced motion freezes decorative schools")
        if index > 0:
            var actor = level.performance
            actor.set_state(5,"attack",Vector2(400,500),2,false)
            actor.set_state(4,"recover",Vector2(400,500),2,false)
            check(actor.hit_age == 0,"boss health reduction starts hit reaction")
            actor.set_state(0,"recover",Vector2(400,500),2,false)
            check(actor.defeat_age == 0,"boss clear starts gentle departure")
            actor.set_state(5,"windup",Vector2(400,500),3,true)
            check(actor.defeat_age == -1 and actor.modulate.a == 1,"retry restores boss appearance")
            check(actor.body.rotation == 0 and actor.surface.get_shader_parameter("strength") == 0,"reduced motion disables boss deformation")
        level.ocean_feedback.clear()
        check(level.ocean_feedback.pool.all(func(item): return item["age"] == 2.0),"retry clears ripple pool")
    # Priority cannot create more players; victory remains audible while paused.
    audio.playback_enabled = true
    for voice in audio.voices: voice.stop()
    for i in range(10):
        audio.last_played.clear()
        audio.play("swim",0)
    audio.last_played.clear()
    check(audio.play("victory",3),"important reward can replace a low-priority voice")
    paused = true
    audio._process(0)
    check(audio.voices.any(func(voice): return voice.playing and voice.stream == audio.streams["victory"]),"victory flourish survives results pause")
    check(not audio.play("boost"),"game effects blocked while paused")
    for voice in audio.voices:
        voice.stop()
        voice.stream = null
    audio.ambience.stop()
    audio.ambience.stream = null
    paused = false
    await frames(4)
    print("OCEAN ALIVE: %s checks, %s failures" % [checks,failures])
    quit(0 if failures == 0 else 1)

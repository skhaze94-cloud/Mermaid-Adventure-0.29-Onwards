extends SceneTree
## Enlarged native gameplay rig: continuous stroke, dash, turn, rise and gestures.
var output := ""
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
    for i in range(count): await process_frame
func run() -> void:
    output = OS.get_environment("ADVENTURE_CAPTURE_DIR")
    if not output.is_empty(): DirAccess.make_dir_recursive_absolute(output)
    var prefs := root.get_node("AppPreferences")
    prefs.persist_enabled = false
    prefs.intro_seen = true
    change_scene_to_file("res://godot/highland_level.tscn")
    await frames(4)
    var level = current_scene
    level.set_physics_process(false)
    level.fallen = true
    level.invulnerable = 100
    level.message_time = 0
    level.player = Vector2(2500,555)
    level.camera = 1770
    level.music_player.play()
    var rig = level.native_rig
    rig.set_process(false)
    rig.gesture_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.jump_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    var label := Label.new()
    label.position = Vector2(410,790)
    label.add_theme_font_size_override("font_size",27)
    label.modulate = Color(.85,1,.97)
    level.premium_hud.add_child(label)
    for frame in range(480):
        level.time = frame/24.0
        var section := int(frame/60)
        var mode: String = ["BREASTSTROKE · OPEN REACH & SWEEP","CRUISE · RELAXED FULL-BODY GLIDE","DASH · LONG STREAMLINED REACH","TURN · SOFT BODY BANK","DESCEND · FIN & HAIR FOLLOW-THROUGH","SETTLE · GENTLE HOVER","HELLO · EXPRESSIVE HANDS","CELEBRATE · PLAYFUL BODY & TAIL"][section]
        var velocity: Vector2 = [Vector2(280,0),Vector2(160,0),Vector2(730,-20),Vector2(-240,30),Vector2(160,180),Vector2.ZERO,Vector2(70,0),Vector2.ZERO][section]
        var dash := section==2
        var facing := -1.0 if section==3 else 1.0
        label.text = "v0.25 HERO ARMS\n"+mode
        level.player_velocity = velocity
        level.facing = facing
        level.boost_time = 1.0 if dash else 0.0
        level._sync_native_visuals()
        if frame == 370: rig.play_gesture("greet")
        if frame == 426: rig.play_gesture("celebrate")
        rig.gesture_player.advance(1.0/24.0)
        rig._process(1.0/24.0)
        # Preview magnification only; the playable rig uses its normal game scale.
        rig.scale *= 1.65
        level.queue_redraw()
        await frames(1)
        if frame in [42,96,144,206,270,330,390,444] and not output.is_empty():
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png(output+"/pose-%s.png" % frame)
    level.music_player.stop()
    level.music_player.stream = null
    var audio := root.get_node("OceanAudio")
    for voice in audio.voices:
        voice.stop()
        voice.stream = null
    audio.ambience.stop()
    audio.ambience.stream = null
    await frames(4)
    print("HERO ARMS NATIVE MOVIE PASSED")
    quit()

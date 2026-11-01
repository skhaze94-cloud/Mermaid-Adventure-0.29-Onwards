extends SceneTree
var output:=OS.get_environment("BEAUTY_CAPTURE_DIR")
func _initialize() -> void:call_deferred("run")
func frame() -> void:
    await process_frame
    await RenderingServer.frame_post_draw
func run() -> void:
    root.size=Vector2i(1400,960)
    var prefs=root.get_node("AppPreferences")
    prefs.persist_enabled=false;prefs.intro_seen=true;prefs.economy=false;prefs.reduced_motion=false
    root.get_node("AdventureRun").persist_enabled=false
    root.get_node("AdventureRun").active=false
    root.get_node("OceanAudio").playback_enabled=false
    var scene=load("res://godot/training_lagoon.tscn").instantiate()
    root.add_child(scene)
    await frame();await frame()
    scene.music_player.stop();scene.music_player.stream=null
    scene.set_process(false);scene.set_physics_process(false);scene.native_rig.set_process(false)
    Engine.time_scale=0
    var places=[['01-welcome',Vector2(420,570),0,0.0],['02-reef-rings',Vector2(1750,520),1,1100.0],['03-pearl-nursery',Vector2(910,1370),1,210.0],['04-bellflower',Vector2(2430,1460),2,1740.0],['05-royal-gifts',Vector2(5500,580),6,4900.0],['08-reef',Vector2(3500,560),2,2800.0],['09-boost',Vector2(4050,580),3,3500.0],['10-first-jump',Vector2(4330,580),4,3800.0],['11-tall-reef',Vector2(4750,560),5,4200.0],['12-volunteers',Vector2(6200,580),7,5650.0],['13-daddy-trial',Vector2(6650,600),8,6200.0],['14-peekaboo',Vector2(7100,670),9,6200.0],['15-bubbles',Vector2(7400,580),10,6200.0]]
    if OS.get_environment("FINISH_ONLY")=="1":places=places.filter(func(p):return p[2]>=8)
    if OS.get_environment("DIALOGUE_ONLY")=="1":places=places.filter(func(p):return p[2]==6)
    for place in places:
        scene._close_dialogue();scene._advance_lesson(place[2]);scene.player=place[1];scene.player_velocity=Vector2.ZERO;scene.camera=place[3];scene.time=12.0
        if scene.lesson>=8:
            for enemy in scene.enemies:enemy.hp=0
        if scene.lesson>=9:scene.boss_hp=0
        if scene.lesson==8:scene.boss_clock=8.7;scene._update_boss(0)
        if scene.lesson==9:scene._start_hide_seek()
        if scene.lesson==10 and is_instance_valid(scene.avina):scene.avina.follow_enabled=true
        scene.arrival_time=2.6;scene.king_world=scene.player+Vector2(260,-140);scene._show_lesson()
        for i in range(8):scene.character_dt=1.0/60;scene._sync_native_visuals()
        scene.deep_routes.sync(true);scene.treasure_gallery.sync(true,0);scene.message_time=0;scene.premium_hud.clear_feedback();scene.queue_redraw()
        for i in range(3):await frame()
        root.get_texture().get_image().save_png(output+'/'+place[0]+'.png')
        print('CAPTURE ',place[0])
    scene.free();await frame();Engine.time_scale=1.0
    scene=load("res://godot/training_lagoon.tscn").instantiate();root.add_child(scene)
    await frame();await frame()
    Engine.time_scale=0
    scene.music_player.stop();scene.music_player.stream=null;scene.set_process(false);scene.set_physics_process(false);scene.native_rig.set_process(false)
    scene.player=Vector2(5500,580);scene.camera=4900;scene._advance_lesson(6);scene.time=12;scene.arrival_time=2.6;scene.king_world=scene.player+Vector2(260,-140)
    for i in range(8):scene.character_dt=1.0/60;scene._sync_native_visuals()
    scene.deep_routes.sync(true);scene.treasure_gallery.sync(true,0);scene.message_time=0;scene.premium_hud.clear_feedback()
    scene._open_dialogue("gifts")
    if scene.speech_reveal:scene.speech_reveal.kill()
    scene.dialogue_text.modulate.a=1.0;scene.dialogue_text.visible_ratio=1.0
    for i in range(5):await frame()
    root.get_texture().get_image().save_png(output+'/06-family-dialogue.png')
    scene._close_dialogue()
    root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(1920,1080)
    for i in range(4):await frame()
    scene._on_viewport_resized();scene.deep_routes.sync(true);scene.queue_redraw()
    for i in range(3):await frame()
    root.get_texture().get_image().save_png(output+'/07-widescreen.png')
    scene.free();await frame();quit()

extends SceneTree
var out:=OS.get_environment('NATIVE_AUDIT_OUT')
var evidence: Array[Dictionary]=[]
func _initialize() -> void:call_deferred('run')
func frame() -> void:
    await process_frame
    await RenderingServer.frame_post_draw
func frames(n: int) -> void:
    for i in range(n):await frame()
func stage(scene,at: Vector2,lesson: int,camera: float) -> void:
    scene._close_dialogue();scene._advance_lesson(lesson);scene.player=at;scene.player_velocity=Vector2.ZERO;scene.camera=camera;scene.time=12.0;scene.message_time=0
    scene.arrival_time=2.6;scene.arrival_intro_pending=false;scene.king_world=at+Vector2(260,-140)
    scene.deep_routes.sync(true)
    for i in range(8):scene.character_dt=1.0/60;scene._sync_native_visuals()
    scene.treasure_gallery.sync(true,0)
    scene._show_lesson();scene._refresh_lesson_hint();scene.ocean_feedback.clear();scene.premium_hud.clear_feedback();scene.queue_redraw()
func run() -> void:
    root.size=Vector2i(1400,960)
    var prefs=root.get_node('AppPreferences');prefs.persist_enabled=false;prefs.intro_seen=true;prefs.economy=false;prefs.reduced_motion=false
    root.get_node('AdventureRun').persist_enabled=false;root.get_node('AdventureRun').active=false;root.get_node('OceanAudio').playback_enabled=false
    var scene=load('res://godot/training_lagoon.tscn').instantiate();root.add_child(scene);await frames(5)
    scene.music_player.stop();scene.music_player.stream=null;scene.set_process(false);scene.set_physics_process(false);scene.native_rig.set_process(false);Engine.time_scale=0
    var places=[['01-welcome',Vector2(420,570),0,0.0],['03-pearl-nursery',Vector2(910,1370),1,210.0],['04-bellflower',Vector2(2430,1460),2,1740.0],['05-royal-gifts',Vector2(5500,580),6,4900.0]]
    for place in places:
        stage(scene,place[1],place[2],place[3]);await frames(5)
        var draws:=0.0;var primitives:=0.0
        for i in range(8):
            await frame();draws+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME);primitives+=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
        evidence.append({'view':place[0],'draw_calls_mean':draws/8,'primitives_mean':primitives/8,'texture_bytes':Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)})
        root.get_texture().get_image().save_png(out+'/'+place[0]+'.png')
    var report:=FileAccess.open(out+'/render-counters.json',FileAccess.WRITE);report.store_string(JSON.stringify(evidence,'  '));report.close()
    if OS.get_environment('NATIVE_EXTRAS')=='1':
        for clip in range(3):
            if OS.get_environment('NATIVE_CAVE_REFRESH')=='1' and clip!=1:continue
            if OS.has_environment('NATIVE_CLIP_ONLY') and clip!=int(OS.get_environment('NATIVE_CLIP_ONLY')):continue
            if clip==0:stage(scene,Vector2(1750,520),1,1100)
            elif clip==1:
                scene.neighbourhood.clear_transients();stage(scene,Vector2(700,1400),1,210);scene.neighbourhood.quiet=false;scene.neighbourhood._speak(0,scene.neighbourhood.profile['people'][0]['lines'][0]);scene.neighbourhood_art.sync()
            else:
                var chests: Array=scene.treasures.filter(func(t):return t.kind=='chest' and not t.has('deep_id'))
                var chest: Dictionary=chests[2];stage(scene,Vector2(chest.x-190,chest.y-90),2,float(chest.x)-700)
                scene.player=Vector2(chest.x,chest.y);var before: int=scene.score;scene._update_collectibles();print('REAL CHEST PICKUP ',scene.score-before)
                scene.player=Vector2(chest.x-190,chest.y-90);scene.ocean_feedback.clear();scene.message_time=0;scene.premium_hud.clear_feedback()
            for i in range(48):
                var dt:=1.0/24;scene.time+=dt;scene.character_dt=dt
                scene.neighbourhood.advance(dt);scene.little_moments.advance(dt);scene._sync_native_visuals();scene.native_rig._process(dt);scene.treasure_gallery.sync(true,dt);scene.queue_redraw()
                await frame();root.get_texture().get_image().save_png(out+'/frames/clip_%s_%03d.png' % [clip,i])
        # Short-window/touch UI and quiet-motion composition.
        root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(844,390);await frames(4)
        scene.simulated_touch=true;scene._on_viewport_resized();stage(scene,Vector2(700,1400),1,210);scene._layout_tutorial();scene.neighbourhood._speak(0,scene.neighbourhood.profile['people'][0]['lines'][0]);scene.neighbourhood.quiet=false;scene.neighbourhood_art.sync();await frames(4)
        root.get_texture().get_image().save_png(out+'/24-phone-neighbour.png')
        scene.neighbourhood.suspend();stage(scene,Vector2(5500,580),6,4900);scene._open_dialogue('gifts')
        if scene.speech_reveal:scene.speech_reveal.kill()
        scene.dialogue_text.modulate.a=1;scene.dialogue_text.visible_ratio=1;await frames(10)
        root.get_texture().get_image().save_png(out+'/25-phone-family.png')
        scene._close_dialogue();scene.reduced_fx=true;prefs.economy=true;scene.high_depth_quality=false;stage(scene,Vector2(910,1370),1,210);scene._sync_native_visuals();await frames(4)
        root.get_texture().get_image().save_png(out+'/26-gentle-economy.png')
    scene.free();await frame();print('NATIVE REVIEW COMPLETE ',out);quit()

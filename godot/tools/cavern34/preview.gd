extends SceneTree
var output:=OS.get_environment('CAVERN_PREVIEW_DIR')
func _initialize() -> void:call_deferred('run')
func frame() -> void:
    await process_frame
    await RenderingServer.frame_post_draw
func run() -> void:
    root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(1120,768)
    var prefs=root.get_node('AppPreferences');prefs.persist_enabled=false;prefs.intro_seen=true;prefs.economy=false;prefs.reduced_motion=false
    root.get_node('AdventureRun').persist_enabled=false;root.get_node('AdventureRun').active=false
    root.get_node('OceanAudio').playback_enabled=false
    for clip in range(2):
        Engine.time_scale=1
        var chapter:=7 if clip==0 else 0
        var scene=load(root.get_node('AdventureRun').SCENES[chapter]).instantiate();root.add_child(scene)
        for i in range(4):await frame()
        scene.set_process(false);scene.set_physics_process(false);scene.native_rig.set_process(false);scene.music_player.stop();scene.invulnerable=10000
        for enemy in scene.enemies:enemy['hp']=0
        scene.boss_hp=0;scene.message_time=0
        var person: Dictionary=scene.neighbourhood.profile['people'][0 if clip==0 else 2]
        var room: Dictionary=scene.deep_routes.profiles[0 if clip==0 else 1]
        if chapter==7:
            scene._close_dialogue();scene.lesson=1;scene.arrival_intro_pending=false;scene.arrival_time=3;scene._show_lesson()
        else:scene.fallen=true;scene.checkpoint=maxf(scene.checkpoint,scene._left_bound())
        scene.player=Vector2(room['a'],835);scene.player_velocity=Vector2.ZERO;scene.camera=maxf(0,scene.player.x-590);scene.deep_routes.sync(true)
        var target: Vector2=person['talk_at']
        Engine.time_scale=0
        for index in range(96):
            for tick in range(5):
                var direction: Vector2=target-scene.player
                scene.touch_vectors[91]=direction.normalized()*minf(1,direction.length()/50)
                scene._physics_process(1.0/60)
                scene._process(1.0/60)
                if scene.native_rig.gesture_player.is_playing():scene.native_rig.gesture_player.advance(1.0/60)
                scene.native_rig._process(1.0/60)
            scene._sync_native_visuals();scene.queue_redraw();await frame()
            root.get_texture().get_image().save_png(output+'/clip_%s_%03d.png' % [clip,index])
        print('SCRIPTED SWIM ',person['id'],' friend_reward=',scene.score_book.seen.has(scene.neighbourhood.friend_key(0 if clip==0 else 2)),' score=',scene.score,' position=',scene.player)
        scene.free();await frame()
    print('FRIENDS CAVERN PREVIEW COMPLETE: 192 frames, 16 simulated seconds');quit()

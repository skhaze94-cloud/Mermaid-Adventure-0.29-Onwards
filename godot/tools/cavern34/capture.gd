extends SceneTree
var output:=OS.get_environment('CAVERN_CAPTURE_DIR')
var measurements: Array[Dictionary]=[]
var picture_count:=0
func _initialize() -> void:call_deferred('run')
func frame() -> void:
    await process_frame
    await RenderingServer.frame_post_draw
func frames(n: int) -> void:
    for i in range(n):await frame()
func stage(scene,chapter: int,room: Dictionary,at: Vector2) -> void:
    scene.player=at;scene.player_velocity=Vector2.ZERO;scene.camera=maxf(0,float(room['x'])+float(room['w'])*.5-700)
    scene.time=12;scene.message_time=0;scene.invulnerable=0;scene.boost_time=0;scene.leap_phase=''
    scene.neighbourhood.suspend()
    if chapter==0:scene.fallen=room['id']!='roots'
    if chapter==7:
        scene.lesson=1;scene._close_dialogue();scene.arrival_time=2.6;scene.arrival_intro_pending=false;scene._show_lesson();scene._refresh_lesson_hint()
    scene.deep_routes.sync(true)
    for i in range(5):
        if scene.get('character_dt')!=null:scene.character_dt=1.0/60
        scene._sync_native_visuals()
    scene.ocean_feedback.clear();scene.premium_hud.clear_feedback();scene.queue_redraw()
func snap(scene,name: String) -> void:
    await frames(2)
    root.get_texture().get_image().save_png(output+'/'+name+'.png');picture_count+=1
    measurements.append({'view':name,'draw_calls':Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),'primitives':Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),'texture_bytes':Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)})
func run() -> void:
    root.size=Vector2i(1400,960)
    root.get_node('AppPreferences').persist_enabled=false;root.get_node('AppPreferences').intro_seen=true
    root.get_node('AdventureRun').persist_enabled=false;root.get_node('AdventureRun').active=false
    root.get_node('OceanAudio').playback_enabled=false
    for chapter in [7,0,1,2,3,4,5,6]:
        if OS.get_environment('CAVERN_DOZY_ONLY')=='1' and chapter!=7:continue
        Engine.time_scale=1
        var scene=load(root.get_node('AdventureRun').SCENES[chapter]).instantiate();root.add_child(scene);await frames(4)
        scene.music_player.stop();scene.music_player.stream=null;scene.set_process(false);scene.set_physics_process(false);scene.native_rig.set_process(false)
        scene.boss_hp=0
        for enemy in scene.enemies:enemy['hp']=0
        Engine.time_scale=0
        for room in scene.deep_routes.profiles:
            if OS.get_environment('CAVERN_DOZY_ONLY')=='1':continue
            var label: String='chapter-%s-%s' % [chapter,room['id']]
            stage(scene,chapter,room,Vector2(room['x']+room['w']*.28,room['y']+room['h']*.50))
            await snap(scene,label+'-interior')
            for key in ['a','b']:
                stage(scene,chapter,room,Vector2(room[key],1040));scene.camera=maxf(0,float(room[key])-700);scene.deep_routes.sync(true);scene._sync_native_visuals();scene.queue_redraw()
                await snap(scene,label+'-entrance-'+key)
            if OS.get_environment('CAVERN_EXTRA_VIEWS')=='1':
                stage(scene,chapter,room,room['chest']-Vector2(165,35))
                await snap(scene,label+'-lower-pocket')
        if OS.get_environment('CAVERN_EXTRA_VIEWS')=='1':
            if chapter==7:
                var room: Dictionary=scene.deep_routes.profiles[1]
                stage(scene,chapter,room,scene.little_moments.keeper_point-Vector2(170,80))
                scene.native_rig.reset_performance();scene.native_rig.set_motion(Vector2.ZERO,1,false,false,1)
                scene.little_moments.sync()
                for tick in range(20):scene.little_moments.advance(.1)
                scene.little_moments.sync();scene.ocean_feedback.clear();scene.premium_hud.clear_feedback()
                print('DOZY CAPTION ',scene.little_moments.speech_key,' left=',scene.little_moments.speech_left,' visible=',scene.little_moments.message_box.visible,' quiet=',scene.little_moments._quiet(),' perform=',scene.little_moments._can_perform())
                await snap(scene,'friend-dozy')
            for i in range(scene.neighbourhood.profile['people'].size()):
                if OS.get_environment('CAVERN_DOZY_ONLY')=='1':continue
                var person: Dictionary=scene.neighbourhood.profile['people'][i]
                var room: Dictionary=scene.deep_routes.profiles[int(person.get('room_index',0))]
                stage(scene,chapter,room,person['talk_at']);scene.camera=maxf(0,scene.player.x-580);scene.deep_routes.sync(true);scene._sync_native_visuals()
                scene.neighbourhood.quiet=false;scene.neighbourhood._speak(i,person['lines'][0]);scene.neighbourhood_art.sync()
                await snap(scene,'friend-'+person['id'])
            if chapter in [7,1] and OS.get_environment('CAVERN_DOZY_ONLY')!='1':
                root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(844,390);await frames(3)
                scene.simulated_touch=true;scene._on_viewport_resized()
                if chapter==7:scene._layout_tutorial()
                var person: Dictionary=scene.neighbourhood.profile['people'][0]
                stage(scene,chapter,scene.deep_routes.profiles[0],person['talk_at']);scene.camera=maxf(0,scene.player.x-580);scene.deep_routes.sync(true);scene._sync_native_visuals();scene.neighbourhood.quiet=false;scene.neighbourhood._speak(0,person['lines'][0]);scene.neighbourhood_art.sync()
                await snap(scene,'phone-chapter-%s' % chapter)
                scene.reduced_fx=true;scene.high_depth_quality=false;scene._sync_native_visuals()
                await snap(scene,'gentle-economy-chapter-%s' % chapter)
                root.size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;await frames(3)
        scene.free();await frames(2)
    var suffix: String='dozy-counters.json' if OS.get_environment('CAVERN_DOZY_ONLY')=='1' else 'render-counters.json'
    var f:=FileAccess.open(output+'/'+suffix,FileAccess.WRITE);f.store_string(JSON.stringify(measurements,'  '));f.close()
    print('CAVERN VISUAL REVIEW: ',picture_count,' native views');quit()

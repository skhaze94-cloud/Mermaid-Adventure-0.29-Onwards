extends SceneTree
var out:=OS.get_environment('MESHY_REVIEW_DIR')
var reports:=[]
func _initialize() -> void:
    if out.is_empty():out=OS.get_user_data_dir().path_join('tutorial39-review')
    call_deferred('run')
func frame() -> void:await process_frame;await RenderingServer.frame_post_draw
func stage(scene,point: Vector2,lesson: int) -> void:
    if scene.dialogue_open:scene._close_dialogue()
    scene.state='playing';scene.lesson=lesson;scene.player=point;scene.player_velocity=Vector2.ZERO;scene.camera=clampf(point.x-650,0,6200);scene.time=18;scene.arrival_intro_pending=false;scene.arrival_time=3;scene.message_time=0;scene.lesson_card.hide()
    scene.king_world=point+Vector2(-350,-90) if lesson in [6,7] else point+Vector2(350,-90)
    scene.queen_world=point+Vector2(-660,-50) if lesson==7 else Vector2(7260,500)
func pose(scene,dt:=.05) -> void:
    scene.time+=dt;scene.character_dt=dt;scene.deep_routes.sync(true);scene._sync_native_visuals();scene.treasure_gallery.sync(true,dt);scene.mesh_y_friends._process(dt);scene.queue_redraw()
func snap(scene,name: String) -> void:
    for i in range(5):pose(scene);await frame()
    root.get_texture().get_image().save_png(out+'/'+name+'.png')
    var stats:={'name':name,'logical':scene.get_viewport_rect().size,'window':root.size,'visible_models':scene.mesh_y_friends.visible_count,'draw_calls':Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),'render_primitives':Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),'texture_bytes':Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),'static_bytes':Performance.get_monitor(Performance.MEMORY_STATIC),'model_viewport':scene.mesh_y_friends.viewport.size}
    reports.append(stats);print(name,': ',stats)
func run() -> void:
    DirAccess.make_dir_recursive_absolute(out)
    root.size=Vector2i(1280,800);root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
    var prefs=root.get_node('AppPreferences');prefs.persist_enabled=false;prefs.intro_seen=true;prefs.economy=false;prefs.reduced_motion=false
    root.get_node('AdventureRun').persist_enabled=false;root.get_node('AdventureRun').active=false;root.get_node('OceanAudio').playback_enabled=false
    var scene=load('res://godot/training_lagoon.tscn').instantiate();root.add_child(scene)
    for i in range(5):await frame()
    scene.set_process(false);scene.set_physics_process(false);scene.mesh_y_friends.set_process(false);scene.music_player.stop();scene.music_player.stream=null
    stage(scene,Vector2(900,1450),0);await snap(scene,'nursery')
    stage(scene,Vector2(2220,1500),0);await snap(scene,'bellflower')
    scene._advance_lesson(7);stage(scene,Vector2(5650,580),7);await snap(scene,'practice')
    stage(scene,Vector2(3480,660),10);await snap(scene,'tea')
    scene.enemies.clear();scene.animated_enemies.bind_enemies(scene.enemies)
    stage(scene,Vector2(900,1450),0)
    var started:=Time.get_ticks_usec()
    for i in range(48):
        pose(scene,1.0/24);await frame()
        root.get_texture().get_image().save_jpg(out+'/motion-%03d.jpg'%i,.87)
    reports.append({'capture_frames':48,'seconds_at_24_fps':2,'actual_render_seconds':(Time.get_ticks_usec()-started)/1000000.0,'note':'staged deterministic pose advancement, llvmpipe software renderer; not device FPS'})
    root.size=Vector2i(844,390)
    for i in range(4):await frame()
    scene.simulated_touch=true;scene._on_viewport_resized();scene._layout_tutorial();stage(scene,Vector2(900,1450),0);await snap(scene,'phone-nursery')
    stage(scene,Vector2(2220,1500),0);await snap(scene,'phone-bellflower')
    stage(scene,Vector2(900,1450),0);scene.high_depth_quality=false;scene.reduced_fx=true;await snap(scene,'economy-gentle')
    scene._open_dialogue('intro');await snap(scene,'phone-dialogue');paused=false
    FileAccess.open(out+'/review.json',FileAccess.WRITE).store_string(JSON.stringify(reports,'  '));scene.free();quit()

extends SceneTree
var output:=OS.get_environment("FAMILY_QA_DIR")
var counters:=[]
var qa_metrics:={}
func _initialize() -> void:call_deferred("run")
func frame() -> void:await process_frame;await RenderingServer.frame_post_draw
func snap(name: String) -> void:
    await frame()
    var im:=root.get_texture().get_image()
    if name.begins_with("family_") and OS.get_environment("FAMILY_QA_JPEG")=="1":
        im.save_jpg(output+"/"+name+".jpg",.95)
        if int(name.trim_prefix("family_")) in [0,12,36,60,84,108,132,143]:im.save_png(output+"/"+name+".png")
    else:im.save_png(output+"/"+name+".png")
func geometry(node: Node) -> Dictionary:
    var data:={"mesh_vertices":0,"mesh_triangles":0,"skeletons":0,"bones":0,"subviewports":0}
    if node is MeshInstance3D and node.mesh:
        for surface in range(node.mesh.get_surface_count()):
            var a: Array=node.mesh.surface_get_arrays(surface)
            data.mesh_vertices+=a[Mesh.ARRAY_VERTEX].size()
            data.mesh_triangles+=(a[Mesh.ARRAY_INDEX].size() if a[Mesh.ARRAY_INDEX]!=null else a[Mesh.ARRAY_VERTEX].size())/3
    if node is Skeleton3D:data.skeletons=1;data.bones=node.get_bone_count()
    if node is SubViewport:data.subviewports=1
    for child in node.get_children():
        var extra:=geometry(child)
        for key in data:data[key]+=extra[key]
    return data
func benchmark(label: String) -> void:
    if OS.get_environment("FAMILY_QA_SKIP_BENCH")=="1":return
    for i in range(20):await frame()
    var samples:=[]
    for i in range(60):
        var began:=Time.get_ticks_usec();await frame();samples.append(Time.get_ticks_usec()-began)
    samples.sort();var total:=0.0
    for value in samples:total+=value
    counters.append({"view":label,"mean_frame_ms":total/samples.size()/1000.0,"median_frame_ms":samples[samples.size()/2]/1000.0,"p95_frame_ms":samples[int(samples.size()*.95)]/1000.0,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"renderer":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info()["string"]})
func stage(scene) -> void:
    scene._close_dialogue();scene._advance_lesson(6);scene.player=Vector2(5500,580);scene.player_velocity=Vector2.ZERO;scene.camera=4900;scene.time=12.0;scene.message_time=0;scene.arrival_time=3;scene.arrival_intro_pending=false;scene.king_world=Vector2(5150,490);scene.queen_world=Vector2(6100,530)
    scene.deep_routes.sync(true)
    for i in range(8):scene.character_dt=1.0/60;scene._sync_native_visuals()
    scene.treasure_gallery.sync(true,0);scene._show_lesson();scene._refresh_lesson_hint();scene.ocean_feedback.clear();scene.premium_hud.clear_feedback();scene.queue_redraw()
func run() -> void:
    root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(1120,768)
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true;prefs.economy=false;prefs.reduced_motion=false
    root.get_node("AdventureRun").persist_enabled=false;root.get_node("AdventureRun").active=false;root.get_node("OceanAudio").playback_enabled=false
    var menu=load("res://godot/title_screen.tscn").instantiate();root.add_child(menu)
    for i in range(5):await frame()
    await benchmark("opening-1120x768")
    await snap("opening")
    menu.free();await frame()
    var scene=load("res://godot/training_lagoon.tscn").instantiate();root.add_child(scene)
    for i in range(6):await frame()
    scene.music_player.stop();scene.music_player.stream=null;scene.set_process(false);scene.set_physics_process(false);scene.native_rig.set_process(false)
    scene.king.set_process(false);scene.queen_teacher.set_process(false)
    stage(scene);qa_metrics["tutorial_geometry"]=geometry(scene)
    await benchmark("tutorial-family-1120x768")
    await snap("tutorial-family")
    scene.king.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;scene.queen_teacher.viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
    await benchmark("tutorial-family-royal-viewports-frozen")
    scene.king.viewport.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE;scene.queen_teacher.viewport.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE
    Engine.time_scale=0
    for actor in [scene.king,scene.queen_teacher]:
        if actor.get("reaction_elapsed")!=null:actor.reaction_elapsed=100.0;actor.reaction_mode=""
    for i in range(144):
        var t:=float(i)/12.0
        var km: String="idle";var qm: String="idle"
        if t>=2 and t<4:km="talk";qm="listen"
        elif t>=4 and t<6:km="listen";qm="talk"
        elif t>=6 and t<8:km="wave";qm="wave"
        elif t>=8 and t<10:km="celebrate";qm="cast"
        elif t>=10:km="swim";qm="swim"
        scene.king.set_travel(Vector2(110,0) if t>=10 else Vector2.ZERO);scene.queen_teacher.set_travel(Vector2(-80,0) if t>=10 else Vector2.ZERO)
        for tick in range(2):
            scene.time+=1.0/24;scene.king.animate(scene.time,km,false);scene.queen_teacher.animate(scene.time,qm,false)
            scene.native_rig.set_motion(Vector2.ZERO,1,false,false,1);scene.native_rig.gesture_player.advance(1.0/24);scene.native_rig._process(1.0/24)
        await snap("family_%03d" % i)
    for size in [Vector2i(1280,720),Vector2i(844,390)]:
        root.size=size;for i in range(5):await frame()
        scene.simulated_touch=true;scene._on_viewport_resized();scene._layout_tutorial();stage(scene);scene._open_dialogue("gifts")
        if scene.speech_reveal:scene.speech_reveal.kill()
        scene.dialogue_text.modulate.a=1;scene.dialogue_text.visible_ratio=1
        for i in range(24):
            for tween in get_processed_tweens():
                if is_instance_valid(tween):tween.custom_step(1.0/60)
            scene.king._advance(1.0/60,"listen",false);scene.queen_teacher._advance(1.0/60,"talk",false)
            await frame()
        await snap("dialogue_%dx%d" % [size.x,size.y]);scene._close_dialogue()
    qa_metrics["render_counters"]=counters
    var file:=FileAccess.open(output+"/metrics.json",FileAccess.WRITE);file.store_string(JSON.stringify(qa_metrics,"  "));file.close();scene.free();await frame();print("FAMILY QA COMPLETE ",output);quit()

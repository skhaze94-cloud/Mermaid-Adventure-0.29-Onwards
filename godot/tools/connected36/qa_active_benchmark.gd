extends SceneTree
var output:=OS.get_environment("FAMILY_BENCH_OUT")
func _initialize() -> void:call_deferred("run")
func frame() -> void:await process_frame;await RenderingServer.frame_post_draw
func rss_bytes() -> int:
    var status:=FileAccess.get_file_as_string("/proc/self/status")
    for line in status.split("\n"):
        if line.begins_with("VmRSS:"):
            var parts:=line.split("\t",false)
            if parts.size()>1:return int(parts[1].strip_edges().split(" ",false)[0])*1024
    return 0
func run() -> void:
    root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(1120,768)
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true;prefs.economy=false;prefs.reduced_motion=false
    root.get_node("AdventureRun").persist_enabled=false;root.get_node("AdventureRun").active=false;root.get_node("OceanAudio").playback_enabled=false
    var load_begin:=Time.get_ticks_usec()
    var scene=load("res://godot/training_lagoon.tscn").instantiate();root.add_child(scene)
    var instantiate_ms:=(Time.get_ticks_usec()-load_begin)/1000.0
    await frame()
    var first_frame_ms:=(Time.get_ticks_usec()-load_begin)/1000.0
    for i in range(5):await frame()
    scene.music_player.stop();scene.music_player.stream=null;scene.set_process(false);scene.set_physics_process(false);scene.native_rig.set_process(false);scene.king.set_process(false);scene.queen_teacher.set_process(false)
    scene._close_dialogue();scene._advance_lesson(6);scene.player=Vector2(5500,580);scene.camera=4900;scene.arrival_time=3;scene.arrival_intro_pending=false;scene.king_world=Vector2(5150,490);scene.queen_world=Vector2(6100,530);scene.deep_routes.sync(true);scene._sync_native_visuals();scene.queue_redraw()
    for actor in [scene.king,scene.queen_teacher]:
        if actor.get("reaction_elapsed")!=null:actor.reaction_elapsed=100.0;actor.reaction_mode=""
    var rows:=[]
    for mode in ["Full","Gentle","Economy"]:
        prefs.economy=mode=="Economy";prefs.reduced_motion=mode=="Gentle"
        scene.native_rig.reduced_motion=mode=="Gentle";scene.native_rig.set_quality(mode!="Economy")
        if scene.king.has_method("set_quality"):scene.king.set_quality(mode!="Economy")
        if scene.queen_teacher.has_method("set_quality"):scene.queen_teacher.set_quality(mode!="Economy")
        var samples:=[];var scripts:=[];var draws:=0.0;var primitives:=0.0
        for i in range(120):
            var begin:=Time.get_ticks_usec()
            scene.time+=1.0/60;scene.king.animate(scene.time,"talk" if i<60 else "wave",mode=="Gentle");scene.queen_teacher.animate(scene.time,"listen" if i<60 else "cast",mode=="Gentle")
            scene.native_rig.set_motion(Vector2(280,0),1,false,false,1);scene.native_rig._process(1.0/60)
            var script_us:=Time.get_ticks_usec()-begin
            await frame()
            if i>=30:
                scripts.append(script_us);samples.append(Time.get_ticks_usec()-begin);draws+=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME);primitives+=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
        samples.sort();scripts.sort();var total:=0.0;var cpu:=0.0
        for value in samples:total+=value
        for value in scripts:cpu+=value
        rows.append({"mode":mode,"mean_frame_ms":total/90/1000,"median_frame_ms":samples[45]/1000.0,"p95_frame_ms":samples[85]/1000.0,"mean_character_script_ms":cpu/90/1000,"p95_character_script_ms":scripts[85]/1000.0,"draw_calls_mean":draws/90,"primitives_mean":primitives/90,"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"rss_bytes":rss_bytes(),"render_buffer_bytes":Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED),"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC)})
    var bones:=[]
    for actor in [scene.king,scene.queen_teacher]:
        var count:=0
        for node in actor.find_children("*","Skeleton3D",true,false):count+=node.get_bone_count()
        bones.append({"role":actor.role,"bones":count})
    var data:={"instantiate_ms":instantiate_ms,"first_scene_frame_ms":first_frame_ms,"royal_skeletons":bones,"engine":Engine.get_version_info()["string"],"renderer":RenderingServer.get_video_adapter_name(),"resolution":"1120x768","method":"30 warm +90 timed frames, actual native rendered intervals, deterministic 60Hz character updates; tutorial world held for matching composition; screenshot writes excluded","results":rows}
    var file:=FileAccess.open(output,FileAccess.WRITE);file.store_string(JSON.stringify(data,"  "));file.close();scene.free();await frame();print("ACTIVE FAMILY BENCH COMPLETE");quit()

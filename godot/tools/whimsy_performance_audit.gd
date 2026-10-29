extends "res://godot/tools/performance_audit.gd"
const ANCHORS:=[6350.0,6200.0,14500.0,5000.0,17000.0,29500.0,4300.0,1500.0]
func run() -> void:
    Engine.time_scale=0;root.size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.economy=false;prefs.reduced_motion=false;prefs.intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false;root.get_node("AdventureRun").active=false
    report["environment"]={"engine":Engine.get_version_info().string,"adapter":RenderingServer.get_video_adapter_name(),"quality":"full","resolution":[1400,960],"scope":"Same frozen native scene with only the new flourish layers hidden/shown; no original quality changes. CPU samples measure new layers only, not FPS."}
    for index in range(8):
        var selected:=OS.get_environment("ADVENTURE_AUDIT_CASE")
        if not selected.is_empty() and selected!=str(index):continue
        var scene=load(root.get_node("AdventureRun").SCENES[index]).instantiate();root.add_child(scene)
        var calls: Array[Node]=[];var animations: Array[AnimationPlayer]=[];freeze(scene,calls,animations)
        for i in range(3):await process_frame
        scene.fallen=true;scene.player=Vector2(ANCHORS[index],620);scene.camera=scene.player.x-550
        scene.boss_hp=0 if index==6 else scene._boss_max_health();scene.music_player.stop();scene.time=4
        if index==7:scene.lesson=1;scene.dialogue_open=false;scene.dialogue_card.hide();scene.choice_card.hide();scene.lesson_card.hide()
        scene._sync_native_visuals()
        var garden=scene.whimsy_garden;var moments=scene.whimsy_moments
        var nodes: int=Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
        var samples: Array[float]=[]
        for frame in range(180):
            var started:=Time.get_ticks_usec()
            garden.set_world(scene.camera,scene._water_line(),scene.player,index,false,false,true,false)
            moments.set_world(scene.camera,scene._water_line(),scene.player,index,false,false,true,false)
            garden.advance(1.0/60);moments.advance(1.0/60)
            if frame%20==0:moments.celebrate(scene.player+Vector2(170,0),"treasure")
            if frame>=30:samples.append((Time.get_ticks_usec()-started)/1000.0)
        var draws: Dictionary={};var textures: Dictionary={}
        var builds: Array[float]=[]
        for enabled in [false,true]:
            garden.visible=enabled;moments.visible=enabled
            var values: Array[float]=[]
            for frame in range(12):
                garden.visible=enabled;moments.visible=enabled
                scene.queue_redraw();garden.queue_redraw();moments.queue_redraw();await process_frame
                if rendered:await RenderingServer.frame_post_draw
                assert(garden.visible==enabled and moments.visible==enabled)
                if frame>=4:
                    values.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
                    if enabled:builds.append(float(garden.last_build_us)/1000.0)
            draws["on" if enabled else "off"]=stats(values)
            textures["on" if enabled else "off"]=Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
        report[str(index)]={"new_layer_update":stats(samples),"ornament_build_and_upload":stats(builds),"batch_vertices":garden.batch_used,"batch_vertex_cap":garden.BATCH_VERTEX_CAP,"batch_overflows":garden.batch_overflows,"draw_calls":draws,"texture_bytes":textures,"node_growth":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))-nodes,"station_count":garden.station_count,"moment_slots":moments.pool.size()}
        print("AUDIT WHIMSY ",index," ",JSON.stringify(report[str(index)]))
        root.remove_child(scene);scene.free()
        for i in range(3):await process_frame
    var file:=FileAccess.open(output+"/results.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
    print("WHIMSY PERFORMANCE AUDIT COMPLETE");quit()

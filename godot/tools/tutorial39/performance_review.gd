extends SceneTree
var rows:=[]
func _initialize() -> void:call_deferred('run')
func frame() -> void:await process_frame;await RenderingServer.frame_post_draw
func run() -> void:
    root.size=Vector2i(1120,700);root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
    root.get_node('AppPreferences').persist_enabled=false;root.get_node('AppPreferences').intro_seen=true
    root.get_node('AdventureRun').persist_enabled=false;root.get_node('AdventureRun').active=false;root.get_node('OceanAudio').playback_enabled=false
    var scene=load('res://godot/training_lagoon.tscn').instantiate();root.add_child(scene)
    for i in range(3):await frame()
    scene.set_process(false);scene.set_physics_process(false);scene.music_player.stop();scene.music_player.stream=null
    if scene.get('mesh_y_friends'):scene.mesh_y_friends.set_process(false)
    if scene.dialogue_open:scene._close_dialogue()
    scene.state='playing';scene.lesson=0;scene.lesson_card.hide();scene.player=Vector2(900,1450);scene.camera=250;scene.player_velocity=Vector2.ZERO;scene.arrival_intro_pending=false;scene.arrival_time=3
    for mode in ['Full','Economy']:
        scene.high_depth_quality=mode=='Full';scene.reduced_fx=false
        var times:=[];var cpus:=[];var draws:=[];var triangles:=[]
        for i in range(28):
            var start:=Time.get_ticks_usec()
            scene.time+=1.0/30;scene.deep_routes.sync(true);scene._sync_native_visuals();scene.treasure_gallery.sync(true,1.0/30)
            if scene.get('mesh_y_friends'):scene.mesh_y_friends._process(1.0/30)
            scene.queue_redraw();var cpu:=(Time.get_ticks_usec()-start)/1000.0
            await frame()
            if i>=8:
                times.append((Time.get_ticks_usec()-start)/1000.0);cpus.append(cpu);draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME));triangles.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
        var row:={'mode':mode,'frame_interval_ms':mean(times),'cpu_visual_sync_ms':mean(cpus),'draw_calls':mean(draws),'render_primitives':mean(triangles),'texture_bytes':Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),'static_bytes':Performance.get_monitor(Performance.MEMORY_STATIC)}
        rows.append(row);print(row)
    var report:={'engine':Engine.get_version_info().string,'renderer':RenderingServer.get_video_adapter_name(),'fixture':'1120x700 nursery; 8 warm-up + 20 samples per mode. Deterministic 30 Hz presentation steps. llvmpipe; not physical-device FPS.','rows':rows}
    FileAccess.open(OS.get_environment('MESHY_PERF'),FileAccess.WRITE).store_string(JSON.stringify(report,'  '));scene.free();quit()
func mean(values: Array) -> float:
    var total:=0.0
    for x in values:total+=x
    return total/maxf(1,values.size())

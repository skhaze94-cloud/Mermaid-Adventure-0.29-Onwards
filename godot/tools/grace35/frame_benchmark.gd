extends SceneTree
var rows:=[]
func _initialize() -> void:call_deferred("run")
func frame() -> void:await process_frame;await RenderingServer.frame_post_draw
func run() -> void:
    root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(840,576)
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true;prefs.reduced_motion=false;prefs.economy=false
    root.get_node("AdventureRun").persist_enabled=false;root.get_node("AdventureRun").active=false;root.get_node("OceanAudio").playback_enabled=false
    for kind in ["opening","tutorial-swim"]:
        var scene=load("res://godot/title_screen.tscn" if kind=="opening" else "res://godot/training_lagoon.tscn").instantiate();root.add_child(scene)
        for i in range(8):await frame()
        if kind=="tutorial-swim":
            scene.set_process(false);scene.set_physics_process(false);scene.music_player.stop();scene._close_dialogue();scene._advance_lesson(1);scene.player=Vector2(1750,620);scene.camera=1100;scene.deep_routes.sync(true);scene._sync_native_visuals();scene.native_rig.reset_performance();scene.native_rig.set_steering(Vector2.RIGHT);scene.native_rig.set_motion(Vector2(345,0),1,false,false,1);scene.queue_redraw()
        for i in range(30):await frame()
        var samples:=[]
        for i in range(90):
            var began:=Time.get_ticks_usec();await frame();samples.append(Time.get_ticks_usec()-began)
        samples.sort();var total:=0.0
        for value in samples:total+=value
        rows.append({"scene":kind,"mean_frame_ms":total/samples.size()/1000,"median_frame_ms":samples[samples.size()/2]/1000.0,"p95_frame_ms":samples[int(samples.size()*.95)]/1000.0,"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"renderer":RenderingServer.get_video_adapter_name(),"resolution":"840x576","frames":90})
        scene.free();await frame()
    var file:=FileAccess.open(OS.get_environment("GRACE_FRAME_OUT"),FileAccess.WRITE);file.store_string(JSON.stringify(rows,"  "));file.close();print("GRACE NATIVE FRAME BENCH COMPLETE");quit()

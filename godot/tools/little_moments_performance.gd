extends SceneTree
var output:=OS.get_environment("MOMENTS_PERF_DIR")
func _initialize() -> void:call_deferred("run")
func frame() -> void:await process_frame;await RenderingServer.frame_post_draw
func tick(scene,camera: float) -> float:
    var start:=Time.get_ticks_usec()
    scene._physics_process(1.0/60);scene.camera=camera;scene._process(1.0/60)
    scene.native_rig.gesture_player.advance(1.0/60);scene.native_rig._process(1.0/60);scene.queue_redraw()
    return (Time.get_ticks_usec()-start)/1000.0
func run() -> void:
    DirAccess.make_dir_recursive_absolute(output);Engine.time_scale=0;root.size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.reduced_motion=false;prefs.economy=false;prefs.intro_seen=true
    root.get_node("AdventureRun").active=false;root.get_node("AdventureRun").avina_along=false;root.get_node("OceanAudio").playback_enabled=false
    var results: Dictionary={}
    for id in ["tutorial","post","cavern"]:
        var scene=load("res://godot/training_lagoon.tscn" if id=="tutorial" else "res://godot/highland_level.tscn").instantiate();root.add_child(scene);scene.music_player.stop();scene.music_player.stream=null
        await frame();await frame();scene.set_process(false);scene.set_physics_process(false);scene.native_rig.set_process(false)
        scene.native_rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
        scene.enemies.clear();scene.animated_enemies.bind_enemies(scene.enemies);scene.fallen=false;scene.message_time=0;scene.invulnerable=0
        var camera:=250.0 if id=="tutorial" else 1150.0 if id=="post" else 1010.0
        scene.player=Vector2(850,580) if id=="tutorial" else Vector2(1720,630) if id=="post" else Vector2(2000,1455)
        scene.player_velocity=Vector2.ZERO;scene.native_rig.reset_performance()
        if id=="tutorial":scene._close_dialogue();scene.lesson=1;scene.arrival_time=2.6;scene._show_lesson()
        scene.camera=camera;scene._sync_native_visuals();scene.deep_routes.sync(true)
        for i in range(30):tick(scene,camera);await frame()
        var cpu: Array[float]=[]
        for i in range(180):cpu.append(tick(scene,camera))
        cpu.sort();var sum:=0.0
        for sample in cpu:sum+=sample
        var frames: Array[float]=[]
        for i in range(30):
            var start:=Time.get_ticks_usec();tick(scene,camera);await frame();frames.append((Time.get_ticks_usec()-start)/1000.0)
        frames.sort()
        results[id]={"tick_mean_ms":sum/cpu.size(),"tick_p95_ms":cpu[171],"software_frame_median_ms":frames[15],"software_frame_p95_ms":frames[28],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"submitted_primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"static_bytes":OS.get_static_memory_usage()}
        scene.premium_hud.clear_feedback();scene.queue_redraw();await frame();await frame();root.get_texture().get_image().save_png(output+"/"+id+".png")
        scene.free();await frame();await frame()
    FileAccess.open(output+"/performance.json",FileAccess.WRITE).store_string(JSON.stringify(results,"  "))
    print("LITTLE MOMENTS PERFORMANCE ",JSON.stringify(results));quit()

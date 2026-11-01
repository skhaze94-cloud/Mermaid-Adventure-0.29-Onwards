extends SceneTree
var rows:=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
    root.get_node("AppPreferences").persist_enabled=false;root.get_node("AppPreferences").intro_seen=true;root.get_node("OceanAudio").playback_enabled=false
    var rig=load("res://godot/sarah_rig.gd").new();root.add_child(rig);rig.set_process(false)
    rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.jump_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    for mode in ["Full","Economy","Gentle"]:
        rig.reset_jump();rig.reset_performance();rig.set_quality(mode!="Economy");rig.reduced_motion=mode=="Gentle"
        rig.set_steering(Vector2.RIGHT);rig.set_motion(Vector2(345,0),1,false,false,1)
        for i in range(120):rig._process(1.0/60)
        var times:=[]
        for i in range(360):
            var began:=Time.get_ticks_usec();rig._process(1.0/60);times.append(Time.get_ticks_usec()-began)
        times.sort();var total:=0.0
        for value in times:total+=value
        var vertices:=0
        for part in rig.painted_parts:
            if part.get("polygon")!=null:vertices+=part.polygon.size()
        rows.append({"scene":"swim","mode":mode,"mean_us":total/times.size(),"median_us":times[times.size()/2],"p95_us":times[int(times.size()*.95)],"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"vertices":vertices,"nodes":rig.get_child_count()})
    rig.free()
    var menu=load("res://godot/title_screen.tscn").instantiate();root.add_child(menu);menu.set_process(false);menu.hero_rig.set_process(false)
    menu.hero_rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    for i in range(120):menu.hero_performance.update(menu,1.0/60)
    var times:=[]
    for i in range(360):
        var began:=Time.get_ticks_usec();menu.hero_performance.update(menu,1.0/60);times.append(Time.get_ticks_usec()-began)
    times.sort();var total:=0.0
    for value in times:total+=value
    rows.append({"scene":"opening-performance","mean_us":total/times.size(),"median_us":times[times.size()/2],"p95_us":times[int(times.size()*.95)],"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC)})
    menu.free();var file:=FileAccess.open(OS.get_environment("GRACE_BENCH_OUT"),FileAccess.WRITE);file.store_string(JSON.stringify(rows,"  "));file.close();print("GRACE BENCH COMPLETE");quit()

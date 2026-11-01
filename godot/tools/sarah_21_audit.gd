extends SceneTree
const Rig=preload("res://godot/sarah_rig.gd")
var output:=OS.get_environment("SARAH_AUDIT_DIR")
var checks:=0
var rig: Node2D
func _initialize() -> void:call_deferred("run")
func frame() -> void:
    await process_frame;await RenderingServer.frame_post_draw
func still(name: String) -> void:
    await frame();await frame()
    root.get_texture().get_image().save_png(output+"/"+name+".png")
func pose(velocity: Vector2,boost:=false,phase:="",at:=.4) -> void:
    rig.reset_performance();rig.jump_player.stop();rig.gesture_player.stop();rig._clear_gesture_values()
    rig.set_motion(velocity,1,boost,phase!="",1);rig.set_steering(velocity.normalized())
    if phase!="":rig.start_jump(0,1);rig.set_jump_state(phase,at,0,1)
    for i in range(60):rig._process(1.0/60)
    rig.scale*=3.0;rig.position=Vector2(650,420)
func bench() -> Dictionary:
    var results: Dictionary={}
    for kind in ["idle","swim","boost","jump","economy","gentle"]:
        rig.reset_performance();rig.reduced_motion=kind=="gentle";rig.set_quality(kind!="economy")
        rig.set_motion(Vector2(260,-60) if kind!="idle" else Vector2.ZERO,1,kind=="boost",kind=="jump",1)
        if kind=="jump":rig.set_jump_state("airborne",.4,0,1)
        for i in range(30):rig._process(1.0/60)
        var samples: Array[float]=[]
        for i in range(180):
            var start:=Time.get_ticks_usec();rig._process(1.0/60);samples.append((Time.get_ticks_usec()-start)/1000.0)
        samples.sort();var sum:=0.0
        for sample in samples:sum+=sample
        results[kind]={"mean_ms":sum/samples.size(),"p95_ms":samples[int(samples.size()*.95)]}
    var vertices:=0;var builds:=0
    for part in rig.painted_parts:
        if part.get("vertex_count")!=null:vertices+=part.vertex_count;builds+=part.topology_builds
    results["geometry"]={"vertices":vertices,"topology_builds":builds,"nodes":rig.get_child_count()}
    results["process_memory_bytes"]=OS.get_static_memory_usage()
    return results
func run() -> void:
    DirAccess.make_dir_recursive_absolute(output)
    root.size=Vector2i(1400,960);root.get_node("AppPreferences").persist_enabled=false;root.get_node("AppPreferences").intro_seen=true;root.get_node("OceanAudio").playback_enabled=false
    var bg:=ColorRect.new();bg.color=Color("163e52");bg.size=Vector2(1400,960);root.add_child(bg)
    rig=Rig.new();root.add_child(rig);rig.set_process(false);rig.hero_light.hide();rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL;rig.jump_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    for state in ["idle","swim","boost","ascent","airborne","reentry","cast","turn"]:
        pose(Vector2.ZERO if state=="idle" else Vector2(270,-50),state=="boost",state if state in ["ascent","airborne","reentry"] else "")
        if state=="cast":rig.set_bubble_charge(true,1);rig.play_gesture("cast");rig.gesture_player.advance(.35);rig._process(.016);rig.scale*=3
        if state=="turn":rig.set_motion(Vector2(-250,30),-1,false,false,1);rig._process(.08);rig.scale*=3
        await still(state)
    var report:=bench()
    rig.reduced_motion=false;rig.set_quality(true);rig.scale=Vector2.ONE*3;rig.position=Vector2(650,420)
    var frame_times: Array[float]=[]
    for i in range(30):
        var start:=Time.get_ticks_usec();rig._process(1.0/60);rig.scale*=3;await frame();frame_times.append((Time.get_ticks_usec()-start)/1000.0)
    frame_times.sort()
    report["render"]={"frame_median_ms":frame_times[15],"frame_p95_ms":frame_times[28],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)}
    rig.free();bg.free()
    var menu=load("res://godot/title_screen.tscn").instantiate();root.add_child(menu);menu.set_process(false)
    for i in range(4):await frame()
    for i in range(300):menu.hero_performance.update(menu,1.0/60)
    await still("opening")
    for t in [8,26]:
        menu.hero_performance.reset();menu.hero_rig.reset_performance()
        for i in range(t*60):menu.hero_performance.update(menu,1.0/60)
        await still("opening-"+str(t))
        var wall: Array[float]=[]
        for i in range(30):
            var start:=Time.get_ticks_usec();menu.hero_performance.update(menu,1.0/60);await frame();wall.append((Time.get_ticks_usec()-start)/1000.0)
        wall.sort()
        report["menu_"+str(t)]={"software_frame_median_ms":wall[15],"software_frame_p95_ms":wall[28],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"static_bytes":OS.get_static_memory_usage(),"submitted_primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)}
    menu.free();await frame();await frame()
    var scene=load("res://godot/highland_level.tscn").instantiate();root.add_child(scene)
    for i in range(4):await frame()
    scene.set_process(false);scene.set_physics_process(false);scene.native_rig.set_process(false)
    scene.boss_hp=0;scene.fallen=true;scene.player=Vector2(12000,550);scene.checkpoint=12000;scene.invulnerable=0;scene.message_time=0
    for enemy in scene.enemies:enemy["hp"]=0
    scene.animated_enemies.bind_enemies(scene.enemies);scene.touch_vectors[97]=Vector2.RIGHT
    var game_times: Array[float]=[]
    for i in range(60):
        var start:=Time.get_ticks_usec();scene._physics_process(1.0/60);scene._sync_native_visuals();scene.native_rig._process(1.0/60);await frame()
        if i>=30:game_times.append((Time.get_ticks_usec()-start)/1000.0)
    game_times.sort()
    report["gameplay"]={"software_frame_median_ms":game_times[15],"software_frame_p95_ms":game_times[28],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"static_bytes":OS.get_static_memory_usage(),"submitted_primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)}
    await still("gameplay")
    scene.free();await frame();await frame()
    FileAccess.open(output+"/performance.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    print("SARAH AUDIT ",JSON.stringify(report));quit()

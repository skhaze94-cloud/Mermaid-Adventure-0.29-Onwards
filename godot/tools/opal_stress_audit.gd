extends "res://godot/tools/performance_audit.gd"
## Same workload/script for v0.5.1 and Opal: eight friendly, 32 hostile, six foes.
const KINDS:=["crab","eel","jelly","puffer","swordfish","shark"]
func seed_shots(scene) -> void:
    while scene.bubble_shots.size()<8:scene.bubble_shots.append({})
    while scene.hostile_shots.size()<32:scene.hostile_shots.append({})
    for i in range(8):
        var shot: Dictionary=scene.bubble_shots[i]
        shot["pos"]=Vector2(scene.camera+160+(i%4)*75,350+(i/4)*65);shot["direction"]=1.0;shot["life"]=1.8
        shot["tier"]=1 if i<7 else 3;shot["damage"]=1;shot["boss_damage"]=1;shot["owner"]="sarah";shot["baby"]=false;shot["consumed"]=false
        shot.erase("packet_id");shot.erase("spawn_from")
    for i in range(32):
        var shot: Dictionary=scene.hostile_shots[i]
        shot["pos"]=Vector2(scene.camera+520+(i%8)*94,360+(i/8)*135);shot["velocity"]=Vector2(-240,0);shot["life"]=2.8
        shot["style"]=scene._opal_primary_id() if scene.has_method("_opal_primary_id") else "boss"
func stress_case(name: String, path: String) -> void:
    seed(90125)
    var started:=Time.get_ticks_usec();var scene=load(path).instantiate();root.add_child(scene)
    var startup:=(Time.get_ticks_usec()-started)/1000.0
    var calls: Array[Node]=[];var animations: Array[AnimationPlayer]=[];freeze(scene,calls,animations)
    scene.music_player.stop();scene.invulnerable=10000;scene.fallen=true;scene.message_time=0
    scene.player=Vector2(scene._boss_home()-500,560);scene.camera=scene._boss_home()-850;scene.bubble_unlocked=true;scene.player_velocity=Vector2(310,0)
    scene.enemies.clear()
    for i in range(6):
        var at:=Vector2(scene.camera+450+(i%3)*300,710+(i/3)*80)
        scene.enemies.append({"kind":KINDS[i],"x":at.x,"y":at.y,"bx":at.x,"by":at.y,"hp":4,"phase":float(i),"dir":-1,
            "mode":"patrol","mode_time":0.0,"cooldown":1.0,"hit_cd":0.0,"aim":Vector2.LEFT})
    scene.animated_enemies.bind_enemies(scene.enemies)
    if scene.get("lesson")!=null:
        scene.lesson=8;scene.dialogue_open=false;scene.dialogue_card.hide();scene.choice_card.hide();scene.king_world=scene.boss_position;scene.character_dt=1.0/60
    var is_opal: bool=scene.get("opal")!=null
    if is_opal and name!="training":scene.opal.begin("audit");scene.opal.advance(1.35)
    var cpu: Array[float]=[];var wall: Array[float]=[];var draws: Array[float]=[];var cold_frames: Array[float]=[]
    for frame in range(90):
        scene.boss_hit_cooldown=999.0;seed_shots(scene)
        var start:=Time.get_ticks_usec();scene._physics_process(1.0/60)
        var physics:=(Time.get_ticks_usec()-start)/1000.0
        seed_shots(scene)
        if frame%24==0:
            scene.native_fx.splash(scene.player-Vector2(scene.camera,0)+Vector2(250,0),Color("d5fbff"),8)
            if is_opal:scene.opal_fx.impact(scene.player+Vector2(250,0),3,true)
        var visual_start:=Time.get_ticks_usec()
        for animation in animations:
            if animation.is_playing():animation.advance(1.0/60)
        for node in calls:node._process(1.0/60)
        var script_ms:=physics+(Time.get_ticks_usec()-visual_start)/1000.0
        await process_frame
        if rendered:await RenderingServer.frame_post_draw
        var frame_ms:=(Time.get_ticks_usec()-start)/1000.0
        if frame<30:cold_frames.append(frame_ms)
        else:
            cpu.append(script_ms);wall.append(frame_ms);draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
    report[name]={"startup_ms":startup,"cold_frame":stats(cold_frames),"first_frame_ms":cold_frames[0],"cold_max_ms":cold_frames.max(),"cpu":stats(cpu),"frame":stats(wall),"draw_calls":stats(draws),
        "texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"objects":Performance.get_monitor(Performance.OBJECT_COUNT),
        "friendly_count":scene.bubble_shots.size(),"hostile_count":scene.hostile_shots.size()}
    if rendered:assert(root.get_texture().get_image().save_png(output+"/stress-"+name+".png")==OK)
    print("AUDIT STRESS ",name," ",JSON.stringify(report[name]));root.remove_child(scene);scene.free()
    for i in range(3):await process_frame
func run() -> void:
    Engine.time_scale=0;root.size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
    rendered=DisplayServer.get_name()!="headless"
    if rendered:DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true;prefs.economy=false;prefs.reduced_motion=false
    root.get_node("OceanAudio").playback_enabled=false;root.get_node("AdventureRun").avina_along=false
    report["environment"]={"engine":Engine.get_version_info().string,"adapter":RenderingServer.get_video_adapter_name(),"resolution":[1400,960],
        "quality":"full","fixed_step":1.0/60,"warmup_frames":30,"measured_frames":60,"friendly":8,"hostile":32,"live_enemies":6,"impact_interval_frames":24,
        "note":"Manual updates; native particles/tweens frozen like the base audit. New charge/impact geometry remains active. Seeding excluded from CPU."}
    await stress_case("highland","res://godot/highland_level.tscn");await stress_case("shadow","res://godot/shadow_kingdom.tscn")
    await stress_case("palace","res://godot/pearl_palace.tscn");await stress_case("training","res://godot/training_lagoon.tscn")
    var file:=FileAccess.open(output+"/results.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
    print("OPAL STRESS AUDIT COMPLETE");quit()

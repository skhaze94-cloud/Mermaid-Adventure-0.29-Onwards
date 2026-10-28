extends SceneTree
## Deterministic, full-quality CPU/render audit. Run unchanged against either revision.
var report: Dictionary = {}
var output := ""
var rendered := false
var frames_to_measure := 60
var quick := false

func _initialize() -> void:
    output = OS.get_environment("ADVENTURE_AUDIT_DIR")
    if output.is_empty(): output = "user://performance-audit"
    DirAccess.make_dir_recursive_absolute(output)
    rendered = DisplayServer.get_name() != "headless"
    quick = OS.get_environment("ADVENTURE_AUDIT_QUICK") == "1"
    call_deferred("run")

func stats(values: Array[float]) -> Dictionary:
    values.sort()
    var total := 0.0
    for v in values: total += v
    return {"mean_ms":total/values.size(),"median_ms":values[values.size()/2],
        "p95_ms":values[mini(values.size()-1,int(values.size()*.95))]}

func freeze(node: Node, calls: Array[Node], animations: Array[AnimationPlayer]) -> void:
    node.process_mode = Node.PROCESS_MODE_DISABLED
    if node.is_processing() and node.has_method("_process"): calls.append(node)
    if node is AnimationPlayer and node.callback_mode_process != AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL:
        animations.append(node)
    for child in node.get_children(): freeze(child,calls,animations)

func measure_cpu(rig) -> void:
    var cases := {
        "rig_process":func(): rig._process(1.0/60),
        "tail_skin":func(): rig.tail_skin.skin(rig.cycle_pose,rig.tail_tuck,rig.turn_kick),
        "arm_skin":func(): rig.arm_meshes[1].skin(.4,.25,.15,.1),
        "hair_skin":func(): rig.ribbons[0].deform(2.3,3.0,.1),
        "spine_and_torso":func(): rig.spine_motion.apply(rig,1.0/60,0,0,rig.swim_clock)
    }
    var timings := {}
    for name in cases:
        for warmup in range(3): cases[name].call()
        var samples: Array[float] = []
        for i in range(40):
            var start := Time.get_ticks_usec()
            cases[name].call()
            samples.append((Time.get_ticks_usec()-start)/1000.0)
        timings[name] = stats(samples)
    report["cpu_components"] = timings
    print("AUDIT CPU ",JSON.stringify(timings))

func run_case(name: String, path: String, spot: String = "entry") -> void:
    var selected := OS.get_environment("ADVENTURE_AUDIT_CASE")
    if not selected.is_empty() and name!=selected: return
    seed(90125)
    var start := Time.get_ticks_usec()
    var scene = load(path).instantiate()
    root.add_child(scene)
    var startup_ms := (Time.get_ticks_usec()-start)/1000.0
    var calls: Array[Node] = []
    var animations: Array[AnimationPlayer] = []
    freeze(scene,calls,animations)
    if scene.get("music_player"): scene.music_player.stop()
    var rig = scene.get("native_rig")
    if rig:
        scene.invulnerable = 10000
        scene.fallen = true
        scene.message_time = 0
        if spot == "boss": scene.player = Vector2(scene._boss_home()-300,540)
        else: scene.player = Vector2(800,540)
        scene.camera = clampf(scene.player.x-550,0,maxf(0,scene._level_length()-1400))
        if spot == "waterfall":
            scene.waterfall_phase = "descent"
            scene.waterfall_y = 180.0
        scene._sync_native_visuals()
    else:
        scene.show_page("menu")
        rig = scene.hero_rig
    rig.set_process(false)
    rig.reset_performance()
    rig.set_motion(Vector2(310,0),1,false,false,1)
    if name == "highland-entry": measure_cpu(rig)
    var cpu: Array[float] = []
    var wall: Array[float] = []
    var draws: Array[float] = []
    for frame in range(frames_to_measure+30):
        var frame_start := Time.get_ticks_usec()
        if scene.has_method("_physics_process"): scene._physics_process(1.0/60)
        for animation in animations:
            if animation.is_playing(): animation.advance(1.0/60)
        for node in calls: node._process(1.0/60)
        var cpu_ms := (Time.get_ticks_usec()-frame_start)/1000.0
        await process_frame
        if rendered: await RenderingServer.frame_post_draw
        if frame>=30:
            cpu.append(cpu_ms)
            wall.append((Time.get_ticks_usec()-frame_start)/1000.0)
            draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
    var result := {"startup_ms":startup_ms,"cpu":stats(cpu),"frame":stats(wall),"draw_calls":stats(draws),
        "nodes":scene.get_child_count(),"objects":Performance.get_monitor(Performance.OBJECT_COUNT),
        "render_objects":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
        "primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
        "texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)}
    report[name] = result
    if rendered:
        var picture := root.get_texture().get_image()
        assert(picture.save_png(output+"/"+name+".png")==OK)
    print("AUDIT ",name," ",JSON.stringify(result))
    root.remove_child(scene)
    scene.free()
    for frame in range(3): await process_frame

func run() -> void:
    # Fixed manual updates keep poses, enemy timing and screenshots comparable
    # even when one revision renders faster. Shader clocks already use game time.
    Engine.time_scale = 0.0
    root.size = Vector2i(1400,960)
    root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
    if rendered: DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
    var prefs = root.get_node("AppPreferences")
    prefs.persist_enabled = false
    prefs.intro_seen = true
    prefs.economy = false
    prefs.reduced_motion = false
    root.get_node("OceanAudio").playback_enabled = false
    report["environment"] = {"engine":Engine.get_version_info().string,"display":DisplayServer.get_name(),
        "adapter":RenderingServer.get_video_adapter_name(),"resolution":[1400,960],"quality":"full",
        "fixed_step":1.0/60,"warmup_frames":30,"measured_frames":frames_to_measure}
    await run_case("highland-entry","res://godot/highland_level.tscn")
    if not quick:
        await run_case("highland-boss","res://godot/highland_level.tscn","boss")
        await run_case("waterfall","res://godot/highland_level.tscn","waterfall")
        var catalog = root.get_node("AdventureRun")
        for index in range(1,catalog.SCENES.size()):
            await run_case("chapter-"+str(index),catalog.SCENES[index],"boss")
        await run_case("title","res://godot/title_screen.tscn")
    var file := FileAccess.open(output+"/results.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "))
    file.close()
    print("PERFORMANCE AUDIT COMPLETE")
    quit()

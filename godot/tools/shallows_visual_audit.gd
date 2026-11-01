extends "res://godot/tools/opal_visual_audit.gd"
var checked:=0
func picture(scene,label: String,tick: float) -> void:
    scene.living_shallows.sync()
    scene.living_shallows.clock=tick
    scene.living_shallows.advance(1.0/60)
    scene.living_shallows.sync()
    await snap(scene,label)
    assert(scene.living_shallows.batch_overflows==0,"opening garden brush stays bounded")
    checked+=1
func run() -> void:
    Engine.time_scale=0;root.size=Vector2i(1400,960)
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false
    root.get_node("AdventureRun").active=false;root.get_node("AdventureRun").avina_along=true
    var scene=setup(root.get_node("AdventureRun").SCENES[0])
    scene.fallen=false;scene.enemies.clear();scene.animated_enemies.bind_enemies(scene.enemies)
    scene.player=Vector2(1510,756);scene.player_velocity=Vector2.ZERO;scene.camera=1090;scene.boss_hp=3
    scene.native_rig.reset_performance();scene.native_rig.set_motion(Vector2.ZERO,1,false,false,1)
    if is_instance_valid(scene.avina):scene.avina.reset_follow();scene.avina.tick(0)
    scene.message_time=0
    scene._sync_native_visuals()
    for i in range(70):scene.living_shallows.advance(1.0/60)
    for phase in [4.0,8.7,12.0,16.0,24.0]:
        scene.living_shallows.line_key="";scene.living_shallows.speech_clock=0
        await picture(scene,"nori-postal-round-"+str(int(phase)),phase)
    scene.player=Vector2(1080,730);scene.camera=530
    await picture(scene,"sunlit-garden-trail",3.0)
    scene.player=Vector2(1510,756);scene.camera=1090
    root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(844,390)
    for i in range(4):await process_frame
    scene.simulated_touch=true;scene._on_viewport_resized()
    scene.living_shallows.line_key="";scene.living_shallows.speech_clock=0
    await picture(scene,"phone-nori-and-gardens",24.0)
    assert(scene.living_shallows.label_panel.visible,"Nori's phone greeting remains readable")
    scene.reduced_fx=true;scene.native_rig.reduced_motion=true
    await picture(scene,"phone-gentle-shallows",24.0)
    scene.reduced_fx=false;scene.high_depth_quality=false
    await picture(scene,"phone-economy-shallows",24.0)
    scene.state="paused";scene.living_shallows.sync()
    await snap(scene,"phone-paused-shallows")
    assert(not scene.living_shallows.label_panel.visible,"pause hides ambient speech")
    scene.state="playing";scene.fallen=true;scene.living_shallows.sync()
    assert(not scene.living_shallows.visible,"opening flourishes stay out of the waterfall's next area")
    await retire(scene)
    print("LIVING SHALLOWS VISUAL COMPLETE ",checked," views plus pause");quit()

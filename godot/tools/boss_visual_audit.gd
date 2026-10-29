extends "res://godot/tools/opal_visual_audit.gd"
func snap(scene, name: String) -> void:
    scene._sync_native_visuals();scene.premium_hud._process(.12)
    await super.snap(scene,name)

func run() -> void:
    Engine.time_scale=0
    root.size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
    var prefs=root.get_node("AppPreferences")
    prefs.persist_enabled=false;prefs.economy=false;prefs.reduced_motion=false;prefs.intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false
    var catalog=root.get_node("AdventureRun");catalog.active=false
    var paths: Array=catalog.SCENES
    var scene=setup(paths[0])
    for pattern in range(3):
        scene.boss_pattern=pattern;scene.boss_phase="windup";scene.boss_phase_time=0
        scene._update_boss(.01);await snap(scene,"carlo-warning-"+str(pattern))
    await retire(scene)
    for index in [1,2]:
        scene=setup(paths[index]);scene.boss_clock=1;scene.boss_shot_clock=1.2;scene._update_boss(0)
        await snap(scene,"journey-warning-"+str(index));await retire(scene)
    for index in [3,4,5,6]:
        scene=setup(paths[index]);scene.boss_clock=1.35;scene.attack_clock=1.2;scene._update_boss(0)
        await snap(scene,"signature-warning-"+str(index))
        if index==6:
            scene._update_boss(.49);scene._update_hostile_shots(.12)
            await snap(scene,"nessie-crest-flight")
        if index==5:
            scene.laser_y=520;scene.boss_clock=2.4;scene._update_boss(0)
            await snap(scene,"rana-laser-warning")
            scene.boss_clock=2.9;scene._update_boss(0)
            await snap(scene,"rana-laser-active")
        await retire(scene)
    scene=setup(paths[7]);scene.dialogue_open=false;scene.dialogue_card.hide();scene.choice_card.hide()
    scene.boss_clock=4.5;scene._update_boss(0)
    await snap(scene,"royal-wave-dash-preview");await retire(scene)
    catalog.begin(0)
    for i in range(6):catalog.complete_stage(i,1500+i*300)
    scene=setup(paths[6]);scene.boss_hp=1;scene.boss_clock=4.2;scene._update_boss(0)
    scene._sync_native_visuals();scene._opal_hit_boss("nessie",2)
    await snap(scene,"nessie-clear-feedback")
    scene.player=Vector2(scene._portal_x()+1,600);scene._update_swimming(0)
    scene.premium_hud._process(2)
    if scene.premium_hud.modal_reveal:scene.premium_hud.modal_reveal.kill()
    scene.premium_hud.modal.modulate.a=1
    await snap(scene,"crown-victory")
    root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(844,390)
    for i in range(4):await process_frame
    scene.simulated_touch=true;scene._on_viewport_resized()
    await snap(scene,"phone-crown-victory")
    assert(scene.premium_hud.action_rect("menu").end.y<=scene.premium_hud.game_size.y)
    await retire(scene)
    var file:=FileAccess.open(output+"/visual-review.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"pictures":pictures,"count":pictures.size(),"quality":"full","renderer":RenderingServer.get_video_adapter_name()},"  "));file.close()
    print("BOSS VISUAL AUDIT COMPLETE");quit()

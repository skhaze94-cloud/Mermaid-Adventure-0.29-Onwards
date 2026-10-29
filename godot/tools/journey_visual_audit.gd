extends "res://godot/tools/opal_visual_audit.gd"
## Full-quality native review fixtures; no changes to gameplay quality settings.
func snap(scene, name: String) -> void:
    scene._sync_native_visuals();scene.premium_hud._process(.12)
    await super.snap(scene,name)

func phone() -> void:
    root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(844,390)
    for i in range(4):await process_frame
func desktop() -> void:
    root.size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
    for i in range(4):await process_frame
func lesson(scene,index: int,at: Vector2) -> void:
    scene.lesson=index;scene.dialogue_open=false;scene.dialogue_card.hide();scene.choice_card.hide()
    scene.player=at;scene.camera=maxf(0,at.x-530);scene.boss_hp=3;scene._show_lesson();scene._layout_tutorial()

func run() -> void:
    Engine.time_scale=0
    await desktop()
    var prefs=root.get_node("AppPreferences")
    prefs.persist_enabled=false;prefs.economy=false;prefs.reduced_motion=false;prefs.intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false
    var catalog=root.get_node("AdventureRun");catalog.active=false
    var paths: Array=catalog.SCENES
    var scene=setup(paths[7])
    lesson(scene,0,Vector2(680,560));await snap(scene,"first-fins-desktop")
    await phone();scene.simulated_touch=true;scene._on_viewport_resized();scene._layout_tutorial()
    await snap(scene,"first-fins-phone")
    assert(scene.lesson_card.position.y+scene.lesson_card.size.y<scene._ui_view().y-40)
    scene._open_dialogue("intro");scene._layout_dialogue()
    await snap(scene,"family-dialogue-phone")
    scene._close_dialogue();lesson(scene,5,Vector2(4730,565));scene.reef_retry=true;scene._refresh_lesson_hint()
    await snap(scene,"reef-retry-phone")
    lesson(scene,10,Vector2(7140,390));scene.boss_hp=0;scene.bubble_unlocked=true;scene.fire_cooldown=0
    scene.opal.begin("audit");scene.opal.advance(1.35);scene._refresh_lesson_hint()
    await snap(scene,"super-practice-phone")
    assert(scene.lesson_card.position.y+scene.lesson_card.size.y<scene._ui_view().y-40)
    await desktop();scene.simulated_touch=false;scene._on_viewport_resized();scene._layout_tutorial()
    await snap(scene,"super-practice-desktop");await retire(scene)
    for index in [0,1,2,3,4,5]:
        scene=setup(paths[index]);scene._prepare_journey_stops()
        for stop in scene.journey_stops:
            if not stop["haven"]:continue
            scene.checkpoint=220;scene.player=Vector2(stop["x"]-210,600)
            scene.camera=maxf(0,float(stop["x"])-720);scene.message_time=0
            await snap(scene,"haven-chapter-"+str(index));break
        if index==5:
            scene.player=Vector2(scene._boss_home()-500,620);scene.camera=scene._boss_home()-850
            scene.boss_clock=1.4;scene.attack_clock=1.2;scene._update_boss(0)
            await snap(scene,"rana-final-approach")
        await retire(scene)
    scene=setup(paths[4]);dense(scene);await snap(scene,"busy-palace-full-quality");await retire(scene)
    var file:=FileAccess.open(output+"/visual-review.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"pictures":pictures,"count":pictures.size(),"quality":"full","renderer":RenderingServer.get_video_adapter_name()},"  "));file.close()
    print("JOURNEY VISUAL AUDIT COMPLETE");quit()

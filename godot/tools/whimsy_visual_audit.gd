extends "res://godot/tools/opal_visual_audit.gd"
const ANCHORS:=[6350.0,6200.0,14500.0,5000.0,17000.0,29500.0,4300.0,1500.0]
func snap(scene,name: String) -> void:
    scene.whimsy_garden.advance(.01);scene.whimsy_moments.advance(.01)
    await super.snap(scene,name)
func world(index: int):
    var scene=setup(root.get_node("AdventureRun").SCENES[index])
    scene.player=scene.RockCollision.recover(Vector2(ANCHORS[index],620),scene.obstacles,scene.HERO_RADIUS*.73,scene._swim_bounds())
    scene.camera=scene.player.x-550;scene.message_time=0;scene.boss_hp=0 if index==6 else scene._boss_max_health()
    if index==7:
        scene.lesson=1;scene.dialogue_open=false;scene.lesson_card.hide();scene.dialogue_card.hide();scene.choice_card.hide()
        scene.player=Vector2(1500,620);scene.camera=950;scene.king_world=Vector2(1900,490)
    scene._sync_native_visuals()
    return scene
func run() -> void:
    Engine.time_scale=0;root.size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.economy=false;prefs.reduced_motion=false;prefs.intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false;root.get_node("AdventureRun").active=false
    if OS.get_environment("ADVENTURE_AUDIT_CASE")=="menu":
        await capture_menu();print("WHIMSY MENU AUDIT COMPLETE");quit();return
    for index in range(8):
        var scene=world(index)
        scene.whimsy_garden.advance(2.3)
        scene.whimsy_moments.celebrate(scene.player+Vector2(180,0),"treasure");scene.whimsy_moments.advance(.2)
        await snap(scene,"chapter-"+str(index)+"-whimsy")
        scene.whimsy_garden.advance(.85);scene.whimsy_moments.advance(.1)
        await snap(scene,"chapter-"+str(index)+"-motion")
        if index==3:
            scene.reduced_fx=true;scene._sync_native_visuals();await snap(scene,"gentle-blackwater")
        if index==4:
            scene.high_depth_quality=false;scene._apply_visual_quality();scene._sync_native_visuals();await snap(scene,"economy-palace")
        if index==7:
            root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(844,390)
            for i in range(4):await process_frame
            scene.simulated_touch=true;scene._on_viewport_resized();await snap(scene,"phone-family-whimsy")
            root.size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
            for i in range(4):await process_frame
        await retire(scene)
    for index in [1,4]:
        var scene=setup(root.get_node("AdventureRun").SCENES[index]);dense(scene)
        scene.boss_clock=1.5;scene._sync_native_visuals();scene.whimsy_moments.celebrate(scene.player,"treasure")
        assert(scene.whimsy_moments.live_count()==0 and scene.whimsy_garden.combat)
        await snap(scene,"quiet-dense-combat-"+str(index));await retire(scene)
    await capture_menu()
    var file:=FileAccess.open(output+"/visual-review.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"pictures":pictures,"count":pictures.size(),"quality":"full except explicitly named gentle/economy views","renderer":RenderingServer.get_video_adapter_name()},"  "));file.close()
    print("WHIMSY VISUAL AUDIT COMPLETE");quit()

func capture_menu() -> void:
    var menu=load("res://godot/title_screen.tscn").instantiate();root.add_child(menu);menu.set_process(false);menu.show_page("menu")
    if menu.reveal_tween:menu.reveal_tween.kill()
    menu.content.modulate.a=1;menu._process(2.5)
    for i in range(5):await process_frame;await RenderingServer.frame_post_draw
    assert(root.get_texture().get_image().save_png(output+"/whimsy-menu.png")==OK);pictures.append("whimsy-menu")
    root.remove_child(menu);menu.free()

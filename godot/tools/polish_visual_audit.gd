extends "res://godot/tools/opal_visual_audit.gd"
## Deterministic native views of v0.6.1 UX and signature attacks at full quality.
func snap(scene, name: String) -> void:
    await super.snap(scene,name)
    if scene.state=="victory":
        assert(scene.premium_hud.action_rect("menu").end.y<=scene.premium_hud.game_size.y,"Results controls must remain on screen")

func menu_snap(menu, name: String) -> void:
    if menu.reveal_tween: menu.reveal_tween.kill()
    menu.content.modulate.a=1.0
    menu.hero_performance.clock=maxf(3.5,menu.hero_performance.clock)
    for i in range(8):
        menu._process(1.0/60)
        await process_frame; await RenderingServer.frame_post_draw
    assert(root.get_texture().get_image().save_png(output+"/"+name+".png")==OK)
    pictures.append(name); print("POLISH AUDIT ",name)
func retire(scene) -> void:
    paused=false
    await super.retire(scene)
func phone(scene) -> void:
    root.content_scale_size=Vector2i(1400,960)
    root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
    root.size=Vector2i(844,390)
    for i in range(4): await process_frame
    scene.simulated_touch=true;scene._on_viewport_resized()
func desktop() -> void:
    root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
    root.size=Vector2i(1400,960)
    for i in range(3): await process_frame

func run() -> void:
    Engine.time_scale=0; await desktop()
    var prefs=root.get_node("AppPreferences")
    prefs.persist_enabled=false;prefs.intro_seen=true;prefs.economy=false;prefs.reduced_motion=false;prefs.best_score=24000
    root.get_node("OceanAudio").playback_enabled=false
    var run_state=root.get_node("AdventureRun")
    run_state.begin(4)
    for i in range(8):run_state.records[i]={"best":1200+i*340,"stars":1+i%3}
    run_state.resume_state=run_state.export_state();run_state.active=false
    var menu=load("res://godot/title_screen.tscn").instantiate();root.add_child(menu)
    await menu_snap(menu,"continue-menu")
    menu.show_page("chapters");await menu_snap(menu,"chapter-records")
    root.remove_child(menu);menu.free()
    run_state.resume_state.clear();run_state.active=false
    var paths: Array=run_state.SCENES
    var scene=setup(paths[0]);scene.opal.begin("audit");scene.opal.advance(.675)
    await snap(scene,"desktop-prism-charge")
    scene.opal.advance(.675);await snap(scene,"desktop-super-ready")
    scene.opal.release("audit");scene.fire_cooldown=.325
    await snap(scene,"desktop-super-cooling-half")
    scene.message_time=0;scene._say("Guard broken — strike after recovery!",2,true)
    await phone(scene);await snap(scene,"phone-boss-feedback")
    scene.fire_cooldown=0;scene.opal.reset();scene.opal.begin("audit");scene.opal.advance(.675)
    await snap(scene,"phone-charge-progress");await retire(scene);await desktop()
    for index in [3,4,5,6]:
        scene=setup(paths[index]);scene.boss_clock=1.35;scene.attack_clock=.9;scene._update_boss(0)
        await snap(scene,"signature-"+scene.chapter_id+"-warning")
        scene._update_boss(.281);scene._update_hostile_shots(.12)
        await snap(scene,"signature-"+scene.chapter_id+"-flight");await retire(scene)
    scene=setup(paths[7]);scene.lesson=10;scene.boss_hp=0;scene.bubble_unlocked=true
    scene.player=Vector2(7240,500);scene.camera=6570;scene.dialogue_open=false;scene.dialogue_card.hide();scene.choice_card.hide();scene._show_lesson()
    await snap(scene,"optional-super-practice");await retire(scene)
    run_state.begin(7)
    for i in [7,0,1,2,3,4,5]:run_state.complete_stage(i,1500+i*450)
    scene=setup(paths[6]);scene.boss_hp=0;scene.score=4000;scene.player=Vector2(scene._portal_x()+1,600)
    scene._update_swimming(0);scene.premium_hud._process(2)
    if scene.premium_hud.modal_reveal: scene.premium_hud.modal_reveal.kill()
    scene.premium_hud.modal.modulate.a=1.0
    await snap(scene,"crown-adventure-results")
    await phone(scene);scene.premium_hud._process(2)
    await snap(scene,"phone-adventure-results");await retire(scene)
    var file:=FileAccess.open(output+"/visual-review.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"pictures":pictures,"count":pictures.size(),"quality":"full","renderer":RenderingServer.get_video_adapter_name()},"  "));file.close()
    print("POLISH VISUAL AUDIT COMPLETE");quit()

extends SceneTree
## Native rendered visual QA; no saved progression and no replacement gameplay.
## PEARL_QA_DIR is required. PEARL_QA_QUICK=1 captures only key states.
const Lines=preload("res://godot/family_dialogue.gd")
var output:=OS.get_environment("PEARL_QA_DIR")
var records: Array=[]
var failures:=0
func _initialize() -> void:call_deferred("run")
func frame() -> void:await process_frame;await RenderingServer.frame_post_draw
func settle(scene,count:=4) -> void:
    for i in range(count):
        for tween in get_processed_tweens():
            if is_instance_valid(tween):tween.custom_step(.06)
        scene._layout_tutorial()
        await frame()
func check(ok: bool,note: String) -> void:
    if not ok:failures+=1;push_error("PEARL CAPTURE: "+note)
func rect_data(control: Control) -> Dictionary:
    var rect:=control.get_global_rect()
    return {"x":rect.position.x,"y":rect.position.y,"w":rect.size.x,"h":rect.size.y,"visible":control.is_visible_in_tree()}
func snap(scene,name: String) -> void:
    await settle(scene)
    var im:=root.get_texture().get_image();im.save_png(output+"/"+name+".png")
    var hud=scene.premium_hud
    var row:={"view":name,"pixels":root.size,"logical":hud.game_size,"ui_scale":hud.ui_scale,
        "dialogue":rect_data(scene.dialogue_card),"speech_scroll":rect_data(scene.dialogue_scroll),
        "continue":rect_data(scene.dialogue_practice),"replies":scene.reply_box.get_child_count(),
        "health":rect_data(hud.health_card),"charge":rect_data(hud.charge_card),"score":rect_data(hud.score_card),"message":rect_data(hud.message_back)}
    if scene.dialogue_card.visible:
        var card: Rect2=scene.dialogue_card.get_global_rect().grow(1)
        check(Rect2(Vector2.ZERO,hud.game_size).grow(1).encloses(card),name+" conversation leaves safe canvas")
        check(card.encloses(scene.dialogue_scroll.get_global_rect()),name+" scroll viewport leaves conversation")
        check(card.encloses(scene.dialogue_practice.get_global_rect()),name+" primary action leaves conversation")
        check(not scene.premium_hud.visible and not scene.lesson_card.visible,name+" duplicate reading HUD")
    records.append(row)
func stage(scene) -> void:
    paused=false
    if scene.dialogue_open:scene._close_dialogue()
    scene.choice_card.hide();scene.lesson_card.show();scene.premium_hud.show();scene.dialogue_shade.hide();scene.state="playing";scene.lesson=6
    scene.player=Vector2(5500,580);scene.player_velocity=Vector2.ZERO;scene.camera=4900;scene.time=12
    scene.message_time=0;scene.arrival_time=3;scene.arrival_intro_pending=false
    scene.king_world=Vector2(5150,490);scene.queen_world=Vector2(6100,530)
    scene.deep_routes.sync(true)
    for i in range(5):scene.character_dt=1.0/60;scene._sync_native_visuals()
    scene.treasure_gallery.sync(true,0);scene._show_lesson();scene._refresh_lesson_hint()
    scene.ocean_feedback.clear();scene.premium_hud.clear_feedback();scene.queue_redraw()
func run() -> void:
    check(not output.is_empty(),"PEARL_QA_DIR required")
    if output.is_empty():quit(1);return
    DirAccess.make_dir_recursive_absolute(output)
    root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(1280,720)
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true;prefs.economy=false;prefs.reduced_motion=false
    root.get_node("AdventureRun").persist_enabled=false;root.get_node("AdventureRun").active=false
    root.get_node("OceanAudio").playback_enabled=false
    var scene=load("res://godot/training_lagoon.tscn").instantiate();root.add_child(scene)
    for i in range(6):await frame()
    scene.music_player.stop();scene.music_player.stream=null
    scene.set_process(false);scene.set_physics_process(false);scene.native_rig.set_process(false)
    scene.king.set_process(false);scene.queen_teacher.set_process(false);scene.premium_hud.set_process(false)
    Engine.time_scale=0
    if OS.get_environment("PEARL_QA_TOUCH_ONLY")=="1":
        await touch_states(scene)
        finish(scene)
        return
    for pixels in [Vector2i(1280,720),Vector2i(844,390)]:
        root.size=pixels
        for i in range(5):await frame()
        scene.simulated_touch=pixels.x<1000;scene._on_viewport_resized();scene._layout_tutorial();stage(scene)
        var tag:="%dx%d"%[pixels.x,pixels.y]
        var hud=scene.premium_hud
        hud.update_hud(scene._hud_snapshot());check(scene.lesson_card.visible,"lesson cue visible outside reading");await snap(scene,tag+"-lesson")
        var ids: Array=Lines.NODES.keys() if OS.get_environment("PEARL_QA_QUICK")!="1" else ["intro","gifts","bubble"]
        for id in ids:
            scene._open_dialogue(id)
            await snap(scene,tag+"-speech-"+id)
            if id in ["intro","gifts","bubble"]:
                while scene.speech_index+1<scene.speech_beats.size():scene._advance_speech()
                scene._toggle_replies();await snap(scene,tag+"-replies-"+id)
                # Scroll to the last reply to prove the final option is accessible.
                scene.reply_box.get_child(2).grab_focus();scene.dialogue_scroll.ensure_control_visible(scene.reply_box.get_child(2))
                await snap(scene,tag+"-last-reply-"+id)
            scene._close_dialogue()
        stage(scene)
        scene.lesson_card.hide()
        var info: Dictionary=scene._hud_snapshot();info["tutorial"]=false;info["touch"]=scene.simulated_touch;info["bubble"]=true
        info["health"]=2;info["energy"]=.23;info["score"]=1234567890;info["pearls"]=24
        hud.update_hud(info);hud._process(100);await snap(scene,tag+"-health-low")
        info["health"]=5;info["energy"]=.92
        info["powerups"]=[{"id":"royal_boost","label":"Royal boost","remaining":5.5,"duration":8.0}]
        hud.update_hud(info);await snap(scene,tag+"-healed-powerup")
        info["powerups"]=[]
        for tier in [1,2,3]:
            info["charge_tier"]=tier;info["charge_progress"]=float(tier)/3
            hud.update_hud(info);await snap(scene,tag+"-charge-"+str(tier))
        info["charge_tier"]=0;info["cooldowns"]={"bubble":.17};info["bubble_recovery"]=.2
        hud.update_hud(info);await snap(scene,tag+"-cooldown")
        info["cooldowns"]={};hud.update_hud(info)
        hud.show_reward({"category":"Secrets","points":50,"extra":0,"multiplier":1},scene.player-Vector2(scene.camera,0))
        await snap(scene,tag+"-reward")
        hud.clear_feedback()
        info["paused"]=true
        hud.update_hud(info);await snap(scene,tag+"-pause")
        info["paused"]=false;info["victory"]=true;info["results"]={"total":12340,"best":12000,"new_record":true,"stars":3,"breakdown":{"Pearls":1200,"Discoveries":500,"Friends":400},"reward":"A wonderful adventure!"}
        hud.update_hud(info);hud._process(5);await snap(scene,tag+"-results")
        hud.update_hud(scene._hud_snapshot());stage(scene)
        scene.state="victory";scene.choice_made=false;scene._show_choice();await snap(scene,tag+"-companion-choice")
        scene.choice_card.hide();scene.dialogue_shade.hide();scene.state="playing";scene.premium_hud.show();paused=false
    finish(scene)
func touch_states(scene) -> void:
    root.size=Vector2i(844,390)
    for i in range(5):await frame()
    scene.simulated_touch=true;scene._on_viewport_resized();scene._layout_tutorial();stage(scene);scene.lesson_card.hide()
    var hud=scene.premium_hud
    var info: Dictionary=scene._hud_snapshot();info["tutorial"]=false;info["touch"]=true;info["bubble"]=true
    for tier in [1,2,3]:
        info["charge_tier"]=tier;info["charge_progress"]=float(tier)/3
        hud.update_hud(info);await snap(scene,"844x390-charge-"+str(tier))
    info["charge_tier"]=0;info["cooldowns"]={"bubble":.17};info["bubble_recovery"]=.2
    hud.update_hud(info);await snap(scene,"844x390-cooldown")
    info["cooldowns"]={};hud.update_hud(info)
    hud.show_reward({"category":"Secrets","points":50,"extra":0,"multiplier":1},scene.player-Vector2(scene.camera,0))
    await snap(scene,"844x390-reward")
    hud.clear_feedback()
    scene.gift_time=5.5
    info["powerups"]=scene._hud_snapshot().get("powerups",[])
    hud.update_hud(info);await snap(scene,"844x390-healed-powerup")
    info["powerups"]=[];info["paused"]=true
    hud.update_hud(info);await snap(scene,"844x390-pause")
    info["paused"]=false;info["victory"]=true;info["score"]=12340
    info["results"]={"total":12340,"best":12000,"new_record":true,"stars":3,"breakdown":{"Pearls":1200,"Discoveries":500,"Friends":400},"reward":"A wonderful adventure!"}
    hud.update_hud(info);hud._process(5);await snap(scene,"844x390-results")
func finish(scene) -> void:
    var file:=FileAccess.open(output+"/capture-report.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"failures":failures,"engine":Engine.get_version_info()["string"],"renderer":RenderingServer.get_video_adapter_name(),"records":records},"  "));file.close()
    scene.free();paused=false;Engine.time_scale=1
    print("PEARL NATIVE CAPTURE: ",records.size()," views, ",failures," geometry failures; inspect PNGs visually")
    quit(1 if failures else 0)

extends "res://godot/pocket_wonders_test.gd"
## User-visible contracts: safe layout, single dialogue owner, active timers and input parity.
const Lines=preload("res://godot/family_dialogue.gd")
func run() -> void:
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false
    root.get_node("AdventureRun").persist_enabled=false;root.get_node("AdventureRun").active=false
    var scene=await create(7,false)
    var hud=scene.premium_hud
    scene.bubble_unlocked=true
    for pixels in [Vector2(1280,720),Vector2(844,390)]:
        var viewport: Vector2=pixels/minf(pixels.x/1400.0,pixels.y/960.0)
        hud.configure_layout(viewport,pixels);scene.simulated_touch=pixels.x<1000;scene._layout_tutorial()
        check(not hud.portrait,"landscape composition available")
        var canvas:=Rect2(Vector2.ZERO,hud.game_size)
        for id in Lines.NODES:
            scene._open_dialogue(id);await frames(4);scene._layout_dialogue();await frames(2)
            check(scene.dialogue_open and paused,"speech pauses hazards: "+id)
            check(not hud.visible and not scene.lesson_card.visible,"single conversation owner: "+id)
            check(canvas.grow(1).encloses(scene.dialogue_card.get_global_rect()),"dialogue stays in safe canvas: "+id)
            check(scene.dialogue_card.get_global_rect().grow(1).encloses(scene.dialogue_practice.get_global_rect()),"primary action stays reachable: "+id)
            while scene.speech_index+1<scene.speech_beats.size():scene._advance_speech()
            scene._toggle_replies();await frames(4);scene._layout_dialogue();await frames(2)
            check(scene.reply_box.visible and scene.reply_box.get_child_count()==3,"three replies retained: "+id)
            for button in scene.reply_box.get_children():
                check(not button.text.is_empty() and button.focus_mode!=Control.FOCUS_NONE,"reply has readable text and keyboard focus")
            scene._close_dialogue();check(not paused and hud.visible,"reading returns to play")
        var info: Dictionary=scene._hud_snapshot();info["tutorial"]=false;info["touch"]=scene.simulated_touch;info["bubble"]=true
        info["health"]=1;info["energy"]=.22;hud.update_hud(info)
        check(hud.health_card.visible and is_equal_approx(hud.energy_meter.value,.22),"health and boost energy remain truthful")
        check(hud.hearts[0].texture!=hud.hearts[4].texture,"empty health is visually distinguishable")
        for action in ["boost","jump","bubble"]:
            var rect: Rect2=hud.action_rect(action)
            check(canvas.encloses(rect),"touch target inside canvas")
            check(scene._touch_target(hud.to_game(rect).get_center())==action,"touch art/input agree for "+action)
        for tier in [1,2,3]:
            info["charge_tier"]=tier;info["charge_progress"]=float(tier)/3.0
            hud.update_hud(info)
            check(not hud.bubble_button_label().is_empty(),"bubble tier has a meaningful state label")
            check(hud.charge_card.visible!=bool(info["touch"]),"charge appears once in desktop card or touch control")
        info["charge_tier"]=0;info["cooldowns"]={"bubble":.1};info["bubble_recovery"]=.2;hud.update_hud(info)
        check(is_equal_approx(hud.bubble_cooldown_fraction(),.5),"cooldown uses actual recovery duration")
        check(hud.bubble_button_label().to_lower().contains("cool"),"recovery state distinguishable from holding")
        info["paused"]=true;hud.update_hud(info)
        check(hud.modal.visible and not hud.touch_layer.visible,"pause owns interaction")
        var pixel_ratio: Vector2=pixels/viewport
        await frames(3)
        for action in ["resume","restart","menu"]:
            var rect: Rect2=hud.to_game(hud.action_rect(action))
            check(rect.size.x*pixel_ratio.x>=43.9 and rect.size.y*pixel_ratio.y>=43.9,"actual paused target at least44physicalpx")
            check(hud.safe_frame.grow(.1).encloses(rect),"actual paused target stays inside safe area")
        info["paused"]=false;info["victory"]=true;info["score"]=12340
        info["results"]={"total":12340,"best":12000,"stars":3,"breakdown":{"Pearls":1200,"Friends":500},"reward":"A wonderful adventure!"}
        hud.update_hud(info);hud._process(5);await frames(4)
        for action in ["restart","menu"]:
            var rect: Rect2=hud.to_game(hud.action_rect(action))
            check(rect.size.x*pixel_ratio.x>=43.9 and rect.size.y*pixel_ratio.y>=43.9,"actual results target at least44physicalpx")
            check(hud.safe_frame.grow(.1).encloses(rect),"actual results target stays inside safe area")
        info["victory"]=false

        info["paused"]=false;info["cooldowns"]={};hud.update_hud(info)
        var count: int=hud.touch_redraws;hud.update_hud(info)
        check(hud.touch_redraws==count,"identical state does not rebuild touch visuals")
        scene._release_tutorial_input()
    # Power-up UI follows the tutorial's real eight-second royal gift.
    scene.lesson=6;scene.gift_time=6.25;scene.gold_gift=true
    var live: Dictionary=scene._hud_snapshot()
    check(live.has("powerups") and live["powerups"].size()==1,"active gift supplies exactly one real power-up")
    if live.has("powerups") and live["powerups"].size()==1:
        var power: Dictionary=live["powerups"][0]
        check(power.get("id","")=="royal_boost" and is_equal_approx(float(power.get("remaining",0)),6.25),"badge reports the real gift timer")
        check(is_equal_approx(float(power.get("duration",0)),8.0),"ring uses the real gift duration")
        hud.update_hud(live)
        check(hud.powerup_row.visible and hud.powerup_badges.has("royal_boost"),"active gift has a visible badge")
        var badge=hud.powerup_badges.get("royal_boost")
        if badge!=null:check(is_equal_approx(float(badge.fraction),6.25/8.0),"ring reflects remaining fraction")
    paused=true;scene._process(.25)
    check(is_equal_approx(scene.gift_time,6.25),"reading/pause freezes real power-up duration")
    paused=false;scene._process(.25)
    check(is_equal_approx(scene.gift_time,6.0),"active play advances real power-up duration")
    scene.gift_time=0;hud.update_hud(scene._hud_snapshot())
    check(not hud.powerup_row.visible,"expired effect leaves no stale badge")
    var pooled_nodes: int=hud.canvas.get_child_count()
    hud.show_reward({"category":"Secrets","points":50,"extra":0,"multiplier":1},Vector2(600,400))
    check(hud.banner.visible,"small discoveries receive a brief celebration")
    check(hud.reward_charm.texture==preload("res://godot/pearl_storybook.gd").texture("slug"),"discovery toast uses the selected slug charm")
    hud._process(2.0)
    check(not hud.banner.visible,"celebration settles instead of repeating indefinitely")
    for label in hud.floating:check(not label.visible,"expired reward label leaves play clear")
    check(hud.canvas.get_child_count()==pooled_nodes,"rewards reuse existing presentation nodes")
    hud.configure_layout(Vector2(1400,960),Vector2(1400,960));scene._layout_tutorial()
    await dispose(scene)
    print("PEARL UI CONTRACT: ",checks," checks, ",failures," failures")
    quit(1 if failures else 0)

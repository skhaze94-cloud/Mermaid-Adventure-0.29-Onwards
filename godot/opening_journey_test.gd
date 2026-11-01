extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, note: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error("OPENING JOURNEY: "+note)
func frames(count := 6) -> void:
    for i in range(count): await process_frame
func run() -> void:
    root.get_node("AppPreferences").persist_enabled=false
    root.get_node("AppPreferences").intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false
    var run_state=root.get_node("AdventureRun")
    run_state.begin(7)
    change_scene_to_file(run_state.SCENES[7]); await frames()
    var level=current_scene
    level.set_process(false); level.set_physics_process(false)
    check(level.heading.text==level.TITLES[0],"first lesson has a clear title without another progress counter")
    level.explore_time=2.1; level._refresh_lesson_hint()
    check(level.hint.text.contains("Find your fins"),"opening teaches movement without a countdown")
    level.lesson=3; level.energy=.2; level._refresh_lesson_hint()
    check(level.hint.text.contains("refill"),"unsuccessful boost has an energy recovery explanation")
    level.lesson=5; level.player=Vector2(4750,550); level.energy=1
    level.leap_cooldown=0; level._jump()
    level.player=Vector2(4755,600); level.leap_phase=""; level.jump_time=0
    level._update_swimming(0); level._refresh_lesson_hint()
    check(level.lesson==5 and level.reef_retry and level.hint.text.to_lower().contains("left"),"failed reef landing explains where to retry without penalising player")
    level.player=Vector2(4750,550); level.leap_cooldown=0; level.energy=1; level._jump()
    level.player=Vector2(5010,600); level.leap_phase=""; level.jump_time=0; level._update_swimming(0)
    check(level.lesson==6 and not level.reef_retry,"successful second reef jump progresses normally")
    level._close_dialogue()
    level.heart_gift=true; level.gold_gift=false; level._refresh_lesson_hint()
    check(level.hint.text.contains("gold gift"),"gift guidance responds to the collected heart")
    level._advance_lesson(7); level._refresh_lesson_hint()
    check(level.hint.text.contains("0 / 3"),"volunteer practice counts remaining live targets")
    level.enemies[0].hp=0; level._refresh_lesson_hint()
    check(level.hint.text.contains("1 / 3"),"volunteer boop feedback follows actual target health")
    level.lesson=8; level.boss_clock=8.5; level.boss_hit_cooldown=0; level.energy=1; level._refresh_lesson_hint()
    check(level.hint.text.to_lower().contains("mint petals open"),"trial explicitly teaches the real hit opening")
    level.boss_hit_cooldown=.4; level._refresh_lesson_hint()
    check(level.hint.text.contains("Daddy resets"),"hit recovery never invites another blocked attack")
    level.touches[4]="pad"; level.touch_vectors[4]=Vector2.RIGHT
    level.player_velocity=Vector2(200,0); level.boost_time=.2
    level._open_dialogue("trial")
    check(level.touches.is_empty() and level.touch_vectors.is_empty(),"conversation clears active touch movement")
    check(level.boost_time==.2 and level.player_velocity==Vector2(200,0),"conversation preserves the authored boost so the first zoom can resume")
    while level.speech_index+1<level.speech_beats.size():level._advance_speech()
    level._toggle_replies()
    check(level.reply_box.get_child_count()==3,"all family branches remain optional")
    check(level.dialogue_practice.text=="Let’s swim ›","one primary action returns to practice")
    root.content_scale_size=Vector2i(1400,960)
    root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
    for pixels in [Vector2i(844,390),Vector2i(1400,960)]:
        root.size=pixels; await frames()
        level._layout_tutorial(); await frames()
        var safe := Rect2(Vector2.ZERO,level._ui_view())
        check(level.dialogue_practice.is_visible_in_tree() and safe.encloses(level.dialogue_practice.get_global_rect()),str(pixels)+" direct practice action is visible inside the viewport")
        var physical_scale: float=float(pixels.y)/level.get_viewport_rect().size.y*level.tutorial_layer.transform.get_scale().y
        check(level.dialogue_practice.size.y*physical_scale>=44,str(pixels)+" direct practice action has a comfortable touch target")
        level.dialogue_scroll.scroll_vertical=9999; await frames()
        check(safe.encloses(level.dialogue_practice.get_global_rect()),str(pixels)+" practice action remains visible when replies are scrolled")
    var released:=InputEventScreenTouch.new(); released.index=4; released.pressed=false
    level._input(released)
    while level.dialogue_open:level.dialogue_practice.pressed.emit()
    check(not paused and not level.dialogue_open and level.touch_vectors.is_empty(),"release inside conversation cannot leave a sticky movement vector")
    level.lesson=10; level.boss_hp=0; level.bubble_unlocked=true
    level._show_lesson()
    check(level._lesson_conversation()=="bubble" and level.Dialogue.NODES["bubble"][3][0][2].contains("same depth") and level.hint.text.contains("Optional"),"first bubble teaches real charge threshold and horizontal aim without an exit gate")
    level.fire_cooldown=0
    check(level.opal.begin("script"),"live bubble charge can begin in optional practice")
    level.opal.charge.advance(1.34); level._refresh_lesson_hint()
    check(level.hint.text.contains("Keep holding"),"early release is not presented as a ready super")
    level.opal.charge.advance(.01); level._refresh_lesson_hint()
    check(level.hint.text.to_lower().contains("release!"),"exact super threshold gives an explicit release cue")
    level._open_dialogue("hide")
    check(not level.opal.charge.held,"opening a family conversation cancels a held bubble")
    level._close_dialogue()
    check(level.bubble_shots.is_empty(),"conversation never fires a cancelled charge")
    level._opal_hit_switch(0,{"owner":"sarah","tier":2})
    check(not level.practice_switch["on"],"ordinary charge does not claim super mastery")
    level._opal_hit_switch(0,{"owner":"sarah","tier":3})
    check(level.practice_switch["on"] and level.hint.text.contains("mastered"),"actual super target hit receives mastery guidance")
    level.practice_switch["on"]=false
    level.player=Vector2(level._portal_x()+1,550); level._update_swimming(0)
    check(level.state=="victory" and level.choice_card.visible,"super practice remains optional when leaving the lagoon")
    level.alone_button.pressed.emit()
    check(level.dialogue_practice.visible and not level.reply_toggle.visible,"farewell uses the same primary action without unrelated replies")
    paused=false; level.free(); await frames()
    print("OPENING JOURNEY: ",checks," checks, ",failures," failures")
    quit(1 if failures else 0)

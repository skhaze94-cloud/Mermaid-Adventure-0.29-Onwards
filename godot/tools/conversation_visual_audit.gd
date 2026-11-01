extends "res://godot/tools/opal_visual_audit.gd"
var layout_checks:=0
func finish_primary(scene) -> void:
    for i in range(24):
        if scene.speech_index+1>=scene.speech_beats.size():return
        assert(scene.dialogue_open,"conversation closed unexpectedly: "+scene.dialogue_id+" state "+scene.state)
        scene._advance_speech()
    assert(false,"conversation has more than 24 beats")
func shot(scene,name: String) -> void:
    await snap(scene,name)
    if not scene.has_method("_ui_view"):return
    var view: Rect2=Rect2(Vector2.ZERO,scene._ui_view())
    if scene.dialogue_open:
        var physical: float=float(root.size.y)/scene.get_viewport_rect().size.y*scene.tutorial_layer.transform.get_scale().y
        assert(scene.dialogue_practice.size.y*physical>=44,"dialogue primary action is comfortable to tap")
    if scene.dialogue_open:
        assert(view.encloses(Rect2(scene.dialogue_card.position,scene.dialogue_card.size)),"dialogue stays in safe area")
        assert(scene.dialogue_practice.get_global_rect().end.y<=scene.get_viewport_rect().size.y+2,"primary action stays on screen")
        if scene.reply_box.visible:
            for reply in scene.reply_box.get_children():
                assert(scene.dialogue_scroll.get_global_rect().grow(1).encloses(reply.get_global_rect()),"every reply is visible without scrolling")
    if scene.lesson_card.visible:
        assert(view.encloses(Rect2(scene.lesson_card.position,scene.lesson_card.size)),"lesson cue stays on screen")
    layout_checks+=1
func size_for(scene,pixels: Vector2i) -> void:
    root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=pixels
    for i in range(4):await process_frame
    scene._on_viewport_resized()
    if scene.has_method("_layout_tutorial"):scene._layout_tutorial()
func run() -> void:
    Engine.time_scale=0
    root.get_node("AppPreferences").persist_enabled=false;root.get_node("AppPreferences").intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false
    root.get_node("AdventureRun").active=false
    var scene=setup("res://godot/training_lagoon.tscn")
    scene.reduced_fx=true;scene.lesson=1;scene.simulated_touch=true;scene.player=Vector2(1050,540);scene.camera=500;scene.king_world=Vector2(1370,430);scene.boss_hp=3
    await size_for(scene,Vector2i(844,390));scene._show_lesson();await shot(scene,"phone-lesson")
    for id in scene.Dialogue.NODES:
        scene._open_dialogue(id);await shot(scene,"phone-"+id)
        while scene.speech_index+1<scene.speech_beats.size():scene._advance_speech()
        scene._toggle_replies();await shot(scene,"phone-"+id+"-replies")
        scene._close_dialogue()
    # Exercise every actual reply button, including its speaker/portrait change.
    for id in scene.Dialogue.NODES:
        for answer in range(3):
            scene._open_dialogue(id)
            finish_primary(scene)
            scene._toggle_replies()
            scene.reply_box.get_child(answer).pressed.emit()
            await shot(scene,"phone-"+id+"-response-"+str(answer))
            scene._close_dialogue()
    for dimensions in [Vector2i(640,360),Vector2i(1024,768)]:
        await size_for(scene,dimensions)
        scene._open_dialogue("bubble");await shot(scene,"size-"+str(dimensions.x)+"-bubble")
        while scene.speech_index+1<scene.speech_beats.size():scene._advance_speech()
        scene._toggle_replies();await shot(scene,"size-"+str(dimensions.x)+"-replies")
        scene._close_dialogue()
    await size_for(scene,Vector2i(844,390))
    scene.lesson=8;scene.player=Vector2(6530,620);scene.camera=6100;scene.boss_clock=8.7;scene.boss_hit_cooldown=0;scene._update_boss(0);scene._show_lesson();await shot(scene,"phone-daddy-trial")
    scene.state="victory";scene.lesson=10;scene.boss_hp=0;scene._show_choice();await shot(scene,"phone-companion")
    scene._choose_companion(true);await shot(scene,"phone-farewell")
    scene.dialogue_done=Callable();scene._close_dialogue();scene.state="playing";scene.choice_made=false
    await size_for(scene,Vector2i(1280,720));scene.simulated_touch=false;scene.lesson=6;scene._show_lesson();scene._open_dialogue("gifts");await shot(scene,"desktop-gifts")
    while scene.speech_index+1<scene.speech_beats.size():scene._advance_speech()
    scene._toggle_replies();await shot(scene,"desktop-replies")
    scene._close_dialogue();await retire(scene)
    scene=setup("res://godot/highland_level.tscn");scene.reduced_fx=true;scene.player=Vector2(1500,600);scene.camera=950;scene.boss_hp=3;scene.simulated_touch=true
    await size_for(scene,Vector2i(844,390));scene._say("The reef saved a little wonder for you, Sarah. Take your time and have a look.",4);await shot(scene,"phone-adventure")
    scene.player=Vector2(scene._boss_home()-450,610);scene.camera=scene._boss_home()-950;scene.boss_phase="recover";scene.boss_phase_time=.2;scene._say("Mint petals · your opening!",2,true);await shot(scene,"phone-boss")
    await retire(scene)
    print("CONVERSATION VISUAL COMPLETE ",layout_checks," views");quit()

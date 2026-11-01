extends "res://godot/pocket_wonders_test.gd"
const Lines=preload("res://godot/family_dialogue.gd")
func run() -> void:
    root.get_node("AppPreferences").persist_enabled=false;root.get_node("AppPreferences").intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false
    var scene=await create(7,false)
    scene.lesson_card.show()
    var options:=0
    for id in Lines.NODES:
        for index in range(3):
            scene._open_dialogue(id)
            check(paused and scene.dialogue_open and not scene.premium_hud.visible,"one conversation owns focus: "+id)
            check(scene.dialogue_practice.visible and not scene.reply_box.visible,"one primary action; replies start tucked away")
            var at: Vector2=scene.player
            scene.touches[8]="boost";scene.touch_vectors[8]=Vector2.RIGHT
            scene._physics_process(.1)
            check(scene.player==at,"reading freezes player and hazards")
            while scene.speech_index+1<scene.speech_beats.size():scene._advance_speech()
            scene._toggle_replies();await frames()
            check(scene.reply_box.get_child_count()==3 and scene.reply_box.visible,"all replies remain reachable")
            var item: Array=Lines.NODES[id][3][index]
            scene.reply_box.get_child(index).pressed.emit()
            check(not scene.reply_toggle.visible and scene.speech_beats.size()>0,"answer becomes a readable response")
            check((scene.king_tone if Lines.NODES[id][0]=="king" else scene.queen_tone)==item[1],"reply tone retained")
            while scene.dialogue_open:scene._advance_speech()
            check(not paused and not scene.dialogue_shade.visible and scene.premium_hud.visible,"resume restores world and HUD")
            check(scene.touches.is_empty() and scene.touch_vectors.is_empty(),"reading releases held touch actions")
            options+=1
    scene.lesson=7;check(scene._lesson_conversation()=="practice","volunteer help describes volunteers, not the final trial")
    scene.lesson=10;scene.bubble_unlocked=true
    var info: Dictionary=scene._hud_snapshot();scene.premium_hud.update_hud(info)
    check(not scene.premium_hud.score_card.visible and not scene.premium_hud.chapter.visible,"tutorial has no competing score or chapter header")
    scene._open_dialogue("intro");scene._toggle_replies()
    var event:=InputEventKey.new();event.keycode=KEY_ESCAPE;event.pressed=true
    scene._input(event);check(scene.dialogue_open and not scene.reply_box.visible,"Back first closes optional replies")
    scene._input(event);check(not scene.dialogue_open and not paused,"Back resumes a lesson")
    scene.lesson=0;scene._open_dialogue("intro");scene.switch_button.pressed.emit()
    check(scene.playing_daddy and not scene.dialogue_open,"optional Daddy costume resumes play immediately")
    await dispose(scene)
    print("CONVERSATION FLOW: ",checks," checks, ",failures," failures; ",options," reply branches")
    quit(1 if failures else 0)

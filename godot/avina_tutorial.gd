extends "res://godot/basic_chapter.gd"
const Dialogue = preload("res://godot/family_dialogue.gd")
const Royal = preload("res://godot/family_royal_actor.gd")
const RINGS: Array[Vector2] = [Vector2(1100,430),Vector2(1900,650),Vector2(2850,420)]
const HIDES: Array[Vector2] = [Vector2(7100,756),Vector2(7240,735),Vector2(7360,760)]
const TITLES := ["Explore the family lagoon","Three glowing swim rings","Through the elite reef","Very dignified zoomies","Your first sky jump","Over the tall reef","Antonella’s royal gifts","Three volunteer boops","King Daddy’s final trial","A tiny game of peekaboo","Avina’s very first bubble"]
const HINTS := ["Swim freely • arrows / WASD / stick / touch pad","Swim into each glowing ring · 0 / 3","Swim beyond the reef · relic chests are optional","Aim and Boost • Space / controller B / Boost button","Jump and land • J or Shift / controller A / Jump","Jump before the tall reef · steer right · land beyond it","Collect heart + gold · jump with the power · land","Boost boop Professor Puff, Sir Wobble and Noodle","Dodge slow spells · wait for GREEN · Boost into Daddy","Look for a little bow behind the sparkling coral","B or Z / controller X / Bubble · hold, then release for a super pearl"]
var lesson := 0
var ring_count := 0
var explore_time := 0.0
var landing_started := false
var jump_origin := 0.0
var heart_gift := false
var gold_gift := false
var gift_time := 0.0
var powered_jump := false
var hide_round := 0
var reveal_time := 0.0
var choice_made := false
var chosen_along := false
var king_tone := "earnest"
var queen_tone := "earnest"
var dialogue_open := false
var dialogue_id := ""
var dialogue_done: Callable
var king: Node2D
var queen_teacher: Node2D
var royal_player: Node2D
var playing_daddy := false
var arrival_time := 0.0
var character_dt := 1.0/60.0
var king_world := Vector2(680,-160)
var king_mode := "idle"
var queen_mode := "idle"
var queen_demo := 0.0
var move_name := ""
var cloud := Vector2.ZERO
var wave := Vector2.ZERO
var cloud_active := false
var wave_active := false
var beard_fired := false
var trial_phase := -1
var tutorial_layer: CanvasLayer
var lesson_card: PanelContainer
var heading: Label
var dialogue: Label
var hint: Label
var choice_card: PanelContainer
var bring_button: Button
var alone_button: Button
var switch_button: Button
var talk_king: Button
var talk_queen: Button
var dialogue_card: PanelContainer
var speaker_label: Label
var dialogue_scroll: ScrollContainer
var dialogue_content: VBoxContainer
var dialogue_text: Label
var portrait: TextureRect
var reply_box: VBoxContainer
var hide_cover: Node2D

func _ready() -> void:
    super._ready()
    bubble_unlocked = false
    performance.hide()
    king = Royal.new(); add_child(king); king.configure("king",310)
    queen_teacher = Royal.new(); add_child(queen_teacher); queen_teacher.configure("queen",300)
    royal_player = Royal.new(); add_child(royal_player); royal_player.configure("king",230); royal_player.hide()
    hide_cover = Node2D.new(); hide_cover.z_index=5; add_child(hide_cover)
    hide_cover.draw.connect(_draw_hide_cover)
    _build_tutorial_ui()
    _show_lesson()
    _save_checkpoint()

func _level_length() -> float: return 7600.0
func _boss_home() -> float: return 6900.0
func _portal_is_open() -> bool: return boss_hp<=0 and lesson>=10
func _portal_hint() -> String: return "CONTINUE" if _portal_is_open() else ("FIND AVINA" if lesson==9 else "FINISH TRAINING")
func _boss_max_health() -> int: return 3
func _stage_enemies() -> Array[Dictionary]: return []
func _stage_obstacles() -> Array[Rect2]: return Chapter.obstacles_for("training")
func _stage_treasure() -> Array[Dictionary]:
    var result := Chapter.treasure_for("training")
    for i in range(26):
        var point := RockCollision.recover(Vector2(480+i*250,570+sin(i*.7)*70),_stage_obstacles(),55,Rect2(50,355,7460,470))
        result.append({"x":point.x,"y":point.y,"kind":"pearl","taken":false,"phase":float(i)})
    return result
func _intro_line() -> String: return "The Family’s Enchanted Lagoon · Lord of Thunder & Bedtime"
func _boss_name() -> String: return "KING DADDY · THUNDER & BEDTIME"
func _check_checkpoints() -> void: pass
func _boss_vulnerable() -> bool: return lesson==8 and boss_hp>0 and fmod(boss_clock,12)>=8.2

func _process(dt: float) -> void:
    if state!="playing" or get_tree().paused:
        opal.cancel()
        return
    character_dt = dt
    super._process(dt)
    if lesson==0 and player_velocity.length()>45:
        explore_time += dt
        if explore_time>4: _advance_lesson(1,"intro")
    if lesson>=1: arrival_time = minf(2.6,arrival_time+dt)
    queen_demo=maxf(0,queen_demo-dt)
    gift_time = maxf(0,gift_time-dt)
    if gift_time>0: energy=1.0
    if lesson==6 and gold_gift and gift_time<=0 and not powered_jump:
        gold_gift=false
        for item in treasures:
            if item.get("gift","")=="gold": item.taken=false
    if reveal_time>0:
        reveal_time=maxf(0,reveal_time-dt)
        if reveal_time<=0 and hide_round<3: _place_hidden_baby()
    if is_instance_valid(hide_cover): hide_cover.queue_redraw()

func _physics_process(dt: float) -> void:
    if dialogue_open or (is_instance_valid(choice_card) and choice_card.visible) or (get_tree().paused and state=="playing"): return
    super._physics_process(dt)

func _update_swimming(dt: float) -> void:
    var gates := [1500.0,3200.0,3870.0,4170.0,4660.0,5270.0,6040.0,6570.0,7090.0,7370.0,7600.0]
    player.x=minf(player.x,gates[lesson]-35)
    super._update_swimming(dt)
    if lesson==1 and ring_count<3 and player.distance_to(RINGS[ring_count])<78:
        ring_count+=1
        native_fx.splash(RINGS[ring_count-1]-Vector2(camera,0),Color("ffe4a2"),12)
        if ring_count==3: _advance_lesson(2,"reef")
        else: _show_lesson()
    elif lesson==2 and player.x>3820: _advance_lesson(3,"boost")
    elif lesson in [4,5,6] and landing_started and leap_phase=="":
        if lesson==4: _advance_lesson(5,"air")
        elif lesson==5 and jump_origin<4800 and player.x>4895: _advance_lesson(6,"gifts")
        elif lesson==6 and powered_jump: _advance_lesson(7,"practice")
        landing_started=false
    elif lesson==9 and reveal_time<=0 and player.distance_to(HIDES[hide_round])<95:
        _find_baby()
    if state=="victory": _show_choice()

func _boost() -> void:
    var before := boost_time
    super._boost()
    if lesson==3 and boost_time>before: _advance_lesson(4,"jump")
func _begin_leap(chained: bool) -> void:
    jump_origin=player.x
    super._begin_leap(chained)
    landing_started=true
    if lesson==6 and heart_gift and gold_gift and gift_time>0:
        powered_jump=true; player_velocity.y=-1040
        native_fx.splash(_hero_screen_position(),Color("ffe39f"),25)
func _on_bubble_fired() -> void:
    if lesson==10:
        hint.text="A whole bubble squad! Swim into the glowing portal →"
        if is_instance_valid(avina):avina.say("Buh-buh!",3)

func _update_collectibles() -> void:
    super._update_collectibles()
    for item in treasures:
        if not item.taken: continue
        if item.get("gift","")=="heart": heart_gift=true
        if item.get("gift","")=="gold" and not gold_gift:
            gold_gift=true; gift_time=8
    if lesson==6 and heart_gift and gold_gift:
        hint.text="Royal power ready! Jump, steer, and land · gold refills if needed"

func _damage(from_pos: Vector2) -> void:
    if state!="playing" or invulnerable>0: return
    health=maxi(3,health-1)
    invulnerable=1.2
    player_velocity.x=80 if player.x>from_pos.x else -80
    _say("Daddy: You’re safe. Every mistake is practice.",2)

func _advance_lesson(next: int, conversation := "") -> void:
    lesson=next
    landing_started=false
    if lesson==6:
        health=mini(health,4)
        treasures.append({"x":5660.0,"y":490.0,"kind":"heart","taken":false,"phase":0.0,"gift":"heart"})
        treasures.append({"x":5860.0,"y":435.0,"kind":"boost","taken":false,"phase":0.0,"gift":"gold"})
    if lesson==7:
        queen_demo=0
        playing_daddy=false
        enemies=[]
        for original in Chapter.source("training").training.practiceEnemies:
            enemies.append({"kind":original.kind,"name":original.name,"x":float(original.x),"y":float(original.y),"bx":float(original.x),"by":float(original.y),"hp":1,"phase":float(original.phase),"cooldown":4.0,"dir":-1,"variant":"","hit_cd":0.0})
        animated_enemies.bind_enemies(enemies)
    if lesson==8: boss_clock=0; playing_daddy=false
    _show_lesson()
    if conversation!="": _open_dialogue(conversation)

func _update_boss(dt: float) -> void:
    if lesson==7:
        if enemies.all(func(enemy): return int(enemy.hp)<=0): _advance_lesson(8,"trial")
        return
    if lesson!=8 or boss_hp<=0 or player.x<6050: return
    boss_clock+=dt
    var p := fmod(boss_clock,12)
    var segment := 0 if p<1.55 else (1 if p<2.5 else (2 if p<4.05 else (3 if p<5.5 else (4 if p<6.95 else (5 if p<8.2 else 6)))))
    if segment!=trial_phase:
        trial_phase=segment; shot_sequence=0
        if segment==0: boss_target=player; beard_fired=false
        if segment==2: cloud=boss_position+Vector2(-150,-100)
        if segment==3: wave=Vector2(boss_position.x-140,630)
    boss_position=Vector2(6900+sin(boss_clock*.8)*18,550+sin(boss_clock*.72)*24)
    cloud_active=segment==2; wave_active=segment==3
    boss_phase="recover" if segment==6 else ("windup" if segment==0 else "attack")
    move_name=["THUNDER TEAPOT · aim warning","TRIPLE TICKLE BOLT","THE CLOUD OF MILD CONCERN","ROYAL WOBBLE WAVE","DAD DASH","BUBBLE BEARD BLAST","GREEN GLOW · BOOST NOW"][segment]
    if segment==1:
        var volley := mini(3,1+int((p-1.55)/.28))
        if volley>shot_sequence:
            shot_sequence=volley
            _spawn_hostile(boss_position+Vector2(-55,-75),(boss_target-boss_position).normalized().rotated((volley-2)*.15),135)
    if cloud_active:
        cloud=cloud.move_toward(player,68*dt)
        if cloud.distance_to(player)<55: _damage(cloud)
    if wave_active:
        wave.x-=125*dt
        if absf(player.x-wave.x)<36 and absf(player.y-wave.y)<100: _damage(wave)
    if segment==4:
        var dash := sin(clampf((p-5.55)/1.4,0,1)*PI)
        boss_position-=Vector2(215,45)*dash
    if segment==5 and not beard_fired:
        beard_fired=true
        for i in range(5): _spawn_hostile(boss_position+Vector2(-30,-45),Vector2.LEFT.rotated((i-2)*.24),105,"king-beard")
    if player.distance_to(boss_position)<135 and boss_hit_cooldown<=0:
        if segment==6 and boost_time>0:
            boss_hp-=1; boss_hit_cooldown=1; boss_clock=0; trial_phase=-1
            invulnerable=1; energy=1; boost_time=0; player_velocity.x=-250
            hostile_shots.clear(); cloud_active=false; wave_active=false
            _award("training:dad:%s" % boss_hp,"Boss",200,boss_position,false)
            _say("Daddy: Magnificent! Also, rude to the beard.",2)
            if boss_hp<=0:
                _award("training:dad:clear","Boss",600,boss_position,false)
                bubble_unlocked=true
                _advance_lesson(9,"win")
                dialogue_done=_start_hide_seek
        elif segment!=6: _damage(boss_position)

func _sync_native_visuals() -> void:
    super._sync_native_visuals()
    if not is_instance_valid(king): return
    performance.hide()
    var target := Vector2(clampf(player.x+200,680,6640),430)
    if lesson>=8: target=boss_position if boss_hp>0 else Vector2(6770,515)
    king_world=boss_position if lesson==8 and boss_hp>0 else king_world.lerp(target,1.0-exp(-character_dt*3.08))
    var shown := king_world
    if lesson==1 and arrival_time<2.6:
        shown.y=lerpf(-160,target.y,smoothstep(0,1,arrival_time/2.6))
    king.position=shown-Vector2(camera,0)
    king.visible=lesson>=1 and not (playing_daddy and lesson<8)
    king_mode="dash" if lesson==8 and trial_phase==4 else ("cast" if lesson==8 and boss_phase=="attack" else ("celebrate" if boss_hp<=0 else "wave"))
    king.animate(time,king_mode,reduced_fx)
    queen_teacher.position=Vector2(5720,530)-Vector2(camera,0)
    if lesson>=9: queen_teacher.position=Vector2(7260,500)-Vector2(camera,0)
    queen_teacher.visible=lesson>=6
    queen_mode="cast" if lesson==6 else ("celebrate" if lesson>=9 else "wave")
    if queen_demo>0: queen_mode="cast"
    queen_teacher.animate(time,queen_mode,reduced_fx)
    royal_player.visible=playing_daddy
    native_rig.visible=not playing_daddy
    if playing_daddy:
        royal_player.position=_hero_screen_position()
        royal_player.scale.x=facing
        royal_player.animate(time,"dash" if boost_time>0 else ("swim" if player_velocity.length()>50 else "idle"),reduced_fx)
    if is_instance_valid(talk_queen): talk_queen.visible=lesson>=6
    if is_instance_valid(switch_button): switch_button.visible=lesson<7

func _draw_world(view: Vector2) -> void:
    super._draw_world(view)
    if lesson==1:
        for i in range(3):
            var point := RINGS[i]-Vector2(camera,0)
            draw_arc(point,56,0,TAU,64,Color("c7ffee") if i<ring_count else Color("ffe3a6"),5)
            if i==ring_count: draw_arc(point,64,0,TAU,64,Color(1,.9,.6,.3),2)
    if lesson==8:
        if boss_phase=="windup": draw_dashed_line(boss_position-Vector2(camera,0),boss_target-Vector2(camera,0),Color("bfe8ff"),2,12)
        _draw_text(boss_position-Vector2(camera,0)+Vector2(-175,-178),move_name,18)
    if queen_demo>0:
        var center := queen_teacher.position+Vector2(65,-45)
        var phase := int((10-queen_demo)/3.34)
        var elapsed := fmod(10-queen_demo,3.34)
        for i in range(7):
            var offset := Vector2.LEFT.rotated((i-3)*.18)*elapsed*65 if phase==0 else (Vector2(cos(i*TAU/7+time),sin(i*TAU/7+time))*55 if phase==1 else Vector2(-elapsed*90,sin(time*2+i)*22))
            draw_circle(center+offset,6,Color(.98,.86,1,.45))
            draw_arc(center+offset,6,0,TAU,20,Color("ffe4d4"),1)
        _draw_text(queen_teacher.position+Vector2(-100,175),["PEARL FAN · demonstration","CROWN HALO · demonstration","PEARL WAVE · demonstration"][mini(phase,2)],14)

func _paint_chapter_boss() -> void: pass
func _start_hide_seek() -> void:
    if not is_instance_valid(avina):
        avina=preload("res://godot/avina_companion.gd").new(); add_child(avina); avina.bind(self)
    avina.follow_enabled=false
    hide_round=0; reveal_time=0
    _place_hidden_baby()
    _open_dialogue("hide")
func _place_hidden_baby() -> void:
    avina.world_position=HIDES[hide_round]
    avina.modulate.a=1
    avina.say("Hee!",1.3)
    _show_lesson()
func _find_baby() -> void:
    avina.say(["Hee!","Hee hee!","Sa-sa!"][hide_round],2)
    _say("Sarah: Peek-a-boo! There’s my little pearl.",2)
    hide_round+=1
    native_fx.splash(avina.position,Color("ffd4ff"),12)
    reveal_time=1.8
    _award("avina:peekaboo:%s" % hide_round,"Secrets",75,avina.world_position,false)
    if hide_round==3:
        avina.follow_enabled=true; avina.request_bubble()
        _advance_lesson(10)
    else:
        avina.world_position.y-=75
        hint.text="Found her! She’s hiding again… %s / 3" % hide_round
func _draw_hide_cover() -> void:
    if lesson!=9: return
    for i in range(3):
        var point := Vector2(HIDES[i].x-camera,Terrain.ground_y(HIDES[i].x))
        Terrain.garden(hide_cover,point,i+9,"training",215)
        if i==hide_round and reveal_time<=0:
            var bow := HIDES[i]-Vector2(camera,0)+Vector2(20,-70)
            for j in range(3): hide_cover.draw_circle(bow+Vector2(sin(time*1.6+j)*12,-j*14),3,Color("efcaff"))

func _show_lesson() -> void:
    if not is_instance_valid(heading): return
    heading.text=TITLES[lesson]
    dialogue.text="King Daddy · Lord of Thunder & Bedtime" if lesson<6 else ("Queen Antonella · The Pearl Queen" if lesson<8 else "The family’s enchanted lagoon")
    hint.text=HINTS[lesson]
    if lesson==1: hint.text="Swim into the glowing rings · %s / 3" % ring_count
    if lesson==9: hint.text="Peekaboo · %s / 3 · swim close to the sparkling coral" % hide_round
    _say("",0)

func _build_tutorial_ui() -> void:
    tutorial_layer=CanvasLayer.new(); tutorial_layer.layer=15; tutorial_layer.process_mode=Node.PROCESS_MODE_ALWAYS; add_child(tutorial_layer)
    lesson_card=_card(); tutorial_layer.add_child(lesson_card)
    var box := VBoxContainer.new(); lesson_card.add_child(box)
    heading=_label("",23,Color("f7dfba")); box.add_child(heading)
    dialogue=_label("",17,Color("f3f8ff")); box.add_child(dialogue)
    hint=_label("",17,Color("a8e8e4")); box.add_child(hint)
    var row := HBoxContainer.new(); row.add_theme_constant_override("separation",10); box.add_child(row)
    switch_button=_button("Try King Daddy",_switch_hero); row.add_child(switch_button)
    talk_king=_button("Talk to Daddy",func(): _open_dialogue("trial" if lesson>=7 else ["intro","intro","reef","boost","jump","air","gifts"][lesson])); row.add_child(talk_king)
    talk_queen=_button("Talk to Mum",func(): _open_dialogue("hide" if lesson>=9 else "gifts")); row.add_child(talk_queen)
    choice_card=_card(); tutorial_layer.add_child(choice_card)
    var choices := VBoxContainer.new(); choices.add_theme_constant_override("separation",14); choice_card.add_child(choices)
    choices.add_child(_label("A little travelling companion?",29,Color("f7dfba")))
    choices.add_child(_label("Sarah: Want to come, little pearl?
Avina: Sa-sa! Buh-buh!

Avina follows safely and makes little bubbles.
Or she can stay with Mum and Daddy.",21,Color("f3f8ff")))
    bring_button=_button("Bring Avina  ♡",func(): _choose_companion(true)); choices.add_child(bring_button)
    alone_button=_button("Go alone · Avina stays with Mum and Daddy",func(): _choose_companion(false)); choices.add_child(alone_button)
    choice_card.hide()
    dialogue_card=_card(); tutorial_layer.add_child(dialogue_card)
    dialogue_scroll=ScrollContainer.new(); dialogue_scroll.follow_focus=true; dialogue_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; dialogue_card.add_child(dialogue_scroll)
    var speech := VBoxContainer.new(); dialogue_content=speech; speech.size_flags_horizontal=Control.SIZE_EXPAND_FILL; speech.add_theme_constant_override("separation",12); dialogue_scroll.add_child(speech)
    var top := HBoxContainer.new(); top.add_theme_constant_override("separation",18); speech.add_child(top)
    portrait=TextureRect.new(); portrait.custom_minimum_size=Vector2(90,90); portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; top.add_child(portrait)
    speaker_label=_label("",26,Color("f7dfba")); speaker_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; top.add_child(speaker_label)
    dialogue_text=_label("",21,Color("f3f8ff")); speech.add_child(dialogue_text)
    reply_box=VBoxContainer.new(); reply_box.add_theme_constant_override("separation",10); speech.add_child(reply_box)
    dialogue_card.hide()
    get_viewport().size_changed.connect(_layout_tutorial)
    _layout_tutorial.call_deferred()

func _switch_hero() -> void:
    if lesson>=7 or state!="playing" or dialogue_open: return
    playing_daddy=not playing_daddy
    switch_button.text="Swim as Sarah" if playing_daddy else "Try King Daddy"
    _sync_native_visuals()
func _open_dialogue(id: String) -> void:
    opal.cancel()
    if dialogue_open: return
    dialogue_id=id; dialogue_open=true; get_tree().paused=true
    lesson_card.hide(); premium_hud.hide(); dialogue_card.show()
    var node: Array = Dialogue.NODES[id]
    speaker_label.text=("King Daddy" if node[0]=="king" else "Queen Antonella")+"
"+node[1]
    dialogue_text.text=node[2]
    _set_portrait(node[0],0)
    _clear_replies()
    for option in node[3]:
        var item: Array=option
        _add_reply(item[0],func(): _dialogue_answer(node[0],item[1],item[2]))
    _focus_reply()
func _dialogue_answer(speaker: String, tone: String, response: String) -> void:
    if speaker=="king": king_tone=tone
    else:
        queen_tone=tone
        queen_demo=10.0
    _set_portrait(speaker,2 if tone=="cheeky" else 1)
    dialogue_text.text=response
    _clear_replies()
    _add_reply("One more tip?",func():
        dialogue_text.text=("Daddy: "+HINTS[lesson]+".
Antonella: Practise at your own pace, darling.")
        _clear_replies(); _add_reply("Let’s try it!",_close_dialogue); _focus_reply())
    _add_reply("Let’s try it!",_close_dialogue)
    _focus_reply()
func _clear_replies() -> void:
    for child in reply_box.get_children(): reply_box.remove_child(child); child.queue_free()
func _add_reply(text: String, callback: Callable) -> void: reply_box.add_child(_button(text,callback))
func _focus_reply() -> void:
    _layout_dialogue.call_deferred()
    if reply_box.get_child_count()>0: reply_box.get_child(0).grab_focus()
    _reset_dialogue_scroll()
func _reset_dialogue_scroll() -> void:
    await get_tree().process_frame
    if is_instance_valid(dialogue_scroll): dialogue_scroll.scroll_vertical=0
func _set_portrait(speaker: String, expression: int) -> void:
    var atlas := AtlasTexture.new()
    atlas.atlas=preload("res://godot/assets/family-v026/king-daddy-atlas.webp") if speaker=="king" else preload("res://godot/assets/family-v026/queen-antonella-atlas.webp")
    atlas.region=Rect2(768+(expression%2)*384,int(expression/2)*256,384,256)
    portrait.texture=atlas
func _layout_dialogue() -> void:
    var view := _ui_view()
    dialogue_card.size=Vector2(minf(740,view.x-48),clampf(dialogue_content.get_combined_minimum_size().y+36,220,minf(580,view.y-48)))
    dialogue_card.position=Vector2((view.x-dialogue_card.size.x)*.5,maxf(24,(view.y-dialogue_card.size.y)*.5))
func _close_dialogue() -> void:
    dialogue_open=false; dialogue_card.hide()
    get_tree().paused=false
    premium_hud.show(); lesson_card.show()
    if state=="victory": premium_hud.hide(); lesson_card.hide()
    if dialogue_done.is_valid():
        var done := dialogue_done; dialogue_done=Callable(); done.call()
func _show_choice() -> void:
    if choice_made or choice_card.visible or dialogue_open: return
    opal.cancel(); lesson_card.hide(); premium_hud.hide(); choice_card.show()
    _layout_tutorial.call_deferred(); bring_button.grab_focus()
    if is_instance_valid(avina): avina.say("Sa-sa?",100)
func _choose_companion(along: bool) -> void:
    if choice_made or state!="victory": return
    choice_made=true; chosen_along=along; choice_card.hide()
    dialogue_open=true; dialogue_card.show()
    var lines := Dialogue.farewell(along,king_tone,queen_tone)
    speaker_label.text="King Daddy · a royal send-off"; _set_portrait("king",7)
    dialogue_text.text=lines[0]
    _clear_replies()
    _add_reply("And Mum?",func():
        speaker_label.text="Queen Antonella · with love"; _set_portrait("queen",1)
        dialogue_text.text=lines[1]+("
Avina: Buh-buh!" if along else "
Avina: *sleepy little wave*")
        _clear_replies()
        _add_reply("Through the portal!",_finish_tutorial)
        _focus_reply())
    _focus_reply()
func _finish_tutorial() -> void:
    var run := get_node("/root/AdventureRun")
    run.tutorial_complete=true; run.avina_along=chosen_along
    dialogue_open=false; dialogue_card.hide(); get_tree().paused=false
    super._advance_journey()
func _advance_journey() -> bool:
    _show_choice(); return true
func _restart() -> void:
    if state=="victory": _show_choice(); return
    if dialogue_open: return
    lesson=0; ring_count=0; explore_time=0; arrival_time=0
    heart_gift=false; gold_gift=false; gift_time=0; powered_jump=false
    landing_started=false; hide_round=0; reveal_time=0; choice_made=false
    playing_daddy=false; trial_phase=-1; cloud_active=false; wave_active=false
    king_world=Vector2(680,-160); king_tone="earnest"; queen_tone="earnest"
    if is_instance_valid(avina): avina.queue_free(); avina=null
    super._restart()
    lesson_card.show(); choice_card.hide(); dialogue_card.hide(); premium_hud.show()
    _show_lesson()
func _input(event: InputEvent) -> void:
    if dialogue_open or choice_card.visible:
        _opal_cancel_for_event(event)
        return
    super._input(event)

func _card() -> PanelContainer:
    var panel := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = Color("102f49")
    style.border_color = Color("b6a4d5")
    style.set_border_width_all(1)
    style.set_corner_radius_all(22)
    style.content_margin_left = 24; style.content_margin_right = 24
    style.content_margin_top = 18; style.content_margin_bottom = 18
    panel.add_theme_stylebox_override("panel",style)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return panel
func _label(text: String, size_px: int, color: Color) -> Label:
    var label := Label.new()
    label.text = text
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    var font: FontFile=preload("res://dist/fonts/story-serif.ttf")
    font.multichannel_signed_distance_field=true
    label.add_theme_font_override("font",font)
    label.add_theme_font_size_override("font_size",size_px)
    label.add_theme_color_override("font_color",color)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return label
func _button(text: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size.y = 58
    var font: FontFile=preload("res://dist/fonts/story-serif-bold.ttf")
    font.multichannel_signed_distance_field=true
    button.add_theme_font_override("font",font)
    button.add_theme_font_size_override("font_size",20)
    button.pressed.connect(callback)
    return button
func _ui_view() -> Vector2:
    var view := get_viewport_rect().size
    var pixels := float(get_window().size.y)/maxf(1,view.y)
    var factor := clampf(1/maxf(.1,pixels),1,2.1)
    tutorial_layer.transform=Transform2D().scaled(Vector2.ONE*factor)
    return view/factor

func _layout_tutorial() -> void:
    var view := _ui_view()
    var width := minf(700,view.x-48)
    lesson_card.size = Vector2(width,0)
    lesson_card.position = Vector2((view.x-width)*.5,minf(124,view.y*.16))
    var physical_scale := float(get_window().size.y)/maxf(1,view.y)
    var readable := clampf(1/maxf(.1,physical_scale),1,1.6)
    var choice_width := minf(600*readable,view.x-48)
    bring_button.custom_minimum_size.y = maxf(58,44/maxf(.1,physical_scale))
    alone_button.custom_minimum_size.y = bring_button.custom_minimum_size.y
    choice_card.size = Vector2(choice_width,0)
    choice_card.position = Vector2((view.x-choice_width)*.5,maxf(24,(view.y-choice_card.size.y)*.5))
    if is_instance_valid(dialogue_card): _layout_dialogue()


func _bubble_world_active() -> bool:
    return super._bubble_world_active() and not dialogue_open and not (is_instance_valid(choice_card) and choice_card.visible)
func _bubble_context_allowed() -> bool:return super._bubble_context_allowed() and lesson>=10
func _hud_snapshot() -> Dictionary:
    var result:=super._hud_snapshot();result["boss_active"]=lesson==8 and boss_hp>0;result["bubble"]=bubble_unlocked and lesson>=10
    return result
func _opal_arena_active() -> bool:return lesson==8 and super._opal_arena_active()
func _opal_opening_soon() -> bool:
    var phase:=fmod(boss_clock,12.0)
    return lesson==8 and phase>=7.98 and phase<8.2
func _opal_update_targets(targets: Array[Dictionary]) -> void:
    super._opal_update_targets(targets)
    if targets.is_empty():return
    targets[0]["bubble"]=false;targets[0]["boost"]=lesson==8 and _opal_boost_available()
func _opal_sync_fields(fx: Node2D) -> void:
    if lesson!=8:return
    if cloud_active:fx.field(0,"king-cloud",cloud-Vector2(camera,0),Vector2(135,120))
    if wave_active:fx.field(1,"king-wave",wave-Vector2(camera,0),Vector2(150,200))

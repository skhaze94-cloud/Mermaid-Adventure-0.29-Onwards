extends "res://godot/basic_chapter.gd"
const Story=preload("res://godot/pearl_storybook.gd")
const Dialogue = preload("res://godot/family_dialogue.gd")
const Royal = preload("res://godot/family_royal_actor.gd")
const FamilyAttention = preload("res://godot/family_attention.gd")
var family_attention = FamilyAttention.new()
const TutorialReef = preload("res://godot/tutorial_reef_beauty.gd")
const TreasureGallery = preload("res://godot/tutorial_treasure_gallery.gd")
var treasure_gallery: Node2D
var art_director: Node2D
const RINGS: Array[Vector2] = [Vector2(1100,430),Vector2(1900,650),Vector2(2850,420)]
const PEEKABOO=preload("res://godot/assets/little-moments/peekaboo.png")
const HIDES: Array[Vector2] = [Vector2(7100,756),Vector2(7240,735),Vector2(7360,760)]
const TITLES := ["Explore the family lagoon","Three glowing swim rings","Through the elite reef","Very dignified zoomies","Your first sky jump","Over the tall reef","Antonella’s royal gifts","Three volunteer boops","King Daddy’s final trial","A tiny game of peekaboo","Avina’s very first bubble"]
const HINTS := ["Swim freely • arrows / WASD / stick / touch pad","Swim into each glowing ring · 0 / 3","Swim beyond the reef · relic chests are optional","Aim and Boost • Space / controller B / Boost button","Jump and land • J or Shift / controller A / Jump","Jump before the tall reef · steer right · land beyond it","Collect heart + gold · jump with the power · land","Boost boop Professor Puff, Sir Wobble and Noodle","Dodge slow spells · wait for GREEN · Boost into Daddy","Look for a little bow behind the sparkling coral","B or Z / controller X / Bubble · hold 1.35 seconds, then release for Royal Aurora"]
var lesson := 0
var ring_count := 0
var explore_time := 0.0
var landing_started := false
var reef_retry := false
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
var arrival_intro_pending := false
var character_dt := 1.0/60.0
var king_world := Vector2(680,-160)
var king_mode := "idle"
var queen_mode := "idle"
var queen_world:=Vector2(6100,530)
var royal_welcome_until:=0.0
var was_exploring_tunnels:=false
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
var dialogue_practice: Button
var dialogue_scroll: ScrollContainer
var dialogue_content: VBoxContainer
var dialogue_text: Label
var portrait: TextureRect
var reply_box: VBoxContainer
var lesson_trial_meter: ProgressBar
var reply_toggle: Button
var extras_toggle: Button
var extra_box: HBoxContainer
var dialogue_shade: ColorRect
var speech_beats: Array[Dictionary] = []
var speech_index := 0
var speech_options: Array = []
var speech_speaker := "king"
var farewell_step := -1
var speech_reveal: Tween
var speech_counter: Label
var speech_tail: Node2D
var dialogue_footer: GridContainer
var dialogue_layout_pending:=false
var tutorial_action_guard := false
var hide_cover: Node2D
var practice_switch := {"pos":Vector2(7480,390), "on":false, "requires_sarah":true}

func _save_checkpoint() -> void:
    checkpoint = clampf(player.x, _left_bound(), _portal_x()-4)
    super._save_checkpoint()

func _checkpoint_extras() -> Dictionary:
    return {"lesson":lesson, "rings":ring_count, "explore":explore_time,
        "heart":heart_gift, "gold":gold_gift, "gift_time":gift_time,
        "powered_jump":powered_jump, "hide_round":hide_round, "practice":practice_switch["on"]}

func _valid_checkpoint_extras(extra: Dictionary) -> bool:
    if not extra.get("lesson") is int or extra["lesson"] not in range(11): return false
    if not extra.get("rings") is int or extra["rings"] not in range(4): return false
    if not extra.get("hide_round") is int or extra["hide_round"] not in range(4): return false
    if int(extra["lesson"]) == 9 and int(extra["hide_round"]) > 2: return false
    for key in ["heart", "gold", "powered_jump", "practice"]:
        if not extra.get(key) is bool: return false
    for key in ["explore", "gift_time"]:
        if not extra.get(key) is float and not extra.get(key) is int: return false
        if not is_finite(float(extra[key])): return false
    return true

func _restore_checkpoint_extras(extra: Dictionary) -> void:
    lesson = int(extra["lesson"]); ring_count = int(extra["rings"])
    explore_time = clampf(float(extra["explore"]),0,4)
    heart_gift = extra["heart"]; gold_gift = extra["gold"]
    gift_time = clampf(float(extra["gift_time"]),0,8); powered_jump = extra["powered_jump"]
    hide_round = int(extra["hide_round"]); practice_switch["on"] = extra["practice"]
    family_attention.reset()
    dialogue_open = false; playing_daddy = false; landing_started = false; reef_retry = false
    dialogue_card.hide(); choice_card.hide(); dialogue_shade.hide(); speech_tail.hide(); lesson_card.show(); premium_hud.show()
    king.configure("king",410 if lesson==8 else 390)
    arrival_time=2.6;arrival_intro_pending=false;king_world=player+Vector2(230,-90)
    if lesson >= 9:
        if not is_instance_valid(avina):
            avina = preload("res://godot/avina_companion.gd").new(); add_child(avina); avina.bind(self)
        avina.follow_enabled = lesson >= 10
        if lesson == 9: _place_hidden_baby()
    _show_lesson()

func _ready() -> void:
    super._ready()
    bubble_unlocked = false
    performance.hide()
    king = Royal.new(); add_child(king); king.configure("king",390);king.tutorial_life=true
    queen_teacher = Royal.new(); add_child(queen_teacher); queen_teacher.configure("queen",410);queen_teacher.tutorial_life=true
    royal_player = Royal.new(); add_child(royal_player); royal_player.configure("king",230); royal_player.hide()
    hide_cover = Node2D.new(); hide_cover.z_index=5; add_child(hide_cover)
    hide_cover.draw.connect(_draw_hide_cover)
    _build_tutorial_ui()
    _show_lesson()
    treasure_gallery = TreasureGallery.new()
    treasure_gallery.name = "TutorialTreasureChests"
    add_child(treasure_gallery)
    treasure_gallery.bind(self)
    art_director=preload("res://godot/tutorial_art_director.gd").new();add_child(art_director);art_director.bind(self)
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
        if is_instance_valid(little_moments):little_moments.sync()
        return
    character_dt = dt
    super._process(dt)
    if lesson==0 and player_velocity.length()>45:
        explore_time += dt
        if explore_time>4: _advance_lesson(1,"intro")
    # First finish the welcome on screen; only then open its conversation.
    if lesson>=1 and not dialogue_open and (not arrival_intro_pending or player.y<900):
        arrival_time = minf(2.6,arrival_time+dt)
        if lesson==1 and arrival_intro_pending and arrival_time>=2.6:
            arrival_intro_pending=false;_open_dialogue("intro")
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
    _refresh_lesson_hint()
    _settle_lesson_size()

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
        elif lesson==5:
            if jump_origin<4800 and player.x>4895: _advance_lesson(6,"gifts")
            else: reef_retry=true
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
        _refresh_lesson_hint()
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
    reef_retry=false
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
    if lesson==8:
        boss_clock=0;playing_daddy=false
        king.configure("king",410)
    _show_lesson()
    _save_checkpoint()
    # Most lessons flow straight into play. The current conversation stays in Help.
    if conversation=="intro":arrival_intro_pending=true
    elif conversation in ["gifts","trial","win"]: _open_dialogue(conversation)

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
        elif segment not in [0,6]: _damage(boss_position)

func _sync_native_visuals() -> void:
    super._sync_native_visuals()
    if is_instance_valid(art_director):art_director.sync()
    if not is_instance_valid(king): return
    performance.hide()
    var previous_king:=king_world
    if player.y>980:was_exploring_tunnels=true
    elif player.y<850 and was_exploring_tunnels:
        royal_welcome_until=time+2.4;was_exploring_tunnels=false
    var target := Vector2(clampf(player.x+350,680,6640),maxf(_water_line()+160,player.y-90))
    if lesson==6:target=Vector2(player.x-350,maxf(_water_line()+160,player.y-90))
    if lesson>=8: target=boss_position if boss_hp>0 else Vector2(6770,515)
    king_world=boss_position if lesson==8 and boss_hp>0 else king_world.lerp(target,1.0-exp(-character_dt*3.08))
    var shown := king_world
    if lesson==1 and arrival_time<2.6:
        # Swim in from open water at Sarah's level; never descend through the HUD.
        var f:=smoothstep(0,1,arrival_time/2.6)
        shown=target+Vector2(310*(1-f),32*sin(f*PI))
        if reduced_fx:shown=target
    if lesson<8:
        shown.x=minf(shown.x,player.x-350) if lesson==6 else maxf(shown.x,player.x+350)
    if lesson>8 and absf(shown.x-player.x)<350:shown.x=player.x+(-350 if target.x<player.x else 350)
    king.position=shown-Vector2(camera,0)
    king.set_attention(signf(player.x-king_world.x))
    king.modulate.a=1 if lesson!=1 or reduced_fx else smoothstep(0,.55,arrival_time)
    king.visible=lesson>=1 and player.y<980 and not (playing_daddy and lesson<8)
    king_mode="dash" if lesson==8 and trial_phase==4 else ("cast" if lesson==8 and boss_phase=="attack" else ("celebrate" if boss_hp<=0 else ("wave" if arrival_time<2.6 else "idle")))
    var teacher_velocity: Vector2=(king_world-previous_king)/maxf(.001,character_dt)
    king.set_travel(teacher_velocity)
    if lesson<8 and arrival_time>=2.6:
        king_mode="wave" if time<royal_welcome_until else "swim" if teacher_velocity.length()>40 else "idle"
    if lesson>8:king_mode="idle"
    king.animate(time,king_mode,reduced_fx)
    var queen_target:=Vector2(7260,500) if lesson>=9 else Vector2(6100,530)
    if lesson>=6 and absf(queen_target.x-player.x)<340:
        queen_target.x=player.x+(350 if queen_target.x>=player.x else -350)
    var previous_queen:=queen_world
    if queen_world.distance_to(queen_target)>850:queen_world=queen_target
    else:queen_world=queen_world.lerp(queen_target,1-exp(-character_dt*3.1))
    queen_teacher.position=queen_world-Vector2(camera,0)
    queen_teacher.set_attention(signf(player.x-queen_world.x))
    var queen_velocity: Vector2=(queen_world-previous_queen)/maxf(.001,character_dt)
    queen_teacher.set_travel(queen_velocity)
    queen_teacher.visible=lesson>=6
    queen_mode="swim" if queen_velocity.length()>40 else "idle"
    if queen_demo>0 or lesson==6 and family_attention.lesson_elapsed<3:queen_mode="cast"
    queen_teacher.animate(time,queen_mode,reduced_fx)
    family_attention.advance(self,character_dt)
    royal_player.visible=playing_daddy
    native_rig.visible=not playing_daddy
    if playing_daddy:
        royal_player.position=_hero_screen_position()
        royal_player.scale.x=facing
        royal_player.animate(time,"dash" if boost_time>0 else ("swim" if player_velocity.length()>50 else "idle"),reduced_fx)

func _draw_world(view: Vector2) -> void:
    # Tutorial-only reef treatment: character art and family rigs are intentionally untouched.
    super._draw_world(view)
    TutorialReef.draw_background(self, camera, time, reduced_fx, view)
    TutorialReef.draw_foreground(self, camera, time, reduced_fx, view)
    if lesson == 10:
        var target: Vector2 = practice_switch["pos"] - Vector2(camera,0)
        TutorialReef.draw_practice(self,target,practice_switch["on"])
    if lesson==1:
        for i in range(3):
            var point := RINGS[i]-Vector2(camera,0)
            TutorialReef.draw_swim_ring(self,point,i,ring_count,time,reduced_fx)
    if lesson==8:
        if trial_phase==3:
            draw_dashed_line(boss_position-Vector2(camera,0),boss_position-Vector2(camera,0)-Vector2(215,45),Color("bfe8ff"),2,12)
        if boss_phase=="windup": draw_dashed_line(boss_position-Vector2(camera,0),boss_target-Vector2(camera,0),Color("bfe8ff"),2,12)
    if queen_demo>0:
        var center: Vector2 = queen_teacher.position+queen_teacher.size*Vector2(.36,-.25)
        var phase := int((10-queen_demo)/3.34)
        var elapsed := fmod(10-queen_demo,3.34)
        for i in range(7):
            var offset := Vector2.LEFT.rotated((i-3)*.18)*elapsed*65 if phase==0 else (Vector2(cos(i*TAU/7+time),sin(i*TAU/7+time))*55 if phase==1 else Vector2(-elapsed*90,sin(time*2+i)*22))
            draw_circle(center+offset,6,Color(.98,.86,1,.45))
            draw_arc(center+offset,6,0,TAU,20,Color("ffe4d4"),1)
        _draw_text(queen_teacher.position+Vector2(-100,queen_teacher.size.y*.5+26),["PEARL FAN · demonstration","CROWN HALO · demonstration","PEARL WAVE · demonstration"][mini(phase,2)],14)

func _paint_chapter_boss() -> void: pass
func _start_hide_seek() -> void:
    if not is_instance_valid(avina):
        avina=preload("res://godot/avina_companion.gd").new(); add_child(avina); avina.bind(self)
    avina.follow_enabled=false
    hide_round=0; reveal_time=0
    _place_hidden_baby()
    _save_checkpoint()
    _show_lesson()
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
        _save_checkpoint()
func _draw_hide_cover() -> void:
    if lesson!=9: return
    hide_cover.draw_texture_rect(PEEKABOO,Rect2(Vector2(6990-camera,655),Vector2(500,245)),false)
    for i in range(3):
        if i==hide_round and reveal_time<=0:
            var bow := HIDES[i]-Vector2(camera,0)+Vector2(20,-70)
            for j in range(3): hide_cover.draw_circle(bow+Vector2(sin(time*1.6+j)*12,-j*14),3,Color("efcaff"))

func _show_lesson() -> void:
    if not is_instance_valid(heading): return
    heading.text=TITLES[lesson]
    dialogue.hide()
    talk_king.text="Help · "+("Mum" if _lesson_conversation() in ["gifts","practice","hide","bubble"] else "Daddy")
    _refresh_lesson_hint()
    _say("",0)
    _layout_tutorial.call_deferred()

func _lesson_conversation() -> String:
    return ["intro","intro","reef","boost","jump","air","gifts","practice","trial","hide","bubble"][lesson]

func _control_name(action: String) -> String:
    if simulated_touch or DisplayServer.is_touchscreen_available():return action.capitalize()
    if not Input.get_connected_joypads().is_empty():return {"swim":"left stick","boost":"B","jump":"A","bubble":"X"}[action]
    return {"swim":"arrows / WASD","boost":"Space","jump":"J / Shift","bubble":"B / Z"}[action]

func _lesson_hint() -> String:
    if player.y>1020 and lesson<8:return deep_routes.room_name()+" · gentle hellos earn points"
    match lesson:
        0:return "Find your fins · "+_control_name("swim")
        1:return "Swim through the gold rings · %s / 3" % ring_count
        2:return "Follow the open passage through the reef"
        3:return "Aim, then Boost · "+_control_name("boost") if energy>=.4 else "Let your aqua energy refill, then Boost"
        4:return "Steer, then splash down" if leap_phase!="" else "Try a little Jump · "+_control_name("jump")
        5:
            if leap_phase!="":return "Steer right, then splash down beyond the reef"
            return "Start left of the reef · Jump, then steer right"
        6:
            if heart_gift and gold_gift:return "Gold power ready · Jump and land"
            return "Collect "+("the gold gift" if heart_gift else "the pink heart" if gold_gift else "Mum’s heart and gold gift")
        7:
            var remaining := 0
            for enemy in enemies:
                if int(enemy.hp)>0:remaining+=1
            return "Aim and Boost for a gentle boop · %s / 3" % (3-remaining)
        8:
            if boss_hit_cooldown>0:return "Lovely boop · swim clear while Daddy resets"
            return "Mint petals open · aim and Boost!" if _boss_vulnerable() else "Dodge gently · mint petals mean Boost"
        9:return "Peek behind the sparkling coral · %s / 3" % hide_round
        10:
            if practice_switch["on"]:return "A beautiful bubble! The portal is ready →"
            if opal.charge.held:return "Royal Aurora ready · release!" if opal.charge.tier()==3 else "Keep holding Bubble…"
            return "Optional: hold %s for a big bubble · or take the portal →" % _control_name("bubble")
    return ""

func _refresh_lesson_hint() -> void:
    if not is_instance_valid(hint):return
    var next := _lesson_hint()
    if hint.text!=next:
        hint.text=next;_settle_lesson_size.call_deferred()
    heading.text=deep_routes.area_name() if player.y>1020 and lesson<8 else TITLES[lesson]
    lesson_trial_meter.visible=lesson==8
    if lesson==8:lesson_trial_meter.value=float(boss_hp)/3.0

func _release_tutorial_input() -> void:
    # Touch releases happen inside the dialogue and are deliberately consumed.
    # Discard their old vectors so closing a conversation never leaves Sarah
    # swimming or boosting on a finger that has already lifted.
    opal.cancel()
    touches.clear(); touch_vectors.clear()
    opal_joy_primed=false
    jump_buffer=0.0;tutorial_action_guard=true
    var device:=_controller_id()
    if device>=0:
        joy_last={"jump":Input.is_joy_button_pressed(device,JOY_BUTTON_A),"boost":Input.is_joy_button_pressed(device,JOY_BUTTON_B),"bubble":Input.is_joy_button_pressed(device,JOY_BUTTON_X),"pause":Input.is_joy_button_pressed(device,JOY_BUTTON_START)}

func _action_held(action: String) -> bool:
    if tutorial_action_guard:
        var device:=_controller_id()
        if Input.is_key_pressed(KEY_SPACE) or device>=0 and Input.is_joy_button_pressed(device,JOY_BUTTON_B):return false
        tutorial_action_guard=false
    return super._action_held(action)

func _build_tutorial_ui() -> void:
    tutorial_layer=CanvasLayer.new(); tutorial_layer.layer=15; tutorial_layer.process_mode=Node.PROCESS_MODE_ALWAYS; add_child(tutorial_layer)
    lesson_card=_card(); tutorial_layer.add_child(lesson_card)
    var box := VBoxContainer.new(); box.add_theme_constant_override("separation",3); lesson_card.add_child(box)
    var title_row := HBoxContainer.new();title_row.add_theme_constant_override("separation",12);box.add_child(title_row)
    heading=_label("",17,Color("f7dfba"));heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title_row.add_child(heading)
    talk_king=_button("Help · Daddy",func():_open_dialogue(_lesson_conversation()));talk_king.custom_minimum_size=Vector2(108,46);talk_king.add_theme_font_size_override("font_size",16);title_row.add_child(talk_king)
    dialogue=_label("",14,Color.WHITE);dialogue.hide();box.add_child(dialogue)
    hint=_label("",16,Color("c0e8df"));box.add_child(hint)
    lesson_trial_meter=ProgressBar.new();lesson_trial_meter.show_percentage=false;lesson_trial_meter.max_value=1.0;lesson_trial_meter.custom_minimum_size.y=6
    lesson_trial_meter.theme=Story.theme();box.add_child(lesson_trial_meter);lesson_trial_meter.hide()
    dialogue_shade=ColorRect.new();dialogue_shade.color=Color(.01,.04,.08,.20);dialogue_shade.mouse_filter=Control.MOUSE_FILTER_STOP;tutorial_layer.add_child(dialogue_shade);dialogue_shade.hide()
    choice_card=_card(); tutorial_layer.add_child(choice_card)
    var choices := VBoxContainer.new(); choices.add_theme_constant_override("separation",12); choice_card.add_child(choices)
    choices.add_child(_label("A little travelling companion?",25,Color("f7dfba")))
    choices.add_child(_label("Avina would love to come. She follows safely and makes tiny bubbles. A cuddle with Mum and Daddy is lovely too.",20,Color("f3f8ff")))
    bring_button=_button("Come along, little pearl ♡",func(): _choose_companion(true)); bring_button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;choices.add_child(bring_button)
    alone_button=_button("Stay for cuddles · I’ll explore solo",func(): _choose_companion(false)); alone_button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;choices.add_child(alone_button)
    choice_card.hide()
    speech_tail=Node2D.new();speech_tail.name="StorybookSpeechTail";tutorial_layer.add_child(speech_tail)
    speech_tail.draw.connect(_draw_speech_tail);speech_tail.hide()
    dialogue_card=_card();dialogue_card.name="StorybookConversation"; tutorial_layer.add_child(dialogue_card)
    var shell := VBoxContainer.new(); shell.add_theme_constant_override("separation",10); dialogue_card.add_child(shell)
    dialogue_scroll=ScrollContainer.new();dialogue_scroll.follow_focus=true;dialogue_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;dialogue_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;shell.add_child(dialogue_scroll)
    dialogue_content=VBoxContainer.new();dialogue_content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;dialogue_content.add_theme_constant_override("separation",10);dialogue_scroll.add_child(dialogue_content)
    dialogue_content.minimum_size_changed.connect(_queue_dialogue_layout)
    var top := HBoxContainer.new();top.add_theme_constant_override("separation",14);dialogue_content.add_child(top)
    portrait=TextureRect.new();portrait.custom_minimum_size=Vector2(68,58);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;top.add_child(portrait)
    speaker_label=_label("",22,Story.INK);speaker_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(speaker_label)
    speech_counter=_label("",14,Story.MUTED);speech_counter.autowrap_mode=TextServer.AUTOWRAP_OFF;speech_counter.custom_minimum_size.x=50;speech_counter.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;speech_counter.size_flags_horizontal=Control.SIZE_SHRINK_END;speech_counter.add_theme_color_override("font_color",Story.MUTED);speech_counter.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;top.add_child(speech_counter)
    dialogue_text=_label("",21,Color("f3f8ff"));dialogue_content.add_child(dialogue_text)
    reply_box=VBoxContainer.new();reply_box.add_theme_constant_override("separation",7);dialogue_content.add_child(reply_box);reply_box.hide()
    extra_box=HBoxContainer.new();extra_box.add_theme_constant_override("separation",10);dialogue_content.add_child(extra_box);extra_box.hide()
    switch_button=_button("Try Daddy’s fins",func():_close_dialogue();_switch_hero());extra_box.add_child(switch_button)
    talk_queen=_button("A word with Mum",func():_present_conversation("gifts"));extra_box.add_child(talk_queen)
    dialogue_footer=GridContainer.new();dialogue_footer.columns=3
    dialogue_footer.add_theme_constant_override("h_separation",10);dialogue_footer.add_theme_constant_override("v_separation",8);shell.add_child(dialogue_footer)
    reply_toggle=_button("Say something…",_toggle_replies);reply_toggle.size_flags_horizontal=Control.SIZE_EXPAND_FILL;dialogue_footer.add_child(reply_toggle)
    extras_toggle=_button("Little extras",func():extra_box.visible=not extra_box.visible;reply_box.hide();_layout_dialogue.call_deferred());dialogue_footer.add_child(extras_toggle)
    dialogue_practice=_button("Continue ›",_advance_speech);dialogue_practice.size_flags_horizontal=Control.SIZE_EXPAND_FILL;dialogue_footer.add_child(dialogue_practice);dialogue_footer.move_child(dialogue_practice,0);Story.button(dialogue_practice,true)
    dialogue_card.hide()
    get_viewport().size_changed.connect(_layout_tutorial)
    _layout_tutorial.call_deferred()

func _switch_hero() -> void:
    if lesson>=7 or state!="playing" or dialogue_open:return
    playing_daddy=not playing_daddy
    switch_button.text="Sarah’s fins again" if playing_daddy else "Try Daddy’s fins"
    _sync_native_visuals()

func _open_dialogue(id: String) -> void:
    if dialogue_open or choice_card.visible or state!="playing":return
    if id=="intro":
        arrival_intro_pending=false
        if arrival_time<2.6:
            arrival_time=2.6;king_world=Vector2(maxf(680,player.x+310),maxf(_water_line()+160,player.y-90))
    _release_tutorial_input()
    dialogue_open=true;get_tree().paused=true;farewell_step=-1
    _compose_family_dialogue()
    if is_instance_valid(little_moments):little_moments.sync();little_moments.hide_other_captions()
    lesson_card.hide();premium_hud.hide();dialogue_card.show();dialogue_shade.show()
    _present_conversation(id)

func _compose_family_dialogue() -> void:
    # Put both parents in a quiet, balanced upper-stage composition. On a short
    # phone viewport this keeps their gestures above the dialogue dock.
    var view := _ui_view()
    var compact: bool = premium_hud.ui_scale < 0.62
    if not compact:return
    var king_target := Vector2(view.x * 0.22, minf(king.position.y, 280.0))
    var queen_target := Vector2(view.x * 0.78, minf(queen_teacher.position.y, 280.0))
    var move := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    move.set_parallel(true)
    move.tween_property(king, "position", king_target, 0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    move.tween_property(queen_teacher, "position", queen_target, 0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _present_conversation(id: String) -> void:
    dialogue_id=id
    var node: Array=Dialogue.NODES[id]
    speech_speaker=node[0];speech_options=node[3]
    _present_speech(node[2],node[0])

func _present_speech(text: String, speaker: String) -> void:
    speech_beats=Dialogue.beats(text,speaker);speech_index=0
    _show_speech()

func _show_speech() -> void:
    var beat: Dictionary=speech_beats[speech_index]
    var who: String=beat["speaker"]
    if is_instance_valid(king):king.set_dialogue_pose(who=="king")
    if is_instance_valid(queen_teacher):queen_teacher.set_dialogue_pose(who=="queen")
    speaker_label.text={"king":"King Daddy","queen":"Mum · Queen Antonella","sarah":"Sarah","avina":"Avina"}[who]
    dialogue_text.text=beat["text"]
    speech_counter.text="%s / %s" % [speech_index+1,speech_beats.size()]
    speech_counter.visible=speech_beats.size()>1
    _set_portrait(who,2 if (king_tone if who=="king" else queen_tone)=="cheeky" else 1)
    var last := speech_index==speech_beats.size()-1
    _clear_replies();reply_box.hide();extra_box.hide();reply_toggle.text="Say something…"
    reply_toggle.visible=last and not speech_options.is_empty() and farewell_step<0
    extras_toggle.visible=last and farewell_step<0 and not premium_hud.portrait and (lesson<7 or lesson>=6 and speech_speaker=="king")
    switch_button.visible=lesson<7
    talk_queen.visible=lesson>=6 and speech_speaker=="king"
    dialogue_practice.show()
    dialogue_practice.text="Continue ›" if not last else ("And Mum? ›" if farewell_step==0 else "Through the portal! ›" if farewell_step==1 else "Let’s swim ›")
    if speech_reveal:speech_reveal.kill()
    dialogue_text.modulate.a=1.0 if reduced_fx else .35
    if not reduced_fx:
        speech_reveal=create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
        speech_reveal.tween_property(dialogue_text,"modulate:a",1.0,.16)
    _focus_reply()
    speech_tail.queue_redraw()

func _advance_speech() -> void:
    if not dialogue_open:return
    if speech_index+1<speech_beats.size():
        speech_index+=1;_show_speech()
    elif farewell_step==0:
        farewell_step=1
        var lines:=Dialogue.farewell(chosen_along,king_tone,queen_tone)
        _present_speech(lines[1],"queen")
    elif farewell_step==1:_finish_tutorial()
    else:_close_dialogue()

func _toggle_replies() -> void:
    extra_box.hide()
    if reply_box.visible:
        reply_box.hide();reply_toggle.text="Say something…";dialogue_practice.grab_focus()
    else:
        _clear_replies()
        for item in speech_options:
            _add_reply(item[0],func():_dialogue_answer(speech_speaker,item[1],item[2]))
        reply_box.show();reply_toggle.text="Keep listening"
        if reply_box.get_child_count()>0:reply_box.get_child(0).grab_focus()
    _layout_dialogue.call_deferred()

func _dialogue_answer(speaker: String, tone: String, response: String) -> void:
    if speaker=="king":king_tone=tone
    else:queen_tone=tone;queen_demo=10.0
    speech_options=[]
    _present_speech(response,speaker)

func _clear_replies() -> void:
    for child in reply_box.get_children():reply_box.remove_child(child);child.queue_free()
func _add_reply(text: String, callback: Callable) -> void:
    var button:=_button(text,callback);button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    reply_box.add_child(button)
func _focus_reply() -> void:
    _layout_dialogue.call_deferred()
    dialogue_practice.grab_focus()
    _reset_dialogue_scroll()
func _reset_dialogue_scroll() -> void:
    await get_tree().process_frame
    if is_instance_valid(dialogue_scroll):dialogue_scroll.scroll_vertical=0
func _set_portrait(speaker: String, expression: int) -> void:
    if speaker in ["sarah","avina"]:
        portrait.texture=preload("res://godot/assets/sarah-definitive-21/front.png") if speaker=="sarah" else preload("res://godot/assets/characters-v027/avina-baby.png")
        return
    var atlas := AtlasTexture.new()
    atlas.atlas=preload("res://godot/assets/family-v026/king-daddy-atlas.webp") if speaker=="king" else preload("res://godot/assets/family-v026/queen-antonella-atlas.webp")
    atlas.region=Rect2(768+(expression%2)*384,int(expression/2)*256,384,256)
    portrait.texture=atlas
func _queue_dialogue_layout() -> void:
    if dialogue_layout_pending:return
    dialogue_layout_pending=true
    _settle_dialogue_layout.call_deferred()
func _settle_dialogue_layout() -> void:
    dialogue_layout_pending=false
    _layout_dialogue()
func _layout_dialogue() -> void:
    var view := _ui_view()
    dialogue_shade.size=view
    var width:=minf(720,view.x-32)
    var compact: bool=width<570
    dialogue_footer.columns=1 if compact else 3
    dialogue_practice.custom_minimum_size.y=60
    reply_toggle.custom_minimum_size.y=54 if compact else 60
    extras_toggle.custom_minimum_size.y=54 if compact else 60
    dialogue_text.add_theme_font_size_override("font_size",20 if compact else 22)
    speaker_label.add_theme_font_size_override("font_size",20 if compact else 22)
    portrait.custom_minimum_size=Vector2(54,48) if compact else Vector2(64,56)
    switch_button.text="Sarah’s fins again" if playing_daddy else "Try Daddy’s fins";talk_queen.text="Talk to Mum"
    switch_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;talk_queen.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    # The content owns wrapping; the scroll owns height. Long optional replies
    # must never enlarge the card beyond its safe area.
    dialogue_card.custom_minimum_size=Vector2.ZERO
    dialogue_card.size.x=width
    var max_height:=minf(430,view.y-32)
    var footer_height: float=dialogue_footer.get_combined_minimum_size().y
    var wanted: float=dialogue_content.get_combined_minimum_size().y+footer_height+46
    dialogue_card.size.y=clampf(wanted,minf(190,max_height),max_height)
    dialogue_card.position=Vector2((view.x-width)*.5,view.y-dialogue_card.size.y-16)
    speech_tail.visible=dialogue_open and dialogue_card.visible and not compact
    speech_tail.queue_redraw()

func _draw_speech_tail() -> void:
    if not is_instance_valid(dialogue_card) or not dialogue_open or not speech_tail.visible:return
    var speaker: String=speech_beats[speech_index]["speaker"] if not speech_beats.is_empty() else ""
    var actor: Node2D=king if speaker=="king" else queen_teacher if speaker=="queen" else native_rig if speaker=="sarah" else avina
    if not is_instance_valid(actor):return
    var at: Vector2=tutorial_layer.transform.affine_inverse()*actor.get_global_transform_with_canvas().origin
    var panel:=Rect2(dialogue_card.position,dialogue_card.size)
    if at.y>=panel.position.y-30 or at.x<16 or at.x>_ui_view().x-16:return
    var x:=clampf(at.x,panel.position.x+42,panel.end.x-42)
    var points:=PackedVector2Array([Vector2(x-11,panel.position.y+2),Vector2(x,panel.position.y-12),Vector2(x+11,panel.position.y+2)])
    speech_tail.draw_colored_polygon(points,Story.IVORY)
    speech_tail.draw_polyline(PackedVector2Array([points[0],points[1],points[2]]),Story.SEAFOAM,1.0,true)

func _close_dialogue() -> void:
    _release_tutorial_input()
    dialogue_open=false;dialogue_card.hide();dialogue_shade.hide();speech_tail.hide();farewell_step=-1
    if is_instance_valid(king):king.end_dialogue_pose()
    if is_instance_valid(queen_teacher):queen_teacher.end_dialogue_pose()
    get_tree().paused=state=="paused"
    premium_hud.show();lesson_card.visible=state=="playing"
    if state=="victory":premium_hud.hide();lesson_card.hide()
    if dialogue_done.is_valid():
        var done := dialogue_done;dialogue_done=Callable();done.call()
func _show_choice() -> void:
    if choice_made or choice_card.visible or dialogue_open:return
    _release_tutorial_input();lesson_card.hide();premium_hud.hide();speech_tail.hide();dialogue_shade.show();choice_card.show()
    _layout_tutorial.call_deferred();bring_button.grab_focus()
    if is_instance_valid(avina):avina.say("Sa-sa?",3)
func _choose_companion(along: bool) -> void:
    if choice_made or state!="victory":return
    choice_made=true;chosen_along=along;choice_card.hide()
    dialogue_open=true;dialogue_card.show();dialogue_shade.show();farewell_step=0;speech_options=[]
    _present_speech(Dialogue.farewell(along,king_tone,queen_tone)[0],"king")
func _finish_tutorial() -> void:
    var run := get_node("/root/AdventureRun")
    run.tutorial_complete=true; run.avina_along=chosen_along
    dialogue_open=false; dialogue_card.hide(); dialogue_shade.hide(); speech_tail.hide(); get_tree().paused=false
    super._advance_journey()
func _advance_journey() -> bool:
    _show_choice(); return true
func _restart() -> void:
    if state=="victory": _show_choice(); return
    if dialogue_open: return
    lesson=0; ring_count=0; explore_time=0; arrival_time=0
    practice_switch["on"] = false
    heart_gift=false; gold_gift=false; gift_time=0; powered_jump=false
    landing_started=false; reef_retry=false; hide_round=0; reveal_time=0; choice_made=false
    playing_daddy=false; trial_phase=-1; cloud_active=false; wave_active=false
    king.configure("king",390);king.tutorial_life=true
    king_world=Vector2(680,490);arrival_intro_pending=false;arrival_time=0; king_tone="earnest"; queen_tone="earnest"
    if is_instance_valid(avina): avina.queue_free(); avina=null
    super._restart()
    lesson_card.show(); choice_card.hide(); dialogue_card.hide(); dialogue_shade.hide(); speech_tail.hide(); premium_hud.show()
    _show_lesson()
func _set_paused(pause_game: bool) -> void:
    super._set_paused(pause_game)
    if pause_game and is_instance_valid(little_moments):little_moments.message_box.hide();little_moments.hide_other_captions()
    if is_instance_valid(lesson_card):lesson_card.visible=state=="playing" and not dialogue_open and not choice_card.visible

func _input(event: InputEvent) -> void:
    if dialogue_open or choice_card.visible:
        _opal_cancel_for_event(event)
        if dialogue_open and farewell_step<0 and event.is_action_pressed("ui_cancel"):
            if reply_box.visible or extra_box.visible:
                reply_box.hide();extra_box.hide();dialogue_practice.grab_focus()
            else:_close_dialogue()
            get_viewport().set_input_as_handled()
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_H and state=="playing":
        _open_dialogue(_lesson_conversation());get_viewport().set_input_as_handled();return
    super._input(event)

func _card() -> PanelContainer:
    var panel := PanelContainer.new()
    panel.theme=Story.theme()
    panel.add_theme_stylebox_override("panel",Story.panel())
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return panel
func _label(text: String, size_px: int, _color: Color) -> Label:
    var label:=Story.label(text,size_px)
    label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    return label
func _button(text: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size.y = 60
    button.focus_mode=Control.FOCUS_ALL
    Story.button(button)
    button.pressed.connect(callback)
    return button
func _ui_view() -> Vector2:
    # Match the HUD's readable physical scale and respect notches/safe areas.
    var hud:=premium_hud
    tutorial_layer.transform=Transform2D(0,Vector2.ONE*hud.ui_scale,0,hud.safe_frame.position)
    return hud.game_size

func _layout_tutorial() -> void:
    var view := _ui_view()
    talk_king.custom_minimum_size.y=60.0 if simulated_touch or DisplayServer.is_touchscreen_available() else 46.0
    var available:=view.x-316
    var width:=minf(430,maxf(240,available))
    lesson_card.size=Vector2(width,0)
    lesson_card.position=Vector2(214+(available-width)*.5,14) if available>=240 else Vector2((view.x-width)*.5,108)
    if premium_hud.portrait:lesson_card.hide()
    choice_card.size=Vector2(minf(570,view.x-40),0)
    choice_card.position=Vector2((view.x-choice_card.size.x)*.5,maxf(20,(view.y-choice_card.size.y)*.5))
    if is_instance_valid(dialogue_card):_layout_dialogue()

func _settle_lesson_size() -> void:
    # Containers grow immediately but do not shrink when wrapped labels settle.
    var wanted:=lesson_card.get_combined_minimum_size().y
    if absf(lesson_card.size.y-wanted)>.5:lesson_card.size.y=wanted


func _bubble_world_active() -> bool:
    return super._bubble_world_active() and not dialogue_open and not (is_instance_valid(choice_card) and choice_card.visible)
func _bubble_context_allowed() -> bool:return super._bubble_context_allowed() and lesson>=10
func _opal_switch_targets() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if lesson == 10: result.append(practice_switch)
    return result
func _opal_hit_switch(_index: int, packet: Dictionary = {}) -> void:
    if lesson != 10 or practice_switch["on"] or packet.get("owner", "sarah") != "sarah": return
    if int(packet.get("tier", 1)) < 3:
        _say("Keep holding until Royal Aurora is ready, then release!",2.5,true)
        return
    practice_switch["on"] = true
    _award("training:super-practice", "Secrets", 100, practice_switch["pos"], false)
    _say("Beautiful! Royal Aurora mastered. The portal is ready.",3.0,true)
    hint.text = "Super bubble mastered! Swim into the glowing portal →"
    _save_checkpoint()
func _hud_snapshot() -> Dictionary:
    var result:=super._hud_snapshot();result["boss_attack"]=move_name if lesson==8 else "";result["boss_active"]=lesson==8 and boss_hp>0;result["bubble"]=bubble_unlocked and lesson>=10
    result["tutorial"]=true
    result["powerups"]=[]
    if gift_time>0:result["powerups"]=[{"id":"royal_boost","label":"Royal boost","remaining":gift_time,"duration":8.0}]
    # The single lesson cue already explains the trial. Keep just its slim meter.
    result["boss_attack"]=""
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


func _owns_treasure_visual(item: Dictionary) -> bool:
    # Optional compositor hook used by the cavern renderer.
    return item.get("kind", "") == "chest"

func _draw_collectible(pos: Vector2, kind: String) -> void:
    if kind == "chest":
        return # The tutorial gallery owns both closed AND collected states.
    if kind=="pearl":
        TutorialReef.draw_pearl(self,pos,time,reduced_fx);return
    super._draw_collectible(pos, kind)

func _draw_chapter_seabed(view: Vector2) -> void:
    TutorialReef.draw_seabed(self,camera,view)

func _draw_chapter_rock(rect: Rect2,index: int) -> void:
    TutorialReef.draw_rock(self,rect,rect.position.x+camera,index)
func _draw_chapter_garden(_x: float,_index: int) -> void:pass

func _dress_tutorial_grotto(canvas: CanvasItem,room: Dictionary,id: int,clock: float) -> void:
    TutorialReef.draw_cave_details(canvas,room,id,clock,reduced_fx)
func _paint_tutorial_perch(canvas: CanvasItem,rect: Rect2,id: int) -> void:
    TutorialReef.draw_perch(canvas,rect,id)
func _paint_tutorial_entrance(canvas: CanvasItem,at: Vector2,tint: Color,clock: float) -> void:
    TutorialReef.draw_entrance(canvas,at,tint,clock,reduced_fx)

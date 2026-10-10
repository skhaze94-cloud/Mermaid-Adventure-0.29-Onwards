extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, note: String) -> void:
    checks+=1
    if not ok: failures+=1; push_error("FAMILY TUTORIAL: "+note)
func frames(count := 6) -> void:
    for i in range(count): await process_frame
func close_conversation(level, answer := 0) -> void:
    check(level.dialogue_open and paused,"conversation pauses gameplay")
    check(level.reply_box.get_child_count()>=3,"branched reply choices")
    var at: Vector2=level.player
    level._physics_process(.1)
    check(level.player==at,"dialogue freezes gameplay physics")
    level.reply_box.get_child(answer).pressed.emit()
    check(level.reply_box.get_child_count()==2,"reply opens second dialogue branch")
    level.reply_box.get_child(0).pressed.emit()
    check(level.reply_box.get_child_count()==1,"follow-up tip reaches final node")
    level.reply_box.get_child(0).pressed.emit()
    check(not paused or level.dialogue_open,"conversation can resume or open next chapter dialogue")
func land(level, at: Vector2) -> void:
    level.player=at; level.leap_phase=""; level.jump_time=0; level.player_velocity=Vector2.ZERO
    level._update_swimming(0)
func run() -> void:
    root.get_node("AppPreferences").persist_enabled=false
    root.get_node("AppPreferences").intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false
    var catalog=root.get_node("AdventureRun")
    catalog.begin(7)
    change_scene_to_file(catalog.SCENES[7]); await frames()
    var level=current_scene
    level.set_physics_process(false); level.set_process(false)
    check(level.obstacles.size()==11 and level.boss_hp==3 and level.enemies.is_empty(),"original reef and Daddy trial preserved")
    check(level.avina==null,"baby absent from training fight")
    check(level.treasures.filter(func(item):return item.kind=="chest").size()==3,"all three original relics")
    level._switch_hero(); check(level.playing_daddy,"try King Daddy hero option")
    level._switch_hero()
    level.player_velocity=Vector2(100,0); level._process(4.1)
    check(level.lesson==1,"exploration leads to Daddy introduction")
    close_conversation(level,1)
    check(level.king_tone=="cheeky","reply tone retained for later farewell")
    for point in level.RINGS: level.player=point; level._update_swimming(0)
    check(level.ring_count==3 and level.lesson==2,"all three actual rings required")
    close_conversation(level)
    level.player=Vector2(3835,550); level._update_swimming(0)
    check(level.lesson==3,"reef traversal unlocks boost")
    close_conversation(level)
    level.energy=1; level._boost(); check(level.lesson==4,"actual boost lesson")
    close_conversation(level)
    level.energy=1; level._jump(); check(level.landing_started,"jump waits for landing")
    land(level,Vector2(4250,600)); check(level.lesson==5,"landed jump unlocks aerial crossing")
    close_conversation(level)
    level.player=Vector2(4750,550); level.energy=1; level.leap_cooldown=0; level._jump()
    land(level,Vector2(5010,600)); check(level.lesson==6,"jump across original tall reef")
    close_conversation(level,2)
    check(level.queen_tone=="cheeky" and level.queen_demo>0,"Antonella tone and magic demonstration")
    for point in [Vector2(5660,490),Vector2(5860,435)]: level.player=point; level._update_collectibles()
    check(level.heart_gift and level.gold_gift and level.gift_time==8,"heart and eight second gold gifts")
    level.leap_cooldown=0; level._jump(); check(level.powered_jump and level.player_velocity.y<-900,"stronger powered jump")
    land(level,Vector2(5980,600)); check(level.lesson==7 and level.enemies.size()==3,"original three volunteer creatures")
    close_conversation(level)
    for enemy in level.enemies:
        level.player=Vector2(enemy.x,enemy.y); level.boost_time=.3; level._update_enemies(0)
    check(level.enemies.all(func(enemy):return int(enemy.hp)<=0),"real boost boops clear volunteers")
    level._update_boss(0); check(level.lesson==8,"practice unlocks final Daddy trial")
    close_conversation(level)
    var moves := {}
    for t in [.1,1.7,2.8,4.4,5.8,7.3,8.6]:
        level.boss_clock=t; level.boss_hit_cooldown=0; level.player=Vector2(6250,750); level.boost_time=0
        level._update_boss(0); moves[level.move_name]=true
        check(level.boss_position.is_finite(),"finite position in each signature move")
    check(moves.size()==7,"six original named moves plus green opening")
    check(not level.hostile_shots.is_empty(),"slow training projectiles are real")
    for i in range(3):
        level.boss_clock=9; level.boss_hit_cooldown=0; level.boost_time=.3; level.player=Vector2(6900,550)
        level._update_boss(0)
    check(level.boss_hp==0 and level.lesson==9 and level.avina==null,"three green hits win, baby still waits for sendoff")
    close_conversation(level,1)
    check(level.dialogue_id=="hide" and is_instance_valid(level.avina),"baby arrives after fight and family praise")
    close_conversation(level,1)
    for i in range(3):
        level.reveal_time=0; level._place_hidden_baby(); level.player=level.HIDES[i]; level._update_swimming(0)
        check(level.hide_round==i+1,"peekaboo finding round "+str(i))
    check(level.lesson==10 and level.avina.follow_enabled,"three finds release baby follower")
    level.avina.tick(.01); check(level.avina.bubbles_cast==1,"baby does only her little bubble")
    for i in range(50): level.avina.request_bubble(); level.avina.tick(.01)
    check(level.avina.bubbles_cast==1,"bubble rate limit")
    level.player=Vector2(level._portal_x()+1,550); level._update_swimming(0)
    check(level.choice_card.visible and paused,"choice appears at portal")
    level.bring_button.pressed.emit()
    check(level.dialogue_text.text.contains("beard"),"cheeky Daddy reply affects take-along farewell")
    level.reply_box.get_child(0).pressed.emit()
    check(level.dialogue_text.text.contains("lightning staff"),"Antonella’s tone affects her farewell")
    level.reply_box.get_child(0).pressed.emit(); await frames(18)
    check(current_scene._stage_index()==0 and catalog.avina_along and not paused,"bring baby starts adventure")
    check(current_scene.bubble_unlocked and is_instance_valid(current_scene.avina),"learned bubble and baby cross transition")
    current_scene._restart()
    check(current_scene.bubble_unlocked and is_instance_valid(current_scene.avina),"restart keeps skill and baby")
    for index in [1,2,3,4,5,6]:
        change_scene_to_file(catalog.SCENES[index]); await frames()
        var chapter=current_scene; chapter.set_physics_process(false)
        check(is_instance_valid(chapter.avina),"baby in chapter "+str(index))
        chapter.avina.request_bubble(); chapter.avina.tick(.02)
        check(chapter.avina.bubbles_cast==1,"baby bubble in chapter "+str(index))
        chapter.reduced_fx=true; chapter.avina.tick(.02)
        check(chapter.avina.sprite.rotation==0 and chapter.avina.sprite.position.y==0,"gentle motion support")
    catalog.begin(7); change_scene_to_file(catalog.SCENES[7]); await frames()
    level=current_scene; level.set_physics_process(false); level.set_process(false)
    level.lesson=10; level.boss_hp=0; level.player=Vector2(level._portal_x()+1,550); level._update_swimming(0)
    level.alone_button.pressed.emit(); check(level.dialogue_text.text.contains("solo explorer"),"solo Daddy branch")
    level.reply_box.get_child(0).pressed.emit(); check(level.dialogue_text.text.contains("stay with us"),"solo Antonella branch")
    level.reply_box.get_child(0).pressed.emit(); await frames(18)
    check(current_scene._stage_index()==0 and not catalog.avina_along and current_scene.avina==null and not paused,"solo continues without baby")
    current_scene.free(); await frames()
    print("FAMILY TUTORIAL: ",checks," checks, ",failures," failures")
    quit(1 if failures else 0)

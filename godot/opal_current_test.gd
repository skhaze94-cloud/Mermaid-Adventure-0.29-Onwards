extends SceneTree
## Live input, chapter gates, swept ordering, bounded pools and reward transactions.
const Sweep=preload("res://godot/opal_collision.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool, reason: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error("OPAL CURRENT: "+reason)
func key(level, code: Key, down: bool, echo:=false) -> void:
    var event:=InputEventKey.new();event.keycode=code;event.pressed=down;event.echo=echo;level._input(event)
func touch(level, index: int, down: bool, point: Vector2, cancelled:=false) -> void:
    var event:=InputEventScreenTouch.new();event.index=index;event.pressed=down;event.position=point;event.canceled=cancelled;level._input(event)
func create(path: String):
    var level=load(path).instantiate();root.add_child(level);level.set_process(false);level.set_physics_process(false);return level
func clean(level) -> void:
    paused=false;level.state="playing";level.waterfall_phase="";level.opal.reset();level.fire_cooldown=0
    level.bubble_shots.clear();level.hostile_shots.clear();level.obstacles.clear();level.enemies.clear();level.animated_enemies.bind_enemies(level.enemies)
    level.boss_hp=0;level.boost_time=0;level.boost_cooldown=0;level.energy=1;level.boss_hit_cooldown=0;level.bubble_unlocked=true
    level.player=Vector2(0,600);level.facing=1;level.touches.clear();level.touch_vectors.clear()
func enemy(level, x: float, hp: int=3, kind: String="puffer", variant: String="") -> Dictionary:
    var target: Dictionary={"kind":kind,"variant":variant,"x":x,"y":600.0,"bx":x,"by":600.0,"hp":hp,"dir":-1,
        "mode":"patrol","mode_time":0.0,"phase":0.0,"hit_cd":0.0}
    level.enemies.append(target);return target
func shot(level, at: Vector2, damage:=1, boss_damage:=1, baby:=false) -> Dictionary:
    level.opal.sequence+=1
    var packet: Dictionary={"packet_id":level.opal.epoch+":"+str(level.opal.sequence),"epoch":level.opal.epoch,"pos":at,
        "direction":1.0,"life":1.8,"damage":damage,"boss_damage":boss_damage,"owner":"avina" if baby else "sarah",
        "baby":baby,"tier":3 if damage==3 else 1,"consumed":false}
    level.bubble_shots.append(packet);return packet
func dispose(level) -> void:root.remove_child(level);level.free()
func run() -> void:
    root.size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
    await process_frame;await process_frame
    root.get_node("AppPreferences").persist_enabled=false;root.get_node("OceanAudio").playback_enabled=false
    root.get_node("AdventureRun").avina_along=false;root.get_node("AdventureRun").tutorial_complete=false
    check(is_equal_approx(Sweep.circle(Vector2.ZERO,Vector2(100,0),Vector2(50,0),10),0.4),"circle entry time")
    check(Sweep.circle(Vector2.ZERO,Vector2.ZERO,Vector2(50,0),10)==INF,"stationary miss")
    check(Sweep.circle(Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,10)==0,"stationary overlap")
    check(is_equal_approx(Sweep.rectangle(Vector2.ZERO,Vector2(100,0),Rect2(30,-10,20,20)),0.3),"rectangle entry time")
    check(Sweep.rectangle(Vector2(0,11),Vector2(100,11),Rect2(30,-10,20,20))==INF,"parallel slab miss")
    var level=create("res://godot/highland_level.tscn");clean(level)
    level.bubble_unlocked=false;key(level,KEY_B,true);key(level,KEY_B,false)
    check(level.bubble_shots.is_empty() and not level.opal.charge.held,"unlock blocks press/release")
    level.bubble_unlocked=true;key(level,KEY_B,true);key(level,KEY_Z,true);key(level,KEY_Z,false)
    check(level.opal.charge.held and level.bubble_shots.is_empty(),"second source cannot steal hold")
    key(level,KEY_B,true,true);level.opal.advance(0.349);key(level,KEY_B,false)
    check(level.bubble_shots.size()==1 and level.bubble_shots[0]["damage"]==1,"one tap; key echo ignored")
    check(is_equal_approx(level.fire_cooldown,0.2),"tap recovery")
    key(level,KEY_B,false);level._fire_bubble();check(level.bubble_shots.size()==1,"release/cooldown cannot duplicate shot")
    clean(level);key(level,KEY_Z,true);level.opal.advance(0.35);key(level,KEY_Z,false)
    check(level.bubble_shots[0]["damage"]==2 and level.bubble_shots[0]["boss_damage"]==1,"partial threshold and boss cap")
    clean(level);key(level,KEY_B,true)
    for i in range(135):level.opal.advance(0.01)
    level.opal.advance(30)
    check(level.opal.charge.held and level.opal.charge.tier()==3 and level.bubble_shots.is_empty(),"split delta full charge never auto fires")
    check(level.opal.ready_chimed,"single readiness latch")
    key(level,KEY_B,false)
    check(level.bubble_shots.size()==1 and level.bubble_shots[0]["damage"]==3 and level.bubble_shots[0]["boss_damage"]==2,"super packet damage")
    check(is_equal_approx(level.fire_cooldown,0.65),"super recovery")
    check(is_equal_approx(level.bubble_shots[0]["pos"].x,level.player.x+152),"super ahead of casting hand")
    clean(level);level.obstacles.append(Rect2(110,570,20,60));level._fire_bubble();level._update_bubbles(0)
    check(level.bubble_shots.is_empty(),"hand socket cannot skip a nearby wall")
    var children: int=level.opal_fx.get_child_count()
    for i in range(80):level.opal_fx.impact(Vector2(100,500),3,true);level.opal_fx.advance(0.01)
    check(level.opal_fx.impacts.size()==12 and level.opal_fx.get_child_count()==children,"fixed impact pool")
    clean(level)
    for i in range(8):shot(level,Vector2(100+i*20,600),3,2)
    level.opal.begin("key:capacity");level.opal.advance(1.35)
    check(not level.opal.release("key:capacity") and level.bubble_shots.size()==8,"all protected pool rejects ninth shot")
    check(level.fire_cooldown==0 and not level.opal.charge.held and level.opal.charge.pending.is_empty(),"refusal commits no recovery or delayed shot")
    clean(level);var baby:=shot(level,Vector2(100,600),1,0,true)
    for i in range(7):shot(level,Vector2(120+i*20,600))
    var oldest: String=level.bubble_shots[1]["packet_id"]
    level.opal.begin("key:capacity");level.opal.advance(1.35);level.opal.release("key:capacity")
    check(level.bubble_shots.size()==8 and level.bubble_shots.has(baby),"admission preserves Avina")
    check(not level.bubble_shots.any(func(s):return s["packet_id"]==oldest) and level.bubble_shots[7]["damage"]==3,"oldest basic recycled for super")
    clean(level);key(level,KEY_B,true);level.opal.advance(1.35);level._set_paused(true)
    check(not level.opal.charge.held and level.bubble_shots.is_empty(),"pause cancels")
    level._set_paused(false);key(level,KEY_B,true);check(not level.opal.charge.held,"held source suppressed after pause")
    key(level,KEY_B,false);key(level,KEY_B,true);check(level.opal.charge.held,"physical release rearms")
    level._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);check(paused and not level.opal.charge.held,"focus cancels and pauses")
    level._set_paused(false);key(level,KEY_B,false);clean(level)
    var button: Vector2=level._touch_rect("bubble",level.get_viewport_rect().size).get_center()
    touch(level,3,true,button);touch(level,7,true,button);touch(level,7,false,button)
    check(level.opal.charge.held and level.opal.charge.source_id=="touch:3","second finger cannot release owner's hold")
    var drag:=InputEventScreenDrag.new();drag.index=3;drag.position=Vector2.ZERO;level._input(drag);touch(level,3,false,Vector2.ZERO)
    check(not level.opal.charge.held and level.bubble_shots.is_empty(),"slide off cancels")
    touch(level,3,true,button);touch(level,3,false,button,true)
    check(level.bubble_shots.is_empty() and not level.opal.suppressed.has("touch:3"),"touch cancel releases latch")
    touch(level,3,true,button);touch(level,3,false,button);check(level.bubble_shots.size()==1,"touch ID reusable")
    clean(level);key(level,KEY_B,true);level._boost();check(not level.opal.charge.held and level.boost_time>0,"boost stays responsive")
    key(level,KEY_B,false);level.boost_time=0;key(level,KEY_B,true);level._jump();check(not level.opal.charge.held and level.leap_phase!="","jump stays responsive")
    key(level,KEY_B,false);key(level,KEY_B,true);level._start_waterfall()
    check(not level.opal.charge.held and not level.opal.begin("script"),"waterfall cancels/gates")
    clean(level);var target:=enemy(level,400,3)
    shot(level,Vector2(0,600));level._update_bubbles(1)
    check(target["hp"]==2 and level.bubble_shots.is_empty(),"swept native shot respects actual HP")
    target["hit_cd"]=0;shot(level,Vector2(0,600),3,2);level._update_bubbles(1);check(target["hp"]==0,"super reduces actual HP")
    var scored: int=level.score;level._update_bubbles(1);check(level.score==scored,"consumed shot scores once")
    clean(level);target=enemy(level,400,1);var duplicate:=shot(level,Vector2(0,600));level.bubble_shots.append(duplicate);level._update_bubbles(1)
    check(target["hp"]==0 and level.bubble_shots.is_empty() and level.opal.retired.size()==1,"duplicate reference consumes once")
    clean(level);target=enemy(level,400,3);level.obstacles.append(Rect2(200,570,20,60));shot(level,Vector2(0,600),3,2);level._update_bubbles(1)
    check(target["hp"]==3 and level.bubble_shots.is_empty(),"first rock blocks enemy")
    level.obstacles[0]=Rect2(800,570,20,60);shot(level,Vector2(0,600));level._update_bubbles(1)
    check(target["hp"]==2,"same-size wall mutation invalidates cache")
    clean(level);target=enemy(level,200,3);var expiring:=shot(level,Vector2(0,600),3,2);expiring["life"]=0.1;level._update_bubbles(1)
    check(target["hp"]==3,"sweep bounded by remaining lifetime")
    clean(level);target=enemy(level,400,3,"crab","guard");level.player=Vector2(1000,600)
    shot(level,Vector2(0,600),3,2);level._update_bubbles(1)
    check(target["hp"]==3 and target["mode"]=="recover" and is_equal_approx(target["hit_cd"],0.25),"guard uses incoming direction, no HP damage")
    target["hit_cd"]=0;shot(level,Vector2(0,600),2,1);level._update_bubbles(1);check(target["hp"]==1,"recovery follow-up damages")
    clean(level);target=enemy(level,400,3);var stale:=shot(level,Vector2(0,600),3,2).duplicate(true)
    level.bubble_shots.clear();level.opal.reset();level.bubble_shots.append(stale);level._update_bubbles(1)
    check(target["hp"]==3 and level.bubble_shots.is_empty(),"previous epoch cannot mutate new world")
    clean(level);level.player=Vector2(400,600);level.invulnerable=0;level.health=5
    level._spawn_hostile(Vector2(0,600),Vector2.RIGHT,900,"puffer");level._update_hostile_shots(1)
    check(level.health==4 and level.hostile_shots.is_empty(),"hostile sweep cannot tunnel through Sarah")
    level.invulnerable=0;level.health=5;level.obstacles.append(Rect2(200,570,20,60))
    level._spawn_hostile(Vector2(0,600),Vector2.RIGHT,900,"jelly");level._update_hostile_shots(1);check(level.health==5,"rock precedes Sarah")
    for i in range(100):level._spawn_hostile(Vector2(0,500),Vector2.RIGHT,100)
    check(level.hostile_shots.size()==32,"hostile cap")
    clean(level);level.opal.begin("joy:4");level._poll_gamepad();check(not level.opal.charge.held,"disconnect cancels")
    var pad:={"jump":false,"boost":false,"bubble":false,"pause":false}
    level._apply_gamepad_sample(4,pad.duplicate());pad["bubble"]=true;level._apply_gamepad_sample(4,pad.duplicate())
    check(level.opal.charge.held,"neutral reconnect rearms next press")
    level._apply_gamepad_sample(-1,{});level._apply_gamepad_sample(4,pad.duplicate());check(not level.opal.charge.held,"held reconnect does not charge")
    pad["bubble"]=false;level._apply_gamepad_sample(4,pad.duplicate());pad["bubble"]=true;level._apply_gamepad_sample(4,pad.duplicate())
    check(level.opal.charge.held,"release after reconnect rearms")
    level.opal.cancel();level.opal.release("joy:4")
    key(level,KEY_B,true);root.get_node("SceneFlow").busy=true;key(level,KEY_B,false);root.get_node("SceneFlow").busy=false
    check(not level.opal.charge.held and not level.opal.suppressed.has("key:%s" % KEY_B),"release in loading overlay clears latch without firing")
    for i in range(100):level.opal._retire({"packet_id":"retired:"+str(i)})
    check(level.opal.retired.size()==64 and level.opal.retired_order.size()==64,"retired ledger bounded")
    var clock: float=level.time;paused=true;level._physics_process(0.2);check(level.time==clock,"external tree pause freezes gameplay")
    paused=false;dispose(level);await boss_checks()
    print("OPAL CURRENT: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
func boss_checks() -> void:
    var paths: Array=root.get_node("AdventureRun").SCENES
    for index in range(7):
        var level=create(paths[index]);clean(level)
        var expected: Array=["maraca","ribbon","otter","orchid","drum","disco"] if index==2 else ["crab","eel","jelly","puffer","swordfish","shark"]
        check(expected.all(func(id):return level.opal_fx.art.frames.has(id)),"six chapter materials resolve without fallback "+str(index))
        check(not level.opal_fx.art.atlases.has("enemies" if index==2 else "lagoon"),"other species atlas not retained "+str(index))
        if index==1:level.duke_hp=10;level.flip_hp=8;level.boss_hp=18;level.flip_position=Vector2(level._boss_home()+600,600)
        else:level.boss_hp=level._boss_max_health()
        level.player=Vector2(level._boss_home()-500,800);level.boss_position=Vector2(level._boss_home(),600)
        level.boss_clock=0;level.boss_phase="windup"
        if index>0:
            var boundary:=4.1 if index==1 else 3.8 if index==2 else 4.0
            level.boss_clock=boundary-0.01;level.opal.refresh_targets()
            check(not level._opal_target_open(level.opal.targets[0]) and level.opal.targets[0]["opening"],"anticipation stays closed "+str(index))
            level.boss_clock=boundary;level.opal.refresh_targets()
            check(level._opal_target_open(level.opal.targets[0])==(index!=1),"exact open boundary "+str(index))
            level.boss_clock=boundary+0.01;level.opal.refresh_targets()
            check(level._opal_target_open(level.opal.targets[0]),"after boundary open "+str(index))
        var pos: Vector2=level.player;level.player.x=0;level.opal.refresh_targets()
        check(not level.opal.targets[0]["active"],"outside arena protected "+str(index));level.player=pos
        level.boss_clock=0;level.boss_phase="windup"
        var hp: int=level.boss_hp
        shot(level,level.boss_position-Vector2(200,0),3,2);level._update_bubbles(0.3)
        check(level.boss_hp==hp,"closed boss blocks bubble "+str(index))
        level.boss_clock=4.2;level.boss_phase="recover";level.boss_hit_cooldown=0
        shot(level,level.boss_position-Vector2(200,0),3,2,true);level._update_bubbles(0.3)
        check(level.boss_hp==hp,"Avina excluded from boss "+str(index))
        level.bubble_shots.clear();shot(level,level.boss_position-Vector2(200,0),3,2);level._update_bubbles(0.3)
        check(level.boss_hp==hp-2,"super boss damage capped at two "+str(index))
        var after: int=level.boss_hp;level.boss_clock=4.2;shot(level,level.boss_position-Vector2(200,0),3,2);level._update_bubbles(0.3)
        check(level.boss_hp==after,"shared hit cooldown blocks next packet "+str(index))
        level.bubble_shots.clear();level.boss_hit_cooldown=0;level.bubble_unlocked=false;level.boss_clock=4.2;level.opal.refresh_targets()
        check(not level.opal.targets[0]["bubble"],"unlock lost before collision "+str(index))
        shot(level,level.boss_position-Vector2(200,0),3,2);level._update_bubbles(0.3);check(level.boss_hp==after,"locked packet causes no damage "+str(index))
        level.bubble_unlocked=true;level.bubble_shots.clear();level.boss_hit_cooldown=0
        if index==1:
            level.boss_clock=0;level.opal.refresh_targets()
            check(not level.opal.targets[0]["open"] and level.opal.targets[1]["open"],"Flip independent of Duke phase")
            var flip: int=level.flip_hp;shot(level,level.flip_position-Vector2(150,0));level._update_bubbles(0.2)
            check(level.flip_hp==flip-1,"independent Flip hit")
            var old_camera: float=level.camera;level.camera=level._boss_home()-800;level.flip_stun=0;level._sync_native_visuals()
            check(level.opal_fx.wakes[level.opal_fx.FOE_CAP+1].visible,"Flip contact wake follows his own active contact state")
            level.flip_stun=1;level._sync_native_visuals()
            check(not level.opal_fx.wakes[level.opal_fx.FOE_CAP+1].visible,"Flip stun suppresses contact wake")
            level.camera=old_camera
            level.boss_hit_cooldown=0;level.boss_clock=4.2;level.flip_position=level.boss_position
            var duke: int=level.duke_hp;flip=level.flip_hp;shot(level,level.boss_position-Vector2(200,0),3,2);level._update_bubbles(0.3)
            check(level.duke_hp==duke-2 and level.flip_hp==flip,"overlap consumes once")
            level.duke_hp=1;level.flip_hp=2;level.boss_hp=3;level.boss_hit_cooldown=0;level.boss_clock=4.2
            level._opal_hit_boss("duke",1);check(level.boss_hp==0 and level.flip_hp==0,"surviving partner finish rule")
            var score: int=level.score;level._finish_boss();check(level.score==score,"duo clear reward once")
        if index in [1,2]:
            level.switches.clear();level.switches.append({"on":false,"pos":Vector2(200,600)})
            level.enemies.clear();var foe:=enemy(level,450,1);shot(level,Vector2(0,600));level._update_bubbles(1)
            check(level.switches[0]["on"] and foe["hp"]==1,"switch precedes enemy")
            var score: int=level.score;level._opal_hit_switch(0);check(level.score==score,"switch reward once")
            level.switches[0]["on"]=false;level.enemies.clear();level.obstacles.append(Rect2(100,570,20,60));level.switches[0]["pos"]=Vector2(128,600)
            shot(level,Vector2(0,600));level._update_bubbles(1);check(not level.switches[0]["on"],"rock wins exact tie")
        if index==2:
            level.obstacles.clear();level.enemies.clear();level.switches.clear();var otter:=enemy(level,400,1,"bubble-bandit-otter")
            level.treasures.append({"taken":true,"kind":"pearl","x":400.0,"y":600.0});var loot_index: int=level.treasures.size()-1;otter["loot"]=[loot_index]
            shot(level,Vector2(0,600));level._update_bubbles(1)
            check(otter["hp"]==0 and not level.treasures[loot_index]["taken"] and not otter.has("loot"),"otter loot released once")
        dispose(level);await process_frame
    var tutorial=create(paths[7]);clean(tutorial);tutorial.lesson=8;tutorial.boss_hp=3;tutorial.player=Vector2(6500,700)
    tutorial.boss_position=Vector2(6900,600);tutorial.boss_clock=8.2;tutorial.bubble_unlocked=true;tutorial.opal.refresh_targets()
    check(tutorial._opal_target_open(tutorial.opal.targets[0]) and not tutorial.opal.targets[0]["bubble"],"King trial boost only")
    tutorial.king_world=Vector2(100,100);tutorial._sync_native_visuals()
    check(tutorial.king.position.is_equal_approx(tutorial.boss_position-Vector2(tutorial.camera,0)),"trial painting aligns with collider")
    check(not tutorial.opal.begin("script"),"early tutorial bubble gate")
    shot(tutorial,Vector2(6700,600),3,2);tutorial._update_bubbles(0.4);check(tutorial.boss_hp==3,"packet cannot bypass trial")
    tutorial.boss_clock=8.19999;tutorial.opal.refresh_targets()
    check(not tutorial._opal_target_open(tutorial.opal.targets[0]) and tutorial.opal.targets[0]["opening"],"King anticipation not early")
    tutorial.lesson=6;tutorial.opal.refresh_targets();check(not tutorial.opal.targets[0]["active"],"friendly teacher role protected")
    check(not tutorial._hud_snapshot()["boss_active"] and not tutorial._hud_snapshot()["bubble"],"teacher HUD protected")
    tutorial.lesson=8;tutorial.boss_hp=5;tutorial.boss_clock=8.6;tutorial.boss_hit_cooldown=0;tutorial.energy=0;tutorial.boost_time=0;tutorial.opal.refresh_targets()
    check(not tutorial._opal_target_open(tutorial.opal.targets[0]) and not tutorial._hud_snapshot()["boss_vulnerable"],"boost invitation requires energy")
    tutorial.energy=1;tutorial.jump_time=0.5;tutorial.opal.refresh_targets()
    check(not tutorial._opal_target_open(tutorial.opal.targets[0]) and not tutorial._hud_snapshot()["boss_vulnerable"],"boost unavailable in jump")
    tutorial.jump_time=0;tutorial.lesson=10;tutorial.boss_hp=0;check(tutorial.opal.begin("key:dialogue"),"bubble lesson enables charge")
    tutorial._open_dialogue("intro");check(paused and not tutorial.opal.charge.held,"dialogue cancels immediately")
    var release:=InputEventKey.new();release.keycode=KEY_B;release.pressed=false;tutorial.opal.suppressed["key:%s" % KEY_B]=true;tutorial._input(release)
    check(not tutorial.opal.suppressed.has("key:%s" % KEY_B),"release in dialogue clears latch")
    paused=false;tutorial.dialogue_open=false;tutorial.dialogue_card.hide();dispose(tutorial)

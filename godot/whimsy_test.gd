extends SceneTree
## New decoration must stay separate from combat, saving and input authority.
var checks := 0
var failures := 0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,note: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error("WHIMSY: "+note)
func frames(n:=3) -> void:
    for i in range(n):await process_frame
func run() -> void:
    root.size=Vector2i(1400,960)
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false
    var catalog=root.get_node("AdventureRun");catalog.active=false
    var anchors: Array[float]=[6350,6200,14500,5000,17000,29500,4300,1500]
    var themes: Array[String]=[]
    for index in range(8):
        var level=load(catalog.SCENES[index]).instantiate();root.add_child(level)
        level.set_process(false);level.set_physics_process(false);await frames()
        if index==7:level.dialogue_open=false;level.dialogue_card.hide();level.choice_card.hide();paused=false
        var garden=level.whimsy_garden;var moments=level.whimsy_moments
        check(garden!=null and moments!=null,"both flourishes in chapter "+str(index))
        check(not garden.is_processing() and not moments.is_processing(),"host owns flourish timing")
        level.fallen=true;level.boss_hp=0;level.player=Vector2(anchors[index],620);level.camera=anchors[index]-550
        for enemy in level.enemies:enemy["hp"]=0
        level._sync_native_visuals()
        check(garden.active and moments.active and garden.visible,"quiet chapter decorations visible")
        check(garden.station_count>0 and garden.station_count<=4,"bounded visible gardens")
        themes.append(garden.THEMES[garden.chapter])
        var objects: int=Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
        var points: int=level.score;var hp: int=level.health;var hero: Vector2=level.player
        for i in range(120):
            garden.advance(1.0/60);moments.advance(1.0/60)
            moments.celebrate(hero,"pearl");moments.celebrate(hero,"treasure")
        check(level.score==points and level.health==hp and level.player==hero,"flourishes never change gameplay state")
        check(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)==objects,"animation creates no nodes")
        check(moments.pool.size()==12 and moments.live_count()<=12,"fixed transient pool")
        var before: int=moments.spawned_total
        moments.celebrate(hero,"impact");moments.celebrate(hero,"boss_hit");moments.celebrate(hero,"unknown")
        check(moments.spawned_total==before,"negative and unknown events have no flourish")
        moments.clear();level._award("whimsy-once","Pearls",10,hero,true)
        before=moments.spawned_total;level._award("whimsy-once","Pearls",10,hero,true)
        check(moments.spawned_total==before,"duplicate awards cannot replay celebration")
        level.enemies.append({"kind":"crab","hp":1,"x":hero.x+100,"y":hero.y,"mode":"windup"})
        level._sync_native_visuals()
        check(garden.combat and moments.combat and moments.live_count()==0,"ordinary windup quiets new decoration")
        before=moments.spawned_total;moments.celebrate(hero,"treasure")
        check(moments.spawned_total==before,"no new distracting celebrations during combat")
        moments.celebrate(hero,"boss_defeat")
        check(moments.live_count()==1,"boss payoff remains available")
        level.enemies.pop_back();level.reduced_fx=true;level._sync_native_visuals()
        var clock: float=garden.clock;var moment_clock: float=moments.clock
        garden.advance(.5);moments.advance(.5)
        check(garden.clock==clock and moments.clock==moment_clock,"Gentle Motion freezes decorative motion")
        moments.clear();moments.celebrate(hero,"heart")
        check(moments.live_count()==1,"Gentle Motion retains a short static positive cue")
        moments.advance(.4);check(moments.live_count()==0,"Gentle Motion cue expires promptly")
        level.high_depth_quality=false;level._sync_native_visuals()
        check(garden.station_count<=2 and garden.economy and moments.economy,"Economy bounds gardens and moments")
        level.waterfall_phase="descent";level._sync_native_visuals()
        check(not garden.visible and not moments.visible and moments.live_count()==0,"waterfall hides and clears both layers")
        level.waterfall_phase="";level.reduced_fx=false;level.high_depth_quality=true;level._sync_native_visuals()
        moments.celebrate(hero,"treasure")
        level._reset_transients()
        check(moments.live_count()==0 and garden.clock==0,"retry clears flourishes")
        level._sync_native_visuals();level.state="paused";paused=true
        clock=garden.clock;moment_clock=moments.clock;level._physics_process(.5)
        check(garden.clock==clock and moments.clock==moment_clock,"pause cannot advance either layer")
        paused=false;level.free();await frames()
    check(themes.size()==8 and themes.all(func(theme):return themes.count(theme)==1),"all eight chapter motifs are distinct")
    # Idle delight needs real stillness; never repeat each frame or during Gentle Motion.
    var fx=preload("res://godot/whimsy_moments.gd").new();root.add_child(fx)
    fx.set_world(0,310,Vector2(500,600),0,false,false,true,false)
    for i in range(10):fx.advance(1)
    check(fx.spawned_total==1,"one stillness delight after sustained rest")
    for i in range(3):fx.advance(1)
    check(fx.spawned_total==1,"stillness delight has a long rest")
    fx.clear();fx.set_world(0,310,Vector2(500,600),0,true,false,true,false)
    var total: int=fx.spawned_total
    for i in range(20):fx.advance(1)
    check(fx.spawned_total==total,"no automatic motion in Gentle Motion")
    fx.free()
    print("WHIMSY: ",checks," checks, ",failures," failures");quit(1 if failures else 0)

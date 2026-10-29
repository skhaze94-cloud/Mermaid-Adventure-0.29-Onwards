extends "res://godot/opal_current_test.gd"
## Live encounter safety, truthful warning geometry and actual clear feedback.
func run() -> void:
    var prefs=root.get_node("AppPreferences")
    prefs.persist_enabled=false;prefs.intro_seen=true
    var audio=root.get_node("OceanAudio");audio.playback_enabled=false
    var paths=root.get_node("AdventureRun").SCENES
    var level=create(paths[0]);await process_frame
    clean(level);level.boss_hp=3;level.boss_pattern=1;level.boss_phase="windup";level.boss_phase_time=0
    level.player=Vector2(level._boss_home()-500,600);level.boss_position=Vector2(level._boss_home(),570)
    level._update_boss(1.05)
    check(level.hostile_shots.is_empty() and level.boss_phase=="windup","Carlo gives a full introductory warning")
    level._update_boss(.06)
    check(level.hostile_shots.size()==3 and level.boss_phase=="attack","Carlo fan remains bounded")
    level._update_boss(.66);level._update_boss(2.2)
    check(level.boss_phase=="recover","Carlo opening leaves charge and travel time")
    level.boss_hit_cooldown=.5
    check(level._boss_attack_hint().contains("wait"),"hit cooldown does not invite an ignored attack")
    level.boss_hit_cooldown=0;level.bubble_unlocked=false;level.energy=0;level.boost_time=0
    check(level._boss_attack_hint().contains("refill"),"intro teaches energy recovery when Boost is unavailable")
    dispose(level)
    for index in [1,2]:
        level=create(paths[index]);await process_frame;clean(level)
        level.boss_hp=12
        if index==1:level.duke_hp=6;level.flip_hp=6;level.combo_clock=0
        level.player=Vector2(level._boss_home()-500,600);level.boss_clock=1;level.boss_shot_clock=1.2
        level._update_boss(0)
        var locked: Array=level.boss_volley.pending.duplicate(true)
        check(locked.size()==3 and level.hostile_shots.is_empty(),"journey volley is warned before firing")
        level._update_boss(.3)
        check(level.hostile_shots.is_empty(),"journey warning grants reaction time")
        level.player.y+=150;level._update_boss(.26)
        check(level.hostile_shots.size()==3,"journey warning releases at most three shots")
        for i in range(3):
            check(level.hostile_shots[i]["pos"]==locked[i]["pos"],"launch point matches world warning")
            check(Vector2(level.hostile_shots[i]["velocity"]).normalized().is_equal_approx(locked[i]["direction"]),"aim remains locked after Sarah dodges")
        level.boss_clock=3.3 if index==1 else 4.2
        check(level._boss_vulnerable(),"journey recovery opens at its advertised boundary")
        var clock: float=level.boss_clock;var score: int=level.score
        level._opal_hit_boss("duke" if index==1 else "miguel",1)
        check(level.score>score,"bubble boss hit earns its owned reward")
        if index==2:check(level.boss_clock==clock,"Miguel keeps his recovery window after a successful hit")
        if index==1:
            level.duke_hp=0;level.flip_hp=4;level.boss_hp=4;level.boss_hit_cooldown=0;level.boss_clock=1
            check(level._boss_vulnerable(),"Flip-only HUD matches his always-open shell")
            check(level._boss_attack_hint().contains("encore"),"surviving duo partner gets his own guidance")
        level.player.x=0;level._update_boss(.1)
        check(level.boss_volley.pending.is_empty() and level.boss_clock==0,"retreat cancels stale attacks and restarts warning")
        dispose(level)
    for index in [3,4,5,6]:
        level=create(paths[index]);await process_frame;clean(level);level.boss_hp=6
        level.player=Vector2(level._boss_home()-500,600);level.camera=level._boss_home()-900
        level.boss_clock=1.35;level.attack_clock=1.2;level._update_boss(0)
        var origin: Vector2=level.volley_origin
        var locked: Array=level.pending_volley.duplicate(true)
        check(locked.size()==3,"signature has three bounded warning lanes")
        level._update_boss(.3)
        check(level.hostile_shots.is_empty(),"signature does not fire during its warning")
        level.player.y+=100;level._update_boss(.19)
        check(level.hostile_shots.size()==3,"signature fires after its warning")
        for i in range(3):check(level.hostile_shots[i]["pos"]==origin+Vector2(locked[i]["offset"]),"moving boss fires from the point it warned")
        if index==5:
            level._spawn_hostile(level.boss_position,Vector2.LEFT,100,"puffer")
            level.boss_clock=2.4;level._update_boss(0)
            check(level.pending_volley.is_empty() and level.hostile_shots.size()==1 and level.hostile_shots[0]["style"]=="puffer","Rana clears her own volley for the laser, preserving unrelated enemies")
        level.player.x=0;level._update_boss(.1)
        check(level.pending_volley.is_empty() and level.boss_clock==0,"signature retreat cannot leave an immediate attack")
        dispose(level)
    level=create(paths[6]);await process_frame;clean(level)
    level.boss_hp=1;level.boss_clock=4.2;level.boss_position=Vector2(level._boss_home(),570)
    level.player=level.boss_position-Vector2(400,0);level.camera=level._boss_home()-900
    level._sync_native_visuals();level.energy=0;level.invulnerable=0
    audio.last_played.clear();var clears: int=audio.events.get("boss_defeat",0)
    level._spawn_hostile(level.player,Vector2.LEFT,100)
    check(level._opal_hit_boss("nessie",2)==1,"final boss still caps damage at remaining HP")
    level._sync_native_visuals()
    check(level.hostile_shots.is_empty() and level.energy==1 and level.invulnerable>=1.2,"clear gives a safe celebratory exit")
    check(audio.events.get("boss_defeat",0)==clears+1,"clear uses its victory audio")
    check(level.premium_hud.banner_label.text=="BOSS CLEAR!","clear banner immediately overrides the preceding hit reward")
    check(level.premium_hud.floating.filter(func(label):return label.visible).size()==1,"clear bonus replaces overlapping last-hit numbers")
    check(level.performance.visible and level.performance.defeat_age>=0,"defeated portrait gets its authored fade")
    check(level.performance.pose=="recover","defeat settles the portrait instead of continuing attack gestures")
    level._opal_hit_boss("nessie",2)
    check(audio.events.get("boss_defeat",0)==clears+1,"clear feedback cannot repeat")
    dispose(level)
    level=create(paths[7]);await process_frame
    audio.last_played.clear();clears=audio.events.get("boss_defeat",0)
    level._award("training:dad:clear","Boss",600,level.boss_position,false)
    check(audio.events.get("boss_defeat",0)==clears+1,"600-point royal trial clear is a defeat, not a hit sound")
    dispose(level)
    print("BOSS POLISH: ",checks," checks, ",failures," failures")
    quit(1 if failures else 0)

extends "res://godot/opal_current_test.gd"
const Pocket=preload("res://godot/pocket_wonders_reactions.gd")
const Baby=preload("res://godot/avina_companion.gd")
func step(game,level,seconds: float) -> void:
    for tick in range(ceili(seconds*60)):
        game.advance(1.0/60)
        level.native_rig.gesture_player.advance(1.0/60)
        level.native_rig._process(1.0/60)
        if is_instance_valid(level.avina):level.avina.tick(1.0/60)
func reset(game,level) -> void:
    paused=false;level.state="playing";level.waterfall_phase="";level.boost_time=0;level.leap_phase=""
    level.player=Vector2(500,600);level.player_velocity=Vector2.ZERO;level.camera=0;level.touch_vectors.clear()
    level.opal.cancel();level.living_reef.reactions.clear()
    game.clear();level.native_rig.reset_performance();level.native_rig.set_motion(Vector2.ZERO,1,false,false,1)
    level.native_rig._process(1.0/60)
    if is_instance_valid(level.avina):level.avina.reset_follow()
func run() -> void:
    root.size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
    root.get_node("AppPreferences").persist_enabled=false;root.get_node("OceanAudio").playback_enabled=false
    var level=create("res://godot/highland_level.tscn");clean(level);level.native_rig.set_process(false)
    var game=Pocket.new();game.bind(level);reset(game,level)
    var at:=Vector2(650,535)
    var registration: Vector2=level.native_rig.face_sprite.position
    var before: Array=[level.player,level.player_velocity,level.score,level.health,level.energy,level.boss_hp,level.bubble_shots.size()]
    check(not game.play("unknown",at) and not game.play("bubble_game",Vector2(1400,535)),"unknown and distant bubble games stay quiet")
    check(game.play("bubble_game",at),"an idle nearby solo game can begin")
    var view: Dictionary=game.snapshot()
    check(view["active"] and view["partner"]=="fish" and view["phase"]==0,"solo Sarah receives a friendly fish partner")
    check(game.finished_serial==0 and not game.play("bubble_game",at),"starting or replaying an active game cannot claim completion")
    step(game,level,.84);view=game.snapshot()
    check(view["phase"]==1 and view["bubble_owner"]=="sarah" and view["phase_progress"]>=0,"Sarah sends a purely decorative first bubble")
    check(level.native_rig.discovery_joy>0 and level.native_rig.discovery_gaze.length()>0,"existing painted face visibly eases into smile and interest")
    step(game,level,1.12);view=game.snapshot()
    check(view["phase"]==2 and view["bubble_owner"]=="fish","solo fish echoes the bubble without requiring Avina")
    step(game,level,1.27);view=game.snapshot()
    check(view["phase"]==3 and view["bubble_owner"]=="sarah","Sarah copies the friendly echo")
    step(game,level,1.12);view=game.snapshot()
    check(view["phase"]==4 and view["fish_mood"]=="surprised" and view["bubble_owner"]=="passing_fish","a passing fish supplies the surprise beat")
    step(game,level,1.07);view=game.snapshot()
    check(view["phase"]==5 and view["fish_mood"]=="happy","surprise resolves to the quiet shared laugh")
    step(game,level,1.05)
    check(not game.active and game.finished_serial==1,"only all six finished beats increment the completion serial")
    game.advance(20);game.clear()
    check(game.finished_serial==1,"idle advance and clear never manufacture or erase completion")
    check(before==[level.player,level.player_velocity,level.score,level.health,level.energy,level.boss_hp,level.bubble_shots.size()],"bubble pantomime changes no movement, score, damage or combat projectile state")
    check(level.native_rig.face_sprite.position==registration,"expressions retain the original face registration")
    var baby=Baby.new();level.add_child(baby);baby.bind(level);level.avina=baby
    reset(game,level);check(game.play("bubble_game",at),"an available baby can join the game")
    check(game.snapshot()["partner"]=="avina","only the actual visible following Avina becomes the partner")
    step(game,level,2.0)
    check(baby.discovery_speech and baby.speech=="Mo’!" and baby.discovery_reaction>0,"Avina responds to the echo with existing protected joy and baby language")
    check(not baby.bubble_pending and baby.bubbles_cast==0 and level.bubble_shots.is_empty(),"Avina's pretend bubble never requests or fires a gameplay bubble")
    reset(game,level);baby.bubble_pending=true
    check(not game.play("bubble_game",at) and baby.bubble_pending,"a real pending baby bubble keeps priority and is not consumed")
    baby.bubble_pending=false;baby.follow_enabled=false
    check(game.play("bubble_game",at) and game.snapshot()["partner"]=="fish","the game remains available when Avina stays with her family")
    baby.follow_enabled=true
    for action in ["boost","cast","impact","charge","leap","input","pause","loading","victory","away"]:
        reset(game,level);game.play("bubble_game",at);var finished: int=game.finished_serial
        match action:
            "boost":level.boost_time=.3;level.native_rig.set_motion(Vector2(760,0),1,true,false,1)
            "cast":level.native_rig.play_gesture("cast")
            "impact":level.native_rig.play_impact()
            "charge":level.opal.begin("script")
            "leap":level.leap_phase="airborne"
            "input":level.touch_vectors[91]=Vector2.RIGHT
            "pause":paused=true
            "loading":root.get_node("SceneFlow").busy=true
            "victory":level.state="victory"
            "away":level.player.x+=700
        game.advance(.02)
        check(not game.active and game.finished_serial==finished,"leaving or protected action cancels the game: "+action)
        if action=="cast":check(level.native_rig.last_gesture=="cast" and level.native_rig.gesture_player.is_playing(),"cleanup never stops the user's actual cast")
        if action=="charge":check(level.opal.charge.held,"cleanup never releases or cancels actual held input")
        if action=="input":check(level.touch_vectors.has(91),"movement input remains owned by the player")
        paused=false;root.get_node("SceneFlow").busy=false
    reset(game,level);game.play("bubble_game",at);level.retry_serial+=1;game.advance(.01)
    check(not game.active and game.finished_serial==1,"retry clears only transient game state")
    reset(game,level);game.play("bubble_game",at)
    level.living_reef.reactions.react("discovery",Vector2(760,490))
    var story_goal: Vector2=level.native_rig.discovery_focus_goal
    game.advance(.01);game.clear()
    check(not game.active and level.living_reef.reactions.focus_left>0 and level.native_rig.discovery_focus_goal==story_goal,"a Living Reef story supersedes the game without its new focus being erased")
    reset(game,level);level.reduced_fx=true;level.native_rig.reduced_motion=true
    game.play("bubble_game",at);step(game,level,2.14)
    check(game.phase==2 and game.snapshot()["gentle"],"Gentle Motion retains the same six story beats")
    check(level.native_rig.discovery_gaze==Vector2.ZERO and not level.native_rig.discovery_gesture and level.native_rig.discovery_joy>0,"Gentle acknowledgements use static painted expressions without extra gaze or waves")
    check(baby.discovery_speech and baby.discovery_reaction==0,"Gentle baby text adds no joy rocking")
    step(game,level,4.2)
    check(not game.active and game.finished_serial==2,"Gentle players can finish the whole bubble story")
    level.reduced_fx=false;level.native_rig.reduced_motion=false
    for request in ["delight","discovery","tea","village","post","dream"]:
        reset(game,level)
        check(game.play(request,at),"a short contextual greeting can begin: "+request)
        step(game,level,1.2)
        check(not game.active and game.finished_serial==2,"short greetings never claim a six-beat game reward: "+request)
    reset(game,level);game.play("tea",at);step(game,level,1.2)
    check(game.cooldown<=2.0,"a short greeting has a short replay delay instead of the full bubble game's twelve seconds")
    game.advance(1.7)
    check(game.play("bubble_game",at),"a finished short greeting allows a nearby mirror game promptly")
    game.clear()
    var family=create("res://godot/training_lagoon.tscn");clean(family)
    family.native_rig.set_process(false);family.dialogue_open=false;family.dialogue_card.hide();family.choice_card.hide();paused=false
    var family_game=Pocket.new();family_game.bind(family);reset(family_game,family)
    check(not family_game.play("bubble_game",at),"the game never distracts from the required opening lessons")
    family.lesson=10;family.boss_hp=0;family.playing_daddy=true
    check(not family_game.play("bubble_game",at) and family.playing_daddy,"the game never changes the chosen King Daddy role")
    family.playing_daddy=false;family.dialogue_open=true
    check(not family_game.play("bubble_game",at),"family conversations retain priority")
    family.dialogue_open=false;family.choice_card.show()
    check(not family_game.play("bubble_game",at),"the companion choice is not bypassed or forced")
    family.choice_card.hide();family_game.clear();game.clear();dispose(family);dispose(level)
    print("POCKET WONDERS REACTIONS: ",checks," checks, ",failures," failures")
    quit(1 if failures else 0)

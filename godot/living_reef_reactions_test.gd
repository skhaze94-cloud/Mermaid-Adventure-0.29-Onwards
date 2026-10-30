extends "res://godot/opal_current_test.gd"
const Reactions=preload("res://godot/living_reef_reactions.gd")
const Baby=preload("res://godot/avina_companion.gd")
func run() -> void:
    root.size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
    root.get_node("AppPreferences").persist_enabled=false
    root.get_node("OceanAudio").playback_enabled=false
    var level=create("res://godot/highland_level.tscn");clean(level)
    level.player=Vector2(500,600);level.camera=0;level.player_velocity=Vector2.ZERO
    var rig=level.native_rig;rig.set_process(false);rig.reset_performance()
    rig.set_motion(Vector2.ZERO,1,false,false,1)
    var baby=Baby.new();level.add_child(baby);baby.bind(level);level.avina=baby
    var reactions=Reactions.new();reactions.bind(level)
    var target:=Vector2(700,510)
    rig._process(1.0/60) # Settle the existing registered tail position before comparison.
    var face_origin: Vector2=rig.face_sprite.position
    var tail_origin: Vector2=rig.tail_skin.position
    var before: Array=[level.score,level.health,level.energy,level.player,level.boss_hp,level.bubble_shots.size(),baby.bubbles_cast,baby.bubble_pending]
    reactions.react("discovery",target)
    check(reactions.accepted_count==1 and reactions.active_kind=="discovery","nearby reef interest can receive one response")
    check(rig.discovery_focus_goal.x>0 and rig.discovery_focus_goal.y<0,"Sarah looks toward the actual point of interest")
    check(rig.discovery_gesture and rig.last_gesture=="greet","discovery reuses the existing gentle greeting")
    check(baby.discovery_speech and baby.speech=="Oooh!","protected companion responds in short baby language")
    baby.tick(.1)
    check(not baby.bubble_pending and baby.bubbles_cast==0,"baby discovery joy never requests a new gameplay action")
    reactions.react("discovery",target)
    check(reactions.accepted_count==1,"repeated discoveries respect the shared cooldown")
    for i in range(30):rig._process(1.0/60)
    check(rig.discovery_gaze.x>0 and rig.discovery_joy>0 and rig.detail_gaze.length()<=1.001,"face response eases within the registered gaze limits")
    check(rig.face_sprite.position==face_origin and rig.tail_skin.position==tail_origin,"expressions do not change painted registration or anchors")
    rig.gesture_player.stop();rig._clear_gesture_values();rig.last_gesture=""
    reactions.advance(2)
    var gaze: Vector2=rig.discovery_gaze
    check(rig.discovery_focus_goal==Vector2.ZERO and reactions.active_kind=="","expiry releases the discovery gaze goal")
    rig._process(1.0/60)
    check(rig.discovery_gaze.length()<gaze.length() and rig.discovery_gaze.length()>0,"normal expiry returns gaze smoothly rather than snapping")
    for i in range(120):rig._process(1.0/60)
    check(rig.discovery_gaze.length()<.002 and rig.discovery_joy<.002,"face returns to its ordinary swimming response")
    reactions.clear();rig.reset_performance()
    reactions.react("note",target)
    check(rig.last_gesture=="reward" and baby.speech=="Ting!","a musical note reuses reward motion and a tiny babble")
    rig.play_gesture("cast");reactions.advance(.01)
    check(rig.last_gesture=="cast" and rig.gesture_player.is_playing() and rig.discovery_focus_goal==Vector2.ZERO,"a cast supersedes discovery without being interrupted by cleanup")
    var accepted: int=reactions.accepted_count
    reactions.react("help",target)
    check(reactions.accepted_count==accepted,"discovery cannot interrupt an active cast")
    reactions.clear();rig.reset_performance();rig.set_motion(Vector2(760,0),1,true,false,1);level.boost_time=.2
    reactions.react("help",target)
    check(reactions.focus_left==0 and not rig.discovery_gesture,"boost keeps its authored action priority")
    level.boost_time=0;rig.set_motion(Vector2.ZERO,1,false,true,1);level.leap_phase="airborne"
    reactions.react("help",target)
    check(reactions.focus_left==0,"airborne performance cannot be interrupted")
    level.leap_phase="";rig.set_motion(Vector2.ZERO,1,false,false,1);rig.play_impact()
    reactions.react("progress",target)
    check(reactions.focus_left==0 and rig.last_gesture=="impact","impact reaction keeps priority")
    rig.reset_performance();rig.bubble_hold_goal=1
    reactions.react("progress",target)
    check(reactions.focus_left==0,"a held charge cannot be interrupted")
    rig.reset_performance();level.boss_hp=3;level.player=Vector2(level._boss_home()-300,600);level.camera=level.player.x-500
    reactions.react("help",level.player+Vector2(100,-50))
    check(reactions.focus_left==0,"live boss encounter suppresses optional reef reactions")
    level.boss_hp=0;level.player=Vector2(500,600);level.camera=0
    reactions.react("help",Vector2(1900,500));reactions.react("help",Vector2(-10,500))
    check(reactions.focus_left==0,"distant and offscreen events remain quiet")
    level.reduced_fx=true;rig.reduced_motion=true
    reactions.react("complete",target);rig.set_discovery_focus(Vector2(100,-100),.5)
    check(reactions.active_kind=="complete" and rig.discovery_focus_goal==Vector2.ZERO and not rig.discovery_gesture,"Gentle Motion uses a static painted smile without extra gaze or waving")
    rig._process(.05)
    check(rig.discovery_joy>0 and rig.discovery_gaze==Vector2.ZERO,"Gentle smile changes the painting without moving geometry")
    check(baby.discovery_speech and baby.discovery_reaction==0,"Gentle baby acknowledgement has no new rocking or paddling")
    level.reduced_fx=false;rig.reduced_motion=false;rig.reset_performance()
    reactions.react("progress",target);paused=true;reactions.advance(.01)
    check(reactions.focus_left==0 and rig.discovery_focus_goal==Vector2.ZERO and not baby.discovery_speech,"pause cancels optional face and baby reactions")
    paused=false;rig.reset_performance();reactions.react("complete",target);level.retry_serial+=1;reactions.advance(.01)
    check(reactions.focus_left==0 and not rig.discovery_gesture and baby.discovery_reaction==0,"retry clears the complete response")
    reactions.react("help",target);reactions.clear()
    check(not rig.discovery_gesture and rig.discovery_joy==0,"explicit cleanup cancels only the owned greeting")
    rig.reset_performance();rig.set_motion(Vector2(760,0),1,true,false,1);level.boost_time=.2
    accepted=reactions.accepted_count;reactions.react("complete",target)
    check(reactions.pending_complete_left==2 and reactions.accepted_count==accepted,"a Boost completion waits in one bounded slot")
    reactions.advance(.15);check(reactions.focus_left==0,"queued completion does not interrupt Boost")
    level.boost_time=0;rig.set_motion(Vector2.ZERO,1,false,false,1);reactions.advance(.2)
    check(reactions.active_kind=="complete" and reactions.accepted_count==accepted+1 and reactions.pending_complete_left==0,"completion celebrates immediately after the protected action ends")
    reactions.clear();rig.reset_performance();rig.bubble_hold_goal=1;accepted=reactions.accepted_count
    reactions.react("complete",target);reactions.advance(1.0);reactions.react("complete",target)
    check(reactions.pending_complete_left<=1.0,"repeated completion notifications cannot extend the pending deadline")
    reactions.advance(1.1);rig.bubble_hold_goal=0;reactions.advance(.1)
    check(reactions.pending_complete_left==0 and reactions.accepted_count==accepted,"a completion held longer than two seconds expires instead of firing later")
    rig.set_motion(Vector2(760,0),1,true,false,1);level.boost_time=.2
    reactions.react("complete",target);level.retry_serial+=1;reactions.advance(.01)
    check(reactions.pending_complete_left==0,"retry cancels queued completion")
    reactions.react("complete",target);root.get_node("SceneFlow").busy=true;reactions.advance(.01)
    check(reactions.pending_complete_left==0,"scene loading cancels queued completion")
    root.get_node("SceneFlow").busy=false;reactions.react("complete",target)
    level.boss_hp=3;level.player=Vector2(level._boss_home()-300,600);reactions.advance(.01)
    check(reactions.pending_complete_left==0,"live combat cancels queued completion")
    level.boss_hp=0;level.player=Vector2(500,600);level.boost_time=0;rig.set_motion(Vector2.ZERO,-1,false,false,1)
    rig.set_discovery_focus(Vector2(200,-90),.4)
    check(rig.discovery_focus_goal.x<0,"gaze correctly mirrors into Sarah’s local coordinates when she faces left")
    rig.set_motion(Vector2.ZERO,1,false,false,1);reactions.clear()
    rig.reset_performance();reactions.react("note",target)
    accepted=reactions.accepted_count
    level.boost_time=.3;rig.set_motion(Vector2(760,0),1,true,false,1)
    reactions.react("complete",target);reactions.advance(.2)
    check(reactions.accepted_count==accepted and reactions.pending_complete_left>0,"the last choir note can queue completion while Boost remains protected")
    level.boost_time=0;rig.set_motion(Vector2.ZERO,1,false,false,1);reactions.advance(.2)
    check(reactions.accepted_count==accepted+1 and reactions.active_kind=="complete" and reactions.cooldown>0,"completion bypasses the ordinary note throttle after Boost ends within 0.4 seconds")
    reactions.react("complete",target)
    check(reactions.accepted_count==accepted+1 and reactions.pending_complete_left==0,"completion has a separate repeat guard and cannot replay the same gesture immediately")
    reactions.react("note",target)
    check(reactions.accepted_count==accepted+1,"completion priority does not permit ordinary note spam")
    reactions.clear();rig.reset_performance();reactions.react("note",target)
    accepted=reactions.accepted_count;rig.play_gesture("cast");reactions.react("complete",target);reactions.advance(.1)
    check(rig.last_gesture=="cast" and rig.gesture_player.is_playing() and reactions.accepted_count==accepted,"completion priority still cannot interrupt an authored cast")
    rig.gesture_player.advance(.3);reactions.advance(.1)
    check(reactions.accepted_count==accepted+1 and reactions.active_kind=="complete","queued completion starts after the cast finishes despite the earlier note cooldown")
    reactions.clear()
    baby.say("Sa-sa?",10);baby.discovery_cooldown=0
    check(not baby.react_to_discovery("help") and baby.speech=="Sa-sa?","reef chatter cannot replace existing family dialogue")
    baby.speech_time=0;baby.discovery_cooldown=0
    check(baby.react_to_discovery("complete") and not baby.react_to_discovery("complete"),"baby reactions have their own repeat limit")
    check(before==[level.score,level.health,level.energy,level.player,level.boss_hp,level.bubble_shots.size(),baby.bubbles_cast,baby.bubble_pending],"reef expressions never change gameplay state or request attacks")
    reactions.clear();dispose(level)
    print("LIVING REEF REACTIONS: ",checks," checks, ",failures," failures")
    quit(1 if failures else 0)

extends "res://godot/pocket_wonders_test.gd"
func tick(scene,seconds: float) -> void:
    for i in range(ceili(seconds*60)):
        scene.little_moments.advance(1.0/60);scene.little_moments.sync()
func run() -> void:
    root.get_node("AppPreferences").persist_enabled=false;root.get_node("AppPreferences").reduced_motion=false
    root.get_node("OceanAudio").playback_enabled=false;root.get_node("AdventureRun").active=false
    var scene=await create(0);scene.fallen=false;scene.player_velocity=Vector2.ZERO;scene.message_time=0
    scene.enemies.clear();scene.animated_enemies.bind_enemies(scene.enemies)
    var story=scene.little_moments
    var children: int=story.get_child_count()
    check(is_instance_valid(story),"opening Highland owns its scoped stories")
    check(scene.native_rig.z_index>scene.deep_routes.z_index,"the entire mermaid clears opaque cavern water")
    var score: int=scene.score
    scene.player=Vector2(1720,770);scene.living_shallows.sync();story.letter_phase=0;tick(scene,.2)
    check(story.letter_phase==1,"Nori notices an escaped letter")
    tick(scene,4.0);scene.player=story.letter_point;tick(scene,.1);check(story.letter_phase in [2,3],"Sarah catches the letter in a decorative bubble")
    scene.player=Vector2(1720,770);tick(scene,2)
    check(story._owned("letter"),"returning the letter earns one banked thank-you")
    scene.living_shallows.speech_clock=0;scene.living_shallows.line_key="";scene.living_shallows.cycle=8;scene.living_shallows.local_attention=1
    scene.living_shallows._update_speech()
    check(scene.living_shallows.line_key!="drop","the old postal vignette cannot announce a second lost letter")
    for i in range(3):scene.player=story.music_point+Vector2(-78+i*78,-125);tick(scene,1)
    check(story.music_notes==7 and story._owned("music"),"three distinct musical positions make a song")
    var ledger: Dictionary=scene.score_book.checkpoint().duplicate(true);score=scene.score
    paused=true;var time: float=story.clock;tick(scene,1);check(story.clock==time and not story.message_box.visible,"pause freezes stories and hides speech")
    paused=false;scene.retry_serial+=1;tick(scene,.1);check(story.letter_phase==4 and story._owned("letter"),"banked post survives retry and cannot start twice")
    scene.reduced_fx=true;story.sync();time=story.clock;tick(scene,1);check(story.clock==time,"Gentle Motion keeps decorative clocks still")
    check(scene.score==score and scene.score_book.checkpoint()==ledger,"quiet mode and retry do not duplicate rewards")
    check(story.get_child_count()==children,"all story nodes are constructed once")
    check(not story.fish.visible and not story.dozy.visible,"Highland does not clone tutorial characters")
    scene.fallen=true;story.sync();check(not story.visible,"stories stay out of the waterfall and later Highland")
    await dispose(scene)
    scene=await create(7);scene._close_dialogue();scene.set_process(false);scene.set_physics_process(false)
    scene.player_velocity=Vector2.ZERO;scene.message_time=0;scene.reduced_fx=false
    story=scene.little_moments;scene.player=story.fish_home;scene.camera=0;scene.native_rig.reset_performance();scene.native_rig.set_motion(Vector2.ZERO,1,false,false,1);story.sync()
    scene.boost_time=.4;tick(scene,1);check(story.fish_cooldown>0 and story.fish_trust==0,"boost startles fish without a penalty")
    scene.boost_time=0;tick(scene,7);check(story._owned("fish") and story.fish_friend.visible,"patience introduces a distinct fish friend")
    score=scene.score;tick(scene,5);check(scene.score==score,"fish cannot award repeatedly")
    scene.player=story.keeper_point-Vector2(0,50);scene.native_rig.reset_performance();tick(scene,3.5)
    check(story._owned("lantern"),"quiet lantern hello completes without combat or a timer")
    scene.neighbourhood_art.caption.show();story.sync()
    check(story.message_box.visible and not scene.neighbourhood_art.caption.visible,"one world caption owns the lantern greeting")
    var cue_size: Vector2=scene.lesson_card.size;scene.lesson_card.size.y=300;story.sync()
    var cue: Rect2=scene.premium_hud.to_game(Rect2(scene.lesson_card.position,scene.lesson_card.size))
    check(not story.message_box.visible or story.message_box.position.y-scene.deep_routes.camera_y>=cue.end.y+24,"ambient speech clears the tutorial cue at larger readable UI scales")
    scene.lesson_card.size=cue_size
    check(not story.music.visible and not story.post.visible,"tutorial does not clone Highland setpieces")
    scene.lesson=1;scene.arrival_time=0;scene.arrival_intro_pending=true
    scene.player=Vector2(1160,1450);scene._process(.5)
    check(scene.arrival_time==0 and not scene.dialogue_open,"Daddy's arrival waits while Sarah explores a cavern")
    scene.player=Vector2(850,580)
    for i in range(160):scene._process(1.0/60)
    check(scene.dialogue_open and scene.arrival_time>=2.6,"Daddy's welcome reaches its resting pose before conversation")
    check(not story.message_box.visible,"tutorial conversation immediately owns the screen over ambient speech")
    scene._close_dialogue();scene.lesson=6;scene.player=Vector2(5500,580);scene.camera=4900;scene._sync_native_visuals()
    check(absf(scene.king.position.x-(scene.player.x-scene.camera))>=280,"Daddy stays off Sarah's face in gift lesson")
    for lesson in range(11):
        scene.lesson=lesson;scene._show_lesson();scene._settle_lesson_size()
        await frames(3);scene._settle_lesson_size()
        check(scene.lesson_card.size.y<190,"lesson cue stays compact: "+str(lesson))
    await dispose(scene)
    print("LITTLE MOMENTS: ",checks," checks, ",failures," failures");quit(1 if failures else 0)

extends "res://godot/tools/little_moments_audit.gd"
func place(scene,at: Vector2) -> void:
    super.place(scene,at)
    scene._refresh_lesson_hint()
func run() -> void:
    DirAccess.make_dir_recursive_absolute(output);Engine.time_scale=0;root.size=Vector2i(1400,960)
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.reduced_motion=false;prefs.economy=false
    root.get_node("AdventureRun").active=false;root.get_node("AdventureRun").avina_along=false;root.get_node("OceanAudio").playback_enabled=false
    var scene=load("res://godot/training_lagoon.tscn").instantiate();root.add_child(scene);scene.music_player.stop();scene.music_player.stream=null
    await frame();await frame();scene.set_process(false);scene.set_physics_process(false);scene.native_rig.set_process(false);scene._close_dialogue();scene.lesson=1;scene.arrival_time=2.6;scene._show_lesson()
    scene.message_time=0;scene.enemies.clear();scene.animated_enemies.bind_enemies(scene.enemies)
    place(scene,Vector2(910,1370));scene.neighbourhood.clock=7;scene.neighbourhood.quiet=false;scene.neighbourhood_art.sync();await capture("nursery-open-water")
    for index in range(2):
        var person: Dictionary=scene.neighbourhood.profile["people"][index]
        place(scene,person["talk_at"]+Vector2(155 if index==0 else -155,-25));scene.neighbourhood._speak(index,person["lines"][0]);scene.neighbourhood.quiet=false;scene.neighbourhood_art.sync();await capture("resident-"+str(index)+"-hello")
        scene.neighbourhood.chat_left=.01;scene.neighbourhood.advance(.02);scene.neighbourhood_art.sync();await capture("resident-"+str(index)+"-sarah")
    place(scene,scene.little_moments.keeper_point-Vector2(0,50));settle(scene,3.5);await capture("bellflower-dozy")
    settle(scene,3);await capture("bellflower-sarah")
    place(scene,Vector2(850,580));scene.lesson=1;scene.arrival_time=2.6;scene._show_lesson()
    for i in range(90):scene.time+=1.0/60;scene.character_dt=1.0/60;scene._sync_native_visuals()
    await capture("daddy-adult-scale")
    place(scene,Vector2(5500,580));scene.lesson=6;scene._show_lesson();scene.queen_demo=3
    for i in range(90):scene.time+=1.0/60;scene.character_dt=1.0/60;scene._sync_native_visuals()
    await capture("parents-gift-scale")
    root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(844,390)
    for i in range(4):await frame()
    scene.simulated_touch=true;scene._on_viewport_resized();scene.lesson=1;scene._show_lesson()
    place(scene,Vector2(910,1370));scene.neighbourhood.suspend();scene.neighbourhood_art.sync();await capture("phone-nursery")
    place(scene,scene.little_moments.keeper_point-Vector2(0,50));scene.little_moments.speech_key=""
    if scene.little_moments.get("lantern_conversation")!=null:scene.little_moments.lantern_conversation=0
    settle(scene,1);await capture("phone-bellflower")
    scene.free();await frame();await frame();print("TUTORIAL25 AUDIT COMPLETE");quit()

extends "res://godot/tools/little_moments_audit.gd"
func run() -> void:
    DirAccess.make_dir_recursive_absolute(output);Engine.time_scale=0
    root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.reduced_motion=false;prefs.economy=false
    root.get_node("AdventureRun").active=false;root.get_node("AdventureRun").avina_along=false;root.get_node("OceanAudio").playback_enabled=false
    for stage in [7,0]:
        var scene=load("res://godot/training_lagoon.tscn" if stage==7 else "res://godot/highland_level.tscn").instantiate()
        root.add_child(scene);scene.music_player.stop();scene.music_player.stream=null;await frame();await frame()
        scene.set_process(false);scene.set_physics_process(false);scene.native_rig.set_process(false)
        scene.enemies.clear();scene.animated_enemies.bind_enemies(scene.enemies);scene.fallen=false
        if stage==7:scene._close_dialogue();scene.lesson=0;scene.arrival_time=2.6;scene._show_lesson()
        for dimensions in [Vector2i(844,390),Vector2i(1024,768)]:
            root.size=dimensions
            for i in range(4):await frame()
            scene.simulated_touch=true;scene._on_viewport_resized()
            var targets=[scene.little_moments.fish_home,scene.little_moments.keeper_point-Vector2(0,60)] if stage==7 else [Vector2(1720,630),scene.little_moments.music_point+Vector2(0,-125)]
            for i in range(targets.size()):
                place(scene,targets[i]);settle(scene,4)
                await capture("phone-"+str(dimensions.x)+"-"+str(stage)+"-"+str(i))
            scene.reduced_fx=true;scene.little_moments.sync();await capture("phone-"+str(dimensions.x)+"-"+str(stage)+"-gentle");scene.reduced_fx=false
        scene.free();await frame();await frame()
    print("LITTLE MOMENTS PHONE AUDIT complete");quit()

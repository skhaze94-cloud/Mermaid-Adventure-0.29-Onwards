extends "res://godot/tools/pearl38/capture.gd"
## Eight-second staged UI review, 24 fps. Actual HUD, charge controller, royal gift timer
## and conversation callbacks. Player placement is held; this is not a playthrough/FPS test.
var movie_output:=OS.get_environment("PEARL_MOVIE_DIR")
func run() -> void:
    if movie_output.is_empty():push_error("PEARL_MOVIE_DIR required");quit(1);return
    DirAccess.make_dir_recursive_absolute(movie_output)
    root.size=Vector2i(1280,720);root.content_scale_size=Vector2i(1400,960)
    root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true;prefs.economy=false;prefs.reduced_motion=false
    root.get_node("AdventureRun").persist_enabled=false;root.get_node("AdventureRun").active=false;root.get_node("OceanAudio").playback_enabled=false
    var scene=load("res://godot/training_lagoon.tscn").instantiate();root.add_child(scene)
    for i in range(6):await frame()
    scene.music_player.stop();scene.music_player.stream=null;scene.set_process(false);scene.set_physics_process(false)
    scene.native_rig.set_process(false);scene.king.set_process(false);scene.queen_teacher.set_process(false);scene.premium_hud.set_process(false)
    Engine.time_scale=0;scene.simulated_touch=true;scene._on_viewport_resized();scene._layout_tutorial();stage(scene)
    scene.lesson=10;scene.bubble_unlocked=true;scene._show_lesson();scene._layout_tutorial()
    var hud=scene.premium_hud
    var cast_began:=false;var cast_released:=false
    for index in range(192):
        var dt:=1.0/24.0
        match index:
            24:scene.health=3
            48:scene.health=5;scene.gift_time=8.0
            60:cast_began=scene.opal.begin("pearl-ui-movie")
            96:cast_released=scene.opal.release("pearl-ui-movie")
            102:hud.show_reward({"category":"Secrets","points":50,"extra":0,"multiplier":1},scene.player-Vector2(scene.camera,0))
            130:scene._open_dialogue("intro")
            138:scene._advance_speech()
            145:scene._advance_speech()
            152:scene._toggle_replies()
            182:scene._close_dialogue()
        # Advance production owners exactly once per captured interval.
        scene._process(dt)
        if not paused:
            scene.opal.advance(dt);scene.opal.update_friendly(dt);scene.opal_fx.advance(dt)
            hud.update_hud(scene._hud_snapshot());hud._process(dt)
        else:
            var speaker: String=scene.speech_beats[scene.speech_index]["speaker"] if not scene.speech_beats.is_empty() else ""
            scene.king._advance(dt,"talk" if speaker=="king" else "listen",false)
            scene.queen_teacher._advance(dt,"talk" if speaker=="queen" else "listen",false)
        for tween in get_processed_tweens():
            if is_instance_valid(tween):tween.custom_step(dt)
        scene._layout_tutorial();scene.queue_redraw()
        await frame()
        var image:=root.get_texture().get_image()
        image.save_jpg(movie_output+"/ui_%03d.jpg"%index,.94)
        if index in [0,24,48,80,96,110,145,170]:image.save_png(movie_output+"/key_%03d.png"%index)
    var file:=FileAccess.open(movie_output+"/movie-report.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"type":"staged native UI review; held player placement, not a full playthrough or device FPS test","frames":192,"fps":24,"seconds":8,"resolution":"1280x720","actual_charge_begin":cast_began,"actual_charge_release":cast_released,"gift_duration":8,"key_frames":[0,24,48,80,96,110,145,170]},"  "));file.close()
    scene.free();paused=false;Engine.time_scale=1
    print("PEARL UI MOVIE: 192 native frames, charge begin=",cast_began," release=",cast_released)
    quit(0 if cast_began and cast_released else 1)

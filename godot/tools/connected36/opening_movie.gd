extends SceneTree
var output:=OS.get_environment("OPENING36_OUT")
func _initialize() -> void:call_deferred("run")
func frame() -> void:await process_frame;await RenderingServer.frame_post_draw
func run() -> void:
    root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(1120,768)
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true;prefs.economy=false;prefs.reduced_motion=false
    root.get_node("AdventureRun").persist_enabled=false;root.get_node("AdventureRun").active=false;root.get_node("OceanAudio").playback_enabled=false
    var menu=load("res://godot/title_screen.tscn").instantiate();root.add_child(menu)
    for i in range(5):await frame()
    menu.set_process(false);menu.hero_rig.set_process(false);menu.hero_rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    menu.hero_performance.reset();menu.hero_rig.reset_performance();Engine.time_scale=0
    for i in range(72):
        for tick in range(2):
            menu.hero_performance.update(menu,1.0/24)
            for tween in get_processed_tweens():
                if is_instance_valid(tween):tween.custom_step(1.0/24)
        await frame();root.get_texture().get_image().save_jpg(output+"/opening_%03d.jpg" % i,.94)
    menu.free();await frame();print("OPENING36 MOVIE:6sec actual authored performance,12fpscapture");quit()

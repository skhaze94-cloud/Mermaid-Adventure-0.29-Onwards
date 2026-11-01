extends SceneTree
var output:=OS.get_environment("FAMILY_QA_DIR")
func _initialize() -> void:call_deferred("run")
func frame() -> void:await process_frame;await RenderingServer.frame_post_draw
func run() -> void:
    root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(1120,768)
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true;prefs.economy=false;prefs.reduced_motion=false
    root.get_node("AdventureRun").persist_enabled=false;root.get_node("AdventureRun").active=false;root.get_node("OceanAudio").playback_enabled=false
    var menu=load("res://godot/title_screen.tscn").instantiate();root.add_child(menu)
    for i in range(8):await frame()
    menu.set_process(false);menu.hero_rig.set_process(false);Engine.time_scale=0;menu.content.modulate.a=1
    menu.hero_rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    menu.hero_performance.reset();menu.hero_rig.reset_performance()
    var tick:=0
    for pose in [[8,"front"],[17,"side"],[28,"away"]]:
        while tick<int(pose[0])*60:menu.hero_performance.update(menu,1.0/60);tick+=1
        await frame();root.get_texture().get_image().save_png(output+"/opening-"+pose[1]+".png")
    for size in [Vector2i(844,390),Vector2i(1280,720)]:
        root.size=size
        for i in range(5):await frame()
        menu._resize()
        for i in range(4):await frame()
        menu.hero_performance.reset();menu.hero_rig.reset_performance()
        for i in range(480):menu.hero_performance.update(menu,1.0/60)
        await frame();root.get_texture().get_image().save_png(output+"/opening_%dx%d.png" % [size.x,size.y])
    prefs.reduced_motion=true;menu.hero_performance.update(menu,1.0/60);await frame();root.get_texture().get_image().save_png(output+"/opening-gentle.png")
    for tween in get_processed_tweens():
        if is_instance_valid(tween):tween.kill()
    Engine.time_scale=1;menu.queue_free()
    for i in range(8):await frame()
    print("SETTLED OPENING QA COMPLETE");quit()

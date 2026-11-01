extends SceneTree
var output:=OS.get_environment("SARAH_REVIEW_DIR")
func _initialize() -> void:call_deferred("run")
func frame() -> void:await process_frame;await RenderingServer.frame_post_draw
func run() -> void:
    Engine.time_scale=0;root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true;root.get_node("OceanAudio").playback_enabled=false
    var menu=load("res://godot/title_screen.tscn").instantiate();root.add_child(menu);menu.set_process(false)
    for dimensions in [Vector2i(844,390),Vector2i(1024,768)]:
        root.size=dimensions
        for i in range(4):await frame()
        menu._resize()
        for mode in ["full","economy","gentle"]:
            prefs.economy=mode=="economy";prefs.reduced_motion=mode=="gentle";menu.hero_performance.reset();menu.hero_rig.reset_performance()
            for i in range(8*60):
                menu.hero_performance.update(menu,1.0/60)
                for tween in get_processed_tweens():
                    if is_instance_valid(tween):tween.custom_step(1.0/60)
            await frame();await frame();root.get_texture().get_image().save_png(output+"/opening-"+str(dimensions.x)+"-"+mode+".png")
    menu.free();await frame();await frame();print("SARAH FLOW LAYOUT COMPLETE");quit()

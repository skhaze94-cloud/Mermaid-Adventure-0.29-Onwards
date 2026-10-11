extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var out := OS.get_environment("ADVENTURE_CAPTURE_DIR")
    if out.is_empty(): quit(1); return
    DirAccess.make_dir_recursive_absolute(out)
    root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
    root.content_scale_size=Vector2i(1280,720)
    root.size=Vector2i(1280,720)
    var prefs = root.get_node("AppPreferences")
    prefs.persist_enabled=false
    prefs.intro_seen=false
    prefs.reduced_motion=false
    prefs.economy=false
    root.get_node("OceanAudio").playback_enabled=false
    var menu = load("res://godot/title_screen.tscn").instantiate()
    root.add_child(menu)
    menu.set_process(false)
    menu.music_player.stop()
    for frame in range(540):
        menu._process(1.0/60)
        menu._process(1.0/60)
        await process_frame
        await RenderingServer.frame_post_draw
        if frame in [45,105,210,360,480]:
            if root.get_texture().get_image().save_png(out+"/opening-"+str(frame)+".png")!=OK: quit(1); return
    if OS.get_environment("SARAH_LAYOUT_REVIEW")=="1":
        for layout in [[Vector2i(640,360),"phone"],[Vector2i(1024,768),"tablet"],[Vector2i(390,844),"portrait"]]:
            root.size=layout[0]
            menu.show_page("menu")
            for tick in range(24):
                menu._process(1.0/60)
                await process_frame
            await RenderingServer.frame_post_draw
            if root.get_texture().get_image().save_png(out+"/layout-"+layout[1]+".png")!=OK: quit(1); return
    print("SARAH V031 OPENING: 540 native frames")
    quit()

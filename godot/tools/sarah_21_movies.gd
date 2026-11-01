extends SceneTree
var output:=OS.get_environment("SARAH_MOVIE_DIR")
var fps:=24.0
func _initialize() -> void:call_deferred("run")
func frame() -> void:await process_frame;await RenderingServer.frame_post_draw
func capture(folder: String,i: int) -> void:
    await frame()
    print("FRAME ",folder," ",Marshalls.raw_to_base64(root.get_texture().get_image().save_jpg_to_buffer(.85)))
func run() -> void:
    root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(1280,720)
    DirAccess.make_dir_recursive_absolute(output+"/opening");DirAccess.make_dir_recursive_absolute(output+"/gameplay")
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true;prefs.economy=false;prefs.reduced_motion=false
    root.get_node("OceanAudio").playback_enabled=false
    var menu=load("res://godot/title_screen.tscn").instantiate();root.add_child(menu);menu.set_process(false)
    for i in range(4):await frame()
    for i in range(0 if OS.get_environment("SARAH_GAME_ONLY")=="1" else 34*int(fps)):
        menu.hero_performance.update(menu,1/fps)
        await capture("opening",i)
        if i in [192,384,624]:root.get_texture().get_image().save_png(output+"/opening-pose-"+str(i)+".png")
    for pixels in ([] if OS.get_environment("SARAH_GAME_ONLY")=="1" else [Vector2i(844,390),Vector2i(1024,768)]):
        root.size=pixels
        for i in range(4):await frame()
        menu.hero_performance.reset();menu.hero_rig.reset_performance()
        for i in range(192):menu.hero_performance.update(menu,1/fps)
        await frame();root.get_texture().get_image().save_png(output+"/opening-"+str(pixels.x)+".png")
        prefs.reduced_motion=true;menu.hero_performance.update(menu,1/fps);await frame();root.get_texture().get_image().save_png(output+"/opening-gentle-"+str(pixels.x)+".png");prefs.reduced_motion=false
    menu.free();await frame()
    if OS.get_environment("SARAH_OPEN_ONLY")=="1":
        print("SARAH OPENING: 34 seconds at 24 fps");quit();return
    root.size=Vector2i(1280,720)
    var scene=load("res://godot/highland_level.tscn").instantiate();root.add_child(scene)
    for i in range(4):await frame()
    scene.set_process(false);scene.set_physics_process(false);scene.native_rig.set_process(false)
    scene.boss_hp=0;scene.fallen=true;scene.player=Vector2(12000,550);scene.checkpoint=12000;scene.invulnerable=0;scene.message_time=0
    for enemy in scene.enemies:enemy["hp"]=0
    scene.animated_enemies.bind_enemies(scene.enemies)
    for i in range(20*int(fps)):
        var t:=i/fps
        scene.touch_vectors[97]=Vector2.RIGHT if t<3 else Vector2(.8,.35) if t<5 else Vector2.RIGHT if t<10 else Vector2(.7,-.4) if t<12 else Vector2.RIGHT if t<15 else Vector2.LEFT if t<18 else Vector2.RIGHT
        if i==3*int(fps) or i==14*int(fps):scene.energy=1;scene._boost()
        if i==6*int(fps):scene.energy=1;scene._jump()
        if i==12*int(fps):scene.opal.begin("preview")
        if i==int(13.6*fps):scene.opal.release("preview")
        scene._physics_process(1/fps);scene._sync_native_visuals();scene.native_rig._process(1/fps)
        await capture("gameplay",i)
    scene.free();await frame()
    print("SARAH MOVIES: 34 second opening, 20 second real-physics gameplay; 24 fps");quit()

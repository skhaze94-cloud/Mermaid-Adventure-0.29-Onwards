extends SceneTree
var output:=OS.get_environment("MOMENTS_AUDIT_DIR")
func _initialize() -> void:call_deferred("run")
func frame() -> void:await process_frame;await RenderingServer.frame_post_draw
func capture(name: String) -> void:
    for node in root.get_children():
        if node.has_method("_hud_snapshot"):
            node.premium_hud.clear_feedback();node.queue_redraw()
            if node.has_method("_draw_hide_cover"):node.hide_cover.queue_redraw()
    await frame();await frame();root.get_texture().get_image().save_png(output+"/"+name+".png")
func settle(scene,seconds: float) -> void:
    for i in range(ceili(seconds*60)):
        if is_instance_valid(scene.living_shallows):scene.living_shallows.advance(1.0/60);scene.living_shallows.sync()
        scene.little_moments.advance(1.0/60);scene.little_moments.sync()
        scene.native_rig.gesture_player.advance(1.0/60);scene.native_rig._process(1.0/60)
func place(scene,at: Vector2) -> void:
    scene.player=at;scene.player_velocity=Vector2.ZERO;scene.camera=maxf(0,at.x-570);scene.message_time=0;scene.invulnerable=0
    scene.native_rig.reset_performance();scene._sync_native_visuals()
    if is_instance_valid(scene.deep_routes):
        scene.camera=scene.deep_routes.room_camera_x(scene.camera);scene.deep_routes.sync(true);scene._sync_native_visuals()
func run() -> void:
    DirAccess.make_dir_recursive_absolute(output)
    Engine.time_scale=0;root.size=Vector2i(1400,960)
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.reduced_motion=false;prefs.economy=false
    root.get_node("AdventureRun").active=false;root.get_node("AdventureRun").avina_along=false
    root.get_node("OceanAudio").playback_enabled=false
    var scene=load("res://godot/training_lagoon.tscn").instantiate();root.add_child(scene);scene.music_player.stop();scene.music_player.stream=null
    await frame();await frame();scene.set_process(false);scene.set_physics_process(false)
    scene.native_rig.set_process(false);scene.message_time=0
    for n in range(11):
        scene._close_dialogue();scene.lesson=n;scene.player=Vector2([400,850,2500,3600,4050,4500,5500,6200,6600,7100,7350][n],580)
        scene.camera=maxf(0,scene.player.x-600);scene.arrival_time=2.6;scene.king_world=scene.player+Vector2(200,-130);scene._show_lesson()
        if n==8:scene.boss_position=Vector2(6900,550)
        if n>=9:scene.boss_hp=0
        scene._sync_native_visuals();await capture("lesson-"+str(n))
    scene.lesson=1;scene.player=Vector2(850,580);scene.camera=250
    for t in [0.0,.6,1.2,2.6]:
        scene.arrival_time=t;scene._sync_native_visuals();await capture("arrival-"+str(t))
    if not is_instance_valid(scene.get("little_moments")):
        scene.free();await frame();quit();return
    scene._close_dialogue();scene.lesson=0;scene._show_lesson();place(scene,Vector2(540,635));settle(scene,5);await capture("tutorial-fish")
    place(scene,scene.little_moments.keeper_point-Vector2(0,60));settle(scene,3);await capture("tutorial-lantern")
    scene.lesson=9;scene.boss_hp=0;scene._start_hide_seek();place(scene,Vector2(7050,620));await capture("peekaboo-garden")
    scene.free();await frame()
    scene=load("res://godot/highland_level.tscn").instantiate();root.add_child(scene);scene.music_player.stop();scene.music_player.stream=null;await frame();await frame()
    scene.set_process(false);scene.set_physics_process(false);scene.native_rig.set_process(false);scene.fallen=false;scene.enemies.clear();scene.animated_enemies.bind_enemies(scene.enemies)
    place(scene,Vector2(1720,630));scene.living_shallows.sync();settle(scene,4);await capture("nori-floating-letter")
    place(scene,scene.little_moments.letter_point);settle(scene,.15);await capture("nori-caught-letter")
    place(scene,Vector2(1720,630));settle(scene,1.5);await capture("nori-thank-you")
    for i in range(3):place(scene,scene.little_moments.music_point+Vector2(-78+i*78,-125));settle(scene,1)
    await capture("highland-music")
    root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
    for dimensions in [Vector2i(844,390),Vector2i(1024,768)]:
        root.size=dimensions
        for i in range(4):await frame()
        scene.simulated_touch=true;scene._on_viewport_resized()
        place(scene,Vector2(1720,630));settle(scene,.1);await capture("size-"+str(dimensions.x)+"-post")
        place(scene,scene.little_moments.music_point+Vector2(0,-125));settle(scene,.1);await capture("size-"+str(dimensions.x)+"-music")
        scene.reduced_fx=true;scene.little_moments.sync();await capture("size-"+str(dimensions.x)+"-gentle");scene.reduced_fx=false
    scene.free();await frame();await frame()
    print("LITTLE MOMENTS AUDIT complete");quit()

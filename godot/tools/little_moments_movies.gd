extends SceneTree
const FPS:=24.0
func _initialize() -> void:call_deferred("run")
func frame() -> void:await process_frame;await RenderingServer.frame_post_draw
func capture(part: String) -> void:
    await frame();print("FRAME ",part," ",Marshalls.raw_to_base64(root.get_texture().get_image().save_jpg_to_buffer(.86)))
func load_scene(index: int):
    paused=false
    var scene=load(root.get_node("AdventureRun").SCENES[index]).instantiate();root.add_child(scene);scene.music_player.stop();scene.music_player.stream=null
    await frame();await frame();scene.set_process(false);scene.set_physics_process(false);scene.native_rig.set_process(false)
    scene.native_rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    scene.native_rig.jump_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    scene.enemies.clear();scene.animated_enemies.bind_enemies(scene.enemies);scene.message_time=0;scene.invulnerable=0;scene.simulated_touch=true
    if index==0:scene.fallen=false
    return scene
func place(scene,at: Vector2) -> void:
    scene.player=at;scene.player_velocity=Vector2.ZERO;scene.camera=maxf(0,at.x-570);scene.native_rig.reset_performance();scene.message_time=0
    scene._sync_native_visuals();scene.deep_routes.sync(true);scene.queue_redraw()
func step(scene,target: Vector2) -> void:
    var direction: Vector2=target-scene.player
    scene.touch_vectors[97]=direction.normalized() if direction.length()>25 else Vector2.ZERO
    if not paused:scene._physics_process(1/FPS)
    scene._process(1/FPS)
    if not paused:
        scene.native_rig.gesture_player.advance(1/FPS);scene.native_rig.jump_player.advance(1/FPS);scene.native_rig._process(1/FPS)
        if scene.native_fx.has_method("_process"):scene.native_fx._process(1/FPS)
        for visual in [scene.ocean_feedback,scene.premium_hud,scene.world_depth,scene.foreground_depth,scene.water_surface]:
            if visual.has_method("_process"):visual._process(1/FPS)
    for tween in get_processed_tweens():
        if is_instance_valid(tween):tween.custom_step(1/FPS)
    scene.queue_redraw()
func retire(scene) -> void:
    paused=false;scene.free();await frame();await frame()
func run() -> void:
    Engine.time_scale=0
    root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(1280,720)
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true;prefs.reduced_motion=false;prefs.economy=false
    root.get_node("AdventureRun").active=false;root.get_node("AdventureRun").avina_along=false;root.get_node("OceanAudio").playback_enabled=false
    var scene=await load_scene(7)
    scene._close_dialogue();scene.lesson=1;scene.arrival_time=0;scene.arrival_intro_pending=true;scene._show_lesson();place(scene,Vector2(600,580))
    for i in range(0 if OS.get_environment("MOMENTS_ONLY")=="1" else 12*int(FPS)):
        if i in [132,204] and scene.dialogue_open:scene.dialogue_practice.pressed.emit()
        if i==252 and scene.dialogue_open:scene._close_dialogue()
        step(scene,Vector2(600,580));await capture("tutorial")
    await retire(scene)
    scene=await load_scene(7);scene._close_dialogue();scene.lesson=0;scene._show_lesson();place(scene,Vector2(540,635))
    for i in range(12*int(FPS)):
        if i==6*int(FPS):place(scene,Vector2(1010,1375))
        step(scene,Vector2(540,635) if i<6*FPS else Vector2(1010,1375));await capture("moments")
    await retire(scene)
    scene=await load_scene(0);place(scene,Vector2(1720,630))
    for i in range(12*int(FPS)):
        var target:=Vector2(1720,630)
        if scene.little_moments.letter_time>2.5 and scene.little_moments.letter_phase==1:target=scene.little_moments.letter_point
        step(scene,target);await capture("moments")
    place(scene,scene.little_moments.music_point+Vector2(-78,-190))
    for i in range(6*int(FPS)):
        var target: Vector2=scene.little_moments.music_point+Vector2(-78+mini(2,int(i/(FPS*1.6)))*78,-190)
        step(scene,target);await capture("moments")
    await retire(scene)
    print("LITTLE MOMENTS MOVIES: 12 s tutorial, 30 s stories, 24 fps");quit()

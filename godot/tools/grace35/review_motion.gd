extends SceneTree
const FPS:=12.0
var output:=OS.get_environment("GRACE_REVIEW_DIR")
var data:=[]
func _initialize() -> void:call_deferred("run")
func frame() -> void:await process_frame;await RenderingServer.frame_post_draw
func snap(name: String) -> void:
    await frame();root.get_texture().get_image().save_png(output+"/"+name+".png")
func run() -> void:
    root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(840,576)
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true;prefs.economy=false;prefs.reduced_motion=false
    root.get_node("AdventureRun").persist_enabled=false;root.get_node("AdventureRun").active=false;root.get_node("OceanAudio").playback_enabled=false
    var menu=load("res://godot/title_screen.tscn").instantiate();root.add_child(menu)
    for n in range(4):await frame()
    menu.set_process(false);menu.hero_rig.set_process(false);menu.hero_rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    Engine.time_scale=0;menu.hero_performance.reset();menu.hero_rig.reset_performance()
    for i in range(72):
        for tick in range(2):menu.hero_performance.update(menu,1.0/24)
        await snap("opening_%03d" % i)
    for size in [Vector2i(844,390),Vector2i(1280,720)]:
        root.size=size;await frame();await frame();menu._settle_layout();menu.hero_performance.update(menu,1.0/60);await snap("menu_%dx%d" % [size.x,size.y])
    menu.free();root.size=Vector2i(840,576);Engine.time_scale=1
    var scene=load("res://godot/training_lagoon.tscn").instantiate();root.add_child(scene)
    for n in range(5):await frame()
    scene.set_process(false);scene.set_physics_process(false);scene.native_rig.set_process(false);scene.music_player.stop();scene._close_dialogue();scene._advance_lesson(1);scene.arrival_intro_pending=false;scene.arrival_time=3
    scene.player=Vector2(1750,620);scene.player_velocity=Vector2.ZERO;scene.camera=1100;scene.deep_routes.sync(true);scene.message_time=0;scene.ocean_feedback.clear();scene.premium_hud.clear_feedback();scene._show_lesson()
    var rig=scene.native_rig;rig.reset_performance();rig.reset_jump();rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL;rig.jump_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    Engine.time_scale=0
    var velocity:=Vector2.ZERO;var facing:=1.0;var cpu:=[]
    for i in range(240):
        var t:=float(i)/FPS
        var direction:=Vector2.RIGHT
        var boost:=false;var jumping:=false
        if t<2.5:direction=Vector2.RIGHT
        elif t<3.7:direction=Vector2.ZERO
        elif t<5.2:direction=Vector2.LEFT
        elif t<6.0:direction=Vector2.RIGHT if int((t-5.2)/.18)%2==0 else Vector2.LEFT
        elif t<7.5:direction=Vector2(.8,-.6)
        elif t<9.0:direction=Vector2(.8,.6)
        elif t<10.0:direction=Vector2.RIGHT;boost=true
        elif t<11.3:direction=Vector2.RIGHT
        elif t<12.6:direction=Vector2.RIGHT;jumping=true
        elif t<14.0:direction=Vector2.RIGHT
        elif t<15.0:direction=Vector2.RIGHT;jumping=true
        elif t<17.0:direction=Vector2(.8,-.2)
        else:direction=Vector2.ZERO
        if i==int(11.3*FPS):rig.start_jump(0,1)
        if i==int(14*FPS):rig.start_jump(2,1);rig.jump_style=2
        if i==int(15.2*FPS):rig.set_bubble_charge(true,.3)
        if i==int(16.2*FPS):rig.set_bubble_charge(false,0);rig.play_gesture("cast")
        if i==int(17.3*FPS):rig.play_gesture("greet")
        if i==int(18.2*FPS):rig.play_gesture("greet");rig.set_bubble_charge(true,.7)
        if i==int(18.6*FPS):rig.set_bubble_charge(false,0);rig.play_gesture("cast")
        if i==int(19*FPS):prefs.economy=true;rig.set_quality(false)
        if i==int(19.5*FPS):prefs.reduced_motion=true;rig.reduced_motion=true
        for tick in range(2):
            var dt:=1.0/24
            velocity=load("res://godot/sarah_motion.gd").swim_velocity(velocity,direction,dt)
            if absf(direction.x)>.08:facing=signf(direction.x)
            var motion:=velocity
            if boost:motion=Vector2(760,0)
            if jumping:
                var start:=11.3 if t<14 else 14.0
                var air:=maxf(0,t-start-.2)
                rig.set_jump_state("ascent" if t-start<.2 else "airborne",air,0 if t<14 else 2,1)
                motion=Vector2(300,-200+air*450)
            else:rig.set_jump_state("",0,0,1)
            rig.set_steering(direction);rig.set_motion(motion,facing,boost,jumping,1)
            rig.gesture_player.advance(dt);rig.jump_player.advance(dt)
            var began:=Time.get_ticks_usec();rig._process(dt);cpu.append(Time.get_ticks_usec()-began)
        scene.time+=1/FPS;scene.character_dt=1/FPS;scene.neighbourhood.advance(1/FPS);scene.neighbourhood_art.sync()
        # Restore the inspected presentation motion after world placement.
        rig.position=Vector2(650,620);scene.queue_redraw()
        await snap("motion_%03d" % i)
        if i in [24,40,54,71,87,103,113,126,143,153,174,188,199,212,227,237]:
            data.append({"frame":i,"seconds":t,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"process_bytes":Performance.get_monitor(Performance.MEMORY_STATIC)})
    cpu.sort();var total:=0.0
    for value in cpu:total+=value
    data.append({"rig_cpu_us_mean":total/cpu.size(),"rig_cpu_us_median":cpu[cpu.size()/2],"rig_cpu_us_p95":cpu[int(cpu.size()*.95)],"samples":cpu.size(),"renderer":RenderingServer.get_video_adapter_name()})
    var file:=FileAccess.open(output+"/metrics.json",FileAccess.WRITE);file.store_string(JSON.stringify(data,"  "));file.close()
    scene.free();await frame();print("GRACE35 CAPTURE COMPLETE: 6 s opening, 20 s controlled movement, 12 fps");quit()

extends "res://godot/tools/little_moments_movies.gd"
func run() -> void:
    Engine.time_scale=0;root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(1280,720)
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true;prefs.economy=false;prefs.reduced_motion=false
    root.get_node("AdventureRun").active=false;root.get_node("AdventureRun").avina_along=false;root.get_node("OceanAudio").playback_enabled=false
    var menu=load("res://godot/title_screen.tscn").instantiate();root.add_child(menu);menu.set_process(false)
    for i in range(4):await frame()
    for i in range(8*int(FPS)):
        menu.hero_performance.update(menu,1/FPS)
        for tween in get_processed_tweens():
            if is_instance_valid(tween):tween.custom_step(1/FPS)
        await capture("flow26")
    menu.free();await frame();await frame()
    var scene=await load_scene(0);scene.fallen=true;scene.boss_hp=0;scene.bubble_unlocked=true;place(scene,Vector2(12000,380))
    var phases: Dictionary={};var chains:=0;var charged:=false;var released:=false
    for i in range(24*int(FPS)):
        var t:=float(i)/FPS
        if i==2*int(FPS):scene.energy=1;scene._boost()
        if i==5*int(FPS):place(scene,Vector2(12500,365));scene.energy=1;scene._jump()
        if t>5 and t<9.5 and scene.splash_window>0 and scene.splash_chain<2:scene._jump()
        if i==10*int(FPS):scene.opal.cancel();place(scene,Vector2(13200,420))
        if i==11*int(FPS):charged=scene.opal.begin("flow-preview")
        if i==int(12.4*FPS):released=scene.opal.release("flow-preview")
        if i==int(14.5*FPS):scene._set_paused(true)
        if i==15*int(FPS):scene._set_paused(false)
        var direction:=Vector2.RIGHT
        if t<2:direction=Vector2(1,.15)
        elif t>10 and t<14:direction=Vector2(.8,.25*sin(t*2))
        elif t>=16 and t<20:direction=Vector2.RIGHT if int((t-16)/.18)%2==0 else Vector2.LEFT
        elif t>=20:direction=Vector2(0,.3) if t<22 else Vector2.ZERO
        var target: Vector2=scene.player+direction*600
        step(scene,target);phases[scene.leap_phase]=true;chains=maxi(chains,scene.splash_chain);await capture("flow26")
    print("FLOW26 ACTION COVERAGE ",JSON.stringify({"jump_phases":phases.keys(),"maximum_chain":chains,"charge_accepted":charged,"bubble_released":released}))
    await retire(scene);print("SARAH FLOW MOVIE COMPLETE 32 seconds");quit()

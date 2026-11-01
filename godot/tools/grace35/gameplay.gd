extends "res://godot/tools/little_moments_movies.gd"
var output:=OS.get_environment("GRACE_GAMEPLAY_DIR")
func run() -> void:
    root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(840,576)
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true;prefs.reduced_motion=false;prefs.economy=false
    root.get_node("AdventureRun").persist_enabled=false;root.get_node("AdventureRun").active=false;root.get_node("AdventureRun").avina_along=false;root.get_node("OceanAudio").playback_enabled=false
    Engine.time_scale=1
    var scene=await load_scene(0);scene.fallen=true;scene.boss_hp=0;scene.bubble_unlocked=true;scene.invulnerable=1000
    place(scene,Vector2(12000,380));Engine.time_scale=0
    var phases:={};var chain:=0;var charge:=false;var release:=false
    for i in range(84):
        var t:=float(i)/12
        if i==10:scene.energy=1;scene._boost()
        if i==24:scene.energy=1;scene._jump()
        if i==53:scene.opal.cancel();charge=scene.opal.begin("grace35-preview")
        if i==68:release=scene.opal.release("grace35-preview")
        for tick in range(5):
            if t>2 and t<4.4 and scene.splash_window>0 and scene.splash_chain<2:scene._jump()
            var direction:=Vector2.RIGHT if t<4.3 else Vector2(.7,.1)
            scene.touch_vectors[97]=direction
            scene._physics_process(1.0/60);scene._process(1.0/60)
            scene.native_rig.gesture_player.advance(1.0/60);scene.native_rig.jump_player.advance(1.0/60);scene.native_rig._process(1.0/60)
            if scene.native_fx.has_method("_process"):scene.native_fx._process(1.0/60)
            for visual in [scene.ocean_feedback,scene.premium_hud,scene.world_depth,scene.foreground_depth,scene.water_surface]:
                if visual.has_method("_process"):visual._process(1.0/60)
            for tween in get_processed_tweens():
                if is_instance_valid(tween):tween.custom_step(1.0/60)
            phases[scene.leap_phase]=true;chain=maxi(chain,scene.splash_chain)
        scene.queue_redraw();await frame();root.get_texture().get_image().save_png(output+"/gameplay_%03d.png" % i)
    var result:={"jump_phases":phases.keys(),"maximum_chain":chain,"charge_accepted":charge,"bubble_released":release,"final_position":str(scene.player),"controls":"actual _physics_process, touch-vector input, boost/jump/opal APIs; fixed 60 Hz simulation; 12 fps capture"}
    var file:=FileAccess.open(output+"/coverage.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close();print("GRACE35 ACTUAL GAMEPLAY ",JSON.stringify(result));scene.free();await frame();quit()

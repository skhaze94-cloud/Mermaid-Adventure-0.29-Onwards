extends "res://godot/tools/opal_visual_audit.gd"
var views:=0
func run() -> void:
    Engine.time_scale=0
    root.size=Vector2i(1400,960)
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false;root.get_node("AdventureRun").active=false
    for chapter in [7,0,1,2,3,4,5,6]:
        var scene=setup(root.get_node("AdventureRun").SCENES[chapter])
        scene.boss_hp=0;scene.enemies.clear();scene.animated_enemies.bind_enemies(scene.enemies);scene.reduced_fx=false
        if chapter==0:scene.fallen=false
        if chapter==7:
            scene.lesson=10;scene.boss_hp=0;scene.dialogue_open=false;scene.dialogue_done=Callable()
            scene.dialogue_card.hide();scene.dialogue_shade.hide();scene.lesson_card.hide();scene.choice_card.hide()
        var model=scene.neighbourhood;var room: Dictionary=model.profile["room"]
        var center: Vector2=room["reef"].get_center()
        scene.player=Vector2(center.x-330,room["reef"].position.y-210);scene.player_velocity=Vector2.ZERO;scene.camera=center.x-680
        scene.message_time=0;scene.deep_routes.sync(true);model.quiet=false;model.clock=4;model.flourish=3.5
        for index in range(2):
            model._speak(index,model.profile["people"][index]["lines"][0]);scene.neighbourhood_art.sync()
            await snap(scene,"district-"+str(chapter)+"-resident-"+str(index));views+=1
        root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
        root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(844,390)
        for i in range(4):await process_frame
        scene.simulated_touch=true;scene._on_viewport_resized();scene.deep_routes.sync(true)
        scene.neighbourhood_art.sync();await snap(scene,"phone-district-"+str(chapter));views+=1
        scene.reduced_fx=true;scene.high_depth_quality=false;scene.neighbourhood_art.sync();await snap(scene,"gentle-economy-district-"+str(chapter));views+=1
        scene._set_paused(true);scene.neighbourhood.suspend();scene.neighbourhood_art.sync()
        assert(not scene.neighbourhood_art.caption.visible,"pause hides neighbourhood speech")
        paused=false;scene.state="playing"
        root.size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
        for i in range(4):await process_frame
        await retire(scene)
    print("WHIMSY FOUR VISUAL COMPLETE ",views," views");quit()

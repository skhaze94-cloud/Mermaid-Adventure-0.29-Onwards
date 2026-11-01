extends "res://godot/tools/opal_visual_audit.gd"
func run() -> void:
    Engine.time_scale=0;root.size=Vector2i(1400,960)
    root.get_node("AppPreferences").persist_enabled=false;root.get_node("AdventureRun").active=false;root.get_node("OceanAudio").playback_enabled=false
    var scene=setup(root.get_node("AdventureRun").SCENES[0]);scene.fallen=false;scene.boss_hp=0;scene.enemies.clear();scene.animated_enemies.bind_enemies(scene.enemies)
    var model=scene.neighbourhood
    for index in range(2):
        var person: Dictionary=model.profile["people"][index]
        scene.player=person["talk_at"]+Vector2(175,-30);scene.camera=person["foot"].x-700;scene.player_velocity=Vector2.ZERO;scene.message_time=0;scene.deep_routes.sync(true)
        model.flourish=0;model.quiet=false
        for i in range(145):model.clock=float(i)/24;scene.neighbourhood_art.sync()
        await snap(scene,"resident-"+str(index)+"-settled")
        for i in range(1,49):model.clock=6+float(i)/24;model.flourish=1;scene.neighbourhood_art.sync()
        await snap(scene,"resident-"+str(index)+"-happy")
    await retire(scene)
    print("CUTE REACTIONS NATIVE SMOKE COMPLETE");quit()

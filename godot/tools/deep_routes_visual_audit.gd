extends "res://godot/tools/opal_visual_audit.gd"
const Data=preload("res://godot/deep_routes_data.gd")
var view_checks:=0
func cavern_scene(chapter: int):
    var scene=setup(root.get_node("AdventureRun").SCENES[chapter])
    scene.enemies.clear();scene.animated_enemies.bind_enemies(scene.enemies)
    scene.player_velocity=Vector2.ZERO;scene.message_time=0;scene.invulnerable=0
    if chapter==7:
        scene.lesson=10;scene.boss_hp=0;scene.dialogue_open=false;scene.playing_daddy=false
        scene.dialogue_card.hide();scene.lesson_card.hide();scene.choice_card.hide()
    return scene
func place_deep(scene,room: Dictionary,at: Vector2) -> void:
    scene.player=at;scene.player_velocity=Vector2.ZERO;scene.camera=maxf(0,at.x-590)
    scene.native_rig.reset_performance();scene.native_rig.set_motion(Vector2(24,0),1,false,false,1)
    scene.deep_routes.sync(true);scene.deep_routes.clock=9
    if is_instance_valid(scene.avina):scene.avina.reset_follow();scene.avina.tick(0)
    scene._sync_native_visuals()
func capture(scene,name: String) -> void:
    await snap(scene,name)
    var cam: float=scene.deep_routes.camera_y
    assert(absf(root.canvas_transform.origin.y+cam)<2,"real Camera2D follows the lower world")
    assert(scene.player.y-cam>80 and scene.player.y-cam<920,"hero stays on screen")
    view_checks+=1
func run() -> void:
    Engine.time_scale=0;root.size=Vector2i(1400,960)
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false
    root.get_node("AdventureRun").active=false;root.get_node("AdventureRun").avina_along=true
    for chapter in [7,0,1,2]:
        var scene=cavern_scene(chapter);var rooms:=Data.rooms(chapter)
        for index in range(rooms.size()):
            var room: Dictionary=rooms[index]
            if chapter==0:scene.fallen=index>0
            place_deep(scene,room,Vector2(room["a"],float(room["y"])+float(room["h"])-125))
            await capture(scene,"chapter-"+str(chapter)+"-"+room["id"]+"-chamber")
            place_deep(scene,room,room["chest"]-Vector2(80,25))
            await capture(scene,"chapter-"+str(chapter)+"-"+room["id"]+"-lower-pocket")
        var chosen: Dictionary=rooms[0]
        if chapter==0:scene.fallen=false
        for y in [760.0,1030.0]:
            place_deep(scene,chosen,Vector2(chosen["a"],y))
            await capture(scene,"chapter-"+str(chapter)+"-descent-"+str(int(y)))
        root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
        root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(844,390)
        for i in range(4):await process_frame
        scene.simulated_touch=true;scene._on_viewport_resized()
        place_deep(scene,chosen,Vector2(chosen["a"],float(chosen["y"])+float(chosen["h"])-125))
        await capture(scene,"phone-cavern-chapter-"+str(chapter))
        scene.reduced_fx=true;scene.native_rig.reduced_motion=true
        await capture(scene,"phone-gentle-cavern-chapter-"+str(chapter))
        scene.reduced_fx=false;scene.high_depth_quality=false
        await capture(scene,"phone-economy-cavern-chapter-"+str(chapter))
        root.size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
        for i in range(4):await process_frame
        await retire(scene)
    print("DEEP ROUTES VISUAL COMPLETE ",view_checks," views");quit()

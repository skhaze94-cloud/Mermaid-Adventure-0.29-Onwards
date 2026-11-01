extends SceneTree
var output:=OS.get_environment("TREASURE_CAPTURE_DIR")
func _initialize() -> void:call_deferred("run")
func frame() -> void:
    await process_frame
    await RenderingServer.frame_post_draw
func shot(scene,filename: String) -> void:
    scene.queue_redraw()
    scene.treasure_gallery.sync(true,0)
    for i in range(3):await frame()
    var err:=root.get_texture().get_image().save_png(output+"/screenshots/"+filename+".png")
    print("CAPTURE ",filename," ",root.get_texture().get_size()," status=",err)
func pose(scene,at: Vector2,lesson: int,camera_x: float) -> void:
    scene._close_dialogue()
    scene.lesson=lesson
    scene.player=at;scene.player_velocity=Vector2.ZERO
    scene.camera=camera_x
    scene.arrival_time=2.6
    scene.king_world=at+Vector2(260,-140)
    scene._show_lesson()
    for i in range(60):
        scene.time+=1.0/60.0;scene.character_dt=1.0/60
        scene._sync_native_visuals()
    scene.message_time=0;scene.premium_hud.clear_feedback()
    scene.deep_routes.sync(true)
    scene.treasure_gallery.sync(false)
func run() -> void:
    root.size=Vector2i(1400,960)
    var prefs=root.get_node("AppPreferences")
    prefs.persist_enabled=false;prefs.intro_seen=true;prefs.economy=false;prefs.reduced_motion=false
    root.get_node("AdventureRun").active=false
    root.get_node("AdventureRun").persist_enabled=false
    root.get_node("OceanAudio").playback_enabled=false
    var scene=load("res://godot/training_lagoon.tscn").instantiate()
    root.add_child(scene)
    await frame();await frame()
    scene.music_player.stop();scene.music_player.stream=null
    scene.set_process(false);scene.set_physics_process(false)
    scene.native_rig.set_process(false)
    scene.treasure_gallery.set_process(false)
    Engine.time_scale=0
    scene.time=12.0
    var chests: Array=scene.treasures.filter(func(t):return t.kind=="chest")
    print("CHEST POSITIONS: ",chests)
    # All screenshots use the real tutorial scene. Positions are staged for QA,
    # collection is performed by the game's original pickup function.
    pose(scene,Vector2(chests[0].x-175,chests[0].y-100),0,0)
    await shot(scene,"01-pearlkeeper-tutorial")
    pose(scene,Vector2(chests[2].x-175,chests[2].y-110),2,float(chests[2].x)-650)
    await shot(scene,"02-moonshell-before-opening")
    # Approach with existing collection logic, then hold a readable inspection pose.
    scene.player=Vector2(chests[2].x,chests[2].y)
    var before: int=scene.score
    scene._update_collectibles()
    scene.treasure_gallery.sync(true,0)
    print("REAL PICKUP: taken=",chests[2].taken," points=",scene.score-before)
    scene.player=Vector2(chests[2].x-175,chests[2].y-100)
    scene._sync_native_visuals()
    for i in range(65):
        scene.treasure_gallery.sync(true,1.0/24.0)
        scene.time+=1.0/24.0
        scene.queue_redraw()
        await frame()
        var err:=root.get_texture().get_image().save_png(output+"/frames/open_%03d.png" % i)
        if err!=OK:push_error("Cannot save animation frame")
        if i==17:await shot(scene,"03-moonshell-reward-reveal")
    await shot(scene,"04-moonshell-opened")
    # The original second-storey caverns use a real Camera2D and the same actor.
    pose(scene,Vector2(chests[3].x-150,chests[3].y-105),0,300)
    await shot(scene,"05-crystalwake-cavern")
    # A QA camera return to an already-collected chest confirms it stays open.
    pose(scene,Vector2(chests[2].x-175,chests[2].y-100),2,float(chests[2].x)-650)
    await shot(scene,"06-return-to-collected-chest")
    scene.free();await frame();await frame()
    print("TREASURE NATIVE CAPTURE COMPLETE")
    quit(0)

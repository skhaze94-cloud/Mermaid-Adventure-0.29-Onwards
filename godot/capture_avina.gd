extends SceneTree
func _initialize() -> void: call_deferred("run")
func frames(count := 10) -> void:
    for i in range(count): await process_frame
func capture(name: String) -> void:
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(OS.get_environment("AVINA_CAPTURE_DIR")+"/"+name+".png")
func run() -> void:
    root.get_node("AppPreferences").persist_enabled=false
    root.get_node("AppPreferences").intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false
    root.get_node("AdventureRun").begin(7)
    change_scene_to_file("res://godot/training_lagoon.tscn"); await frames()
    var level=current_scene; level.set_physics_process(false)
    level.lesson=1; level.arrival_time=2.6; level.player=Vector2(950,550); level.camera=360
    await frames(24); await capture("Family-Lagoon-Rings")
    level._open_dialogue("intro"); await frames(); await capture("King-Daddy-Dialogue")
    level._close_dialogue(); level.lesson=6; level.player=Vector2(5550,580); level.camera=5000; level._show_lesson()
    level._open_dialogue("gifts"); await frames(); await capture("Antonella-Dialogue")
    level.reply_box.get_child(2).pressed.emit(); level.reply_box.get_child(1).pressed.emit()
    await frames(15); await capture("Antonella-Pearl-Demo")
    level.lesson=8; level.boss_clock=9; level.player=Vector2(6620,570); level.camera=6000
    level._update_boss(0); level._show_lesson(); await frames(); await capture("King-Daddy-Green-Opening")
    level.queen_demo=0; level.boss_hp=0; level.lesson=9; level.player=Vector2(7070,580); level.camera=6200
    level._start_hide_seek(); level._close_dialogue(); await frames(); await capture("Avina-Peekaboo")
    level.lesson=10; level.avina.follow_enabled=true; level.avina.reset_follow(); level._show_lesson(); await frames(); await capture("Avina-Tutorial")
    level.player=Vector2(level._portal_x()+1,550); level._update_swimming(0); await frames(); await capture("Avina-Companion-Choice")
    level.bring_button.pressed.emit(); await frames(); await capture("Family-Take-Along-Farewell")
    level.reply_box.get_child(0).pressed.emit(); level.reply_box.get_child(0).pressed.emit(); await frames(18)
    while root.get_node("SceneFlow").busy: await process_frame
    current_scene.set_physics_process(false); current_scene.fallen=true; current_scene.player=Vector2(2060,570); current_scene.camera=1530
    await frames(30); await capture("Avina-Highland-Companion")
    current_scene.free(); await frames(); quit()

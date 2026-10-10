extends SceneTree
var output := ""
var number := 0
func _initialize() -> void: call_deferred("run")
func shot() -> void:
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(output+"/frame-%04d.png" % number)
    number += 1
func hold(count: int) -> void:
    for i in range(count): await shot()
func travel(path: String, title: String, index: int) -> void:
    var flow := root.get_node("SceneFlow")
    flow.go(path, title, "", index)
    while flow.busy and number < 500: await shot()
func run() -> void:
    output = OS.get_environment("ADVENTURE_CAPTURE_DIR")
    assert(not output.is_empty())
    DirAccess.make_dir_recursive_absolute(output)
    root.size = Vector2i(960,660)
    var prefs := root.get_node("AppPreferences")
    prefs.persist_enabled = false
    prefs.intro_seen = true
    prefs.reduced_motion = false
    Engine.time_scale = 0.35
    change_scene_to_file("res://godot/title_screen.tscn")
    for i in range(8): await process_frame
    current_scene.content.modulate.a = 1.0
    await hold(18)
    current_scene.show_page("chapters")
    await hold(18)
    await travel("res://godot/highland_level.tscn", "Highland Gold", 0)
    current_scene.invulnerable = 100
    await hold(24)
    current_scene._set_paused(true)
    await hold(24)
    await travel("res://godot/shadow_kingdom.tscn", "Shadow Crab Kingdom", 1)
    if current_scene.has_method("_stage_index"):
        current_scene.invulnerable = 100
        current_scene.fallen = true
        current_scene.player = Vector2(1100,540)
        current_scene.camera = 550
        current_scene._sync_native_visuals()
    await hold(30)
    print("POLISH CAPTURE: %s frames" % number)
    quit()

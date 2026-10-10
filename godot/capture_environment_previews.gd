extends SceneTree
func _initialize() -> void:
    call_deferred("_capture")
func _capture() -> void:
    var level = load("res://godot/highland_level.tscn").instantiate()
    root.add_child(level)
    level.set_process(false)
    level.set_physics_process(false)
    var shots := [
        {"name":"05-waterfall-entrance", "size":Vector2i(1400,960), "x":3020.0,"fallen":false,"boss":22},
        {"name":"06-victory-portal", "size":Vector2i(1400,960), "x":20500.0,"fallen":true,"boss":0},
        {"name":"07-phone-wide-lake", "size":Vector2i(844,390), "x":1250.0,"fallen":false,"boss":22},
        {"name":"08-tablet-grotto", "size":Vector2i(1024,768), "x":12500.0,"fallen":true,"boss":22}
    ]
    for shot in shots:
        root.size = shot["size"]
        for frame in range(3):
            await process_frame
        level.player = Vector2(shot["x"],570.0)
        level.camera = clampf(level.player.x-480.0,0.0,maxf(0.0,level.Highland.LEVEL_LENGTH-root.get_visible_rect().size.x))
        level.fallen = shot["fallen"]
        level.boss_hp = shot["boss"]
        level.message_time = 0.0
        level.time = 3.0
        level.simulated_touch = root.size.x < 1100
        level._sync_native_visuals()
        level.premium_hud.update_hud(level._hud_snapshot())
        level.queue_redraw()
        for frame in range(3):
            await process_frame
        await RenderingServer.frame_post_draw
        var image := root.get_texture().get_image()
        var path: String = "res://godot/visual-previews/"+shot["name"]+".png"
        if image.save_png(path) != OK:
            push_error("Environment capture failed: "+path)
            quit(1)
            return
        print("ENVIRONMENT PREVIEW CAPTURED: "+path)
    root.remove_child(level)
    level.free()
    quit(0)

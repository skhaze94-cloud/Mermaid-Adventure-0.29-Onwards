extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
    root.content_scale_size=Vector2i(1400,960)
    root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
    root.get_node("AppPreferences").persist_enabled=false
    var level = load("res://godot/highland_level.tscn").instantiate()
    root.add_child(level)
    level.set_process(false)
    level.set_physics_process(false)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://godot/ui-previews"))
    for name in ["hud","touch","results","results-phone","tablet","pause-phone","long-score"]:
        root.size=Vector2i(960,540) if name in ["touch","results-phone","pause-phone"] else (Vector2i(1024,768) if name=="tablet" else Vector2i(1400,960))
        for frame in range(4): await process_frame
        level._restart()
        level.player=Vector2(1900,570)
        level.camera=1300
        level.time=3.0
        level.simulated_touch=name in ["touch","tablet"]
        level.message_time=0
        for i in range(10): level._award("pearl:"+str(i),"Pearls",10,level.player,true)
        level.picked_count=10
        level._award("chest","Treasure",100,level.player+Vector2(200,0),true)
        level._award("enemy","Enemies",50,level.player-Vector2(100,0),true)
        if name.begins_with("results"):
            level._award("boss","Boss",1000,level.player,false)
            level.picked_count=24
            level._complete_score()
            level.state="victory"
        if name == "pause-phone": level._set_paused(true)
        if name == "long-score": level.score=1234567890
        level._sync_native_visuals()
        level.premium_hud.configure_layout(root.get_visible_rect().size,Vector2(root.size))
        level.premium_hud.update_hud(level._hud_snapshot())
        level.premium_hud._process(2.0)
        if not name.begins_with("results"):
            level.premium_hud.show_reward({"points":100,"category":"Treasure","extra":0,"multiplier":5},level.player-Vector2(level.camera,0))
            level.premium_hud._process(0.3)
        level.queue_redraw()
        for frame in range(4): await process_frame
        await RenderingServer.frame_post_draw
        var image := root.get_texture().get_image()
        image.save_png("res://godot/ui-previews/"+name+".png")
        if name.begins_with("results") or name == "pause-phone":
            for action in (["restart","menu"] if name.begins_with("results") else ["resume","restart","menu"]):
                if not Rect2(Vector2.ZERO,level.premium_hud.game_size).encloses(level.premium_hud.action_rect(action)):
                    push_error("UI CAPTURE clipped modal action: "+name+action)
                    quit(1)
                    return
        print("UI CAPTURE ",name," ",root.size," card=",level.premium_hud.modal_card.get_rect()," buttons=",level.premium_hud.action_rect("menu"))
    level.free()
    quit()

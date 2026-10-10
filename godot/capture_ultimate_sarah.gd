extends SceneTree
## Native close-up of the production rig; no replacement artwork or animation.
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var out := OS.get_environment("ADVENTURE_CAPTURE_DIR")
    if out.is_empty(): quit(1); return
    DirAccess.make_dir_recursive_absolute(out)
    root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
    root.content_scale_size=Vector2i(960,540)
    root.size=Vector2i(960,540)
    root.get_node("OceanAudio").playback_enabled=false
    var background := TextureRect.new()
    background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
    background.size=Vector2(960,540)
    root.add_child(background)
    var shade := ColorRect.new()
    shade.color=Color(.01,.06,.09,.42)
    shade.size=Vector2(960,540)
    root.add_child(shade)
    var rig = load("res://godot/sarah_rig.gd").new()
    root.add_child(rig)
    rig.position=Vector2(525,245)
    rig.set_process(false)
    rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.jump_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    var title := Label.new()
    title.position=Vector2(24,18)
    title.text="v0.29 · ULTIMATE SARAH"
    title.add_theme_font_size_override("font_size",25)
    title.modulate=Color("f4dca5")
    root.add_child(title)
    var caption := Label.new()
    caption.position=Vector2(24,466)
    caption.add_theme_font_size_override("font_size",23)
    root.add_child(caption)
    var note := Label.new()
    note.position=Vector2(24,507)
    note.text="Production Godot rig · enlarged for inspection · 36 body loops / 12 strokes"
    note.add_theme_font_size_override("font_size",15)
    note.modulate=Color("b4d9d9")
    root.add_child(note)
    var cases := [
        ["breaststroke",Vector2(280,0),false,"","Breaststroke · reach, catch, pull, recover"],
        ["front_crawl",Vector2(345,0),false,"","Front crawl · alternating arms"],
        ["sidestroke",Vector2(160,0),false,"","Sidestroke · relaxed lead and trailing pull"],
        ["butterfly",Vector2(345,0),false,"","Butterfly · paired sweep and rolling tail"],
        ["rise_scoop",Vector2(30,-330),false,"","Swim up · high catch and downward scoop"],
        ["rise_alternate",Vector2(30,-330),false,"","Swim up · alternating climbing strokes"],
        ["dive_spear",Vector2(30,330),false,"","Swim down · spear reach and trim sweep"],
        ["dive_sweep",Vector2(30,330),false,"","Swim down · tucked sweeping stroke"],
        ["boost_dolphin",Vector2(760,0),true,"","Boost · dolphin kick and forward reach"],
        ["boost_drive",Vector2(760,-120),true,"","Boost · compact power drive"],
        ["",Vector2.ZERO,false,"pull","Waterfall entry · gather and balance"],
        ["",Vector2(70,0),false,"descent","Waterfall · opposed sculling in the current"],
        ["",Vector2(80,-430),false,"descent","Waterfall climb · scoop against the current"],
        ["",Vector2(80,430),false,"descent","Waterfall dive · streamlined descent"],
        ["",Vector2(700,-180),true,"descent","Waterfall boost · stable surge and fluke drive"],
        ["",Vector2(160,0),false,"outflow","Waterfall exit · open into a relaxed glide"]
    ]
    var serial := 0
    rig.reset_performance()
    for case in cases:
        rig.swim_style_override=case[0]
        rig.set_waterfall_context(case[3])
        rig.set_motion(case[1],1,case[2],false,1)
        background.texture=load("res://godot/assets/waterfall-cavern-v07.webp") if case[3]!="" else load("res://godot/assets/environment-lake-v011.webp")
        caption.text=case[4]
        for frame in range(60):
            for tick in range(2): rig._process(1.0/60)
            rig.scale *= 1.7
            await process_frame
            await RenderingServer.frame_post_draw
            if frame==40:
                var image := root.get_texture().get_image()
                if image.save_png(out+"/pose-%02d.png" % (serial/60))!=OK: quit(1); return
            serial+=1
    print("ULTIMATE SARAH NATIVE PREVIEW: %d frames" % serial)
    quit()

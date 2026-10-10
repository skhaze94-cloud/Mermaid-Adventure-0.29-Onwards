extends SceneTree
## Same production rig in a full-body view and a clipped close-up.
func _initialize() -> void: call_deferred("run")
func label(text: String, position: Vector2, size: int, color: Color) -> Label:
    var item := Label.new()
    item.text=text
    item.position=position
    item.add_theme_font_size_override("font_size",size)
    item.modulate=color
    root.add_child(item)
    return item
func run() -> void:
    var out := OS.get_environment("ADVENTURE_CAPTURE_DIR")
    if out.is_empty(): quit(1); return
    DirAccess.make_dir_recursive_absolute(out)
    root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
    root.content_scale_size=Vector2i(1280,720)
    root.size=Vector2i(1280,720)
    root.get_node("OceanAudio").playback_enabled=false
    var background := TextureRect.new()
    background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
    background.size=Vector2(1280,720)
    background.texture=load("res://godot/assets/environment-lake-v011.webp")
    root.add_child(background)
    var shade := ColorRect.new()
    shade.color=Color(.01,.045,.06,.48)
    shade.size=Vector2(1280,720)
    root.add_child(shade)
    label("SARAH · FLUID NECK & BACK REVIEW",Vector2(30,25),29,Color("f4dca5"))
    label("Full body",Vector2(30,95),20,Color("b4d9d9"))
    label("Neck & back close-up · anchored joins",Vector2(760,95),20,Color("b4d9d9"))
    var panel := Control.new()
    panel.position=Vector2(740,135)
    panel.size=Vector2(510,425)
    panel.clip_contents=true
    root.add_child(panel)
    var rigs := []
    for i in range(2):
        var rig = load("res://godot/sarah_rig.gd").new()
        (root if i==0 else panel).add_child(rig)
        rig.position=Vector2(395,365) if i==0 else Vector2(180,330)
        rig.set_process(false)
        rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
        rig.jump_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
        rig.reset_jump()
        rig.reset_performance()
        rigs.append(rig)
    var caption := label("",Vector2(30,620),24,Color("f1fff8"))
    label("Chest leads · neck settles · restrained back ripple · fixed collar and hip bands",Vector2(30,671),17,Color("b4d9d9"))
    var cases := [
        [Vector2.ZERO,false,"", "Idle · gentle breathing and relaxed neck",150],
        [Vector2(280,0),false,"", "Swim · back ripple follows the tail rhythm",90],
        [Vector2(30,-330),false,"", "Rise · chest leads and neck follows",90],
        [Vector2(30,330),false,"", "Dive · controlled back and neck response",90],
        [Vector2(760,-80),true,"", "Boost · compact flowing body line",90],
        [Vector2(-345,0),false,"", "Turn · neck inertia eases the heading change",90],
        [Vector2(80,-430),false,"descent", "Waterfall climb · coordinated back and current",90],
        [Vector2(700,120),true,"descent", "Waterfall boost · compact ripple under effort",90],
        [Vector2.ZERO,false,"", "Recovery · back and neck settle smoothly",90]
    ]
    var serial := 0
    for i in range(cases.size()):
        var case: Array = cases[i]
        caption.text=case[3]
        for rig in rigs:
            rig.set_waterfall_context(case[2])
            rig.set_motion(case[0],1,case[1],false,1)
        background.texture=load("res://godot/assets/waterfall-cavern-v07.webp") if case[2]!="" else load("res://godot/assets/environment-lake-v011.webp")
        for frame in range(case[4]):
            for rig in rigs:
                for tick in range(2): rig._process(1.0/60)
            rigs[0].scale*=1.9
            rigs[1].scale*=3.2
            await process_frame
            await RenderingServer.frame_post_draw
            if frame==60 or (i==0 and frame==134):
                var suffix := "blink" if i==0 and frame==134 else str(i)
                if root.get_texture().get_image().save_png(out+"/detail-"+suffix+".png")!=OK: quit(1); return
            serial+=1
    print("SARAH SPINE NATIVE PREVIEW: %d frames" % serial)
    quit()

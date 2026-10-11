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
    label("SARAH · FLUID ELBOWS & WRISTS",Vector2(30,25),29,Color("f4dca5"))
    label("Full body",Vector2(30,95),20,Color("b4d9d9"))
    label("Arm articulation · tracking close-up",Vector2(760,95),20,Color("b4d9d9"))
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
    label("Shoulder-led reach · elbow flexion · wrist follow-through · continuous painted skin",Vector2(30,671),17,Color("b4d9d9"))
    var cases := [
        [Vector2.ZERO,false,"","Idle · relaxed shoulders and head",150,"",-1,""],
        [Vector2(345,0),false,"","Breaststroke · elbow catch and wrist recovery",60,"breaststroke",-1,""],
        [Vector2(345,0),false,"","Front Crawl · elbow catch and wrist recovery",60,"front_crawl",-1,""],
        [Vector2(345,0),false,"","Sidestroke · elbow catch and wrist recovery",60,"sidestroke",-1,""],
        [Vector2(345,0),false,"","Butterfly · elbow catch and wrist recovery",60,"butterfly",-1,""],
        [Vector2(40,-330),false,"","Rise Scoop · elbow catch and wrist recovery",60,"rise_scoop",-1,""],
        [Vector2(40,-330),false,"","Rise Alternate · elbow catch and wrist recovery",60,"rise_alternate",-1,""],
        [Vector2(40,330),false,"","Dive Spear · elbow catch and wrist recovery",60,"dive_spear",-1,""],
        [Vector2(40,330),false,"","Dive Sweep · elbow catch and wrist recovery",60,"dive_sweep",-1,""],
        [Vector2(760,0),true,"","Boost Dolphin · elbow catch and wrist recovery",60,"boost_dolphin",-1,""],
        [Vector2(760,0),true,"","Boost Drive · elbow catch and wrist recovery",60,"boost_drive",-1,""],
        [Vector2(345,0),false,"descent","Waterfall Scull · elbow catch and wrist recovery",60,"waterfall_scull",-1,""],
        [Vector2(760,0),true,"descent","Waterfall Surge · elbow catch and wrist recovery",60,"waterfall_surge",-1,""],
        [Vector2(310,-120),false,"","Aerial performance 1 · ribcage and waist response",60,"",0,""],
        [Vector2(310,-120),false,"","Aerial performance 2 · ribcage and waist response",60,"",1,""],
        [Vector2(310,-120),false,"","Aerial performance 3 · ribcage and waist response",60,"",2,""],
        [Vector2(310,-120),false,"","Aerial performance 4 · ribcage and waist response",60,"",3,""],
        [Vector2(310,-120),false,"","Aerial performance 5 · ribcage and waist response",60,"",4,""],
        [Vector2(310,-120),false,"","Aerial performance 6 · ribcage and waist response",60,"",5,""],
        [Vector2.ZERO,false,"","Greet · arm gesture and hand settling",60,"",-1,"greet"],
        [Vector2.ZERO,false,"","Cast · arm gesture and hand settling",60,"",-1,"cast"],
        [Vector2.ZERO,false,"","Celebrate · arm gesture and hand settling",60,"",-1,"celebrate"],
        [Vector2.ZERO,false,"","Impact · arm gesture and hand settling",60,"",-1,"impact"],
        [Vector2.ZERO,false,"","Reward · arm gesture and hand settling",60,"",-1,"reward"],
        [Vector2(80,-430),false,"descent","Waterfall climb · connected current response",90,"",-1,""],
        [Vector2(-345,60),false,"","Turn · gaze leads, head follows",90,"",-1,""],
        [Vector2.ZERO,false,"","Recovery · shoulders and jaw settle",90,"",-1,""]
    ]
    var serial := 0
    for i in range(cases.size()):
        var case: Array = cases[i]
        caption.text=case[3]
        for rig in rigs:
            rig.reset_jump()
            rig.gesture_player.stop()
            rig._clear_gesture_values()
            if case[6]>=0: rig.jump_style=case[6]
            rig.swim_style_override=case[5]
            if case[7]!="": rig.play_gesture(case[7])
            rig.set_waterfall_context(case[2])
            rig.set_motion(case[0],-1 if case[0].x<0 else 1,case[1],case[6]>=0,1)
        background.texture=load("res://godot/assets/waterfall-cavern-v07.webp") if case[2]!="" else load("res://godot/assets/environment-lake-v011.webp")
        for frame in range(case[4]):
            for rig in rigs:
                for tick in range(2):
                    if case[6]>=0: rig.set_jump_state("airborne",float(frame*2+tick)/(case[4]*2)*.88,case[6],1)
                    rig.gesture_player.advance(1.0/60)
                    rig._process(1.0/60)
            rigs[0].scale*=1.55 if case[6]>=0 else 1.9
            rigs[1].scale*=3.2
            var focus: Vector2 = panel.get_global_transform().affine_inverse()*rigs[1].torso.to_global(rigs[1].torso_motion.chest_point(Vector2(45,-8)))
            rigs[1].position+=Vector2(260,290)-focus
            await process_frame
            await RenderingServer.frame_post_draw
            if frame in [15,30,45] or (i==0 and frame==134):
                var suffix := "blink" if i==0 and frame==134 else str(i)
                if frame in [15,30]: suffix+="-phase-"+str(frame)
                if root.get_texture().get_image().save_png(out+"/detail-"+suffix+".png")!=OK: quit(1); return
            serial+=1
    print("SARAH ARMS NATIVE PREVIEW: %d frames" % serial)
    quit()

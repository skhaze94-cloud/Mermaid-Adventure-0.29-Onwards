extends SceneTree
## Matched production poses with the waist palette disabled/enabled.
func _initialize() -> void: call_deferred("run")
func caption(text: String, position: Vector2, size: int) -> Label:
    var item := Label.new()
    item.text=text
    item.position=position
    item.add_theme_font_size_override("font_size",size)
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
    var backdrop := ColorRect.new()
    backdrop.color=Color("17363e")
    backdrop.size=Vector2(1280,720)
    root.add_child(backdrop)
    caption("SARAH · UNIFIED TORSO–TAIL JOIN",Vector2(30,25),30)
    caption("Previous palette",Vector2(70,105),23)
    caption("Shared iridescent transition",Vector2(730,105),23)
    var rigs := []
    for i in range(2):
        var rig = load("res://godot/sarah_rig.gd").new()
        var panel := Control.new()
        panel.position=Vector2(i*640,140)
        panel.size=Vector2(640,475)
        panel.clip_contents=true
        root.add_child(panel)
        panel.add_child(rig)
        rig.set_process(false)
        rig.reset_jump()
        rig.reset_performance()
        rig.bodice.material.set_shader_parameter("waist_unified",i==1)
        rig.tail_skin.material.set_shader_parameter("waist_unified",i==1)
        rigs.append(rig)
    var status := caption("",Vector2(30,635),24)
    caption("Original scales and silhouette · stable overlap · matching motion",Vector2(30,680),18)
    var cases := [
        [Vector2.ZERO,false,"","Idle"],
        [Vector2(345,0),false,"","Swimming"],
        [Vector2(40,-330),false,"","Rising"],
        [Vector2(760,0),true,"","Boost"],
        [Vector2(80,-430),false,"descent","Waterfall climb"],
        [Vector2(-345,60),false,"","Turning"]
    ]
    for i in range(cases.size()):
        var sample: Array = cases[i]
        status.text=sample[3]
        for rig in rigs:
            rig.set_waterfall_context(sample[2])
            rig.set_motion(sample[0],-1 if sample[0].x<0 else 1,sample[1],false,1)
        for frame in range(90):
            for j in range(2):
                var rig = rigs[j]
                rig._process(1.0/60)
                rig._process(1.0/60)
                rig.scale*=3.5
                var panel: Control = rig.get_parent()
                var focus: Vector2 = panel.get_global_transform().affine_inverse()*rig.torso.to_global(Vector2(28,6))
                rig.position+=Vector2(360,300)-focus
            await process_frame
            await RenderingServer.frame_post_draw
            if frame==45:
                if root.get_texture().get_image().save_png(out+"/waist-"+str(i)+".png")!=OK: quit(1); return
    print("SARAH WAIST PREVIEW: 540 matched frames")
    quit()

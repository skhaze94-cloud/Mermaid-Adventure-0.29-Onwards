extends SceneTree
## Native character showcase; the same rigs, textures and poses as the game.
func _initialize() -> void: call_deferred("run")
func caption(stage: Node, text: String, where: Vector2, width: float, font_size: int, color := Color("dff7f1")) -> Label:
    var label := Label.new()
    label.text=text
    label.position=where
    label.size=Vector2(width,80)
    label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size",font_size)
    label.modulate=color
    stage.add_child(label)
    return label
func run() -> void:
    root.get_node("OceanAudio").playback_enabled=false
    var out := OS.get_environment("CHARACTER_CAPTURE_DIR")
    if out.is_empty(): out="/tmp/character027"
    DirAccess.make_dir_recursive_absolute(out)
    var stage := Node2D.new()
    root.add_child(stage)
    var background := ColorRect.new()
    background.color=Color("073544")
    background.size=Vector2(1400,960)
    stage.add_child(background)
    caption(stage,"SARAH MARIA",Vector2(0,24),1400,22,Color("9ae4d4"))
    caption(stage,"Character Harmony · v0.27",Vector2(0,61),1400,43)
    caption(stage,"Connected silhouettes. Softer gestures. A little more life in every movement.",Vector2(0,124),1400,19,Color("a9cfce"))
    var king = load("res://godot/family_royal_actor.gd").new()
    stage.add_child(king); king.configure("king",465); king.position=Vector2(240,430)
    var queen = load("res://godot/family_royal_actor.gd").new()
    stage.add_child(queen); queen.configure("queen",450); queen.position=Vector2(1160,430)
    var sarah = load("res://godot/sarah_rig.gd").new()
    stage.add_child(sarah); sarah.position=Vector2(740,355); sarah.set_process(false)
    sarah.gesture_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    sarah.reset_performance()
    var baby = load("res://godot/avina_companion.gd").new()
    stage.add_child(baby); baby.position=Vector2(765,545); baby.sprite.scale*=1.5
    caption(stage,"KING DADDY",Vector2(55,681),370,20)
    caption(stage,"SARAH MARIA",Vector2(455,487),250,20)
    caption(stage,"BABY AVINA",Vector2(650,651),230,18,Color("ecc9fa"))
    caption(stage,"QUEEN ANTONELLA",Vector2(975,681),370,20)
    caption(stage,"Movement refinement across every chapter",Vector2(0,752),1400,20,Color("a9cfce"))
    var creatures := []
    var Art = load("res://godot/creature_art.gd")
    for i in range(6):
        var kind: String = ["crab","eel","jelly","puffer","swordfish","shark"][i]
        var sprite := Sprite2D.new()
        sprite.texture=Art.atlas(kind)
        sprite.material=Art.material(kind)
        sprite.position=Vector2(200+i*200,852)
        sprite.scale=Art.base_scale(kind)*.54
        stage.add_child(sprite); creatures.append(sprite)
    var mode_label := caption(stage,"SWIM · REACH, CATCH & SOFT RECOVERY",Vector2(420,205),560,18,Color("f7d69a"))
    for frame in range(480):
        var t := frame/60.0
        var dash := frame>=240 and frame<360
        sarah.set_motion(Vector2(700,0) if dash else Vector2(210,15),1,dash,false,1)
        sarah._process(1.0/60)
        sarah.scale*=1.5
        king.animate(t,"cast" if dash else "wave",false)
        queen.animate(t,"cast" if dash else "celebrate",false)
        baby.sprite.rotation=sin(t*2.4)*.025
        baby.sprite.position.y=sin(t*2.4)*3
        baby.sprite.material.set_shader_parameter("clock",t)
        baby.sprite.material.set_shader_parameter("wiggle",sin(t*4)*.018)
        baby.sprite.material.set_shader_parameter("joy",.4)
        mode_label.text="DASH · A LONG, CALM FORWARD REACH" if dash else "SWIM · REACH, CATCH & SOFT RECOVERY"
        for sprite in creatures: sprite.material.set_shader_parameter("visual_clock",t)
        await process_frame
        if frame in [90,290,410]:
            await RenderingServer.frame_post_draw
            check_save(root.get_texture().get_image().save_png(out+"/showcase-%03d.png" % frame))
    print("CHARACTER HARMONY NATIVE CAPTURE PASSED")
    quit()
func check_save(error: Error) -> void:
    if error!=OK:
        push_error("Character preview could not be saved")
        quit(1)

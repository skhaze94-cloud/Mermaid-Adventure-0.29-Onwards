extends SceneTree
## Tests the actual painted alpha at the neck/collar overlap through motion.
var checks := 0
var failures := 0
func check(ok: bool, why: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("SARAH CONTINUITY: " + why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var rig = load("res://godot/sarah_rig.gd").new()
    root.add_child(rig)
    rig.set_process(false)
    rig.gesture_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.jump_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    var bodice: Image = rig.ATLAS.get_image()
    check(rig.back_hair.get_parent() == rig.head_joint,"Hair does not follow the skull")
    check(rig.tail_skin.get_parent() == rig.torso,"Hip does not follow torso yaw")
    for face in rig.faces:
        check(face.get_image().get_pixel(470,560).a > .8,"Expression loses the neck paint")
    for direction in [-1.0,1.0]:
        for mode in ["idle","swim","boost","rise","turn","jump"]:
            rig.reset_jump()
            rig.reset_performance()
            var velocity := Vector2.ZERO if mode == "idle" else Vector2(300*direction,20)
            if mode == "rise": velocity.y = -260
            rig.set_motion(velocity,direction,mode=="boost",mode=="jump",1)
            rig.play_gesture("greet")
            for frame in range(120):
                if mode == "jump": rig.set_jump_state("airborne",float(frame)/119*.88,0,direction)
                if mode == "turn" and frame == 40: rig.set_motion(-velocity,-direction,false,false,1)
                rig.gesture_player.advance(1.0/60)
                rig._process(1.0/60)
                # The lower neck paint must lie inside opaque collar artwork.
                # This uses source alpha, not just overlapping bounding boxes.
                var neck: Vector2 = rig.face_sprite.to_global(Vector2(470,560))
                var in_body: Vector2 = rig.bodice.to_local(neck)
                var pixel: Vector2 = rig.BODICE_REGION.position+(in_body-rig.BODICE_BOUNDS.position)*rig.BODICE_REGION.size/rig.BODICE_BOUNDS.size
                var inside: bool = pixel.x>=0 and pixel.y>=0 and pixel.x<bodice.get_width() and pixel.y<bodice.get_height()
                check(inside and bodice.get_pixelv(Vector2i(pixel)).a>.7,"Painted neck separates from collar: "+mode)
                check(rig.tail_skin.position == Vector2(1,6),"Tail socket drifts in body space")
                check(rig.back_hair.position == Vector2(-3,-13),"Hair root drifts in skull space")
    rig.free()
    print("SARAH CONTINUITY: %d checks, %d failures" % [checks,failures])
    quit(0 if failures==0 else 1)

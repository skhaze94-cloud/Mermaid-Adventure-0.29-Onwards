extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var rig = load("res://godot/sarah_rig.gd").new()
    root.add_child(rig)
    rig.set_process(false)
    rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.jump_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    var shoulder_span := 0.0
    var jaw_span := 0.0
    for hz in [30,60,120]:
        rig.reset_performance()
        for context in ["","descent","outflow"]:
            rig.set_waterfall_context(context)
            for velocity in [Vector2.ZERO,Vector2(345,0),Vector2(0,-330),Vector2(0,330),Vector2(760,0),Vector2(-345,0)]:
                rig.set_motion(velocity,-1 if velocity.x<0 else 1,velocity.length()>650,false,1)
                for tick in range(hz):
                    var before: float = rig.spine_motion.neck.x
                    rig._process(1.0/hz)
                    var motion = rig.spine_motion
                    check(absf(motion.shoulder_near.x)<.10 and absf(motion.shoulder_far.x)<.10,"Shoulder exceeds safe range")
                    check(absf(motion.neck.x-before)<.05,"Head transition snaps")
                    check(motion.jaw.x>=0 and motion.jaw.x<=.65,"Jaw exceeds range")
                    shoulder_span=maxf(shoulder_span,absf(motion.shoulder_near.x))
                    jaw_span=maxf(jaw_span,motion.jaw.x)
        rig.reduced_motion=true
        rig._process(1.0/hz)
        check(rig.face_details.surface.get_shader_parameter("jaw_open")==0.0,"Gentle Motion leaves jaw movement")
        rig.reduced_motion=false
        rig.reset_performance()
        check(rig.spine_motion.jaw==Vector2.ZERO and rig.spine_motion.shoulder_near==Vector2.ZERO,"Restart retains secondary motion")
    check(shoulder_span>.02 and jaw_span>.25,"Secondary motion remains static")
    rig.free()
    print("DEFINITIVE SARAH: %d checks, %d failures" % [checks,failures])
    quit(1 if failures else 0)

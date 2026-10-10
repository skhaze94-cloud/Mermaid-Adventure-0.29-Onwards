extends SceneTree
const Cycles = preload("res://godot/sarah_pose_cycles.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, reason: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("SARAH DEPTH: "+reason)
func advance(rig, ticks: int) -> void:
    for i in range(ticks): rig._process(1.0/60)
func run() -> void:
    Cycles.build()
    check(Cycles.NAMES.size()==36,"v0.29 must double the 18 body loops")
    var signatures: Array[Vector4] = []
    for name in Cycles.NAMES:
        check(Cycles.cycles[name].size()==432,"v0.29 must triple v0.29.2 samples per loop")
        var signature := Cycles.sample(name,.7)+Cycles.sample(name,2.2)*.5
        for previous in signatures: check(previous.distance_to(signature)>.003,"Distinct performances must not duplicate another loop")
        signatures.append(signature)
    var rig = load("res://godot/sarah_rig.gd").new()
    root.add_child(rig)
    rig.set_process(false)
    rig.gesture_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    for state in [[Vector2.ZERO,"hover"],[Vector2(160,0),"cruise"],[Vector2(410,0),"crawl"],[Vector2(160,180),"spear"]]:
        rig.reset_performance()
        rig.set_motion(state[0],1,false,false,1)
        advance(rig,90)
        check(rig.pose_set==state[1],"Contextual movement does not select "+state[1])
    for action in ["greet","cast","reward","impact","celebrate"]:
        rig.reset_performance()
        rig.play_gesture(action)
        rig.gesture_player.advance(.05)
        advance(rig,8)
        var expected: String = {"greet":"greet","cast":"cast","reward":"reach","impact":"recover","celebrate":"celebrate"}[action]
        check(rig.pose_set==expected,"Action depth missing for "+action)
    rig.reset_performance()
    rig.set_motion(Vector2(300,0),1,false,false,1)
    advance(rig,90)
    rig.set_motion(Vector2.ZERO,1,false,false,1)
    advance(rig,8)
    check(rig.pose_set=="settle","Stopping does not settle through the body")
    rig.reset_performance()
    rig.set_motion(Vector2(230,0),-1,false,false,1)
    advance(rig,5)
    check(rig.pose_set=="bank","Turn does not use banking performance")
    var last_tip: Vector2 = rig.tail_skin.tip_center
    for state in [Vector2.ZERO,Vector2(160,0),Vector2(410,0),Vector2(120,-240),Vector2(160,180)]:
        rig.set_motion(state,1,false,false,1)
        for i in range(90):
            rig._process(1.0/60)
            check(rig.tail_skin.tip_center.distance_to(last_tip)<20,"Context transition snaps the fluke")
            check(rig.tail_skin.tip_center.is_finite(),"Context transition invalidates skin")
            last_tip = rig.tail_skin.tip_center
    rig.reduced_motion = true
    rig.set_steering(Vector2(1,1))
    advance(rig,60)
    check(rig.depth_bank==0 and rig.depth_turn==0,"Reduced motion retains banking")
    check(rig.tail_skin.polygon==rig.tail_skin.rest,"Reduced motion retains contextual deformation")
    rig.reset_performance()
    check(rig.depth_bank==0 and rig.settle_blend==0,"Restart retains secondary motion")
    rig.free()
    print("SARAH DEPTH: %s checks, %s failures" % [checks,failures])
    quit(1 if failures else 0)

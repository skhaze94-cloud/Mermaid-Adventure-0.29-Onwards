extends SceneTree
const Arms = preload("res://godot/sarah_arm_cycles.gd")
var checks := 0
var failures := 0
func check(ok: bool, why: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("SARAH BREASTSTROKE: "+why)
func _initialize() -> void: call_deferred("run")
func hand(rig, index: int) -> Vector2:
    var mesh = rig.arm_meshes[index]
    # Middle row at the fingertips of the actual deformed arm geometry.
    var columns := 32
    var middle_row := 4
    return mesh.get_parent().to_local(mesh.to_global(mesh.polygon[middle_row*(columns+1)+columns]))
func run() -> void:
    check(Arms.sample(0).distance_to(Arms.sample(TAU))<.00001,"Stroke loop pops")
    var before := (Arms.sample(0)-Arms.sample(-.001))/.001
    var after := (Arms.sample(.001)-Arms.sample(0))/.001
    check(before.distance_to(after)<.02,"Stroke loop has a velocity kink")
    var rig = load("res://godot/sarah_rig.gd").new()
    root.add_child(rig)
    rig.set_process(false)
    rig.gesture_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.reset_performance()
    var source_uv: PackedVector2Array = rig.arm_meshes[1].uv.duplicate()
    rig.set_motion(Vector2(300,0),1,false,false,1)
    for i in range(90): rig._process(1.0/60)
    var lo := Vector2(INF,INF)
    var hi := Vector2(-INF,-INF)
    for i in range(240):
        rig._process(1.0/60)
        var h := hand(rig,1).rotated(rig.near_arm.rotation)
        lo = lo.min(h)
        hi = hi.max(h)
        check(rig.arm_pose_near.y> -1.30,"Recovery folds the forearm too tightly")
        check(absf(rig.arm_pose_near.x-rig.arm_pose_far.x)<.4,"Arms alternate instead of synchronized breaststroke")
        for mesh in rig.arm_meshes:
            check(mesh.polygon[0]==mesh.rest[0],"Elbow skin pulls the shoulder seam")
            var valid := true
            for point in mesh.polygon: valid = valid and point.is_finite()
            check(valid,"Stroke produces invalid arm geometry")
    check(hi.x-lo.x>45 and hi.y-lo.y>30,"Hands do not complete a reach/sweep/recovery path")
    check(rig.arm_meshes[1].uv==source_uv,"Stroke slides the sleeve/hand painting")
    var old_hand: Vector2 = rig.near_arm.to_global(hand(rig,1))
    rig.set_motion(Vector2(700,0),1,true,false,1)
    for i in range(120):
        rig._process(1.0/60)
        var new_hand: Vector2 = rig.near_arm.to_global(hand(rig,1))
        check(new_hand.distance_to(old_hand)<14,"Dash transition snaps the hand")
        old_hand=new_hand
    check(absf(rig.arm_pose_near.y)<.06 and absf(rig.arm_pose_far.y)<.06,"Dash retains folded swim elbows")
    check(hand(rig,1).rotated(rig.near_arm.rotation ).x>60,"Dash fails to reach forward")
    var dash_pose: Vector3 = rig.arm_pose_near
    for i in range(120):
        rig._process(1.0/60)
        check(rig.arm_pose_near.distance_to(dash_pose)<.01,"Dash keeps paddling")
    rig.reduced_motion = true
    rig.set_motion(Vector2(300,0),1,false,false,1)
    for i in range(120): rig._process(1.0/60)
    check(rig.arm_meshes[1].polygon==rig.arm_meshes[1].rest,"Gentle mode retains elbow deformation")
    check(absf(rig.arm_pose_near.x)<.01,"Gentle mode retains a full stroke")
    rig.reset_performance()
    check(rig.arm_pose_near==Vector3.ZERO and rig.arm_pose_far==Vector3.ZERO,"Restart keeps a folded arm pose")
    rig.free()
    print("SARAH BREASTSTROKE: %d checks, %d failures" % [checks,failures])
    quit(0 if failures==0 else 1)

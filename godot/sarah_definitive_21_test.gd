extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,note: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error("SARAH 2.1: "+note)
func run() -> void:
    var rig=load("res://godot/sarah_rig.gd").new();root.add_child(rig);rig.set_process(false)
    rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.jump_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    var builds:=[]
    for part in rig.painted_parts:
        if part.get("topology_builds")!=null:builds.append(part.topology_builds)
    var count: int=rig.get_child_count()
    for hz in [30,60,120]:
        rig.reset_performance()
        for phase in ["idle","swim","boost","ascent","airborne","reentry","cast","turn","stop"]:
            var velocity:=Vector2.ZERO if phase in ["idle","stop"] else Vector2(240,-80)
            rig.set_motion(velocity,-1 if phase=="turn" else 1,phase=="boost",phase in ["ascent","airborne","reentry"],1)
            rig.set_steering(velocity.normalized())
            rig.set_jump_state(phase if phase in ["ascent","airborne","reentry"] else "",.35,1,1)
            rig.set_bubble_charge(phase=="cast",1)
            for i in range(hz/2):
                rig._process(1.0/hz)
                for index in range(2):
                    var joint=rig.far_arm if index==0 else rig.near_arm
                    check(rig.definitive_21.attachment_error(rig,index)<.0001,"arm socket leaves actual torso surface")
                    check(rig.arm_meshes[index].polygon.size()==rig.arm_meshes[index].rest.size(),"skin topology changes")
                check(rig.scale.is_finite() and absf(rig.scale.x)>.001,"turn produces singular transform")
                check(not (rig.definitive_21.portrait.visible and rig.face_details.visible),"two facial paintings ghost together")
        check(rig.get_child_count()==count,"motion allocates new rig nodes")
    rig.reset_performance();rig.set_motion(Vector2(700,0),1,true,false,1);rig.play_gesture("greet")
    check(rig.last_gesture!="greet","idle gesture interrupts Boost")
    rig._process(.016);check(rig.definitive_21.action=="boost","action ownership loses Boost")
    rig.set_motion(Vector2.ZERO,1,false,false,1);rig.set_bubble_charge(true,.8);rig.play_gesture("reward");rig._process(.016)
    check(rig.last_gesture!="reward" and rig.definitive_21.action=="cast","discovery overrides bubble hold")
    rig.reset_performance();rig.definitive_21.opening=true;rig.definitive_21.view_goal=.82
    for i in range(120):rig._process(.016)
    check(rig.definitive_21.portrait.visible and rig.definitive_21.front_weight>.95 and rig.bodice.visible,"opening cannot turn toward player")
    rig.definitive_21.view_goal=-.65
    for i in range(120):rig._process(.016)
    check(rig.definitive_21.portrait.visible and rig.definitive_21.front_weight<.01 and rig.bodice.visible,"opening cannot glance back to lagoon")
    rig.reduced_motion=true;rig.set_motion(Vector2.ZERO,-1,false,false,1);rig._process(.016)
    check(not rig.definitive_21.portrait.visible and absf(rig.scale.x)>.99,"Gentle Motion retains a projected thin turn")
    rig.reduced_motion=false;rig.set_quality(false);rig._process(.016)
    var k:=0
    for part in rig.painted_parts:
        if part.get("topology_builds")!=null:check(part.topology_builds==builds[k],"steady motion or quality switching rebuilds topology");k+=1
    var clock: float=rig.clock;rig.hide();rig._process(.1);check(rig.clock==clock,"hidden character still animates")
    rig.show();rig.reset_performance();check(rig.definitive_21.heading==Vector2(1,0),"retry keeps visual turn inertia")
    rig.free();await process_frame
    print("SARAH DEFINITIVE 2.1: ",checks," checks, ",failures," failures");quit(1 if failures else 0)

extends SceneTree
## Temporal and geometry invariants missing from the earlier socket-only suite.
var checks:=0
var failures:=0
func check(ok: bool,note: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error("SARAH FLOW: "+note)
func _initialize() -> void:call_deferred("run")
func run() -> void:
    root.get_node("AppPreferences").persist_enabled=false;root.get_node("OceanAudio").playback_enabled=false
    var rig=load("res://godot/sarah_rig.gd").new();root.add_child(rig);rig.set_process(false)
    rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.jump_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    var topology:=[]
    for part in rig.painted_parts:
        if part.get("topology_builds")!=null:topology.append(part.topology_builds)
    var count: int=rig.get_child_count()
    for uv in rig.tail_skin.uv:
        check(uv.x>=0 and uv.y>=0 and uv.x<rig.tail_skin.texture.get_width() and uv.y<rig.tail_skin.texture.get_height(),"tail crop leaves the imported texture and exposes a root gap")
    for hz in [30,60,120]:
        rig.reset_performance();var intermediates:=0;var previous:=0.0;var maximum_step:=0.0
        for i in range(hz*2):
            var facing:=1.0 if i<hz/3 or i>hz else -1.0
            if i>hz+hz/3:facing=-facing # Interrupted reversal after the first complete turn.
            rig.set_motion(Vector2(280*facing,60),facing,false,false,1);rig.set_steering(Vector2(facing,.2));rig._process(1.0/hz)
            var f: float=rig.definitive_21.front_weight
            if f>.01 and f<.99:intermediates+=1
            maximum_step=maxf(maximum_step,absf(f-previous));previous=f
            check(absf(rig.tail_skin.transform.determinant())>.2,"turn collapses or inverts tail area")
            check(absf(rig.near_arm.transform.determinant())>.2 and absf(rig.far_arm.transform.determinant())>.2,"turn collapses an arm through zero width")
            check(rig.bodice.visible and rig.tail_skin.visible,"body or tail is substituted with an invisible view")
            check(rig.bodice.polygon.size()==975 and rig.tail_skin.polygon.size()==2509,"turn changes mesh topology")
            check(not(rig.face_details.visible and rig.definitive_21.portrait.visible),"view handoff draws two faces")
        check(intermediates>3,"torso paint remains a binary switch")
        check(maximum_step<.65,"continuous torso transition jumps too far in one frame")
    rig.reset_performance();rig.set_motion(Vector2(280,0),1,false,false,1)
    for i in range(90):rig._process(1.0/60)
    var hip: Vector2=rig.tail_skin.to_global(rig.tail_skin.socket)
    check(hip.distance_to(rig.torso.to_global(rig.torso_motion.HIP_PIVOT))<.001,"side tail leaves the actual hip while the lower torso bends")
    var length:=0.0
    for i in range(1,rig.tail_skin.centers.size()):length+=rig.tail_skin.centers[i].distance_to(rig.tail_skin.centers[i-1])
    check(absf(length-rig.tail_skin.tail_length)<.01,"full-quality tail changes physical centerline length")
    for jump in range(6):
        rig.reset_jump();rig.reset_performance();rig.jump_style=jump
        for i in range(45):
            rig.set_motion(Vector2(220,-140 if i<22 else 160),1,false,true,1);rig.set_jump_state("airborne",float(i)/44*.88,0,1);rig._process(1.0/60)
            for angle in rig.tail_skin.angles:check(angle<=1.361 and angle>=-1.151,"stacked jump offsets exceed the combined curl envelope")
    rig.reset_jump();rig.reset_performance();rig.set_quality(false);rig.set_motion(Vector2(280,0),1,false,false,1)
    for i in range(30):rig._process(1.0/60)
    var tip: Vector2=rig.tail_skin.tip_center;var travel:=0.0
    for i in range(90):
        rig._process(1.0/60);travel+=tip.distance_to(rig.tail_skin.tip_center);tip=rig.tail_skin.tip_center
    check(travel>4,"Economy tail remains a static rest shape")
    for i in range(24):
        rig.set_quality(i%2==0);rig.reduced_motion=i%3==0;rig._process(1.0/60)
    var k:=0
    for part in rig.painted_parts:
        if part.get("topology_builds")!=null:check(part.topology_builds==topology[k],"quality changes rebuild the mesh");k+=1
    check(rig.get_child_count()==count,"steady actions allocate rig nodes")
    var clock: float=rig.clock;rig.hide();rig._process(.05);check(rig.clock==clock,"invisible rig still animates")
    rig.show();rig.reset_performance();check(rig.definitive_21.heading==Vector2(1,0) and rig.tail_skin.position==Vector2(1,6),"retry keeps projected hip or turn state")
    rig.free();await process_frame;print("SARAH FLOW: ",checks," checks, ",failures," failures");quit(1 if failures else 0)

extends SceneTree
var rows:=[]
var failures:=0
func check(ok: bool, note: String) -> void:
    if not ok:failures+=1;push_error(note)
func _initialize() -> void:call_deferred("run")
func points(rig) -> Dictionary:
    var d:={}
    for pair in [["body",rig.bodice],["tail",rig.tail_skin],["near_arm",rig.arm_meshes[1]],["far_arm",rig.arm_meshes[0]],["hair",rig.ribbons[0]]]:
        var a:=PackedVector2Array()
        for p in pair[1].polygon:a.append(pair[1].to_global(p))
        d[pair[0]]=a
    return d
func run() -> void:
    root.get_node("AppPreferences").persist_enabled=false;root.get_node("OceanAudio").playback_enabled=false
    var rig=load("res://godot/sarah_rig.gd").new();root.add_child(rig);rig.set_process(false)
    rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL;rig.jump_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    for hz in [30,60,120]:
        rig.reset_jump();rig.reset_performance();rig.set_steering(Vector2.RIGHT);rig.set_motion(Vector2(345,0),1,false,false,1)
        for i in range(hz*2):rig._process(1.0/hz)
        var before:=points(rig);var previous: float=rig.scale.x;var crossing:={};var peaks:={}
        for i in range(hz):
            rig.set_steering(Vector2.LEFT);rig.set_motion(Vector2(-345,0),-1,false,false,1);rig._process(1.0/hz)
            var after:=points(rig);var step:={}
            for key in after:
                var maximum:=0.0
                for k in range(after[key].size()):maximum=maxf(maximum,after[key][k].distance_to(before[key][k]))
                step[key]=maximum;peaks[key]=maxf(peaks.get(key,0.0),maximum)
            if rig.scale.x*previous<0:crossing={"frame":i,"heading":rig.definitive_21.heading.x,"front":rig.definitive_21.front_weight,"steps":step}
            previous=rig.scale.x;before=after
        rows.append({"hz":hz,"crossing":crossing,"peaks":peaks})
        check(not crossing.is_empty(),"fixture did not cross facing")
        for region in ["body","near_arm","far_arm"]:
            check(crossing["steps"][region]<3,"visible body region jumps at facing handoff: "+region)

    # Identical minor opposing input, with and without a bubble hold.
    for cast in [false,true]:
        rig.reset_performance();rig.set_motion(Vector2(280,0),1,false,false,1);rig.set_steering(Vector2.RIGHT)
        for i in range(60):rig._process(1.0/60)
        rig.set_bubble_charge(cast,.5);rig.set_steering(Vector2(-.1,0));rig.set_motion(Vector2(270,0),-1,false,false,1);rig._process(1.0/60)
        check(rig.grace_motion.presentation_facing==1,"minor aiming input reverses travel presentation")
        rows.append({"cast":cast,"tiny_input_facing":rig.grace_motion.presentation_facing,"physical_velocity_x":rig.velocity_value.x})
    rig.free();await process_frame
    print("SARAH TURN REGRESSION: 14 assertions, ",failures," failures; ",JSON.stringify(rows))
    quit(1 if failures else 0)

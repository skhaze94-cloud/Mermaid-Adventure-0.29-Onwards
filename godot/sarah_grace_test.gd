extends SceneTree
const Grace=preload("res://godot/sarah_grace_motion.gd")
var checks:=0
var failures:=0
func check(ok: bool,note: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        if failures<15:push_error("SARAH GRACE: "+note)
func _initialize() -> void:call_deferred("run")
func step(rig,velocity: Vector2,steering: Vector2,dt: float) -> void:
    rig.set_steering(steering);rig.set_motion(velocity,-1 if velocity.x<0 else 1,false,false,1);rig._process(dt)
func run() -> void:
    root.get_node("AppPreferences").persist_enabled=false;root.get_node("OceanAudio").playback_enabled=false
    var rig=load("res://godot/sarah_rig.gd").new();root.add_child(rig);rig.set_process(false)
    rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.jump_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    var endpoints:=[]
    for hz in [30,60,120]:
        rig.reset_jump();rig.reset_performance()
        for i in range(hz*2):step(rig,Vector2(345,0),Vector2.RIGHT,1.0/hz)
        # The actual controller stops in about .17 seconds. The pose settles longer.
        var velocity:=Vector2(345,0)
        for i in range(int(hz*.3)):
            velocity=load("res://godot/sarah_motion.gd").swim_velocity(velocity,Vector2.ZERO,1.0/hz)
            step(rig,velocity,Vector2.ZERO,1.0/hz)
        check(velocity==Vector2.ZERO,"stop test did not physically stop")
        check(rig.brake_blend>.12 and rig.settle_blend>.12,"stop pose dies before its follow-through")
        endpoints.append(rig.brake_blend)
        for i in range(hz*2):step(rig,Vector2.ZERO,Vector2.ZERO,1.0/hz)
        check(rig.brake_blend<.002 and rig.settle_blend<.003,"stopping residue never settles")
        check(not rig.gesture_player.is_playing(),"a stop triggers an unsolicited wave")
        # Jitter points against existing travel, without committing a full turn.
        for i in range(hz):
            rig.set_steering(Vector2(-.12,0));rig.set_motion(Vector2(220,0),-1,false,false,1);rig._process(1.0/hz)
            check(rig.grace_motion.presentation_facing==1.0,"tiny opposing input reverses the whole character")
        rig.set_steering(Vector2.LEFT);rig.set_motion(Vector2(120,0),-1,false,false,1);rig._process(1.0/hz)
        check(rig.grace_motion.presentation_facing==-1.0,"decisive input delays turn intent")
        for lead_tick in range(int(hz*.09)):
            rig.set_steering(Vector2.LEFT);rig.set_motion(Vector2(120,0),-1,false,false,1);rig._process(1.0/hz)
        check(rig.grace_motion.gaze_lead.x<0 and rig.definitive_21.heading.x>0,"gaze does not lead the body through reversal")
        for i in range(hz):step(rig,Vector2(-280,0),Vector2.LEFT,1.0/hz)
        check(rig.definitive_21.heading.x<-.98,"deliberate turn never completes")
        # A light held stick must still complete a real low-speed reversal.
        rig.reset_jump();rig.reset_performance()
        for i in range(hz):step(rig,Vector2(220,0),Vector2.RIGHT,1.0/hz)
        velocity=Vector2(220,0)
        var premature:=false
        for i in range(hz/2):
            velocity=load("res://godot/sarah_motion.gd").swim_velocity(velocity,Vector2(-.12,0),1.0/hz)
            rig.set_steering(Vector2(-.12,0));rig.set_motion(velocity,-1,false,false,1);rig._process(1.0/hz)
            if velocity.x>24 and rig.grace_motion.presentation_facing<0:premature=true
        check(not premature,"light held input flips before travel reverses")
        check(velocity.x<-24 and rig.grace_motion.presentation_facing==-1.0,"light held input leaves Sarah swimming backwards")
    check(absf(endpoints[0]-endpoints[2])<.06,"stop envelope depends excessively on refresh rate")
    # Retiming is monotonic and C1 across the wrap, with a real relaxed interval.
    var smallest:=INF;var largest:=0.0;var previous:=0.0
    for i in range(1001):
        var p:=float(i)*TAU/1000
        var mapped:=p-.52*sin(p)
        if i>0:smallest=minf(smallest,mapped-previous);largest=maxf(largest,mapped-previous)
        previous=mapped
    check(smallest>0 and largest/smallest>3,"stroke has no longer extension or reverses time")
    rig.reset_performance();rig.set_motion(Vector2(280,0),1,false,false,1);rig.set_steering(Vector2.RIGHT)
    var glide_frames:=0;var pull_frames:=0;var waist_error:=0.0
    for i in range(360):
        rig._process(1.0/60)
        if rig.grace_motion.glide>.6:glide_frames+=1
        if rig.grace_motion.glide<.1:pull_frames+=1
        waist_error=maxf(waist_error,rig.tail_skin.to_global(rig.tail_skin.socket).distance_to(rig.torso.to_global(rig.torso_motion.HIP_PIVOT)))
        for index in range(2):check(rig.definitive_21.attachment_error(rig,index)<.0001,"grace pose opens a shoulder socket")
    check(glide_frames>35 and pull_frames>100,"continuous cruising lacks distinct glide and pull")
    check(waist_error<.001,"grace timing opens the shared waist")
    # A moving cast/boost takes ownership from the greeting immediately.
    for action in ["cast","boost","jump","impact"]:
        rig.reset_jump();rig.reset_performance();rig.play_gesture("greet")
        if action=="cast":rig.set_bubble_charge(true,.7)
        elif action=="boost":rig.set_motion(Vector2(760,0),1,true,false,1)
        elif action=="jump":rig.start_jump(0,1);rig.set_jump_state("airborne",.3,0,1)
        else:rig.play_impact()
        rig._process(1.0/60)
        check(rig.definitive_21.action==action,"action priority lost: "+action)
        check(rig.gesture_wave==0,"greeting survives an important action")
    rig.reset_jump();rig.reset_performance();rig.jump_style=2
    check(absf(rig._jump_roll(.5))<.3,"ordinary jump performs a full spin")
    rig.jump_chain=2;check(absf(rig._jump_roll(.5))>2,"chained jump lost its celebratory spin")
    rig.reset_jump();rig.reset_performance()
    var clock: float=rig.clock;rig._process(0);check(rig.clock==clock,"pause advances grace motion")
    rig.hide();rig._process(.05);check(rig.clock==clock,"hidden rig advances grace motion");rig.show()
    check(rig.grace_motion.stop_energy==0 and rig.grace_motion.gaze_lead==Vector2.ZERO and rig.grace_motion.phase==0,"retry retains grace state")
    rig.free();await process_frame
    print("SARAH GRACE: ",checks," checks, ",failures," failures")
    quit(1 if failures else 0)

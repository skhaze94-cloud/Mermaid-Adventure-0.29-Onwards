extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,note: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        if failures<12:push_error('CONNECTED SARAH: '+note)
func _initialize() -> void:call_deferred('run')
func run() -> void:
    root.get_node('AppPreferences').persist_enabled=false;root.get_node('OceanAudio').playback_enabled=false
    var rig=load('res://godot/sarah_rig.gd').new();root.add_child(rig);rig.set_process(false)
    rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.jump_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    var maximum_step:=0.0;var minimum_width:=INF;var maximum_tangent_error:=0.0
    var cross_step:=0.0;var samples:=[]
    for hz in [30,60,120]:
        rig.reset_jump();rig.reset_performance();rig.set_steering(Vector2.RIGHT);rig.set_motion(Vector2(280,0),1,false,false,1)
        for i in range(hz*2):rig._process(1.0/hz)
        var previous:=PackedVector2Array();var previous_heading:=1.0
        for i in range(hz):
            rig.set_steering(Vector2.LEFT);rig.set_motion(Vector2(-280,0),-1,false,false,1);rig._process(1.0/hz)
            var skin=rig.tail_skin;var transform: Transform2D=skin.get_global_transform()
            var current:=PackedVector2Array()
            for c in range(193):current.append(transform*skin.polygon[6*193+c])
            var frame_step:=0.0
            if previous.size()==193:
                for c in range(193):frame_step=maxf(frame_step,current[c].distance_to(previous[c]))
            maximum_step=maxf(maximum_step,frame_step)
            if previous_heading>0 and rig.definitive_21.heading.x<0:cross_step=maxf(cross_step,frame_step)
            previous_heading=rig.definitive_21.heading.x;previous=current
            for c in [15,40,80,120,165,180]:
                var cross_section: Vector2=transform*(skin.polygon[12*193+c])-transform*(skin.polygon[c])
                var spine: Vector2=current[maxi(0,c-1)]-current[mini(192,c+1)]
                var effective_width:=absf(spine.normalized().cross(cross_section))
                minimum_width=minf(minimum_width,effective_width)
                check(effective_width>47,'projected width collapses into a ribbon at '+str(hz)+'Hz frame '+str(i))
            for row in range(13):
                var a: Vector2=rig.connected_waist.polygon[row*13]
                var b: Vector2=rig.connected_waist.polygon[row*13+12]
                check(a.distance_to(b)>18,'broad waist loft collapses across its width')
            check(rig.bodice.visible and rig.tail_skin.visible and rig.connected_waist.visible,'an anatomical skin becomes invisible')
            check(rig.definitive_21.attachment_error(rig,1)<.0001,'arm socket leaves deformed bodice')
            check(rig.bodice.polygon.size()==975 and skin.polygon.size()==2509 and rig.connected_waist.polygon.size()==169,'steady turn rebuilds topology')
            if hz==60:samples.append({'frame':i,'heading':rig.definitive_21.heading.x,'view':rig.definitive_21.front_weight,'centerline_step':frame_step})
    # Original model-space arc remains length-preserving despite projected depth.
    var length:=0.0
    for c in range(1,193):length+=rig.tail_skin.centers[c].distance_to(rig.tail_skin.centers[c-1])
    check(absf(length-rig.tail_skin.tail_length)<.01,'tail model arc stretches')
    check(cross_step<30,'signed coordinate crossing produces a visible centerline snap')
    for mode in ['Full','Economy','Gentle']:
        rig.reset_performance();rig.set_quality(mode!='Economy');rig.reduced_motion=mode=='Gentle'
        rig.set_motion(Vector2(280,0),1,false,false,1)
        for i in range(90):rig._process(1.0/60)
        check(rig.connected_waist.polygon.size()==169 and rig.connected_waist.polygon[0].is_finite(),'mode loses connected waist')
    var clock: float=rig.clock;rig._process(0);check(rig.clock==clock,'pause advances character');rig.hide();rig._process(.05);check(rig.clock==clock,'hidden rig advances character')
    rig.show();rig.reset_performance();check(rig.definitive_21.heading==Vector2(1,0),'retry retains turn')
    var metrics:={'checks':checks,'failures':failures,'maximum_centerline_step':maximum_step,'crossing_centerline_step':cross_step,'minimum_effective_full_grid_width':minimum_width,'samples':samples}
    var file:=FileAccess.open('res://verification/connected36/sarah-connected-metrics.json',FileAccess.WRITE);file.store_string(JSON.stringify(metrics,'  '));file.close()
    rig.free();await process_frame;print('CONNECTED SARAH: ',checks,' checks, ',failures,' failures; min projected width ',minimum_width,' crossing displacement ',cross_step);quit(1 if failures else 0)

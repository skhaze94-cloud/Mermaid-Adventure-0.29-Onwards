extends SceneTree
const Princess = preload("res://godot/sarah_princess_motion.gd")
var checks := 0
var failures := 0
func check(ok: bool, why: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error("PRINCESS SARAH: "+why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var rig = load("res://godot/sarah_rig.gd").new()
    root.add_child(rig);rig.set_process(false);rig.reset_performance()
    check(rig.tail_skin.rest.size()==7605 and rig.face_details.rest.size()==28665,"Tail/face detail does not triple v0.4")
    check(rig.bodice.rest.size()==975 and rig.arm_meshes[1].rest.size()==891,"Body/arm detail does not triple v0.4")
    check(rig.ribbons[0].rest.size()==765,"Hair detail does not triple v0.4")
    rig.face_details.adapt_detail(true)
    check(not rig.face_details.full_detail,"Normal gameplay shades unnecessary face subdivisions")
    rig.face_sprite.scale*=2.0
    rig.face_details.adapt_detail(true)
    check(rig.face_details.full_detail,"Close-up loses full face articulation")
    rig.face_sprite.scale*=.5
    rig.face_details.adapt_detail(true)
    check(rig.face_details.polygons.size()<rig.face_details.full_triangles.size(),"Adaptive face topology does not reduce draw work")
    check(rig.face_details.rest.size()==28665,"Adaptive drawing discards authored face points")
    for i in range(300):
        var weights := Princess.weights(float(i)*.1)
        check(absf(weights.x+weights.y+weights.z-1.0)<.0001 and weights.x>=0 and weights.y>=0 and weights.z>=0,"Variation weights invalid")
    for direction in [1.0,-1.0]:
        rig.set_motion(Vector2(760*direction,-120),direction,true,false,1)
        for frame in range(180):
            rig._process(1.0/60)
            check(rig.swim_wake.droplets.size()<=rig.swim_wake.LIMIT,"Wake exceeds particle budget")
        check(rig.arm_pose_near.x<-.55 and absf(rig.arm_pose_near.y)<.06,"Boost does not hold streamlined arms")
        check(rig.swim_wake.droplets.size()>0,"Boost wake missing")
        var old: Vector2 = rig.swim_wake.droplets[0].position
        rig.position+=Vector2(100,25)
        rig.facing_value=-direction
        rig._process(1.0/120)
        check(rig.swim_wake.droplets[0].position.distance_to(old)<2.0,"Turning or moving Sarah drags world-space wake")
    var aerial := {}
    rig.jump_style_cursor=0
    for i in range(18):
        rig.start_jump(0,1)
        aerial[rig.jump_style]=true
        check(is_zero_approx(rig._jump_roll(0)),"Aerial variation starts with a snap")
        check(absf(rig._jump_roll(1))<.001 or rig.jump_style%6==2,"Aerial variation ends with a snap")
    check(aerial.size()==18,"Aerial performances have not tripled")
    rig.reset_jump()
    rig.set_motion(Vector2.ZERO,1,false,false,1)
    for frame in range(120): rig._process(1.0/60)
    check(rig.swim_wake.droplets.is_empty(),"Idle retains stale wake")
    rig.set_motion(Vector2(760,0),1,true,false,1)
    for frame in range(30): rig._process(1.0/60)
    rig.reduced_motion=true;rig._process(1.0/60)
    check(rig.swim_wake.droplets.is_empty(),"Gentle mode retains effects")
    rig.reduced_motion=false;rig.set_quality(false);rig._process(1.0/60)
    check(rig.swim_wake.droplets.is_empty(),"Economy mode retains effects")
    rig.reset_performance()
    check(rig.swim_wake.droplets.is_empty() and rig.princess_variation==Vector3.ZERO,"Restart retains princess motion")
    rig.free()
    print("PRINCESS SARAH: %d checks, %d failures" % [checks,failures])
    quit(0 if failures==0 else 1)

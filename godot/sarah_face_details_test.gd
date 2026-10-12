extends SceneTree
const Details = preload("res://godot/sarah_face_details.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, why: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error("SARAH FACE DETAILS: "+why)
func run() -> void:
    var level = load("res://godot/highland_level.tscn").instantiate()
    root.add_child(level)
    level.set_process(false)
    level.set_physics_process(false)
    var rig = level.native_rig
    rig.set_process(false)
    rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.jump_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.reset_jump()
    rig.reset_performance()
    var mesh = rig.face_details
    var surface = mesh.surface
    var uv: PackedVector2Array = mesh.uv.duplicate()
    var rest: PackedVector2Array = mesh.polygon.duplicate()
    var identity: int = mesh.get_instance_id()
    var nodes: int = rig.get_child_count()
    check(mesh.get_parent()==rig.face_sprite and rig.face_sprite.get_parent()==rig.head_joint,"Face details lost skull hierarchy")
    check(rig.face_sprite.self_modulate.a==0,"Original face quad would double-draw")
    check(mesh.rest.size()==28665 and mesh.polygons.size()==56064,"Connected detail surface lacks local resolution")
    check(mesh.texture==rig.EXPRESSIONS,"Details replace original face artwork")
    # Every stroke and action must feed the same whole-body response.
    for state in [[Vector2.ZERO,1.0,false,""],[Vector2(345,0),1.0,false,""],
            [Vector2(20,-330),1.0,false,""],[Vector2(20,330),1.0,false,""],
            [Vector2(760,0),1.0,true,""],[Vector2(-345,0),-1.0,false,""],
            [Vector2.ZERO,1.0,false,"pull"],[Vector2(80,-430),1.0,false,"descent"],
            [Vector2(700,120),1.0,true,"descent"],[Vector2(160,0),1.0,false,"outflow"]]:
        rig.set_waterfall_context(state[3])
        rig.set_motion(state[0],state[1],state[2],false,1)
        var old_gaze: Vector2 = rig.detail_gaze
        var old_smile: float = rig.expression_blend
        for tick in range(180):
            rig._process(1.0/120)
            var response: Vector4 = surface.get_shader_parameter("response")
            check(is_equal_approx(response.z,rig.depth_turn),"Face yaw disagrees with body yaw")
            check(is_equal_approx(response.w,rig.boost_blend),"Face effort disagrees with boost")
            check(is_equal_approx(float(surface.get_shader_parameter("body_wave")),rig.cycle_pose.y),"Hair phase disagrees with tail wave")
            check(is_equal_approx(float(surface.get_shader_parameter("motion_phase")),rig.swim_clock),"Face has an independent stroke clock")
            check(rig.detail_gaze.length()<=1.001 and rig.detail_gaze.is_finite(),"Gaze exceeds subtle limits")
            check(rig.detail_gaze.distance_to(old_gaze)<.13,"Gaze snaps during directional changes")
            check(absf(rig.expression_blend-old_smile)<.08,"Smile snaps during action changes")
            check(rig.face_sprite.position==Vector2(-51,-69),"Face registration/neck attachment moves")
            old_gaze=rig.detail_gaze
            old_smile=rig.expression_blend
    # Blinks close/reopen locally while ears, nose, mouth and hair keep one painting.
    var previous := Details.blink_at(4.3)
    var fully_closed := false
    for tick in range(84):
        var blink := Details.blink_at(4.3+tick/120.0)
        check(blink>=0 and blink<=1,"Blink envelope out of range")
        check(absf(blink-previous)<.22,"Blink has a hard texture jump")
        fully_closed=fully_closed or blink>.99
        previous=blink
    check(fully_closed and Details.blink_at(4.7)==0,"Blink never fully closes/reopens")
    check(is_zero_approx(Details.blink_at(0)-Details.blink_at(4.7)),"Blink period has a seam")
    check(mesh.texture==rig.EXPRESSIONS and mesh.uv==uv and mesh.polygon==rest,"Expression slides or rebuilds painted surface")
    check(mesh.get_instance_id()==identity and rig.get_child_count()==nodes,"Per-frame facial node allocation")
    level._set_paused(true)
    check(not rig.can_process(),"Facial detail continues during pause")
    level._set_paused(false)
    rig.reduced_motion=true
    rig._process(1.0/60)
    check(not surface.get_shader_parameter("detail_enabled") and surface.get_shader_parameter("gaze")==Vector2.ZERO,"Gentle motion retains local facial movement")
    rig.reduced_motion=false
    rig.set_quality(false)
    rig._process(1.0/60)
    check(not surface.get_shader_parameter("detail_enabled"),"Economy keeps facial deformation")
    rig.set_quality(true)
    rig._process(1.0/60)
    check(surface.get_shader_parameter("detail_enabled"),"Returning to quality fails to restore details")
    var endpoints := []
    for fps in [30,60,120]:
        rig.reset_jump()
        rig.reset_performance()
        rig.set_motion(Vector2(760,-180),1,true,false,1)
        for tick in range(fps*3): rig._process(1.0/fps)
        endpoints.append([rig.detail_gaze,rig.expression_blend])
    check(endpoints[0][0].distance_to(endpoints[2][0])<.005,"Gaze depends on refresh rate")
    check(absf(endpoints[0][1]-endpoints[2][1])<.001,"Smile depends on refresh rate")
    level._restart()
    check(rig.detail_gaze==Vector2.ZERO and rig.expression_blend==0 and rig.blink_blend==0,"Restart retains expression/gaze")
    check(not surface.get_shader_parameter("detail_enabled") and surface.get_shader_parameter("response")==Vector4.ZERO,"Restart retains ear/nose/hair response")
    level.free()
    print("SARAH FACE DETAILS: %d checks, %d failures" % [checks,failures])
    quit(1 if failures else 0)

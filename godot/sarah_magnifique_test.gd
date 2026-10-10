extends SceneTree
const Motion = preload("res://godot/sarah_motion.gd")
const Controls = preload("res://godot/control_layout.gd")
var failures := 0
func _initialize() -> void:
    call_deferred("_run")
func check(ok: bool, why: String) -> void:
    if not ok:
        failures += 1
        push_error("SARAH MAGNIFIQUE: " + why)
func _run() -> void:
    var v := Vector2.ZERO
    for tick in range(13):
        v = Motion.swim_velocity(v,Vector2.RIGHT,1.0/60.0)
    check(is_equal_approx(v.x,345.0), "Full swim speed should arrive within 13 fixed ticks")
    for tick in range(10):
        v = Motion.swim_velocity(v,Vector2.ZERO,1.0/60.0)
    check(v == Vector2.ZERO, "Releasing steering must stop within ten ticks")
    v = Vector2(345.0,0.0)
    for tick in range(22):
        v = Motion.swim_velocity(v,Vector2.LEFT,1.0/60.0)
    check(v.x < -340.0, "Reversal is still sluggish")
    for tick in range(60):
        v = Motion.swim_velocity(v,Vector2(0.5,0),1.0/60.0)
    check(is_equal_approx(v.x,172.5), "Analogue precision must preserve half speed")
    v = Motion.swim_velocity(Vector2.ZERO,Vector2.ONE,1.0)
    check(is_equal_approx(v.length(),345.0), "Diagonal steering gains unfair speed")
    var center := Controls.pad_rect(Vector2(1400,960)).get_center()
    check(Controls.pad_vector(center+Vector2(18,0),Vector2(1400,960)) == Vector2.ZERO, "Touch dead zone changed")
    check(is_equal_approx(Controls.pad_vector(center+Vector2(30,0),Vector2(1400,960)).x,0.5), "Touch precision range missing")
    check(is_equal_approx(Controls.pad_vector(center+Vector2(42,0),Vector2(1400,960)).x,1.0), "Outer pad must reach full speed")
    var level = load("res://godot/highland_level.tscn").instantiate()
    root.add_child(level)
    level.set_process(false)
    level.set_physics_process(false)
    var rig = level.native_rig
    rig.set_process(false)
    rig.gesture_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.reset_performance()
    check(rig.ribbons.size() == 3, "Continuous tail and anchored hair skins missing")
    check(rig.arm_meshes.size() == 2, "Continuous elbow/wrist skin missing")
    var count: int = rig.get_child_count()
    var uv_before: PackedVector2Array = rig.ribbons[0].uv
    rig.set_motion(Vector2(300,120),1.0,false,false,1.0)
    for tick in range(30):
        rig._process(1.0/60.0)
    check(rig.ribbons[0].polygon != rig.ribbons[0].rest, "Hair mesh remains rigid")
    check(rig.ribbons[0].uv == uv_before, "Deforming hair changes its atlas coordinates")
    for ribbon in rig.ribbons:
        for i in range(ribbon.rest.size()):
            if ribbon.weights[i] == 0.0:
                check(ribbon.polygon[i] == ribbon.rest[i], "Attachment seam must remain fixed")
    for arm in rig.arm_meshes:
        check(arm.polygon[0] == arm.rest[0], "Painted shoulder sleeve has detached")
    var phase_before: float = rig.swim_clock
    rig.set_motion(Vector2.ZERO,1.0,false,false,1.0)
    rig._process(1.0/60.0)
    check(rig.swim_clock > phase_before and rig.swim_clock-phase_before < 0.2, "Changing speed jumps the swim phase")
    rig.set_motion(Vector2(-300,0),-1.0,false,false,1.0)
    rig._process(1.0/60.0)
    check(absf(rig.scale.x) > 0.8, "Turning collapses Sarah's silhouette")
    rig.play_gesture("cast")
    rig.gesture_player.advance(0.105)
    check(rig.gesture_reach > 0.95, "Bubble reach timeline missing")
    rig.play_impact()
    check(rig.gesture_player.current_animation == "impact", "Damage should interrupt casting")
    rig.play_gesture("greet")
    check(rig.gesture_player.current_animation == "impact", "Idle greeting interrupts damage response")
    rig.set_quality(false)
    rig._process(1.0/60.0)
    for ribbon in rig.ribbons:
        check(ribbon.polygon == ribbon.rest, "Economy must reset flexible mesh shapes")
    rig.set_quality(true)
    rig.reduced_motion = true
    rig._process(1.0/60.0)
    for ribbon in rig.ribbons:
        check(ribbon.polygon == ribbon.rest, "Gentle motion must keep mesh flutter off")
    level.bubble_unlocked = true
    level._fire_bubble()
    check(level.bubble_shots.size() == 1 and rig.gesture_player.current_animation == "cast", "Actual bubble input must trigger the gesture and shot together")
    var shots: int = level.bubble_shots.size()
    level._fire_bubble()
    check(level.bubble_shots.size() == shots, "Gestures must not bypass projectile cooldown")
    level._set_paused(true)
    check(not rig.gesture_player.can_process(), "Performance continues while paused")
    level._set_paused(false)
    level._restart()
    check(not rig.gesture_player.is_playing() and rig.gesture_reach == 0 and rig.turn_elapsed == 1.0, "Restart retains a previous performance")
    check(rig.get_child_count() == count, "Animation creates new rig nodes")
    root.remove_child(level)
    level.free()
    if failures == 0: print("GODOT SARAH MAGNIFIQUE TEST PASSED")
    quit(0 if failures == 0 else 1)


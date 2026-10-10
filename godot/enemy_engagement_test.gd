extends SceneTree
const Combat = preload("res://godot/enemy_combat.gd")
var failures := 0
func check(ok: bool, why: String) -> void:
    if not ok:
        failures += 1
        push_error("ENEMY ENGAGEMENT: "+why)
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var empty: Array[Rect2] = []
    for kind in ["crab","eel","jelly","puffer","swordfish","shark"]:
        var e := {"kind":kind,"x":500.0,"y":600.0,"bx":500.0,"by":600.0,"hp":1,"phase":0.0,"dir":1}
        var target := Vector2(790,600) if kind == "crab" else Vector2(920,600)
        var approached := false
        var attacked := false
        var recovered := false
        var locked := Vector2.ZERO
        for tick in range(600):
            Combat.step(e,target,tick/60.0,1.0/60.0,empty)
            approached = approached or e["mode"] == "approach"
            if e["mode"] == "attack":
                if not attacked: locked = e["aim"]
                attacked = true
                check(Vector2(e["aim"]).is_equal_approx(locked),kind+" attack homes after commitment")
                target = Vector2(100,780) # Dodge after commitment.
            elif attacked and e["mode"] == "recover": recovered = true
            if recovered and e["mode"] == "patrol": break
        check(approached and attacked and recovered,kind+" fails approach / attack / recovery")
        check(Vector2(e["x"],e["y"]).distance_to(Vector2(500,600)) < 100,kind+" never returns to its territory")
    var h := {"kind":"eel","at":2.3,"x":-0.55,"passed":false}
    var locked := Vector2.ZERO
    var first_attack := -1.0
    var windup_at := -1.0
    for tick in range(180):
        var clock := 0.7+tick/60.0
        Combat.step_waterfall(h,Vector2(870,384),Vector2(100,0),clock,1.0/60.0,1400,520,true)
        if h["mode"] == "windup" and windup_at < 0: windup_at = clock
        if h["mode"] == "attack":
            if first_attack < 0:
                first_attack = clock
                locked = h["aim"]
            check(Vector2(h["aim"]).is_equal_approx(locked),"Waterfall lunge must lock its aim")
    check(first_attack-windup_at >= 0.63,"Waterfall attack has no dodge warning")
    check(Vector2(h["offset"]).x > 20,"Waterfall eel never leaves its scrolling lane")
    var level = load("res://godot/highland_level.tscn").instantiate()
    root.add_child(level)
    level.set_process(false)
    level.set_physics_process(false)
    level._start_waterfall()
    level.waterfall_phase = "descent"
    level.waterfall_time = 0.0
    level.invulnerable = 999.0
    var saw_attack := false
    for tick in range(1000):
        level._update_waterfall(1.0/60.0)
        if level.waterfall_phase != "descent": break
        var active := 0
        for hazard in level.waterfall_hazards:
            if not hazard["passed"] and hazard.get("mode","") == "attack": active += 1
        check(active <= 1,"Overlapping waterfall lunges remove the dodge lane")
        saw_attack = saw_attack or active == 1
        level._sync_native_visuals()
        for i in range(level.waterfall_hazards.size()):
            var hazard: Dictionary = level.waterfall_hazards[i]
            var pos := Combat.waterfall_position(hazard,level.waterfall_time,1400,520)
            check(is_equal_approx(level.waterfall_models[i]["x"],pos.x),"Waterfall portrait and collision diverge")
    check(saw_attack,"Real waterfall never commits to a lunge")
    level._restart()
    level._start_waterfall()
    for hazard in level.waterfall_hazards:
        check(not hazard.has("offset") and not hazard.has("mode"),"Retry retains previous waterfall pursuit")
    root.remove_child(level)
    level.free()
    if failures == 0: print("GODOT ENEMY ENGAGEMENT TEST PASSED")
    quit(0 if failures == 0 else 1)

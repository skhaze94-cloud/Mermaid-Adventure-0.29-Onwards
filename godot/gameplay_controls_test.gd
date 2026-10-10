extends SceneTree
const Controls = preload("res://godot/control_layout.gd")
const Combat = preload("res://godot/enemy_combat.gd")
var failures := 0

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, reason: String) -> void:
    if not ok:
        failures += 1
        push_error("GAMEPLAY CHECK: " + reason)

func _run() -> void:
    var level = load("res://godot/highland_level.tscn").instantiate()
    root.add_child(level)
    level.set_process(false)
    level.set_physics_process(false)
    # Start a real jump near the bottom; it must pass through ascent and air.
    level.player = Vector2(1000, 830)
    level._jump()
    level._update_swimming(1.0 / 60.0)
    check(level.leap_phase == "ascent" and level.player.y < 830, "deep jump cancelled on first tick")
    var saw_air := false
    var minimum_y := 900.0
    for i in range(180):
        level._update_swimming(1.0 / 60.0)
        minimum_y = minf(minimum_y, level.player.y)
        if level.leap_phase == "airborne":
            saw_air = true
        if saw_air and level.leap_phase == "":
            break
    check(saw_air and minimum_y < level.WATER_SURFACE, "deep jump never breaches water")
    check(level.leap_phase == "" and level.splash_window > 0, "jump does not splash down")
    var before: int = level.score
    level._jump()
    check(level.splash_chain == 1 and level.score == before + 100, "post-splash chain missing")
    # Buffered input near landing executes once, with bounded chain rewards.
    level.leap_phase = "airborne"
    level.jump_time = 10
    level.player = Vector2(1000, 315)
    level.player_velocity = Vector2(0, 600)
    level._jump()
    level._update_swimming(1.0 / 60.0)
    check(level.splash_chain == 2 and level.leap_phase == "ascent", "pre-splash buffer lost")
    level._restart()
    level.facing = -1
    level.player_velocity.x = -400
    level._jump()
    check(level.player_velocity.x < -390, "left jump loses existing momentum")
    # Jump ascent is still vulnerable underwater, rather than invincible for seconds.
    level.invulnerable = 0
    level.player.y = 700
    level._damage(level.player + Vector2.RIGHT)
    check(level.health == 4, "underwater ascent incorrectly grants immunity")
    level._restart()
    # Fixed physics simulation duration is independent of render cadence.
    level._start_waterfall()
    for i in range(1224): # 20.4 seconds = entry + descent + outflow
        level.health = 5
        level.invulnerable = 1
        level._physics_process(1.0 / 60.0)
    check(level.fallen and level.waterfall_phase == "", "fixed-tick waterfall duration changed")
    # A complete rollback avoids retry farming score and waterfall pearls.
    level._restart()
    level._start_waterfall()
    level.score += 200
    level.picked_count += 10
    level.enemies[0]["hp"] = 0
    level.treasures[0]["taken"] = true
    level.health = 0
    level._respawn()
    check(level.score == 0 and level.picked_count == 0, "retry duplicates waterfall rewards")
    check(level.enemies[0]["hp"] == 1 and not level.treasures[0]["taken"], "checkpoint does not restore encounters")
    check(level.waterfall_boost == 0 and level.hostile_shots.is_empty(), "retry leaves transient attacks")
    # Input and drawing share geometry; diagonals are one finger, actions separate.
    var size := Vector2(1400, 960)
    var center: Vector2 = level._pad_rect().get_center()
    level._set_touch(8, center + Vector2(45, -45) * level.premium_hud.ui_scale, "pad")
    level._set_touch(12, level._touch_rect("boost", size).get_center(), "boost")
    var steering: Vector2 = level._input_vector()
    check(steering.x > 0.6 and steering.y < -0.6, "single-finger diagonal steering missing")
    check(level.touches[12] == "boost", "second finger ownership lost")
    check(Controls.pad_vector(Controls.pad_rect(size).get_center(), size) == Vector2.ZERO, "pad dead zone missing")
    check(Controls.radial_stick(Vector2(0.1, 0)) == Vector2.ZERO, "controller dead zone missing")
    check(is_equal_approx(Controls.radial_stick(Vector2(0.6, 0)).x, 0.5), "controller analogue range discontinuous")
    check(Controls.controller_id(-1, [4]) == 4, "controller assumes device zero")
    check(Controls.controller_id(4, [2, 4]) == 4, "controller switches valid device")
    check(Controls.controller_id(4, []) == -1, "controller disconnect not cleared")
    level._set_paused(true)
    check(paused and level.touches.is_empty() and level.touch_vectors.is_empty(), "pause fails to clear held touch")
    check(not level.world_depth.can_process() and not level.native_rig.can_process(), "world animations continue while paused")
    check(level._touch_target(level._touch_rect("resume", size).get_center()) == "resume", "resume button cannot be reached")
    var paused_time: float = level.time
    level._physics_process(1)
    check(level.time == paused_time, "gameplay clock advances while paused")
    level._touch_action("resume")
    check(not paused and level.state == "playing", "touch resume fails")
    check(level._touch_target(level._touch_rect("restart", size).get_center()) != "restart", "invisible restart active during gameplay")
    # Species lock aim before attack; player movement cannot instantly retarget it.
    for kind in ["eel", "swordfish", "shark", "crab", "puffer", "jelly"]:
        var enemy := {"kind": kind, "x": 1000.0, "y": 600.0, "bx": 1000.0, "by": 600.0, "phase": 0.0, "hp": 1, "dir": 1}
        Combat.step(enemy, Vector2(1100, 600), 0, 0.01, [])
        enemy["cooldown"] = 0
        Combat.step(enemy, Vector2(1100, 600), 0, 0.01, [])
        check(enemy["mode"] == "windup", kind + " missing telegraph")
        # Early windup may track; the final warning and attack must stay locked.
        for i in range(30):
            Combat.step(enemy,Vector2(900,400),0,1.0/60.0,[])
        var aim: Vector2 = enemy["aim"]
        var fired := false
        for i in range(31):
            if Combat.step(enemy, Vector2(1250, 780), 0, 1.0 / 60.0, []) == "fire":
                fired = true
        check(Vector2(enemy["aim"]) == aim, kind + " retargets committed attack")
        check(enemy["mode"] == "attack", kind + " never attacks")
        if kind in ["puffer", "jelly"]:
            check(fired, kind + " does not emit projectile")
    level._restart()
    level.player = Vector2(level.Highland.BOSS_X - 500, 500)
    level._update_boss(0.01)
    var locked: Vector2 = level.boss_target
    level.player.y = 800
    level._update_boss(0.5)
    check(level.boss_target == locked and not level._boss_vulnerable(), "Carlo windup tracks player or exposes early")
    level._update_boss(0.5)
    check(level.boss_phase == "attack", "Carlo attack missing")
    level._update_boss(0.7)
    check(level._boss_vulnerable(), "Carlo recovery missing")
    level._update_boss(2.2)
    check(level.boss_pattern == 1 and level.boss_phase == "windup", "Carlo pattern does not advance")
    level._update_boss(1)
    check(level.hostile_shots.size() == 3, "Carlo volley missing")
    level.native_boss.defeat()
    level._restart()
    check(not level.native_boss.defeating and not level.native_boss.defeat_tween.is_running(), "restart leaves defeat tween running")
    level.bubble_unlocked = true
    for i in range(20):
        level._fire_bubble()
    check(level.bubble_shots.size() == 1, "bubble firing bypasses cooldown")
    level._restart()
    root.remove_child(level)
    level.free()
    print("GODOT GAMEPLAY CONTROLS TEST " + ("PASSED" if failures == 0 else "FAILED: " + str(failures)))
    quit(0 if failures == 0 else 1)

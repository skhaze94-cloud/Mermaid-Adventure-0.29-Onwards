extends RefCounted
## Species-specific, locked attacks. Each encounter telegraphs before committing.
static func step(enemy: Dictionary, target: Vector2, clock: float, dt: float,
        obstacles: Array[Rect2]) -> String:
    if not enemy.has("mode"):
        enemy["mode"] = "patrol"
        enemy["mode_time"] = 0.0
        enemy["cooldown"] = 1.0 + fmod(float(enemy["phase"]), 3.0) * 0.4
        enemy["aim"] = Vector2.LEFT
        enemy["dir"] = int(enemy.get("dir", -1))
        var spawn := Vector2(float(enemy["x"]), float(enemy["y"]))
        for obstacle in obstacles:
            var expanded := obstacle.grow(49)
            if expanded.has_point(spawn):
                var above := expanded.position.y - 1.0
                var below := expanded.end.y + 1.0
                spawn.y = below if above < 350.0 or absf(below - spawn.y) < absf(above - spawn.y) else above
        enemy["y"] = clampf(spawn.y, 350.0, 840.0)
        enemy["by"] = enemy["y"]
    var kind := String(enemy["kind"])
    var pos := Vector2(float(enemy["x"]), float(enemy["y"]))
    var previous := pos
    var anchor := Vector2(float(enemy["bx"]), float(enemy["by"]))
    var phase := float(enemy["phase"])
    var mode := String(enemy["mode"])
    enemy["mode_time"] = float(enemy["mode_time"]) + dt
    enemy["cooldown"] = maxf(0.0, float(enemy["cooldown"]) - dt)
    var previous_target: Vector2 = enemy.get("previous_target",target)
    var target_velocity := ((target-previous_target)/maxf(dt,0.001)).limit_length(500.0)
    enemy["previous_target"] = target
    var event := ""
    if mode == "patrol":
        if kind == "crab":
            pos.x += float(enemy["dir"]) * 90.0 * dt
            if absf(pos.x - anchor.x) > 170.0:
                enemy["dir"] = -int(enemy["dir"])
                pos.x = clampf(pos.x, anchor.x - 170, anchor.x + 170)
        elif kind == "jelly":
            pos = anchor + Vector2(sin(clock + phase) * 30, cos(clock * 1.6 + phase) * 55)
        else:
            pos = anchor + Vector2(sin(clock + phase) * 50, cos(clock * 1.6 + phase) * 30)
        var range_limit := 560.0 if kind != "crab" else 330.0
        if pos.distance_to(target) < range_limit and target.y > 280.0 and float(enemy["cooldown"]) <= 0.0:
            enemy["aim"] = (target - pos).normalized()
            var strike_range := 330.0 if kind in ["puffer","jelly"] else (180.0 if kind == "crab" else 270.0)
            enemy["mode"] = "windup" if pos.distance_to(target) < strike_range else "approach"
            enemy["mode_time"] = 0.0
    elif mode == "approach":
        var toward := target-pos
        enemy["aim"] = toward.normalized()
        var range_limit := 330.0 if kind in ["puffer","jelly"] else (180.0 if kind == "crab" else 270.0)
        var move := toward.normalized()
        if kind in ["puffer","jelly"]:
            # Ranged creatures orbit into a firing lane rather than pile onto Sarah.
            move = Vector2(signf(toward.x)*0.45,sin(clock*2.0+phase)*0.55)
        if kind == "crab": move.y = 0.0
        pos += move*(105.0 if kind == "crab" else 145.0)*dt
        if pos.distance_to(anchor) > 360.0 or toward.length() > 730.0 or target.y <= 280.0:
            enemy["mode"] = "recover"
            enemy["mode_time"] = 0.0
        elif toward.length() < range_limit:
            enemy["mode"] = "windup"
            enemy["mode_time"] = 0.0
    elif mode == "windup":
        # Track early, then lock the aim for the final readable warning.
        if float(enemy["mode_time"]) < 0.42:
            enemy["aim"] = (target+target_velocity*0.16-pos).normalized()

        if float(enemy["mode_time"]) >= (0.95 if kind == "puffer" else 0.75):
            enemy["mode"] = "attack"
            enemy["mode_time"] = 0.0
            if kind in ["puffer", "jelly"]:
                event = "fire"
    elif mode == "attack":
        var speed := 540.0 if kind in ["swordfish", "shark"] else (430.0 if kind == "eel" else 230.0)
        if kind not in ["puffer", "jelly"]:
            pos += Vector2(enemy["aim"]) * speed * dt
        if float(enemy["mode_time"]) >= 0.48:
            enemy["mode"] = "recover"
            enemy["mode_time"] = 0.0
    else:
        pos = pos.move_toward(anchor, dt * 160.0)
        if float(enemy["mode_time"]) >= 1.25 and pos.distance_to(anchor) < 40.0:
            enemy["mode"] = "patrol"
            enemy["mode_time"] = 0.0
            enemy["cooldown"] = 1.4
    pos.y = clampf(pos.y, 350.0, 840.0)
    for obstacle in obstacles:
        if obstacle.grow(48).has_point(pos):
            pos = previous
            enemy["mode"] = "recover"
            enemy["mode_time"] = 0.0
            break
    enemy["x"] = pos.x
    enemy["y"] = pos.y
    var aim := Vector2(enemy["aim"])
    if absf(aim.x) > 0.15 and String(enemy["mode"]) != "patrol":
        enemy["dir"] = -1 if aim.x < 0 else 1
    return event


static func waterfall_position(hazard: Dictionary, clock: float, width: float, half: float) -> Vector2:
    return Vector2(width*0.5+float(hazard["x"])*half,384.0+(float(hazard["at"])-clock)*350.0)+Vector2(hazard.get("offset",Vector2.ZERO))

static func step_waterfall(hazard: Dictionary, target: Vector2, velocity: Vector2,
        clock: float, dt: float, width: float, half: float, can_attack: bool) -> void:
    if hazard["kind"] == "reef" or hazard["passed"]: return
    if not hazard.has("mode"):
        hazard["mode"] = "patrol"
        hazard["mode_time"] = 0.0
        hazard["offset"] = Vector2.ZERO
        hazard["aim"] = Vector2.UP
    var pos := waterfall_position(hazard,clock,width,half)
    var mode := String(hazard["mode"])
    hazard["mode_time"] = float(hazard["mode_time"])+dt
    var duration := float(hazard["mode_time"])
    var offset: Vector2 = hazard["offset"]
    if mode == "patrol" and pos.y-target.y < 390.0 and pos.y > target.y+100.0:
        hazard["mode"] = "windup"
        hazard["mode_time"] = 0.0
    elif mode == "windup":
        if duration < 0.38:
            hazard["aim"] = (target+velocity.limit_length(430.0)*0.12-pos).normalized()
            offset.x = move_toward(offset.x,(target.x-pos.x)*0.25,minf(half*0.18,75.0)*dt)
        if duration >= 0.64 and can_attack:
            hazard["mode"] = "attack"
            hazard["mode_time"] = 0.0
        elif pos.y < target.y-100.0:
            hazard["mode"] = "recover"
            hazard["mode_time"] = 0.0
    elif mode == "attack":
        var speed := 310.0 if hazard["kind"] == "eel" else (220.0 if hazard["kind"] == "puffer" else 180.0)
        offset += Vector2(hazard["aim"])*speed*dt
        if duration >= 0.64:
            hazard["mode"] = "recover"
            hazard["mode_time"] = 0.0
    elif mode == "recover":
        offset = offset.move_toward(Vector2.ZERO,100.0*dt)
    offset.x = clampf(offset.x,-half*0.48,half*0.48)
    offset.x = clampf(offset.x,-half*0.84-float(hazard["x"])*half,half*0.84-float(hazard["x"])*half)
    offset.y = clampf(offset.y,-150.0,80.0)
    hazard["offset"] = offset
    hazard["dir"] = -1 if Vector2(hazard["aim"]).x < 0 else 1

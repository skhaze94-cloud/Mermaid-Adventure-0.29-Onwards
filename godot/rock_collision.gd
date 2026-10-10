extends RefCounted
## Swept axis sliding for the existing world-space rectangular reefs.
## Recover overlaps before moving, including jump re-entry and checkpoint loads.
const SKIN := 0.1

static func blocked(point: Vector2, rocks: Array[Rect2], margin: float) -> bool:
    for rock in rocks:
        if rock.grow(margin).has_point(point):
            return true
    return false

static func recover(point: Vector2, rocks: Array[Rect2], margin: float, bounds: Rect2) -> Vector2:
    var origin := Vector2(clampf(point.x, bounds.position.x, bounds.end.x), clampf(point.y, bounds.position.y, bounds.end.y))
    if not blocked(origin, rocks, margin):
        return origin
    var xs: Array[float] = [origin.x, bounds.position.x, bounds.end.x]
    var ys: Array[float] = [origin.y, bounds.position.y, bounds.end.y]
    for rock in rocks:
        var box := rock.grow(margin)
        xs.append(box.position.x - SKIN)
        xs.append(box.end.x + SKIN)
        ys.append(box.position.y - SKIN)
        ys.append(box.end.y + SKIN)
    var best := origin
    var distance := INF
    for x in xs:
        for y in ys:
            var candidate := Vector2(x, y)
            if x < bounds.position.x or x > bounds.end.x or y < bounds.position.y or y > bounds.end.y:
                continue
            var squared := candidate.distance_squared_to(origin)
            if squared < distance and not blocked(candidate, rocks, margin):
                best = candidate
                distance = squared
    return best

static func move(start: Vector2, displacement: Vector2, velocity: Vector2, rocks: Array[Rect2], margin: float, bounds: Rect2) -> Dictionary:
    var point := recover(start, rocks, margin, bounds)
    var target_x := clampf(point.x + displacement.x, bounds.position.x, bounds.end.x)
    for rock in rocks:
        var box := rock.grow(margin)
        if point.y < box.position.y or point.y >= box.end.y:
            continue
        if displacement.x > 0 and point.x < box.position.x and target_x >= box.position.x:
            target_x = minf(target_x, box.position.x - SKIN)
        elif displacement.x < 0 and point.x > box.end.x and target_x <= box.end.x:
            target_x = maxf(target_x, box.end.x + SKIN)
    var hit_x := not is_equal_approx(target_x, point.x + displacement.x)
    point.x = target_x
    var target_y := clampf(point.y + displacement.y, bounds.position.y, bounds.end.y)
    for rock in rocks:
        var box := rock.grow(margin)
        if point.x < box.position.x or point.x >= box.end.x:
            continue
        if displacement.y > 0 and point.y < box.position.y and target_y >= box.position.y:
            target_y = minf(target_y, box.position.y - SKIN)
        elif displacement.y < 0 and point.y > box.end.y and target_y <= box.end.y:
            target_y = maxf(target_y, box.end.y + SKIN)
    var hit_y := not is_equal_approx(target_y, point.y + displacement.y)
    point.y = target_y
    point = recover(point, rocks, margin, bounds)
    if hit_x: velocity.x = 0.0
    if hit_y: velocity.y = 0.0
    return {"position":point, "velocity":velocity, "hit_x":hit_x, "hit_y":hit_y}

extends RefCounted
## Highland Gold v8.2 coordinates and native waterfall simulation.
const Source = preload("res://godot/chapter_data.gd")
## Coordinates are deliberately aligned with the HTML release, not rescaled to a shorter demo.
const LEVEL_LENGTH := 29640.0
const WATERFALL_START := 3010.0
const WATERFALL_EXIT := 4120.0
const BOSS_X := 29250.0
const PORTAL_X := 29510.0
const SOURCE_ROUTE_START := 4060.0
const SOURCE_BOSS_X := 14600.0
const ROUTE_SCALE := (BOSS_X - SOURCE_ROUTE_START) / (SOURCE_BOSS_X - SOURCE_ROUTE_START)
const FALL_DURATION := 17.0
const FALL_ENTRY := 1.8
const FALL_EXIT := 1.6

static func route_x(x: float) -> float:
    if x <= SOURCE_ROUTE_START:
        return x
    return roundf(SOURCE_ROUTE_START + (x - SOURCE_ROUTE_START) * ROUTE_SCALE)

static func obstacles() -> Array[Rect2]:
    return Source.obstacles_for("highland")

static func enemies() -> Array[Dictionary]:
    return Source.enemies_for("highland")

static func treasure() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    # Regular exploration gold; the waterfall has its own 22-piece timeline.
    for i in range(105):
        var x := 450.0 + float(i) * 192.0
        if x > 2900.0 and x < SOURCE_ROUTE_START:
            continue
        if x > LEVEL_LENGTH - 320.0:
            continue
        var y := float([440, 565, 690, 770][i % 4])
        result.append({"x": x, "y": y, "kind": "pearl", "taken": false, "phase": float(i) * 0.8})
    for i in range(9):
        var x := route_x(float([4660, 5620, 6370, 7750, 9140, 10540, 11920, 13280, 14120][i]))
        result.append({"x": x, "y": 845.0, "kind": "chest", "taken": false, "phase": float(i) * 0.7})
    var powerups := [
        [4190, 600, "heart"], [4900, 450, "boost"], [5560, 550, "heart"],
        [6280, 650, "heart"], [6750, 520, "boost"], [7920, 470, "heart"],
        [9020, 610, "boost"], [10380, 500, "heart"], [11520, 620, "boost"],
        [12620, 500, "heart"], [13680, 610, "boost"], [14320, 520, "heart"]
    ]
    for p in powerups:
        result.append({"x": route_x(float(p[0])), "y": float(p[1]), "kind": p[2], "taken": false, "phase": 0.0})
    return result

static func waterfall_hazards() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var offsets := [-0.56, 0.50, -0.45, 0.57, 0.0, -0.55]
    for i in range(12):
        var kind: String = "eel" if i in [4, 7, 10] else ["reef", "jelly", "puffer"][i % 3]
        result.append({"at": 2.3 + float(i) * 1.17, "x": offsets[i % 6], "kind": kind, "passed": false})
    return result

static func waterfall_gold() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for i in range(22):
        result.append({"at": 1.3 + float(i) * 0.68, "x": sin(float(i) * 0.85) * 0.48, "taken": false})
    return result

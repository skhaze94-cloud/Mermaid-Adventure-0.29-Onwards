extends RefCounted
## Build once per chapter; existing authored stops remain, with quiet rest points
## in the longest gaps. No enemy, treasure or scenery coordinates are changed.
const Rock = preload("res://godot/rock_collision.gd")
const MAX_GAP := 4800.0
const MARGIN := 43.0 * .73

static func build(authored: Array, start: float, boss: float, rocks: Array[Rect2], enemies: Array[Dictionary], bounds: Rect2) -> Array[Dictionary]:
    var anchors: Array[Dictionary] = []
    for stop in authored:
        anchors.append({"x":float(stop[0]),"name":String(stop[1]),"haven":false})
    var approach := boss-1050.0
    if anchors.is_empty() or float(anchors.back()["x"]) < approach-500:
        anchors.append({"x":approach,"name":"Final Approach","haven":true})
    anchors.sort_custom(func(a,b):return a["x"]<b["x"])
    var result: Array[Dictionary] = []
    var previous := start
    for anchor in anchors:
        var end: float=anchor["x"]
        var sections := maxi(1,ceili((end-previous)/MAX_GAP))
        for part in range(1,sections):
            var x := lerpf(previous,end,float(part)/sections)
            var safe := _quiet_position(x,rocks,enemies,bounds)
            result.append({"x":safe.x,"name":"Resting Pearl","haven":true})
        result.append(anchor)
        previous=end
    for stop in result:
        stop["position"] = Rock.recover(Vector2(stop["x"],480),rocks,MARGIN,bounds)
    return result

static func _quiet_position(x: float, rocks: Array[Rect2], enemies: Array[Dictionary], bounds: Rect2) -> Vector2:
    var best := Rock.recover(Vector2(x,480),rocks,MARGIN,bounds)
    var best_score := -INF
    # Prefer a quiet berth near the intended distance. Evaluate only at setup.
    for offset in [0,-160,160,-320,320,-480,480]:
        var wanted := Vector2(x+offset,480)
        var at := Rock.recover(wanted,rocks,MARGIN,bounds)
        var clearance := 650.0
        for enemy in enemies:
            clearance=minf(clearance,at.distance_to(Vector2(enemy.get("bx",enemy["x"]),enemy.get("by",enemy["y"]))))
        var score := clearance-absf(float(offset))*.25-at.distance_to(wanted)
        if score>best_score:best_score=score;best=at
    return best

extends RefCounted
## World coordinates from the attached Mermaid Adventure 9.2, spark-eel.js / v70-world.js.
const Source = preload("res://godot/chapter_data.gd")
const SHADOW_LENGTH := 14300.0
const LAGOON_LENGTH := 33150.0
const PACK_KINDS := ["maraca-snapper", "ribbon-ambusher", "bubble-bandit-otter", "orchid-hermit", "drumback-turtle", "disco-cuttlefish"]
static func sx(x: float) -> float: return roundf(x * LAGOON_LENGTH / 7600.0)
static func obstacles(shadow: bool) -> Array[Rect2]: return Source.obstacles_for("shadow" if shadow else "miguel")
static func enemies(shadow: bool) -> Array[Dictionary]:
    var result := Source.enemies_for("shadow" if shadow else "miguel")
    # Preserve the supplied lagoon-pack creature variety on six original anchors.
    if not shadow:
        for i in range(mini(6,result.size())): result[i]["kind"] = PACK_KINDS[i]
    return result
static func pads(shadow: bool) -> Array[float]: return Source.pads_for("shadow" if shadow else "miguel")
static func treasure(shadow: bool) -> Array[Dictionary]: return Source.treasure_for("shadow" if shadow else "miguel")
static func pickup(x: float, y: float, kind: String, phase := 0.0) -> Dictionary:
    return {"x":x,"y":y,"kind":kind,"taken":false,"phase":phase}
static func switches() -> Array[Dictionary]:
    return [{"pos":Vector2(3802,430),"on":false},{"pos":Vector2(7722,720),"on":false},{"pos":Vector2(11148,470),"on":false}]

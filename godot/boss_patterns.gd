extends RefCounted
## Three-shot signatures share the existing cadence, speed, caps and hit windows.
const WARNING_SECONDS := 0.48
const INTERVALS := {"blackwater":1.0,"palace":1.15,"rana":1.05,"nessie":.95}
const NAMES := {"palace":"Crown Waltz · watch the pearl lanes", "rana":"Rainbow Ladder · dodge the locked laser",
    "nessie":"Cresting Wake · leave the warning lanes", "blackwater":"Pincer Pearls · move out of the crossing"}

static func plan(kind: String, origin: Vector2, target: Vector2, sequence: int) -> Array[Dictionary]:
    var shots: Array[Dictionary] = []
    var aim := (target-origin).normalized()
    if aim == Vector2.ZERO: aim = Vector2.LEFT
    var mirror := 1.0 if sequence%2 == 0 else -1.0
    for i in range(3):
        var offset := Vector2.ZERO
        var direction := aim
        var lane := float(i-1)
        match kind:
            "palace":
                # A fan alternates with three staggered crown gates.
                offset = Vector2(-24,lane*72) if sequence%2 == 0 else Vector2.ZERO
                direction = aim.rotated(lane*.30 + mirror*.10)
            "rana":
                offset = Vector2(-45,lane*96)
                direction = Vector2.LEFT.rotated(lane*.12*mirror)
            "nessie":
                # Offset crests follow her tail rather than repeating the crown fan.
                offset = Vector2(-105+i*42,lane*58)
                direction = aim.rotated(lane*.12*mirror)
            "blackwater":
                offset = Vector2(-30,lane*112) if i != 1 else Vector2(-125,0)
                direction = (target-origin-offset).normalized()
                if direction == Vector2.ZERO: direction = Vector2.LEFT
            _:
                direction = aim.rotated(lane*.35)
        shots.append({"offset":offset,"direction":direction})
    return shots

static func warning_points(shots: Array[Dictionary]) -> PackedVector2Array:
    var points := PackedVector2Array()
    for shot in shots:
        for segment in range(3):
            points.append(Vector2(shot["offset"])+Vector2(shot["direction"])*(18+segment*30))
            points.append(Vector2(shot["offset"])+Vector2(shot["direction"])*(36+segment*30))
    return points

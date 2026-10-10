extends RefCounted
## Shoulder sweep, elbow fold and wrist pitch: reach / catch / pull / recovery.
## Shared phase makes this breaststroke; small perspective differences separate hands.
const KEYS := [Vector3(-.22,.04,-.10),Vector3(-.24,.02,-.08),
    Vector3(.65,.08,.08),Vector3(1.36,-.30,-.12),
    Vector3(1.72,-.76,-.18),Vector3(1.10,-1.12,-.12),
    Vector3(.38,-.64,.06),Vector3(-.15,-.08,-.08)]
static func sample(phase: float) -> Vector3:
    var cursor := fposmod(phase,TAU)/TAU*KEYS.size()
    var a := int(floor(cursor))%KEYS.size()
    var t := cursor-floorf(cursor)
    var p0: Vector3 = KEYS[(a-1+KEYS.size())%KEYS.size()]
    var p1: Vector3 = KEYS[a]
    var p2: Vector3 = KEYS[(a+1)%KEYS.size()]
    var p3: Vector3 = KEYS[(a+2)%KEYS.size()]
    return .5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t)

static func performance(phase: float, speed: float, vertical: float) -> Vector3:
    var pose := sample(phase)
    # Cruise: leisurely catch; rise/dive: slightly higher forward placement.
    var cruise := 1.0-smoothstep(180.0,310.0,speed)
    pose.x *= 1.0-cruise*.08
    pose.y *= 1.0-cruise*.08
    pose.x -= clampf(-vertical/900.0,-.10,.10)
    return pose

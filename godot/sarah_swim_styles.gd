extends RefCounted
## Shared, sampled shoulder/elbow/wrist tracks. Phase is never reset on a turn.
const SAMPLES := 432
const NAMES := ["breaststroke", "front_crawl", "sidestroke", "butterfly",
    "rise_scoop", "rise_alternate", "dive_spear", "dive_sweep",
    "boost_dolphin", "boost_drive", "waterfall_scull", "waterfall_surge"]
const Breaststroke = preload("res://godot/sarah_arm_cycles.gd")
static var tracks: Dictionary = {}

static func _pose(style: String, p: float, far: bool) -> Vector3:
    var q := p + (PI if far else 0.0)
    match style:
        "breaststroke": return Breaststroke.sample(p + (.10 if far else 0.0))
        "front_crawl":
            # Alternating long catch and folded recovery under the shoulder.
            return Vector3(.57 + .78*sin(q), -.43-.44*sin(q-.65), .24*sin(q-.25))
        "sidestroke":
            # Leading arm reaches while the trailing arm makes a compact pull.
            return Vector3(.48+.54*sin(p+.35), -.38-.32*sin(p-.55), .21*sin(p-.35)) if not far else Vector3(.91+.32*sin(p+1.6), -.55-.24*sin(p+.9), -.18*sin(p+.25))
        "butterfly":
            return Vector3(.46+.89*sin(p-.35), -.40-.42*sin(p-1.0), .25*sin(p-.05))
        "rise_scoop":
            # Higher catch, deep symmetric downward scoop for upward travel.
            return Vector3(.27+.91*sin(p-.65), -.40-.44*sin(p-1.3), -.05+.23*sin(p-.4))
        "rise_alternate":
            return Vector3(.12+.68*sin(q-.5), -.43-.35*sin(q-1.2), .24*sin(q-.3))
        "dive_spear":
            # Reach, then a small alternating trim sweep; never a rigid dive.
            return Vector3(-.25+.26*sin(q), -.16-.14*sin(q-.8), -.07+.16*sin(q-.3))
        "dive_sweep":
            return Vector3(.71+.55*sin(p+.6), -.36-.32*sin(p-.15), .23*sin(p+.35))
        "boost_dolphin":
            # Streamlined arms; propulsion travels through hips and fluke.
            return Vector3(-.42+.025*sin(p), .025+.012*sin(p-.5), -.06+.02*sin(p-1.0))
        "boost_drive":
            return Vector3(-.37+.07*sin(p), -.045+.045*sin(p-.8), -.035+.03*sin(p))
        "waterfall_scull":
            # Compact opposed steering sweeps hold balance in the current.
            return Vector3(.67+.37*sin(q), -.48-.28*sin(q-.5), .28*sin(q+.35))
        "waterfall_surge":
            return Vector3(-.28+.055*sin(p), -.025+.035*sin(p-.9), -.07+.025*sin(p+.2))
    return Vector3.ZERO

static func build() -> void:
    if not tracks.is_empty(): return
    for style in NAMES:
        var near: Array[Vector3] = []
        var far: Array[Vector3] = []
        for i in range(SAMPLES):
            var p := float(i)*TAU/SAMPLES
            near.append(_pose(style,p,false))
            far.append(_pose(style,p,true))
        tracks[style] = [near,far]

static func sample(style: String, phase: float, far: bool = false) -> Vector3:
    build()
    var frames: Array = tracks[style][1 if far else 0]
    var cursor := fposmod(phase,TAU)/TAU*SAMPLES
    var a := int(floorf(cursor))%SAMPLES
    var t := cursor-floorf(cursor)
    var p0: Vector3 = frames[(a-1+SAMPLES)%SAMPLES]
    var p1: Vector3 = frames[a]
    var p2: Vector3 = frames[(a+1)%SAMPLES]
    var p3: Vector3 = frames[(a+2)%SAMPLES]
    return .5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t)

static func choose(speed: float, vertical: float, phase: float, boost: bool, waterfall: String, horizontal_phase: float = -1.0) -> String:
    var alternate := int(floor(phase/(TAU*3.0)))%2 == 1
    if boost:
        if waterfall != "": return "waterfall_surge"
        return "boost_drive" if alternate else "boost_dolphin"
    if waterfall == "pull" or waterfall == "outflow": return "waterfall_scull"
    # A directional dead zone prevents rapid stroke changes near horizontal.
    if vertical < -maxf(90.0,speed*.32):
        return "rise_alternate" if alternate else "rise_scoop"
    if vertical > maxf(90.0,speed*.32):
        return "dive_sweep" if alternate else "dive_spear"
    if waterfall == "descent": return "waterfall_scull"
    # Two ordinary strokes, breaststroke, three ordinary strokes, breaststroke.
    # Directional strokes and boost retain their own appropriate propulsion.
    var horizontal := phase if horizontal_phase<0 else horizontal_phase
    if int(floor(horizontal/TAU))%7 in [2,6]: return "breaststroke"
    if speed < 235.0: return "sidestroke"
    if speed > 320.0: return "butterfly" if alternate else "front_crawl"
    return "front_crawl"

static func body_loop(style: String) -> String:
    return {"breaststroke":"swim", "front_crawl":"crawl", "sidestroke":"sidestroke",
        "butterfly":"butterfly", "rise_scoop":"scoop", "rise_alternate":"climb",
        "dive_spear":"spear", "dive_sweep":"dive", "boost_dolphin":"dolphin",
        "boost_drive":"boost_drive", "waterfall_scull":"waterfall_scull",
        "waterfall_surge":"waterfall_boost"}[style]

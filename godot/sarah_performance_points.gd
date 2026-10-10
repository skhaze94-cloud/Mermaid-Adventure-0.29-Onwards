extends RefCounted
## 432 samples for seven coordinated channels: two shoulder sockets, head, jaw, chest.
const Styles = preload("res://godot/sarah_swim_styles.gd")
const SAMPLES := 432
const EXTRA := ["idle","turn","greet","cast","celebrate","impact",
    "jump_ascent","jump_airborne","jump_landing","recover"]
static var tracks: Dictionary = {}
static func pose(name: String, p: float) -> Array:
    var opposed := name in ["front_crawl","rise_alternate","waterfall_scull"]
    var far_phase := p+(PI if opposed else .18)
    var effort := .72
    var head := .040
    var jaw := .35
    if name=="idle": effort=.16; head=.014; jaw=.08
    elif name=="sidestroke": effort=.48; head=.025; jaw=.12
    elif name=="butterfly" or name=="rise_scoop": effort=.92; head=.052
    elif name.begins_with("boost") or name=="waterfall_surge": effort=.40; head=.023; jaw=.05
    elif name.begins_with("dive"): effort=.38; head=.026; jaw=.08
    elif name=="greet" or name=="celebrate": effort=.75; head=.060; jaw=.55
    elif name=="cast": effort=.40; head=.032; jaw=.16
    elif name=="impact": effort=.22; head=.020; jaw=.04
    elif name.begins_with("jump"): effort=.55; head=.045; jaw=.22
    elif name=="recover": effort=.32; head=.023; jaw=.10
    elif name=="turn": effort=.70; head=.048; jaw=.10
    # Catch advances the shoulder, then the pull draws it back; far arm may oppose.
    var near := Vector2(sin(p-.50)*.65, -sin(p-.05)*.85)*effort
    var far := Vector2(sin(far_phase-.65)*.55,-sin(far_phase-.20)*.70)*effort
    if name=="sidestroke": far*=.55
    # A secondary harmonic creates anticipation/settling, rather than a single pendulum.
    var pitch := (sin(p-.90)+.22*sin(p*2.0-.35))*head
    var jaw_response := (.5+.5*sin(p-1.25))*jaw
    var chest := sin(p-.25)*effort*.22
    return [Vector4(near.x,near.y,far.x,far.y),Vector3(pitch,jaw_response,chest)]
static func build() -> void:
    if not tracks.is_empty(): return
    var names: Array = Styles.NAMES.duplicate()
    names.append_array(EXTRA)
    for name in names:
        var shoulders: Array[Vector4] = []
        var expression: Array[Vector3] = []
        for i in range(SAMPLES):
            var point := pose(name,float(i)*TAU/SAMPLES)
            shoulders.append(point[0]); expression.append(point[1])
        tracks[name]=[shoulders,expression]
static func sample(name: String, phase: float) -> Array:
    build()
    var cursor := fposmod(phase,TAU)/TAU*SAMPLES
    var a := int(floorf(cursor))%SAMPLES
    var b := (a+1)%SAMPLES
    var weight := cursor-floorf(cursor)
    # Dense linear channels are filtered by the response springs; no state resets.
    return [tracks[name][0][a].lerp(tracks[name][0][b],weight),
        tracks[name][1][a].lerp(tracks[name][1][b],weight)]

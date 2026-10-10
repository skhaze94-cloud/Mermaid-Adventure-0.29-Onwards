extends RefCounted
## Thirty-six 144-sample body/fluke loops (5,184 poses), with continuous tangents.
const POSES := 144
const NAMES := ["idle","swim","glide","boost","rise","playful",
    "hover","drift","cruise","sprint","descend","bank",
    "settle","reach","greet","cast","recover","celebrate",
    "crawl","sidestroke","butterfly","scoop","climb","dive","spear",
    "dolphin","boost_drive","boost_rise","boost_dive","waterfall_pull",
    "waterfall_scull","waterfall_rise","waterfall_dive","waterfall_boost",
    "waterfall_outflow","turn_carve"]
static var cycles: Dictionary = {}
static func build() -> void:
    if not cycles.is_empty(): return
    for name in NAMES:
        var poses: Array[Vector4] = []
        for i in range(POSES):
            var p := float(i)*TAU/POSES
            # Hip wave, middle bend, fluke lag and arm paddle are separate tracks.
            var pose := Vector4.ZERO
            match name:
                "idle": pose = Vector4(sin(p)*.10,.14+sin(p-.7)*.14,sin(p-1.5)*.16,sin(p+.4)*.08)
                "swim": pose = Vector4(sin(p)*.22,sin(p-.85)*.48,sin(p-1.65)*.32,sin(p+.6)*.20)
                "glide": pose = Vector4(sin(p)*.08,sin(p-.6)*.18,sin(p-1.2)*.14,sin(p)*.06)
                "boost": pose = Vector4(sin(p)*.08,sin(p-1)*.24,sin(p-1.7)*.35,sin(p)*.05)
                "rise": pose = Vector4(-.08+sin(p)*.18,.18+sin(p-.8)*.42,sin(p-1.6)*.25,sin(p+.8)*.17)
                "playful": pose = Vector4(sin(p)*.28,.18+sin(p-.7)*.58,sin(p-1.6)*.38,sin(p+.5)*.25)
                "hover": pose = Vector4(sin(p)*.07,.24+sin(p-.55)*.12,sin(p-1.9)*.12,sin(p+.8)*.06)
                "drift": pose = Vector4(sin(p)*.05,.10+sin(p-1.2)*.10,sin(p-2.0)*.09,sin(p+.2)*.04)
                "cruise": pose = Vector4(sin(p)*.16,sin(p-.95)*.35,sin(p-1.8)*.27,sin(p+.55)*.14)
                "sprint": pose = Vector4(sin(p)*.10,sin(p-.7)*.31,sin(p-1.5)*.40,sin(p+.7)*.03)
                "descend": pose = Vector4(.08+sin(p)*.15,-.10+sin(p-.7)*.32,sin(p-1.55)*.24,sin(p+.7)*.12)
                "bank": pose = Vector4(sin(p+.25)*.18,.14+sin(p-.65)*.38,sin(p-1.6)*.31,sin(p+.45)*.12)
                "settle": pose = Vector4(sin(p)*.08,.28+sin(p-.55)*.17,sin(p-1.4)*.17,sin(p+.4)*.06)
                "reach": pose = Vector4(-.05+sin(p)*.09,.12+sin(p-.8)*.22,sin(p-1.65)*.19,sin(p+.6)*.08)
                "greet": pose = Vector4(sin(p)*.12,.20+sin(p-.5)*.28,sin(p-1.4)*.24,sin(p+.7)*.18)
                "cast": pose = Vector4(-.08+sin(p)*.07,.10+sin(p-.9)*.19,sin(p-1.7)*.20,sin(p+.2)*.05)
                "recover": pose = Vector4(.04+sin(p)*.10,.23+sin(p-.7)*.22,sin(p-1.6)*.21,sin(p+.5)*.07)
                "celebrate": pose = Vector4(sin(p)*.25,.24+sin(p-.6)*.52,sin(p-1.5)*.35,sin(p+.8)*.23)
                "crawl": pose = Vector4(sin(p)*.17,sin(p-.9)*.39,sin(p-1.9)*.29,sin(p)*.16)
                "sidestroke": pose = Vector4(.04+sin(p)*.12,.16+sin(p-1.1)*.26,sin(p-2.0)*.21,sin(p+.8)*.10)
                "butterfly": pose = Vector4(sin(p-.2)*.25,sin(p-1.0)*.46,sin(p-1.85)*.37,sin(p-.4)*.22)
                "scoop": pose = Vector4(-.10+sin(p)*.21,.22+sin(p-.9)*.45,sin(p-1.75)*.28,sin(p-.6)*.19)
                "climb": pose = Vector4(-.06+sin(p)*.15,.14+sin(p-.6)*.37,sin(p-1.5)*.33,sin(p+.3)*.15)
                "dive": pose = Vector4(.12+sin(p)*.14,-.18+sin(p-.9)*.29,sin(p-1.9)*.22,sin(p+.9)*.11)
                "spear": pose = Vector4(.06+sin(p)*.08,-.06+sin(p-1.05)*.20,sin(p-2.05)*.18,sin(p)*.05)
                "dolphin": pose = Vector4(sin(p)*.12,sin(p-.8)*.33,sin(p-1.6)*.44,sin(p+.5)*.02)
                "boost_drive": pose = Vector4(sin(p)*.14,sin(p-.65)*.29,sin(p-1.45)*.38,sin(p+.2)*.04)
                "boost_rise": pose = Vector4(-.08+sin(p)*.11,.10+sin(p-.75)*.32,sin(p-1.65)*.41,sin(p+.4)*.03)
                "boost_dive": pose = Vector4(.08+sin(p)*.09,-.08+sin(p-.95)*.27,sin(p-1.8)*.39,sin(p+.6)*.025)
                "waterfall_pull": pose = Vector4(.06+sin(p)*.13,.32+sin(p-.6)*.25,sin(p-1.6)*.30,sin(p+.2)*.13)
                "waterfall_scull": pose = Vector4(sin(p)*.11,.18+sin(p-1.1)*.22,sin(p-2.0)*.25,sin(p+.7)*.12)
                "waterfall_rise": pose = Vector4(-.12+sin(p)*.19,.28+sin(p-.8)*.40,sin(p-1.7)*.32,sin(p+.3)*.18)
                "waterfall_dive": pose = Vector4(.10+sin(p)*.12,-.14+sin(p-.85)*.28,sin(p-1.75)*.26,sin(p+.5)*.09)
                "waterfall_boost": pose = Vector4(sin(p)*.10,.04+sin(p-.9)*.30,sin(p-1.85)*.43,sin(p+.3)*.035)
                "waterfall_outflow": pose = Vector4(-.04+sin(p)*.16,.08+sin(p-.75)*.31,sin(p-1.6)*.27,sin(p+.65)*.14)
                "turn_carve": pose = Vector4(.05+sin(p+.4)*.20,.20+sin(p-.5)*.33,sin(p-1.4)*.29,sin(p+.8)*.13)
            poses.append(pose)
        cycles[name] = poses
static func sample(name: String, phase: float) -> Vector4:
    build()
    var frames: Array = cycles[name]
    var cursor := fposmod(phase,TAU)/TAU*POSES
    var a := int(floor(cursor))%POSES
    # Catmull-Rom gives tangent continuity at every key and the loop seam.
    var t: float = cursor-floorf(cursor)
    var p0: Vector4 = frames[(a-1+POSES)%POSES]
    var p1: Vector4 = frames[a]
    var p2: Vector4 = frames[(a+1)%POSES]
    var p3: Vector4 = frames[(a+2)%POSES]
    return .5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t)

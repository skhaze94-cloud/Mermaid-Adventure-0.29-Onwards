extends RefCounted
## Three continuously blended interpretations of each stroke: reach, flow, release.
## Separate delayed harmonics keep the whole body coordinated without faster flailing.
const VARIANTS := 3
static func weights(phase: float) -> Vector3:
    var p := phase/9.0
    var w := Vector3(1.0+cos(p),1.0+cos(p-TAU/3.0),1.0+cos(p-TAU*2.0/3.0))
    return w/(w.x+w.y+w.z)

static func arm(phase: float, far: bool) -> Vector3:
    var w := weights(phase)
    var p := phase+(.25 if far else 0.0)
    var reach := Vector3(sin(p-.35)*.075,-sin(p-.9)*.045,sin(p-1.35)*.04)
    var flow := Vector3(sin(p*2.0-.6)*.025,sin(p-1.0)*.055,sin(p-1.6)*.065)
    var release := Vector3(sin(p-.8)*.045,sin(p*2.0-1.3)*.03,sin(p-1.9)*.05)
    return reach*w.x+flow*w.y+release*w.z

static func body(phase: float, activity: float, boost: float) -> Vector4:
    var w := weights(phase)
    var reach := Vector4(sin(phase-.2)*.035,sin(phase-1.05)*.055,sin(phase-2.0)*.065,0)
    var flow := Vector4(sin(phase*2.0-.4)*.018,sin(phase*2.0-1.2)*.025,sin(phase*2.0-2.2)*.035,0)
    var release := Vector4(sin(phase-.6)*.022,sin(phase-1.4)*.045,sin(phase-2.5)*.055,0)
    return (reach*w.x+flow*w.y+release*w.z)*activity*(1.0-boost*.8)

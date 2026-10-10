extends RefCounted
## Sixteen authored joint-motion clips, sampled at 96 keys per seamless cycle.
## Paint stays on a single skin; these tracks move geometry, never swap portraits.
const CLIPS := ["cruise","paddle","glide","glance","gather","coil","flare","hold","launch","strike","follow","bank","brake","recoil","settle","rest"]
const SAMPLES := 96
# Tail/claw amplitude, fin/other claw amplitude, jaw/bell pulse, body bank.
const SHAPES := [Vector4(.17,.18,.05,.045),Vector4(.27,.31,.08,.065),Vector4(.09,.11,.025,.025),Vector4(.14,.23,.055,.095),Vector4(.15,.22,.12,-.06),Vector4(.30,.17,.15,-.10),Vector4(.24,.34,.23,-.035),Vector4(.10,.11,.17,-.045),Vector4(.36,.38,.24,.12),Vector4(.44,.45,.28,.085),Vector4(.28,.28,.13,.065),Vector4(.26,.36,.07,.14),Vector4(.28,.40,.10,-.08),Vector4(.19,.24,.08,-.055),Vector4(.13,.17,.045,.035),Vector4(.08,.10,.025,.015)]
const FREQUENCIES := [1.0,1.35,.65,.85,.85,.70,1.25,.55,1.6,1.8,1.4,1.15,1.2,.95,.8,.6]
static var libraries: Dictionary = {}

static func library(profile: String) -> AnimationLibrary:
    if libraries.has(profile): return libraries[profile]
    var result := AnimationLibrary.new()
    var speed := .82 if profile in ["carlo","duke","rana","palace","training"] else (1.1 if profile in ["eel","swordfish","shark","blackwater"] else 1.0)
    for index in range(CLIPS.size()):
        var anim := Animation.new()
        anim.length = TAU / (3.0 * FREQUENCIES[index] * speed)
        anim.loop_mode = Animation.LOOP_LINEAR
        var track := anim.add_track(Animation.TYPE_VALUE)
        anim.track_set_path(track,NodePath(".:joints"))
        var posture := anim.add_track(Animation.TYPE_VALUE)
        anim.track_set_path(posture,NodePath(".:posture"))
        var shape: Vector4 = SHAPES[index]
        for key in range(SAMPLES+1):
            var p := key * TAU / SAMPLES
            var beat := sin(p)
            var following := sin(p-.85)
            # Independent counter-beats, flexion and delayed tips produce depth.
            var joints := Vector4(beat*shape.x,following*shape.y,(.5+.5*sin(p+.45))*shape.z,sin(p-.35)*shape.w)
            var stage := index/4
            var spread: float = [0.0,.40,.68,.15][stage]
            var tuck: float = [0.0,.48,-.10,.12][stage]
            var bias := (.025 if index%4==3 else 0.0)
            var pose := Vector4(spread+.10*sin(p-.5),tuck+.10*sin(p+.7),sin(p-.6)*.09+bias,shape.w)
            anim.track_insert_key(track,key*anim.length/SAMPLES,joints)
            anim.track_insert_key(posture,key*anim.length/SAMPLES,pose)
        result.add_animation(CLIPS[index],anim)
    libraries[profile] = result
    return result

static func select(mode: String, age: float, clock: float, phase: float) -> int:
    if mode in ["patrol","approach"]:
        return int(floor((clock+phase)*.38)) % 4
    var thresholds := Vector3(.18,.40,.62) if mode=="windup" else (Vector3(.09,.20,.34) if mode=="attack" else Vector3(.15,.35,.65))
    var step := 0 if age<thresholds.x else (1 if age<thresholds.y else (2 if age<thresholds.z else 3))
    return ({"windup":4,"attack":8,"recover":12}.get(mode,0)) + step

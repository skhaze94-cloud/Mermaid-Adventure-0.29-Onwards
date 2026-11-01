extends RefCounted
## Per-resident, scene-clock performance. No timers, inputs or saved state.
const TRAITS={"mallow":Vector3(.018,3.0,.7),"tilly":Vector3(.024,4.0,1.0),"posy":Vector3(.028,4.0,1.2),"purl":Vector3(.015,2.8,.65),"ludo":Vector3(.022,3.8,.9),"vesper":Vector3(.020,4.2,.75),"peep":Vector3(.028,4.5,1.1),"saffron":Vector3(.022,3.3,.8),"button":Vector3(.032,4.8,1.2),"hush":Vector3(.014,2.6,.6),"crumb":Vector3(.025,3.2,.8),"dot":Vector3(.019,3.0,.7),"miri":Vector3(.030,4.5,1.1),"oona":Vector3(.017,3.8,.65),"bibi":Vector3(.035,5.0,1.25),"thimble":Vector3(.014,2.5,.6)}
var id: String
var state:="rest"
var started:=0.0
var last_time:=-1.0
var cooldown:=0.0
var near:=false
var flourish_seen:=false
var offset:=Vector2.ZERO
var tilt:=0.0
var joy:=0.0
var look:=0.0
var greeting:=0.0
func _init(name: String="mallow") -> void:id=name
func advance(time: float,attention: float,celebrating: bool,still: bool,direction: float) -> void:
    var dt:=clampf(time-last_time,0,.1) if last_time>=0 else 0.0
    if time<last_time:state="rest";started=time;cooldown=0;near=false;flourish_seen=false
    last_time=time
    if still:
        offset=Vector2.ZERO;tilt=0;joy=0;look=0;greeting=0;state="rest";started=time
        near=attention>.6;flourish_seen=celebrating;return
    cooldown=maxf(0,cooldown-dt)
    var entered:=attention>.6 and not near
    if attention<.3:near=false
    elif attention>.6:near=true
    if celebrating and not flourish_seen:
        state="delight";started=time;cooldown=14
    elif entered and cooldown<=0:
        state="notice";started=time;cooldown=14
    flourish_seen=celebrating
    var age:=maxf(0,time-started)
    if state=="notice" and age>.85:state="hello";started=time;age=0
    elif state=="hello" and age>2.4:state="shy";started=time;age=0
    elif state=="shy" and age>1.6 or state=="delight" and age>2.8:state="rest";started=time;age=0
    var target:=0.0
    match state:
        "notice":target=sin(clampf(age/.85,0,1)*PI)*.55
        "hello":target=sin(clampf(age/2.4,0,1)*PI)
        "shy":target=-sin(clampf(age/1.6,0,1)*PI)*.45
        "delight":target=sin(clampf(age/2.8,0,1)*PI)*1.25
    var character_style: Vector3=TRAITS.get(id,Vector3(.02,3,.8))
    var ease:=1-exp(-dt*9)
    tilt=lerpf(tilt,target*character_style.x*direction,ease)
    offset=offset.lerp(Vector2(-direction*target*character_style.y*.3,-absf(target)*character_style.y),ease)
    joy=lerpf(joy,maxf(0,target),ease)
    look=lerpf(look,direction*attention*.0035*(.6+maxf(0,target)),ease)
    greeting=lerpf(greeting,target*character_style.z,ease)

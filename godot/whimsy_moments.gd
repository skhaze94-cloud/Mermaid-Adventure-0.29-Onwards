extends Node2D
## Positive little ocean gestures. Fixed records, cached shapes, no gameplay state.
## The host owns timing so pause, waterfall, retry and capture stay authoritative.
const CAPACITY := 12
const KINDS := ["pearl","treasure","checkpoint","heart","boss_defeat","boost","idle"]
const DURATIONS := [.90,1.45,1.55,1.25,2.0,.65,1.75]
const COOLDOWNS := [.28,.65,1.2,.55,1.8,.85,9.0]
const KIND_CAPS := [3,2,1,2,1,1,1]
const PALETTES := [Color("f5dbe5"),Color("c9e5f4"),Color("f7d9db"),Color("c7dfed"),Color("f2d7df"),Color("dae8f6"),Color("f6e9cf"),Color("f6d9e1")]
var pool: Array[Dictionary] = []
var cooldowns: Array[float] = []
var star_shape := PackedVector2Array()
var leaf_shape := PackedVector2Array()
var heart_shape := PackedVector2Array()
var camera := 0.0
var waterline := 280.0
var player := Vector2.ZERO
var previous_player := Vector2.ZERO
var chapter := 0
var reduced := false
var economy := false
var active := true
var combat := false
var clock := 0.0
var idle_time := 0.0
var idle_rest := 7.0
var has_player := false
var spawned_total := 0

func _ready() -> void:
    z_index=2
    set_process(false)
    for i in range(CAPACITY):
        pool.append({"age":9.0,"duration":0.0,"at":Vector2.ZERO,"kind":0,"direction":Vector2.RIGHT,"seed":0.0})
    cooldowns.resize(KINDS.size());cooldowns.fill(0.0)
    # One set of normalized silhouettes is shared by every transient drawing.
    for i in range(10):
        var angle:=float(i)*TAU/10-PI/2
        star_shape.append(Vector2(cos(angle),sin(angle))*(1.0 if i%2==0 else .48))
    for i in range(9):
        var t:=float(i)/8
        leaf_shape.append(Vector2(t*2-1,-sin(t*PI)*.40))
    for i in range(7,0,-1):
        var t:=float(i)/8
        leaf_shape.append(Vector2(t*2-1,sin(t*PI)*.40))
    for i in range(32):
        var t:=float(i)*TAU/32
        heart_shape.append(Vector2(pow(sin(t),3),-(13*cos(t)-5*cos(2*t)-2*cos(3*t)-cos(4*t))/16))

func set_world(camera_x: float, line: float, hero: Vector2, chapter_index: int, gentle: bool, low: bool, enabled: bool, in_combat: bool) -> void:
    camera=camera_x;waterline=line;player=hero;chapter=clampi(chapter_index,0,7)
    reduced=gentle;economy=low;combat=in_combat
    if active and not enabled: clear()
    active=enabled;visible=enabled
    if not has_player:previous_player=hero;has_player=true
    # Ordinary celebration never competes with a live attack warning.
    if combat:
        for item in pool:
            if int(item["kind"])!=4:item["age"]=9.0
        idle_time=0.0
    queue_redraw()

func advance(dt: float) -> void:
    if not is_finite(dt) or dt<=0:return
    if not active:return
    if not reduced:clock+=dt
    for i in range(cooldowns.size()):cooldowns[i]=maxf(0,cooldowns[i]-dt)
    var changed:=false
    for item in pool:
        if float(item["age"])<float(item["duration"]):
            item["age"]=minf(float(item["duration"]),float(item["age"])+dt)
            changed=true
    idle_rest=maxf(0,idle_rest-dt)
    var still:=has_player and player.distance_squared_to(previous_player)<1.0
    previous_player=player
    if not combat and not reduced and not economy and still and player.y>waterline+65:
        idle_time+=dt
        if idle_time>=4.5 and idle_rest<=0:
            celebrate(player+Vector2(64,-48),"idle")
            idle_time=0.0;idle_rest=12.0
    else:idle_time=0.0
    if changed:queue_redraw()

func celebrate(at: Vector2, kind: String, direction := Vector2.RIGHT) -> void:
    var index:=KINDS.find(kind)
    if not active or index<0 or pool.is_empty():return
    if combat and kind!="boss_defeat":return
    if reduced and kind in ["boost","idle"]:return
    if cooldowns[index]>0:return
    var same:=0
    for item in pool:
        if float(item["age"])<float(item["duration"]) and int(item["kind"])==index:same+=1
    if same>=int(KIND_CAPS[index]):return
    if economy and live_count()>=4 and index!=4:return
    var chosen:=-1
    for i in range(pool.size()):
        if float(pool[i]["age"])>=float(pool[i]["duration"]):chosen=i;break
    if chosen<0:
        # Major arrivals may reuse an ordinary record; no pool ever grows.
        if index not in [1,2,4]:return
        var oldest:=-1.0
        for i in range(pool.size()):
            if int(pool[i]["kind"])==4:continue
            if float(pool[i]["age"])>oldest:oldest=float(pool[i]["age"]);chosen=i
        if chosen<0:return
    var heading: Vector2=direction.normalized() if direction.length_squared()>.001 else Vector2.RIGHT
    spawned_total+=1
    var item: Dictionary=pool[chosen]
    item["age"]=0.0;item["duration"]=.38 if reduced else float(DURATIONS[index])
    item["at"]=at;item["kind"]=index;item["direction"]=heading;item["seed"]=float(spawned_total)*1.37
    cooldowns[index]=float(COOLDOWNS[index]);queue_redraw()

func clear() -> void:
    for item in pool:item["age"]=9.0
    for i in range(cooldowns.size()):cooldowns[i]=0.0
    clock=0.0;idle_time=0.0;idle_rest=7.0;has_player=false
    queue_redraw()

func live_count() -> int:
    var count:=0
    for item in pool:
        if float(item["age"])<float(item["duration"]):count+=1
    return count

func _draw() -> void:
    if not active:return
    var view:=get_viewport_rect().size
    var tint: Color=PALETTES[chapter]
    for item in pool:
        var age: float=item["age"];var duration: float=item["duration"]
        if age>=duration or duration<=0:continue
        var at: Vector2=item["at"]-Vector2(camera,0)
        if at.x < -140 or at.x>view.x+140 or at.y < -130 or at.y>view.y+130:continue
        var t:=clampf(age/duration,0,1)
        var opacity: float=(1.0-t)*.78
        var motion:=0.0 if reduced else t
        var seed: float=item["seed"]
        var kind: int=item["kind"]
        if kind==0:
            # The pearl gets one satin twinkle, never a shower of particles.
            _glint(at+Vector2(9,-13-motion*17),4.5*(1-motion*.55),Color(tint,opacity*.85))
            if not economy:_bubble(at+Vector2(-11+motion*4,-6-motion*24),3.0,Color("fff4eb",opacity*.48))
        elif kind==3:
            _heart(at+Vector2(0,-18-motion*36),8.0*(1-motion*.25),Color("f5c9d7",opacity*.72))
            if not economy:_bubble(at+Vector2(15,-9-motion*28),4.5,Color(tint,opacity*.55))
        elif kind==5:
            var heading: Vector2=item["direction"]
            for i in range(1 if economy else 2):
                var p: Vector2=at-heading*(18+motion*25+i*14)+heading.orthogonal()*(i*2-1)*8
                _leaf(p,Vector2(8,5),heading.angle()+.25,Color(tint,opacity*.38))
        elif kind==6:
            # A quiet held stillness gesture, away from Sarah's face and hands.
            var p:=at+Vector2(sin(motion*PI)*5,-motion*22)
            _bubble(p,12,Color(tint,opacity*.48));_heart(p,4.2,Color("f5d2dd",opacity*.52))
            if not economy:_glint(p+Vector2(15,-11),3,Color("fff6e9",opacity*.55))
        else:
            var count:=3 if economy else (7 if kind==4 else 5)
            var span:=74.0 if kind==4 else 44.0
            var lift:=98.0 if kind==4 else 35.0
            for i in range(count):
                var phase:=float(i)/maxf(1,count-1)
                var angle:=lerpf(-2.75,-.39,phase)
                var offset:=Vector2(cos(angle)*span,sin(angle)*(span*.43))
                var p: Vector2=at+Vector2(0,-lift)+offset*(.52+motion*.52)+Vector2(sin(seed+i)*motion*6,-motion*19)
                if i%2==0:_star(p,5.0+float(i%3),motion*.3+seed,Color(tint,opacity*.72))
                else:_leaf(p,Vector2(9,6),angle+motion*.65,Color("f9ece7",opacity*.65))
            if not economy:_glint(at+Vector2(0,-lift-28-motion*20),7*(1-motion*.4),Color("fff4e9",opacity*.82))
    draw_set_transform(Vector2.ZERO)

func _glint(at: Vector2, size: float, tint: Color) -> void:
    draw_line(at-Vector2(size,0),at+Vector2(size,0),tint,1.1,true)
    draw_line(at-Vector2(0,size*1.35),at+Vector2(0,size*1.35),tint,1.1,true)
    draw_circle(at,1.5,Color(tint,tint.a*.8))
func _bubble(at: Vector2, radius: float, tint: Color) -> void:
    draw_arc(at,radius,.1,TAU-.25,18,tint,1.0,true)
    draw_arc(at+Vector2(-radius*.10,-radius*.11),radius*.72,-2.65,-1.65,6,Color("fff8f1",tint.a*.7),1.2,true)
func _star(at: Vector2, size: float, angle: float, tint: Color) -> void:
    draw_set_transform(at,angle,Vector2.ONE*size)
    draw_colored_polygon(star_shape,tint)
    draw_set_transform(Vector2.ZERO)
func _leaf(at: Vector2, size: Vector2, angle: float, tint: Color) -> void:
    draw_set_transform(at,angle,size)
    draw_colored_polygon(leaf_shape,tint)
    draw_line(Vector2(-.6,0),Vector2(.7,0),Color("fff7ec",tint.a*.55),.10,true)
    draw_set_transform(Vector2.ZERO)
func _heart(at: Vector2, size: float, tint: Color) -> void:
    draw_set_transform(at,0,Vector2.ONE*size)
    draw_colored_polygon(heart_shape,tint)
    draw_set_transform(Vector2.ZERO)

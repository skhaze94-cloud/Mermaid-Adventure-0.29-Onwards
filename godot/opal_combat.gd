extends RefCounted
## Transactional charge, bounded pools and earliest swept collisions for all chapters.
const Charge=preload("res://godot/opal_charge.gd")
const Sweep=preload("res://godot/opal_collision.gd")
const FRIENDLY_CAP:=8
const HOSTILE_CAP:=32
var charge=Charge.new()
var level: Node2D
var epoch:=""
var sequence:=0
var generation:=0
var targets: Array[Dictionary]=[]
var retired: Dictionary={}
var retired_order: Array[String]=[]
var ready_chimed:=false
var suppressed: Dictionary={}
var obstacle_signature:=-1
var friendly_walls: Array[Rect2]=[]
var hostile_walls: Array[Rect2]=[]
func bind(host: Node2D) -> void:
    level=host;targets=level._opal_make_targets();reset()
func reset() -> void:
    cancel();charge=Charge.new();generation+=1
    epoch="%s:%s" % [level.get_instance_id(),generation]
    retired.clear();retired_order.clear();obstacle_signature=-1
    friendly_walls.clear();hostile_walls.clear();ready_chimed=false
    if is_instance_valid(level) and is_instance_valid(level.opal_fx):level.opal_fx.reset()
func cancel(source:="") -> void:
    if not source.is_empty() and charge.source_id!=source:return
    if charge.held and not charge.source_id.is_empty() and charge.source_id!="script":suppressed[charge.source_id]=true
    charge.cancel();ready_chimed=false
    if is_instance_valid(level) and is_instance_valid(level.opal_fx):level.opal_fx.hide_preview()
func begin(source: String) -> bool:
    if suppressed.has(source):return false
    charge.cooldown=level.fire_cooldown
    var accepted: bool=charge.begin(source,level.bubble_unlocked,level._bubble_context_allowed())
    if accepted:ready_chimed=false
    return accepted
func advance(dt: float) -> void:
    if not level._bubble_context_allowed():
        cancel()
        if level.state=="playing" and not level.get_tree().paused:level.fire_cooldown=maxf(0.0,level.fire_cooldown-dt)
        return
    charge.cooldown=level.fire_cooldown;charge.advance(dt,level._bubble_context_allowed())
    level.fire_cooldown=charge.cooldown
    if charge.held and charge.tier()==3 and not ready_chimed:
        ready_chimed=true;level._sfx("pearl",0);level._vibrate(0.11,0.04,0.07)
func release(source: String) -> bool:
    suppressed.erase(source)
    if not level._bubble_context_allowed():cancel();return false
    var packet: Dictionary=charge.prepare_release(source)
    if packet.is_empty():return false
    Sweep.compact(level.bubble_shots)
    if level.bubble_shots.size()>=FRIENDLY_CAP:
        var recycle:=-1
        for i in range(level.bubble_shots.size()):
            var old: Dictionary=level.bubble_shots[i]
            if not old.get("baby",false) and int(old.get("tier",1))==1:recycle=i;break
        if recycle>=0:level.bubble_shots.remove_at(recycle)
        else:
            charge.commit_release(packet["packet_id"],false)
            level._say("Bubble squad full - let one pop, then charge again!",1.4,true)
            if is_instance_valid(level.opal_fx):level.opal_fx.hide_preview()
            return false
    var local_id: int=packet["packet_id"]
    sequence+=1;packet["packet_id"]=epoch+":"+str(sequence);packet["epoch"]=epoch
    packet["spawn_from"]=level.player+Vector2(level.facing*70,0)
    packet["pos"]=level._opal_cast_position(packet["tier"]);packet["direction"]=level.facing
    packet["life"]=1.8;packet["consumed"]=false;level.bubble_shots.append(packet)
    charge.commit_release(local_id,true);level.fire_cooldown=charge.cooldown
    level._sfx("bubble");level.native_rig.play_gesture("cast")
    if is_instance_valid(level.avina):level.avina.request_bubble()
    if is_instance_valid(level.opal_fx):level.opal_fx.hide_preview()
    level._on_bubble_fired();return true
func little_bubble(at: Vector2, direction: float) -> bool:
    if level.bubble_shots.size()>=FRIENDLY_CAP or not level._bubble_world_active():return false
    sequence+=1
    level.bubble_shots.append({"packet_id":epoch+":"+str(sequence),"epoch":epoch,"owner":"avina","team":"friendly","baby":true,
        "tier":1,"damage":1,"boss_damage":0,"pos":at,"direction":direction,"life":1.3,"consumed":false})
    return true
func refresh_targets() -> void:level._opal_update_targets(targets)
func _refresh_walls() -> void:
    var signature:=hash(level.obstacles)
    if signature==obstacle_signature:return
    obstacle_signature=signature;friendly_walls.resize(level.obstacles.size());hostile_walls.resize(level.obstacles.size())
    for i in range(level.obstacles.size()):friendly_walls[i]=level.obstacles[i].grow(20.0);hostile_walls[i]=level.obstacles[i].grow(12.0)
func _retire(packet: Dictionary) -> void:
    packet["consumed"]=true;packet["life"]=0.0
    var id:=str(packet.get("packet_id",""))
    if id.is_empty():return
    retired[id]=true;retired_order.append(id)
    if retired_order.size()>64:retired.erase(retired_order.pop_front())
func update_friendly(dt: float) -> void:
    if level.bubble_shots.is_empty() or not level._bubble_world_active():return
    refresh_targets();_refresh_walls()
    var serial: int=level.retry_serial
    for shot in level.bubble_shots:
        if shot.get("consumed",false) or float(shot.get("life",0.0))<=0:continue
        if shot.get("epoch",epoch)!=epoch or retired.has(str(shot.get("packet_id",""))):shot["life"]=0.0;continue
        var from: Vector2=shot.get("spawn_from",shot["pos"]);shot.erase("spawn_from")
        var travel:=minf(maxf(dt,0.0),float(shot["life"]))
        var incoming:=Vector2(float(shot["direction"]),0)
        var to: Vector2=Vector2(shot["pos"])+incoming*700.0*travel
        var hit:=_nearest(from,to,shot);shot["life"]=float(shot["life"])-maxf(dt,0.0)
        if hit.is_empty():shot["pos"]=to;continue
        var at:=from.lerp(to,float(hit["t"]));shot["pos"]=at
        _retire(shot) # Consume before callbacks, including reentrant retries and duo overlap.
        var damage:=0
        var kind: int=hit["kind"]
        var index: int=hit["index"]
        if kind==1:level._opal_hit_switch(index,shot)
        elif kind==2:
            var enemy: Dictionary=level.enemies[index]
            var amount:=1 if shot.get("baby",false) else clampi(int(shot.get("damage",1)),1,3)
            damage=level._hit_enemy(enemy,amount,false,incoming)
        elif kind==3:
            var target: Dictionary=targets[index]
            if not shot.get("baby",false) and shot.get("owner","sarah")=="sarah" and target["bubble"] and target["open"] and float(target["cooldown"])<=0:
                damage=level._opal_hit_boss(target["id"],clampi(int(shot.get("boss_damage",1)),1,2))
        if serial!=level.retry_serial:return
        if is_instance_valid(level.opal_fx):level.opal_fx.impact(at,int(shot.get("tier",1)),damage>0)
    Sweep.compact(level.bubble_shots)
func _nearest(from: Vector2, to: Vector2, shot: Dictionary) -> Dictionary:
    var first:=INF
    var category:=-1
    var chosen:=-1
    var left:=minf(from.x,to.x);var right:=maxf(from.x,to.x)
    var top:=minf(from.y,to.y);var bottom:=maxf(from.y,to.y)
    for i in range(friendly_walls.size()):
        var obstacle: Rect2=friendly_walls[i]
        if right<obstacle.position.x or left>obstacle.end.x or bottom<obstacle.position.y or top>obstacle.end.y:continue
        var t:=Sweep.rectangle(from,to,obstacle)
        if t<first:first=t;category=0;chosen=i
    var switches: Array[Dictionary]=level._opal_switch_targets()
    for i in range(switches.size()):
        if switches[i]["on"]:continue
        if switches[i].get("requires_sarah",false) and shot.get("owner","sarah")!="sarah":continue
        var t:=Sweep.circle(from,to,switches[i]["pos"],48.0)
        if t<first:first=t;category=1;chosen=i
    for i in range(level.enemies.size()):
        var enemy: Dictionary=level.enemies[i]
        if int(enemy["hp"])<=0:continue
        var centre:=Vector2(enemy["x"],enemy["y"])
        if right<centre.x-70 or left>centre.x+70:continue
        var t:=Sweep.circle(from,to,centre,70)
        if t<first:first=t;category=2;chosen=i
    if not shot.get("baby",false) and shot.get("owner","sarah")=="sarah":
        for i in range(targets.size()):
            var target: Dictionary=targets[i]
            if not target["active"]:continue
            var t:=Sweep.circle(from,to,target["pos"],target["radius"])
            if t<first:first=t;category=3;chosen=i
    return {} if category<0 else {"t":first,"kind":category,"index":chosen}
func update_hostile(dt: float) -> void:
    if not level._bubble_world_active() or level.hostile_shots.is_empty():return
    _refresh_walls()
    var serial: int=level.retry_serial
    for shot in level.hostile_shots:
        if float(shot["life"])<=0:continue
        var from: Vector2=shot["pos"]
        var to:=from+Vector2(shot["velocity"])*minf(maxf(dt,0.0),float(shot["life"]))
        var first:=INF
        var left:=minf(from.x,to.x);var right:=maxf(from.x,to.x)
        var top:=minf(from.y,to.y);var bottom:=maxf(from.y,to.y)
        for obstacle in hostile_walls:
            if right<obstacle.position.x or left>obstacle.end.x or bottom<obstacle.position.y or top>obstacle.end.y:continue
            first=minf(first,Sweep.rectangle(from,to,obstacle))
        var player_hit:=Sweep.circle(from,to,level.player,48.0)
        shot["life"]=float(shot["life"])-maxf(dt,0.0)
        if player_hit<first:
            shot["pos"]=from.lerp(to,player_hit);shot["life"]=0.0
            if level.boost_time<=0:
                level._damage(shot["pos"])
                if serial!=level.retry_serial:return
            elif is_instance_valid(level.opal_fx):level.opal_fx.impact(shot["pos"],1,false)
        elif first!=INF:shot["pos"]=from.lerp(to,first);shot["life"]=0.0
        else:shot["pos"]=to
    Sweep.compact(level.hostile_shots)
static func target(id: String, fit: Vector2, radius: float) -> Dictionary:
    return {"id":id,"fit":fit,"radius":radius,"pos":Vector2.ZERO,"active":false,"open":false,"opening":false,
        "cooldown":0.0,"bubble":false,"boost":false,"hp":0}

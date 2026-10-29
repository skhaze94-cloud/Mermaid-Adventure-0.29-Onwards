extends RefCounted
## Earliest swept hit in normalized segment time. Stable ties: rock, switch, enemy, boss.
static func circle(from: Vector2, to: Vector2, centre: Vector2, radius: float) -> float:
    var offset := from-centre
    if offset.length_squared()<=radius*radius:return 0.0
    var movement:=to-from
    var a:=movement.length_squared()
    if a<0.000001:return INF
    var b:=offset.dot(movement)
    var c:=offset.length_squared()-radius*radius
    var discriminant:=b*b-a*c
    if discriminant<0:return INF
    var hit:=(-b-sqrt(discriminant))/a
    return hit if hit>=0 and hit<=1 else INF

static func rectangle(from: Vector2, to: Vector2, bounds: Rect2) -> float:
    var movement:=to-from
    var enter:=0.0
    var leave:=1.0
    for axis in range(2):
        if absf(movement[axis])<0.000001:
            if from[axis]<bounds.position[axis] or from[axis]>bounds.end[axis]:return INF
        else:
            var first:=(bounds.position[axis]-from[axis])/movement[axis]
            var last:=(bounds.end[axis]-from[axis])/movement[axis]
            if first>last:
                var swap:=first
                first=last;last=swap
            enter=maxf(enter,first);leave=minf(leave,last)
            if enter>leave:return INF
    return enter

static func guarded(enemy: Dictionary, incoming: Vector2) -> bool:
    if enemy.get("kind","")!="orchid-hermit" and enemy.get("variant","") not in ["guard","armoured"]:return false
    if enemy.get("mode","")=="recover":return false
    return incoming.x*float(enemy.get("dir",-1)) < -0.0001

static func compact(shots: Array[Dictionary]) -> void:
    var write:=0
    for read in range(shots.size()):
        if float(shots[read].get("life",0.0))>0:
            if write!=read:shots[write]=shots[read]
            write+=1
    shots.resize(write)

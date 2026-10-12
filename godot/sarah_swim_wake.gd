extends Node2D
## Bounded world-space wake: shaded droplets and projected vortex ellipses.
## Camera/facing changes cannot drag already-emitted water around Sarah.
const LIMIT := 72
var droplets: Array[Dictionary] = []
var emission := 0.0
var serial := 0
func _ready() -> void:
    z_index=-3
func clear() -> void:
    droplets.clear()
    emission=0.0
    queue_redraw()
func advance(rig, dt: float) -> void:
    if rig.reduced_motion or not rig.high_quality or rig.leaping or not rig.visible:
        clear()
        return
    for i in range(droplets.size()-1,-1,-1):
        var p: Dictionary = droplets[i]
        p.age+=dt
        p.position+=p.velocity*dt
        p.velocity*=exp(-dt*1.8)
        if p.age>=p.life: droplets.remove_at(i)
    var speed: float = rig.velocity_value.length()
    if speed>65.0:
        emission+=dt*(36.0 if rig.boosting else 18.0)
        while emission>=1.0:
            emission-=1.0
            serial+=1
            var side := -1.0 if serial%2==0 else 1.0
            var direction: Vector2 = rig.velocity_value.normalized()
            var cross := direction.orthogonal()
            var origin: Vector2 = rig.fin_anchor_global()+cross*side*3.0
            if serial%3==0:
                origin=rig.near_arm.global_position if side>0 else rig.far_arm.global_position
            if droplets.size()>=LIMIT: droplets.pop_front()
            droplets.append({"position":origin,"velocity":-rig.velocity_value*.10+cross*side*14.0+Vector2(0,-9),
                "age":0.0,"life":.65 if rig.boosting else .85,"radius":2.0+float(serial%4)*.65,
                "depth":side,"ring":rig.boosting and serial%4==0,"angle":direction.angle()})
    else:
        emission=0.0
    queue_redraw()
func _draw() -> void:
    var inverse := global_transform.affine_inverse()
    for p in droplets:
        var t: float = p.age/p.life
        var fade: float = sin(t*PI)*(1.0-t)*.50
        var center: Vector2 = inverse*p.position
        var radius: float = p.radius*(1.0+t*.8)/maxf(global_scale.abs().x,.1)
        var tint := Color(.55,.91,1.0,fade*(.7 if p.depth<0 else 1.0))
        if p.ring:
            var points := PackedVector2Array()
            for i in range(25):
                var angle := TAU*i/24.0
                var offset := Vector2(cos(angle)*p.radius*(1.0+t*.8)*.55,sin(angle)*p.radius*(1.0+t*.8)*2.5).rotated(p.angle)
                points.append(center+inverse.basis_xform(offset))
            draw_polyline(points,tint,1.0,true)
        else:
            draw_circle(center,radius,tint,false,.85,true)
            draw_circle(center+Vector2(-radius*.25,-radius*.30),radius*.25,Color(.90,1,1,fade),true)

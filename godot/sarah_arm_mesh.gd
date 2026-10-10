extends "res://godot/sarah_ribbon_mesh.gd"
## Painted anatomy pivots inside the limb, with a fixed shoulder and smooth joints.
func skin(elbow_angle: float, wrist_angle: float) -> void:
    var points := rest.duplicate()
    var left := rest[0].x
    var length := 0.0
    var top := INF
    var bottom := -INF
    for point in rest:
        length = maxf(length,point.x-left)
        top = minf(top,point.y)
        bottom = maxf(bottom,point.y)
    var height := bottom-top
    # The source painting slopes downward from sleeve to hand. A y=0 pivot
    # bends empty space above the elbow and pinches the inside of the forearm.
    var elbow := Vector2(left+length*.48,top+height*.51)
    var wrist_rest := Vector2(left+length*.76,top+height*.67)
    var wrist := elbow+(wrist_rest-elbow).rotated(elbow_angle)
    for i in range(points.size()):
        var u := (rest[i].x-left)/length
        if u<=.34:
            points[i] = rest[i]
            continue
        var bend := smoothstep(.34,.66,u)
        var p := elbow+(rest[i]-elbow).rotated(elbow_angle*bend)
        var finger := smoothstep(.73,.87,u)
        points[i] = wrist+(p-wrist).rotated(wrist_angle*finger)
    polygon = points
    mesh_updates += 1

extends "res://godot/sarah_ribbon_mesh.gd"
## Painted anatomy pivots inside the limb, with a fixed shoulder and smooth joints.
var elbow_uv := Vector2(.48,.55)
var wrist_uv := Vector2(.69,.73)
func painted_pivot(point: Vector2) -> Vector2:
    # Read the pivot from the shaped rest grid, so sleeve fullness does not
    # move articulation away from the corresponding painted anatomy.
    var column := point.x*32.0
    var row := point.y*8.0
    var x := mini(31,int(column))
    var y := mini(7,int(row))
    return rest[y*33+x].lerp(rest[y*33+x+1],column-x).lerp(
        rest[(y+1)*33+x].lerp(rest[(y+1)*33+x+1],column-x),row-y)
func skin(elbow_angle: float, wrist_angle: float) -> void:
    var points := rest.duplicate()
    var left := rest[0].x
    var length := rest[32].x-left
    # The source painting slopes downward from sleeve to hand. A y=0 pivot
    # bends empty space above the elbow and pinches the inside of the forearm.
    var elbow := painted_pivot(elbow_uv)
    var wrist_rest := painted_pivot(wrist_uv)
    var wrist := elbow+(wrist_rest-elbow).rotated(elbow_angle)
    for i in range(points.size()):
        var u := (rest[i].x-left)/length
        if u<=.34:
            points[i] = rest[i]
            continue
        # Keep the sleeve fixed, concentrate flexion at the painted elbow,
        # then carry the forearm as one segment instead of bending its length.
        var bend := smoothstep(.36,.56,u)
        var p := elbow+(rest[i]-elbow).rotated(elbow_angle*bend)
        var finger := smoothstep(.63,.78,u)
        points[i] = wrist+(p-wrist).rotated(wrist_angle*finger)
    polygon = points
    mesh_updates += 1

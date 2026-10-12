extends "res://godot/sarah_ribbon_mesh.gd"
## Painted anatomy pivots inside the limb, with a fixed shoulder and smooth joints.
const COLUMNS := 98
const ROWS := 9
var elbow_uv := Vector2(.48,.55)
var wrist_uv := Vector2(.69,.73)
func painted_pivot(point: Vector2) -> Vector2:
    # Read the pivot from the shaped rest grid, so sleeve fullness does not
    # move articulation away from the corresponding painted anatomy.
    var column := point.x*COLUMNS
    var row := point.y*(ROWS-1)
    var x := mini(COLUMNS-1,int(column))
    var y := mini(ROWS-2,int(row))
    return rest[y*(COLUMNS+1)+x].lerp(rest[y*(COLUMNS+1)+x+1],column-x).lerp(
        rest[(y+1)*(COLUMNS+1)+x].lerp(rest[(y+1)*(COLUMNS+1)+x+1],column-x),row-y)
func skin(elbow_angle: float, wrist_angle: float, hand_cup: float = 0.0, streamline: float = 0.0) -> void:
    var points := rest.duplicate()
    var left := rest[0].x
    var length := rest[COLUMNS].x-left
    # The source painting slopes downward from sleeve to hand. A y=0 pivot
    # bends empty space above the elbow and pinches the inside of the forearm.
    var elbow := painted_pivot(elbow_uv)
    var wrist_rest := painted_pivot(wrist_uv)
    var wrist := elbow+(wrist_rest-elbow).rotated(elbow_angle)
    var hand_rest := painted_pivot(Vector2(.80,wrist_uv.y))
    var palm := elbow+(hand_rest-elbow).rotated(elbow_angle)
    palm=wrist+(palm-wrist).rotated(wrist_angle)
    var elbow_rotations: Array[Transform2D] = []
    var wrist_rotations: Array[Transform2D] = []
    var finger_rotations: Array[Transform2D] = []
    var finger_weights := PackedFloat32Array()
    for column in range(COLUMNS+1):
        var u := (rest[column].x-left)/length
        elbow_rotations.append(Transform2D(elbow_angle*smoothstep(.36,.56,u),Vector2.ZERO))
        wrist_rotations.append(Transform2D(wrist_angle*smoothstep(.63,.78,u),Vector2.ZERO))
        var free := smoothstep(.80,.99,u)
        finger_weights.append(free)
        finger_rotations.append(Transform2D(streamline*free*.60,Vector2.ZERO))
    var cup_offset := Vector2(-hand_cup*1.8,hand_cup*.8).rotated(elbow_angle+wrist_angle)
    for i in range(points.size()):
        var column := i%(COLUMNS+1)
        var u := (rest[i].x-left)/length
        if u<=.34:
            points[i] = rest[i]
            continue
        # Keep the sleeve fixed, concentrate flexion at the painted elbow,
        # then carry the forearm as one segment instead of bending its length.
        var p := elbow+elbow_rotations[column].basis_xform(rest[i]-elbow)
        points[i] = wrist+wrist_rotations[column].basis_xform(p-wrist)
        # Soft cupping closes the painted finger fan during the catch and
        # releases it through recovery; the wrist and sleeve remain anchored.
        var free := finger_weights[column]
        var offset := points[i]-palm
        points[i]+=offset*Vector2(-absf(hand_cup)*.10,-hand_cup*.30)*free
        points[i]+=cup_offset*free
        # Torpedo fingers gather toward travel, rather than showing a waving fan.
        # The palm/wrist attachment is pinned; rotation grows along the fingers.
        var gathered := points[i]-palm
        gathered.y*=1.0-streamline*free*.18
        points[i]=palm+finger_rotations[column].basis_xform(gathered)
    polygon = points
    mesh_updates += 1

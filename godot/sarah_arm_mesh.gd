extends "res://godot/sarah_ribbon_mesh.gd"
## Painted anatomy pivots inside the limb, with a fixed shoulder and smooth joints.
const COLUMNS := 98
const ROWS := 13
var root_lock_angle := 0.0
var elbow_rotations: Array[Transform2D] = []
var wrist_rotations: Array[Transform2D] = []
var finger_rotations: Array[Transform2D] = []
var cap_rotations: Array[Transform2D] = []
var elbow_weights:=PackedFloat32Array()
var wrist_weights:=PackedFloat32Array()
var finger_weights:=PackedFloat32Array()
var cap_weights:=PackedFloat32Array()
func prepare_weights() -> void:
    if elbow_weights.size()==COLUMNS+1:return
    elbow_rotations.resize(COLUMNS+1);wrist_rotations.resize(COLUMNS+1);finger_rotations.resize(COLUMNS+1);cap_rotations.resize(COLUMNS+1)
    for column in range(COLUMNS+1):
        var u:=float(column)/COLUMNS
        elbow_weights.append(smoothstep(.36,.56,u));wrist_weights.append(smoothstep(.63,.78,u));finger_weights.append(smoothstep(.80,.99,u));cap_weights.append(1-smoothstep(.13,.34,u))
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
    prepare_weights()
    for column in range(COLUMNS+1):
        elbow_rotations[column]=Transform2D(elbow_angle*elbow_weights[column],Vector2.ZERO)
        wrist_rotations[column]=Transform2D(wrist_angle*wrist_weights[column],Vector2.ZERO)
        finger_rotations[column]=Transform2D(streamline*finger_weights[column]*.60,Vector2.ZERO)
        cap_rotations[column]=Transform2D(-root_lock_angle*cap_weights[column],Vector2.ZERO)
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
    # The cap follows the chest while flexion leaves through the upper arm.
    if absf(root_lock_angle)>.00001:
        for i in range(points.size()):
            var u: float=(rest[i].x-left)/length
            var column:=i%(COLUMNS+1)
            if cap_weights[column]>0:points[i]=cap_rotations[column].basis_xform(points[i])
    polygon = points
    mesh_updates += 1

func current_point(point: Vector2) -> Vector2:
    var column:=point.x*COLUMNS;var row:=point.y*(ROWS-1)
    var x:=mini(COLUMNS-1,int(column));var y:=mini(ROWS-2,int(row))
    return polygon[y*(COLUMNS+1)+x].lerp(polygon[y*(COLUMNS+1)+x+1],column-x).lerp(polygon[(y+1)*(COLUMNS+1)+x].lerp(polygon[(y+1)*(COLUMNS+1)+x+1],column-x),row-y)

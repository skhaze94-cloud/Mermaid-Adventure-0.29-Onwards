extends "res://godot/sarah_ribbon_mesh.gd"
## One connected painted tail; centerline skin preserves length while curling.
const SEGMENTS := 64
var socket := Vector2.ZERO
var tail_length := 175.0
var tip_center := Vector2(-175,0)
var centers := PackedVector2Array()
var angles := PackedFloat32Array()
var bend_value := 0.0
var root_bend := 0.0
func setup(source: Texture2D, region: Rect2, destination: Rect2) -> void:
    configure(source,region,destination,SEGMENTS,13)
    socket = Vector2(destination.end.x,destination.get_center().y)
    tail_length = destination.size.x
    centers.resize(SEGMENTS+1)
    angles.resize(SEGMENTS+1)
    for i in range(rest.size()):
        weights[i] = clampf((socket.x-rest[i].x)/tail_length,0,1)
    skin(Vector4.ZERO,0,0)
func skin(pose: Vector4, tuck: float, steering: float) -> void:
    centers[0] = socket
    angles[0] = 0
    bend_value = pose.y+tuck*1.55+steering*.35
    var step := tail_length/SEGMENTS
    for i in range(1,SEGMENTS+1):
        var t := (float(i)-.5)/SEGMENTS
        # Travel through the body, then fold at the middle; the socket stays fixed.
        var angle := pose.x*smoothstep(0,.28,t)
        # The waist bend flows into the proximal tail, with zero displacement at the socket.
        angle += root_bend*smoothstep(0,.18,t)*(1.0-smoothstep(.45,.80,t))
        angle += bend_value*smoothstep(.22,.70,t)
        angle += pose.z*smoothstep(.67,1,t)
        angles[i] = angle
        centers[i] = centers[i-1]+Vector2(-step,0).rotated(angle)
    var points := rest.duplicate()
    for i in range(points.size()):
        var t := weights[i]
        var column := mini(SEGMENTS,int(round(t*SEGMENTS)))
        var offset := Vector2(0,rest[i].y-socket.y).rotated(angles[column])
        points[i] = centers[column]+offset
    polygon = points
    tip_center = centers[SEGMENTS-3]
    mesh_updates += 1
func reset_shape() -> void:
    super.reset_shape()
    tip_center = Vector2(socket.x-tail_length,socket.y)
    bend_value = 0
    root_bend = 0

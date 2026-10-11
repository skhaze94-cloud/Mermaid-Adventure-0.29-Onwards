extends "res://godot/sarah_ribbon_mesh.gd"
## One connected painted tail; centerline skin preserves length while curling.
const SEGMENTS := 194 # 2,535 paint points: three times v0.30.
var detail_phase := 0.0
var detail_strength := 0.0
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
        var release := smoothstep(.15,.48,t)
        angle += detail_strength*release*(sin(detail_phase*.73-t*5.0)*.009
            +sin(detail_phase*1.17-t*8.0)*.004+sin(detail_phase*1.81-t*11.0)*.002)
        angles[i] = angle
        centers[i] = centers[i-1]+Vector2(-step,0).rotated(angle)
    var points := rest.duplicate()
    for i in range(points.size()):
        var t := weights[i]
        var column := mini(SEGMENTS,int(round(t*SEGMENTS)))
        var offset := Vector2(0,rest[i].y-socket.y).rotated(angles[column])
        var edge := (rest[i].y-socket.y)/(tail_length*.23)
        var tip := smoothstep(.65,.95,t)
        var flutter := detail_strength*tip*(sin(detail_phase*.91-t*6.0+edge*.8)*.20
            +sin(detail_phase*1.39-t*9.0-edge*.5)*.09+sin(detail_phase*2.03-t*12.0)*.04)
        offset.y += flutter*edge
        # Fine scale-breathing, separate from the fin edges and main centerline.
        offset *= 1.0+detail_strength*smoothstep(.2,.55,t)*(sin(detail_phase*.53-t*4.0)*.0015
            +sin(detail_phase*.89-t*6.0)*.0007+sin(detail_phase*1.31-t*9.0)*.0003)
        points[i] = centers[column]+offset
    polygon = points
    tip_center = centers[SEGMENTS-3]
    mesh_updates += 1
func reset_shape() -> void:
    super.reset_shape()
    tip_center = Vector2(socket.x-tail_length,socket.y)
    bend_value = 0
    root_bend = 0
    detail_phase = 0
    detail_strength = 0

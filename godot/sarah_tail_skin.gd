extends "res://godot/sarah_ribbon_mesh.gd"
## One connected painted tail; centerline skin preserves length while curling.
const SEGMENTS := 584 # 7,605 paint points: three times v0.4.
var detail_phase := 0.0
var detail_strength := 0.0
var socket := Vector2.ZERO
var tail_length := 175.0
var tip_center := Vector2(-175,0)
var centers := PackedVector2Array()
var angles := PackedFloat32Array()
var column_normals := PackedVector2Array()
var bend_value := 0.0
var root_bend := 0.0
var column_map := PackedInt32Array()
var flutter_base := PackedVector4Array()
var flutter_edge := PackedVector2Array()
var flutter_shared := PackedFloat32Array()
var scale_wave := PackedFloat32Array()
var row_wave := PackedVector4Array()
var row_edge := PackedVector2Array()
var row_offset := PackedFloat32Array()
var row_distance := PackedFloat32Array()
func setup(source: Texture2D, region: Rect2, destination: Rect2) -> void:
    configure(source,region,destination,SEGMENTS,13)
    socket = Vector2(destination.end.x,destination.get_center().y)
    tail_length = destination.size.x
    centers.resize(SEGMENTS+1)
    angles.resize(SEGMENTS+1)
    column_normals.resize(SEGMENTS+1)
    flutter_base.resize(SEGMENTS+1)
    flutter_edge.resize(SEGMENTS+1)
    flutter_shared.resize(SEGMENTS+1)
    scale_wave.resize(SEGMENTS+1)
    column_map.resize(rest.size())
    for row in range(13):
        var distance := rest[row*(SEGMENTS+1)].y-socket.y
        var edge := distance/(tail_length*.23)
        row_distance.append(distance)
        row_offset.append(edge)
        row_wave.append(Vector4(cos(edge*.8),sin(edge*.8),cos(edge*.5),sin(edge*.5)))
        row_edge.append(Vector2(cos(edge),sin(edge)))
    for i in range(rest.size()):
        weights[i] = clampf((socket.x-rest[i].x)/tail_length,0,1)
        column_map[i] = mini(SEGMENTS,int(round(weights[i]*SEGMENTS)))
    skin(Vector4.ZERO,0,0)
func skin(pose: Vector4, tuck: float, steering: float) -> void:
    centers[0] = socket
    angles[0] = 0
    column_normals[0] = Vector2.DOWN
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
            +sin(detail_phase*1.17-t*8.0)*.004+sin(detail_phase*1.81-t*11.0)*.002
            +sin(detail_phase*.43-t*3.5)*.0015+sin(detail_phase*2.31-t*14.0)*.0008+sin(detail_phase*2.87-t*17.0)*.0004
            +sin(detail_phase*.61-t*4.1)*.001+sin(detail_phase*1.53-t*9.6)*.0006+sin(detail_phase*3.17-t*19.1)*.0003)
        angles[i] = angle
        centers[i] = centers[i-1]+Vector2(-step,0).rotated(angle)
        # Every painted row uses this same column angle. Rotate once, keeping
        # all 7,605 points and the exact centerline/curvature sampling.
        column_normals[i] = Vector2.DOWN.rotated(angles[i])
    # Column waves are shared by all 13 painted rows. Cache the trigonometry.
    for column in range(SEGMENTS+1):
        var t := float(column)/SEGMENTS
        var tip := detail_strength*smoothstep(.65,.95,t)
        var a := detail_phase*.91-t*6.0
        var b := detail_phase*1.39-t*9.0
        flutter_base[column]=Vector4(sin(a)*.20,cos(a)*.20,sin(b)*.09,-cos(b)*.09)*tip
        var d := detail_phase*.57-t*3.9
        var f := detail_phase*2.51-t*15.1
        var h := detail_phase*1.91-t*11.7
        flutter_edge[column]=Vector2(sin(d)*.028+sin(f)*.008+sin(h)*.006,
            cos(d)*.028-cos(f)*.008+cos(h)*.006)*tip
        flutter_shared[column]=(sin(detail_phase*2.03-t*12.0)*.04
            +sin(detail_phase*1.73-t*10.3)*.017+sin(detail_phase*.69-t*4.7)*.012
            +sin(detail_phase*2.93-t*17.3)*.003)*tip
        scale_wave[column]=1.0+detail_strength*smoothstep(.2,.55,t)*(sin(detail_phase*.53-t*4.0)*.0015
            +sin(detail_phase*.89-t*6.0)*.0007+sin(detail_phase*1.31-t*9.0)*.0003)
    var points := rest.duplicate()
    for source_column in range(SEGMENTS+1):
        var column := column_map[source_column]
        var normal := column_normals[column]
        var center := centers[column]
        var base := flutter_base[column]
        var edge := flutter_edge[column]
        var shared := flutter_shared[column]
        var scale_amount := scale_wave[column]
        for row in range(13):
            var offset := normal*row_distance[row]
            var flutter := base.dot(row_wave[row])+edge.dot(row_edge[row])+shared
            offset.y += flutter*row_offset[row]
            offset *= scale_amount
            points[row*(SEGMENTS+1)+source_column] = center+offset
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

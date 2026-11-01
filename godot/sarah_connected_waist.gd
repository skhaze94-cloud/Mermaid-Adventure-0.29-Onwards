extends "res://godot/sarah_ribbon_mesh.gd"
## Broad anatomical loft between the actual deformed lower torso and proximal tail.
## Original scale paint is registered along the same curve; no accessory/effect mask.
const COLUMNS:=12
const ROWS:=12
func bind(rig) -> void:
    var resolution: Vector2=rig.NEW_TAIL.get_size()/Vector2(2172,724)
    configure(rig.NEW_TAIL,Rect2(Vector2(1900,200)*resolution,Vector2(220,330)*resolution),Rect2(0,0,1,1),COLUMNS,ROWS+1)
    var coords:=uv.duplicate()
    for row in range(ROWS+1):
        var t:=float(row)/ROWS
        for col in range(COLUMNS+1):
            var cross:=float(col)/COLUMNS
            # Register to the exact original tail columns and central painted rows.
            var source_column: int=192-int(round(t*15))
            var source_row: float=3.6+cross*4.8
            var lo:=int(source_row);var fraction:=source_row-lo
            coords[row*(COLUMNS+1)+col]=rig.tail_skin.uv[lo*193+source_column].lerp(rig.tail_skin.uv[(lo+1)*193+source_column],fraction)
    uv=coords
    z_index=-1
func apply(rig) -> void:
    var body=rig.bodice;var tail=rig.tail_skin
    var p0: Vector2=rig.torso.transform*body.polygon[8*75+37]
    var hip: Vector2=rig.torso.transform*tail.transform*tail.polygon[6*193+192]
    var column:=15
    var inverse: Transform2D=rig.torso.transform.affine_inverse()
    var p2: Vector2=rig.torso.transform*tail.transform*tail.polygon[6*193+193-column-1]
    var start_tangent: Vector2=rig.torso.transform.basis_xform(body.polygon[9*75+37]-body.polygon[7*75+37]).normalized()
    var end_tangent: Vector2=(rig.torso.transform.basis_xform(tail.transform.basis_xform(tail.polygon[6*193+193-column-2]-tail.polygon[6*193+193-column]))).normalized()
    var distance:=p0.distance_to(p2)
    var a: Vector2=p0+start_tangent*distance*.38
    var b: Vector2=p2-end_tangent*distance*.32
    var points:=rest.duplicate()
    for row in range(ROWS+1):
        var t:=float(row)/ROWS
        var center:=p0*pow(1-t,3)+a*3*t*pow(1-t,2)+b*3*t*t*(1-t)+p2*t*t*t
        var tangent: Vector2=(a-p0)*3*pow(1-t,2)+(b-a)*6*(1-t)*t+(p2-b)*3*t*t
        var screen_tangent:=Vector2(tangent.x*rig.scale.x,tangent.y*rig.scale.y).normalized()
        var screen_normal:=Vector2(screen_tangent.y,-screen_tangent.x)
        var cross_axis:=Vector2(screen_normal.x/rig.scale.x,screen_normal.y/rig.scale.y)
        var radius: float=lerpf(12.0,15.5,t)*(1.0-rig.definitive_21.front_weight*.12)
        for col in range(COLUMNS+1):
            var lateral:=(float(col)/COLUMNS-.5)*2
            points[row*(COLUMNS+1)+col]=inverse*(center+cross_axis*lateral*radius)
    polygon=points
    mesh_updates+=1

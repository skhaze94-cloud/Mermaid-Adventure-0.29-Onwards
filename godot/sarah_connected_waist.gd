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
            coords[row*(COLUMNS+1)+col]=Vector2(2120-t*220,238+cross*260)*resolution
    uv=coords
    z_index=-1
func apply(rig) -> void:
    var body=rig.bodice;var tail=rig.tail_skin
    var p0: Vector2=rig.torso.transform*body.polygon[8*75+37]
    var hip: Vector2=rig.torso.transform*tail.transform*tail.polygon[6*193+192]
    var column:=15
    var inverse: Transform2D=rig.torso.transform.affine_inverse()
    var p2: Vector2=rig.torso.transform*tail.transform*tail.polygon[6*193+193-column-1]
    var points:=rest.duplicate()
    for row in range(ROWS+1):
        var t:=float(row)/ROWS
        var center:=p0*(1-t)*(1-t)+hip*2*t*(1-t)+p2*t*t
        var tangent: Vector2=(hip-p0)*2*(1-t)+(p2-hip)*2*t
        var screen_tangent:=Vector2(tangent.x*rig.scale.x,tangent.y*rig.scale.y).normalized()
        var screen_normal:=Vector2(screen_tangent.y,-screen_tangent.x)
        var cross_axis:=Vector2(screen_normal.x/rig.scale.x,screen_normal.y/rig.scale.y)
        var radius: float=lerpf(12.0,15.5,t)*(1.0-rig.definitive_21.front_weight*.12)
        for col in range(COLUMNS+1):
            var lateral:=(float(col)/COLUMNS-.5)*2
            points[row*(COLUMNS+1)+col]=inverse*(center+cross_axis*lateral*radius)
    polygon=points
    mesh_updates+=1

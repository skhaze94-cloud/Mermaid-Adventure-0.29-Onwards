extends RefCounted
## Registered paint coordinates on ONE body surface; no overlapping torso sprites.
var front_uv:=PackedVector2Array()
var front_texture: Texture2D
var material: ShaderMaterial
static var cached_front_uv:=PackedVector2Array()
static var cached_custom:=PackedFloat32Array()
func _span(image: Image,rect: Rect2,v: float) -> Vector2:
    var y:=clampi(int(rect.position.y+v*(rect.size.y-1)),0,image.get_height()-1)
    var first:=1.0;var last:=0.0
    for x in range(int(rect.position.x),mini(image.get_width(),int(rect.end.x))):
        if image.get_pixel(x,y).a>.35:
            var u: float=(x-rect.position.x)/rect.size.x
            first=minf(first,u);last=maxf(last,u)
    return Vector2(first,last) if last-first>.06 else Vector2(0,1)
func bind(rig) -> void:
    front_texture=load("res://godot/assets/sarah-flow-v026/front-connected.png")
    if cached_front_uv.is_empty():
        var front_image:=front_texture.get_image();var side_image: Image=rig.ATLAS.get_image()
        var size:=Vector2(front_image.get_size());var crop:=Rect2(Vector2(65,190)/1254.0*size,Vector2(1130,980)/1254.0*size)
        var custom:=PackedFloat32Array();custom.resize(rig.bodice.rest.size()*4)
        for row in range(13):
            var v:=float(row)/12
            var a:=_span(side_image,rig.BODICE_REGION,v);var b:=_span(front_image,crop,v)
            for col in range(75):
                var u:=float(col)/74
                var q: float=(u-a.x)/maxf(.06,a.y-a.x)
                var mapped: float=lerpf(b.x,b.y,q) if v>.18 else u
                front_uv.append(Vector2(mapped,v))
                var uv: Vector2=(crop.position+Vector2(mapped,v)*crop.size)/size
                var i:=row*75+col;custom[i*4]=uv.x;custom[i*4+1]=uv.y
        cached_front_uv=front_uv;cached_custom=custom
    else:front_uv=cached_front_uv
    rig.bodice.custom0=cached_custom;rig.bodice._build_surface()
    material=ShaderMaterial.new();material.shader=load("res://godot/shaders/sarah_body_view.gdshader")
    material.set_shader_parameter("front_paint",front_texture);rig.bodice.material=material
    rig.volume_materials.append(material)
func apply(rig,weight: float,collar: Vector2) -> void:
    material.set_shader_parameter("view_mix",weight)
    if weight<.00001:return
    var points: PackedVector2Array=rig.bodice.polygon
    var body_transform: Transform2D=rig.torso.transform;var inverse:=body_transform.affine_inverse()
    var hx: float=rig.scale.x
    for i in range(points.size()):
        var uv:=front_uv[i]
        var local:=Vector2((uv.x-.5)*66.0/absf(hx)*(1+rig.torso_motion.breath.x),(uv.y-.12)*62.0)
        var hip:=Vector2(0,48)
        var hip_weight:=smoothstep(.55,.92,uv.y)
        local=local.lerp(hip+(local-hip).rotated(rig.torso_motion.waist.x),hip_weight)
        points[i]=inverse*((body_transform*points[i]).lerp(collar+local,weight))
    rig.bodice.polygon=points

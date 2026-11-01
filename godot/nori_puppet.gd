extends MeshInstance2D
## An immutable original painting with independently articulated antennae,
## mailbag and mantle. Fixed mesh; all motion is a bounded vertex shader.
const PAINTING_PATH="res://godot/assets/pocket-wonders/sea-slug-postman.webp"
const MOTION=preload("res://godot/shaders/nori_living.gdshader")
var paint: ShaderMaterial
const GRID:=28
func _ready() -> void:
    texture=load(PAINTING_PATH)
    var vertices:=PackedVector3Array();var uvs:=PackedVector2Array();var indices:=PackedInt32Array()
    for row in range(GRID+1):
        for col in range(GRID+1):
            var uv:=Vector2(float(col)/GRID,float(row)/GRID)
            vertices.append(Vector3((uv.x-.5)*1254,(uv.y-1147.0/1254)*1254,0))
            uvs.append(uv)
    for row in range(GRID):
        for col in range(GRID):
            var i:=row*(GRID+1)+col
            indices.append_array(PackedInt32Array([i,i+1,i+GRID+1,i+1,i+GRID+2,i+GRID+1]))
    var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uvs;arrays[Mesh.ARRAY_INDEX]=indices
    var painted_mesh:=ArrayMesh.new();painted_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    mesh=painted_mesh
    paint=ShaderMaterial.new();paint.shader=MOTION;material=paint
func pose(foot: Vector2,height: float,tick: float,gentle: bool,look_left: bool,attention: float) -> void:
    position=foot
    var factor:=height/1058.0
    scale=Vector2(-factor if look_left else factor,factor)
    paint.set_shader_parameter("story_time",tick)
    paint.set_shader_parameter("movement",0.0 if gentle else 1.0)
    paint.set_shader_parameter("attention",attention)

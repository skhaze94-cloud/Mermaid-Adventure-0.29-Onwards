extends Node2D
## One authored placement per garden painting. Rocks stay planted; only the tips sway.
const Art=preload("res://godot/tutorial_atelier_art.gd")
const WIND=preload("res://godot/shaders/tutorial_garden.gdshader")
const PLACEMENTS: Array[Vector4]=[
    Vector4(220,893,0,152),Vector4(1650,895,1,166),
    Vector4(3140,894,3,142),Vector4(4020,895,2,108),
    Vector4(5770,893,4,150),Vector4(7030,894,5,118),
    Vector4(378,1516,7,86),Vector4(1438,1495,6,108)]
var host: Node2D
var gardens: Array[MeshInstance2D]=[]
var motion_state:=-1
func bind(level: Node2D) -> void:
    host=level;name="AuthoredTutorialGardens";z_index=2;set_process(false)
    for i in range(PLACEMENTS.size()):
        var p: Vector4=PLACEMENTS[i]
        var crop: Rect2=Art.GARDEN_REGIONS[int(p.z)]
        var size:=Vector2(p.w*crop.size.x/crop.size.y,p.w)
        var vertices:=PackedVector3Array();var uv:=PackedVector2Array();var indices:=PackedInt32Array()
        for row in range(7):
            for column in range(9):
                var q:=Vector2(float(column)/8,float(row)/6)
                vertices.append(Vector3((q.x-.5)*size.x,(q.y-1)*size.y,0))
                uv.append((crop.position+Vector2(.5,.5)+q*(crop.size-Vector2.ONE))/Art.GARDEN_SHEET.get_size())
        for row in range(6):
            for column in range(8):
                var n:=row*9+column;indices.append_array(PackedInt32Array([n,n+1,n+9,n+1,n+10,n+9]))
        var arrays:=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_INDEX]=indices
        var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
        var actor:=MeshInstance2D.new();actor.name="Garden_%s" % int(p.z);actor.mesh=mesh;actor.texture=Art.GARDEN_SHEET;actor.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
        var material:=ShaderMaterial.new();material.shader=WIND
        var atlas_size:=Art.GARDEN_SHEET.get_size()
        material.set_shader_parameter("atlas_rect",Vector4(crop.position.x/atlas_size.x,crop.position.y/atlas_size.y,crop.end.x/atlas_size.x,crop.end.y/atlas_size.y))
        material.set_shader_parameter("phase",float(i)*1.73);actor.material=material
        actor.modulate=Color(.91,.96,.94,1);add_child(actor);gardens.append(actor)
    sync()
func sync() -> void:
    if not is_instance_valid(host):return
    var quality:=0 if host.reduced_fx else 1
    if quality!=motion_state:
        motion_state=quality
        for garden in gardens:garden.material.set_shader_parameter("motion_strength",float(quality))
    visible=host.waterfall_phase=="" and host.state in ["playing","paused"]
    var view:=Rect2(Vector2(host.camera,host._camera_y())-Vector2(240,200),host.get_viewport_rect().size+Vector2(480,400))
    for i in range(gardens.size()):
        var p: Vector4=PLACEMENTS[i]
        gardens[i].position=Vector2(p.x-host.camera,p.y)
        gardens[i].visible=visible and view.has_point(Vector2(p.x,p.y))

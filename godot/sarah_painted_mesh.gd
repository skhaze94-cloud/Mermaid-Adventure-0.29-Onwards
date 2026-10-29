extends MeshInstance2D
## Exact painted grid on a persistent indexed surface. Only positions change per frame.
## Polygon2D rebuilt UVs, colours, topology and GPU buffers for every skin update.
## Keep the polygon/UV interface so geometry and paint-registration reviews remain valid.
var polygon := PackedVector2Array():
    set(value):
        polygon = value
        if surface_mesh and vertex_count == value.size():
            surface_mesh.surface_update_vertex_region(0,0,value.to_byte_array())
            vertex_uploads += 1
        else:
            _build_surface()
var uv := PackedVector2Array():
    set(value):
        uv = value
        _build_surface()
var polygons: Array[PackedInt32Array] = []:
    set(value):
        polygons = value
        _build_surface()
var surface_mesh: ArrayMesh
var vertex_count := 0
var topology_builds := 0
var vertex_uploads := 0
var custom0 := PackedFloat32Array()
var custom1 := PackedFloat32Array()

func _build_surface() -> void:
    if polygon.is_empty() or uv.size()!=polygon.size() or polygons.is_empty() or texture==null:
        return
    var normalized_uv := PackedVector2Array()
    normalized_uv.resize(uv.size())
    var size := texture.get_size()
    for i in range(uv.size()): normalized_uv[i] = uv[i]/size
    var indices := PackedInt32Array()
    indices.resize(polygons.size()*3)
    for i in range(polygons.size()):
        # Authored grids contain explicit triangles; their connectivity never changes.
        assert(polygons[i].size()==3)
        for j in range(3): indices[i*3+j] = polygons[i][j]
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = polygon
    arrays[Mesh.ARRAY_TEX_UV] = normalized_uv
    arrays[Mesh.ARRAY_INDEX] = indices
    var flags := Mesh.ARRAY_FLAG_USE_2D_VERTICES | Mesh.ARRAY_FLAG_USE_DYNAMIC_UPDATE
    if not custom0.is_empty():
        arrays[Mesh.ARRAY_CUSTOM0] = custom0
        flags |= Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT
    if not custom1.is_empty():
        arrays[Mesh.ARRAY_CUSTOM1] = custom1
        flags |= Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT
    var replacement := ArrayMesh.new()
    replacement.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},
        flags)
    assert(replacement.get_surface_count()==1,"Painted mesh surface upload failed")
    # Dynamic uploads do not recalculate the AABB. Reserve the complete articulation
    # envelope so a curl, roll or camera edge cannot clip the moving painted skin.
    var bounds := Rect2(polygon[0],Vector2.ZERO)
    for point in polygon: bounds = bounds.expand(point)
    bounds = bounds.grow(maxf(bounds.size.length()*2.0,64.0))
    replacement.custom_aabb = AABB(Vector3(bounds.position.x,bounds.position.y,-1),Vector3(bounds.size.x,bounds.size.y,2))
    surface_mesh = replacement
    mesh = surface_mesh
    vertex_count = polygon.size()
    topology_builds += 1

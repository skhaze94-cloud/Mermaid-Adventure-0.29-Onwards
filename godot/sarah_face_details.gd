extends "res://godot/sarah_painted_mesh.gd"
## One persistent painted surface. Neck anchors and UVs stay fixed.
const DETAIL_SHADER = preload("res://godot/shaders/sarah_face_details.gdshader")
const COLUMNS := 584 # 28,665 connected points: three times v0.4.
const ROWS := 49
var rest := PackedVector2Array()
var surface: ShaderMaterial
var full_triangles: Array[PackedInt32Array] = []
var play_triangles: Array[PackedInt32Array] = []
var full_detail := true
static var cached_feature_key := 0
static var cached_features0 := PackedFloat32Array()
static var cached_features1 := PackedFloat32Array()

static func feature(point: Vector2, center: Vector2, radius: Vector2) -> float:
    var d := (point-center)/radius
    return exp(-d.dot(d)*2.0)

func _prepare_features(coordinates: PackedVector2Array, source_size: Vector2, region: Rect2) -> void:
    var key := hash([coordinates,source_size,region])
    if cached_feature_key != key or cached_features0.is_empty():
        var first := PackedFloat32Array()
        var second := PackedFloat32Array()
        first.resize(coordinates.size()*4)
        second.resize(coordinates.size()*4)
        for i in range(coordinates.size()):
            # Reproduce the shader's registered paint coordinates. These masks
            # depend only on the unchanged painting, never the live pose.
            var p := (coordinates[i]/source_size*source_size-region.position-Vector2(.5,.5))/(region.size-Vector2.ONE)
            var anchored := 1.0-smoothstep(.78,.90,p.y)
            var hair := maxf(1.0-smoothstep(.38,.64,p.x),1.0-smoothstep(.10,.22,p.y))
            first[i*4] = anchored
            first[i*4+1] = feature(p,Vector2(.49,.70),Vector2(.10,.12))
            first[i*4+2] = feature(p,Vector2(.83,.565),Vector2(.065,.075))
            first[i*4+3] = feature(p,Vector2(.80,.71),Vector2(.14,.085))
            second[i*4] = feature(p,Vector2(.82,.685),Vector2(.11,.025))
            second[i*4+1] = feature(p,Vector2(.73,.65),Vector2(.20,.15))
            second[i*4+2] = maxf(feature(p,Vector2(.68,.36),Vector2(.12,.05)),feature(p,Vector2(.88,.31),Vector2(.085,.05)))
            second[i*4+3] = (1.0-smoothstep(.12,.67,p.x))*hair*anchored
        cached_feature_key = key
        cached_features0 = first
        cached_features1 = second
    custom0 = cached_features0
    custom1 = cached_features1

func configure(source: Texture2D, regions: Array) -> void:
    texture=source
    texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
    var region: Rect2 = regions[0]
    var coordinates := PackedVector2Array()
    var triangles: Array[PackedInt32Array] = []
    for row in range(ROWS):
        for column in range(COLUMNS+1):
            var p := Vector2(float(column)/COLUMNS,float(row)/(ROWS-1))
            rest.append(p*region.size)
            coordinates.append(region.position+Vector2(.5,.5)+p*(region.size-Vector2.ONE))
    for row in range(ROWS-1):
        for column in range(COLUMNS):
            var a := row*(COLUMNS+1)+column
            var b := a+COLUMNS+1
            triangles.append(PackedInt32Array([a,a+1,b+1]))
            triangles.append(PackedInt32Array([a,b+1,b]))
    _prepare_features(coordinates,source.get_size(),region)
    polygon=rest
    uv=coordinates
    polygons=triangles
    full_triangles=triangles
    # Retain all authored points, but avoid shading invisible subpixel triangles.
    var columns: Array[int] = []
    for column in range(0,COLUMNS,3): columns.append(column)
    columns.append(COLUMNS)
    for row in range(ROWS-1):
        for index in range(columns.size()-1):
            var a := row*(COLUMNS+1)+columns[index]
            var next := row*(COLUMNS+1)+columns[index+1]
            var b := a+COLUMNS+1
            var end := next+COLUMNS+1
            play_triangles.append(PackedInt32Array([a,next,end]))
            play_triangles.append(PackedInt32Array([a,end,b]))
    surface=ShaderMaterial.new()
    surface.shader=DETAIL_SHADER
    surface.set_shader_parameter("atlas_size",source.get_size())
    for i in range(3):
        var crop: Rect2 = regions[i]
        surface.set_shader_parameter(["neutral_crop","happy_crop","blink_crop"][i],Vector4(crop.position.x,crop.position.y,crop.size.x,crop.size.y))
    material=surface
    reset_details()

func adapt_detail(high: bool) -> void:
    var width := 710.0*get_global_transform_with_canvas().get_scale().abs().x
    var wanted := high and (width>110.0 if full_detail else width>130.0)
    if wanted==full_detail: return
    full_detail=wanted
    polygons=full_triangles if full_detail else play_triangles

static func blink_at(time: float) -> float:
    var phase := fposmod(time,4.7)
    # Quick close, short hold, gentle reopening; no whole-face texture swap.
    return smoothstep(4.45,4.51,phase)*(1.0-smoothstep(4.56,4.68,phase))

func set_response(flow: Vector2, turn: float, effort: float, breath: float,
        body_wave: float, hair_lag: float, phase: float, gaze: Vector2,
        expression: float, blink: float, enabled: bool) -> void:
    surface.set_shader_parameter("detail_enabled",enabled)
    surface.set_shader_parameter("response",Vector4(flow.x,flow.y,turn,effort))
    surface.set_shader_parameter("breath",breath)
    surface.set_shader_parameter("body_wave",body_wave)
    surface.set_shader_parameter("hair_lag",hair_lag)
    surface.set_shader_parameter("motion_phase",phase)
    surface.set_shader_parameter("gaze",gaze if enabled else Vector2.ZERO)
    surface.set_shader_parameter("expression",expression)
    surface.set_shader_parameter("blink",blink)

func reset_details() -> void:
    surface.set_shader_parameter("jaw_open",0.0)
    surface.set_shader_parameter("neck_follow",0.0)
    set_response(Vector2.ZERO,0,0,0,0,0,0,Vector2.ZERO,0,0,false)

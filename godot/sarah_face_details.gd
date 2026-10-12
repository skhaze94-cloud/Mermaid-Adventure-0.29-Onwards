extends Polygon2D
## One persistent painted surface. Neck anchors and UVs stay fixed.
const DETAIL_SHADER = preload("res://godot/shaders/sarah_face_details.gdshader")
const COLUMNS := 584 # 28,665 connected points: three times v0.4.
const ROWS := 49
var rest := PackedVector2Array()
var surface: ShaderMaterial
var full_triangles: Array[PackedInt32Array] = []
var play_triangles: Array[PackedInt32Array] = []
var full_detail := true

func configure(source: Texture2D, regions: Array) -> void:
    texture=source
    texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
    antialiased=true
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

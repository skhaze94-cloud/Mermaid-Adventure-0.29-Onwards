extends Node2D
## Persistent high-density skin. Pose transitions are independent of frame rate.
const KING = preload("res://godot/assets/characters-v027/king-daddy.png")
const QUEEN = preload("res://godot/assets/characters-v027/queen-antonella.png")
const BODY_SHADER = preload("res://godot/shaders/royal_body.gdshader")
var mesh: MeshInstance2D
var surface: ShaderMaterial
var role := "king"
var pose := "idle"
var clock := 0.0
var previous_clock := -1.0
var gentle := false
var size := Vector2(207,310)
var pose_blend := Vector3.ZERO
var cast_glow := 0.0

func _ready() -> void:
    z_index = 3
    mesh = MeshInstance2D.new()
    mesh.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    surface = ShaderMaterial.new()
    surface.shader = BODY_SHADER
    mesh.material = surface
    mesh.mesh = _make_skin()
    add_child(mesh)
    configure(role)

func configure(kind: String, height := 310.0) -> void:
    role = kind
    var art: Texture2D = KING if role=="king" else QUEEN
    size = art.get_size()*(height/art.get_height())
    mesh.texture = art
    mesh.scale = size
    previous_clock = -1.0
    pose_blend = Vector3.ZERO
    cast_glow = 0.0
    surface.set_shader_parameter("is_queen",role=="queen")
    animate(0,"idle",true)

func animate(at: float, mode: String, reduced: bool) -> void:
    var dt := clampf(at-previous_clock,0.0,.05) if previous_clock>=0 else 0.0
    previous_clock = at
    clock = at
    pose = mode
    gentle = reduced
    var target := Vector3.ZERO
    match mode:
        "wave": target = Vector3(.13,.035,.012)
        "celebrate": target = Vector3(.18,.07,-.018)
        "cast": target = Vector3(-.15,-.08,-.025)
        "hug": target = Vector3(.10,.12,.02)
        "dash": target = Vector3(-.16,-.035,.12)
        "swim": target = Vector3(.07,.055,-.02)
    var ease := 1.0-exp(-dt*10.0)
    pose_blend = pose_blend.lerp(target,ease)
    cast_glow = lerpf(cast_glow,1.0 if mode=="cast" else 0.0,ease)
    surface.set_shader_parameter("clock",clock)
    surface.set_shader_parameter("strength",0.0 if gentle else 1.0)
    surface.set_shader_parameter("pose",pose_blend)
    mesh.rotation = 0.0 if gentle else pose_blend.z+sin(clock*1.5)*.008
    queue_redraw()

func _make_skin() -> ArrayMesh:
    var vertices := PackedVector3Array()
    var uv := PackedVector2Array()
    var triangles := PackedInt32Array()
    const COLUMNS := 40
    const ROWS := 56
    for y in range(ROWS+1):
        for x in range(COLUMNS+1):
            vertices.append(Vector3(float(x)/COLUMNS-.5,float(y)/ROWS-.5,0))
            uv.append(Vector2(float(x)/COLUMNS,float(y)/ROWS))
    for y in range(ROWS):
        for x in range(COLUMNS):
            var i := y*(COLUMNS+1)+x
            triangles.append_array(PackedInt32Array([i,i+1,i+COLUMNS+1,i+1,i+COLUMNS+2,i+COLUMNS+1]))
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_TEX_UV] = uv
    arrays[Mesh.ARRAY_INDEX] = triangles
    var result := ArrayMesh.new()
    result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    return result

func _draw() -> void:
    if cast_glow<.01: return
    var hand := size*(Vector2(.31,-.15) if role=="king" else Vector2(.37,-.245))
    var color := Color("b4f4ff") if role=="king" else Color("ffe1cb")
    draw_arc(hand,18+(0.0 if gentle else sin(clock*3)*2),0,TAU,48,Color(color,cast_glow*.5),2,true)
    for i in range(4):
        var angle := i*TAU/4+(0.0 if gentle else clock)
        var offset := Vector2(cos(angle),sin(angle))*25
        draw_circle(hand+offset,2,Color(color,cast_glow))

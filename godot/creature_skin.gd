extends MeshInstance2D
## Persistent dense painted skin with smoothly blended articulated animation tracks.
const Motion = preload("res://godot/creature_motion.gd")
const Art = preload("res://godot/creature_art.gd")
static var shared_mesh: ArrayMesh
var profile := ""
var surface: ShaderMaterial
var clips: AnimationLibrary
var clip_index := 0
var joints := Vector4.ZERO
var posture := Vector4.ZERO
var cycle := 0.0
var last_clock := -1.0
var last_sample_clock := -1.0
var last_mode := ""
var mode_started := 0.0
var initialized := false
var flip_h: bool = false:
    set(value):
        flip_h = value
        if surface: surface.set_shader_parameter("facing",-1.0 if value else 1.0)

static func geometry() -> ArrayMesh:
    if shared_mesh: return shared_mesh
    var vertices := PackedVector3Array()
    var uv := PackedVector2Array()
    var triangles := PackedInt32Array()
    for y in range(33):
        for x in range(49):
            vertices.append(Vector3(x/48.0-.5,y/32.0-.5,0))
            uv.append(Vector2(x/48.0,y/32.0))
    for y in range(32):
        for x in range(48):
            var i := y*49+x
            triangles.append_array(PackedInt32Array([i,i+1,i+49,i+1,i+50,i+49]))
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX]=vertices
    arrays[Mesh.ARRAY_TEX_UV]=uv
    arrays[Mesh.ARRAY_INDEX]=triangles
    shared_mesh = ArrayMesh.new()
    shared_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    return shared_mesh

func configure(kind: String, art: Texture2D = null, bounds := Vector2.ZERO) -> void:
    profile = kind
    clips = Motion.library(kind)
    mesh = geometry()
    surface = ShaderMaterial.new()
    surface.shader = preload("res://godot/shaders/creature_skin.gdshader")
    material = surface
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    var source: Texture2D = art
    if source == null: source = Art.atlas(kind,canonical_pose(kind))
    var size := source.get_size()
    if source is AtlasTexture:
        texture = source.atlas
        set_region(source.region)
    else:
        texture = source
    if bounds != Vector2.ZERO:
        scale = size*minf(bounds.x/size.x,bounds.y/size.y)
    else:
        scale = size*Art.base_scale(kind)
    surface.set_shader_parameter("anatomy",{"eel":1,"jelly":2,"crab":3,"carlo":6,"duke":6,"puffer":4,"swordfish":5,"shark":7,"blackwater":7,"miguel":8,"nessie":9,"flip":10,"rana":11,"palace":12,"training":12}.get(kind,0))

static func canonical_pose(kind: String) -> int:
    return 2 if kind=="crab" else 0

func set_region(region: Rect2) -> void:
    var full := texture.get_size()
    surface.set_shader_parameter("cell_uv",Vector4(region.position.x/full.x,region.position.y/full.y,region.size.x/full.x,region.size.y/full.y))

func animate(mode: String, clock: float, _dt: float, phase: float = 0.0, gentle: bool = false, quality: bool = true, update_detail: bool = true, source_age: float = -1.0) -> void:
    if mode != last_mode:
        last_mode = mode
        mode_started = clock
    var age := maxf(0.0,clock-mode_started) if source_age<0 else source_age
    clip_index = Motion.select(mode,age,clock,phase)
    surface.set_shader_parameter("combat_pose",Art.pose(mode))
    surface.set_shader_parameter("animate_detail",not gentle)
    surface.set_shader_parameter("high_quality",quality)
    if gentle:
        joints=Vector4.ZERO
        posture=Vector4.ZERO
        surface.set_shader_parameter("joints",joints)
        surface.set_shader_parameter("posture",posture)
        last_clock=clock
        return
    # The game clock freezes in pause. Avoid accumulating phase in paused UI sync.
    var advance := 0.0 if last_clock<0 else clampf(clock-last_clock,0.0,.10)
    last_clock=clock
    var anim := clips.get_animation(Motion.CLIPS[clip_index])
    cycle += advance/anim.length
    if not initialized: cycle=phase/TAU
    if not update_detail and initialized: return
    var at := fposmod(cycle,1.0)*anim.length
    var target: Vector4 = anim.value_track_interpolate(0,at)
    var goal: Vector4 = anim.value_track_interpolate(1,at)
    var ease := 1.0 if not initialized else 1.0-exp(-clampf(clock-last_sample_clock,0.0,.10)*14.0)
    last_sample_clock=clock
    joints=joints.lerp(target,ease)
    posture=posture.lerp(goal,ease)
    initialized=true
    surface.set_shader_parameter("joints",joints)
    surface.set_shader_parameter("posture",posture)
    surface.set_shader_parameter("visual_clock",cycle*TAU)
    surface.set_shader_parameter("depth_turn",joints.w)

func reset_motion() -> void:
    initialized=false
    last_clock=-1
    last_sample_clock=-1
    last_mode=""
    joints=Vector4.ZERO
    posture=Vector4.ZERO
    cycle=0

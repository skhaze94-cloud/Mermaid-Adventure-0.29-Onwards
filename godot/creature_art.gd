extends RefCounted
## Shared artwork, pose layout and proportions for both lake and waterfall creatures.
const TEXTURES := {
    "crab": preload("res://godot/assets/enemy-crab-v09.webp"),
    "eel": preload("res://godot/assets/enemy-eel-v09.webp"),
    "jelly": preload("res://godot/assets/enemy-jelly-v09.webp"),
    "puffer": preload("res://godot/assets/enemy-puffer-v09.webp"),
    "swordfish": preload("res://godot/assets/enemy-swordfish-v09.webp"),
    "shark": preload("res://godot/assets/enemy-shark-v09.webp"),
    "carlo": preload("res://godot/assets/enemy-carlo-v09.webp")
}
const SHADER: Shader = preload("res://godot/shaders/creature_portrait.gdshader")
const SIZES := {"crab": Vector2(180,150), "eel": Vector2(242,155),
    "jelly": Vector2(142,208), "puffer": Vector2(172,172),
    "swordfish": Vector2(250,158), "shark": Vector2(235,184), "carlo": Vector2(380,310)}

static func region(kind: String, pose_index: int) -> Rect2:
    var texture: Texture2D = TEXTURES[kind]
    if kind == "shark":
        # Supplied sheet has irregular spacing; use measured portrait bounds.
        var cells := [Rect2(330,50,410,285), Rect2(750,45,342,290),
            Rect2(1100,80,340,260), Rect2(20,705,360,330)]
        return cells[clampi(pose_index,0,3)]
    var cell := texture.get_size() / 2.0
    # The broad attacking claws extend past the geometric halfway line.
    # Explicit source bounds retain the whole claw and exclude its neighbour.
    if kind == "crab" and pose_index >= 2:
        var split := texture.get_width() * (680.0 / 1254.0)
        return Rect2(0.0 if pose_index == 2 else split, cell.y,
            split if pose_index == 2 else texture.get_width() - split, cell.y)
    if kind == "carlo" and pose_index >= 2:
        var split := texture.get_width() * (800.0 / 1536.0)
        return Rect2(0.0 if pose_index == 2 else split, cell.y,
            split if pose_index == 2 else texture.get_width() - split, cell.y)
    return Rect2(Vector2(pose_index % 2, pose_index / 2) * cell, cell)

static func pose(mode: String) -> int:
    return {"patrol":0, "windup":1, "attack":2, "recover":3}.get(mode,0)

static func base_scale(kind: String) -> Vector2:
    var size := region(kind,0).size
    for frame in range(1,4):
        size = size.max(region(kind,frame).size)
    var target: Vector2 = SIZES[kind]
    # Fit in a bounded box with uniform scale, rather than squashing anatomy.
    return Vector2.ONE * minf(target.x / size.x, target.y / size.y)

static func atlas(kind: String, frame := 0) -> AtlasTexture:
    var texture := AtlasTexture.new()
    texture.atlas = TEXTURES[kind]
    texture.region = region(kind,frame)
    texture.filter_clip = true
    return texture

static func material(kind: String) -> ShaderMaterial:
    var result := ShaderMaterial.new()
    result.shader = SHADER
    result.set_shader_parameter("anatomy", {"eel":1,"jelly":2,"crab":3,"carlo":3,"puffer":4,"swordfish":5,"shark":5}.get(kind,0))
    set_region(result,kind,0)
    return result

static func set_region(surface: ShaderMaterial, kind: String, frame: int) -> void:
    var rect := region(kind,frame)
    var texture: Texture2D = TEXTURES[kind]
    surface.set_shader_parameter("cell_uv", Vector4(rect.position.x / texture.get_width(),
        rect.position.y / texture.get_height(), rect.size.x / texture.get_width(), rect.size.y / texture.get_height()))

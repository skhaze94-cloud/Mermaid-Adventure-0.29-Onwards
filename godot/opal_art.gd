extends RefCounted
## Scene-owned textures/materials. Only metadata survives between chapters.
const ROOT := "res://godot/assets/opal-current/"
const Roster=preload("res://godot/opal_roster.gd")
const SHADER=preload("res://godot/shaders/opal_projectile.gdshader")
static var metadata: Dictionary={}
var atlases: Dictionary={}
var frames: Dictionary={}
var materials: Dictionary={}
var chapter:=""
func configure(which: String, friendly: Texture2D, enemies: Texture2D, boss: Texture2D) -> void:
    chapter=which
    if metadata.is_empty():metadata=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"manifest.json"))
    for pair in [["friendly",friendly],["lagoon" if which=="miguel" else "enemies",enemies],[which,boss]]:
        var key: String=pair[0]
        if not metadata["atlases"].has(key):continue
        atlases[key]=pair[1] if pair[1] else load(ROOT+metadata["atlases"][key]["file"])
    for key in metadata["frames"]:
        var entry: Dictionary=metadata["frames"][key]
        if not atlases.has(entry["atlas"]):continue
        var rect: Array=entry["region"]
        var frame:=AtlasTexture.new();frame.atlas=atlases[entry["atlas"]]
        frame.region=Rect2(rect[0],rect[1],rect[2],rect[3]);frame.filter_clip=true
        frames[key]=frame
        var material:=ShaderMaterial.new();material.shader=SHADER
        var size: Vector2=frame.atlas.get_size()
        material.set_shader_parameter("cell_uv",Vector4(rect[0]/size.x,rect[1]/size.y,rect[2]/size.x,rect[3]/size.y))
        materials[key]=material
func key_for(style: String) -> String:
    var key: String=Roster.ENEMY_STYLE.get(style,style)
    key=metadata["aliases"].get(key,key)
    return key if frames.has(key) else (chapter if frames.has(chapter) else "puffer")
func set_gentle(gentle: bool) -> void:
    for material in materials.values():material.set_shader_parameter("gentle",gentle)

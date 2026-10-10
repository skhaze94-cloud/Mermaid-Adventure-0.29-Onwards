extends RefCounted
## The pack uses measured, irregular cells. Trim each source rect using its manifest,
## preserving the actual four directions (including the swapped ribbon windup views).
const ROOT := "res://godot/assets/lagoon-pack/"
static var frames: Dictionary = {}
static var textures: Dictionary = {}
static var sizes: Dictionary = {}
static var frame_atlases: Dictionary = {}
static func load_pack() -> void:
    if not frames.is_empty(): return
    var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"manifest.json"))
    for atlas in manifest["atlases"]: textures[atlas["id"]] = load(ROOT+atlas["file"])
    for frame in manifest["frames"]:
        var r: Array = frame["rect"]
        var bounds: Array = frame["contentBoundsInCell"]
        var crop := Rect2(r[0]+bounds[0],r[1]+bounds[1],bounds[2]-bounds[0],bounds[3]-bounds[1])
        var texture := AtlasTexture.new()
        texture.atlas = textures[frame["atlas"]]
        texture.region = crop
        texture.filter_clip = true
        frames[frame["id"]] = texture
        frame_atlases[frame["id"]] = frame["atlas"]
        sizes[frame["atlas"]] = maxf(float(sizes.get(frame["atlas"],0)),maxf(crop.size.x,crop.size.y))
static func enemy_frame(enemy: Dictionary) -> Texture2D:
    load_pack()
    var angle := "left-profile" if int(enemy.get("dir",-1)) < 0 else "right-profile"
    if String(enemy.get("mode","patrol")) in ["approach","windup"]: angle = "left-three-quarter" if int(enemy.get("dir",-1)) < 0 else "right-three-quarter"
    var pose := "windup" if String(enemy.get("mode","patrol")) in ["windup","attack"] else "idle"
    return frames.get(String(enemy["kind"])+"/"+pose+"/"+angle)
static func keys(atlas: String) -> Array[String]:
    load_pack()
    var result: Array[String] = []
    for key in frames:
        if frame_atlases[key] == atlas: result.append(key)
    return result

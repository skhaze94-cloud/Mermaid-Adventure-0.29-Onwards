extends RefCounted
const BASE="res://godot/assets/cavern-v034/"
const ROOMS={"nursery":"res://godot/assets/tutorial-v025/pearl-nursery.png","bellflower":"res://godot/assets/tutorial-v025/bellflower-hollow.png","roots":"rootgarden","cathedral":"cathedral","ribbonlight":"archive","lantern":"res://godot/assets/tutorial-v025/bellflower-hollow.png","moonpool":"moonpool","postbox":"archive","orchid":"rootgarden","amphitheatre":"coraltheatre","silverstream":"moonpool","pocket-rain":"archive","tea-terrace":"coraltheatre","shell-rehearsal":"cathedral","sea-star":"moonpool"}
static func painting(id: String) -> Texture2D:
    var path: String=ROOMS[id]
    return load(path if path.begins_with("res://") else BASE+path+".png")
static func tint(id: String) -> Color:
    match id:
        "orchid":return Color(.98,.91,1.03)
        "silverstream":return Color(.88,1.02,1.02)
        "pocket-rain":return Color(.86,.91,1.0)
        "tea-terrace":return Color(1.01,.98,.90)
        "sea-star":return Color(.94,.99,1.03)
    return Color.WHITE

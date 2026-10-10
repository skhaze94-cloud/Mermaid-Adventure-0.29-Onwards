extends RefCounted
## Measured alpha bounds: atlas frames are intentionally not assumed to be equal cells.
const GARDENS: Texture2D = preload("res://godot/assets/environment-gardens-v011.webp")
const ROCKS: Texture2D = preload("res://godot/assets/environment-rocks-v011.webp")
const PROPS: Texture2D = preload("res://godot/assets/environment-props-v011.webp")
const GARDEN_REGIONS = [Rect2(38,15,371,413), Rect2(479,53,376,371), Rect2(904,42,392,388), Rect2(1350,38,397,394), Rect2(18,516,415,332), Rect2(474,456,387,402), Rect2(904,530,394,314), Rect2(1344,489,408,366)]
const ROCK_REGIONS = [Rect2(113,27,463,727), Rect2(734,50,429,704), Rect2(25,804,595,414), Rect2(636,814,598,408)]
const PROP_REGIONS = [Rect2(94,81,477,504), Rect2(658,129,556,481), Rect2(110,695,471,462), Rect2(751,671,353,507)]
static func crop(source: Texture2D, region: Rect2) -> AtlasTexture:
    var atlas := AtlasTexture.new()
    atlas.atlas = source
    atlas.region = region
    atlas.filter_clip = true
    return atlas
static func garden(i: int) -> AtlasTexture:
    return crop(GARDENS, GARDEN_REGIONS[[0,1,2,3,5,6,7][posmod(i, 7)]])
static func rock(i: int) -> AtlasTexture:
    return crop(ROCKS, ROCK_REGIONS[posmod(i, 4)])
static func prop(kind: String) -> AtlasTexture:
    return crop(PROPS, PROP_REGIONS[{"pearl":0, "chest":1, "heart":2, "boost":3}.get(kind, 0)])

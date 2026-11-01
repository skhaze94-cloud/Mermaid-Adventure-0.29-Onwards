extends RefCounted
## Original alpha atlases; clipped regions and cached textures, no image copies at runtime.
const ROCK_SHEET: Texture2D=preload("res://godot/assets/tutorial-v033/reef-formations.png")
const ROCK_REGIONS: Array[Rect2]=[Rect2(16,80,375,233),Rect2(414,105,303,212),Rect2(728,86,346,233),Rect2(1084,80,346,247),Rect2(62,335,217,387),Rect2(440,348,187,372),Rect2(720,450,338,251),Rect2(1075,385,347,315),Rect2(26,760,334,251),Rect2(375,811,356,193),Rect2(751,779,335,229),Rect2(1118,770,291,240)]
static var rock_frames: Array[Texture2D]=[]
static func rock(index: int) -> Texture2D:
    if rock_frames.is_empty():
        for region in ROCK_REGIONS:
            var frame:=AtlasTexture.new();frame.atlas=ROCK_SHEET;frame.region=region;frame.filter_clip=true;rock_frames.append(frame)
    return rock_frames[posmod(index,ROCK_REGIONS.size())]
const GARDEN_SHEET: Texture2D=preload("res://godot/assets/tutorial-v033/coral-gardens.png")
const GARDEN_REGIONS: Array[Rect2]=[Rect2(42,27,407,417),Rect2(512,21,342,443),Rect2(912,107,409,344),Rect2(1370,52,368,390),Rect2(31,483,414,363),Rect2(504,535,392,301),Rect2(938,491,417,345),Rect2(1423,516,303,335)]
static var garden_frames: Array[Texture2D]=[]
static func garden(index: int) -> Texture2D:
    if garden_frames.is_empty():
        for region in GARDEN_REGIONS:
            var frame:=AtlasTexture.new();frame.atlas=GARDEN_SHEET;frame.region=region;frame.filter_clip=true;garden_frames.append(frame)
    return garden_frames[posmod(index,GARDEN_REGIONS.size())]
const PLINTH_SHEET: Texture2D=preload("res://godot/assets/tutorial-v033/treasure-plinths.png")
const PLINTH_REGIONS: Array[Rect2]=[Rect2(26,251,465,261),Rect2(532,187,479,327),Rect2(1043,225,468,290),Rect2(27,653,462,256),Rect2(531,622,469,283),Rect2(1040,647,468,273)]
static var plinth_frames: Array[Texture2D]=[]
static func plinth(index: int) -> Texture2D:
    if plinth_frames.is_empty():
        for region in PLINTH_REGIONS:
            var frame:=AtlasTexture.new();frame.atlas=PLINTH_SHEET;frame.region=region;frame.filter_clip=true;plinth_frames.append(frame)
    return plinth_frames[posmod(index,PLINTH_REGIONS.size())]
const WREATH_SHEET: Texture2D=preload("res://godot/assets/tutorial-v033/swim-wreaths.png")
const WREATH_REGIONS: Array[Rect2]=[Rect2(21,20,686,681),Rect2(736,20,701,669),Rect2(1465,13,691,692)]
static var wreath_frames: Array[Texture2D]=[]
static func wreath(index: int) -> Texture2D:
    if wreath_frames.is_empty():
        for region in WREATH_REGIONS:
            var frame:=AtlasTexture.new();frame.atlas=WREATH_SHEET;frame.region=region;frame.filter_clip=true;wreath_frames.append(frame)
    return wreath_frames[posmod(index,WREATH_REGIONS.size())]

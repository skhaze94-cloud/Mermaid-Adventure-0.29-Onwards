extends RefCounted
## Extracted by executing the supplied v8.2 setup functions in a DOM-free VM.
## Keep source coordinates here; controllers implement basic native gameplay.
const Rock = preload("res://godot/rock_collision.gd")
static var cache: Dictionary = {}
const IDS := ["highland","shadow","miguel","blackwater","palace","rana","nessie","training"]
const TITLES := ["Highland Gold","Shadow Crab Kingdom","Miguel’s Lagoon","Blackwater Tunnel","Pearl Palace","Rana Rex’s Rainbow Ruin","Nessie · The Crown Thief","The Family’s Enchanted Lagoon"]
static func source(id: String) -> Dictionary:
    if cache.is_empty():
        var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://godot/source/levels-v82.json"))
        if parsed is Dictionary: cache = parsed
        else: push_error("Unable to read v8.2 chapter data")
    return cache.get(id,{})
static func length_for(id: String) -> float:
    # Nessie's HTML finale reuses Rana's world, but confines combat to 2730–3650.
    # Split it into a playable standalone arena with a short unlocked exit.
    return 5500.0 if id == "nessie" else float(source(id).get("length",7600))
static func boss_health(id: String) -> int:
    var boss: Dictionary = source(id).get("boss",{})
    return int(boss.get("max",boss.get("maxHp",boss.get("hp",3))))
static func boss_x(id: String) -> float:
    return 3280.0 if id == "nessie" else float(source(id).get("boss",{}).get("x",6900))
static func waterline(id: String) -> float:
    return float(source(id).get("meta",{}).get("waterline",310))
static func obstacles_for(id: String) -> Array[Rect2]:
    var result: Array[Rect2] = []
    for b in source(id).get("obstacles",[]): result.append(Rect2(float(b.x),float(b.y),float(b.w),float(b.h)))
    return result
static func enemies_for(id: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var rocks := obstacles_for(id)
    for original in source(id).get("enemies",[]):
        var kind := String(original.get("kind","crab"))
        var variant := String(original.get("variant",""))
        if "crab" in kind:
            variant = kind.replace("-crab","") if variant.is_empty() else variant
            kind = "crab"
        elif kind in ["spark-eel","storm-eel"]: kind = "eel"; variant = "electric"
        elif kind == "reef-shark": kind = "shark"
        elif kind == "seahorse": kind = "swordfish"
        var point := Rock.recover(Vector2(float(original.x),float(original.y)),rocks,76,Rect2(50,waterline(id)+90,length_for(id)-90,735-waterline(id)))
        result.append({"kind":kind,"source_kind":original.get("kind","crab"),"x":point.x,"y":point.y,"bx":point.x,"by":point.y,"hp":int(original.get("hp",1)),"phase":float(original.get("phase",result.size())),"cooldown":0.0,"dir":-1,"variant":variant,"hit_cd":0.0})
    return result
static func treasure_for(id: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for item in source(id).get("coins",[]):
        if id=="nessie" and (float(item.x)<2730 or float(item.x)>length_for(id)-100): continue
        result.append({"x":float(item.x),"y":float(item.y),"kind":"chest" if item.get("type","")=="chest" else "pearl","taken":false,"phase":float(item.get("phase",0))})
    for item in source(id).get("powerups",[]):
        if id=="nessie" and (float(item.x)<2730 or float(item.x)>length_for(id)-100): continue
        result.append({"x":float(item.x),"y":float(item.y),"kind":"heart" if item.get("type","")=="heart" else "boost","taken":false,"phase":float(item.get("phase",0))})
    if id == "training":
        for item in source(id).get("training",{}).get("relics",[]):
            result.append({"x":float(item.x),"y":float(item.y),"kind":"chest","taken":false,"phase":0.0})
    var rocks := obstacles_for(id)
    for item in result:
        var point := Rock.recover(Vector2(item.x,item.y),rocks,55,Rect2(50,80,length_for(id)-90,780))
        item.x = point.x
        item.y = point.y
    return result
static func pads_for(id: String) -> Array[float]:
    var result: Array[float] = []
    for x in source(id).get("meta",{}).get("pads",[]):
        if float(x) < length_for(id)-100: result.append(float(x))
    return result

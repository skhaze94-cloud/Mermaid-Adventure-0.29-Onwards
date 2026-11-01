extends RefCounted
## Authored optional caverns. Every room has two surface connections, an upper
## gallery, a lower pocket and a central reef that gives a genuine choice of path.
const FLOOR:=910.0
const BOTTOM:=2240.0
const DEFINITIONS:={
    3:[{"id":"pocket-rain","name":"The Pocket-Rain Tailor Tunnel","x":4700.0,"y":1160.0,"w":1500.0,"h":600.0,"a":4950.0,"b":5950.0,"color":Color("a5d9e4")}],
    4:[{"id":"tea-terrace","name":"The Very Polite Tea Tunnel","x":7300.0,"y":1160.0,"w":1700.0,"h":620.0,"a":7550.0,"b":8740.0,"color":Color("ead2ad")}],
    5:[{"id":"shell-rehearsal","name":"The Sleepy Shell Tunnel","x":14700.0,"y":1160.0,"w":1700.0,"h":620.0,"a":14940.0,"b":16130.0,"color":Color("d1b9ec")}],
    6:[{"id":"sea-star","name":"The Little Sea-Star Tunnel","x":3650.0,"y":1100.0,"w":1300.0,"h":520.0,"a":3880.0,"b":4700.0,"color":Color("adcee9")}],
    7:[
        {"id":"nursery","name":"The Pearl Nursery","x":280.0,"y":1100.0,"w":1260.0,"h":580.0,"a":660.0,"b":1160.0,"color":Color("9cdcd4")},
        {"id":"bellflower","name":"Bellflower Hollow","x":1860.0,"y":1160.0,"w":1180.0,"h":620.0,"a":2100.0,"b":2860.0,"color":Color("d4b9ea")}],
    0:[
        {"id":"roots","name":"Nori’s Root Garden","x":850.0,"y":1160.0,"w":1560.0,"h":540.0,"a":1200.0,"b":2260.0,"color":Color("b5dfc2")},
        {"id":"cathedral","name":"The Sunken Bell Cathedral","x":6000.0,"y":1200.0,"w":1640.0,"h":670.0,"a":6240.0,"b":7400.0,"color":Color("b5c8ed")},
        {"id":"ribbonlight","name":"Ribbonlight Archive","x":11700.0,"y":1120.0,"w":1560.0,"h":640.0,"a":11940.0,"b":13020.0,"color":Color("eed1b1")}],
    2:[
        {"id":"orchid","name":"The Orchid Rootways","x":2100.0,"y":1160.0,"w":1640.0,"h":640.0,"a":2360.0,"b":3440.0,"color":Color("d6a6d8")},
        {"id":"amphitheatre","name":"The Coral Amphitheatre","x":7900.0,"y":1240.0,"w":1800.0,"h":660.0,"a":8200.0,"b":9410.0,"color":Color("b1dec9")},
        {"id":"silverstream","name":"Silverstream Hollow","x":15900.0,"y":1120.0,"w":1780.0,"h":650.0,"a":16200.0,"b":17500.0,"color":Color("a1dbe9")}],
    1:[
        {"id":"lantern","name":"The Lantern-Well Caverns","x":1650.0,"y":1160.0,"w":1560.0,"h":660.0,"a":1900.0,"b":2960.0,"color":Color("bea6e6")},
        {"id":"moonpool","name":"The Upside-Down Moonpool","x":4800.0,"y":1240.0,"w":1700.0,"h":650.0,"a":5060.0,"b":6240.0,"color":Color("8edbde")},
        {"id":"postbox","name":"The Lost Postbox Grotto","x":8500.0,"y":1140.0,"w":1680.0,"h":660.0,"a":8770.0,"b":9890.0,"color":Color("d9aecf")}]
}
static func enabled(chapter: int) -> bool:return DEFINITIONS.has(chapter)
static func rooms(chapter: int) -> Array[Dictionary]:
    var result: Array[Dictionary]=[]
    for authored in DEFINITIONS.get(chapter,[]):
        var room: Dictionary=authored.duplicate(true)
        room["key"]="cavern:%s:%s" % [chapter,room["id"]]
        var x: float=room["x"];var y: float=room["y"];var w: float=room["w"];var h: float=room["h"]
        var center:=Vector2(x+w*.5,y+h*.5)
        room["body"]=Rect2(x,y,w,h)
        room["free"]=[Rect2(x,y,w,h),Rect2(float(room["a"])-(160 if chapter==7 else 130),780,320 if chapter==7 else 260,y-780+240),Rect2(float(room["b"])-(160 if chapter==7 else 130),780,320 if chapter==7 else 260,y-780+240),
            Rect2(x+w*.35,y-145,w*.35,310),Rect2(x+w*.39,y+h-80,w*.32,310)]
        room["reef"]=Rect2(center-Vector2(w*.10,40),Vector2(w*.20,120))
        room["neighbourhood"]=result.is_empty()
        room["perches"]=[]
        if room["neighbourhood"]:
            var right_start:=x+w-155
            if right_start<float(room["b"])+70:right_start=float(room["b"])-225
            room["perches"]=[Rect2(x+5,y+h*.66,150,46),Rect2(right_start,y+h*.63,150,46)]
        elif chapter in [0,1,2]:
            room["perches"]=[Rect2(x+5,y+h*.66,150,46)]
        if chapter==7 and room["neighbourhood"]:
            room["perches"]=[Rect2(x,y+410,260,95),Rect2(x+w-250,y+390,250,100)]
        room["chest"]=Vector2(x+w*.55,y+h+140)
        room["waypoints"]=[Vector2(room["a"],720),Vector2(room["a"],y+150),Vector2(room["a"],y+h-110),
            Vector2(x+w*.55,y+h-110),Vector2(x+w*.55,y+h+130),Vector2(x+w*.55,y+h-110),
            Vector2(room["b"],y+h-110),Vector2(room["b"],y+140),Vector2(room["b"],720)]
        room["upper_route"]=[Vector2(room["a"],y+150),Vector2(x+w*.43,y+70),Vector2(x+w*.50,y-45),Vector2(x+w*.62,y+70),Vector2(room["b"],y+140)]
        result.append(room)
    return result

static func apertures(chapter: int) -> Array[Rect2]:
    var out: Array[Rect2]=[]
    for room in rooms(chapter):
        for key in ["a","b"]:out.append(Rect2(float(room[key])-(160 if chapter==7 else 130),600,320 if chapter==7 else 260,440))
    return out

static func surface_rocks(original: Array[Rect2],chapter: int) -> Array[Rect2]:
    var rocks: Array[Rect2]=original.duplicate()
    if not enabled(chapter):return rocks
    for hole in apertures(chapter):
        var next: Array[Rect2]=[]
        for rock in rocks:
            var cut:=rock.intersection(hole)
            if not cut.has_area():next.append(rock);continue
            if cut.position.x>rock.position.x:next.append(Rect2(rock.position,Vector2(cut.position.x-rock.position.x,rock.size.y)))
            if cut.end.x<rock.end.x:next.append(Rect2(cut.end.x,rock.position.y,rock.end.x-cut.end.x,rock.size.y))
            if cut.position.y>rock.position.y:next.append(Rect2(cut.position.x,rock.position.y,cut.size.x,cut.position.y-rock.position.y))
            if cut.end.y<rock.end.y:next.append(Rect2(cut.position.x,cut.end.y,cut.size.x,rock.end.y-cut.end.y))
        rocks=next
    return rocks

static func solids(chapter: int,length: float) -> Array[Rect2]:
    var out: Array[Rect2]=[]
    if not enabled(chapter):return out
    var openings: Array[Rect2]=[];var cuts: Array[float]=[0.0,length]
    for room in rooms(chapter):
        for space in room["free"]:
            openings.append(space);cuts.append(space.position.x);cuts.append(space.end.x)
    cuts.sort()
    for i in range(cuts.size()-1):
        var x: float=cuts[i];var width: float=cuts[i+1]-x
        if width<.1:continue
        var spans: Array[Vector2]=[]
        for space in openings:
            if x+width*.5>=space.position.x and x+width*.5<=space.end.x:spans.append(Vector2(maxf(FLOOR,space.position.y),minf(BOTTOM,space.end.y)))
        spans.sort_custom(func(a,b):return a.x<b.x)
        var y:=FLOOR
        for span in spans:
            if span.x>y:out.append(Rect2(x,y,width,span.x-y))
            y=maxf(y,span.y)
        if y<BOTTOM:out.append(Rect2(x,y,width,BOTTOM-y+120))
    for room in rooms(chapter):
        if chapter!=7:out.append(room["reef"])
        for perch in room["perches"]:out.append(perch)
    return out

static func treasures(chapter: int) -> Array[Dictionary]:
    var out: Array[Dictionary]=[]
    for room in rooms(chapter):
        out.append({"x":room["chest"].x,"y":room["chest"].y,"kind":"chest","taken":false,"phase":0.0,"deep_id":String(room["key"])+":chest"})
        if chapter==7:continue
        for i in range(6):
            var at:=Vector2(float(room["a"]),920+i*65.0)
            if at.y>float(room["y"])+130:break
            out.append({"x":at.x,"y":at.y,"kind":"pearl","taken":false,"phase":float(i),"deep_id":String(room["key"])+":pearl:"+str(i)})
    return out

static func merge_treasures(existing: Array[Dictionary],chapter: int,seen: Dictionary={}) -> void:
    if chapter==7:
        for i in range(existing.size()-1,-1,-1):
            if String(existing[i].get("deep_id","")).begins_with("cavern:7:") and existing[i]["kind"]=="pearl":existing.remove_at(i)
    for extra in treasures(chapter):
        var found:=false
        for item in existing:
            if item.get("deep_id","")==extra["deep_id"]:
                found=true
                if chapter==7:
                    item["x"]=extra["x"];item["y"]=extra["y"]
                    item["taken"]=bool(item.get("taken",false)) or seen.has(extra["deep_id"])
                break
        if not found:
            extra["taken"]=seen.has(extra["deep_id"])
            existing.append(extra)

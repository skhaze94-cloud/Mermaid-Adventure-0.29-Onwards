extends RefCounted
## One two-character neighbourhood in each chapter; textures load per scene.
const Deep=preload("res://godot/deep_routes_data.gd")
const PAIRS:={7:["mallow","tilly"],0:["posy","purl"],1:["ludo","vesper"],2:["peep","saffron"],3:["button","hush"],4:["crumb","dot"],5:["miri","oona"],6:["bibi","thimble"]}
const NAMES:={7:"The Quilt-and-Pearl Nursery",0:"Posy & Purl’s Garden Steps",1:"The Lantern Story Library",2:"The Bubble-Tart Conservatory",3:"The Pocket-Rain Tailor Shop",4:"The Very Polite Tea Terrace",5:"The Sleepy Shell Rehearsal",6:"The Little Sea-Star Observatory"}
const TINTS:=[Color("e8c5ca"),Color("c5bee9"),Color("b7e2ca"),Color("a5d9e4"),Color("ead2ad"),Color("d1b9ec"),Color("adcee9"),Color("dfc8e9")]
static var cast: Dictionary={}
static func load_cast() -> void:
    if not cast.is_empty():return
    var data=JSON.parse_string(FileAccess.get_file_as_string("res://godot/assets/whimsy-four/cast.json"))
    if not data is Dictionary:return
    for person in data.get("characters",[]):cast[person["id"]]=person
static func for_chapter(chapter: int) -> Dictionary:
    load_cast()
    var room: Dictionary=Deep.rooms(chapter)[0]
    var people: Array[Dictionary]=[]
    for i in range(2):
        var actor: Dictionary=cast[PAIRS[chapter][i]].duplicate(true)
        actor["foot"]=Vector2(room["perches"][i].get_center().x,room["perches"][i].position.y)
        actor["height"]=168.0 if i==0 else 178.0
        actor["talk_at"]=actor["foot"]-Vector2(0,100)
        actor["room_index"]=0
        actor["home"]=actor["foot"];actor["roam"]=true
        actor["talk_offset"]=Vector2(175 if i==0 else -175,-100)
        actor["talk_at"]=actor["foot"]+actor["talk_offset"]
        actor["reply"]="A little hello makes a lovely adventure, "+String(actor["name"])+"."
        if chapter==7:
            actor["foot"]=Vector2(float(room["x"])+140,float(room["y"])+410) if i==0 else Vector2(float(room["x"])+float(room["w"])-130,float(room["y"])+390)
            actor["height"]=200.0 if i==0 else 210.0
            actor["talk_offset"]=Vector2(185 if i==0 else -225,-110)
            actor["talk_at"]=actor["foot"]+actor["talk_offset"]
            actor["home"]=actor["foot"];actor["roam"]=true
            actor["lines"]=["I made a little quiet corner. Come and rest your fins, Sarah.","Follow the soft light. Both openings lead back to the lagoon.","I was practising a very small stroll. Would you stroll with me?"] if i==0 else ["Sarah! There is room for both of us by the pearl ledge.","Dozy keeps the warm lanterns in Bellflower Hollow, just along the lagoon.","I like a little paddle, then a little hello."]
        if not String(actor["lines"][0]).contains("Sarah"):actor["lines"][0]="Hi, Sarah! "+String(actor["lines"][0])
        actor["reply"]={"mallow":"A tiny stroll sounds lovely, Mallow.","tilly":"A gentle hello for everyone, Tilly.","posy":"A bouquet just because! That is very kind, Posy.","purl":"A scarf for my tail? I will hold very still, Purl.","ludo":"Thank you for keeping a little light for us, Ludo.","vesper":"I shall bring you a lovely new dream, Vesper.","peep":"A bubble tart sounds deliciously light, Peep!","saffron":"Good morning to every leaf, Saffron.","button":"That is a very smart little stitch, Button.","hush":"A quiet hello is a lovely hello too, Hush.","crumb":"One tiny crumb and a very big thank-you, Crumb.","dot":"May I have the smallest cup, Dot?","miri":"Your little shell song makes me smile, Miri.","oona":"I shall save you a very gentle round of applause, Oona.","bibi":"One little star, and one very good friend, Bibi.","thimble":"I like looking at the sea with you, Thimble."}.get(actor["id"],actor["reply"])
        people.append(actor)
    var rooms:=Deep.rooms(chapter)
    for index in range(1,rooms.size()):
        var place: Dictionary=rooms[index]
        if not preload("res://godot/cavern_friends_data.gd").PEOPLE.has(place["id"]):continue
        var actor: Dictionary=preload("res://godot/cavern_friends_data.gd").PEOPLE[place["id"]].duplicate(true)
        actor["room_index"]=index;actor["height"]=185.0 if actor["id"]!="luma" else 200.0
        var perch: Rect2=place["perches"][0]
        actor["foot"]=Vector2(perch.get_center().x,perch.position.y)
        actor["home"]=actor["foot"];actor["roam"]=true
        actor["talk_offset"]=Vector2(185,-100);actor["talk_at"]=actor["foot"]+actor["talk_offset"]
        people.append(actor)
    return {"id":"whimsy-four:"+str(chapter),"name":NAMES[chapter],"room":room,"rooms":rooms,"people":people,"tint":TINTS[chapter],"after_boss":chapter==6}

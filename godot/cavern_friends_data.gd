extends RefCounted
const SHEET=preload("res://godot/assets/cavern-v034/friends.png")
const REGIONS: Array[Rect2]=[Rect2(36,29,457,474),Rect2(556,43,459,454),Rect2(1048,24,460,474),Rect2(26,539,513,442),Rect2(554,546,464,435),Rect2(1041,514,478,479)]
const PEOPLE={
 "cathedral":{"id":"coda","name":"Coda","kind":"music","atlas":0,"lines":["Hi, Sarah! I polish the little bells. This one rings like a giggle.","The big arch echoes your smallest hello. Shall we try a quiet one?","Both streams lead outside. I will keep your little bell warm."],"reply":"A giggling bell! That is a lovely sound, Coda."},
 "ribbonlight":{"id":"folio","name":"Folio","kind":"light","atlas":1,"lines":["Hello, Sarah! I keep the sea's smallest stories in these ribbons.","This scroll is about a brave mermaid. The ending is still swimming here.","A good story always leaves room for a friend."],"reply":"Then let us put a friendly hello in the next chapter, Folio."},
 "moonpool":{"id":"luma","name":"Luma","kind":"light","atlas":2,"lines":["Hi, Sarah! Welcome to my moon-blue little corner.","I am practising a very gentle wobble. You can wobble with me.","That silver current leads back up. No need to hurry, though."],"reply":"One gentle wobble, coming right up, Luma!"},
 "postbox":{"id":"pipette","name":"Pipette","kind":"stars","atlas":3,"lines":["Sarah! Special delivery: one hello and absolutely no bills.","Nori taught me how to deliver kindness. I am still practising the stamp.","This envelope is empty. It leaves lots of room for a nice thought."],"reply":"My favourite sort of delivery. Thank you, Pipette!"},
 "amphitheatre":{"id":"tango","name":"Tango","kind":"music","atlas":4,"lines":["Hello, Sarah! Front-row swimming for our very important mermaid.","Tonight's performance is a tiny wave. I have rehearsed both claws.","You may clap with bubbles. The coral rather likes it."],"reply":"Bravo, Tango! That was a magnificent little wave."},
 "silverstream":{"id":"rill","name":"Rill","kind":"garden","atlas":5,"lines":["Hi, Sarah! I followed the silver stream and found a friend.","My gills tickle when the current tells a funny story.","Both little streams go up to the reef. I will wave you home."],"reply":"Then this was a very good stream to follow, Rill."}}
static var frames: Array[Texture2D]=[]
static func texture(index: int) -> Texture2D:
    if frames.is_empty():
        for region in REGIONS:
            var frame:=AtlasTexture.new();frame.atlas=SHEET;frame.region=region;frame.filter_clip=true;frames.append(frame)
    return frames[index]

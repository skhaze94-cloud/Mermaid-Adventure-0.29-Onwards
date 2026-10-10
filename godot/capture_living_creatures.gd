extends SceneTree
## Native 60 fps proof of the shipped mesh rigs, not a separate animated mock-up.
const CreatureSkin = preload("res://godot/creature_skin.gd")
const Art = preload("res://godot/creature_art.gd")
var actors: Array = []
var cards: Array[Label] = []
func _initialize() -> void: call_deferred("run")
func label(stage: Node, text: String, where: Vector2, width: float, size: int, color := Color("dff7f1")) -> Label:
    var item := Label.new()
    item.text=text
    item.position=where
    item.size=Vector2(width,65)
    item.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    item.add_theme_font_size_override("font_size",size)
    item.modulate=color
    stage.add_child(item)
    return item
func run() -> void:
    root.get_node("OceanAudio").playback_enabled=false
    var out := OS.get_environment("CREATURE_CAPTURE_DIR")
    if out.is_empty():out="/tmp/creatures028"
    DirAccess.make_dir_recursive_absolute(out)
    var stage := Node2D.new()
    root.add_child(stage)
    var background := ColorRect.new()
    background.color=Color("073544")
    background.size=Vector2(1400,960)
    stage.add_child(background)
    label(stage,"SARAH MARIA · MERMAID ADVENTURE",Vector2(0,28),1400,19,Color("9ae4d4"))
    label(stage,"Living Creatures · v0.28",Vector2(0,68),1400,43)
    var subtitle := label(stage,"16 motion clips per creature · connected joints · continuous movement",Vector2(0,137),1400,20,Color("a9cfce"))
    var state_label := label(stage,"",Vector2(0,192),1400,21,Color("f7d69a"))
    label(stage,"Actual Godot meshes and animation tracks used throughout the adventure",Vector2(0,908),1400,18,Color("a9cfce"))
    for i in range(6):
        var actor := CreatureSkin.new()
        stage.add_child(actor)
        actor.position=Vector2(245+(i%3)*455,365+(i/3)*337)
        actors.append(actor)
        cards.append(label(stage,"",Vector2((i%3)*455+22,513+(i/3)*337),435,21))
    for frame in range(960):
        var bosses := frame>=480
        if frame in [0,480]:
            subtitle.text="Boss performances · articulated claws, wing beats, tails and flippers" if bosses else "16 motion clips per creature · connected joints · continuous movement"
            for i in range(6):
                var kind: String = (["carlo","duke","miguel","blackwater","rana","nessie"] if bosses else ["crab","eel","jelly","puffer","swordfish","shark"])[i]
                var art: Texture2D = null
                if kind=="duke":art=Art.atlas("carlo",0)
                elif kind=="blackwater":art=Art.atlas("shark",0)
                elif kind=="miguel":art=load("res://dist/assets/miguel.webp")
                elif kind=="rana":art=load("res://dist/assets/rana-rex.webp")
                elif kind=="nessie":art=load("res://dist/assets/nessie.webp")
                actors[i].configure(kind,art,Vector2(395,255))
                actors[i].reset_motion()
                cards[i].text=(["CARLO · PINCER DUET","DUKE CLAW · SHELL & LEGS","MIGUEL · WING FLEX","BARON BITE · TAIL & FINS","RANA REX · ARMS & TAIL","NESSIE · FLIPPERS & SPINE"] if bosses else ["CRAB · TWO MOVING JAWS","EEL · FLEXIBLE SWIMMING SPINE","JELLYFISH · PUMP & TRAILING STRANDS","PUFFERFISH · INFLATE & PADDLE","SWORDFISH · TAIL KICK & BANK","SHARK · TWO-JOINT TAIL & FINS"])[i]
        var local := frame%480
        var mode: String = ["patrol","windup","attack","recover"][local/120]
        state_label.text={"patrol":"SWIM / PATROL · INDEPENDENT JOINT BEATS","windup":"ANTICIPATION · GATHER, COIL, FLARE & HOLD","attack":"ATTACK · LAUNCH, STRIKE, FOLLOW THROUGH & BANK","recover":"RECOVERY · BRAKE, RECOIL, SETTLE & REST"}[mode]
        for i in range(6): actors[i].animate(mode,frame/60.0,1.0/60.0,i*.47,false,true,true,(local%120)/60.0)
        await process_frame
        if frame in [60,90,119,180,270,390,540,570,599,660,750,870]:
            await RenderingServer.frame_post_draw
            if root.get_texture().get_image().save_png(out+"/creatures-%03d.png" % frame)!=OK:quit(1);return
    print("LIVING CREATURES NATIVE CAPTURE PASSED")
    quit()

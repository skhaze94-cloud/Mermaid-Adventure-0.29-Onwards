extends "res://godot/tools/pocket_wonders_visual_audit.gd"
func run() -> void:
    Engine.time_scale=0;root.size=Vector2i(1400,960)
    var prefs=root.get_node("AppPreferences")
    prefs.persist_enabled=false;prefs.intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false
    root.get_node("AdventureRun").active=false;root.get_node("AdventureRun").avina_along=true
    var scene=world(1)
    place(scene,1,false)
    scene.pocket_wonders_art.bind(scene,scene.pocket_wonders)
    var model=scene.pocket_wonders
    var record: Dictionary=model.records[1]
    for tick in range(700):model.advance(1.0/60.0)
    assert(record["completed"],"Nori's actual letter encounter completes")
    scene.message_time=0;record["glow_time"]=0.0;record["chat_wait"]=0.0
    model.reactions.clear();model.advance(.1)
    assert(model.hint(record).begins_with("Nori:"),"Nori offers a genuine ambient comment")
    scene._sync_native_visuals()
    await snap(scene,"nori-neighbour-chat")
    views.erase(scene.get_instance_id());await retire(scene)
    print("NEIGHBOUR CAPTURE COMPLETE");quit()

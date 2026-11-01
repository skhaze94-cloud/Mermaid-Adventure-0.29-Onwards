extends SceneTree
var checks:=0
var failures:=0
const HASHES={"queen.pos36": "fa465d775c922482aa9187b1416f8d82281d67310707ac8333f51960194f7701", "queen.bind.json": "989a4b86b452105b64fe286a9536a672e3842fd4067b55cbc79572c2ede7ab4b", "king.pos36": "51cf34d1aa9084034cb2670fe50ea684390d2e53be69b07abe221d6395fb3e0b", "king.skin36": "b68e28d8f1b3db7a6eddbc57a19f18245556c0b5cfdd98480e0cf629aaf1f1e8", "king.bind.json": "93d0ae4cdc35c0df8b52550afbbd605366690ddf69fca632856edff9e86f83c7", "queen.skin36": "1548763cc73468877d05d173e03f2051445dd6c048dba0075156411e747ccbaa"}
func _initialize() -> void:call_deferred("run")
func verify(ok: bool,note: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(note)
func run() -> void:
    root.get_node("AppPreferences").persist_enabled=false
    root.get_node("OceanAudio").playback_enabled=false
    for name in HASHES:
        verify(FileAccess.get_sha256("res://godot/assets/royal-connected36/"+name)==HASHES[name],"Packaged skin/reference bytes differ: "+name)
    for role in ["king","queen"]:
        var actor: Node2D=load("res://godot/family_royal_actor.gd").new();root.add_child(actor);actor.call("configure",role,390)
        await process_frame # flush the previous role queued for replacement
        var skin: RefCounted=actor.get("connected_skin")
        verify(skin.get("binding_valid")==true,"Packaged "+role+" skin binding invalid")
        var bones: Array=actor.find_children("*","Skeleton3D",true,false)
        verify(bones.size()==1 and bones[0].get_bone_count()==(22 if role=="king" else 21),"Packaged bone count")
        var meshes: Array=actor.find_children("*","MeshInstance3D",true,false)
        verify(meshes.size()>0 and meshes.back().skin!=null,"Packaged mesh has no GPU skin")
        actor.free();await process_frame
    print("WINDOWS SKIN INTEGRITY: ",checks," checks, ",failures," failures");quit(1 if failures else 0)

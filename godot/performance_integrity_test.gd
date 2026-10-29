extends SceneTree
## Verify reuse, unchanged detail/paint registration and live UI invalidation.
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error(message)
func run() -> void:
    var rig = load("res://godot/sarah_rig.gd").new()
    root.add_child(rig)
    rig.set_process(false)
    rig.reset_performance()
    rig.face_details.adapt_detail(true)
    var records := {}
    for part in rig.painted_parts:
        if not part is MeshInstance2D: continue
        check(part.mesh.get_surface_count()==1,"Missing indexed painted surface")
        records[part] = [part.mesh,part.topology_builds,hash(part.uv),hash(part.polygons)]
    rig.set_motion(Vector2(310,-70),1,false,false,1)
    for frame in range(120):
        rig._process(1.0/120)
        for part in records:
            var record: Array = records[part]
            check(part.mesh==record[0] and part.topology_builds==record[1],"Animation rebuilds its indexed surface")
            check(hash(part.uv)==record[2] and hash(part.polygons)==record[3],"Animation changes painting or topology")
    var face = rig.face_details
    check(face.custom0.size()==face.rest.size()*4 and face.custom1.size()==face.rest.size()*4,"Static feature attributes are missing")
    var source_size: Vector2 = face.texture.get_size()
    var region: Rect2 = rig.FACE_REGIONS[0]
    for i in range(face.rest.size()):
        var p: Vector2 = (face.uv[i]/source_size*source_size-region.position-Vector2(.5,.5))/(region.size-Vector2.ONE)
        check(absf(face.custom0[i*4+1]-face.feature(p,Vector2(.49,.70),Vector2(.10,.12)))<.000001,"Ear mask changes its painted feature")
        check(absf(face.custom1[i*4]-face.feature(p,Vector2(.82,.685),Vector2(.11,.025)))<.000001,"Lip mask changes its painted feature")
    rig.free()
    var hud = load("res://godot/premium_hud.gd").new()
    root.add_child(hud)
    hud.set_process(false)
    var info := {"score":0,"touch":true,"pad":Vector2.ZERO,"cooldowns":{"boost":0.0},"energy":1.0}
    hud.update_hud(info)
    var updates: int = hud.touch_redraws
    hud.update_hud(info.duplicate(true))
    check(hud.touch_redraws==updates and hud.skipped_redraws>0,"Identical HUD snapshots are rebuilt")
    info=info.duplicate(true);info["progress"]=.5
    hud.update_hud(info)
    check(hud.touch_redraws==updates,"Unrelated progress rebuilds touch geometry")
    info=info.duplicate(true);info["cooldowns"]["boost"]=.5
    hud.update_hud(info)
    check(hud.touch_redraws==updates+1,"Cooldown animation misses a redraw")
    info=info.duplicate(true);info["pad"]=Vector2(.1,.2)
    hud.update_hud(info)
    check(hud.touch_redraws==updates+2,"Joystick animation misses a redraw")
    info=info.duplicate(true);info["energy"]=.1
    hud.update_hud(info)
    check(hud.touch_redraws==updates+3,"Recharge cue misses a redraw")
    info["paused"]=true
    hud.update_hud(info)
    check(not hud.touch_layer.visible and hud.modal.visible,"Reused HUD dictionary misses pause invalidation")
    hud.free()
    print("PERFORMANCE INTEGRITY: %s checks, %s failures" % [checks,failures])
    quit(0 if failures==0 else 1)

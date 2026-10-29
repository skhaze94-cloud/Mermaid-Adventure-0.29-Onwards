extends "res://godot/opal_current_test.gd"
## Exercise released live packets against real enemies, not just balance constants.
func run() -> void:
    root.get_node("AppPreferences").persist_enabled=false
    root.get_node("OceanAudio").playback_enabled=false
    var level=create("res://godot/highland_level.tscn")
    await process_frame
    for i in range(3):
        clean(level)
        var foe=enemy(level,500,4)
        check(level.opal.begin("test"),"tier accepts fresh input")
        level.opal.advance([0.0,0.35,1.35][i])
        root.get_node("OceanAudio").last_played.clear()
        level.opal.release("test")
        check(is_equal_approx(root.get_node("OceanAudio").voices[0].pitch_scale,[1.20,1.0,.82][i]),"live release uses distinct tier pitch")
        var packet: Dictionary=level.bubble_shots[0]
        var start: Vector2=packet["pos"]
        level._update_bubbles(.1)
        check(is_equal_approx(Vector2(packet["pos"]).x-start.x,[70.0,78.0,86.0][i]),"live tier travel speed")
        level._update_bubbles(1)
        check(foe["hp"]==4-[1,2,4][i],"live tier damage reaches target")
        check(foe["hit_cd"]<[.2,.35,.45][i],"ordinary enemy can accept the next recovered shot")
        var points: int=level.score
        level._update_bubbles(1)
        check(level.score==points and level.bubble_shots.is_empty(),"impact cannot duplicate rewards")
        check(is_equal_approx(level.fire_cooldown,[.2,.35,.45][i]),"tier recovery commits only on release")
    clean(level)
    var guard=enemy(level,400,4,"orchid-hermit")
    level.opal.begin("test");level.opal.advance(1.35);level.opal.release("test");level._update_bubbles(1)
    check(guard["hp"]==4 and guard["mode"]=="recover","super opens guard without bypassing armour")
    clean(level)
    level.opal.begin("test");level.opal.advance(.35)
    check(level.opal.prism_chimed and not level.opal.ready_chimed,"Prism has its own readiness state")
    level.opal.advance(1)
    check(level.opal.ready_chimed,"super readiness still latches")
    level.opal.cancel();level.opal.release("test")
    check(level.bubble_shots.is_empty() and level.fire_cooldown==0,"cancelled charge never fires or starts recovery")
    dispose(level)
    print("BUBBLE POLISH: ",checks," checks, ",failures," failures")
    quit(1 if failures else 0)

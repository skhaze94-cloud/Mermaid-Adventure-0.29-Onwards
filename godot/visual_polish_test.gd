extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, why: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error("VISUAL POLISH: "+why)
func run() -> void:
    var prefs = root.get_node("AppPreferences")
    prefs.persist_enabled=false
    prefs.intro_seen=true
    prefs.reduced_motion=true
    prefs.touch_size=1.2
    var catalog = root.get_node("AdventureRun")
    for scene in catalog.SCENES:
        var level = load(scene).instantiate()
        root.add_child(level)
        level.set_process(false);level.set_physics_process(false)
        var hud = level.premium_hud
        for size in [Vector2i(1400,960),Vector2i(960,540),Vector2i(640,360)]:
            root.size=size
            await process_frame
            hud.configure_layout(root.get_visible_rect().size,Vector2(size))
            var snapshot: Dictionary = level._hud_snapshot()
            snapshot["boss_active"]=true
            snapshot["boss_name"]="Nessie · The Crown Thief"
            snapshot["boss_vulnerable"]=true
            snapshot["touch"]=true
            snapshot["combo"]=3
            snapshot["energy"]=.2
            hud.update_hud(snapshot)
            await process_frame
            await process_frame
            check(hud.boss_card.size.y<=90,"Boss panel covers gameplay after a wrapped title")
            check(Rect2(Vector2.ZERO,hud.game_size).encloses(hud.boss_card.get_rect()),"Boss panel leaves safe viewport")
            check(hud.chapter.position.y>hud.combo_meter.position.y+hud.combo_meter.size.y,"Chapter overlaps combo meter")
            for action in ["jump","boost","bubble","pause"]:
                var rect: Rect2 = hud.action_rect(action)
                check(rect.size.x>=44 and rect.size.y>=44,"Action target shrank during cosmetic replacement")
                check(Rect2(Vector2.ZERO,hud.game_size).encloses(rect),"Action control outside safe viewport")
            check(not hud.action_rect("boost").intersects(hud.action_rect("jump")),"Enlarged Boost and Jump controls overlap")
            check(not hud.action_rect("boost").intersects(hud.action_rect("bubble")),"Enlarged Boost and Bubble controls overlap")
            snapshot["paused"]=true
            hud.update_hud(snapshot)
            check(not hud.touch_layer.visible,"Gameplay controls leak over pause")
        level.free()
    print("VISUAL POLISH: %d checks, %d failures" % [checks,failures])
    quit(0 if failures==0 else 1)

extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
    if not ok:
        failures += 1
        push_error(message)
func wait_for_flow(flow: Node) -> void:
    var start := Time.get_ticks_msec()
    while flow.busy and Time.get_ticks_msec()-start < 15000:
        await process_frame
    check(not flow.busy, "transition must complete")
func run() -> void:
    var prefs := root.get_node("AppPreferences")
    prefs.persist_enabled = false
    prefs.intro_seen = true
    var flow := root.get_node("SceneFlow")
    flow.test_animations = true
    change_scene_to_file("res://godot/title_screen.tscn")
    await process_frame
    await process_frame
    check(not flow.go("res://missing-chapter.tscn", "Missing"), "missing chapter rejected before freezing")
    check(not flow.busy, "invalid chapter leaves menu available")
    for gentle in [false, true]:
        prefs.reduced_motion = gentle
        paused = true
        check(flow.go("res://godot/highland_level.tscn", "Highland Gold", "", 0), "valid chapter accepted")
        check(not flow.go("res://godot/title_screen.tscn", "Duplicate"), "repeated press cannot replace transition")
        await wait_for_flow(flow)
        check(current_scene.name == "HighlandGold", "real threaded path loads correct chapter")
        check(not paused and current_scene.process_mode != Node.PROCESS_MODE_DISABLED, "new scene unpaused and active")
        check(flow.cover == 0 and not flow.surface.visible and not flow.card.visible, "transition releases overlay")
        current_scene._set_paused(true)
        current_scene._return_to_menu()
        await wait_for_flow(flow)
        check(current_scene.name == "SarahStorybookOpening" and not paused, "return from pause uses same transition")
    prefs.reduced_motion=false
    check(flow.go("res://godot/highland_level.tscn","Highland Gold","",0),"Interrupted reveal starts")
    var started := Time.get_ticks_msec()
    while (not is_instance_valid(current_scene) or current_scene.name!="HighlandGold") and Time.get_ticks_msec()-started<15000:
        await process_frame
    for tick in range(5): await process_frame
    if is_instance_valid(current_scene): current_scene.free()
    await wait_for_flow(flow)
    check(not flow.surface.visible and not flow.busy,"Removed incoming scene leaves transition overlay")
    change_scene_to_file("res://godot/title_screen.tscn")
    await process_frame
    print("SCENE FLOW TEST " + ("PASSED" if failures == 0 else "FAILED"))
    quit(0 if failures == 0 else 1)

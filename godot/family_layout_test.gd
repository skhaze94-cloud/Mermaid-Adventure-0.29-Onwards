extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, note: String) -> void:
    checks+=1
    if not ok: failures+=1; push_error("FAMILY LAYOUT: "+note)
func frames(count := 6) -> void:
    for i in range(count): await process_frame
func run() -> void:
    root.get_node("AppPreferences").persist_enabled=false
    root.get_node("OceanAudio").playback_enabled=false
    root.content_scale_size=Vector2i(1400,960)
    root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
    change_scene_to_file("res://godot/training_lagoon.tscn"); await frames()
    var level=current_scene; level.set_physics_process(false); level.set_process(false)
    for pixels in [Vector2i(640,360),Vector2i(844,390),Vector2i(1024,768),Vector2i(1920,1080),Vector2i(390,844)]:
        root.size=pixels; await frames()
        level._layout_tutorial(); await frames()
        var view: Vector2=level._ui_view()
        var safe := Rect2(Vector2.ZERO,view)
        level.lesson=6
        level._open_dialogue("gifts"); await frames()
        check(safe.encloses(Rect2(level.dialogue_card.position,level.dialogue_card.size)),str(pixels)+" dialogue stays in safe view")
        check(level.dialogue_scroll.follow_focus,"controller focus scrolls to options")
        level._close_dialogue()
        level.state="victory"; paused=true; level._show_choice(); await frames()
        level._layout_tutorial(); await frames()
        check(safe.encloses(Rect2(level.choice_card.position,level.choice_card.size)),str(pixels)+" companion choice stays in safe view")
        var physical: float=float(pixels.y)/level.get_viewport_rect().size.y*level.tutorial_layer.transform.get_scale().y
        check(level.bring_button.size.y*physical>=43.9,str(pixels)+" minimum touch target")
        level.choice_card.hide(); level.state="playing"; paused=false; level.lesson_card.show(); level.premium_hud.show()
    current_scene.free(); await frames()
    print("FAMILY LAYOUT: ",checks," checks, ",failures," failures")
    quit(1 if failures else 0)

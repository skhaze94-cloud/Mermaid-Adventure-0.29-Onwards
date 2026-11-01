extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func verify(ok: bool,note: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(note)
func frames(n:=3) -> void:
    for i in range(n):await process_frame
func run() -> void:
    root.size=Vector2i(1400,960)
    root.get_node('AppPreferences').persist_enabled=false;root.get_node('AppPreferences').intro_seen=true
    root.get_node('AdventureRun').persist_enabled=false;root.get_node('AdventureRun').active=false
    root.get_node('OceanAudio').playback_enabled=false
    var scene=load('res://godot/training_lagoon.tscn').instantiate();root.add_child(scene);await frames()
    scene.set_process(false);scene.set_physics_process(false);scene.lesson=1;scene.message_time=0
    scene.player=Vector2(700,1400);scene.camera=210;scene.deep_routes.sync(true);scene._sync_native_visuals()
    var art=scene.neighbourhood_art;var model=scene.neighbourhood
    model.quiet=false;model.chat_actor=0;model.chat_left=5.0
    model.chat_line='A little longer story, with a little room to rest your fins. '.repeat(5)
    art.sync();await frames();art.sync()
    var tall: float=art.caption.size.y
    verify(tall>140 and tall<400,'A long neighbour line has a bounded readable panel')
    model.chat_line='Hello, Sarah!';art.sync();await frames();art.sync()
    verify(art.caption.visible,'The short greeting stays visible')
    verify(art.caption.size.y<tall and art.caption.size.y<135,'A short line shrinks the previous long panel')
    verify(art.caption.get_global_rect().end.y<=960,'Caption remains inside the desktop view')
    var hero_box:=Rect2(scene.player-Vector2(scene.camera,scene._camera_y())-Vector2(130,85),Vector2(260,170))
    verify(not art.caption.get_global_rect().intersects(hero_box),'Caption leaves Sarah’s body clear')
    root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(844,390)
    await frames();scene.simulated_touch=true;scene._on_viewport_resized();scene._layout_tutorial();scene.deep_routes.sync(true);scene._sync_native_visuals()
    model.chat_line='I made a little quiet corner. Come and rest your fins, Sarah.'
    art.sync();await frames();art.sync()
    verify(art.caption.visible,'Phone neighbour greeting remains visible')
    verify(art.caption.size.y<180,'Phone caption uses its actual wrap height')
    verify(scene.talk_king.custom_minimum_size.y>=60,'Touch help retains the larger target')
    scene.free();await frames();print('TUTORIAL CAPTION REGRESSION: ',checks,' checks, ',failures,' failures');quit(1 if failures else 0)

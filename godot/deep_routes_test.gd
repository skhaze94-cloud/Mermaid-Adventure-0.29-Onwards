extends "res://godot/pocket_wonders_test.gd"
const Deep=preload("res://godot/deep_routes_data.gd")
var visited:=0
var deepest:=0.0
func run() -> void:
    root.size=Vector2i(1400,960)
    root.get_node("AppPreferences").persist_enabled=false;root.get_node("OceanAudio").playback_enabled=false
    root.get_node("AppPreferences").intro_seen=true
    var catalog=root.get_node("AdventureRun");catalog.active=false;catalog.avina_along=true
    for chapter in [7,0,1,2]:
        var scene=await create(chapter)
        check(is_instance_valid(scene.deep_routes),"expanded chapter has its real vertical camera")
        check(scene._swim_bounds().end.y>2100,"playable bounds extend below the old seabed")
        var original_portal: float=scene._portal_x();var original_boss: int=scene.boss_hp
        var list:=Deep.rooms(chapter)
        check(scene.deep_routes.water_shapes.size()==list.size(),"every collision layout has a painted connected outline")
        for index in range(list.size()):
            var room: Dictionary=list[index]
            if chapter==0:scene.fallen=index>0
            place(scene,room["waypoints"][0]);scene.deep_routes.sync(true)
            for target in room["waypoints"]:
                var margin: float=scene.HERO_RADIUS*.73
                check(not scene.RockCollision.blocked(target,scene.obstacles,margin),"route anchor clears actual collision: "+room["key"]+" "+str(target))
                check(await swim_to(scene,target),"real controls reach downward/return waypoint: "+room["key"]+" "+str(target))
                if target.distance_to(room["chest"])<59:
                    var chest_id: String=String(room["key"])+":chest"
                    check(scene.score_book.seen.has(chest_id) and scene.checkpoint_position.y>900,"first cavern chest banks a genuine deep berth")
                deepest=maxf(deepest,scene.player.y)
                check(not scene.RockCollision.blocked(scene.player,scene.obstacles,margin),"swimming stays outside cave walls")
                scene.deep_routes.sync()
                if scene.player.y>1200:
                    check(scene.deep_routes.camera_y>400,"camera follows the actual descent")
                    var shown_y: float=scene.player.y-scene.deep_routes.camera_y
                    check(shown_y>140 and shown_y<900,"Sarah remains on screen in the lower rooms")
            # A second upper path loops above the central reef; the main lower
            # path already returned to daylight using a different shaft.
            place(scene,room["upper_route"][0])
            for target in room["upper_route"]:check(await swim_to(scene,target),"upper gallery is navigable: "+room["key"])
            place(scene,room["chest"])
            scene._update_collectibles();scene.deep_routes.sync(true)
            scene._save_checkpoint()
            var id: String=String(room["key"])+":chest"
            check(scene.score_book.seen.has(id),"optional chest has stable owned reward")
            var earned: int=scene.score
            check(scene._valid_checkpoint(scene._checkpoint_bundle()),"deep checkpoint validates")
            var berth: Vector2=scene.checkpoint_position
            scene._respawn();scene._update_collectibles()
            check(scene.score==earned and scene.score_book.seen.has(id),"retry cannot farm the cavern chest")
            check(scene.player.distance_to(berth)<2 and scene.player.y>900,"retry restores the actual underground berth")
            check(scene._portal_x()==original_portal and scene.boss_hp==original_boss,"side route does not bypass boss or move original exit")
            visited+=1
        # Old checkpoints omit cavern items. Merge appends the additions without
        # changing existing pickup indices or duplicating a stable cavern ID.
        var legacy: Array[Dictionary]=scene._stage_treasure()
        var count:=legacy.size();Deep.merge_treasures(legacy,chapter)
        var merged:=legacy.size();Deep.merge_treasures(legacy,chapter)
        check(merged>count and legacy.size()==merged,"legacy treasures merge once and retain original order")
        await dispose(scene)
    var other=await create(3)
    check(is_instance_valid(other.deep_routes) and other._world_bottom()==Deep.BOTTOM,"Whimsy Four adds an optional later-chapter tunnel")
    await dispose(other)
    await deep_continue_checks()
    print("DEEP ROUTES: ",checks," checks, ",failures," failures; ",visited," complete cavern loops; deepest ",deepest,"; swim ticks ",swim_ticks)
    quit(1 if failures else 0)

func deep_continue_checks() -> void:
    var catalog=root.get_node("AdventureRun");var prefs=root.get_node("AppPreferences")
    var original_path: String=catalog.storage_path
    var original_persist: bool=catalog.persist_enabled;var original_prefs: bool=prefs.persist_enabled
    var path:="user://deep-routes-continue.json"
    catalog.flush_saves();catalog.storage_path=path;catalog.persist_enabled=true;prefs.persist_enabled=true
    catalog.last_written.clear();catalog.last_queued.clear();catalog.resume_state.clear();catalog.begin(1)
    var scene=await create(1);var room: Dictionary=Deep.rooms(1)[0]
    place(scene,room["chest"]);scene._update_collectibles();scene.deep_routes.sync(true)
    var earned: int=scene.score;var berth: Vector2=scene.checkpoint_position
    var id: String=String(room["key"])+":chest"
    await frames();catalog.flush_saves()
    var saved: Dictionary=Store.read(path)["state"]
    check(not saved.is_empty() and saved["checkpoint"]["position"].y>900,"native worker stores the deep checkpoint")
    await dispose(scene);catalog.begin(0);catalog.resume_state.clear()
    check(catalog.load_progress() and catalog.has_resume(),"deep save is offered to Continue")
    change_scene_to_file("res://godot/title_screen.tscn");await frames(6)
    current_scene.primary.pressed.emit()
    for i in range(120):
        await process_frame
        if current_scene and current_scene.has_method("_stage_index") and current_scene._stage_index()==1:break
    await frames(3);scene=current_scene
    var restored: bool=scene!=null and scene.has_method("_stage_index") and scene._stage_index()==1
    check(restored,"actual title Continue opens the expanded chapter")
    if restored:
        scene.set_process(false);scene.set_physics_process(false)
        check(scene.player.distance_to(berth)<3 and scene.player.y>900,"Continue restores the actual underground position")
        check(scene.deep_routes.camera_y>500,"Continue opens with the vertical camera already at depth")
        check(scene.score==earned and scene.score_book.seen.has(id),"Continue preserves exact cavern reward ownership")
        scene._update_collectibles()
        check(scene.score==earned,"Continue cannot farm a second chest reward")
        current_scene=null;await dispose(scene)
    catalog.flush_saves();catalog.storage_path=original_path;catalog.persist_enabled=original_persist;prefs.persist_enabled=original_prefs
    for suffix in ["", ".bak", ".tmp"]:
        if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)

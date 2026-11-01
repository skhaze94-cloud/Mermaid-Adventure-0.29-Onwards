extends "res://godot/pocket_wonders_test.gd"
const District=preload("res://godot/whimsy_four_data.gd")
const Deep=preload("res://godot/deep_routes_data.gd")
var new_people:=0
var new_rooms:=0
func run() -> void:
    root.get_node("AppPreferences").persist_enabled=false;root.get_node("AppPreferences").intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false
    var ids: Dictionary={}
    for chapter in [7,0,1,2,3,4,5,6]:
        var scene=await create(chapter)
        scene.message_time=0
        if chapter==7:scene.dialogue_shade.hide()
        var model=scene.neighbourhood;var art=scene.neighbourhood_art
        var profile: Dictionary=model.profile;var room: Dictionary=profile["room"]
        if chapter==6:scene.boss_hp=0
        if chapter==0:scene.fallen=false
        check(profile["people"].size()==art.actors.size() and art.textures_loaded==profile["people"].size(),"the chapter resident paintings load once")
        check(room["perches"].size()==2,"each home has two real solid perches")
        for perch in room["perches"]:check(perch in scene.obstacles,"painted perch uses actual collision")
        var route: Array=room["waypoints"]
        place(scene,route[0])
        for at in route:
            check(not scene.RockCollision.blocked(at,scene.obstacles,scene.HERO_RADIUS*.73),"neighbour platforms leave route anchors clear")
            check(await swim_to(scene,at),"actual controls complete the neighbourhood tunnel loop")
        for person in profile["people"]:
            if chapter==0:scene.fallen=int(person.get("room_index",0))>0
            check(not ids.has(person["id"]),"sixteen distinct identities")
            ids[person["id"]]=true;new_people+=1
            var at: Vector2=person["talk_at"]-Vector2(0,48)
            check(not scene.RockCollision.blocked(at,scene.obstacles,scene.HERO_RADIUS*.73),"greeting point clears its platform")
            place(scene,at);scene.message_time=0
            var before: int=scene.score
            for tick in range(110):step(scene)
            check(scene.score_book.seen.has("friends-cavern:%s:%s" % [chapter,person["id"]]),"saved hello for "+String(person["id"]))
            check(model.chat_line!="","resident has its own local greeting")
        check(model.completed and scene.score_book.seen.has(profile["id"]),"both greetings bank one welcome reward")
        var earned: int=scene.score;var saved: Dictionary=model.export_state()
        check(model.valid_state(saved,scene.score_book.seen),"district save owns its reward")
        check(not model.valid_state({"version":1,"visited":[profile["people"][0]["id"],profile["people"][0]["id"]],"completed":true},scene.score_book.seen),"duplicate resident IDs are rejected")
        check(not model.valid_state({"version":1,"visited":["invented"],"completed":false}),"foreign resident IDs are rejected")
        var snap: Dictionary=scene._checkpoint_bundle();check(scene._valid_checkpoint(snap),"host accepts native deep greeting checkpoint")
        scene._respawn();scene.message_time=0
        check(model.completed and model.visited.size()==2 and scene.score==earned,"retry retains both friends and exact reward")
        for tick in range(200):step(scene)
        check(scene.score==earned,"remaining nearby cannot farm welcome points")
        var count: int=art.get_child_count();var phase: float=model.clock
        scene._set_paused(true);model.advance(.2);art.sync()
        check(model.clock==phase and not art.caption.visible,"pause stops performances and hides speech")
        scene._set_paused(false);scene.message_time=0;place(scene,profile["people"][0]["talk_at"]-Vector2(0,48))
        model._speak(0,"A private hello.");scene._say("Gameplay has priority",3,true);model.advance(.02);art.sync()
        check(model.chat_actor<0 and not art.caption.visible,"gameplay speech suppresses optional neighbourhood chatter")
        scene.message_time=0;scene.reduced_fx=true;phase=model.clock;model.advance(.2);art.sync()
        check(model.clock==phase and art.actors.all(func(actor):return actor.rotation==0),"Gentle Motion retains static painted company")
        scene.reduced_fx=false;scene.high_depth_quality=false
        for tick in range(30):model.advance(.016);art.sync()
        check(art.get_child_count()==count and art.textures_loaded==profile["people"].size(),"Economy uses a bounded scene and no repeated texture loads")
        if chapter>=3 and chapter<=6:new_rooms+=1
        await dispose(scene)
    await continue_check()
    check(ids.size()==22 and new_rooms==4,"twenty-two residents and four later tunnel loops")
    print("WHIMSY FOUR: ",checks," checks, ",failures," failures; ",new_people," residents, ",new_rooms," new loops")
    quit(1 if failures else 0)
func continue_check() -> void:
    var catalog=root.get_node("AdventureRun");var prefs=root.get_node("AppPreferences")
    var original: String=catalog.storage_path
    var path:="user://whimsy-four-continue.json"
    catalog.flush_saves();catalog.storage_path=path;catalog.persist_enabled=true;prefs.persist_enabled=true
    catalog.last_written.clear();catalog.last_queued.clear();catalog.resume_state.clear();catalog.begin(4)
    var scene=await create(4);var model=scene.neighbourhood
    for person in model.profile["people"]:
        place(scene,person["talk_at"]-Vector2(0,48));scene.message_time=0
        for tick in range(115):step(scene)
    var earned: int=scene.score;var berth: Vector2=scene.checkpoint_position
    await frames();catalog.flush_saves()
    check(not Store.read(path)["state"].is_empty(),"native save worker writes neighbourhood memory")
    await dispose(scene);catalog.begin(0);catalog.resume_state.clear()
    check(catalog.load_progress() and catalog.has_resume(),"neighbourhood save offers Continue")
    change_scene_to_file("res://godot/title_screen.tscn");await frames(6)
    current_scene.primary.pressed.emit()
    for i in range(120):
        await process_frame
        if current_scene and current_scene.has_method("_stage_index") and current_scene._stage_index()==4:break
    await frames(3);scene=current_scene
    var restored: bool=scene!=null and scene.has_method("_stage_index") and scene._stage_index()==4
    check(restored,"title Continue opens the new tea tunnel")
    if restored:
        scene.set_process(false);scene.set_physics_process(false)
        check(scene.neighbourhood.completed and scene.neighbourhood.visited.size()==2,"both residents remember Sarah after reopening")
        check(scene.score==earned and scene.player.distance_to(berth)<3 and scene.player.y>900,"Continue preserves exact welcome reward and deep berth")
        current_scene=null;await dispose(scene)
    catalog.flush_saves();catalog.storage_path=original;catalog.persist_enabled=false;prefs.persist_enabled=false
    for suffix in ["", ".bak", ".tmp"]:
        if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)

extends "res://godot/pocket_wonders_test.gd"
func run() -> void:
    root.get_node("AppPreferences").persist_enabled=false;root.get_node("AppPreferences").reduced_motion=false;root.get_node("OceanAudio").playback_enabled=false;root.get_node("AdventureRun").active=false
    var scene=await create(7);scene._close_dialogue();scene.set_process(false);scene.set_physics_process(false);scene.message_time=0;scene.player=Vector2(300,650);scene.player_velocity=Vector2.ZERO
    scene.enemies.clear();scene.animated_enemies.bind_enemies(scene.enemies);scene.pocket_wonders.reactions.clear();scene.living_reef.reactions.clear()
    var Deep=load("res://godot/deep_routes_data.gd");var rooms=Deep.rooms(7)
    check(rooms.size()==2 and rooms[0]["w"]>=1200,"two tutorial loops retained with a more spacious nursery")
    check(Deep.apertures(7)[0].size.x>=320,"tutorial entrances are wider")
    var model=scene.neighbourhood;model.clear_transients();model.quiet=false
    var a: Dictionary=model.profile["people"][0];var b: Dictionary=model.profile["people"][1]
    check(a["foot"].distance_to(b["foot"])>800,"residents have separate ledges and breathing room")
    var start: Vector2=a["foot"]
    for i in range(600):model.advance(1.0/60)
    check(a["foot"].distance_to(start)>5 and a["foot"].distance_to(start)<40,"Mallow takes a bounded stroll using existing scene time")
    scene.player=a["talk_at"]+Vector2(160,-30);start=a["foot"]
    for i in range(120):model.advance(1.0/60)
    check(a["foot"]==start,"resident stops to converse with nearby Sarah")
    model._speak(0,a["lines"][0]);model.chat_left=.001;model.advance(.01)
    check(model.sarah_reply and model.chat_line.begins_with("A tiny stroll"),"Sarah answers the resident through the existing caption owner")
    paused=true;start=a["foot"];model.advance(1)
    check(a["foot"]==start and model.reply_pending=="","pause freezes strolling and clears stale replies")
    paused=false;scene.reduced_fx=true;start=a["foot"];scene.player=Vector2(300,650)
    for i in range(120):model.advance(1.0/60)
    check(a["foot"]==start,"Gentle Motion disables roaming")
    scene.reduced_fx=false;scene._sync_native_visuals()
    check(scene.king.size.y>=390 and scene.queen_teacher.size.y>=410,"both tutorial parents are substantially larger")
    check(scene.king.tutorial_life and scene.queen_teacher.tutorial_life,"tutorial parents opt into articulated life without changing other scenes")
    check(scene.little_moments.keeper_point.x>rooms[0]["body"].end.x,"Dozy has his own Bellflower home")
    var rock=load("res://godot/rock_collision.gd")
    var old_chest:=Vector2(880,1760)
    var recovered: Vector2=rock.recover(old_chest,scene.obstacles,scene.HERO_RADIUS*.73,scene._swim_bounds())
    check(not rock.blocked(recovered,scene.obstacles,scene.HERO_RADIUS*.73),"an old underground berth recovers safely into the revised tutorial")
    check(rooms[0]["key"]=="cavern:7:nursery" and model.profile["id"]=="whimsy-four:7","save and reward identities remain stable")
    var legacy: Array[Dictionary]=[{"x":880.0,"y":1760.0,"kind":"chest","taken":false,"phase":0.0,"deep_id":"cavern:7:nursery:chest"},{"x":580.0,"y":920.0,"kind":"pearl","taken":true,"phase":0.0,"deep_id":"cavern:7:nursery:pearl:0"}]
    var seen: Dictionary={"cavern:7:nursery:pearl:0":true,"cavern:7:nursery:chest":true}
    Deep.merge_treasures(legacy,7,seen)
    check(legacy.size()==2 and legacy[0]["taken"] and legacy[0]["x"]==rooms[0]["chest"].x,"legacy chests migrate to their new berth without granting rewards twice")
    check(seen.has("cavern:7:nursery:pearl:0"),"retiring old pearl rows preserves the earned ledger")
    await dispose(scene)
    print("TUTORIAL OVERHAUL: ",checks," checks, ",failures," failures");quit(1 if failures else 0)

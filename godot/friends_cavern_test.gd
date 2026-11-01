extends "res://godot/pocket_wonders_test.gd"
var friends:=0
var rooms:=0
func run() -> void:
    root.size=Vector2i(1400,960)
    root.get_node('AppPreferences').persist_enabled=false;root.get_node('AppPreferences').intro_seen=true
    root.get_node('AdventureRun').persist_enabled=false;root.get_node('AdventureRun').active=false
    root.get_node('OceanAudio').playback_enabled=false
    var identities: Dictionary={}
    for chapter in [7,0,1,2,3,4,5,6]:
        var scene=await create(chapter);scene.message_time=0
        var model=scene.neighbourhood
        for index in range(scene.deep_routes.profiles.size()):
            var room: Dictionary=scene.deep_routes.profiles[index];rooms+=1
            var residents:=0
            for person in model.profile['people']:
                if int(person['room_index'])==index:residents+=1
            if chapter==7 and room['id']=='bellflower':residents+=1
            check(residents>0,'Every cavern has company: '+String(room['id']))
            check(not Geometry2D.triangulate_polygon(scene.deep_routes.water_shapes[index]).is_empty(),'Cavern outline triangulates: '+String(room['id']))
            check(scene.deep_routes.water_meshes[index].get_surface_count()==1,'Cavern GPU geometry is cached once')
            if chapter==0:scene.fallen=index>0
            for target in room['waypoints']:
                check(not scene.RockCollision.blocked(target,scene.obstacles,scene.HERO_RADIUS*.73),'Return route clears the actual ledges')
        for index in range(model.profile['people'].size()):
            var person: Dictionary=model.profile['people'][index]
            var key: String=model.friend_key(index)
            check(not identities.has(person['id']),'Every resident identity is distinct');identities[person['id']]=true;friends+=1
            if chapter==0:scene.fallen=int(person['room_index'])>0
            check(not scene.RockCollision.blocked(person['talk_at'],scene.obstacles,scene.HERO_RADIUS*.73),'Sarah can reach '+String(person['name']))
            place(scene,person['talk_at']);scene.message_time=0;model.clear_transients()
            scene.living_reef.reactions.clear();scene.pocket_wonders.reactions.clear()
            var before: int=scene.score;var was_complete: bool=model.completed
            for tick in range(18):model.advance(.1)
            check(scene.score_book.seen.has(key),'A calm real greeting awards '+String(person['name']))
            var expected:=50+(120 if not was_complete and model.completed else 0)
            check(scene.score==before+expected,'Exactly 50 friend points; the original pair bonus stays separate')
            check(model.chat_actor==index and not model.chat_line.is_empty() and not model.reply_pending.is_empty(),'Friend speaks and Sarah has a local reply')
            check(scene.checkpoint_snapshot['ledger']['seen'].has(key),'Hello and reward are saved together')
            check(scene._valid_checkpoint(scene._checkpoint_bundle()),'New friend keeps the established checkpoint schema valid')
            var earned: int=scene.score
            for tick in range(120):model.advance(.1)
            check(scene.score==earned,'Waiting cannot farm friend points')
            scene._respawn();scene.message_time=0;place(scene,person['talk_at'])
            for tick in range(25):model.advance(.1)
            check(scene.score==earned and scene.score_book.seen.has(key),'Retry remembers the exact friend reward')
        if chapter==7:
            var point: Vector2=scene.little_moments.keeper_point-Vector2(0,50)
            place(scene,point);scene.message_time=0;scene.deep_routes.sync(true);scene.little_moments.sync()
            for tick in range(20):scene.little_moments.advance(.1)
            check(scene.score_book.seen.has('friends-cavern:7:dozy'),'Dozy also gives a saved 50-point hello')
            check(scene.little_moments.speech_key=='lantern','Dozy retains the existing lantern conversation')
            scene.little_moments.sync();await frames(3);scene.little_moments.sync()
            check(scene.little_moments.message_box.visible,'Dozy greeting remains visible after native caption layout')
            var body:=Rect2(scene.player-Vector2(scene.camera,0)-Vector2(130,90),Vector2(260,180))
            var caption:=Rect2(scene.little_moments.message_box.position,scene.little_moments.message_box.size*scene.little_moments.message_box.scale)
            var speaker:=Rect2(scene.little_moments.dozy.position-Vector2(70,130),Vector2(140,130))
            check(not caption.intersects(body) and not caption.intersects(speaker),'Dozy caption leaves Sarah and its moving speaker clear')
            friends+=1
        var count: int=scene.neighbourhood_art.actors.size();var phase: float=model.clock;var score: int=scene.score
        scene._set_paused(true);model.advance(.5);scene.neighbourhood_art.sync()
        check(model.clock==phase and scene.score==score and not scene.neighbourhood_art.caption.visible,'Pause freezes greetings, points and captions')
        scene._set_paused(false);scene.message_time=0
        scene.reduced_fx=true;model.advance(.5);scene.neighbourhood_art.sync()
        check(model.clock==phase and scene.neighbourhood_art.actors.size()==count,'Gentle Motion retains the cast without advancing motion')
        await dispose(scene)
    await legacy_check()
    check(rooms==15 and friends==23,'All fifteen caverns and twenty-three named friends are covered')
    print('FRIENDS CAVERN: ',checks,' checks, ',failures,' failures; ',rooms,' caverns, ',friends,' friends')
    quit(1 if failures else 0)
func legacy_check() -> void:
    var scene=await create(0);scene.fallen=false;scene.message_time=0
    var model=scene.neighbourhood;var ids: Array=[]
    for i in range(2):ids.append(model.profile['people'][i]['id'])
    var old: Dictionary={'version':1,'visited':ids,'completed':true}
    scene.score_book=scene.ScoreBook.new();scene.score=0
    scene._award(model.profile['id'],'Secrets',120,Vector2(1500,1400),false)
    check(model.valid_state(old,scene.score_book.seen),'A v0.33 completed neighbourhood save is accepted without new friend keys')
    model.restore_state(old)
    var before: int=scene.score;place(scene,model.profile['people'][0]['talk_at']);scene.message_time=0
    for tick in range(18):model.advance(.1)
    check(scene.score==before+50 and model.completed,'An old friend gains the new hello once and keeps the old welcome bonus')
    var earned: int=scene.score;scene._respawn();scene.message_time=0
    for tick in range(50):model.advance(.1)
    check(scene.score==earned,'Migrated hello cannot be collected twice')
    await dispose(scene)

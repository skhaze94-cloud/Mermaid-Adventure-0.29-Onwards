extends SceneTree
## Integrated, real-controller visits. Art-only pantomime never casts a combat shot.
const Store=preload("res://godot/progress_store.gd")
const Baby=preload("res://godot/avina_companion.gd")
var checks:=0
var failures:=0
var swim_ticks:=0
var kinds: Dictionary={}
func _initialize() -> void:call_deferred("run")
func check(ok: bool,note: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error("POCKET WONDERS: "+note)
func frames(count:=3) -> void:
    for i in range(count):await process_frame
func create(index: int,ready_story:=true):
    var scene=load(root.get_node("AdventureRun").SCENES[index]).instantiate();root.add_child(scene)
    scene.set_process(false);scene.set_physics_process(false);await frames()
    scene.fallen=true;scene.invulnerable=10000;scene.checkpoint=maxf(scene.checkpoint,scene._left_bound())
    for enemy in scene.enemies:enemy["hp"]=0
    scene.native_rig.reset_performance()
    if index==6 and ready_story:scene.boss_hp=0
    if index==7:
        if ready_story:scene.lesson=10;scene.boss_hp=0
        scene.dialogue_open=false;scene.lesson_card.hide();scene.dialogue_card.hide();scene.choice_card.hide()
    paused=false
    return scene
func dispose(scene) -> void:
    paused=false;scene.free();await frames()
func place(scene,at: Vector2) -> void:
    scene.touch_vectors.clear();scene.player_velocity=Vector2.ZERO;scene.boost_time=0
    scene.player=scene.RockCollision.recover(at,scene.obstacles,scene.HERO_RADIUS*.73,scene._swim_bounds())
    scene.camera=maxf(0,scene.player.x-530);scene.native_rig.reset_performance()
    if is_instance_valid(scene.avina):scene.avina.reset_follow();scene.avina.tick(0)
func step(scene,dt:=1.0/60.0) -> void:
    scene.invulnerable=10000;scene._physics_process(dt);swim_ticks+=1
    scene.camera=maxf(0,scene.player.x-530)
    # These are the native host's performance inputs. Advance authored gestures
    # explicitly because the fixture deliberately freezes automatic processing.
    scene.native_rig.set_motion(scene.player_velocity,scene.facing,scene.boost_time>0,scene.leap_phase!="",1)
    if scene.native_rig.gesture_player.is_playing():scene.native_rig.gesture_player.advance(dt)
    if is_instance_valid(scene.avina):scene.avina.tick(dt)
func swim_to(scene,at: Vector2) -> bool:
    for tick in range(300):
        var delta: Vector2=at-scene.player
        scene.touch_vectors[91]=delta.normalized()*minf(1,delta.length()/40.0)
        step(scene)
        if delta.length()<24:
            scene.touch_vectors.clear()
            return true
    scene.touch_vectors.clear();return false
func settle(scene,seconds: float) -> void:
    scene.touch_vectors.clear()
    for tick in range(ceili(seconds*60)):step(scene)
func await_complete(scene,record: Dictionary,seconds:=25.0) -> bool:
    for tick in range(ceili(seconds*60)):
        step(scene)
        if record["completed"]:return true
    return false
func visit(scene,index: int,misbehave:=true) -> void:
    var model=scene.pocket_wonders;var record: Dictionary=model.records[index]
    var at: Vector2=record["profile"]["at"]
    place(scene,at-Vector2(300,0));step(scene)
    check(record["discovered"],"approach discovers "+String(record["profile"]["id"]))
    if record["profile"]["kind"]=="village" and misbehave:
        scene.touch_vectors[91]=Vector2.RIGHT;scene.energy=1;scene.boost_cooldown=0
        scene._boost();step(scene)
        check(float(record["gag_time"])>0 and int(record["phase"])==4,"real Boost makes neighbours rescue their laundry")
        scene.touch_vectors.clear()
        for tick in range(30):step(scene)
        check(await swim_to(scene,at),"real swimming returns beside the village")
        for tick in range(360):
            if int(record["phase"])==5:break
            step(scene)
        check(int(record["phase"])==5,"the washing returns gently after the Boost gag")
    else:check(await swim_to(scene,at),"real swimming reaches the wonder")
    scene.touch_vectors.clear()

func run() -> void:
    root.size=Vector2i(1400,960)
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false
    var catalog=root.get_node("AdventureRun");catalog.active=false;catalog.avina_along=false
    var bindings: Array=InputMap.get_actions()
    var ids: Dictionary={}
    for chapter in range(8):
        var scene=await create(chapter);var model=scene.pocket_wonders
        check(model.records.size()==2,"exactly two bounded authored pockets in chapter "+str(chapter))
        for index in range(model.records.size()):
            var record: Dictionary=model.records[index];var profile: Dictionary=record["profile"]
            check(not ids.has(profile["id"]),"each of sixteen wonders has a stable unique ID")
            ids[profile["id"]]=true;kinds[profile["kind"]]=true
            check(not scene.RockCollision.blocked(profile["at"],scene.obstacles,64),"interaction anchor clears the actual reef")
            var previous_boss: int=scene.boss_hp;var previous_bubble: bool=scene.bubble_unlocked
            var previous_portal: float=scene._portal_x()
            var previous_secrets: int=scene.score_book.categories.get("Secrets",0)
            await visit(scene,index)
            check(await_complete(scene,record),"real input and idle time complete "+String(profile["kind"]))
            check(scene.state=="playing" and not paused,"a wonder never pauses or captures the game")
            check(scene.score_book.seen.has(profile["id"]),"completed wonder owns its reward")
            check(int(scene.score_book.categories.get("Secrets",0))==previous_secrets+int(profile["reward"]),"only the authored Secrets bonus is awarded")
            check(scene.checkpoint_snapshot["wonders"]["memories"][index]["completed"],"completion and reward are banked together")
            check(scene._valid_checkpoint(scene._checkpoint_bundle()),"completed checkpoint validates with owned memories")
            check(scene.boss_hp==previous_boss and scene.bubble_unlocked==previous_bubble and scene._portal_x()==previous_portal,"optional play leaves boss, unlock and portal rules alone")
            check(scene.bubble_shots.is_empty() and scene.hostile_shots.is_empty(),"decorative wonder bubbles never become projectiles")
            var score_before: int=scene.score;var count_before: int=model.completed_count
            for tick in range(6):model.advance(.1)
            check(scene.score==score_before and model.completed_count==count_before,"remaining nearby cannot repeat the reward")
            scene._respawn()
            check(record["completed"] and scene.score_book.seen.has(profile["id"]) and scene.score==score_before,"retry keeps remembered wonder and ledger")
            check(int(record["phase"])==0 and model.note_queue.is_empty() and not model.reactions.active,"retry clears only transient pantomime and audio")
        check(not is_instance_valid(scene.avina) and not catalog.avina_along,"solo chapter fixtures never force the companion choice")
        await dispose(scene)
    check(ids.size()==16 and kinds.size()==5,"all sixteen stations and all five interaction types are exercised")
    check(InputMap.get_actions()==bindings and root.get_node("OceanAudio").voices.size()==10,"controls and bounded sound voices retain their original contracts")
    await context_checks()
    await memory_checks()
    await partner_checks()
    await neighbour_checks()
    await continuation_checks()
    print("POCKET WONDERS: ",checks," checks, ",failures," failures; ",swim_ticks," real swim ticks")
    quit(1 if failures else 0)

func neighbour_checks() -> void:
    var scene=await create(1);var model=scene.pocket_wonders
    var record: Dictionary=model.records[1]
    await visit(scene,1)
    check(await_complete(scene,record),"Nori shares his first letter")
    var earned: int=scene.score
    settle(scene,10.0)
    check(float(record["chat_left"])>0 and model.hint(record).begins_with("Nori:"),"Nori stays to chat after his letter is remembered")
    check(scene.score==earned and scene.bubble_shots.is_empty(),"neighbour chat grants no repeated reward or attack")
    scene.opal.charge.held=true;record["chat_wait"]=0.0;record["chat_left"]=0.0
    model.advance(.1)
    check(float(record["chat_left"])==0,"Nori yields when Sarah is charging a bubble")
    scene.opal.cancel();scene.message_time=3.0
    model.advance(.1)
    check(float(record["chat_left"])==0,"Nori yields to existing gameplay speech")
    scene.message_time=0.0;scene.player_velocity=Vector2.ZERO
    model.advance(.1)
    check(float(record["chat_left"])>0,"another small greeting is available after the conversation clears")
    model.clear_transients()
    check(float(record["chat_left"])==0 and record["completed"],"retry clears chatter while keeping Nori's letter")
    await dispose(scene)

func context_checks() -> void:
    for chapter in [6,7]:
        var scene=await create(chapter,false);var model=scene.pocket_wonders
        place(scene,model.records[0]["profile"]["at"]);model.advance(.2)
        check(not model.records[0]["discovered"] and not model.eligible(model.records[0]),"finale and tutorial wonders respect their story gates")
        await dispose(scene)
    var family=await create(7);var family_record: Dictionary=family.pocket_wonders.records[0]
    place(family,family_record["profile"]["at"]);step(family);settle(family,.4)
    var family_elapsed: float=family_record["elapsed"]
    family.dialogue_open=true;family.pocket_wonders.advance(.5)
    check(float(family_record["elapsed"])==family_elapsed and family.pocket_wonders.quiet(),"family conversation keeps priority over a nearby tea party")
    family.dialogue_open=false;family.playing_daddy=true;family.pocket_wonders.advance(.5)
    check(float(family_record["elapsed"])==family_elapsed and family.pocket_wonders.quiet(),"playing Daddy cannot accidentally advance Sarah’s wonder")
    family.playing_daddy=false;await dispose(family)
    var scene=await create(0);var model=scene.pocket_wonders;var record: Dictionary=model.records[1]
    place(scene,record["profile"]["at"]);step(scene);settle(scene,.6)
    check(record["state"]=="playing" and float(record["elapsed"])>0,"tea starts through relaxed presence")
    var elapsed: float=record["elapsed"]
    scene._set_paused(true);scene._process(.2);model.advance(.5)
    check(float(record["elapsed"])==elapsed and not model.reactions.active,"pause freezes the cup and clears owned expressions")
    scene._set_paused(false)
    scene.waterfall_phase="descent";model.advance(.5)
    check(float(record["elapsed"])==elapsed,"waterfall travel cannot advance a wonder")
    scene.waterfall_phase="";root.get_node("SceneFlow").busy=true;model.advance(.5)
    check(float(record["elapsed"])==elapsed,"scene loading freezes the encounter")
    root.get_node("SceneFlow").busy=false
    var enemy: Dictionary=scene.enemies[0];var prior: Dictionary=enemy.duplicate(true)
    enemy["hp"]=1;enemy["x"]=scene.player.x+100;enemy["y"]=scene.player.y;enemy["mode"]="attack"
    model.advance(.5)
    check(float(record["elapsed"])==elapsed and model.quiet(),"nearby real enemy attack quiets the tea party")
    enemy.clear();enemy.merge(prior)
    var position_before: Vector2=scene.player
    scene.touch_vectors[91]=Vector2.RIGHT
    for tick in range(8):step(scene)
    check(scene.player.x>position_before.x and float(record["elapsed"])==elapsed,"existing movement remains responsive and politely suspends pouring")
    scene.touch_vectors.clear()
    place(scene,record["profile"]["at"]+Vector2(850,0));model.advance(.1)
    check(record["state"]=="invited" and float(record["elapsed"])==0 and not record["completed"],"leaving an unfinished party resets its transient performance without failure")
    place(scene,record["profile"]["at"]);scene.reduced_fx=true;scene.native_rig.reduced_motion=true
    check(await_complete(scene,record),"Gentle Motion retains the complete tea activity")
    var earned: int=scene.score;var ledger: Dictionary=scene.score_book.checkpoint()
    place(scene,record["profile"]["at"]+Vector2(850,0));model.advance(20)
    place(scene,record["profile"]["at"])
    for tick in range(700):step(scene)
    check(record["completed"] and scene.score==earned and scene.score_book.checkpoint()==ledger,"a full decorative replay cannot farm a second reward")
    await dispose(scene)

func memory_checks() -> void:
    var scene=await create(0);var model=scene.pocket_wonders
    var original: Dictionary=scene._checkpoint_bundle().duplicate(true)
    original["snapshot"].erase("wonders")
    check(scene._valid_checkpoint(original),"v0.11 checkpoints remain valid without wonders")
    place(scene,model.records[1]["profile"]["at"]);step(scene);settle(scene,1.0);scene._save_checkpoint()
    var partial: Dictionary=scene._checkpoint_bundle().duplicate(true)
    check(model.records[1]["discovered"] and not model.records[1]["completed"] and scene._valid_checkpoint(partial),"discovered unfinished memory is checkpoint-compatible")
    settle(scene,1.0);scene._respawn()
    check(model.records[1]["discovered"] and not model.records[1]["completed"] and float(model.records[1]["elapsed"])==0,"retry remembers discovery while discarding half-poured tea")
    var good: Dictionary=model.export_state();var ledger: Dictionary=scene.score_book.checkpoint()
    check(model.valid_state(good,ledger),"a genuine memory document validates")
    var bad: Dictionary=good.duplicate(true);bad["version"]="1"
    check(not model.valid_state(bad,ledger),"wrong memory version type is rejected")
    bad=good.duplicate(true);bad["memories"].append(bad["memories"][0].duplicate())
    check(not model.valid_state(bad,ledger),"duplicate or excess memory records are rejected")
    bad=good.duplicate(true);bad["memories"][0]["id"]="wonders:another:world"
    check(not model.valid_state(bad,ledger),"another chapter’s memory cannot be injected")
    bad=good.duplicate(true);bad["memories"][0]["discovered"]="yes"
    check(not model.valid_state(bad,ledger),"memory flags require real booleans")
    bad=good.duplicate(true);bad["memories"][0]["completed"]=true
    check(not model.valid_state(bad,ledger),"a complete but undiscovered memory is rejected")
    bad=good.duplicate(true);bad["memories"][1]["completed"]=true
    check(not model.valid_state(bad,ledger),"invented completion without its owned bonus is rejected")
    var false_ledger: Dictionary=ledger.duplicate(true);false_ledger["seen"][good["memories"][0]["id"]]=true
    check(not model.valid_state(good,false_ledger),"an owned bonus cannot disappear from the memory document")
    bad=partial.duplicate(true);bad["snapshot"]["wonders"]={"version":1,"memories":"broken"}
    check(not scene._valid_checkpoint(bad),"the host checkpoint validator invokes wonder validation")
    var path:="user://pocket-memory-roundtrip.json"
    check(Store.write(path,{"checkpoint":partial})==OK,"native checkpoint writes with verified checksum")
    var loaded: Dictionary=Store.read(path)["state"].get("checkpoint",{})
    check(not loaded.is_empty() and loaded["position"] is Vector2 and Store._same_value(loaded,partial),"native checkpoint roundtrip preserves memories and existing Vector2 berth within native JSON precision")
    for suffix in ["", ".bak", ".tmp"]:
        if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
    await dispose(scene)

func partner_checks() -> void:
    var catalog=root.get_node("AdventureRun");catalog.avina_along=true
    var scene=await create(2);var model=scene.pocket_wonders;var record: Dictionary=model.records[1]
    place(scene,record["profile"]["at"]);scene.avina.speech_time=0;scene.avina.tick(0)
    step(scene);settle(scene,.4)
    check(model.reactions.active and model.reactions.partner=="avina","the real follower participates in the shared mirror game")
    var accepted: int=model.reactions.finished_serial
    check(await_complete(scene,record) and model.reactions.finished_serial==accepted+1,"six genuine reaction beats complete the shared game exactly once")
    check(scene.avina.bubbles_cast==0 and not scene.avina.bubble_pending and scene.bubble_shots.is_empty(),"baby pantomime never requests or fires an attack bubble")
    await dispose(scene);catalog.avina_along=false

func continuation_checks() -> void:
    var catalog=root.get_node("AdventureRun");var prefs=root.get_node("AppPreferences")
    var original_path: String=catalog.storage_path;var original_persist: bool=catalog.persist_enabled;var original_preferences: bool=prefs.persist_enabled
    var path:="user://pocket-wonders-continue-test.json"
    catalog.flush_saves();catalog.storage_path=path;catalog.persist_enabled=true;prefs.persist_enabled=true
    catalog.last_written.clear();catalog.last_queued.clear();catalog.resume_state.clear();catalog.begin(1)
    var scene=await create(1);var record: Dictionary=scene.pocket_wonders.records[1]
    await visit(scene,1)
    check(await_complete(scene,record),"Continue fixture receives the postman’s actual letter")
    var id: String=record["profile"]["id"];var earned: int=scene.score
    await frames();catalog.flush_saves()
    var written: Dictionary=Store.read(path)["state"]
    check(not written.is_empty() and written.get("current")==1,"real worker saves the current chapter")
    if written.is_empty():await dispose(scene)
    else:
        check(written["checkpoint"]["snapshot"]["wonders"]["memories"][1]["completed"] and written["checkpoint"]["snapshot"]["ledger"]["seen"].has(id),"disk state atomically owns the letter and reward")
        var safe: Vector2=written["checkpoint"]["position"]
        await dispose(scene);catalog.begin(0);catalog.resume_state.clear()
        check(catalog.load_progress() and catalog.has_resume() and catalog.resume_chapter()==1,"native reload discovers the wonder checkpoint")
        change_scene_to_file("res://godot/title_screen.tscn");await frames(6)
        var menu=current_scene
        check(menu.primary.text.contains("Continue"),"the native title offers Continue")
        menu.primary.pressed.emit()
        for tick in range(120):
            await process_frame
            if current_scene and current_scene.has_method("_stage_index") and current_scene._stage_index()==1:break
        await frames(3);scene=current_scene
        var restored: bool=scene!=null and scene.has_method("_stage_index") and scene._stage_index()==1
        check(restored,"actual title Continue opens a new saved chapter instance")
        if restored:
            scene.set_process(false);scene.set_physics_process(false);record=scene.pocket_wonders.records[1]
            check(record["completed"] and scene.score_book.seen.has(id),"Continue restores the letter memory and ownership")
            check(scene.checkpoint_snapshot["score"]==earned and int(scene.score_book.categories.get("Secrets",0))==int(record["profile"]["reward"]),"Continue restores the exact checkpoint bonus independently of nearby ordinary pickups")
            check(scene.player.distance_to(safe)<2 and not scene.RockCollision.blocked(scene.player,scene.obstacles,scene.HERO_RADIUS*.73),"Continue uses the collision-safe saved berth")
            check(scene.invulnerable>0 and scene.bubble_shots.is_empty() and scene.hostile_shots.is_empty(),"Continue restores grace and clears transient attacks")
            var score_after: int=scene.score
            settle(scene,.4)
            check(scene.score==score_after and record["completed"],"resuming beside the postman cannot duplicate his reward")
            scene._respawn()
            check(scene.score==earned and record["completed"],"retry after Continue retains the banked wonder")
            await frames();catalog.flush_saves()
            check(Store.read(path)["state"]["checkpoint"]["snapshot"]["wonders"]["memories"][1]["completed"],"initial hidden setup never overwrites the restored memory on disk")
            current_scene=null;await dispose(scene)
    catalog.flush_saves();catalog.persist_enabled=original_persist;prefs.persist_enabled=original_preferences;catalog.storage_path=original_path
    for suffix in ["", ".bak", ".tmp"]:
        if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)

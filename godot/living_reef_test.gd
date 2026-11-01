extends SceneTree
const Store=preload("res://godot/progress_store.gd")
var checks:=0
var failures:=0
var swim_ticks:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,note: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error("LIVING REEF: "+note)
func frames(n:=3) -> void:
    for i in range(n):await process_frame
func create(index: int):
    var scene=load(root.get_node("AdventureRun").SCENES[index]).instantiate();root.add_child(scene)
    scene.set_process(false);scene.set_physics_process(false);await frames()
    if index==7:scene.dialogue_open=false;scene.dialogue_card.hide();scene.choice_card.hide();paused=false
    for enemy in scene.enemies:enemy["hp"]=0
    scene.fallen=true;scene.invulnerable=10000
    scene.checkpoint=maxf(scene.checkpoint,scene._left_bound())
    return scene
func dispose(scene) -> void:
    paused=false;scene.free();await frames()
func discover(scene) -> void:
    scene.player=scene.living_reef.profile["at"];scene.camera=maxf(0,scene.player.x-530)
    scene.boost_time=0;scene.living_reef.advance(.016)
    check(scene.living_reef.state=="discovered","nearby activity discovered")
    scene.living_reef.advance(.016)
func swim_to(scene,goal: Vector2,wait_friend:=false) -> bool:
    for i in range(1400):
        var delta: Vector2=goal-scene.player
        scene.touch_vectors[91]=delta.normalized()*minf(1,delta.length()/35)
        scene.invulnerable=10000
        scene._physics_process(1.0/60);swim_ticks+=1
        scene.camera=maxf(0,scene.player.x-530)
        if delta.length()<22:
            scene.touch_vectors.clear();scene.player_velocity=Vector2.ZERO
            if wait_friend:
                for j in range(200):
                    var before: int=scene.living_reef.progress
                    scene._physics_process(1.0/60);swim_ticks+=1
                    if scene.living_reef.completed or scene.living_reef.progress>before:break
            return true
    scene.touch_vectors.clear();return false
func shot(scene,at: Vector2,baby:=false) -> void:
    scene.player=at-Vector2(170,0);scene.camera=maxf(0,scene.player.x-530);scene.facing=1
    if baby:scene.opal.little_bubble(at-Vector2(100,0),1)
    else:
        scene.bubble_unlocked=true;scene.fire_cooldown=0;scene.opal.cancel();scene._fire_bubble()
    scene._update_bubbles(.35)
func run() -> void:
    root.size=Vector2i(1400,960)
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false
    var catalog=root.get_node("AdventureRun");catalog.active=false
    for index in range(8):
        var scene=await create(index);var reef=scene.living_reef
        check(not reef.profile.is_empty(),"authored activity exists chapter "+str(index))
        check(reef.profile["points"].size()==3,"three bounded activity targets")
        if index in [6,7]:
            scene.player=reef.profile["at"];reef.advance(.1)
            check(not reef.eligible() and reef.state=="hidden","finale/tutorial story gate respected")
            if index==6:scene.boss_hp=0
            else:scene.lesson=10;scene.boss_hp=0
        await discover(scene)
        var kind: String=reef.profile["kind"]
        var before: int=scene.score
        if kind=="current":
            var direction: Vector2=(reef.profile["points"][0]-reef.profile["at"]).normalized()
            check(reef.current_drift(direction).length()>50,"current gives a gentle chosen ride")
            check(reef.current_drift(Vector2.ZERO)==Vector2.ZERO,"current never drags an idle player")
            check(reef.current_drift(-direction)==Vector2.ZERO,"current does not fight retreat input")
            scene.boost_time=.2;check(reef.current_drift(direction)==Vector2.ZERO,"current never alters an authored Boost")
            scene.boost_time=0;scene.state="paused"
            check(reef.current_drift(direction)==Vector2.ZERO,"paused current cannot move Sarah")
            scene.state="playing";scene.reduced_fx=true
            check(reef.current_drift(direction).length()>50,"Gentle Motion retains the same ride mechanics")
            scene.reduced_fx=false
        if kind=="choir":
            scene.bubble_unlocked=false
            for target in [2,0,1]:
                scene.player=reef.profile["points"][target];scene.camera=maxf(0,scene.player.x-530)
                scene.boost_time=.25;reef.has_player=false;reef.advance(.016)
                check(reef.activated[target],"Boost wakes shell in any order")
            check(reef.notes_played==3,"three distinct accepted shell notes")
            var queued: int=reef.pending_notes.size()
            check(reef.completed and queued>0 and queued<=3,"quick Boost choir keeps its remaining voices queued after completion")
            var wait: float=reef.note_clock
            paused=true;reef.advance(.5)
            check(reef.pending_notes.size()==queued and reef.note_clock==wait,"pause freezes the final choir voices instead of discarding or rushing them")
            paused=false;reef.advance(.15)
            check(reef.pending_notes.size()==queued-1,"the completed choir releases its next voice after the shared 0.14-second spacing")
            reef.advance(.15)
            check(reef.pending_notes.is_empty(),"all three voices including the final completed note are delivered")
            check(scene.score==before+int(reef.profile["reward"]),"choir reward exact and owned")
        else:
            for target in reef.profile["points"]:
                check(await swim_to(scene,target,kind=="guide"),"real swim reaches optional stop "+str(index))
            if kind=="guide":check(await swim_to(scene,reef.profile["home"],true),"friend escorted home through actual swimming")
        check(reef.completed and reef.progress==3,"activity completes chapter "+str(index))
        check(scene.score_book.seen.has(reef.profile["id"]),"owned discovery award")
        check(scene.checkpoint_snapshot["reef"]["completed"],"completion and reward bank at checkpoint")
        check(scene._valid_checkpoint(scene._checkpoint_bundle()),"new checkpoint validates with ledger")
        var earned: int=scene.score;var event_count: int=reef.completions
        for i in range(10):reef.advance(.1);reef.hit_bubble(0,{"owner":"sarah"})
        check(scene.score==earned and reef.completions==event_count,"completed activity cannot farm rewards")
        scene._respawn()
        check(reef.completed and scene.score==earned,"retry retains banked activity and score")
        check(not reef.has_player and reef.reactions.pending_complete_left==0,"retry clears transient sweeps/reactions")
        await dispose(scene)
    var scene=await create(0);var reef=scene.living_reef
    await discover(scene)
    var first: Vector2=reef.profile["points"][0]
    shot(scene,first,true);check(reef.progress==0,"Avina bubbles never solve Sarah’s choir")
    var rocks: Array[Rect2]=scene.obstacles.duplicate()
    scene.obstacles.append(Rect2(first-Vector2(80,80),Vector2(16,160)))
    shot(scene,first);check(reef.progress==0,"real swept wall wins before choir target")
    scene.obstacles=rocks
    shot(scene,first);check(reef.progress==1 and reef.activated[0],"real Sarah bubble wakes a choir shell")
    scene._save_checkpoint();var partial: Dictionary=scene._checkpoint_bundle().duplicate(true)
    check(scene._valid_checkpoint(partial),"partial activity checkpoint valid")
    shot(scene,reef.profile["points"][1]);check(reef.progress==2,"second voice before rollback")
    scene._respawn();check(reef.progress==1 and not reef.activated[1],"retry rolls partial activity back with its ledger")
    check(reef.pending_notes.is_empty(),"retry cancels an unfinished choir note instead of replaying rollback feedback")
    var old: Dictionary=partial.duplicate(true);old["snapshot"].erase("reef")
    check(scene._valid_checkpoint(old),"v0.10 checkpoint remains compatible")
    var bad: Dictionary=partial.duplicate(true);bad["snapshot"]["reef"]["completed"]=true;bad["snapshot"]["reef"]["state"]="complete";bad["snapshot"]["reef"]["progress"]=3;bad["snapshot"]["reef"]["activated"]=[true,true,true]
    check(not scene._valid_checkpoint(bad),"completion without owned ledger reward rejected")
    bad=partial.duplicate(true);bad["snapshot"]["reef"]["actor"]=Vector2(INF,0)
    check(not scene._valid_checkpoint(bad),"nonfinite friend position rejected")
    bad=partial.duplicate(true);bad["snapshot"]["reef"]["progress"]=3
    check(not scene._valid_checkpoint(bad),"inconsistent activity progress rejected")
    var saved_clock: float=reef.glow_time
    paused=true;reef.advance(.5)
    check(reef.glow_time==saved_clock,"pause stops activity timing")
    paused=false;scene.waterfall_phase="descent";reef.advance(.5)
    check(reef.glow_time==saved_clock and reef.bubble_targets().is_empty(),"waterfall cannot activate activity")
    scene.waterfall_phase="";scene.reduced_fx=true
    shot(scene,reef.profile["points"][1]);shot(scene,reef.profile["points"][2])
    check(reef.completed,"Gentle Motion preserves all gameplay")
    var state: Dictionary=reef.export_state();var path:="user://living-reef-native-test.json"
    var envelope: Dictionary={"checkpoint":scene._checkpoint_bundle(),"reef":state}
    check(Store.write(path,envelope)==OK,"native activity payload writes with verified checksum")
    var loaded: Dictionary=Store.read(path)["state"]
    check(loaded["reef"]==state and loaded["reef"]["actor"] is Vector2,"native state round trip retains ownership and Vector2")
    await dispose(scene)
    await continuation_checks()
    print("LIVING REEF: ",checks," checks, ",failures," failures; ",swim_ticks," real swim ticks")
    quit(1 if failures else 0)

func continuation_checks() -> void:
    var catalog=root.get_node("AdventureRun")
    var prefs=root.get_node("AppPreferences")
    var original_path: String=catalog.storage_path
    var original_persist: bool=catalog.persist_enabled
    var original_preferences: bool=prefs.persist_enabled
    var path:="user://living-reef-continue-test.json"
    catalog.flush_saves();catalog.storage_path=path
    catalog.persist_enabled=true;prefs.persist_enabled=true
    catalog.last_written.clear();catalog.last_queued.clear();catalog.resume_state.clear()
    catalog.begin(4)
    var scene=await create(4)
    await discover(scene)
    for target in scene.living_reef.profile["points"]:shot(scene,target)
    var activity_id: String=scene.living_reef.profile["id"]
    var earned: int=scene.score
    check(scene.living_reef.completed and scene.score_book.seen.has(activity_id),"Continue fixture completes the live palace choir with an owned reward")
    await frames();catalog.flush_saves()
    var written: Dictionary=Store.read(path)["state"]
    check(not written.is_empty() and written.get("current")==4,"real AdventureRun worker writes the saved chapter")
    if written.is_empty():
        await dispose(scene);catalog.persist_enabled=original_persist;prefs.persist_enabled=original_preferences;catalog.storage_path=original_path
        return
    check(written["checkpoint"]["snapshot"]["reef"]["completed"] and written["checkpoint"]["snapshot"]["ledger"]["seen"].has(activity_id),"real disk checkpoint keeps activity completion together with ledger ownership")
    var safe: Vector2=written["checkpoint"]["position"]
    await dispose(scene)
    # Exercise native reload and the actual title Continue binding, not a direct
    # restore_state call or a hand-made checkpoint fixture.
    catalog.begin(0);catalog.resume_state.clear()
    check(catalog.load_progress() and catalog.has_resume() and catalog.resume_chapter()==4,"AdventureRun reload discovers the Living Reef checkpoint on disk")
    change_scene_to_file("res://godot/title_screen.tscn");await frames(6)
    var menu=current_scene
    check(menu.primary.text.contains("Continue"),"real title offers Continue for a reef checkpoint")
    menu.primary.pressed.emit()
    for tick in range(120):
        await process_frame
        if current_scene and current_scene.has_method("_stage_index") and current_scene._stage_index()==4:break
    await frames(3)
    scene=current_scene
    var restored: bool=scene!=null and scene.has_method("_stage_index") and scene._stage_index()==4
    check(restored,"actual title Continue enters a newly instantiated saved chapter")
    if restored:
        scene.set_process(false);scene.set_physics_process(false)
        check(scene.living_reef.completed and scene.living_reef.progress==3,"Continue restores all three choir voices and completed state")
        # One ordinary pearl is beside this real berth and may be collected on
        # the first resumed physics tick. Check the restored checkpoint score
        # and exact Secrets ownership independently of that legitimate pickup.
        check(scene.checkpoint_snapshot["score"]==earned and scene.score_book.seen.has(activity_id) and int(scene.score_book.categories.get("Secrets",0))==int(scene.living_reef.profile["reward"]),"Continue restores the exact checkpoint score and one-time discovery reward")
        var resumed_score: int=scene.score
        check(scene.player.distance_to(safe)<2 and not scene.RockCollision.blocked(scene.player,scene.obstacles,scene.HERO_RADIUS*.73),"Continue places Sarah at the saved collision-safe berth")
        check(scene.invulnerable>0 and scene.hostile_shots.is_empty() and scene.bubble_shots.is_empty(),"Continue supplies arrival grace and clears transient attacks")
        for i in range(3):scene.living_reef.hit_bubble(i,{"owner":"sarah"})
        scene.living_reef._finish();scene.living_reef.advance(.3)
        check(scene.score==resumed_score and scene.living_reef.completed,"continued activity cannot award again through repeated bubbles or completion callbacks")
        scene._respawn()
        check(scene.score==earned and scene.living_reef.completed and scene.score_book.seen.has(activity_id),"retry after Continue retains the banked activity and ledger")
        await frames();catalog.flush_saves()
        var resaved: Dictionary=Store.read(path)["state"]
        check(resaved["checkpoint"]["snapshot"]["reef"]["completed"],"Continue never replaces a completed reef snapshot with initial hidden state")
        current_scene=null;await dispose(scene)
    catalog.flush_saves();catalog.persist_enabled=original_persist;prefs.persist_enabled=original_preferences;catalog.storage_path=original_path
    for suffix in ["", ".bak", ".tmp"]:
        if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)

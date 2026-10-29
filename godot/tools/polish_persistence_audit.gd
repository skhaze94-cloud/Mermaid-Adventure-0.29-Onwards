extends SceneTree
## Run write/read in separate engine processes against an isolated absolute path.
const Store = preload("res://godot/progress_store.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, reason: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error("PERSISTENCE AUDIT: "+reason)
func frames(count := 5) -> void:
    for i in range(count):await process_frame
func run() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size()!=2 or args[0] not in ["write","read"]:
        push_error("Use: -- write|read /absolute/isolated-save.json");quit(1);return
    var run_state=root.get_node("AdventureRun")
    var prefs=root.get_node("AppPreferences")
    prefs.persist_enabled=false;prefs.intro_seen=true;prefs.reduced_motion=true
    root.get_node("OceanAudio").playback_enabled=false
    run_state.storage_path=args[1]
    if args[0]=="write":
        run_state.persist_enabled=true;prefs.persist_enabled=true
        run_state.begin(1);run_state.tutorial_complete=true;run_state.avina_along=true
        run_state.records[0]={"best":4321,"stars":2}
        change_scene_to_file(run_state.SCENES[1]);await frames()
        var level=current_scene
        level.set_process(false);level.set_physics_process(false)
        level.checkpoint=12600.0;level.duke_hp=7;level.flip_hp=4;level.boss_hp=11
        level.switches[0]["on"]=true
        level._award("restart:pearl","Pearls",120,level.player,false)
        level.score_book.damage_taken=2;level._save_checkpoint();await frames()
        run_state.flush_saves()
        check(Store.read(args[1])["state"].get("current",-1)==1,"writer commits actual checkpoint")
    else:
        run_state.persist_enabled=false
        check(run_state.load_progress() and run_state.has_resume(),"new process reads saved adventure")
        check(run_state.chapter_best(0)==4321 and run_state.chapter_stars(0)==2,"new process retains chapter records")
        change_scene_to_file("res://godot/title_screen.tscn");await frames()
        check(current_scene.primary.text.contains("Continue"),"new process offers Continue")
        current_scene.primary.pressed.emit();await frames(18)
        var level=current_scene
        check(level._stage_index()==1 and level.checkpoint==12600.0,"new process opens saved checkpoint")
        check(level.duke_hp==7 and level.flip_hp==4 and level.boss_hp==11,"new process restores independent boss health")
        check(level.switches[0]["on"] and level.score==120 and level.score_book.seen.has("restart:pearl"),"new process restores switch and award ledger")
        check(level.bubble_unlocked and is_instance_valid(level.avina) and level.score_book.damage_taken==2,"new process restores unlock, companion and damage history")
    print("PERSISTENCE AUDIT ",JSON.stringify({"mode":args[0],"pid":OS.get_process_id(),"checks":checks,"failures":failures,"last_save_ms":run_state.last_save_ms,"last_enqueue_ms":run_state.last_enqueue_ms}))
    quit(1 if failures else 0)

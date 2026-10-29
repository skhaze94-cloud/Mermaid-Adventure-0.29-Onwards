extends SceneTree
## Save recovery, real Continue restoration, HUD feedback and bounded boss patterns.
const Store = preload("res://godot/progress_store.gd")
const Patterns = preload("res://godot/boss_patterns.gd")
var checks := 0
var failures := 0
var save_path := ""
var catalog: Node
var prefs: Node

func _initialize() -> void: call_deferred("run")
func check(ok: bool, reason: String) -> void:
    checks += 1
    if not ok: failures += 1; push_error("ADVENTURE POLISH: "+reason)
func frames(count := 3) -> void:
    for i in range(count): await process_frame
func create(path: String):
    var level = load(path).instantiate()
    root.add_child(level)
    level.set_process(false); level.set_physics_process(false)
    return level
func dispose(level) -> void:
    paused = false
    root.remove_child(level); level.free()

func storage_checks() -> void:
    var path := save_path+".probe"
    var first := {"position":Vector2(13.125,4.75),"ledger":{7:{"score":42}},"label":"Sarah’s pearl"}
    check(Store.write(path,first)==OK,"atomic initial file write")
    check(Store.read(path)["state"]==first,"native JSON preserves vectors and integer ledger keys")
    var second := first.duplicate(true); second["ledger"][7]["score"]=84
    check(Store.write(path,second)==OK,"replace save after verified temporary write")
    var broken := FileAccess.open(path,FileAccess.WRITE); broken.store_string("{interrupted"); broken.close()
    var recovered := Store.read(path)
    check(recovered["recovered"] and recovered["state"]==first,"truncated primary recovers verified backup")
    check(Store.write(path,second)==OK and Store._read_file(path+".bak")==first,"repair keeps good backup")
    check(Store.write(path,{"invalid":true},catalog._valid_state)==ERR_INVALID_DATA,"reject invalid session before replacing a save")
    check(Store.read(path)["state"]==second,"rejected state preserves latest valid save")

func continuation_checks() -> void:
    catalog.storage_path=save_path; catalog.persist_enabled=true; prefs.persist_enabled=true
    catalog.last_written.clear(); catalog.resume_state.clear(); catalog.records.clear()
    catalog.begin(1)
    catalog.tutorial_complete=true; catalog.avina_along=true
    var level = create(catalog.SCENES[1]); await frames()
    level.checkpoint=12600.0; level.player=Vector2(12670,540)
    level._award("polish:save","Pearls",40,level.player,false)
    level.picked_count=4; level.score_book.damage_taken=2
    level.duke_hp=7; level.flip_hp=4; level.boss_hp=11; level.switches[0]["on"]=true
    level._save_checkpoint(); await frames()
    var written: Dictionary = Store.read(save_path)["state"]
    check(not written.is_empty(),"real checkpoint is written to disk")
    if written.is_empty():
        print("SAVE DIAGNOSTIC ",JSON.stringify({"ready":level.save_ready,"active":catalog.active,"index":catalog.current_index,"persist":catalog._can_persist(),"valid":catalog._valid_state(catalog.export_state()),"message":catalog.save_message,"temporary":FileAccess.file_exists(save_path+".tmp")}))
        dispose(level); prefs.persist_enabled=false; catalog.persist_enabled=false
        return
    check(written["current"]==1 and written["tutorial"] and written["avina"],"chapter, unlock and companion choice saved")
    check(written["checkpoint"]["snapshot"]["duke"]==7 and written["checkpoint"]["snapshot"]["flip"]==4,"duo checkpoint includes both independent bodies")
    check(level._valid_checkpoint(written["checkpoint"]),"real duo snapshot passes validation")
    var invalid: Dictionary=written["checkpoint"].duplicate(true); invalid["snapshot"]["duke"]=20
    check(not level._valid_checkpoint(invalid),"inconsistent duo HP rejected")
    dispose(level)
    check(Store.write(save_path,{"incompatible":true})==OK,"prepare incompatible primary with valid recovery checkpoint")
    catalog.begin(0); catalog.resume_state.clear()
    check(catalog.load_progress() and catalog.has_resume() and not catalog.save_message.is_empty(),"incompatible primary recovers previous session")
    change_scene_to_file("res://godot/title_screen.tscn"); await frames(6)
    var menu=current_scene
    check(menu.primary.text.contains("Continue"),"real title offers Continue for a saved checkpoint")
    var begin_button = menu.content.get_children().filter(func(child): return child is Button and child.text.begins_with("Begin"))[0]
    begin_button.pressed.emit(); await frames()
    check(menu.page=="new_adventure" and catalog.has_resume(),"new adventure asks before replacing checkpoint")
    var keep_button = menu.content.get_children().filter(func(child): return child is Button and child.text.begins_with("Keep"))[0]
    keep_button.pressed.emit(); await frames()
    check(menu.page=="menu" and menu.primary.text.contains("Continue"),"keeping a save returns to Continue")
    menu.primary.pressed.emit(); await frames(16)
    level=current_scene; level.set_process(false); level.set_physics_process(false)
    check(level._stage_index()==1,"actual Continue button loads saved chapter")
    check(level.duke_hp==7 and level.flip_hp==4 and level.boss_hp==11,"Continue restores authoritative duo HP")
    check(level.switches[0]["on"] and level.score==40 and level.picked_count==4,"Continue restores switch, score and pickup ledger")
    check(level.score_book.seen.has("polish:save") and level.score_book.damage_taken==2,"Continue retains award ownership and damage history")
    check(is_instance_valid(level.avina) and level.bubble_unlocked,"Continue brings Avina and unlocked Bubble")
    check(level.hostile_shots.is_empty() and level.bubble_shots.is_empty() and not level.opal.charge.held,"Continue cancels transient attacks and input")
    check(level.invulnerable>0 and level.checkpoint==12600.0,"restored checkpoint gives safe arrival grace")
    catalog.record_stage(1,{"total":1200,"stars":1})
    catalog.record_stage(1,{"total":1200,"stars":1})
    check(catalog.total()==1200 and catalog.chapter_best(1)==1200,"completion and records remain idempotent")
    check(Store.read(save_path)["state"]["current"]==2,"cleared stage saves the next chapter")
    dispose(level)
    catalog.begin(7)
    level=create(catalog.SCENES[7]); await frames()
    level.lesson=9; level.ring_count=3; level.boss_hp=0; level.bubble_unlocked=true
    level.player=Vector2(7300,600); level._start_hide_seek(); level._close_dialogue()
    level.hide_round=2; level._place_hidden_baby(); level._save_checkpoint(); await frames()
    dispose(level)
    catalog.begin(0); catalog.load_progress(); check(catalog.continue_saved()==7,"tutorial checkpoint resumes in tutorial")
    level=create(catalog.SCENES[7]); await frames()
    check(level.lesson==9 and level.hide_round==2 and level.ring_count==3,"tutorial lesson and peekaboo progress restored")
    check(is_instance_valid(level.avina) and not level.avina.follow_enabled and level.avina.world_position==level.HIDES[2],"hidden baby restored without replaying prior awards")
    check(not level.dialogue_open and level.state=="playing" and not paused,"tutorial resume leaves movement available")
    level.lesson=10; level.boss_hp=0; level.enemies.clear(); level.obstacles.clear()
    level.player=Vector2(7280,390); level.facing=1; level.fire_cooldown=0
    level._fire_bubble(); level._update_bubbles(.4)
    check(not level.practice_switch["on"],"tap cannot complete the optional super target")
    level.fire_cooldown=0; level.opal.begin("script"); level.opal.advance(1.35); level.opal.release("script"); level._update_bubbles(.4)
    check(level.practice_switch["on"],"real charged projectile completes optional super practice")
    var score: int=level.score
    level._opal_hit_switch(0,{"owner":"sarah","tier":3})
    check(level.score==score and level.score_book.seen.has("training:super-practice"),"practice reward awarded once")
    level.practice_switch["on"]=false
    check(level._portal_is_open(),"optional practice never blocks tutorial exit")
    dispose(level)
    prefs.persist_enabled=false; catalog.persist_enabled=false

func feedback_checks() -> void:
    catalog.active=false
    var level=create(catalog.SCENES[0]); await frames()
    level.bubble_unlocked=true
    for hold in [0.0,.35,1.35]:
        level.fire_cooldown=0; level.opal.reset(); level.bubble_shots.clear()
        level.opal.begin("script"); level.opal.advance(hold); level.opal.release("script")
        level.opal.advance(level.opal.charge.recovery_duration*.5)
        level.premium_hud.update_hud(level._hud_snapshot())
        check(is_equal_approx(level.premium_hud.bubble_cooldown_fraction(),.5),"each charge tier has a proportional halfway cooldown")
        check(level.premium_hud.bubble_button_label()=="COOLING","cooldown never invites an ignored hold")
    level.fire_cooldown=0; level.opal.reset(); level.opal.begin("script"); level.opal.advance(.675)
    var info: Dictionary=level._hud_snapshot(); info["touch"]=false
    level.premium_hud.update_hud(info)
    check(level.premium_hud.charge_card.visible and is_equal_approx(level.premium_hud.charge_meter.value,.5),"desktop/controller charge progress visible")
    info["touch"]=true; level.premium_hud.update_hud(info)
    check(not level.premium_hud.charge_card.visible and level.premium_hud.bubble_button_label()=="PRISM BLOOM","touch uses its existing button for charge feedback")
    level.player=Vector2(level._boss_home()-300,600); level.message_time=0
    level._say("Guard broken — strike after recovery!",2,true)
    level.premium_hud.update_hud(level._hud_snapshot())
    check(level.premium_hud.message_label.visible and level.premium_hud.boss_card.visible,"priority feedback remains visible with boss HUD")
    level.message_time=0; level._say("Ordinary travel hint",2)
    level.premium_hud.update_hud(level._hud_snapshot())
    check(not level.premium_hud.message_label.visible,"travel hints do not crowd boss feedback")
    level.boss_hp=0; level.player=Vector2(800,600); level.camera=200
    level.enemies.clear()
    for distance in [500,480,460,440,420,30]:
        level.enemies.append({"kind":"puffer","x":800.0+distance,"y":600.0,"bx":800.0+distance,"by":600.0,"hp":2,"phase":0.0,"dir":-1,"variant":"","hit_cd":0.0,"mode":"patrol"})
    level.animated_enemies.bind_enemies(level.enemies)
    level.enemies[5]["mode"]="attack"; level._sync_native_visuals()
    check(level.opal_fx.focus_slots.size()==4 and level.opal_fx.focus_slots.has(5),"attacking late-array enemy receives emphasis")
    check(not level.opal_fx.focus_slots.has(0),"farther passive enemy does not displace immediate threat")
    level.enemies[5]["mode"]="recover"; level.enemies[5]["hit_cd"]=1.0; level.enemies[0]["mode"]="attack"
    level._sync_native_visuals()
    check(level.opal_fx.focus_slots.has(0) and not level.opal_fx.focus_slots.has(5),"cooling foe yields emphasis to a live attacker")
    dispose(level)

func result_checks() -> void:
    catalog.begin(0)
    catalog.complete_stage(0,1000); catalog.complete_stage(5,2000)
    var level=create(catalog.SCENES[6]); await frames()
    check(is_equal_approx(float(level._hud_snapshot()["progress"]),0),"Nessie begins at zero route progress")
    level.boss_hp=0; level.score=4000; level.player=Vector2(level._portal_x()+1,600)
    level._update_swimming(0)
    check(is_equal_approx(float(level._hud_snapshot()["progress"]),1),"portal completes route progress")
    var hud=level.premium_hud; hud._process(2)
    check(hud.result_total.text=="ADVENTURE TOTAL  7,250","finale shows all chapters including current stage once")
    var sum := 0
    for points in hud.result_values: sum+=points
    check(sum==7250 and hud.result_rows.size()==3,"campaign breakdown reconciles to adventure total")
    check(hud.result_title.text=="THE CROWN IS HOME!","finale celebrates the crown’s return")
    var texts: int=hud.result_text_updates; var layouts: int=hud.modal_layout_updates
    for i in range(120): hud._process(1.0/60)
    check(hud.result_text_updates==texts and hud.modal_layout_updates==layouts,"settled results stop formatting and layout work")
    level._complete_score(); check(catalog.total()==7250,"repeated completion cannot duplicate campaign score")
    dispose(level)
    catalog.begin(0)
    for i in range(6): catalog.complete_stage(i,100)
    catalog.record_stage(6,{"total":400,"stars":1})
    check(catalog.adventure_best==1000,"full journey receives its own persistent best")

func boss_checks() -> void:
    catalog.active=false
    var shapes: Array[String]=[]
    for index in [3,4,5,6]:
        var level=create(catalog.SCENES[index]); await frames()
        level.player=Vector2(level._boss_home()-700,600); level.invulnerable=100
        level.boss_clock=1.35; level.attack_clock=.9; level._update_boss(0)
        check(level.pending_volley.size()==3 and level.hostile_shots.is_empty(),"signature warns before firing "+level.chapter_id)
        var locked: Array[Dictionary]=level.pending_volley.duplicate(true)
        shapes.append(JSON.stringify(JSON.from_native(locked)))
        level.player.y+=140
        level._update_boss(.141); level._update_boss(.141)
        check(level.hostile_shots.size()==3 and level.pending_volley.is_empty(),"warning releases three bounded projectiles "+level.chapter_id)
        for i in range(level.hostile_shots.size()):
            var shot: Dictionary=level.hostile_shots[i]
            check(Vector2(shot["velocity"]).normalized().is_equal_approx(locked[i]["direction"]),"telegraph direction stays locked after Sarah moves")
            check(is_equal_approx(Vector2(shot["velocity"]).length(),270),"signature keeps original projectile speed")
        level.boss_clock=4.2; level._update_boss(0)
        check(level._boss_vulnerable() and level.pending_volley.is_empty(),"existing recovery gate retained "+level.chapter_id)
        level.boss_hp=0; level._update_boss(0)
        check(level.pending_volley.is_empty() and level.volley_rays.is_empty(),"defeat clears pending attack "+level.chapter_id)
        dispose(level)
    for i in range(shapes.size()):
        for j in range(i+1,shapes.size()): check(shapes[i]!=shapes[j],"bosses use distinct signature geometry")

func run() -> void:
    root.size=Vector2i(1400,960); root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
    catalog=root.get_node("AdventureRun"); prefs=root.get_node("AppPreferences")
    prefs.persist_enabled=false; prefs.reduced_motion=true; prefs.intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false
    var old_path: String=catalog.storage_path
    save_path="user://polish-test-%s.json" % OS.get_process_id()
    storage_checks()
    await continuation_checks()
    await feedback_checks()
    await result_checks()
    await boss_checks()
    catalog.persist_enabled=false; prefs.persist_enabled=false; catalog.storage_path=old_path
    for stem in [save_path,save_path+".probe"]:
        for suffix in ["",".bak",".tmp"]:
            if FileAccess.file_exists(stem+suffix): DirAccess.remove_absolute(stem+suffix)
    print("ADVENTURE POLISH: ",checks," checks, ",failures," failures")
    quit(1 if failures else 0)

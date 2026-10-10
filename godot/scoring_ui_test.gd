extends SceneTree
const Book = preload("res://godot/score_book.gd")
const Profiles = preload("res://godot/device_profiles.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
    if not value:
        failures += 1
        push_error("SCORING UI: "+message)
func run() -> void:
    var book = Book.new()
    var total := 0
    for i in range(10):
        var reward: Dictionary = book.award(str(i),"Pearls",10,true)
        total += reward.points
        check(reward.multiplier == (5 if i>=9 else (3 if i>=5 else (2 if i>=2 else 1))),"multiplier threshold")
    check(book.award("0","Pearls",10,true).is_empty(),"duplicate pickup")
    var saved: Dictionary = book.checkpoint()
    book.award("temporary","Enemies",50,true)
    book.rollback(saved)
    check(not book.seen.has("temporary") and book.multiplier==1,"checkpoint rollback")
    book.award("new","Pearls",10,true)
    total += 10
    book.tick(3.0)
    check(book.multiplier==1 and book.combo_left==0,"expiry")
    var result: Dictionary = book.complete(total,20,0)
    var sum := 0
    for value in result.breakdown.values(): sum += int(value)
    check(sum==result.total and result.total==total+350,"breakdown and bonuses")
    check(book.complete(total,20,0)==result and book.award("late","Pearls",10,true).is_empty(),"completion once")
    var hurt = Book.new()
    hurt.damage_taken=1
    check(hurt.complete(6000,0,7000).stars==3 and not hurt.result.perfect and not hurt.result.new_record,"ratings and retained record")
    var prefs = root.get_node("AppPreferences")
    var original_best: int = prefs.best_score
    var original_persist: bool = prefs.persist_enabled
    var existed := FileAccess.file_exists(prefs.PATH)
    var original_bytes := FileAccess.get_file_as_bytes(prefs.PATH) if existed else PackedByteArray()
    prefs.best_score=987654
    prefs.persist_enabled=true
    prefs.save()
    var config := ConfigFile.new()
    check(config.load(prefs.PATH)==OK and config.get_value("records","highland")==987654,"record saved")
    if existed:
        var file := FileAccess.open(prefs.PATH,FileAccess.WRITE)
        file.store_buffer(original_bytes)
        file.close()
    else: DirAccess.remove_absolute(ProjectSettings.globalize_path(prefs.PATH))
    prefs.persist_enabled=false
    var level = load("res://godot/highland_level.tscn").instantiate()
    root.add_child(level)
    level.set_process(false)
    level.set_physics_process(false)
    level.simulated_touch=true
    level._award("test","Pearls",10,level.player,true)
    level._award("test","Pearls",10,level.player,true)
    check(level.score==10,"real event duplicate guard")
    level._save_checkpoint()
    level._award("after-checkpoint","Enemies",50,level.player,true)
    level._respawn()
    check(level.score==10 and not level.score_book.seen.has("after-checkpoint"),"real checkpoint restores ledger")
    level._award("fresh","Pearls",10,level.player,true)
    var left: float = level.score_book.combo_left
    level._set_paused(true)
    await process_frame
    check(level.score_book.combo_left==left and level.touches.is_empty(),"pause freezes and releases")
    level._set_paused(false)
    for profile in Profiles.cases():
        var pixels := Vector2(profile.size)
        var view := pixels/minf(pixels.x/1400,pixels.y/960)
        level.premium_hud.configure_layout(view,pixels,profile.safe)
        var hud = level.premium_hud
        if hud.portrait: continue
        var center: Vector2 = level._pad_rect().get_center()
        var event := InputEventScreenTouch.new()
        event.index=2
        event.position=center+Vector2(42,0)*hud.ui_scale
        event.pressed=true
        level._input(event)
        event.index=3
        event.position=center-Vector2(42,0)*hud.ui_scale
        level._input(event)
        check(level._input_vector().x>0,"second finger does not steal joystick")
        event.index=2
        event.canceled=true
        level._input(event)
        check(level._input_vector()==Vector2.ZERO,"canceled touch releases")
        level._on_viewport_resized()
    level._complete_score()
    var final_score: int = level.score
    level._complete_score()
    check(level.score==final_score,"level results no repeated bonuses")
    level.score=1234567890
    level.premium_hud.update_hud(level._hud_snapshot())
    level.premium_hud._process(4.0)
    check(level.premium_hud.score_label.text=="1,234,567,890","long live score")
    prefs.best_score=original_best
    prefs.persist_enabled=original_persist
    paused=false
    level.free()
    print("GODOT SCORING UI TEST "+("PASSED" if failures==0 else "FAILED"))
    quit(0 if failures==0 else 1)


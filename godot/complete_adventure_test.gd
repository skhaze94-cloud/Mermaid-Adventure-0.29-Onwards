extends SceneTree
const Data = preload("res://godot/chapter_data.gd")
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("COMPLETE ADVENTURE: "+message)
func frames(count := 6) -> void:
    for i in range(count): await process_frame
func run() -> void:
    var prefs = root.get_node("AppPreferences")
    prefs.persist_enabled = false
    prefs.intro_seen = true
    prefs.reduced_motion = true
    var catalog = root.get_node("AdventureRun")
    # Exercise every real native chapter-selection button and its bound index.
    for index in range(catalog.SCENES.size()):
        change_scene_to_file("res://godot/title_screen.tscn")
        await frames()
        var menu = current_scene
        menu.show_page("chapters")
        await frames()
        var choices = menu.content.get_children().filter(func(node):return node is Button)
        check(choices.size()==8,"all eight chapters need menu buttons")
        choices[index].pressed.emit()
        await frames(10)
        var level = current_scene
        check(level.get_script()!=null and level._stage_index()==index,"chapter button loads correct scene: "+str(index))
        level.set_physics_process(false)
        check(level.obstacles.size()==Data.source(Data.IDS[index]).obstacles.size(),"all source formations imported")
        check(level.enemies.size()==(0 if index==7 else Data.source(Data.IDS[index]).enemies.size()),"all source enemies imported")
        check(level.boss_hp==level._boss_max_health(),"source boss health initialized")
        check(catalog.active and catalog.start_index==index,"selected chapter starts a linked run")
        if index in [3,4,5,6]:
            level.player = Vector2(level._boss_home(),570)
            level.boss_clock = 4.2
            level.boost_time = .3
            level.boss_hit_cooldown = 0
            var before: int = level.boss_hp
            level._update_boss(.016)
            check(level.boss_hp==before-1,"green opening accepts boost hit")
            level._save_checkpoint()
            level.boss_hp = 0
            level._respawn()
            check(level.boss_hp==before-1 and level.leap_phase=="" and level.hostile_shots.is_empty(),"retry restores checkpoint and clears attacks")
        level._return_to_menu()
        await frames()
        check(current_scene.name=="SarahStorybookOpening" and not paused,"pause/menu return must unpause")
    # Play the complete continuation chain, including optional training first.
    catalog.begin(7)
    change_scene_to_file(catalog.SCENES[7])
    await frames()
    for expected in [7,0,1,2,3,4,5,6]:
        var level = current_scene
        check(level._stage_index()==expected,"route order "+str(expected))
        level.set_physics_process(false)
        level.fallen = true
        level.boss_hp = 0
        if expected==1: level.duke_hp=0; level.flip_hp=0
        if expected==7: level.lesson=10
        level.player = Vector2(level._portal_x()+1,540)
        level._update_swimming(0)
        check(level.state=="victory" and paused,"portal must show stage-clear menu "+str(expected))
        level._sync_native_visuals()
        if expected==7:
            level.bring_button.pressed.emit()
            level.reply_box.get_child(0).pressed.emit()
            level.reply_box.get_child(0).pressed.emit()
        else: level.premium_hud.modal_buttons["restart"].pressed.emit()
        await frames(12)
        check(not paused,"Continue must release paused tree "+str(expected))
    check(current_scene.name=="SarahStorybookOpening","Nessie clear returns to main menu")
    check(catalog.completed.size()==8,"all eight chapter scores recorded")
    check(catalog.next_name(6)=="","Nessie is final chapter")
    # Newer Godot has a built-in draw_ellipse. Never override its signature.
    for path in ["res://godot/journey_level.gd","res://godot/basic_chapter.gd"]:
        check(not FileAccess.get_file_as_string(path).contains("func draw_ellipse("),"avoid newer-engine CanvasItem method conflict")
    print("COMPLETE ADVENTURE: ",checks," checks, ",failures," failures")
    quit(1 if failures else 0)

extends SceneTree
const Data := preload("res://godot/journey_data.gd")
const Pack := preload("res://godot/lagoon_art.gd")
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error("THREE-STAGE: "+message)
func frames(count := 4) -> void:
    for i in range(count): await process_frame
func run() -> void:
    root.get_node("AppPreferences").persist_enabled = false
    var journey = root.get_node("AdventureRun")
    journey.begin()
    var first = load(journey.SCENES[0]).instantiate()
    root.add_child(first)
    current_scene = first
    first.set_physics_process(false)
    first.boss_hp = 0
    first.fallen = true
    first.player = Vector2(first._portal_x(),540)
    first._update_swimming(0)
    check(first.state == "victory" and paused,"Highland portal should show clear results")
    check(first._next_stage_name() == "Shadow Crab Kingdom","Highland should lead to Shadow Crab")
    first._restart()
    await frames(8)
    var shadow = current_scene
    check(shadow.name == "ShadowCrabKingdom" and not paused,"Shadow scene transition should unpause")
    shadow.set_physics_process(false)
    check(shadow.obstacles.size()==7 and shadow.enemies.size()==27,"HTML shadow geometry/roster")
    check(shadow.bubble_unlocked and shadow.fallen,"Bubble and underwater start must carry over")
    shadow.player = Vector2(200,500)
    shadow._update_swimming(.01)
    check(shadow.player.x<300,"Shadow must not clamp to Highland's waterfall exit")
    shadow.bubble_shots.append({"pos":Vector2(3802,430),"direction":1.0,"life":1.0})
    shadow._update_bubbles(0)
    check(shadow.switches[0]["on"],"Bubble shell switch should open optional treasure")
    shadow.player = Vector2(7200,500)
    shadow._check_checkpoints()
    check(shadow.checkpoint==7098,"Royal Market checkpoint")
    shadow.duke_hp = 3
    shadow.flip_hp = 4
    shadow._respawn()
    check(shadow.duke_hp==10 and shadow.flip_hp==8 and shadow.switches[0]["on"],"Retry must restore paired boss and switches")
    shadow.player = Vector2(13000,450)
    shadow.combo_clock = 5.81
    shadow._update_boss(.01)
    check(shadow.crab_stun>0 and shadow.flip_stun>0,"Comedy collision creates attack opening")
    shadow.boss_hp = 0
    shadow.duke_hp = 0
    shadow.flip_hp = 0
    shadow.player = Vector2(shadow._portal_x(),540)
    shadow._update_swimming(0)
    check(shadow.state=="victory","Shadow portal clear")
    shadow._restart()
    await frames(8)
    var lagoon = current_scene
    lagoon.set_physics_process(false)
    check(lagoon.name=="MiguelLagoon" and not paused,"Miguel transition")
    check(lagoon._level_length()==33150 and lagoon.obstacles.size()==10,"Miguel extended HTML geometry")
    check(lagoon._boss_home()==Data.sx(7000) and lagoon.boss_hp==4,"Miguel boss home and health")
    for kind in Data.PACK_KINDS:
        check(lagoon.enemies.any(func(e):return e["kind"]==kind),"Missing pack enemy "+kind)
        for dir in [-1,1]:
            for mode in ["patrol","approach","windup","attack"]:
                check(Pack.enemy_frame({"kind":kind,"dir":dir,"mode":mode}) != null,"Missing directional pose "+kind)
    check(lagoon._water_line()==310,"Miguel waterline from HTML")
    check(lagoon.terrain_keys.size()==12 and lagoon.flora_keys.size()==12,"All 24 scenery views must load")
    for stage in [true,false]:
        for item in Data.treasure(stage):
            for block in Data.obstacles(stage): check(not block.grow(30).has_point(Vector2(item["x"],item["y"])),"Collectible in blocked scenery")
    for e in lagoon.enemies:
        lagoon.player = Vector2(e["x"]-260,e["y"])
        lagoon.invulnerable = 100
        for i in range(200): lagoon._update_enemies(.016)
    var otter: Dictionary = lagoon.enemies.filter(func(e):return e["kind"]=="bubble-bandit-otter")[0]
    var pearl: Dictionary = lagoon.treasures.filter(func(t):return t["kind"]=="pearl" and not t["taken"])[0]
    otter["loot"] = [lagoon.treasures.find(pearl)]
    pearl["taken"] = true
    lagoon._release_loot(otter)
    check(not pearl["taken"],"Otter must release uncollected pearls safely")
    lagoon.player = Vector2(lagoon._boss_home(),540)
    lagoon.boss_clock = 4.4
    lagoon.boost_time = .3
    lagoon.boss_hit_cooldown = 0
    lagoon._update_boss(.01)
    check(lagoon.boss_hp==3,"Green Miguel recovery window should accept boost damage")
    lagoon._save_checkpoint()
    lagoon.boss_hp = 0
    lagoon._respawn()
    check(lagoon.boss_hp==3,"Miguel checkpoint health should restore")
    lagoon.boss_hp = 0
    lagoon.player = Vector2(lagoon._portal_x(),540)
    lagoon._update_swimming(0)
    check(lagoon.state=="victory" and lagoon._next_stage_name()=="Blackwater Tunnel","Miguel continues into Blackwater")
    lagoon._restart()
    await frames(8)
    check(current_scene.name=="BlackwaterTunnel" and not paused,"Miguel clear opens the tunnel")
    current_scene._return_to_menu()
    await frames(8)
    check(journey.completed.size()==3,"All three completed scores recorded")
    print("GODOT FIRST THREE CHAPTERS TEST "+("PASSED" if failures==0 else "FAILED"))
    quit(0 if failures==0 else 1)

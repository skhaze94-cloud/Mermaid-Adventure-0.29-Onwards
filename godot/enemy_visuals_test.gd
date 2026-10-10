extends SceneTree
## Art layout, combat pose, pooling, quality and waterfall regression checks.
const CreatureSkin = preload("res://godot/creature_skin.gd")
const Art = preload("res://godot/creature_art.gd")
var failures := 0
func _initialize() -> void:
    call_deferred("_run")
func check(ok: bool, reason: String) -> void:
    if not ok:
        failures += 1
        push_error("ENEMY VISUAL TEST: " + reason)
func _run() -> void:
    var level = load("res://godot/highland_level.tscn").instantiate()
    root.add_child(level)
    level.set_physics_process(false)
    level.set_process(false)
    var pool = level.animated_enemies
    check(pool.sprites.size() == level.enemies.size(), "Every lake enemy must have a native portrait")
    var count: int = pool.get_child_count()
    for kind in ["crab", "eel", "jelly", "puffer", "swordfish", "shark"]:
        var i: int = pool.kinds.find(kind)
        check(i >= 0, "Missing species " + kind)
        if i < 0: continue
        var enemy: Dictionary = level.enemies[pool.indices[i]]
        enemy["x"] = 500.0
        enemy["y"] = 480.0
        for mode in ["patrol", "windup", "attack", "recover"]:
            enemy["mode"] = mode
            pool.animate_visible(0.0, 1.0, true, 0.001, true, false)
            check(pool.materials[i].get_shader_parameter("combat_pose") == Art.pose(mode),kind + " combat cue must match immediately")
            check(pool.atlases[i].region == Art.region(kind,CreatureSkin.canonical_pose(kind)),kind + " uses a connected canonical skin")
            check(pool.sprites[i].visible, kind + " portrait visible")
            var ratio: Vector2 = pool.sprites[i].scale/pool.atlases[i].region.size
            check(is_equal_approx(ratio.x,ratio.y),kind + " anatomy must not stretch")
            check(pool.materials[i].get_shader_parameter("animate_detail") == false, "Gentle motion disables detail")
            check(pool.materials[i].get_shader_parameter("high_quality") == false, "Economy disables extra samples")
            var rect := Art.region(kind, Art.pose(mode))
            check(Rect2(Vector2.ZERO, Art.TEXTURES[kind].get_size()).encloses(rect), kind + " atlas bounds")
        enemy["hp"] = 0
        pool.animate_visible(0.0, 1.0, true, 0.01)
        check(not pool.sprites[i].visible, "Gentle motion hides defeated enemies immediately")
        enemy["hp"] = 1
        enemy["x"] = 100000.0
        pool.animate_visible(0.0, 1.0, false, 0.01)
        check(not pool.sprites[i].visible, "Offscreen creature culled")
    check(pool.get_child_count() == count, "Animation must reuse nodes")
    level._start_waterfall()
    level.waterfall_phase = "descent"
    level.waterfall_time = 5.0
    level._sync_native_visuals()
    check(level.waterfall_enemies.visible and not pool.visible, "Descent switches pools")
    for i in range(level.waterfall_enemies.sprites.size()):
        var kind: String = level.waterfall_enemies.kinds[i]
        check(level.waterfall_enemies.atlases[i].atlas == Art.TEXTURES[kind], "Waterfall shares refreshed " + kind + " artwork")
    var boss = level.native_boss
    for mode in ["windup", "attack", "recover"]:
        boss.set_boss_state(5, mode == "recover", 1.0, 500, 480, 1400, mode, 0)
        check(boss.surface.get_shader_parameter("combat_pose") == Art.pose(mode), "Carlo immediate combat cue")
        check(boss.sprite.mesh is ArrayMesh,"Carlo has articulated geometry")
    boss.play_hit()
    boss.defeat()
    boss.reset_boss()
    check(not boss.defeating and boss.sprite.modulate.a == 1.0, "Restart clears boss defeat")
    var ratio: Vector2 = boss.sprite.scale/Art.region("carlo",0).size
    check(is_equal_approx(ratio.x,ratio.y), "Carlo proportions")
    root.remove_child(level)
    level.free()
    if failures == 0: print("GODOT ENEMY VISUALS TEST PASSED")
    quit(0 if failures == 0 else 1)

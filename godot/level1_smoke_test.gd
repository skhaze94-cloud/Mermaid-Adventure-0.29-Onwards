extends SceneTree
## Headless behaviour test: source geometry, waterfall timing, pickup and portal.

var failures := 0

func _initialize() -> void:
    call_deferred("_run_checks")

func _check(condition: bool, reason: String) -> void:
    if not condition:
        failures += 1
        push_error("GODOT LEVEL 1 TEST FAILURE: " + reason)

func _run_checks() -> void:
    var level = load("res://godot/highland_level.tscn").instantiate()
    root.add_child(level)
    # Native-Godot v0.2: these are real editor scene nodes, not HTML-style canvas sprites.
    _check(level.native_rig.get_node("Torso/ContinuousMenuTail") is MeshInstance2D, "Articulated Sarah tail missing")
    _check(level.native_rig.get_node("Torso/HeadNeck") is Node2D, "Native face joint missing")
    _check(level.native_rig.get_node("Torso/NearArm") is Node2D, "Native arm joint missing")
    _check(level.native_fx.water_overlay.material is ShaderMaterial, "Water GPU shader missing")
    # 0.3: all depth planes and passes must be native render resources.
    _check(level.world_depth.background.material is ShaderMaterial, "Painted background shader missing")
    _check(level.world_depth.far_entries.size() == 25, "Far garden plane missing")
    _check(level.world_depth.middle_entries.size() == 33, "Mid garden plane missing")
    _check(level.foreground_depth.entries.size() == 18, "Foreground parallax silhouettes missing")
    _check(level.relief_obstacles.sprites.size() == 23, "Native reef collision texture sprites missing")
    _check(level.relief_obstacles.sprites[0].material is ShaderMaterial, "Raised reef material shader missing")
    _check(level.world_depth.z_index < level.relief_obstacles.z_index, "Deep reefs must draw behind obstacles")
    _check(level.relief_obstacles.z_index <= level.native_fx.z_index, "Refraction must sample obstacle art before Sarah")

    _check(level.native_fx.refract_overlay.material is ShaderMaterial, "GPU refraction shader missing")
    _check(level.native_fx.mist_overlay.material is ShaderMaterial, "Volumetric depth mist shader missing")
    level.world_depth.set_camera(3900.0, true, false)
    var depth_entry: Dictionary = level.world_depth.middle_entries[0]
    var far_entry: Dictionary = level.world_depth.far_entries[0]
    _check(is_equal_approx(float(level.world_depth.background_material.get_shader_parameter("grotto_mix")), 1.0), "Grotto tint not updating")
    _check(float(depth_entry["factor"]) > float(far_entry["factor"]), "Parallax order incorrect")
    level.foreground_depth.set_camera(3900.0, false, false)
    _check(not level.foreground_depth.visible, "Foreground must disappear during waterfall")
    level.foreground_depth.set_camera(3900.0, true, false)
    level.native_fx.set_quality(false)
    _check(not level.native_fx.refract_overlay.visible, "Economy mode should disable refraction")
    level.native_fx.set_quality(true)
    _check(level.native_fx.refract_overlay.visible, "High mode should restore refraction")

    _check(level.native_fx.trail is CPUParticles2D, "Native particle trail missing")
    _check(level.native_boss.sprite is MeshInstance2D, "Godot articulated Carlo mesh missing")
    _check(level.native_boss.light is PointLight2D, "Carlo vulnerability light missing")
    # Graphics overhaul: HUD is above every shader, with native actor lighting.
    _check(level.premium_hud is CanvasLayer, "Native premium HUD must be a CanvasLayer")
    _check(level.premium_hud.layer >= 6, "HUD must draw above the 2.5D post-processing")
    _check(level.premium_hud.canvas is Control, "Native HUD drawing control missing")
    _check(level.premium_hud.canvas.mouse_filter == Control.MOUSE_FILTER_IGNORE,
        "HUD must not intercept touchscreen controls")
    _check(level.native_rig.hero_light is PointLight2D, "Sarah's key light missing")
    _check(level.water_surface is Node2D, "Water surface shader composition missing")
    _check(level.water_surface.foam.size() == 32, "Wave foam highlights not initialized")
    _check(level.native_fx.cinematic_overlay.material is ShaderMaterial,
        "Cinematic depth edge grade shader missing")
    var sample: Dictionary = level._hud_snapshot()
    _check(int(sample.get("health", -1)) == 5, "HUD health snapshot mismatched")
    level.premium_hud.update_hud(sample)
    _check(level.premium_hud.info.has("progress"), "HUD missing level progress")
    level.native_fx.set_quality(false)
    _check(not level.native_fx.cinematic_overlay.visible,
        "Economy preset must omit cinematic grade")
    level.native_fx.set_quality(true)
    _check(level.native_fx.cinematic_overlay.visible,
        "High preset must restore cinematic grade")

    # v0.5 animation/performance regression checks; no FPS claims from headless CI.
    _check(level.animated_enemies.sprites.size() > 0, "Pooled enemy sprite atlas missing")
    _check(level.animated_enemies.sprites.size() == level.animated_enemies.atlases.size(),
        "Pooled atlas textures do not match enemy sprites")
    var enemy_idx: int = level.animated_enemies.indices[0]
    var enemy_pos: float = float(level.enemies[enemy_idx]["x"])
    level.animated_enemies.animate_visible(maxf(0.0, enemy_pos - 500.0),
        3.0, false, 0.05, true, true)
    _check(level.animated_enemies.active_count >= 1, "Nearby enemy must be visible")
    var tick_before: int = level.animated_enemies.animation_ticks
    level.animated_enemies.animate_visible(maxf(0.0, enemy_pos - 500.0),
        3.001, false, 0.001, true, true)
    _check(level.animated_enemies.animation_ticks == tick_before+1,
        "High quality creature motion must update every rendered frame")
    level.animated_enemies.animate_visible(maxf(0.0, enemy_pos - 500.0),
        3.05, false, 0.05, true, false)
    tick_before = level.animated_enemies.animation_ticks
    level.animated_enemies.animate_visible(maxf(0.0, enemy_pos - 500.0),
        3.051, false, 0.001, true, false)
    _check(level.animated_enemies.animation_ticks == tick_before,
        "Economy mode must skip redundant decorative updates")
    level.animated_enemies.animate_visible(maxf(0.0, enemy_pos - 500.0),
        3.1, false, 0.08, false, true)
    _check(not level.animated_enemies.visible,
        "Enemy pool should disappear during waterfall")

    _check(level.native_fx.burst_pool.size() == level.native_fx.BURST_POOL_SIZE,
        "Impact burst pool not preallocated")
    var burst_count: int = level.native_fx.burst_pool.size()
    var child_count: int = level.native_fx.get_child_count()
    for i in range(24):
        level.native_fx.splash(Vector2(210, 490), Color("#b5f9e8"), 6)
    _check(level.native_fx.burst_pool.size() == burst_count,
        "Impact bursts must not allocate new pool members")
    _check(level.native_fx.get_child_count() == child_count,
        "Impact bursts allocated extra particle nodes")
    _check(level.native_fx.burst_events == 24,
        "Expected pooled particle burst reuses")

    level.native_rig.set_motion(Vector2(440, 5), 1.0, false, false, 1.0)
    level.native_rig._process(0.10)
    _check(level.native_rig.swim_blend > 0.0,
        "Sarah swim animation must blend from idle")
    level.native_rig.set_motion(Vector2(830, 0), -1.0, true, false, 1.0)
    level.native_rig._process(0.12)
    _check(level.native_rig.boost_blend > 0.2,
        "Boost animation blend missing")
    # The rig intentionally clamps large deltas to 50ms; test real frame progression.
    level.native_rig._process(0.05)
    _check(level.native_rig.animation_mode == "boost",
        "Animation mode must reflect boosting")
    _check(level.native_rig.scale.x < 0.0,
        "Sarah turn should flip without zero-width squashing")
    level.native_rig.play_impact()
    _check(level.native_rig.hit_kick > 0.0,
        "Damage reaction must animate")
    var hud_redraws: int = level.premium_hud.redraw_count
    level.premium_hud.update_hud(level._hud_snapshot())
    _check(level.premium_hud.redraw_count == hud_redraws,
        "Static HUD should skip repeated redraw")
    _check(level.performance_overlay is CanvasLayer,
        "Runtime performance overlay missing")
    _check(not level.performance_overlay.enabled,
        "Profiling UI must default off")
    level.performance_overlay.set_monitor_visible(true)
    _check(level.performance_overlay.enabled and level.performance_overlay.visible,
        "F6 diagnostics must be available")
    level.performance_overlay.set_monitor_visible(false)
    level.high_depth_quality = false
    level._apply_visual_quality()
    _check(not level.native_rig.hero_light.enabled and not level.native_boss.light.enabled,
        "Economy mode must disable expensive native lights")
    level.high_depth_quality = true
    level._apply_visual_quality()
    _check(level.native_rig.hero_light.enabled,
        "High preset should restore character lighting")
    _check(level.world_depth.placement_updates >= 1, "Parallax placement counters missing")

    _check(level.obstacles.size() == 23, "Source obstacle count changed")
    _check(level.enemies.size() >= 25, "Expected a playable enemy roster")
    _check(level.treasures.size() > 80, "Expected exploration treasure")
    _check(level.boss_hp == 3, "Carlo boss not initialized")
    level._start_waterfall()
    _check(level.waterfall_phase == "pull", "Waterfall entry missing")
    _check(level.waterfall_hazards.size() == 12, "Source waterfall hazards missing")
    _check(level.waterfall_gold.size() == 22, "Source waterfall treasure missing")
    level._update_waterfall(1.9)
    _check(level.waterfall_phase == "descent", "Waterfall descent missing")
    level._update_waterfall(17.1)
    _check(level.waterfall_phase == "outflow", "Waterfall duration incorrect")
    level._update_waterfall(1.7)
    _check(level.waterfall_phase == "", "Outflow should finish")
    _check(level.fallen, "Post-waterfall route should unlock")
    _check(level.player.x == 4120.0, "Grotto exit mismatch")
    var first_pearl: Dictionary = level.treasures[0]
    level.player = Vector2(float(first_pearl["x"]), float(first_pearl["y"]))
    var score_before: int = level.score
    level._update_collectibles()
    _check(level.score > score_before, "Collectible should score")
    level.boss_hp = 0
    level.player = Vector2(level._portal_x()+10, 530)
    level._update_swimming(0.016)
    _check(level.state == "victory", "Exit portal should complete level")
    if failures == 0:
        print("GODOT LEVEL 1 LOGIC TEST PASSED")
    else:
        print("GODOT LEVEL 1 LOGIC TEST FAILED: " + str(failures))
    root.remove_child(level)
    level.free()
    quit(0 if failures == 0 else 1)

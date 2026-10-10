extends Node2D
const GroundArt = preload("res://godot/terrain_painter.gd")
## Sarah Maria — Highland Gold, Godot 4 playable port (prototype 0.1).
## Source of truth: dist/game.js, dist/highland.js, dist/creature-sprites-v731.js
## Import artwork and soundtrack from the SAME repository, res://dist/assets/.
const Controls = preload("res://godot/control_layout.gd")
const Combat = preload("res://godot/enemy_combat.gd")
const Source = preload("res://godot/chapter_data.gd")
const Highland = preload("res://godot/highland_data.gd")
const BACKGROUND = preload("res://dist/assets/highlands.webp")
const HERO = preload("res://dist/assets/sarah-mermaid.webp")
const FALL_BOULDER = preload("res://godot/assets/waterfall-boulder-v07.webp")
const REEF = preload("res://dist/assets/barrier-reef.webp")
const FLORA = preload("res://dist/assets/flora-layer.webp")
const CARLO = preload("res://dist/assets/carlo.webp")
const MUSIC = preload("res://dist/assets/bubble-bell-adventure.mp3")

const WATER_SURFACE := 280.0
const BOTTOM := 902.0
const HERO_RADIUS := 43.0
const MAX_HEALTH := 5
const BOSS_MAX_HEALTH := 3
const RockCollision = preload("res://godot/rock_collision.gd")
const SarahMotion = preload("res://godot/sarah_motion.gd")
const SWIM_SPEED := SarahMotion.SWIM_SPEED
const BOOST_SPEED := 850.0

var player := Vector2(220.0, 460.0)
var player_velocity := Vector2.ZERO
var facing := 1.0
var camera := 0.0
var time := 0.0
var health := MAX_HEALTH
var energy := 1.0
const ScoreBook = preload("res://godot/score_book.gd")
var score_book = ScoreBook.new()
var score := 0
var picked_count := 0
var checkpoint := 220.0
var invulnerable := 0.0
var boost_time := 0.0
var boost_cooldown := 0.0
var boost_direction := Vector2.RIGHT
var jump_time := 0.0
var leap_cooldown := 0.0
var state := "playing"
var fallen := false
var message := "Swim right. Discover the waterfall and Carlo's kingdom!"
var message_time := 5.0

var obstacles: Array[Rect2] = []
var enemies: Array[Dictionary] = []
const EnvironmentArt = preload("res://godot/environment_art.gd")
var collectible_art := {"pearl": EnvironmentArt.prop("pearl"), "chest": EnvironmentArt.prop("chest"), "heart": EnvironmentArt.prop("heart"), "boost": EnvironmentArt.prop("boost")}
var treasures: Array[Dictionary] = []
var avina: Node2D
var bubbles: Array[Dictionary] = []
var boss_hp := BOSS_MAX_HEALTH
var boss_hit_cooldown := 0.0
var boss_clock := 0.0
var bubble_unlocked := false
var bubble_shots: Array[Dictionary] = []
var last_checkpoint_message := ""
var waterfall_phase := ""
var waterfall_time := 0.0
var waterfall_x := 0.0
var waterfall_y := 0.0
var waterfall_velocity := Vector2.ZERO
var waterfall_boost := 0.0
var waterfall_boost_cooldown := 0.0
var waterfall_hazards: Array[Dictionary] = []
var waterfall_gold: Array[Dictionary] = []
var waterfall_gold_count := 0
var touches: Dictionary = {}
var simulated_touch := false
var ocean_life: Node2D
var ocean_feedback: Node2D
var swim_audio_clock := 0.0
var music_player: AudioStreamPlayer
var native_rig: Node2D
var native_fx: Node2D
var native_boss: Node2D
var animated_enemies: Node2D
var performance_overlay: CanvasLayer
var premium_hud: CanvasLayer
var water_surface: Node2D
var waterfall_models: Array[Dictionary] = []
var waterfall_enemies: Node2D
var waterfall_world: Node2D
var environment_landmarks: Node2D
var world_depth: Node2D
var foreground_depth: Node2D
var relief_obstacles: Node2D
var high_depth_quality := true
var reduced_fx := false
var music_muted := false
var joy_last: Dictionary = {}
var active_joy := -1
var touch_vectors: Dictionary = {}
var jump_effects: Node2D
var leap_air_time := 0.0
var leap_spin_direction := 1.0
var leap_phase := ""
var jump_buffer := 0.0
var splash_window := 0.0
var splash_chain := 0
var fire_cooldown := 0.0
var checkpoint_snapshot: Dictionary = {}
var boss_phase := "windup"
var boss_phase_time := 0.0
var boss_pattern := 0
var boss_target := Vector2.ZERO
var boss_position := Vector2(Highland.BOSS_X, 570)
var hostile_shots: Array[Dictionary] = []
var retry_serial := 0
var music_tween: Tween

func _ready() -> void:
    if get_node("/root/AdventureRun").tutorial_complete: bubble_unlocked = true
    obstacles = _stage_obstacles()
    enemies = _stage_enemies()
    treasures = _stage_treasure()
    music_player = AudioStreamPlayer.new()
    music_player.stream = MUSIC
    music_player.bus = "Music"
    music_player.volume_db = -17.0
    if music_player.stream is AudioStreamMP3:
        music_player.stream.loop = true
    add_child(music_player)
    # Headless Godot 4.4 has an MP3 playback shutdown leak. Play only with a real display.
    # This does not mute desktop, Android or browser releases.
    if DisplayServer.get_name() != "headless" and not OS.has_environment("GODOT_CAPTURE_PREVIEW"):
        music_player.play()
    # Godot editor-authored child scenes, ready before the level controller.
    native_fx = get_node("NativeUnderwaterFX")
    native_rig = get_node("SarahAtlasRig")
    jump_effects = get_node("JumpChoreographyFX")
    native_boss = get_node("CarloNativeBoss")
    animated_enemies = get_node("AnimatedEnemySprites")
    animated_enemies.bind_enemies(enemies)
    waterfall_enemies = get_node("WaterfallEnemySprites")
    for hazard in Highland.waterfall_hazards():
        waterfall_models.append({"kind": hazard["kind"], "x": 0.0, "y": -1000.0,
            "hp": 1, "phase": float(waterfall_models.size()), "mode": "patrol",
            "dir": -1 if float(hazard["x"]) > 0.0 else 1})
    waterfall_enemies.bind_enemies(waterfall_models)
    performance_overlay = get_node("PerformanceOverlay")
    premium_hud = get_node("PremiumHud")
    water_surface = get_node("PaintedWaterSurface")
    waterfall_world = get_node("PaintedWaterfallCavern")
    environment_landmarks = get_node("EnvironmentLandmarks")
    world_depth = get_node("PaintedWorldDepth")
    foreground_depth = get_node("SparseForegroundDepth")
    relief_obstacles = get_node("ReliefReefObstacles")
    ocean_life = preload("res://godot/ocean_life.gd").new()
    ocean_feedback = preload("res://godot/ocean_feedback.gd").new()
    add_child(ocean_life)
    add_child(ocean_feedback)
    get_node("/root/OceanAudio").set_chapter(_stage_index())
    process_mode = Node.PROCESS_MODE_ALWAYS
    for child in get_children():
        child.process_mode = Node.PROCESS_MODE_PAUSABLE
    premium_hud.process_mode = Node.PROCESS_MODE_ALWAYS
    performance_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
    get_viewport().size_changed.connect(_on_viewport_resized)
    _save_checkpoint()
    var preferences := get_node_or_null("/root/AppPreferences")
    if preferences:
        reduced_fx = preferences.reduced_motion
        high_depth_quality = not preferences.economy
        native_fx.set_reduced_motion(reduced_fx)
        native_rig.reduced_motion = reduced_fx
        native_boss.reduced_motion = reduced_fx
    premium_hud.menu_requested.connect(_return_to_menu)
    get_node("/root/SceneFlow").failed.connect(func(message: String): _say(message, 5.0))
    if _stage_index()!=7 and get_node("/root/AdventureRun").avina_along:
        avina = preload("res://godot/avina_companion.gd").new()
        add_child(avina)
        avina.bind(self)
        avina.say("Sa-sa!",2.5)
    _apply_visual_quality()
    _sync_native_visuals()
    queue_redraw()

func _exit_tree() -> void:
    # Headless CI must release MP3 playback explicitly before ResourceCache cleanup.
    if is_instance_valid(music_player):
        music_player.stop()
        music_player.stream = null

func _return_to_menu() -> void:
    # Returning from a paused scene must release the shared scene-tree pause.
    get_tree().paused = false
    touches.clear()
    touch_vectors.clear()
    get_node("/root/SceneFlow").go("res://godot/title_screen.tscn", "Back to the lagoon", "Every adventure leaves a little wonder.")

func _input(event: InputEvent) -> void:
    if get_node("/root/SceneFlow").busy: return
    if event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_ESCAPE, KEY_P:
                if state != "victory":
                    _toggle_pause()
            KEY_R:
                _restart()
            KEY_SPACE:
                _boost()
            KEY_J, KEY_SHIFT:
                _jump()
            KEY_B, KEY_Z:
                _fire_bubble()
            KEY_M:
                if music_tween and music_tween.is_running():
                    music_tween.kill()
                music_muted = not music_muted
                if music_muted:
                    music_player.volume_db = -80.0
                else:
                    music_player.volume_db = -17.0
                _say("Music " + ("off" if music_muted else "on"), 1.5)
            KEY_F3:
                reduced_fx = not reduced_fx
                native_fx.set_reduced_motion(reduced_fx)
                native_rig.reduced_motion = reduced_fx
                native_boss.reduced_motion = reduced_fx
                _sync_native_visuals()
                _say("Visual effects " + ("reduced" if reduced_fx else "enabled"), 1.5)
            KEY_F4:
                high_depth_quality = not high_depth_quality
                _apply_visual_quality()
                _say("3D depth effects " + ("high" if high_depth_quality else "economy"), 1.7)
            KEY_F6:
                performance_overlay.set_monitor_visible(not performance_overlay.enabled)
            KEY_ENTER:
                if state == "victory":
                    _restart()
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if state != "playing":
            _touch_action(_touch_target(event.position))
    elif event is InputEventScreenTouch:
        if event.pressed and not event.canceled:
            var action := _touch_target(event.position)
            if action == "pad" and "pad" in touches.values(): action = ""
            touches[event.index] = action
            _set_touch(event.index, event.position, action)
            _touch_action(action)
        else:
            touches.erase(event.index)
            touch_vectors.erase(event.index)
    elif event is InputEventScreenDrag:
        if touches.get(event.index, "") == "pad":
            _set_touch(event.index, event.position, "pad")
        elif touches.get(event.index, "") in ["boost","jump","bubble"]:
            if not _touch_rect(touches[event.index],get_viewport_rect().size).grow(10).has_point(event.position):
                touches.erase(event.index)
                touch_vectors.erase(event.index)
        # A sliding action finger releases rather than taking another button.
    if is_instance_valid(premium_hud):
        premium_hud.update_hud(_hud_snapshot())
    queue_redraw()

func _touch_action(action: String) -> void:
    if action == "boost":
        _boost()
    elif action == "jump":
        _jump()
    elif action == "bubble":
        _fire_bubble()
    elif action == "pause":
        if state != "victory":
            _toggle_pause()
    elif action == "resume":
        _set_paused(false)
    elif action == "restart":
        _restart()
    elif action == "menu":
        _return_to_menu()

func _touch_target(point: Vector2) -> String:
    if premium_hud.portrait:
        return ""
    point = premium_hud.to_ui(point)
    var size: Vector2 = premium_hud.game_size
    if state != "playing":
        for action in ["resume", "restart", "menu"]:
            if action == "resume" and state == "victory":
                continue
            if premium_hud.action_rect(action).has_point(point):
                return action
        return ""
    if premium_hud.pad_rect().has_point(point):
        return "pad"
    for action in ["boost", "jump", "bubble", "pause"]:
        if action == "bubble" and not bubble_unlocked:
            continue
        if premium_hud.action_rect(action).has_point(point):
            return action
    return ""

func _touch_rect(action: String, size: Vector2) -> Rect2:
    return premium_hud.to_game(premium_hud.action_rect(action))

func _set_touch(index: int, point: Vector2, action: String) -> void:
    touches[index] = action
    if action == "pad":
        touch_vectors[index] = premium_hud.pad_vector(premium_hud.to_ui(point))

func _set_paused(paused: bool) -> void:
    if state == "victory" or (not paused and premium_hud.portrait):
        return
    state = "paused" if paused else "playing"
    touches.clear()
    touch_vectors.clear()
    jump_buffer = 0.0
    get_tree().paused = paused
    music_player.stream_paused = paused
    premium_hud.update_hud(_hud_snapshot())
    queue_redraw()

func _toggle_pause() -> void:
    _set_paused(state == "playing")

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready():
        touches.clear()
        touch_vectors.clear()
        joy_last.clear()
        if state == "playing":
            _set_paused(true)

func _controller_id() -> int:
    active_joy = Controls.controller_id(active_joy, Input.get_connected_joypads())
    return active_joy

func _input_vector() -> Vector2:
    var direction := Vector2.ZERO
    if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
        direction.x += 1.0
    if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
        direction.x -= 1.0
    if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
        direction.y += 1.0
    if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
        direction.y -= 1.0
    for vector in touch_vectors.values():
        direction += Vector2(vector)
    var device := _controller_id()
    if device >= 0:
        var stick := Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
        direction += Controls.radial_stick(stick)
        direction.x += float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT)) - float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT))
        direction.y += float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN)) - float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP))
    return direction.limit_length(1.0)

func _poll_gamepad() -> void:
    var device := _controller_id()
    if device < 0:
        joy_last.clear()
        return
    var buttons := {
        "jump": Input.is_joy_button_pressed(device, JOY_BUTTON_A),
        "boost": Input.is_joy_button_pressed(device, JOY_BUTTON_B),
        "bubble": Input.is_joy_button_pressed(device, JOY_BUTTON_X),
        "pause": Input.is_joy_button_pressed(device, JOY_BUTTON_START)
    }
    for action in buttons:
        if buttons[action] and not joy_last.get(action, false):
            if action == "jump":
                if state == "victory": _restart()
                else: _jump()
            elif action == "boost":
                _boost()
            elif action == "bubble":
                _fire_bubble()
            elif action == "pause" and state != "victory":
                _toggle_pause()
    joy_last = buttons

func _vibrate(soft: float, strong: float, duration: float) -> void:
    var device := _controller_id()
    if device >= 0:
        Input.start_joy_vibration(device, soft, strong, duration)

func _boost() -> void:
    if state != "playing" or energy < 0.4:
        return
    if waterfall_phase != "":
        if waterfall_phase != "descent" or waterfall_boost_cooldown > 0.0:
            return
        energy -= 0.4
        var direction := _input_vector()
        if direction == Vector2.ZERO:
            direction = boost_direction
        boost_direction = direction
        waterfall_velocity = Vector2(direction.x * BOOST_SPEED / 520.0, direction.y * BOOST_SPEED)
        waterfall_boost = 0.30
        waterfall_boost_cooldown = 0.46
        native_fx.splash(_hero_screen_position(), Color("#92ffff"), 13)
        _sfx("boost")
        _vibrate(0.25, 0.08, 0.12)
        return
    if boost_cooldown > 0.0 or jump_time > 0.0:
        return
    energy -= 0.4
    boost_time = 0.38
    boost_cooldown = 0.55
    var direction := _input_vector()
    if direction == Vector2.ZERO:
        direction = Vector2(facing, 0)
    boost_direction = direction
    player_velocity = direction * BOOST_SPEED
    native_fx.splash(_hero_screen_position(), Color("#b4ffff"), 15)
    _ocean_event("boost",player,boost_direction)
    _vibrate(0.18, 0.07, 0.10)

func _jump() -> void:
    if state != "playing" or waterfall_phase != "":
        return
    if leap_phase != "":
        jump_buffer = 0.22
        return
    if splash_window > 0.0 and splash_chain < 3:
        _begin_leap(true)
    elif leap_cooldown <= 0.0 and energy >= 0.4:
        _begin_leap(false)

func _begin_leap(chained: bool) -> void:
    if not chained:
        energy -= 0.4
        splash_chain = 0
    else:
        splash_chain += 1
        _award("jump:%s:%s" % [time,splash_chain],"Acrobatics",100*splash_chain,player,false)
        _say("Splash chain! +" + str(100 * splash_chain), 1.0)
    leap_phase = "ascent"
    leap_air_time = 0.0
    leap_spin_direction = facing
    _sfx("splash")
    native_rig.start_jump(splash_chain, facing)
    jump_time = 10.0
    jump_buffer = 0.0
    splash_window = 0.0
    leap_cooldown = 0.0
    player_velocity = Vector2(maxf(absf(player_velocity.x), 240.0) * facing, -780.0)
    native_fx.splash(_hero_screen_position(), Color("#e2ffff"), 22)
    _vibrate(0.24, 0.06, 0.14)

func _fire_bubble() -> void:
    if state != "playing" or not bubble_unlocked or waterfall_phase != "":
        return
    if fire_cooldown > 0.0 or bubble_shots.size() >= 8:
        return
    _sfx("bubble")
    native_rig.play_gesture("cast")
    fire_cooldown = 0.20
    bubble_shots.append({"pos": player + Vector2(facing * 70, 0), "direction": facing, "life": 1.8})
    if is_instance_valid(avina): avina.request_bubble()
    native_fx.splash(_hero_screen_position() + Vector2(facing * 56, 0), Color("#b4dbff"), 7)

func _award(id: String, category: String, amount: int, at: Vector2, chain: bool) -> void:
    var reward: Dictionary = score_book.award(id,category,amount,chain)
    if reward.is_empty(): return
    score += int(reward["points"])
    if is_instance_valid(avina) and category in ["Treasure","Secrets","Pearls"] and avina.speech_time<=0:
        avina.say("Ooooh!",1.7)
    if category == "Boss":
        _ocean_event("boss_defeat" if amount >= 1000 else "boss_hit",at)
    elif category == "Enemies": _ocean_event("impact",at)
    elif category in ["Treasure","Secrets"]: _ocean_event("treasure",at)
    elif category == "Pearls": _ocean_event("pearl",at)

    if is_instance_valid(premium_hud):
        premium_hud.show_reward(reward,at-Vector2(camera,0))

func _complete_score() -> void:
    var prefs = get_node("/root/AppPreferences")
    var result: Dictionary = score_book.complete(score,picked_count,prefs.best_score)
    score = int(result["total"])
    prefs.best_score = int(result["best"])
    prefs.save()
    _sfx("victory",3)

func _say(text: String, duration: float = 3.0) -> void:
    message = text
    message_time = duration

func _process(_delta: float) -> void:
    if state != "playing":
        return
    _sync_native_visuals()
    if is_instance_valid(avina) and not get_tree().paused: avina.tick(_delta)
    queue_redraw()

func _physics_process(dt: float) -> void:
    _poll_gamepad()
    if state != "playing":
        return
    var serial := retry_serial
    if _action_held("boost"):
        _boost()
    if _action_held("bubble"):
        _fire_bubble()
    score_book.tick(dt)
    time += dt
    swim_audio_clock += dt
    if swim_audio_clock > 0.72 and player_velocity.length() > 160 and boost_time <= 0 and leap_phase == "":
        _sfx("swim",0)
        swim_audio_clock = 0

    invulnerable = maxf(0.0, invulnerable - dt)
    boost_time = maxf(0.0, boost_time - dt)
    boost_cooldown = maxf(0.0, boost_cooldown - dt)
    jump_buffer = maxf(0.0, jump_buffer - dt)
    splash_window = maxf(0.0, splash_window - dt)
    fire_cooldown = maxf(0.0, fire_cooldown - dt)
    leap_cooldown = maxf(0.0, leap_cooldown - dt)
    boss_hit_cooldown = maxf(0.0, boss_hit_cooldown - dt)
    energy = minf(1.0, energy + dt * 0.23)
    message_time = maxf(0.0, message_time - dt)
    if waterfall_phase != "":
        _update_waterfall(dt)
    else:
        _update_swimming(dt)
        if state != "playing": return
        _update_enemies(dt)
        if retry_serial != serial:
            return
        _update_collectibles()
        _update_boss(dt)
        if retry_serial != serial:
            return
        _update_bubbles(dt)
        _update_hostile_shots(dt)
        _check_checkpoints()
    var view := get_viewport_rect().size
    # Cinematic anticipation: the view looks ahead in Sarah's direction of travel.
    var anticipation := 0.0 if waterfall_phase != "" else clampf(player_velocity.x * 0.18, -100.0, 160.0)
    var camera_target := clampf(player.x - view.x * 0.43 + anticipation, 0.0, maxf(0.0, _level_length() - view.x))
    camera = lerpf(camera, camera_target, 1.0 - exp(-dt * (7.2 if boost_time > 0.0 else 5.8)))
    # Presentation is refreshed once per rendered frame in _process().

func _hero_screen_position() -> Vector2:
    if waterfall_phase == "":
        return player - Vector2(camera, 0.0)
    var viewport := get_viewport_rect().size
    var half := minf(viewport.x * 0.40, 520.0)
    var pos := Vector2(viewport.x * 0.5 + waterfall_x * half, 384.0 + waterfall_y)
    if waterfall_phase == "pull":
        return (player - Vector2(camera, 0.0)).lerp(pos, clampf(waterfall_time / Highland.FALL_ENTRY, 0.0, 1.0))
    return pos

func _apply_visual_quality() -> void:
    environment_landmarks.set_quality(high_depth_quality)
    native_fx.set_quality(high_depth_quality)
    world_depth.set_quality(high_depth_quality)
    relief_obstacles.set_quality(high_depth_quality)
    # Lights are the costliest effects on lower-powered/mobile GPUs.
    native_rig.set_quality(high_depth_quality)
    native_rig.hero_light.enabled = high_depth_quality
    native_boss.light.enabled = high_depth_quality

func _hud_snapshot() -> Dictionary:
    return {
        "health": health,
        "energy": energy,
        "score": score,
        "combo":score_book.multiplier,
        "combo_left":score_book.combo_left,
        "results":score_book.result,
        "reduced":reduced_fx,
        "cooldowns":{"boost":waterfall_boost_cooldown if waterfall_phase == "descent" else boost_cooldown,"jump":leap_cooldown,"bubble":fire_cooldown},
        "pearls": picked_count,
        "chapter": _chapter_name(), "boss_name": _boss_name(), "next_stage": _next_stage_name(),
        "progress": clampf(player.x / _level_length(), 0.0, 1.0),
        "message": message,
        "message_time": message_time,
        "boss_active": player.x > _boss_home() - 850.0 and boss_hp > 0,
        "boss_health": float(boss_hp) / float(_boss_max_health()),
        "boss_vulnerable": _boss_vulnerable(),
        "bubble": bubble_unlocked,
        "paused": state == "paused",
        "victory": state == "victory",
        "touch": simulated_touch or DisplayServer.is_touchscreen_available(),
        "pressed": touches.values(),
        "pad": _touch_direction(),
        "boss_phase": boss_phase,
        "boss_pattern": boss_pattern,
        "waterfall": waterfall_phase,
        "fall_progress": clampf(waterfall_time / 17.0, 0.0, 1.0) if waterfall_phase == "descent" else (1.0 if waterfall_phase == "outflow" else 0.0)
    }

func _sync_native_visuals() -> void:
    if is_instance_valid(ocean_life):
        ocean_life.set_world(camera,_water_line(),player,_stage_index(),reduced_fx,not high_depth_quality,waterfall_phase == "")
        ocean_feedback.camera = camera
        ocean_feedback.reduced = reduced_fx
        ocean_feedback.active = waterfall_phase == ""
    RenderingServer.global_shader_parameter_set("gameplay_time", time)
    if not is_instance_valid(native_rig) or not is_instance_valid(native_fx):
        return
    var pos := _hero_screen_position()
    native_rig.position = pos
    var waterfall_active := waterfall_phase != ""
    var waterfall_half := minf(get_viewport_rect().size.x*.40,520.0)
    var velocity := waterfall_velocity * Vector2(waterfall_half, 1.0) if waterfall_active else player_velocity
    var faded := 1.0 if invulnerable <= 0.0 else 0.65 + 0.35 * absf(sin(time * 13.0))
    native_rig.set_steering(_input_vector())
    native_rig.set_waterfall_context(waterfall_phase)
    native_rig.set_motion(velocity, facing, boost_time > 0.0 or waterfall_boost > 0.0, jump_time > 0.0, faded)
    native_rig.set_jump_state(leap_phase, leap_air_time, splash_chain, leap_spin_direction)
    native_rig.position.y += native_rig.airborne_clearance(pos.y)
    var fin_world: Vector2 = native_rig.fin_anchor_global() + Vector2(camera,0)
    jump_effects.update_jump(fin_world, camera, leap_phase, time, reduced_fx, high_depth_quality)
    # Depth shaders affect scenery without refracting Sarah or covering the HUD.
    # During the waterfall, render the refractive field in front of the shaft.
    native_fx.z_index = -1
    waterfall_world.set_phase(waterfall_phase, waterfall_time, reduced_fx, high_depth_quality)
    native_fx.set_motion(pos, velocity, jump_time <= 0.0)
    if is_instance_valid(animated_enemies):
        animated_enemies.animate_visible(camera, time, reduced_fx,
            get_process_delta_time(), not waterfall_active, high_depth_quality)
    if waterfall_phase == "descent":
        var half := minf(get_viewport_rect().size.x * 0.4, 520.0)
        for i in range(waterfall_hazards.size()):
            var hazard: Dictionary = waterfall_hazards[i]
            var hazard_pos := Combat.waterfall_position(hazard,waterfall_time,get_viewport_rect().size.x,half)
            waterfall_models[i]["x"] = hazard_pos.x
            waterfall_models[i]["y"] = hazard_pos.y
            for key in ["mode","mode_time","aim","dir"]:
                if hazard.has(key): waterfall_models[i][key] = hazard[key]
            waterfall_models[i]["hp"] = 0 if hazard["passed"] else 1
    waterfall_enemies.animate_visible(0.0, time, reduced_fx, get_process_delta_time(),
        waterfall_phase == "descent", high_depth_quality)
    if is_instance_valid(world_depth):
        world_depth.visible = waterfall_phase != "descent"
        world_depth.set_camera(camera, fallen or waterfall_phase == "outflow", reduced_fx)
    if is_instance_valid(foreground_depth):
        foreground_depth.set_camera(camera, not waterfall_active, reduced_fx)
    if is_instance_valid(relief_obstacles):
        relief_obstacles.set_camera(camera, not waterfall_active)
    if is_instance_valid(water_surface):
        water_surface.set_scene(camera, not waterfall_active, reduced_fx)
    environment_landmarks.set_scene(camera, fallen, waterfall_active, boss_hp <= 0, reduced_fx)
    native_fx.set_depth_profile(fallen)
    if is_instance_valid(premium_hud):
        premium_hud.update_hud(_hud_snapshot())
    if is_instance_valid(native_boss):
        var boss_x := boss_position.x - camera
        var boss_y := boss_position.y
        native_boss.set_boss_state(boss_hp, _boss_vulnerable(), boss_clock, boss_x, boss_y, get_viewport_rect().size.x, boss_phase, boss_pattern)

func _update_swimming(dt: float) -> void:
    var input_dir := _input_vector()
    var previous := player
    if absf(input_dir.x) > 0.08:
        facing = signf(input_dir.x)
    if leap_phase == "ascent":
        player_velocity.x = move_toward(player_velocity.x, input_dir.x * 420.0, dt * 400.0)
        player_velocity.y = -780.0
        player += player_velocity * dt
        if player.y <= _water_line() - 12.0:
            leap_phase = "airborne"
            leap_air_time = 0.0
            jump_effects.emit_surface(Vector2(player.x, _water_line()), splash_chain, false)
            player_velocity.y = -700.0
    elif leap_phase == "airborne":
        leap_air_time += dt
        player_velocity.y += 1250.0 * dt
        player_velocity.x = move_toward(player_velocity.x, input_dir.x * 420.0, dt * 400.0)
        player += player_velocity * dt
        if player.y >= _water_line() + 40.0 and player_velocity.y > 0.0:
            player.y = _water_line() + 45.0
            leap_phase = ""
            _sfx("splash")
            native_rig.land_jump()
            jump_effects.emit_surface(Vector2(player.x, _water_line()), splash_chain, true)
            jump_time = 0.0
            splash_window = 0.24
            leap_cooldown = 0.35
            native_fx.splash(_hero_screen_position(), Color("#e2ffff"), 18)
            if jump_buffer > 0.0 and splash_chain < 3:
                _begin_leap(true)
    elif boost_time > 0.0:
        player += player_velocity * dt
    else:
        player_velocity = SarahMotion.swim_velocity(player_velocity,input_dir,dt)
        player += player_velocity * dt
    player.x = clampf(player.x, _left_bound(), _level_length() - 40.0)
    if player.y < 80.0:
        player.y = 80.0
        player_velocity.y = maxf(player_velocity.y, 0.0)
    player.y = clampf(player.y, 80.0 if leap_phase != "" else _water_line() + 45.0, BOTTOM - 26.0)
    var collision := _move_around_rocks(previous, player)
    player = collision["position"]
    player_velocity = collision["velocity"]
    if collision["hit_y"] and leap_phase == "ascent":
        leap_phase = ""
        jump_time = 0.0
        leap_cooldown = 0.25
        native_rig.reset_jump()
        jump_effects.reset_jump()
        player = RockCollision.recover(player, obstacles, HERO_RADIUS * 0.73, _swim_bounds())
    if _has_waterfall() and not fallen and player.x >= Highland.WATERFALL_START and leap_phase == "":
        _start_waterfall()
        return
    if player.x >= _portal_x() and boss_hp <= 0:
        _complete_score()
        state = "victory"
        native_rig.set_motion(Vector2.ZERO,facing,false,false,1.0)
        native_rig.set_jump_state("",0.0,0,facing)
        native_rig.play_gesture("celebrate")
        touches.clear()
        touch_vectors.clear()
        _say("Highland Gold complete! Mermaid Bubble unlocked.", 1000.0)
        get_tree().paused = true
        music_player.stream_paused = true
        premium_hud.update_hud(_hud_snapshot())
        queue_redraw()

func _check_checkpoints() -> void:
    var positions := [
        [2770.0, "Waterfall inlet"],
        [Highland.route_x(6500.0), "Secret Grotto"],
        [Highland.route_x(9050.0), "Kelp Cathedral"],
        [Highland.route_x(11700.0), "Shell Ruins"],
        [Highland.route_x(13720.0), "Carlo's Court"]
    ]
    for item in positions:
        if player.x > float(item[0]) and checkpoint < float(item[0]):
            checkpoint = float(item[0])
            health = MAX_HEALTH
            _save_checkpoint()
            _say("Checkpoint: " + String(item[1]))
    if player.x > _boss_home() - 900 and checkpoint < _boss_home() - 1000:
        checkpoint = _boss_home() - 900
        _save_checkpoint()
        _say("Checkpoint: Carlo's arena")

func _update_enemies(dt: float) -> void:
    var serial := retry_serial
    for enemy in enemies:
        if int(enemy["hp"]) <= 0 or absf(float(enemy["x"]) - player.x) > 1200.0:
            continue
        var event := Combat.step(enemy, player, time, dt, obstacles)
        if event == "fire":
            _spawn_hostile(Vector2(enemy["x"], enemy["y"]), Vector2(enemy["aim"]), 290.0)
        var pos := Vector2(float(enemy["x"]), float(enemy["y"]))
        var radius := 96.0 if enemy["kind"] == "eel" else 79.0
        if String(enemy.get("mode", "patrol")) == "recover":
            radius *= 0.75
        if player.distance_to(pos) < radius and player.y > _water_line():
            if boost_time > 0.0:
                enemy["hp"] = 0
                _award("enemy:%s" % enemies.find(enemy),"Enemies",50,pos,true)
                native_fx.splash(pos - Vector2(camera, 0), Color("#e5ffce"), 17)
                _vibrate(0.22, 0.08, 0.12)
            else:
                _damage(pos)
                if retry_serial != serial:
                    return

func _update_collectibles() -> void:
    for treasure in treasures:
        if treasure["taken"]:
            continue
        var pos := Vector2(float(treasure["x"]), float(treasure["y"]))
        if player.distance_to(pos) < 59.0:
            treasure["taken"] = true
            var kind: String = treasure["kind"]
            if kind in ["heart","boost","chest"]:
                native_rig.play_gesture("reward")
            if kind == "heart":
                health = mini(MAX_HEALTH, health + 1)
                _ocean_event("heart",pos)
                _say("Heart restored!", 1.3)
            elif kind == "boost":
                energy = 1.0
                _ocean_event("heart",pos)
                _say("Boost crystal!", 1.3)
            else:
                _award("pickup:%s" % treasures.find(treasure),"Treasure" if kind == "chest" else "Pearls",100 if kind == "chest" else 10,pos,true)
                picked_count += 1
                if kind == "chest":
                    _say("Treasure chest! +100", 1.4)
                    native_fx.splash(pos - Vector2(camera, 0), Color("#ffeaaa"), 29)
                elif picked_count % 5 == 0:
                    native_fx.splash(pos - Vector2(camera, 0), Color("#b2feff"), 12)

func _damage(from_pos: Vector2) -> void:
    if invulnerable > 0.0 or state != "playing" or player.y < _water_line():
        return
    _ocean_event("impact",player)
    score_book.damage_taken += 1
    health -= 1
    invulnerable = 1.5
    player_velocity = (player - from_pos).normalized() * 240.0
    _say("Ouch! Careful, Sarah.", 1.6)
    native_fx.flash(Color("#ff9bad"), 0.27, 0.33)
    native_fx.splash(_hero_screen_position(), Color("#ffc1cb"), 14)
    native_rig.play_impact()
    _vibrate(0.65, 0.42, 0.20)
    if health <= 0:
        _respawn()

func _save_checkpoint() -> void:
    if not checkpoint_snapshot.is_empty(): _ocean_event("checkpoint",Vector2(checkpoint,player.y))
    checkpoint_snapshot = {
        "ledger":score_book.checkpoint(), "score": score, "picked": picked_count, "treasures": treasures.duplicate(true),
        "enemies": enemies.duplicate(true), "boss_hp": boss_hp, "bubble": bubble_unlocked
    }

func _respawn() -> void:
    retry_serial += 1
    if not checkpoint_snapshot.is_empty():
        score_book.rollback(checkpoint_snapshot.get("ledger",{}))
        premium_hud.clear_feedback()
        score = int(checkpoint_snapshot["score"])
        picked_count = int(checkpoint_snapshot["picked"])
        treasures.assign(checkpoint_snapshot["treasures"].duplicate(true))
        enemies.assign(checkpoint_snapshot["enemies"].duplicate(true))
        animated_enemies.bind_enemies(enemies)
        boss_hp = int(checkpoint_snapshot["boss_hp"])
        bubble_unlocked = bool(checkpoint_snapshot["bubble"])
    _reset_transients()
    health = MAX_HEALTH
    energy = 1.0
    fallen = checkpoint >= Highland.WATERFALL_EXIT
    player = Vector2(checkpoint, 480.0)
    camera = maxf(0.0, player.x - get_viewport_rect().size.x * 0.43)
    invulnerable = 2.0
    native_boss.reset_boss()
    if not music_muted:
        music_player.volume_db = -17.0
    _say("Back to your checkpoint!", 2.6)

func _reset_transients() -> void:
    if music_tween and music_tween.is_running():
        music_tween.kill()
    leap_phase = ""
    jump_time = 0.0
    jump_buffer = 0.0
    splash_window = 0.0
    splash_chain = 0
    leap_air_time = 0.0
    native_rig.reset_jump()
    native_rig.reset_performance()
    jump_effects.reset_jump()
    leap_cooldown = 0.0
    boost_time = 0.0
    boost_cooldown = 0.0
    waterfall_phase = ""
    waterfall_boost = 0.0
    waterfall_boost_cooldown = 0.0
    waterfall_time = 0.0
    waterfall_gold_count = 0
    player_velocity = Vector2.ZERO
    boost_direction = Vector2.RIGHT
    facing = 1.0
    touches.clear()
    touch_vectors.clear()
    bubble_shots.clear()
    hostile_shots.clear()
    fire_cooldown = 0.0
    boss_clock = 0.0
    boss_phase = "windup"
    boss_phase_time = 0.0
    boss_pattern = 0
    boss_position = Vector2(_boss_home(), 570)
    boss_target = boss_position
    boss_hit_cooldown = 0.0
    native_fx.reset_transients()
    if is_instance_valid(ocean_feedback): ocean_feedback.clear()

func _update_boss(dt: float) -> void:
    if player.x < _boss_home() - 850.0 or boss_hp <= 0:
        return
    var serial := retry_serial
    boss_clock += dt
    boss_phase_time += dt
    if boss_phase == "windup":
        if boss_phase_time <= dt:
            boss_target = player
        if boss_phase_time >= 0.95:
            boss_phase = "attack"
            boss_phase_time = 0.0
            if boss_pattern == 1:
                var aim := (boss_target - boss_position).normalized()
                for angle in [-0.24, 0.0, 0.24]:
                    _spawn_hostile(boss_position, aim.rotated(angle), 360.0)
    elif boss_phase == "attack":
        if boss_pattern == 2:
            boss_position = boss_position.move_toward(boss_target, 530.0 * dt)
            boss_position.x = clampf(boss_position.x, _boss_home() - 680.0, _boss_home() + 70.0)
            boss_position.y = clampf(boss_position.y, _water_line() + 190.0, BOTTOM - 180.0)
        if boss_pattern == 0 and player.distance_to(boss_position) < 280.0:
            _damage(boss_position)
            if retry_serial != serial:
                return
        if boss_phase_time >= 0.65:
            boss_phase = "recover"
            boss_phase_time = 0.0
    elif boss_phase_time >= 2.1:
        boss_phase = "windup"
        boss_phase_time = 0.0
        boss_pattern = (boss_pattern + 1) % 3
        boss_target = player
    if boss_phase != "attack":
        boss_position = boss_position.move_toward(Vector2(_boss_home(), 570), 190.0 * dt)
    if player.distance_to(boss_position) < 180.0 and player.y > _water_line():
        if boost_time > 0.0 and _boss_vulnerable() and boss_hit_cooldown <= 0.0:
            boss_hp -= 1
            boss_hit_cooldown = 2.2
            invulnerable = 0.65
            _award("boss-hit:%s" % boss_hp,"Boss",200,boss_position,false)
            native_boss.play_hit()
            native_fx.splash(boss_position - Vector2(camera, 0), Color("#fff1a4"), 32)
            _vibrate(0.32, 0.40, 0.22)
            if boss_hp == 0:
                _award("boss-defeat","Boss",1000,boss_position,false)
                bubble_unlocked = true
                hostile_shots.clear()
                _say("Carlo defeated! Mermaid Bubble unlocked. Find the portal!", 5.0)
                native_boss.defeat()
            else:
                _say("Carlo hit! " + str(boss_hp) + " hearts remaining.", 1.2)
        elif boost_time <= 0.0 and boss_phase != "recover":
            _damage(boss_position)

func _boss_vulnerable() -> bool:
    return boss_hp > 0 and boss_phase == "recover"

func _spawn_hostile(pos: Vector2, direction: Vector2, speed: float) -> void:
    if hostile_shots.size() < 32:
        hostile_shots.append({"pos": pos, "velocity": direction * speed, "life": 2.8})

func _update_hostile_shots(dt: float) -> void:
    var serial := retry_serial
    for shot in hostile_shots:
        shot["pos"] = Vector2(shot["pos"]) + Vector2(shot["velocity"]) * dt
        shot["life"] = float(shot["life"]) - dt
        var pos := Vector2(shot["pos"])
        for obstacle in obstacles:
            if obstacle.grow(12).has_point(pos):
                shot["life"] = 0.0
        if float(shot["life"]) > 0.0 and player.distance_to(pos) < 48.0:
            shot["life"] = 0.0
            if boost_time <= 0.0:
                _damage(pos)
                if retry_serial != serial:
                    return
            else:
                native_fx.splash(pos - Vector2(camera, 0), Color("#b5ffdc"), 8)
    hostile_shots = hostile_shots.filter(func(shot): return float(shot["life"]) > 0.0)

func _touch_direction() -> Vector2:
    var result := Vector2.ZERO
    for vector in touch_vectors.values():
        result += Vector2(vector)
    return result.limit_length(1.0)

func _update_bubbles(dt: float) -> void:
    for shot in bubble_shots:
        shot["pos"] = Vector2(shot["pos"]) + Vector2(float(shot["direction"]) * 700.0 * dt, 0)
        shot["life"] = float(shot["life"]) - dt
        for obstacle in obstacles:
            if obstacle.grow(20).has_point(Vector2(shot["pos"])):
                shot["life"] = 0.0
        if float(shot["life"]) <= 0.0:
            continue
        for enemy in enemies:
            if int(enemy["hp"]) <= 0:
                continue
            if Vector2(shot["pos"]).distance_to(Vector2(float(enemy["x"]), float(enemy["y"]))) < 70.0:
                enemy["hp"] = 0
                shot["life"] = 0.0
                _award("enemy:%s" % enemies.find(enemy),"Enemies",50,Vector2(enemy["x"],enemy["y"]),true)
                break
    bubble_shots = bubble_shots.filter(func(shot): return float(shot["life"]) > 0.0)

func _start_waterfall() -> void:
    get_node("/root/OceanAudio").set_chapter(_stage_index(),true)
    waterfall_phase = "pull"
    waterfall_time = 0.0
    waterfall_x = 0.0
    waterfall_y = 0.0
    waterfall_velocity = Vector2.ZERO
    waterfall_hazards = Highland.waterfall_hazards()
    waterfall_gold = Highland.waterfall_gold()
    waterfall_gold_count = 0
    checkpoint = 2770.0
    _save_checkpoint()
    waterfall_boost = 0.0
    waterfall_boost_cooldown = 0.0
    boost_time = 0.0
    player_velocity = Vector2.ZERO
    _say("Into the waterfall!", 1.2)
    native_fx.flash(Color("#a5ffff"), 0.30, 0.90)
    if not music_muted:
        _fade_music(-23.0, 1.1)

func _update_waterfall(dt: float) -> void:
    waterfall_time += dt
    if waterfall_phase == "pull":
        if waterfall_time + 0.000001 >= Highland.FALL_ENTRY:
            waterfall_phase = "descent"
            waterfall_time = maxf(0.0, waterfall_time - Highland.FALL_ENTRY)
        return
    if waterfall_phase == "outflow":
        if waterfall_time + 0.000001 >= Highland.FALL_EXIT:
            waterfall_phase = ""
            fallen = true
            player = Vector2(Highland.WATERFALL_EXIT, 610.0)
            camera = player.x - get_viewport_rect().size.x * 0.4
            get_node("/root/OceanAudio").set_chapter(_stage_index())
            checkpoint = Highland.WATERFALL_EXIT
            _save_checkpoint()
            invulnerable = 1.5
            _say("Secret Grotto! Keep swimming right.", 4.0)
            native_fx.flash(Color("#e0ffff"), 0.18, 0.45)
            if not music_muted:
                _fade_music(-17.0, 1.0)
        return
    waterfall_boost = maxf(0.0, waterfall_boost - dt)
    waterfall_boost_cooldown = maxf(0.0, waterfall_boost_cooldown - dt)
    var direction := _input_vector()
    if direction != Vector2.ZERO:
        boost_direction = direction
        if direction.x != 0:
            facing = signf(direction.x)
    var half := minf(get_viewport_rect().size.x * 0.40, 520.0)
    var swirl := sin(waterfall_time * 1.4) * 0.18 if waterfall_time > 4.0 else 0.0
    if waterfall_boost <= 0:
        var target := Vector2(direction.x * 430.0 / half + swirl, direction.y * 430.0)
        waterfall_velocity = waterfall_velocity.lerp(target, 1.0 - exp(-dt * 9.0))
    waterfall_x = clampf(waterfall_x + waterfall_velocity.x * dt, -0.84, 0.84)
    waterfall_y = clampf(waterfall_y + waterfall_velocity.y * dt, -145.0, 205.0)
    var hero_x := get_viewport_rect().size.x * 0.5 + waterfall_x * half
    var hero_y := 384.0 + waterfall_y
    var active_attacks := 0
    for hazard in waterfall_hazards:
        if not hazard["passed"] and hazard.get("mode","") == "attack": active_attacks += 1
    for hazard in waterfall_hazards:
        if hazard["passed"]:
            continue
        var old_mode: String = hazard.get("mode","patrol")
        Combat.step_waterfall(hazard,Vector2(hero_x,hero_y),Vector2(waterfall_velocity.x*half,waterfall_velocity.y),waterfall_time,dt,get_viewport_rect().size.x,half,active_attacks == 0)
        if old_mode != "attack" and hazard.get("mode","") == "attack": active_attacks += 1
        var hazard_pos := Combat.waterfall_position(hazard,waterfall_time,get_viewport_rect().size.x,half)
        if hazard_pos.y < 94.0:
            hazard["passed"] = true
            continue
        var h_x := hazard_pos.x
        var h_y := hazard_pos.y
        var radius := 100.0 if hazard["kind"] == "reef" else 76.0
        if absf(hero_x - h_x) < radius and absf(hero_y - h_y) < 85.0:
            if waterfall_boost > 0 and hazard["kind"] != "reef":
                hazard["passed"] = true
                _award("fall-enemy:%s" % hazard["at"],"Enemies",50,Vector2(hero_x,hero_y)+Vector2(camera,0),true)
            elif invulnerable <= 0.0:
                _damage(Vector2(player.x + h_x - hero_x, player.y + h_y - hero_y))
                if waterfall_phase != "descent":
                    return
    for pearl in waterfall_gold:
        if pearl["taken"]:
            continue
        var p_x := get_viewport_rect().size.x * 0.5 + float(pearl["x"]) * half
        var p_y := 384.0 + (float(pearl["at"]) - waterfall_time) * 350.0
        if absf(hero_x - p_x) < 66.0 and absf(hero_y - p_y) < 62.0:
            pearl["taken"] = true
            waterfall_gold_count += 1
            picked_count += 1
            _award("fall-pearl:%s" % pearl["at"],"Pearls",20,Vector2(p_x,p_y)+Vector2(camera,0),true)
    if waterfall_time + 0.000001 >= Highland.FALL_DURATION:
        waterfall_phase = "outflow"
        waterfall_time = maxf(0.0, waterfall_time - Highland.FALL_DURATION)
        _say("There it is — the secret grotto!", 3.0)

func _restart() -> void:
    if state == "victory" and _advance_journey():
        return
    get_tree().paused = false
    music_player.stream_paused = false
    _reset_transients()
    retry_serial += 1
    player = Vector2(220.0, 460.0)
    player_velocity = Vector2.ZERO
    camera = 0.0
    time = 0.0
    health = MAX_HEALTH
    energy = 1.0
    score_book = ScoreBook.new()
    premium_hud.clear_feedback()
    score = 0
    picked_count = 0
    checkpoint = 220.0
    invulnerable = 0.0
    boost_time = 0.0
    boost_cooldown = 0.0
    jump_time = 0.0
    leap_cooldown = 0.0
    boss_clock = 0.0
    boss_hp = _boss_max_health()
    boss_hit_cooldown = 0.0
    if is_instance_valid(native_boss):
        native_boss.reset_boss()
    bubble_unlocked = get_node("/root/AdventureRun").tutorial_complete
    bubble_shots.clear()
    fallen = not _has_waterfall()
    waterfall_phase = ""
    touches.clear()
    obstacles = _stage_obstacles()
    enemies = _stage_enemies()
    animated_enemies.bind_enemies(enemies)
    treasures = _stage_treasure()
    state = "playing"
    _save_checkpoint()
    if not music_muted:
        music_player.volume_db = -17.0
    _say("Highland Gold — your adventure begins!", 3.0)
    if is_instance_valid(native_fx):
        native_fx.flash(Color("#d6ffff"), 0.16, 0.4)
    if is_instance_valid(premium_hud):
        premium_hud.update_hud(_hud_snapshot())
    _on_viewport_resized()

func _draw() -> void:
    var s := get_viewport_rect().size
    # Godot's native PaintedWorldDepth is the opaque 2.5D underlay.
    # Keep the solid colour as a fallback if the compositor is absent.
    if not is_instance_valid(world_depth):
        draw_rect(Rect2(Vector2.ZERO, s), Color("#09283f"))
    if waterfall_phase == "descent" or waterfall_phase == "pull" or waterfall_phase == "outflow":
        _draw_waterfall(s)
    else:
        _draw_world(s)
    # All text/UI is now drawn by PremiumHud on a separate CanvasLayer.
    # It remains crisp and remains legible above GPU post-processing.

func _draw_world(s: Vector2) -> void:
    # The backdrop and gardens now come from the GPU-shaded, depth-separated
    # Godot world plane; never repaint its source image as a second ghost layer.
    draw_rect(Rect2(0, _water_line(), s.x, s.y - _water_line()), Color(0.01, 0.17, 0.28, 0.075))
    # PaintedWaterSurface draws the 3-frequency animated specular waterline.
    for i in range(20):
        var x := fposmod(float(i) * 223.0 - camera * 0.37 + time * (9.0 + float(i % 4)), s.x + 120.0) - 50.0
        var y := _water_line() + 80.0 + fmod(float(i) * 133.0, maxf(10.0, s.y - _water_line() - 90.0))
        draw_circle(Vector2(x, y), 2.5 + float(i % 3), Color(0.72, 1.0, 0.97, 0.34))
    for treasure in treasures:
        if treasure["taken"]:
            continue
        var x := float(treasure["x"]) - camera
        if x < -80 or x > s.x + 80:
            continue
        var y := float(treasure["y"]) + (0.0 if reduced_fx or treasure["kind"]=="chest" else sin(time * 2.0 + float(treasure["phase"])) * 5.0)
        _draw_collectible(Vector2(x, y), String(treasure["kind"]))
    for enemy in enemies:
        if int(enemy["hp"]) <= 0:
            continue
        var x := float(enemy["x"]) - camera
        if x < -200 or x > s.x + 200:
            continue
        _draw_enemy_cue(enemy, Vector2(x, float(enemy["y"])))
    if player.x > _boss_home() - s.x - 200 or camera > _boss_home() - s.x - 200:
        _draw_boss()
    for shot in hostile_shots:
        var pos := Vector2(shot["pos"]) - Vector2(camera, 0)
        draw_circle(pos, 12, Color("#ffa382"))
        draw_arc(pos, 17, 0, TAU, 16, Color("#ffe4ab"), 2)
    for shot in bubble_shots:
        var pos := Vector2(shot["pos"]) - Vector2(camera, 0)
        var baby: bool = shot.get("baby",false)
        draw_circle(pos, 14.0 if baby else 24.0, Color(0.88,0.69,1.0,0.4) if baby else Color(0.55,0.96,1.0,0.45))
        draw_arc(pos, 12.0 if baby else 20.0, 0, TAU, 40, Color("#f4daff") if baby else Color("#d9ffff"), 3.0)
    _draw_hero(player - Vector2(camera, 0))


func _draw_collectible(pos: Vector2, kind: String) -> void:
    var texture: Texture2D = collectible_art.get(kind, collectible_art["pearl"])
    var pulse := 1.0 if reduced_fx or kind=="chest" else 1.0 + sin(time * 3.1 + pos.x * 0.015) * 0.035
    var width := (80.0 if kind == "chest" else 55.0) * pulse
    var size := Vector2(width, width * texture.get_height() / texture.get_width())
    if kind=="chest":
        var pedestal := GroundArt.prop_pedestal(pos,size,pos.x+camera)
        if pedestal.has_area():
            draw_texture_rect(GroundArt.formation(2),pedestal,false,Color(.72,.88,.90))
            GroundArt.contact(self,pos+Vector2(0,size.y*.5-2),size.x,.38)
    draw_texture_rect(texture, Rect2(pos - size * 0.5, size), false)


func _draw_boss() -> void:
    if boss_hp <= 0:
        return
    var x := boss_position.x - camera
    if x < -360 or x > get_viewport_rect().size.x + 360:
        return
    var y := boss_position.y
    var glow := Color(0.28, 1.0, 0.58, 0.22) if _boss_vulnerable() else Color(1.0, 0.44, 0.47, 0.18)
    draw_circle(Vector2(x, y), 180.0, glow)
    if not is_instance_valid(native_boss):
        draw_texture_rect(CARLO, Rect2(x - 162, y - 180, 324, 352), false)
    draw_rect(Rect2(x - 140, y - 206, 280, 15), Color("#123349"))
    draw_rect(Rect2(x - 140, y - 206, 280.0 * float(boss_hp) / _boss_max_health(), 15), Color("#80ffc8") if _boss_vulnerable() else Color("#ffba8a"))
    var label: String = "BOOST NOW" if _boss_vulnerable() else ["CLAW SWEEP", "PEARL VOLLEY", "CRAB DASH"][boss_pattern]
    _draw_text(Vector2(x - 110, y - 220), label, 22, Color("#fff0d1"))
    if boss_phase == "windup":
        var origin := boss_position - Vector2(camera, 0)
        if boss_pattern == 0:
            draw_arc(origin, 280, -PI, 0, 40, Color(1, 0.64, 0.38, 0.75), 4)
        else:
            draw_line(origin, boss_target - Vector2(camera, 0), Color(1, 0.72, 0.44, 0.8), 3)

func _draw_hero(pos: Vector2) -> void:
    var opacity := 1.0 if invulnerable <= 0.0 else 0.58 + 0.42 * absf(sin(time * 13.0))
    var tilt := clampf(player_velocity.y / 1150.0, -0.30, 0.30) * facing
    var bob := sin(time * 5.0) * 3.0 if jump_time <= 0.0 else 0.0
    draw_set_transform(pos + Vector2(0, bob), tilt, Vector2(facing, 1.0))
    # The character is now a native articulated Sprite2D hierarchy; keep fallback only.
    if not is_instance_valid(native_rig):
        draw_texture_rect(HERO, Rect2(-115, -77, 230, 154), false, Color(1, 1, 1, opacity))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    if boost_time > 0.0 or waterfall_boost > 0.0:
        for i in range(5):
            draw_circle(pos - boost_direction * float(25 + i * 25), float(12 - i), Color(0.7, 1.0, 1.0, 0.23))

func _draw_waterfall(s: Vector2) -> void:
    # Backdrop, continuous walls and mist belong to PaintedWaterfallCavern.
    var half := minf(s.x * 0.40, 520.0)
    var cx := s.x * 0.5
    # Veiled currents are light, narrow and staggered. Avoid opaque overlays.
    for i in range(8):
        var fraction := float(i + 1) / 9.0
        var xx := cx + (fraction * 2.0 - 1.0) * half
        var alpha := 0.036 + float(i % 3) * 0.014
        draw_line(Vector2(xx, -25), Vector2(xx + sin(time * 0.7 + float(i)) * 22.0, s.y + 25),
            Color(0.56, 0.99, 0.96, alpha), 14.0 if i % 2 == 0 else 8.0)
    # Subtle horizontal translucency hints at distance within the waterfall.
    for i in range(4):
        var yy := float(i) * s.y * 0.26
        draw_line(Vector2(cx - half * 0.8, yy), Vector2(cx + half * 0.8, yy + 45.0),
            Color(0.34, 0.81, 0.85, 0.045), 3.0)
    for i in range(12 if reduced_fx else 28):
        var xx := cx + sin(float(i) * 6.2) * half * 0.93
        var yy := fposmod(float(i) * 91.0 - time * (0.0 if reduced_fx else 260.0), s.y + 100.0) - 50.0
        draw_line(Vector2(xx, yy), Vector2(xx + sin(time * 2.0 + float(i)) * 8.0, yy + 55), Color(0.73, 1.0, 1.0, 0.20 if i % 3 else 0.40), 2.0)
    # Dispersed spray and foam respond to the shaft's downward current.
    for i in range(6 if reduced_fx else 18):
        var shift := sin(float(i) * 8.7) * half * 0.87
        var yy := fposmod(float(i) * 71.0 + time * (0.0 if reduced_fx else 240.0), s.y + 100.0) - 50.0
        var spray_x := cx + shift + sin(time * 1.6 + float(i)) * 8.0
        draw_circle(Vector2(spray_x, yy), 2.0 + float(i % 3),
            Color(0.83, 1.0, 0.98, 0.12 + 0.08 * float(i % 2)))
    for hazard in waterfall_hazards:
        if hazard["passed"] or waterfall_phase != "descent":
            continue
        var yy := 384.0 + (float(hazard["at"]) - waterfall_time) * 350.0
        if yy < -180 or yy > s.y + 180:
            continue
        var xx := cx + float(hazard["x"]) * half
        var kind: String = hazard["kind"]
        if kind == "reef":
            draw_texture_rect(FALL_BOULDER, Rect2(xx - 115, yy - 90, 230, 180), false)
    for pearl in waterfall_gold:
        if pearl["taken"] or waterfall_phase != "descent":
            continue
        var yy := 384.0 + (float(pearl["at"]) - waterfall_time) * 350.0
        if yy < -50 or yy > s.y + 50:
            continue
        _draw_collectible(Vector2(cx + float(pearl["x"]) * half, yy), "pearl")
    var hero_pos := Vector2(cx + waterfall_x * half, 384.0 + waterfall_y)
    if waterfall_phase == "pull":
        var u := clampf(waterfall_time / Highland.FALL_ENTRY, 0.0, 1.0)
        hero_pos = (player - Vector2(camera, 0)).lerp(hero_pos, u)
    _draw_hero(hero_pos)


func _draw_hud(s: Vector2) -> void:
    draw_rect(Rect2(12, 10, s.x - 24, 79), Color(0.035, 0.13, 0.22, 0.75))
    _draw_text(Vector2(30, 46), "HIGHLAND GOLD", 27, Color("#fff2d2"))
    _draw_text(Vector2(30, 76), "Carlo's Cold Kingdom", 18, Color("#b4edee"))
    if s.x >= 1100:
        _draw_text(Vector2(s.x - 380, 72), "F3: MOTION   F4: DEPTH   M: MUSIC", 14, Color("#b4edee"))
    for i in range(MAX_HEALTH):
        draw_circle(Vector2(315.0 + float(i) * 29.0, 43.0), 11.0, Color("#ff8eb9") if i < health else Color("#465568"))
    _draw_text(Vector2(490, 48), "SCORE  " + str(score), 23, Color("#fff1bc"))
    draw_rect(Rect2(700, 29, 178, 20), Color("#25495e"))
    draw_rect(Rect2(700, 29, 178 * energy, 20), Color("#72ead9"))
    _draw_text(Vector2(705, 70), "BOOST", 18, Color("#d9fffd"))
    _draw_text(Vector2(905, 47), "PEARLS  " + str(picked_count), 21, Color("#d9fbff"))
    var progress := clampf(player.x / _level_length(), 0.0, 1.0)
    draw_rect(Rect2(12, s.y - 11, s.x - 24, 6), Color("#123a54"))
    draw_rect(Rect2(12, s.y - 11, (s.x - 24.0) * progress, 6), Color("#f7d78b"))
    if message_time > 0.0 and state == "playing":
        var width := minf(s.x - 36.0, 900.0)
        var start := (s.x - width) * 0.5
        draw_rect(Rect2(start, 118, width, 59), Color(0.025, 0.17, 0.28, 0.76))
        _draw_text(Vector2(start + 21, 155), message, 21, Color("#f3fff5"))
    if player.x > _boss_home() - 850.0 and boss_hp > 0:
        _draw_text(Vector2(s.x * 0.5 - 215, 200), "CARLO: BOOST WHEN HE GLOWS GREEN", 23, Color("#ffeed1"))
    if bubble_unlocked:
        _draw_text(Vector2(s.x - 287, 76), "B / Z : BUBBLE", 20, Color("#aeffee"))

func _draw_text(pos: Vector2, value: String, font_size: int = 23, color: Color = Color.WHITE) -> void:
    draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw_touch_controls(s: Vector2) -> void:
    for action in ["left", "right", "up", "down", "boost", "jump", "bubble", "pause"]:
        if action == "bubble" and not bubble_unlocked:
            continue
        var rect := _touch_rect(action, s)
        draw_rect(rect, Color(0.04, 0.21, 0.30, 0.70))
        var labels := {"left": "LEFT", "right": "RIGHT", "up": "UP", "down": "DOWN", "boost": "BOOST", "jump": "JUMP", "bubble": "BUBBLE", "pause": "II"}
        _draw_text(rect.position + Vector2(8, rect.size.y * 0.60), labels[action], 20, Color("#eafffa"))

func _draw_overlay(s: Vector2) -> void:
    draw_rect(Rect2(Vector2.ZERO, s), Color(0.015, 0.075, 0.11, 0.78))
    var center := s * 0.5
    var heading := "LEVEL COMPLETE" if state == "victory" else "PAUSED"
    _draw_text(center + Vector2(-160, -70), heading, 45, Color("#fff0cb"))
    _draw_text(center + Vector2(-174, -20), "Score: " + str(score) + "   |   Collected: " + str(picked_count), 25, Color("#c7fff6"))
    _draw_text(center + Vector2(-220, 33), "Press P to resume, or R to restart" if state == "paused" else "Press Enter or R to play again", 22, Color("#f1fdff"))
    if DisplayServer.is_touchscreen_available():
        var rect := _touch_rect("restart", s)
        draw_rect(rect, Color("#268d93"))
        _draw_text(rect.position + Vector2(48, 43), "RESTART", 23, Color.WHITE)

func _draw_enemy_cue(enemy: Dictionary, pos: Vector2) -> void:
    var mode := String(enemy.get("mode", "patrol"))
    if mode == "windup":
        var aim := Vector2(enemy.get("aim", Vector2.LEFT))
        draw_arc(pos, 88, -PI, PI, 32, Color(1, 0.76, 0.38, 0.85), 3)
        draw_line(pos, pos + aim * 170.0, Color(1, 0.79, 0.50, 0.72), 3)
    elif mode == "recover":
        draw_arc(pos, 73, -2.7, -0.4, 16, Color(0.58, 1, 0.78, 0.65), 2)

func _action_held(action: String) -> bool:
    if action in touches.values():
        return true
    var device := _controller_id()
    if action == "boost":
        return Input.is_key_pressed(KEY_SPACE) or (device >= 0 and Input.is_joy_button_pressed(device, JOY_BUTTON_B))
    return Input.is_key_pressed(KEY_B) or Input.is_key_pressed(KEY_Z) or (device >= 0 and Input.is_joy_button_pressed(device, JOY_BUTTON_X))

func _fade_music(volume: float, duration: float) -> void:
    if music_tween and music_tween.is_running():
        music_tween.kill()
    music_tween = create_tween().bind_node(music_player)
    music_tween.tween_property(music_player, "volume_db", volume, duration)

func _on_viewport_resized() -> void:
    touches.clear()
    touch_vectors.clear()
    if is_instance_valid(premium_hud):
        premium_hud._resize()
        if premium_hud.portrait and state == "playing":
            _set_paused(true)

func _pad_rect() -> Rect2:
    return premium_hud.to_game(premium_hud.pad_rect())

# Hooks shared by the original Highland scene and the two HTML 9.2 chapters.
func _level_length() -> float: return Highland.LEVEL_LENGTH
func _boss_home() -> float: return Highland.BOSS_X
func _portal_x() -> float: return Highland.PORTAL_X
func _boss_max_health() -> int: return BOSS_MAX_HEALTH
func _left_bound() -> float: return 50.0 if not fallen else Highland.WATERFALL_EXIT
func _has_waterfall() -> bool: return true
func _stage_obstacles() -> Array[Rect2]: return Source.obstacles_for("highland")
func _stage_enemies() -> Array[Dictionary]: return Source.enemies_for("highland")
func _stage_treasure() -> Array[Dictionary]: return Source.treasure_for("highland")
func _chapter_name() -> String: return "HIGHLAND GOLD · STAGE 1"
func _boss_name() -> String: return "CARLO THE CRAB"
func _stage_index() -> int: return 0
func _next_stage_name() -> String:
    var run := get_node_or_null("/root/AdventureRun")
    return run.next_name(_stage_index()) if run and run.active else ""
func _advance_journey() -> bool:
    if get_node("/root/SceneFlow").busy: return true
    var run := get_node_or_null("/root/AdventureRun")
    if not run or not run.active: return false
    run.complete_stage(_stage_index(), score)
    get_tree().paused = false
    var target: String = run.next_scene(_stage_index())
    if target.is_empty(): target = "res://godot/title_screen.tscn"
    var next: int = run.next_index(_stage_index())
    get_node("/root/SceneFlow").go(target, run.NAMES[next] if next >= 0 else "Adventure complete", "" if next >= 0 else "A brave heart. A whole ocean of memories.", next)
    return true

func _swim_bounds() -> Rect2:
    var top := 80.0 if leap_phase != "" else _water_line() + 45.0
    return Rect2(_left_bound(), top, _level_length() - 40.0 - _left_bound(), BOTTOM - 26.0 - top)

func _move_around_rocks(previous: Vector2, desired: Vector2) -> Dictionary:
    var bounds := _swim_bounds()
    var start := Vector2(clampf(previous.x, bounds.position.x, bounds.end.x), clampf(previous.y, bounds.position.y, bounds.end.y))
    return RockCollision.move(start, desired - start, player_velocity, obstacles, HERO_RADIUS * 0.73, bounds)

func _water_line() -> float: return WATER_SURFACE

func _sfx(effect: String, priority := 1) -> void:
    get_node("/root/OceanAudio").play(effect,priority)
func _ocean_event(effect: String, at: Vector2, direction := Vector2.RIGHT) -> void:
    _sfx(effect,3 if effect in ["boss_defeat","checkpoint"] else 1)
    if is_instance_valid(ocean_feedback): ocean_feedback.burst(at,effect,direction)

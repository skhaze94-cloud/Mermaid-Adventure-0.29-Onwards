extends Node2D
const Polish = preload("res://godot/visual_polish.gd")
const GroundArt = preload("res://godot/terrain_painter.gd")
## Sarah Maria — Highland Gold, Godot 4 playable port (prototype 0.1).
## Source of truth: dist/game.js, dist/highland.js, dist/creature-sprites-v731.js
## Import artwork and soundtrack from the SAME repository, res://dist/assets/.
const Controls = preload("res://godot/control_layout.gd")
const Combat = preload("res://godot/enemy_combat.gd")
const Source = preload("res://godot/chapter_data.gd")
const Highland = preload("res://godot/highland_data.gd")
const HERO_PATH = "res://dist/assets/sarah-mermaid.webp"
const FALL_BOULDER = preload("res://godot/assets/waterfall-boulder-v07.webp")
const CARLO_PATH = "res://dist/assets/carlo.webp"
const MUSIC = preload("res://dist/assets/bubble-bell-adventure.mp3")

const WATER_SURFACE := 280.0
const BOTTOM := 902.0
const JourneyRoute = preload("res://godot/journey_route.gd")
const HAVEN_SHELL = preload("res://godot/assets/ui-v014/shell.png")
const HERO_RADIUS := 43.0
const MAX_HEALTH := 5
const BOSS_MAX_HEALTH := 3
const RockCollision = preload("res://godot/rock_collision.gd")
const SarahMotion = preload("res://godot/sarah_motion.gd")
const SWIM_SPEED := SarahMotion.SWIM_SPEED
const BOOST_SPEED := 850.0
const OpalCombat=preload("res://godot/opal_combat.gd")
const OpalEffects=preload("res://godot/opal_effects.gd")
var opal=OpalCombat.new()
var opal_fx: Node2D
var empty_opal_switches: Array[Dictionary]=[]
@export var opal_friendly_atlas: Texture2D
@export var opal_enemy_atlas: Texture2D
@export var opal_boss_atlas: Texture2D
var opal_joy_primed:=false
var opal_joy_device:=-1

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
var message_priority := false
var save_ready := false
var checkpoint_pending := false
var checkpoint_position := Vector2(220, 480)

var obstacles: Array[Rect2] = []
var enemies: Array[Dictionary] = []
const EnvironmentArt = preload("res://godot/environment_art.gd")
var collectible_art := {"pearl": EnvironmentArt.prop("pearl"), "chest": EnvironmentArt.prop("chest"), "heart": EnvironmentArt.prop("heart"), "boost": EnvironmentArt.prop("boost")}
var treasures: Array[Dictionary] = []
var avina: Node2D
var bubbles: Array[Dictionary] = []
var boss_hp := BOSS_MAX_HEALTH
var boss_hit_cooldown := 0.0
var boss_volley = preload("res://godot/boss_volley.gd").new()
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
var journey_stops: Array[Dictionary] = []
var journey_stops_ready := false
var boss_phase := "windup"
var boss_phase_time := 0.0
var boss_pattern := 0
var boss_target := Vector2.ZERO
var boss_position := Vector2(Highland.BOSS_X, 570)
var hostile_shots: Array[Dictionary] = []
var retry_serial := 0
var music_tween: Tween
var fallback_hero: Texture2D
var fallback_boss: Texture2D

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
    opal_fx=OpalEffects.new();add_child(opal_fx);move_child(opal_fx,1)
    opal_fx.configure(_opal_art_chapter(),opal_friendly_atlas,opal_enemy_atlas,opal_boss_atlas)
    opal.bind(self)
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
    get_node("/root/AdventureRun").save_finished.connect(_on_save_finished)
    get_node("/root/SceneFlow").failed.connect(func(message: String): _say(message, 5.0))
    if _stage_index()!=7 and get_node("/root/AdventureRun").avina_along:
        avina = preload("res://godot/avina_companion.gd").new()
        add_child(avina)
        avina.bind(self)
        avina.say("Sa-sa!",2.5)
    _apply_visual_quality()
    _sync_native_visuals()
    queue_redraw()
    # Derived chapters finish their setup before any restored snapshot is applied.
    _finish_scene_setup.call_deferred()

func _finish_scene_setup() -> void:
    if not is_inside_tree(): return
    save_ready = true
    var run := get_node_or_null("/root/AdventureRun")
    if not is_instance_valid(run): return
    var saved: Dictionary = run.take_restore(_stage_index())
    if not saved.is_empty():
        if _valid_checkpoint(saved):
            checkpoint = float(saved["checkpoint"])
            checkpoint_snapshot = saved["snapshot"].duplicate(true)
            score_book.damage_taken = maxi(0, int(saved.get("damage_taken", 0)))
            _respawn()
            checkpoint_position = saved.get("position", player)
            player = RockCollision.recover(checkpoint_position, obstacles, HERO_RADIUS * .73, _swim_bounds())
            _restore_checkpoint_extras(saved.get("extra", {}))
            camera = clampf(player.x - get_viewport_rect().size.x * .43, 0, maxf(0, _level_length() - get_viewport_rect().size.x))
            _say("Welcome back, Sarah! Your checkpoint is ready.", 4.0)
        else:
            _say("Welcome back! This chapter is ready from the beginning.", 4.0)
    _persist_checkpoint()
    _sync_native_visuals()

func _valid_checkpoint(saved: Dictionary) -> bool:
    if not saved.get("checkpoint") is float and not saved.get("checkpoint") is int: return false
    var x := float(saved["checkpoint"])
    if not is_finite(x) or x < _left_bound() or x > _portal_x(): return false
    if not saved.get("snapshot") is Dictionary: return false
    var snapshot: Dictionary = saved["snapshot"]
    for key in ["ledger"]:
        if not snapshot.get(key) is Dictionary: return false
    if not snapshot["ledger"].get("categories") is Dictionary or not snapshot["ledger"].get("seen") is Dictionary: return false
    for key in ["score", "picked", "boss_hp"]:
        if not snapshot.get(key) is int or int(snapshot[key]) < 0: return false
    if int(snapshot["boss_hp"]) > _boss_max_health() or not snapshot.get("bubble") is bool: return false
    for key in ["enemies", "treasures"]:
        if not snapshot.get(key) is Array or snapshot[key].size() > 512: return false
        for item in snapshot[key]:
            if not item is Dictionary or not item.get("kind") is String: return false
            for axis in ["x", "y"]:
                if not item.get(axis) is float and not item.get(axis) is int: return false
                if not is_finite(float(item[axis])): return false
            if key == "enemies":
                if not preload("res://godot/opal_roster.gd").ENEMY_FITS.has(item["kind"]): return false
                if not item.get("hp") is int or int(item["hp"]) < 0: return false
                for axis in ["bx", "by", "phase"]:
                    if not item.get(axis) is float and not item.get(axis) is int: return false
                    if not is_finite(float(item[axis])): return false
            elif not item.get("taken") is bool or item["kind"] not in ["pearl","chest","heart","boost"]: return false
    if not saved.get("position", Vector2.ZERO) is Vector2 or not Vector2(saved.get("position", Vector2.ZERO)).is_finite(): return false
    if not saved.get("extra", {}) is Dictionary: return false
    return _valid_checkpoint_extras(saved.get("extra", {}))

func _checkpoint_extras() -> Dictionary: return {}
func _valid_checkpoint_extras(extra: Dictionary) -> bool: return true
func _restore_checkpoint_extras(_extra: Dictionary) -> void: pass

func _checkpoint_bundle() -> Dictionary:
    return {"checkpoint": checkpoint, "position": checkpoint_position,
        "snapshot": checkpoint_snapshot, "damage_taken": score_book.damage_taken,
        "extra": _checkpoint_extras()}

func _persist_checkpoint() -> void:
    checkpoint_pending = false
    if not is_inside_tree() or not save_ready or state not in ["playing", "paused"] or checkpoint_snapshot.is_empty(): return
    var run := get_node_or_null("/root/AdventureRun")
    if not is_instance_valid(run): return
    if not run.store_checkpoint(_stage_index(), _checkpoint_bundle()):
        _say(run.save_message, 6.0, true)

func _on_save_finished(success: bool) -> void:
    if not success:_say("Couldn’t save — keep the adventure open.",6.0,true)

func _exit_tree() -> void:
    opal.cancel()
    # Headless CI must release MP3 playback explicitly before ResourceCache cleanup.
    if is_instance_valid(music_player):
        music_player.stop()
        music_player.stream = null

func _return_to_menu() -> void:
    opal.cancel()
    _persist_checkpoint()
    # Returning from a paused scene must release the shared scene-tree pause.
    get_tree().paused = false
    touches.clear()
    touch_vectors.clear()
    get_node("/root/SceneFlow").go("res://godot/title_screen.tscn", "Back to the lagoon", "Every adventure leaves a little wonder.")

func _input(event: InputEvent) -> void:
    if get_node("/root/SceneFlow").busy:
        _opal_cancel_for_event(event)
        return
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
                opal.begin("key:%s" % event.keycode)
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
    elif event is InputEventKey and not event.pressed and event.keycode in [KEY_B,KEY_Z]:
        opal.release("key:%s" % event.keycode)
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if state != "playing":
            _touch_action(_touch_target(event.position))
    elif event is InputEventScreenTouch:
        if event.pressed and not event.canceled:
            var action := _touch_target(event.position)
            if action == "pad" and "pad" in touches.values(): action = ""
            touches[event.index] = action
            _set_touch(event.index, event.position, action)
            if action=="bubble":opal.begin("touch:%s" % event.index)
            else:_touch_action(action)
        else:
            if touches.get(event.index,"")=="bubble" and event.canceled:opal.cancel("touch:%s" % event.index)
            opal.release("touch:%s" % event.index)
            touches.erase(event.index)
            touch_vectors.erase(event.index)
    elif event is InputEventScreenDrag:
        if touches.get(event.index, "") == "pad":
            _set_touch(event.index, event.position, "pad")
        elif touches.get(event.index, "") in ["boost","jump","bubble"]:
            if not _touch_rect(touches[event.index],get_viewport_rect().size).grow(10).has_point(event.position):
                opal.cancel("touch:%s" % event.index)
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
    opal.cancel()
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
    if what == NOTIFICATION_WM_CLOSE_REQUEST and is_node_ready():
        _persist_checkpoint()
        var run:=get_node_or_null("/root/AdventureRun")
        if is_instance_valid(run):run.flush_saves()
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready():
        touches.clear()
        touch_vectors.clear()
        joy_last.clear()
        if state == "playing":
            _set_paused(true)
        _persist_checkpoint()

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
    var device:=_controller_id()
    var buttons:={} if device<0 else {"jump":Input.is_joy_button_pressed(device,JOY_BUTTON_A),
        "boost":Input.is_joy_button_pressed(device,JOY_BUTTON_B),"bubble":Input.is_joy_button_pressed(device,JOY_BUTTON_X),
        "pause":Input.is_joy_button_pressed(device,JOY_BUTTON_START)}
    _apply_gamepad_sample(device,buttons)
func _apply_gamepad_sample(device: int, buttons: Dictionary) -> void:
    if device!=opal_joy_device:opal_joy_device=device;opal_joy_primed=false
    if opal.charge.source_id.begins_with("joy:") and opal.charge.source_id!="joy:%s" % device:opal.cancel()
    if device<0:joy_last.clear();return
    if not opal_joy_primed:joy_last["bubble"]=buttons["bubble"];opal_joy_primed=true
    if not buttons["bubble"]:opal.suppressed.erase("joy:%s" % device)
    for action in buttons:
        if buttons[action] and not joy_last.get(action,false):
            if action=="jump":
                if state=="victory":_restart()
                else:_jump()
            elif action=="boost":_boost()
            elif action=="bubble":opal.begin("joy:%s" % device)
            elif action=="pause" and state!="victory":_toggle_pause()
        if action=="bubble" and not buttons[action] and joy_last.get(action,false):opal.release("joy:%s" % device)
    joy_last=buttons

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
        opal.cancel()
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
    opal.cancel()
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
    opal.cancel()
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
    # Programmatic quick tap; physical sources use press/hold/release.
    if opal.begin("script"):opal.release("script")
func _on_bubble_fired() -> void:pass
func _bubble_world_active() -> bool:
    return state=="playing" and not get_tree().paused and waterfall_phase=="" and not get_node("/root/SceneFlow").busy
func _bubble_context_allowed() -> bool:return _bubble_world_active() and bubble_unlocked
func _opal_cancel_for_event(event: InputEvent) -> void:
    opal.cancel()
    if event is InputEventKey and not event.pressed and event.keycode in [KEY_B,KEY_Z]:opal.suppressed.erase("key:%s" % event.keycode)
    elif event is InputEventScreenTouch and not event.pressed:opal.suppressed.erase("touch:%s" % event.index)

func _award(id: String, category: String, amount: int, at: Vector2, chain: bool) -> void:
    var reward: Dictionary = score_book.award(id,category,amount,chain)
    if reward.is_empty(): return
    score += int(reward["points"])
    if is_instance_valid(avina) and category in ["Treasure","Secrets","Pearls"] and avina.speech_time<=0:
        avina.say("Ooooh!",1.7)
    if category == "Boss":
        var clear := id in ["boss-defeat","boss:clear","training:dad:clear"] or id.begins_with("boss:clear:")
        reward["boss_clear"]=clear
        _ocean_event("boss_defeat" if clear else "boss_hit",at)
        if clear:
            boss_volley.clear()
            hostile_shots.clear()
            energy=1.0
            invulnerable=maxf(invulnerable,1.2)
            _say("Royal trial complete! Talk to your family." if _stage_index()==7 else "Carlo defeated! Bubble unlocked · follow the portal." if _stage_index()==0 else _boss_name()+" defeated! Follow the glowing portal.",4,true)
    elif category == "Enemies": _ocean_event("impact",at)
    elif category in ["Treasure","Secrets"]: _ocean_event("treasure",at)
    elif category == "Pearls": _ocean_event("pearl",at)

    if is_instance_valid(premium_hud):
        premium_hud.show_reward(reward,at-Vector2(camera,0))

func _complete_score() -> void:
    if score_book.finished: return
    var prefs = get_node("/root/AppPreferences")
    var run := get_node("/root/AdventureRun")
    var result: Dictionary = score_book.complete(score,picked_count,run.chapter_best(_stage_index()))
    score = int(result["total"])
    result["reward"] = _completion_reward()
    run.record_stage(_stage_index(), result)
    prefs.best_score = maxi(prefs.best_score, score)
    prefs.save()
    _sfx("victory",3)

func _completion_reward() -> String:
    return "Carlo’s portal is open!" if bubble_unlocked else "Mermaid Bubble unlocked"

func _say(text: String, duration: float = 3.0, priority := false) -> void:
    if message_priority and message_time > 0.5 and not priority: return
    message = text
    message_time = duration
    message_priority = priority

func _process(_delta: float) -> void:
    if not _bubble_context_allowed():opal.cancel()
    if state != "playing" or get_tree().paused:
        return
    _sync_native_visuals()
    if is_instance_valid(avina) and not get_tree().paused: avina.tick(_delta)
    queue_redraw()

func _physics_process(dt: float) -> void:
    _poll_gamepad()
    if state != "playing" or get_tree().paused:
        opal.cancel()
        return
    var serial := retry_serial
    if _action_held("boost"):
        _boost()
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
    opal.advance(dt)
    opal_fx.advance(dt)
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
        "bubble_recovery":opal.charge.recovery_duration,
        "pearls": picked_count,
        "chapter": _chapter_name(), "boss_name": _boss_name(), "next_stage": _next_stage_name(),
        "progress": clampf((player.x - _route_start()) / maxf(1, _portal_x() - _route_start()), 0.0, 1.0),
        "message": message,
        "message_time": message_time,
        "message_priority":message_priority,
        "adventure_total":get_node("/root/AdventureRun").total_with_stage(_stage_index(), score) if state=="victory" else 0,
        "adventure_breakdown":get_node("/root/AdventureRun").campaign_breakdown(_stage_index(), score) if state=="victory" and _stage_index()==6 else {},
        "chapters_complete":get_node("/root/AdventureRun").completed.size(),
        "boss_active": player.x > _boss_home() - 850.0 and boss_hp > 0,
        "boss_health": float(boss_hp) / float(_boss_max_health()),
        "boss_vulnerable": _boss_vulnerable() and boss_hit_cooldown<=0 and (_bubble_context_allowed() or _opal_boost_available()),
        "bubble": bubble_unlocked,
        "charge_tier":opal.charge.tier() if opal.charge.held else 0,
        "charge_progress":opal.charge.elapsed/opal.charge.SUPER_SECONDS if opal.charge.held else 0.0,
        "paused": state == "paused",
        "victory": state == "victory",
        "touch": simulated_touch or DisplayServer.is_touchscreen_available(),
        "pressed": touches.values(),
        "pad": _touch_direction(),
        "boss_attack": _boss_attack_hint(),
        "boss_phase": boss_phase,
        "boss_pattern": boss_pattern,
        "waterfall": waterfall_phase,
        "fall_progress": clampf(waterfall_time / 17.0, 0.0, 1.0) if waterfall_phase == "descent" else (1.0 if waterfall_phase == "outflow" else 0.0)
    }

func _sync_native_visuals() -> void:
    opal.refresh_targets()
    if is_instance_valid(opal_fx):opal_fx.sync(self)
    if is_instance_valid(native_rig):native_rig.set_bubble_charge(opal.charge.held,opal.charge.elapsed/1.35)
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
    if _uses_highland_scenery():
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
    if _uses_highland_scenery():
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
    if _uses_highland_scenery() and is_instance_valid(native_boss):
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

func _checkpoint_stops() -> Array:
    return [
        [2770.0, "Waterfall Inlet"],
        [Highland.route_x(6500.0), "Secret Grotto"],
        [Highland.route_x(9050.0), "Kelp Cathedral"],
        [Highland.route_x(11700.0), "Shell Ruins"],
        [Highland.route_x(13720.0), "Carlo’s Court"]
    ]

func _prepare_journey_stops() -> void:
    if journey_stops_ready or _stage_index()==7: return
    journey_stops_ready=true
    # The finale already begins beside its boss and needs no travel checkpoint.
    if _stage_index()==6:return
    var bounds := Rect2(_left_bound(),_water_line()+45,_level_length()-40-_left_bound(),BOTTOM-26-(_water_line()+45))
    journey_stops=JourneyRoute.build(_checkpoint_stops(),_route_start(),_boss_home(),obstacles,enemies,bounds)

func _check_checkpoints() -> void:
    if state!="playing":return
    _prepare_journey_stops()
    var arrived := false
    for stop in journey_stops:
        if player.x>float(stop["x"])+60 and checkpoint<float(stop["x"]):
            checkpoint=float(stop["x"])
            last_checkpoint_message=String(stop["name"])
            arrived=true
    if arrived:
        health=MAX_HEALTH
        energy=1.0
        if has_method("_release_all_loot"):call("_release_all_loot")
        # Coalesce crossings into one snapshot and one sound, even after a long frame.
        _save_checkpoint()
        _say("Checkpoint · "+last_checkpoint_message+" · fins refreshed",3)

func _draw_journey_haven() -> void:
    if _stage_index() in [6,7] or state!="playing":return
    _prepare_journey_stops()
    for stop in journey_stops:
        if not stop["haven"] or float(stop["x"])<checkpoint-1:continue
        var at: Vector2=stop["position"]-Vector2(camera,0)
        if at.x < -90 or at.x>get_viewport_rect().size.x+90:continue
        var pulse := 1.0 if reduced_fx else 1.0+sin(time*1.7)*.06
        draw_circle(at,36*pulse,Color(.36,.9,.85,.10))
        draw_arc(at,29*pulse,0,TAU,48,Color(.64,.96,.88,.7),1.5,true)
        draw_texture_rect(HAVEN_SHELL,Rect2(at-Vector2(20,20),Vector2(40,40)),false,Color(1,1,1,.92))
        _draw_text(at+Vector2(-45,55),"Resting Pearl",14,Color("c7ece3"))
        break # At most one haven is painted in a frame.

func _update_enemies(dt: float) -> void:
    var serial := retry_serial
    for enemy in enemies:
        if int(enemy["hp"]) <= 0 or absf(float(enemy["x"]) - player.x) > 1200.0:
            continue
        enemy["hit_cd"]=maxf(0.0,float(enemy.get("hit_cd",0))-dt)
        var event := Combat.step(enemy, player, time, dt, obstacles)
        if event == "fire":
            _spawn_hostile(Vector2(enemy["x"], enemy["y"]), Vector2(enemy["aim"]), 290.0, enemy["kind"])
        var pos := Vector2(float(enemy["x"]), float(enemy["y"]))
        var radius := 96.0 if enemy["kind"] == "eel" else 79.0
        if String(enemy.get("mode", "patrol")) == "recover":
            radius *= 0.75
        if player.distance_to(pos) < radius and player.y > _water_line():
            if boost_time > 0.0:
                var applied:=_hit_enemy(enemy,maxi(2,int(enemy["hp"])),true,boost_direction)
                if applied>0:
                    native_fx.splash(pos-Vector2(camera,0),Color("#e5ffce"),17)
                    _vibrate(0.22,0.08,0.12)
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
    _say("Ouch! Careful, Sarah.", 1.6, true)
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
        "enemies": enemies.duplicate(true), "boss_hp": boss_hp, "bubble": bubble_unlocked, "fallen":fallen
    }
    checkpoint_position = RockCollision.recover(Vector2(checkpoint, player.y if _stage_index() == 7 else 480.0), obstacles, HERO_RADIUS * .73, _swim_bounds())
    if not checkpoint_pending:
        checkpoint_pending = true
        _persist_checkpoint.call_deferred()

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
    fallen = bool(checkpoint_snapshot.get("fallen", checkpoint >= Highland.WATERFALL_EXIT))
    player = RockCollision.recover(checkpoint_position, obstacles, HERO_RADIUS*.73, _swim_bounds())
    camera = maxf(0.0, player.x - get_viewport_rect().size.x * 0.43)
    invulnerable = 2.0
    native_boss.reset_boss()
    if not music_muted:
        music_player.volume_db = -17.0
    _say("Back to your checkpoint!", 2.6)

func _reset_transients() -> void:
    boss_volley.clear()
    message_priority = false
    message_time = 0.0
    opal.reset()
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
        boss_phase="windup";boss_phase_time=0;boss_clock=0
        return
    var serial := retry_serial
    boss_clock += dt
    boss_phase_time += dt
    if boss_phase == "windup":
        if boss_phase_time <= dt:
            boss_target = player
        if boss_phase_time >= 1.1:
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
    elif boss_phase_time >= 2.5:
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
        elif boost_time <= 0.0 and boss_phase == "attack":
            _damage(boss_position)

func _boss_vulnerable() -> bool:
    return boss_hp > 0 and boss_phase == "recover"

func _spawn_hostile(pos: Vector2, direction: Vector2, speed: float, style:="") -> void:
    if hostile_shots.size()<32:hostile_shots.append({"pos":pos,"velocity":direction*speed,"life":2.8,"style":_opal_primary_id() if style.is_empty() else style})

func _update_hostile_shots(dt: float) -> void:
    opal.update_hostile(dt)

func _touch_direction() -> Vector2:
    var result := Vector2.ZERO
    for vector in touch_vectors.values():
        result += Vector2(vector)
    return result.limit_length(1.0)

func _update_bubbles(dt: float) -> void:
    opal.update_friendly(dt)

func _start_waterfall() -> void:
    opal.cancel()
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
    opal.cancel()
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
        _draw_journey_haven()
        if not boss_volley.rays.is_empty():
            draw_set_transform(Vector2(-camera,0))
            draw_multiline(boss_volley.rays,Color("ffe3a6"),2,true)
            draw_set_transform(Vector2.ZERO)
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
    if not is_instance_valid(native_boss):
        if not fallback_boss: fallback_boss = load(CARLO_PATH)
        draw_texture_rect(fallback_boss,Rect2(x-162,y-180,324,352),false)
    if boss_phase == "windup":
        var origin := boss_position - Vector2(camera, 0)
        if boss_pattern == 0:
            draw_arc(origin, 280, 0, TAU, 80, Color(1, 0.64, 0.38, 0.75), 4)
        elif boss_pattern==1:
            var aim: Vector2=(boss_target-boss_position).normalized()
            if aim==Vector2.ZERO:aim=Vector2.LEFT
            for angle in [-.24,0,.24]:
                draw_line(origin,origin+aim.rotated(angle)*minf(600,boss_target.distance_to(boss_position)),Color(1,.72,.44,.8),3)
        else:
            draw_line(origin, boss_target - Vector2(camera, 0), Color(1, 0.72, 0.44, 0.8), 3)

func _draw_hero(pos: Vector2) -> void:
    var opacity := 1.0 if invulnerable <= 0.0 else 0.58 + 0.42 * absf(sin(time * 13.0))
    var tilt := clampf(player_velocity.y / 1150.0, -0.30, 0.30) * facing
    var bob := sin(time * 5.0) * 3.0 if jump_time <= 0.0 else 0.0
    draw_set_transform(pos + Vector2(0, bob), tilt, Vector2(facing, 1.0))
    # The character is now a native articulated Sprite2D hierarchy; keep fallback only.
    if not is_instance_valid(native_rig):
        if not fallback_hero: fallback_hero = load(HERO_PATH)
        draw_texture_rect(fallback_hero, Rect2(-115, -77, 230, 154), false, Color(1, 1, 1, opacity))
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


func _draw_text(pos: Vector2, value: String, font_size: int = 23, color: Color = Color.WHITE) -> void:
    draw_string(preload("res://dist/fonts/story-serif.ttf"), pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

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
    opal.cancel()
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
func _route_start() -> float: return 220.0
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
    run.advance_stage(_stage_index(), score)
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

func _sfx(effect: String, priority := 1, pitch := 0.0) -> void:
    get_node("/root/OceanAudio").play(effect,priority,pitch)
func _ocean_event(effect: String, at: Vector2, direction := Vector2.RIGHT) -> void:
    _sfx(effect,3 if effect in ["boss_defeat","checkpoint"] else 1)
    if is_instance_valid(ocean_feedback): ocean_feedback.burst(at,effect,direction)

func _uses_highland_scenery() -> bool: return true

# Authoritative combat snapshots also drive the opportunity shells.
func _opal_primary_id() -> String:return "carlo"
func _opal_art_chapter() -> String:return _opal_primary_id()
func _opal_make_targets() -> Array[Dictionary]:
    var id:=_opal_primary_id()
    return [OpalCombat.target(id,preload("res://godot/opal_roster.gd").BOSS_FITS[id],150)]
func _opal_arena_active() -> bool:return boss_hp>0 and waterfall_phase=="" and player.x>=_boss_home()-850
func _opal_boost_available() -> bool:return boost_time>0 or (energy>=0.4 and boost_cooldown<=0 and jump_time<=0)
func _opal_opening_soon() -> bool:return boss_phase=="attack" and boss_phase_time>=0.47 and boss_phase_time<0.65
func _opal_update_targets(targets: Array[Dictionary]) -> void:
    if targets.is_empty():return
    var target:=targets[0]
    target["pos"]=boss_position;target["hp"]=boss_hp;target["active"]=_opal_arena_active()
    target["open"]=_boss_vulnerable();target["opening"]=_opal_opening_soon();target["cooldown"]=boss_hit_cooldown
    target["attacking"]=boss_phase=="attack"
    target["bubble"]=bubble_unlocked and _bubble_context_allowed();target["boost"]=_opal_boost_available()
func _opal_target_open(target: Dictionary) -> bool:
    return target["active"] and target["open"] and float(target["cooldown"])<=0 and (target["bubble"] or target["boost"])
func _opal_hit_boss(_id: String, damage: int) -> int:
    if not bubble_unlocked or not _opal_arena_active() or not _boss_vulnerable() or boss_hit_cooldown>0:return 0
    var applied:=mini(boss_hp,clampi(damage,1,2));boss_hp-=applied;boss_hit_cooldown=2.2
    _award("boss-hit:%s" % boss_hp,"Boss",200*applied,boss_position,false);native_boss.play_hit()
    if boss_hp<=0:
        _award("boss-defeat","Boss",1000,boss_position,false);bubble_unlocked=true;hostile_shots.clear();native_boss.defeat()
        _say("Carlo defeated! Mermaid Bubble unlocked. Find the portal!",5)
    return applied
func _opal_switch_targets() -> Array[Dictionary]:return empty_opal_switches
func _opal_hit_switch(_index: int, _packet: Dictionary = {}) -> void:pass
func _opal_sync_fields(_fx: Node2D) -> void:pass
func _opal_cast_position(tier: int) -> Vector2:
    var radius:=24.0 if tier==1 else 30.0 if tier==2 else 38.0
    return player+Vector2(facing*(preload("res://godot/opal_roster.gd").SARAH_CAST_HAND_X+radius),0)
func _opal_enemy_reward() -> int:return 50
func _release_loot(_enemy: Dictionary) -> void:pass
func _guarded(enemy: Dictionary) -> bool:return OpalCombat.Sweep.guarded(enemy,Vector2(enemy["x"],enemy["y"])-player)
func _hit_enemy(enemy: Dictionary, damage: int, boosted: bool, incoming:=Vector2.ZERO) -> int:
    if int(enemy["hp"])<=0 or float(enemy.get("hit_cd",0))>0:return 0
    if incoming==Vector2.ZERO:incoming=Vector2(enemy["x"],enemy["y"])-player
    if OpalCombat.Sweep.guarded(enemy,incoming):
        enemy["mode"]="recover";enemy["mode_time"]=0.0;enemy["hit_cd"]=0.25
        _say("Shell guard! Strike again while it recovers.",1.8,true);return 0
    var applied:=mini(int(enemy["hp"]),maxi(0,damage))
    if applied==0:return 0
    enemy["hp"]=int(enemy["hp"])-applied;enemy["hit_cd"]=0.6;enemy["mode"]="recover";enemy["mode_time"]=0.0
    var at:=Vector2(enemy["x"],enemy["y"]);_ocean_event("impact",at)
    if boosted:invulnerable=maxf(invulnerable,0.5)
    if int(enemy["hp"])<=0:_release_loot(enemy);_award("enemy:%s" % enemies.find(enemy),"Enemies",_opal_enemy_reward(),at,true)
    return applied

func _boss_attack_hint() -> String:
    if boss_hit_cooldown>0:return "Hit landed · wait for lavender arcs"
    if _boss_vulnerable() and not bubble_unlocked and not _opal_boost_available():return "Recovery · let your energy refill"
    if _stage_index()==7:return "Royal trial · watch Daddy’s next move"
    if _boss_vulnerable():return "Recovery · Bubble or Boost" if bubble_unlocked else "Recovery · Boost now"
    if _stage_index()==1:return "Duke’s fan · watch Flip above" if boss_volley.pending.is_empty() else "Duke’s fan · lanes locked"
    if _stage_index()==2:return "Maraca fan · leave the marked lanes" if not boss_volley.pending.is_empty() else "Miguel’s dance · keep a dodge route"
    return ["Claw circle · swim outside the ring","Pearl fan · dodge between lanes","Crab dash · leave the marked path"][clampi(boss_pattern,0,2)]

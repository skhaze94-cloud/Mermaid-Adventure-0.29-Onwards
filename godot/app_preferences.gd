extends Node
## Shared user choices; the menu and playable scene use the same audio bus.
const PATH := "user://sarah-preferences.cfg"
var music_volume := 0.8
var sound_volume := 0.8
var ambience_volume := 0.65
var reduced_motion := false
var economy := false
var intro_seen := false
var best_score := 0
var touch_size := 1.0
var touch_opacity := 0.85
var persist_enabled := true

func _ready() -> void:
    persist_enabled = not OS.has_environment("SARAH_DISABLE_SAVES")
    process_mode = Node.PROCESS_MODE_ALWAYS
    _configure_menu_controller()
    var config := ConfigFile.new()
    if config.load(PATH) == OK:
        music_volume = clampf(float(config.get_value("options", "music", 0.8)), 0.0, 1.0)
        sound_volume = clampf(float(config.get_value("options","sound",0.8)),0.0,1.0)
        ambience_volume = clampf(float(config.get_value("options","ambience",0.65)),0.0,1.0)
        reduced_motion = bool(config.get_value("options", "reduced_motion", false))
        economy = bool(config.get_value("options", "economy", false))
        intro_seen = bool(config.get_value("opening", "seen", false))
        best_score = maxi(0,int(config.get_value("records","highland",0)))
        touch_size = clampf(float(config.get_value("options","touch_size",1.0)),0.85,1.20)
        touch_opacity = clampf(float(config.get_value("options","touch_opacity",0.85)),0.35,1.0)
    apply_audio()

func _configure_menu_controller() -> void:
    # Desktop Godot's built-in ui_accept can contain keyboard events only.
    for mapping in [["ui_accept", JOY_BUTTON_A], ["ui_up", JOY_BUTTON_DPAD_UP], ["ui_down", JOY_BUTTON_DPAD_DOWN], ["ui_left", JOY_BUTTON_DPAD_LEFT], ["ui_right", JOY_BUTTON_DPAD_RIGHT]]:
        var button := InputEventJoypadButton.new()
        button.device = -1
        button.button_index = mapping[1]
        if not InputMap.action_has_event(mapping[0], button):
            InputMap.action_add_event(mapping[0], button)
    for mapping in [["ui_up", JOY_AXIS_LEFT_Y, -1.0], ["ui_down", JOY_AXIS_LEFT_Y, 1.0], ["ui_left", JOY_AXIS_LEFT_X, -1.0], ["ui_right", JOY_AXIS_LEFT_X, 1.0]]:
        var motion := InputEventJoypadMotion.new()
        motion.device = -1
        motion.axis = mapping[1]
        motion.axis_value = mapping[2]
        if not InputMap.action_has_event(mapping[0], motion):
            InputMap.action_add_event(mapping[0], motion)

func apply_audio() -> void:
    for setting in [["SFX",sound_volume],["Ambience",ambience_volume]]:
        var channel := AudioServer.get_bus_index(setting[0])
        if channel >= 0:
            AudioServer.set_bus_mute(channel,float(setting[1]) <= 0.001)
            AudioServer.set_bus_volume_db(channel,linear_to_db(maxf(float(setting[1]),0.001)))
    var bus := AudioServer.get_bus_index("Music")
    if bus >= 0:
        AudioServer.set_bus_mute(bus, music_volume <= 0.001)
        AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(music_volume, 0.001)))

func save() -> void:
    apply_audio()
    if not persist_enabled:
        return
    var config := ConfigFile.new()
    config.set_value("records","highland",best_score)
    config.set_value("options","touch_size",touch_size)
    config.set_value("options","touch_opacity",touch_opacity)
    config.set_value("options", "music", music_volume)
    config.set_value("options", "sound", sound_volume)
    config.set_value("options", "ambience", ambience_volume)
    config.set_value("options", "reduced_motion", reduced_motion)
    config.set_value("options", "economy", economy)
    config.set_value("opening", "seen", intro_seen)
    if config.save(PATH) != OK:
        push_warning("Unable to save Sarah's preferences on this device.")

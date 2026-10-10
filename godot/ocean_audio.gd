extends Node
## Bounded effects pool; separate sound and ambience controls; persistent jingles.
const ROOT := "res://godot/assets/audio-v023/"
const EFFECTS := ["pearl","treasure","heart","checkpoint","victory","boss_defeat","ui","boost","splash","swim","impact","boss_hit","bubble"]
var streams: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var priorities: Array[int] = []
var last_played: Dictionary = {}
var ambience: AudioStreamPlayer
var ambient_kind := ""
var ambient_fade: Tween
var playback_enabled := true
var events: Dictionary = {}
var variant := 0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    playback_enabled = DisplayServer.get_name() != "headless"
    for effect in EFFECTS:
        streams[effect] = load(ROOT+effect+".wav")
    for i in range(10):
        var voice := AudioStreamPlayer.new()
        voice.bus = "SFX"
        voice.volume_db = -15
        add_child(voice)
        voices.append(voice)
        priorities.append(0)
    ambience = AudioStreamPlayer.new()
    ambience.bus = "Ambience"
    ambience.volume_db = -60
    add_child(ambience)

func play(effect: String, priority := 1) -> bool:
    if not streams.has(effect): return false
    var now := Time.get_ticks_msec()
    var interval := 100 if effect in ["pearl","boss_hit","impact"] else (180 if effect == "swim" else 55)
    if now-int(last_played.get(effect,-10000)) < interval: return false
    if get_tree().paused and effect not in ["victory","ui"]: return false
    var slot := -1
    for i in range(voices.size()):
        if not voices[i].playing:
            slot = i
            break
    if slot < 0:
        for i in range(voices.size()):
            if priorities[i] < priority:
                slot = i
                break
    if slot < 0: return false
    last_played[effect] = now
    events[effect] = int(events.get(effect,0))+1
    variant += 1
    var voice := voices[slot]
    voice.stop()
    voice.stream = streams[effect]
    voice.stream_paused = false
    voice.volume_db = -27.0 if effect == "swim" else (-23.0 if effect == "ui" else (-19.0 if effect == "pearl" else -15.0))
    voice.pitch_scale = [0.97,1.0,1.035][variant%3] if effect in ["pearl","swim","bubble"] else 1.0
    priorities[slot] = priority
    if playback_enabled: voice.play()
    return true

func set_chapter(index: int, waterfall := false) -> void:
    var kind := "waterfall" if waterfall else ("deep" if index in [1,3] else "reef")
    if kind == ambient_kind: return
    ambient_kind = kind
    if ambient_fade: ambient_fade.kill()
    ambience.stop()
    var stream: AudioStreamWAV = load(ROOT+"ambience_"+kind+".wav")
    stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    stream.loop_begin = 0
    stream.loop_end = int(stream.get_length()*stream.mix_rate)
    ambience.stream = stream
    ambience.volume_db = -60
    if playback_enabled: ambience.play()
    ambient_fade = create_tween()
    ambient_fade.tween_property(ambience,"volume_db",-22.0,0.9)

func fade_out() -> void:
    if ambient_fade: ambient_fade.kill()
    ambient_fade = create_tween()
    ambient_fade.tween_property(ambience,"volume_db",-60.0,0.35)
    ambient_kind = ""
    for voice in voices: voice.stop()

func _process(_dt: float) -> void:
    # Effects stop immediately on pause. Victory/UI sounds may play while paused.
    ambience.stream_paused = get_tree().paused
    if get_tree().paused:
        for voice in voices:
            if voice.stream and voice.stream not in [streams["victory"],streams["ui"]]:
                voice.stop()
    else:
        for voice in voices: voice.stream_paused = false

func _exit_tree() -> void:
    for voice in voices:
        voice.stop()
        voice.stream = null
    if is_instance_valid(ambience):
        ambience.stop()
        ambience.stream = null
    streams.clear()

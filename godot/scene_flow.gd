extends CanvasLayer
## One persistent scene boundary: background loading, input guard and ocean iris.
signal finished
signal failed(message: String)
const LINES := ["Follow the gold beyond the waterfall.", "A hidden kingdom beneath the reef.", "A warm lagoon, a new friend.", "Follow the pearls into the quiet deep.", "A palace full of ocean light.", "Ancient gardens. A little courage.", "One last adventure with Nessie.", "A gentle place to find your fins."]
var busy := false
var test_animations := false
var cover := 0.0:
    set(value):
        cover = value
        if material: material.set_shader_parameter("progress", value)
var surface: ColorRect
var material: ShaderMaterial
var card: PanelContainer
var heading: Label
var caption: Label
var kicker: Label
var old_scene: Node
var old_mode := Node.PROCESS_MODE_INHERIT
var old_pause := false
var outgoing_music: AudioStreamPlayer
var outgoing_volume := -17.0

func _ready() -> void:
    var Kit: GDScript = load("res://godot/ui_kit.gd")
    layer = 100
    process_mode = Node.PROCESS_MODE_ALWAYS
    surface = ColorRect.new()
    surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
    material = ShaderMaterial.new()
    material.shader = preload("res://godot/shaders/ocean_transition.gdshader")
    surface.material = material
    add_child(surface)
    card = PanelContainer.new()
    card.theme = Kit.theme()
    card.add_theme_stylebox_override("panel", Kit.panel(Color("082b40"), Color("e9c880"), 24))
    card.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(card)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 12)
    card.add_child(column)
    var crest: TextureRect = Kit.icon("crest", Vector2(72,72))
    column.add_child(crest)
    kicker = Kit.label("THE ADVENTURE CONTINUES", 14, Color("e9c880"))
    heading = Kit.label("", 36, Color("fff0c9"))
    caption = Kit.label("", 18, Color("b4d9d9"))
    for label in [kicker, heading, caption]:
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        column.add_child(label)
    surface.visible = false
    card.visible = false
    get_viewport().size_changed.connect(_resize)
    _resize()

func _resize() -> void:
    var size := get_viewport().get_visible_rect().size
    surface.size = size
    material.set_shader_parameter("aspect", size.x / maxf(size.y, 1.0))
    card.size = Vector2(minf(620, size.x - 40), 0)
    card.position = Vector2((size.x-card.size.x)*0.5, maxf(16,(size.y-card.size.y)*0.5))

func go(path: String, title: String, subtitle := "", chapter_index := -1) -> bool:
    if busy or not ResourceLoader.exists(path): return false
    busy = true
    get_node("/root/OceanAudio").fade_out()
    old_scene = get_tree().current_scene
    old_pause = get_tree().paused
    if is_instance_valid(old_scene):
        old_mode = old_scene.process_mode
        old_scene.process_mode = Node.PROCESS_MODE_DISABLED
    outgoing_music = old_scene.get("music_player") if is_instance_valid(old_scene) else null
    if is_instance_valid(outgoing_music):
        outgoing_volume = outgoing_music.volume_db
    get_tree().paused = false
    var focused := get_viewport().gui_get_focus_owner()
    if focused: focused.release_focus()
    heading.text = title
    caption.text = subtitle if not subtitle.is_empty() else (LINES[chapter_index] if chapter_index >= 0 else "An ocean of wonder awaits.")
    kicker.text = "CHAPTER %s" % (chapter_index+1) if chapter_index in range(7) else "SARAH MARIA"
    _travel.call_deferred(path)
    return true

func _travel(path: String) -> void:
    var fast := DisplayServer.get_name() == "headless" and not test_animations
    if fast:
        var ready_scene: PackedScene = load(path)
        if not ready_scene or get_tree().change_scene_to_packed(ready_scene) != OK:
            _recover("This chapter could not be opened. Please try again.")
            return
        await get_tree().process_frame
        await get_tree().process_frame
        _finish()
        return
    var gentle: bool = get_node("/root/AppPreferences").reduced_motion
    material.set_shader_parameter("gentle", gentle)
    surface.visible = not fast
    surface.mouse_filter = Control.MOUSE_FILTER_STOP
    card.modulate.a = 0.0
    var error := ResourceLoader.load_threaded_request(path, "PackedScene")
    if error != OK:
        _recover("This chapter could not be opened. Please try again.")
        return
    if not fast:
        if is_instance_valid(outgoing_music):
            create_tween().tween_property(outgoing_music, "volume_db", -60.0, 0.35)
        var fade := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        fade.tween_property(self, "cover", 1.0, 0.18 if gentle else 0.38)
        await fade.finished
        card.visible = true
        await get_tree().process_frame
        _resize()
        var reveal := create_tween()
        reveal.tween_property(card, "modulate:a", 1.0, 0.18)
        await reveal.finished
    var started := Time.get_ticks_msec()
    while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
        if Time.get_ticks_msec()-started > 20000:
            _recover("The kingdom is taking too long to open. Please try again.")
            return
        await get_tree().process_frame
    if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_LOADED:
        _recover("This chapter could not be opened. Please try again.")
        return
    var scene: PackedScene = ResourceLoader.load_threaded_get(path)
    error = get_tree().change_scene_to_packed(scene)
    if error != OK:
        _recover("This chapter could not be opened. Please try again.")
        return
    await get_tree().process_frame
    await get_tree().process_frame
    var incoming := get_tree().current_scene
    var incoming_mode := incoming.process_mode
    incoming.process_mode = Node.PROCESS_MODE_DISABLED
    var incoming_music: AudioStreamPlayer = incoming.get("music_player")
    var target_volume: float = incoming_music.volume_db if incoming_music else -17.0
    if incoming_music and not fast:
        incoming_music.volume_db = -60.0
    if not fast:
        if not gentle: await get_tree().create_timer(0.55, true).timeout
        if incoming_music:
            create_tween().tween_property(incoming_music, "volume_db", target_volume, 0.75)
        var reveal := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        reveal.tween_property(card, "modulate:a", 0.0, 0.18)
        reveal.tween_property(self, "cover", 0.0, 0.22 if gentle else 0.55)
        await reveal.finished
    incoming.process_mode = incoming_mode
    _finish()

func _recover(message: String) -> void:
    if is_instance_valid(old_scene): old_scene.process_mode = old_mode
    if is_instance_valid(outgoing_music): outgoing_music.volume_db = outgoing_volume
    get_tree().paused = old_pause
    if is_instance_valid(old_scene):
        get_node("/root/OceanAudio").set_chapter(old_scene._stage_index() if old_scene.has_method("_stage_index") else -1)
    _finish()
    failed.emit(message)

func _finish() -> void:
    cover = 0.0
    card.visible = false
    surface.visible = false
    surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
    old_scene = null
    busy = false
    finished.emit()

func _input(_event: InputEvent) -> void:
    if busy: get_viewport().set_input_as_handled()

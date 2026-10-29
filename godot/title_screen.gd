extends Control
var selected_chapter := 7
var chapter_thumbnails: Dictionary = {}
const CHAPTER_ART := ["res://godot/assets/environment-lake-v011.webp", "res://dist/assets/shadow-kingdom-v751.webp", "res://dist/assets/colombia.webp", "res://godot/assets/waterfall-cavern-v07.webp", "res://dist/assets/pearl-palace.webp", "res://dist/assets/colombia.webp", "res://dist/assets/colombia.webp", "res://dist/assets/training-lagoon.webp"]
## Native Godot front end: focusable controls, responsive artwork and skippable credits.
const Controls = preload("res://godot/control_layout.gd")
const BODY: Font = preload("res://dist/fonts/story-serif.ttf")
const BOLD: Font = preload("res://dist/fonts/story-serif-bold.ttf")
const SCENERY: Texture2D = preload("res://dist/assets/highlands.webp")
const HERO: Texture2D = preload("res://godot/assets/sarah-title-v08.webp")
const MUSIC = preload("res://dist/assets/bubble-bell-adventure.mp3")
const GOLD := Color("f4dca5")
const WHITE := Color("f1fff8")
const PALE := Color("b4d9d9")
const INTRO := [
    ["A FAMILY ADVENTURE", "A little courage.\nAn ocean of wonder.", "Every great adventure begins with a curious heart."],
    ["CREATED WITH LOVE", "For Sarah Maria", "An adventure by Sam Khaze"],
    ["THE STORY BEGINS", "Beyond the waterfall", "A hidden kingdom. A brave little mermaid.\nAnd a whole world waiting to be discovered."]
]
var page := ""
var clock := 0.0
var intro_clock := 0.0
var intro_card := -1
var transitioning := false
var background: TextureRect
var lagoon_material: ShaderMaterial
var hero: TextureRect
const OpeningPerformance = preload("res://godot/sarah_opening_performance.gd")
var hero_performance = OpeningPerformance.new()
var hero_rig: Node2D
var hero_home := Vector2.ZERO
var motes: Control
var ui: Control
var content: VBoxContainer
var scroll: ScrollContainer
var footer: Label
var skip: Button
var back_button: Button
var veil: ColorRect
var music_player: AudioStreamPlayer
var reveal_tween: Tween
var prefs: Node
var ui_size := Vector2(1400, 960)
var safe_frame := Rect2()
var ui_scale := 1.0
var primary: Button
var music_slider: HSlider
var motion_toggle: CheckButton
var quality_toggle: CheckButton
var continue_requested := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().paused = false
    prefs = get_node("/root/AppPreferences")
    get_node("/root/AdventureRun").save_finished.connect(_on_save_finished)
    get_node("/root/OceanAudio").set_chapter(-1)
    for font in [BODY, BOLD]:
        font.multichannel_signed_distance_field = true
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    background = TextureRect.new()
    background.texture = SCENERY
    background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    lagoon_material = ShaderMaterial.new()
    lagoon_material.shader = preload("res://godot/shaders/title_lagoon.gdshader")
    background.material = lagoon_material
    add_child(background)
    motes = Control.new()
    motes.mouse_filter = Control.MOUSE_FILTER_IGNORE
    motes.draw.connect(_draw_atmosphere)
    add_child(motes)
    hero = TextureRect.new()
    hero.texture = HERO
    hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(hero)
    hero.self_modulate.a=0.0
    hero_rig=preload("res://godot/sarah_rig.gd").new()
    hero.add_child(hero_rig)
    hero_rig.set_process(false)
    hero_rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    hero_rig.jump_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    ui = Control.new()
    ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(ui)
    content = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 15)
    scroll = ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.follow_focus = true
    ui.add_child(scroll)
    scroll.add_child(content)
    footer = _label("HIGHLAND GOLD  •  CHAPTER ONE", 15, PALE)
    ui.add_child(footer)
    skip = _button("Skip opening  ›", _finish_intro, false)
    ui.add_child(skip)
    back_button = _button("‹  Back", func(): show_page("options" if page == "controls" else "menu"))
    ui.add_child(back_button)
    veil = ColorRect.new()
    veil.color = Color("071d2b")
    veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    veil.modulate.a = 0.0
    add_child(veil)
    music_player = AudioStreamPlayer.new()
    music_player.stream = MUSIC
    music_player.bus = "Music"
    music_player.volume_db = -22.0
    if music_player.stream is AudioStreamMP3:
        music_player.stream.loop = true
    add_child(music_player)
    if DisplayServer.get_name() != "headless" and not OS.has_environment("GODOT_CAPTURE_PREVIEW"):
        music_player.play()
    get_viewport().size_changed.connect(_resize)
    if prefs.intro_seen or OS.has_environment("GODOT_CAPTURE_PREVIEW"):
        show_page("menu")
    else:
        play_intro()
    _resize()

func _exit_tree() -> void:
    if is_instance_valid(music_player):
        music_player.stop()
        music_player.stream = null

func _label(text_value: String, font_size: int, color: Color = WHITE, font: Font = BODY) -> Label:
    var label := Label.new()
    label.text = text_value
    label.add_theme_font_override("font", font)
    label.add_theme_font_size_override("font_size", font_size)
    label.set_meta("normal_font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return label

func _style(fill: Color, edge: Color, width := 1) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = edge
    style.set_border_width_all(width)
    style.set_corner_radius_all(14)
    style.content_margin_left = 22
    style.content_margin_right = 22
    style.content_margin_top = 12
    style.content_margin_bottom = 12
    return style

func _button(text_value: String, action: Callable, featured := false) -> Button:
    var button := Button.new()
    button.text = text_value
    button.custom_minimum_size = Vector2(0, 64)
    button.add_theme_font_override("font", BOLD)
    button.add_theme_font_size_override("font_size", 22)
    button.add_theme_color_override("font_color", Color("112b36") if featured else WHITE)
    button.add_theme_color_override("font_hover_color", Color("112b36") if featured else GOLD)
    button.add_theme_color_override("font_pressed_color", Color("112b36") if featured else WHITE)
    button.add_theme_color_override("font_focus_color", Color("112b36") if featured else WHITE)
    button.add_theme_stylebox_override("normal", _style(GOLD if featured else Color(0.025, 0.12, 0.17, 0.88), GOLD if featured else Color("43666b")))
    button.add_theme_stylebox_override("hover", _style(Color("fff0c9") if featured else Color("153c47"), GOLD))
    button.add_theme_stylebox_override("pressed", _style(Color("d0ba89") if featured else Color("102c37"), GOLD))
    button.add_theme_stylebox_override("focus", _style(Color(0,0,0,0), Color("a3fff1"), 3))
    button.expand_icon = true
    button.add_theme_constant_override("icon_max_width",34)
    button.pressed.connect(func(): get_node("/root/OceanAudio").play("ui",0))
    button.pressed.connect(action)
    return button

func _comfort_slider(title: String, low: float, high: float, value: float, changed: Callable) -> void:
    content.add_child(_label(title,20,PALE))
    var slider := HSlider.new()
    slider.min_value = low
    slider.max_value = high
    slider.step = 0.05
    slider.value = value
    slider.custom_minimum_size.y = 48
    slider.value_changed.connect(changed)
    content.add_child(slider)

func _clear_content() -> void:
    if reveal_tween and reveal_tween.is_running():
        reveal_tween.kill()
    for child in content.get_children():
        content.remove_child(child)
        child.queue_free()
    primary = null
    music_slider = null
    motion_toggle = null
    quality_toggle = null

func _heading(kicker: String, title: String, subtitle: String = "") -> void:
    content.add_child(_label(kicker, 16, GOLD, BOLD))
    var heading := _label(title, 72 if page == "menu" else 48, WHITE, BOLD)
    heading.name = "PageTitle"
    content.add_child(heading)
    if subtitle != "":
        content.add_child(_label(subtitle, 23, PALE))

func _add_button(text_value: String, action: Callable, featured := false) -> Button:
    var button := _button(text_value, action, featured)
    content.add_child(button)
    if primary == null:
        primary = button
    return button

func show_page(next_page: String) -> void:
    if transitioning:
        return
    page = next_page
    _clear_content()
    scroll.scroll_vertical = 0
    skip.visible = false
    back_button.visible = page != "menu"
    footer.text = "v0.7.0  •  BUBBLE POLISH" if page == "menu" else "SARAH MARIA"
    match page:
        "menu":
            _heading("SARAH MARIA", "Mermaid\nAdventure", "Follow your wonder.")
            var run := get_node("/root/AdventureRun")
            if run.has_resume():
                _add_button("Continue adventure  ›", func(): start_adventure(true), true)
                content.add_child(_label(run.NAMES[run.resume_chapter()]+" · saved checkpoint",18,PALE))
            _add_button("Begin adventure  ›", func(): _request_begin(7), not run.has_resume())
            _add_button("Choose a chapter", func(): show_page("chapters"))
            _add_button("Options", func(): show_page("options"))
            _add_button("Credits & opening", func(): show_page("credits"))
            content.add_child(_label(("Adventure best: "+preload("res://godot/ui_kit.gd").number(run.adventure_best)) if run.adventure_best>0 else ("Personal best: "+preload("res://godot/ui_kit.gd").number(prefs.best_score)),18,GOLD))
            if not run.save_message.is_empty(): footer.text = run.save_message
        "new_adventure":
            _heading("ANOTHER OCEAN TO EXPLORE", "A fresh adventure?", "Your saved checkpoint will be replaced when this adventure begins. Your stars and personal bests stay with you.")
            _add_button("Begin this adventure  ›", func(): start_adventure(), true)
            _add_button("Keep my saved adventure", func(): show_page("menu"))
        "chapters":
            _heading("YOUR ADVENTURE", "Choose a chapter", "Each chapter continues into the next. Meet baby Avina in the tutorial, or choose any chapter.")
            var catalog := get_node("/root/AdventureRun")
            for index in range(catalog.SCENES.size()):
                _add_chapter_button(index, catalog.NAMES[index])
        "options":
            _heading("MAKE YOURSELF AT HOME", "Your adventure", "A little comfort for every explorer.")
            content.add_child(_label("Music volume", 22, GOLD, BOLD))
            music_slider = HSlider.new()
            music_slider.name = "MusicVolume"
            music_slider.min_value = 0
            music_slider.max_value = 100
            music_slider.step = 5
            music_slider.value = prefs.music_volume * 100
            music_slider.custom_minimum_size.y = 48
            music_slider.value_changed.connect(_music_changed)
            content.add_child(music_slider)
            _comfort_slider("Sound effects",0.0,1.0,prefs.sound_volume,func(value): prefs.sound_volume=value; prefs.save())
            _comfort_slider("Ocean ambience",0.0,1.0,prefs.ambience_volume,func(value): prefs.ambience_volume=value; prefs.save())
            motion_toggle = _toggle("Gentle motion", prefs.reduced_motion, _motion_changed)
            content.add_child(_label("Less movement, fewer effects, the same magic.", 18, PALE))
            quality_toggle = _toggle("Economy graphics", prefs.economy, _quality_changed)
            content.add_child(_label("Lighter lighting and effects for smaller devices.", 18, PALE))
            _comfort_slider("Touch control size",0.85,1.20,prefs.touch_size,func(value): prefs.touch_size=value; prefs.save())
            _comfort_slider("Touch control opacity",0.35,1.0,prefs.touch_opacity,func(value): prefs.touch_opacity=value; prefs.save())
            _add_button("How to play", func(): show_page("controls"))
        "controls":
            _heading("A FEW LITTLE POINTERS", "Ready to explore?", "Swim, leap and find what lies beneath.")
            content.add_child(_label("Swim    Arrow keys / WASD / left stick\nBoost    Space / controller B\nJump    J or Shift / controller A\nBubble    Hold B or Z / controller X, then release\nPause    Escape / P / controller Start", 23, WHITE))
            content.add_child(_label("On a touch screen, use the sliding pad and action buttons. The family tutorial grants Bubble; starting at Highland Gold earns it from Carlo instead. Quick release: Pearl Pop. Hold 0.35 seconds: Prism Bloom. Hold 1.35 seconds: Royal Aurora, then release! Swim freely while charging; Boost or Jump cancels it. Play in landscape.", 20, PALE))
            primary = back_button
        "credits":
            _heading("MADE WITH LOVE", "For Sarah Maria", "For every little heart with a big imagination.")
            content.add_child(_label("Game & story\nSam Khaze", 26, GOLD, BOLD))
            content.add_child(_label("Music\nBubble Bell Adventure\n\nArtwork\nGame illustrations & AI-assisted artwork\n\nMade with Godot", 21, WHITE))
            _add_button("Replay the opening", play_intro)
    _resize()
    _reveal()
    _settle_layout.call_deferred()
    _focus_current.call_deferred()

func _focus_current() -> void:
    if transitioning or not is_inside_tree():
        return
    var target: Control = skip if page == "intro" else (music_slider if page == "options" else primary)
    if is_instance_valid(target) and target.is_inside_tree():
        target.grab_focus()

func _toggle(text_value: String, value: bool, action: Callable) -> CheckButton:
    var toggle := CheckButton.new()
    toggle.text = text_value
    toggle.button_pressed = value
    toggle.custom_minimum_size.y = 54
    toggle.add_theme_font_override("font", BOLD)
    toggle.add_theme_font_size_override("font_size", 22)
    toggle.add_theme_color_override("font_color", WHITE)
    toggle.add_theme_stylebox_override("normal", _style(Color("10323e"), Color("43666b")))
    toggle.add_theme_stylebox_override("focus", _style(Color(0,0,0,0), Color("a3fff1"), 3))
    toggle.toggled.connect(action)
    content.add_child(toggle)
    return toggle

func _music_changed(value: float) -> void:
    prefs.music_volume = value / 100.0
    prefs.save()

func _motion_changed(value: bool) -> void:
    prefs.reduced_motion = value
    prefs.save()
    if reveal_tween and reveal_tween.is_running():
        reveal_tween.kill()
    content.modulate.a = 1.0
    hero.position = hero_home

func _quality_changed(value: bool) -> void:
    prefs.economy = value
    prefs.save()

func _settle_layout() -> void:
    # Native containers calculate wrapping after entering the tree.
    await get_tree().process_frame
    if is_inside_tree():
        _resize()
        await get_tree().process_frame
        if is_inside_tree(): scroll.scroll_vertical = 0

func _reveal() -> void:
    content.modulate.a = 1.0 if prefs.reduced_motion else 0.0
    if not prefs.reduced_motion:
        reveal_tween = create_tween()
        reveal_tween.tween_property(content, "modulate:a", 1.0, 0.55)

func play_intro() -> void:
    if transitioning:
        return
    page = "intro"
    intro_clock = 0.0
    hero_performance.reset()
    hero_rig.reset_jump()
    hero_rig.reset_performance()
    intro_card = -1
    skip.visible = true
    back_button.visible = false
    footer.text = "A SARAH MARIA ADVENTURE"
    _set_intro_card(0)
    _focus_current.call_deferred()

func _set_intro_card(index: int) -> void:
    intro_card = index
    _clear_content()
    _heading(INTRO[index][0], INTRO[index][1], INTRO[index][2])
    _resize()
    _reveal()
    _settle_layout.call_deferred()

func _finish_intro() -> void:
    prefs.intro_seen = true
    prefs.save()
    show_page("menu")

func _request_begin(index: int) -> void:
    selected_chapter = index
    if get_node("/root/AdventureRun").has_resume(): show_page("new_adventure")
    else: start_adventure()

func start_adventure(resume := false) -> void:
    if transitioning:
        return
    transitioning = true
    continue_requested = resume
    prefs.intro_seen = true
    prefs.save()
    # Remove focus and block presses during the fade; no duplicate scene loads.
    var focused := get_viewport().gui_get_focus_owner()
    if focused:
        focused.release_focus()
    veil.mouse_filter = Control.MOUSE_FILTER_STOP
    skip.disabled = true
    for child in content.get_children():
        if child is BaseButton:
            child.disabled = true
    _enter_level.call_deferred()

func _enter_level() -> void:
    var run := get_node("/root/AdventureRun")
    if continue_requested:
        selected_chapter = run.continue_saved()
        if selected_chapter < 0:
            _transition_failed("There is no saved checkpoint yet. Begin an adventure to make one.")
            return
    else: run.begin(selected_chapter)
    var flow := get_node("/root/SceneFlow")
    if not flow.failed.is_connected(_transition_failed): flow.failed.connect(_transition_failed)
    if not flow.go(run.SCENES[selected_chapter], run.NAMES[selected_chapter], "", selected_chapter):
        _transition_failed("Unable to open the adventure. Please try again.")

func _transition_failed(message: String) -> void:
    transitioning = false
    continue_requested = false
    veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    show_page("menu")
    footer.text = message

func _on_save_finished(success: bool) -> void:
    if page=="menu":footer.text="v0.7.0  •  BUBBLE POLISH" if success else get_node("/root/AdventureRun").save_message

func _resize() -> void:
    var view := get_viewport_rect().size
    background.size = view
    motes.size = view
    veil.size = view
    var window_size := Vector2(get_viewport().get_window().size)
    var safe_pixels := Rect2()
    if OS.get_name() in ["Android", "iOS"]:
        safe_pixels = Rect2(DisplayServer.get_display_safe_area())
        safe_pixels.position -= Vector2(DisplayServer.window_get_position())
    safe_frame = Controls.safe_frame(view, window_size, safe_pixels)
    ui_scale = Controls.ui_scale(view, window_size)
    ui_size = safe_frame.size / ui_scale
    ui.position = safe_frame.position
    ui.scale = Vector2.ONE * ui_scale
    ui.size = ui_size
    var w := ui_size.x
    var h := ui_size.y
    var compact := h < 760.0
    var portrait := w < h * 0.8
    var inset := 26.0 if compact or portrait else maxf(65.0, (w - 1400.0) * 0.5 + 65.0)
    var width := minf(540.0, w * 0.46 - inset) if not portrait else w - 52.0
    scroll.position = Vector2(inset, 0)
    scroll.size.x = width
    content.size.x = width
    var saved_menu: bool = page=="menu" and get_node("/root/AdventureRun").has_resume()
    content.add_theme_constant_override("separation", 9 if compact else 12 if saved_menu else 15)
    for child in content.get_children():
        if child is Label:
            if child.name == "PageTitle":
                child.add_theme_font_size_override("font_size", (44 if page == "menu" else 34) if compact or portrait else (72 if page == "menu" else 48))
            else:
                var original: int = child.get_meta("normal_font_size", 18)
                child.add_theme_font_size_override("font_size", mini(original, 18) if compact else original)
    # A stable viewport avoids scrollbar/wrapped-text size feedback on resize.
    scroll.position.y = 24.0 if compact else h * (0.22 if page == "menu" else (0.32 if page == "intro" else 0.11))
    if saved_menu and not compact: scroll.position.y=h*.14
    scroll.size.y = h - scroll.position.y - 70.0
    if portrait:
        # Portrait remains usable in the menu; the game has its landscape guard.
        scroll.position.y = maxf(235.0, h * 0.31)
        scroll.size.y = h - scroll.position.y - 62.0
    footer.position = Vector2(inset, h - 34)
    footer.size = Vector2(w - inset * 2.0, 24)
    footer.add_theme_font_size_override("font_size", 12 if compact or portrait else 15)
    skip.position = Vector2(w - 240, h - 82)
    skip.size = Vector2(214, 64)
    back_button.position = Vector2(w - 186, h - 84)
    back_button.size = Vector2(160, 64)
    var hero_height := safe_frame.size.y * (0.31 if portrait else 0.87)
    hero.size = Vector2(hero_height * 0.82, hero_height)
    hero_home = safe_frame.position + Vector2(safe_frame.size.x * (0.55 if portrait else 0.73) - hero.size.x * 0.5, safe_frame.size.y * (0.015 if portrait else 0.06))
    hero.position = hero_home
    hero.modulate.a = 0.88 if page in ["options", "controls", "credits"] else 1.0

func _process(delta: float) -> void:
    clock += delta
    lagoon_material.set_shader_parameter("menu_clock", clock)
    lagoon_material.set_shader_parameter("gentle_motion", not prefs.reduced_motion and not prefs.economy)
    hero.position=hero_home
    hero_performance.update(self,delta)
    motes.queue_redraw()
    if page == "intro" and not transitioning:
        intro_clock += delta
        var next := int(intro_clock / 3.4)
        if next >= INTRO.size():
            _finish_intro()
        elif next != intro_card:
            _set_intro_card(next)

func _draw_atmosphere() -> void:
    var view := motes.size
    var center := Vector2(view.x * 0.73, view.y * 0.42)
    for ring in range(12, 0, -1):
        motes.draw_circle(center, view.y * (0.15 + float(ring) * 0.025), Color(0.32, 0.84, 0.77, 0.008))
    var amount := 9 if prefs.economy or prefs.reduced_motion else 26
    var motion := 0.0 if prefs.reduced_motion else clock
    for i in range(amount):
        var x := fposmod(float(i) * 137.9 + sin(motion * 0.23 + i) * 18.0, view.x)
        var y := fposmod(float(i) * 89.7 - motion * (8.0 + float(i % 4) * 3.0), view.y)
        var radius := (2.0 + float(i % 4)) * ui_scale
        motes.draw_circle(Vector2(x,y), radius, Color(0.75, 1.0, 0.95, 0.16), false, 1.0, true)
    # Soft dark backing keeps every label readable over the painting.
    for strip in range(40):
        var alpha := 0.33 * (1.0 - float(strip) / 40.0)
        motes.draw_rect(Rect2(float(strip) * view.x * 0.017, 0, view.x * 0.017, view.y), Color(0.015, 0.055, 0.095, alpha))

func _unhandled_input(event: InputEvent) -> void:
    if transitioning:
        return
    var back: bool = event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE
    back = back or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B)
    if page == "intro":
        if back or event.is_action_pressed("ui_accept") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
            _finish_intro()
            get_viewport().set_input_as_handled()
    elif back and page != "menu":
        show_page("options" if page == "controls" else "menu")
        get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        set_process(false)
        if is_instance_valid(music_player):
            music_player.stream_paused = true
    elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
        set_process(true)
        if is_instance_valid(music_player):
            music_player.stream_paused = false


func _add_chapter_button(index: int, title: String) -> void:
    var callback := func():
        _request_begin(index)
    var display_title: String = {5:"Rana Rex’s Ruin",6:"Nessie · Crown Thief",7:"Family Tutorial · Avina’s Peekaboo"}.get(index,title)
    var button := _add_button(display_title, callback)
    var run := get_node("/root/AdventureRun")
    var stars: int = run.chapter_stars(index)
    if stars>0: button.text += "  "+"★".repeat(stars)
    button.clip_text = true
    button.tooltip_text = title+(" · Best "+preload("res://godot/ui_kit.gd").number(run.chapter_best(index)) if stars>0 else "")
    if not chapter_thumbnails.has(index):
        var artwork: Texture2D = load(CHAPTER_ART[index])
        var image := artwork.get_image() if artwork else null
        if image:
            image.resize(128, maxi(1, int(128.0*image.get_height()/image.get_width())), Image.INTERPOLATE_LANCZOS)
            chapter_thumbnails[index] = ImageTexture.create_from_image(image)
    if chapter_thumbnails.has(index): button.icon = chapter_thumbnails[index]
    button.add_theme_constant_override("icon_max_width", 84)
    button.add_theme_constant_override("h_separation", 18)
    button.add_theme_font_size_override("font_size", 19)
    button.custom_minimum_size.y = 78
    button.alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

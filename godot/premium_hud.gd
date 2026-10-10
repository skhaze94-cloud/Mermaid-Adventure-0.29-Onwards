extends CanvasLayer
signal menu_requested
const Controls = preload("res://godot/control_layout.gd")
const Kit = preload("res://godot/ui_kit.gd")
const Card = preload("res://godot/ui_card.tscn")
var canvas: Control
var info: Dictionary = {}
var game_size := Vector2(1400,960)
var ui_scale := 1.0
var safe_frame := Rect2(0,0,1400,960)
var portrait := false
var redraw_count := 0
var skipped_redraws := 0
var score_card: PanelContainer
var score_label: Label
var pearl_label: Label
var combo_label: Label
var combo_meter: ProgressBar
var health_card: PanelContainer
var hearts: Array[TextureRect] = []
var energy_meter: ProgressBar
var route: ProgressBar
var chapter: Label
var modal_reveal: Tween
var message_back: Panel
var message_label: Label
var boss_card: PanelContainer
var boss_label: Label
var boss_meter: ProgressBar
var touch_layer: Control
var modal: Control
var modal_card: PanelContainer
var modal_content: VBoxContainer
var header_crest: TextureRect
var result_scroll: ScrollContainer
var result_title: Label
var breakdown: VBoxContainer
var result_total: Label
var record_label: Label
var rating_label: Label
var reward_label: Label
var stars: Array[TextureRect] = []
var modal_buttons: Dictionary = {}
var menu_button: Button
var rotate_label: Label
var floating: Array[Label] = []
var float_ages: Array[float] = []
var float_origins: Array[Vector2] = []
var banner: Control
var banner_label: Label
var banner_age := 99.0
var banner_sparkles: Array[TextureRect] = []
var shown_score := 0.0
var score_pulse := 0.0
var results_elapsed := 0.0
var result_rows: Array[Label] = []
var result_values: Array[int] = []
var result_seen := false
var control_size := 1.0
var control_opacity := 0.85
var touch_normal: StyleBoxFlat
var touch_pressed: StyleBoxFlat

func _ready() -> void:
    layer = 6
    canvas = Control.new()
    canvas.name = "PearlAndCrownHUD"
    canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.theme = Kit.theme()
    touch_normal = Kit.panel(Color(0.015,0.10,0.17,0.80),Color("#59bfc4"),28)
    touch_pressed = Kit.panel(Color("#145565"),Color("#ffb7e5"),28)
    add_child(canvas)
    score_card = Card.instantiate()
    canvas.add_child(score_card)
    var score_box := VBoxContainer.new()
    score_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    score_card.add_child(score_box)
    var row := HBoxContainer.new()
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    score_box.add_child(row)
    row.add_child(Kit.icon("shell",Vector2(52,52)))
    var figures := VBoxContainer.new()
    row.add_child(figures)
    figures.add_child(Kit.label("ADVENTURE SCORE",11,Color("#acdcd9")))
    score_label = Kit.label("0",26,Color("#ffe3a1"))
    figures.add_child(score_label)
    pearl_label = Kit.label("0 pearls",14)
    score_box.add_child(pearl_label)
    combo_label = Kit.label("",14,Color("#ffb7ec"))
    canvas.add_child(combo_label)
    combo_meter = _meter(canvas)
    health_card = Card.instantiate()
    canvas.add_child(health_card)
    var health_box := VBoxContainer.new()
    health_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    health_card.add_child(health_box)
    var health_row := HBoxContainer.new()
    health_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    health_row.add_theme_constant_override("separation",4)
    health_box.add_child(health_row)
    for i in range(5):
        var heart := Kit.icon("heart",Vector2(26,26))
        health_row.add_child(heart)
        hearts.append(heart)
    health_box.add_child(Kit.label("MERMAID ENERGY",10,Color("#acdcd9")))
    energy_meter = _meter(health_box)
    energy_meter.custom_minimum_size.y = 12
    chapter = Kit.label("HIGHLAND GOLD",12,Color("#c6f2e6"))
    canvas.add_child(chapter)
    route = _meter(canvas)
    message_back = Panel.new()
    message_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
    message_back.add_theme_stylebox_override("panel", Kit.panel(Color(0.025,0.12,0.18,0.88),Color(0.32,0.72,0.73,0.4),10))
    canvas.add_child(message_back)
    message_label = Kit.label("",15)
    message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    canvas.add_child(message_label)
    boss_card = Card.instantiate()
    canvas.add_child(boss_card)
    var boss_box := VBoxContainer.new()
    boss_card.add_child(boss_box)
    boss_label = Kit.label("CARLO THE CRAB",14,Color("#ffe3a1"))
    boss_box.add_child(boss_label)
    boss_meter = _meter(boss_box)
    boss_meter.custom_minimum_size.y = 12
    touch_layer = Control.new()
    touch_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(touch_layer)
    touch_layer.draw.connect(_draw_touch)
    modal = Control.new()
    modal.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(modal)
    var scrim := ColorRect.new()
    scrim.name = "ModalScrim"
    scrim.color = Color(0.01,0.035,0.08,0.88)
    scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
    modal.add_child(scrim)
    modal_card = Card.instantiate()
    modal.add_child(modal_card)
    modal_content = VBoxContainer.new()
    modal_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
    modal_content.add_theme_constant_override("separation",4)
    modal_card.add_child(modal_content)
    result_title = Kit.label("",26,Color("#ffe3a1"))
    result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    result_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var heading := HBoxContainer.new()
    heading.alignment = BoxContainer.ALIGNMENT_CENTER
    heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
    header_crest = Kit.icon("crest",Vector2(56,56))
    heading.add_child(header_crest)
    heading.add_child(result_title)
    modal_content.add_child(heading)
    var star_row := HBoxContainer.new()
    star_row.alignment = BoxContainer.ALIGNMENT_CENTER
    modal_content.add_child(star_row)
    for i in range(3):
        var star := Kit.icon("star",Vector2(40,40))
        star_row.add_child(star)
        stars.append(star)
    rating_label = Kit.label("",12,Color("#a9dfdd"))
    rating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    rating_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    modal_content.add_child(rating_label)
    var scroll := ScrollContainer.new()
    result_scroll = scroll
    scroll.name = "ScoreBreakdownScroll"
    scroll.custom_minimum_size.y = 108
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    modal_content.add_child(scroll)
    breakdown = VBoxContainer.new()
    breakdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    breakdown.mouse_filter = Control.MOUSE_FILTER_IGNORE
    scroll.add_child(breakdown)
    result_total = Kit.label("",24,Color("#ffe3a1"))
    result_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    modal_content.add_child(result_total)
    record_label = Kit.label("",14,Color("#ffb7ec"))
    record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var record_row := HBoxContainer.new()
    record_row.alignment = BoxContainer.ALIGNMENT_CENTER
    record_row.add_child(Kit.icon("crown",Vector2(26,26)))
    record_row.add_child(record_label)
    modal_content.add_child(record_row)
    reward_label = Kit.label("",13,Color("#a9f4de"))
    reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    modal_content.add_child(reward_label)
    for action in ["resume","restart","menu"]:
        var button := Button.new()
        button.mouse_filter = Control.MOUSE_FILTER_IGNORE
        button.text = {"resume":"Resume adventure","restart":"Play again","menu":"Back to the lagoon"}[action]
        button.icon = Kit.ICONS["home" if action == "menu" else ("restart" if action == "restart" else "jump")]
        button.expand_icon = true
        button.add_theme_constant_override("icon_max_width",26)
        button.pressed.connect(func(): _modal_action(action))
        modal.add_child(button)
        modal_buttons[action] = button
    menu_button = modal_buttons["menu"]
    rotate_label = Kit.label("ROTATE TO LANDSCAPE\nYour adventure is paused",24,Color("#ffe3a1"))
    rotate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    canvas.add_child(rotate_label)
    for i in range(12):
        var point_label := Kit.label("",20)
        point_label.visible = false
        canvas.add_child(point_label)
        floating.append(point_label)
        float_ages.append(99.0)
        float_origins.append(Vector2.ZERO)
    banner = Control.new()
    banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.add_child(banner)
    var ribbon := Kit.icon("ribbon")
    ribbon.stretch_mode = TextureRect.STRETCH_SCALE
    ribbon.position = Vector2.ZERO
    ribbon.size = Vector2(240,80)
    banner.add_child(ribbon)
    banner_label = Kit.label("",20,Color("#fff2ba"))
    banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    banner_label.position = Vector2(12,22)
    banner_label.size = Vector2(216,42)
    banner.add_child(banner_label)
    for i in range(5):
        var sparkle := Kit.icon("star",Vector2(12,12))
        banner.add_child(sparkle)
        banner_sparkles.append(sparkle)
    banner.visible = false
    _ignore_decoration(canvas)
    get_viewport().size_changed.connect(_resize)
    _resize()

func _ignore_decoration(node: Node) -> void:
    if node is Control and not node is ScrollContainer and not node is ScrollBar:
        node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    for child in node.get_children(): _ignore_decoration(child)

func _meter(parent: Node) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.show_percentage = false
    bar.max_value = 1.0
    bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(bar)
    return bar
func _modal_action(action: String) -> void:
    get_node("/root/OceanAudio").play("ui",0)
    if action == "menu": menu_requested.emit()
    else: get_parent()._touch_action(action)
func _resize() -> void:
    var pixels := Vector2(get_viewport().get_window().size)
    var safe := Rect2()
    if OS.get_name() in ["Android","iOS"]:
        safe = Rect2(DisplayServer.get_display_safe_area())
        safe.position -= Vector2(DisplayServer.window_get_position())
    configure_layout(get_viewport().get_visible_rect().size,pixels,safe)
func configure_layout(viewport_size: Vector2, window_size: Vector2, safe_pixels := Rect2()) -> void:
    safe_frame = Controls.safe_frame(viewport_size,window_size,safe_pixels)
    ui_scale = Controls.ui_scale(viewport_size,window_size)
    game_size = safe_frame.size/ui_scale
    portrait = window_size.y>window_size.x
    canvas.position = safe_frame.position
    canvas.scale = Vector2.ONE*ui_scale
    canvas.size = game_size
    var prefs = get_node_or_null("/root/AppPreferences")
    if prefs:
        control_size = prefs.touch_size
        control_opacity = prefs.touch_opacity
    var w := game_size.x
    var h := game_size.y
    score_card.position = Vector2(14,14)
    score_card.size = Vector2(minf(260,w*0.38),100)
    health_card.position = Vector2(w-190-(82 if info.get("touch",false) else 0),14)
    health_card.size = Vector2(176,92)
    combo_label.position = Vector2(18,117)
    combo_meter.position = Vector2(18,140)
    combo_meter.size = Vector2(minf(240,w*0.34),8)
    chapter.position = Vector2(18,155)
    route.position = Vector2(16,h-12)
    route.size = Vector2(w-32,6)
    var message_width := minf(w-40,740)
    message_back.position = Vector2((w-message_width)*0.5,174)
    message_back.size = Vector2(message_width,29)
    message_label.position = message_back.position + Vector2(8,2)
    message_label.size = Vector2(message_width-16,25)
    boss_card.position = Vector2((w-minf(w-40,340))/2,150 if h<720 else 204)
    boss_card.size = Vector2(minf(w-40,340),66)
    touch_layer.size = game_size
    modal.size = game_size
    modal.get_node("ModalScrim").size = game_size
    modal_card.position = Vector2((w-minf(w-36,540))/2,maxf(16,(h-550)/2))
    header_crest.custom_minimum_size = Vector2.ONE*(40 if h<600 else 74)
    for star in stars: star.custom_minimum_size = Vector2.ONE*(28 if h<600 else 40)
    result_scroll.custom_minimum_size.y = 54 if h<600 else 108
    result_title.add_theme_font_size_override("font_size",22 if h<600 else 26)
    modal_card.size = Vector2(minf(w-36,540),minf(h-135,430))
    for action in modal_buttons:
        var rect := action_rect(action)
        modal_buttons[action].position = rect.position
        modal_buttons[action].size = rect.size
    rotate_label.position = Vector2(0,h*0.43)
    rotate_label.size = Vector2(w,90)
    banner.position = Vector2(w-258,118)
    _refresh()
func to_ui(point: Vector2) -> Vector2: return (point-safe_frame.position)/ui_scale
func to_game(rect: Rect2) -> Rect2: return Rect2(safe_frame.position+rect.position*ui_scale,rect.size*ui_scale)
func pad_rect() -> Rect2:
    var rect := Controls.pad_rect(game_size)
    var factor := maxf(1.0,control_size)
    rect.position.y = game_size.y-16-rect.size.y*factor
    rect.size *= factor
    return rect
func pad_vector(point: Vector2) -> Vector2:
    var offset := (point-pad_rect().get_center())/maxf(1.0,control_size)
    if offset.length() <= 18: return Vector2.ZERO
    return offset.normalized()*clampf((offset.length()-18)/24,0,1)
func action_rect(action: String) -> Rect2:
    if info.get("paused",false) and action in ["resume","restart","menu"]:
        return Rect2(game_size.x*0.5-135,modal_card.position.y+modal_card.size.y+10+["resume","restart","menu"].find(action)*54,270,48)
    if info.get("victory",false) and action in ["restart","menu"]:
        return Rect2(game_size.x*0.5-120,modal_card.position.y+modal_card.size.y+(70 if action == "menu" else 10),240,40 if action == "menu" else 50)
    if action == "menu": return Rect2(game_size.x*0.5-135,game_size.y*0.5+139,270,64)
    var rect := Controls.rect(action,game_size)
    if action in ["boost","jump","bubble"]:
        var center := rect.get_center()
        rect.size *= maxf(1.0,control_size)
        rect.position = center-rect.size/2
        rect.position.x = clampf(rect.position.x,12,game_size.x-12-rect.size.x)
    return rect
func update_hud(next_info: Dictionary) -> void:
    if info == next_info: skipped_redraws += 1
    else: redraw_count += 1
    var was_paused: bool = info.get("paused",false)
    var was_victory: bool = info.get("victory",false)
    info = next_info
    if bool(info.get("victory",false)) and not was_victory:
        _build_results()
        configure_layout(get_viewport().get_visible_rect().size,Vector2(get_viewport().get_window().size))
    elif was_victory and not bool(info.get("victory",false)):
        result_seen = false
    _refresh()
    if (bool(info.get("victory",false)) and not was_victory) or (bool(info.get("paused",false)) and not was_paused):
        if modal_reveal: modal_reveal.kill()
        modal.modulate.a = 1.0 if info.get("reduced",false) else 0.0
        if not info.get("reduced",false):
            modal_reveal = create_tween()
            modal_reveal.tween_property(modal, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE)
    if bool(info.get("victory",false)) and not was_victory: modal_buttons["restart"].grab_focus()
    elif bool(info.get("paused",false)) and not was_paused: modal_buttons["resume"].grab_focus()
func _refresh() -> void:
    if not is_instance_valid(score_card): return
    rotate_label.visible = portrait
    score_card.visible = not portrait
    health_card.visible = not portrait
    health_card.position.x = game_size.x-190-(82 if info.get("touch",false) else 0)
    for i in range(5): hearts[i].modulate = Color.WHITE if i<int(info.get("health",5)) else Color(0.28,0.38,0.46,0.5)
    energy_meter.value = info.get("energy",1.0)
    pearl_label.text = "%s pearls" % Kit.number(int(info.get("pearls",0)))
    var combo := int(info.get("combo",1))
    combo_label.text = "COMBO! ×%s" % combo if combo>1 else ""
    combo_meter.visible = combo>1 and not portrait
    combo_meter.value = float(info.get("combo_left",0))/3.0
    combo_label.visible = not portrait
    chapter.text = "THE WATERFALL" if info.get("waterfall","") != "" else info.get("chapter","HIGHLAND GOLD · STAGE 1")
    chapter.visible = not portrait and not (game_size.y<720 and info.get("boss_active",false))
    route.value = info.get("fall_progress" if info.get("waterfall","") != "" else "progress",0)
    route.visible = not portrait
    message_label.text = info.get("message","") if info.get("message_time",0)>0 else ""
    message_label.visible = not portrait and not info.get("boss_active",false) and not modal.visible
    message_back.visible = message_label.visible and not message_label.text.is_empty()
    var hint_alpha := clampf(float(info.get("message_time",0))/0.3,0.0,1.0)
    message_label.modulate.a = hint_alpha
    message_back.modulate.a = hint_alpha
    boss_card.visible = info.get("boss_active",false) and not portrait
    boss_meter.value = info.get("boss_health",1.0)
    boss_label.text = info.get("boss_name","CARLO THE CRAB") + (" · BOOST!" if info.get("boss_vulnerable",false) else "")
    touch_layer.visible = info.get("touch",false) and not portrait and not info.get("paused",false) and not info.get("victory",false)
    touch_layer.modulate.a = control_opacity
    touch_layer.queue_redraw()
    modal.visible = info.get("paused",false) or info.get("victory",false) or portrait
    modal_card.visible = not portrait
    if modal.visible:
        banner.visible = false
        for label in floating: label.visible = false
    for action in modal_buttons:
        modal_buttons[action].visible = modal.visible and not portrait and (action != "resume" or not info.get("victory",false))
        var rect := action_rect(action)
        modal_buttons[action].position = rect.position
        modal_buttons[action].size = rect.size
    modal_buttons["restart"].text = "Next chapter  ›" if info.get("victory",false) and info.get("next_stage","") != "" else ("Back to menu" if info.get("victory",false) and info.get("journey_final",false) else "Play again")
    if not info.get("victory",false):
        result_title.text = "A MOMENT TO BREATHE"
        rating_label.text = "Your ocean adventure will be here."
        result_total.text = "Score  "+Kit.number(int(info.get("score",0)))
        record_label.text = "Take your time. Find your fins."
        record_label.autowrap_mode = TextServer.AUTOWRAP_OFF
        reward_label.text = "Ready when you are, Sarah Maria."
        for star in stars: star.visible = false
        for label in result_rows: label.visible = false
func show_reward(reward: Dictionary, at: Vector2) -> void:
    var slot := 0
    for i in range(float_ages.size()):
        if float_ages[i]>float_ages[slot]: slot=i
    var category := String(reward["category"])
    var major := int(reward["points"])>=100
    floating[slot].text = "+%s" % Kit.number(int(reward["points"]))
    floating[slot].add_theme_color_override("font_color",Color("#ffe19c") if major else (Color("#bdfded") if category == "Pearls" else Color("#ffc3ed")))
    floating[slot].add_theme_font_size_override("font_size",24 if major else 19)
    var ui := to_ui(at)+Vector2(-18,-65)
    ui.x = clampf(ui.x,20,game_size.x-140)
    ui.y = clampf(ui.y,210,game_size.y-190)
    float_origins[slot] = ui
    float_ages[slot] = 0
    floating[slot].visible = true
    score_pulse = 1.0
    if (major or int(reward["extra"])>0) and banner_age>0.7:
        banner_label.text = "Treasure Bonus!" if category == "Treasure" else ("Combo! ×%s" % reward["multiplier"] if reward["extra"]>0 else "Wonderful! +%s" % reward["points"])
        banner_age = 0.0
        banner.visible = true
        # Keep the celebration on the opposite side from the action.
        banner.position.x = 18 if to_ui(at).x>game_size.x*0.65 else game_size.x-258
func clear_feedback() -> void:
    for i in range(floating.size()):
        floating[i].visible = false
        float_ages[i] = 99
    banner.visible = false
    banner_age = 99
    shown_score = 0.0
    score_pulse = 0.0
func _build_results() -> void:
    for child in breakdown.get_children():
        breakdown.remove_child(child)
        child.queue_free()
    result_rows.clear()
    result_values.clear()
    var results: Dictionary = info.get("results",{})
    result_title.text = "ADVENTURE COMPLETE" if info.get("journey_final",false) else "STAGE CLEAR!"
    var details: Dictionary = results.get("breakdown",{})
    for category in details:
        if int(details[category]) == 0: continue
        var label := Kit.label("",15)
        breakdown.add_child(label)
        result_rows.append(label)
        result_values.append(int(details[category]))
        label.set_meta("category",category)
    rating_label.text = results.get("rules","1 star: clear · 2: 3,000 · 3: 6,000")
    record_label.text = ("New Record!  " if results.get("new_record",false) else "Personal best  ")+Kit.number(int(results.get("best",0)))
    reward_label.text = results.get("reward","")+(" · Perfect! +250" if results.get("perfect",false) else "")+(" · Pearl Bonus! +100" if results.get("pearl_bonus",false) else "")
    if info.get("next_stage","") != "": reward_label.text += "\nNext: " + String(info["next_stage"])
    reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    for i in range(3):
        stars[i].visible = true
        stars[i].modulate = Color.WHITE if i<int(results.get("stars",1)) else Color(0.25,0.4,0.5,0.65)
    results_elapsed = 0.0
    result_seen = true
func _process(dt: float) -> void:
    if info.is_empty(): return
    var reduced: bool = info.get("reduced",false)
    var target := float(info.get("score",0))
    if target < shown_score or reduced: shown_score = target
    elif not info.get("paused",false): shown_score = move_toward(shown_score,target,maxf(1,(target-shown_score)*minf(dt*9,1)))
    score_label.text = Kit.number(roundi(shown_score))
    score_label.add_theme_font_size_override("font_size",26 if score_label.text.length()<10 else 20)
    if not info.get("paused",false): score_pulse = maxf(0,score_pulse-dt*4)
    score_label.scale = Vector2.ONE*(1.0+(0.0 if reduced else sin(score_pulse*PI)*0.055))
    if modal.visible and not portrait:
        result_scroll.visible = bool(info.get("victory",false))
        modal_card.size = Vector2(minf(game_size.x-36,540),minf(game_size.y-(135 if info.get("victory",false) else 200),430 if info.get("victory",false) else 230))
        for action in modal_buttons:
            var rect := action_rect(action)
            modal_buttons[action].position = rect.position
            modal_buttons[action].size = rect.size
    if info.get("victory",false):
        banner.visible = false
        for label in floating: label.visible = false
        results_elapsed += dt
        var factor := 1.0 if reduced else smoothstep(0,1,clampf(results_elapsed/1.4,0,1))
        for i in range(result_rows.size()): result_rows[i].text = "%s    %s" % [result_rows[i].get_meta("category"),Kit.number(roundi(result_values[i]*factor))]
        result_total.text = "TOTAL  "+Kit.number(roundi(target*factor))
        return
    if info.get("paused",false):
        banner.visible = false
        for label in floating: label.visible = false
        return
    for i in range(floating.size()):
        float_ages[i] += dt
        var age := float_ages[i]
        floating[i].visible = age<0.9 and not portrait
        floating[i].position = float_origins[i]+Vector2(0,0 if reduced else -age*35)
        floating[i].modulate.a = clampf((0.9-age)/0.3,0,1)
    banner_age += dt
    banner.visible = banner_age<1.5 and not portrait
    banner.modulate.a = minf(clampf(banner_age/0.12,0,1),clampf((1.5-banner_age)/0.25,0,1))
    banner.scale = Vector2.ONE*(1.0 if reduced else 0.94+0.06*smoothstep(0,1,clampf(banner_age/0.25,0,1)))
    for i in range(banner_sparkles.size()):
        var spark := banner_sparkles[i]
        spark.visible = not reduced and banner_age>0.18
        spark.position = Vector2(24+i*46,12-sin(banner_age*4+i)*8)
        spark.modulate.a = maxf(0,sin(banner_age*4+i))
func _draw_touch() -> void:
    var pad := pad_rect()
    var center := pad.get_center()
    var factor := control_size
    var direction: Vector2 = info.get("pad",Vector2.ZERO)
    touch_layer.draw_texture_rect(Kit.ICONS["joystick"],Rect2(center-Vector2(78,66)*factor,Vector2(156,132)*factor),false)
    if direction.length()>0.05:
        touch_layer.draw_line(center,center+direction*42*maxf(1,factor),Color("#a5fff5"),4)
    touch_layer.draw_texture_rect(Kit.ICONS["thumb"],Rect2(center+direction*42*maxf(1,factor)-Vector2(24,24)*factor,Vector2(48,48)*factor),false)
    for action in ["jump","boost","bubble","pause"]:
        var rect := action_rect(action)
        var locked: bool = action == "bubble" and not info.get("bubble",false)
        var available: bool = action not in ["jump","boost"] or float(info.get("energy",1.0))>=0.4
        var pressed: bool = action in info.get("pressed",[])
        var style := touch_pressed if pressed else touch_normal
        touch_layer.draw_style_box(style,rect)
        var icon_size := minf(rect.size.x,rect.size.y)*0.64*minf(1,factor)
        var icon_at := rect.get_center()-Vector2.ONE*icon_size/2+Vector2(0,-5)
        touch_layer.draw_texture_rect(Kit.ICONS[action],Rect2(icon_at,Vector2.ONE*icon_size),false,Color(0.4,0.5,0.6,0.55) if locked or not available else Color.WHITE)
        var label: String = "LOCKED" if locked else ("LOW ENERGY" if not available else String(action).to_upper())
        touch_layer.draw_string(ThemeDB.fallback_font,rect.position+Vector2(0,rect.size.y-10),label,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,11,Color("#defdf5"))
        var cool := float(info.get("cooldowns",{}).get(action,0))
        if cool>0:
            touch_layer.draw_arc(rect.get_center(),minf(rect.size.x,rect.size.y)*0.43,-PI/2,-PI/2+TAU*clampf(cool/(0.20 if action == "bubble" else 0.9),0,1),32,Color("#ffe2ad"),3)

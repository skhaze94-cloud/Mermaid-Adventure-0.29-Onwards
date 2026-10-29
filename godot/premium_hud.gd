extends CanvasLayer
signal menu_requested
const Polish = preload("res://godot/visual_polish.gd")
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
var boss_hint: Label
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
var touch_signature: Array = []
var touch_redraws := 0
var charge_card: PanelContainer
var charge_label: Label
var charge_meter: ProgressBar
var ready_notice_left := 0.0
var last_bubble_cooldown := 0.0
var displayed_score := -1
var results_settled := false
var result_text_updates := 0
var modal_layout_signature: Array = []
var modal_layout_updates := 0

func _ready() -> void:
    layer = 6
    canvas = Control.new()
    canvas.name = "PearlAndCrownHUD"
    canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
    canvas.theme = Kit.theme()
    touch_normal = Kit.panel(Color(0.025,0.12,0.18,0.94),Color("#6fc9c7"),22)
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
    charge_card = PanelContainer.new()
    charge_card.add_theme_stylebox_override("panel",Kit.panel(Color(0.025,0.12,0.18,0.94),Color("#a8e8f1"),16))
    canvas.add_child(charge_card)
    var charge_box := VBoxContainer.new()
    charge_card.add_child(charge_box)
    charge_label = Kit.label("Bubble ready",14,Color("#dfffee"))
    charge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    charge_box.add_child(charge_label)
    charge_meter = _meter(charge_box)
    charge_meter.custom_minimum_size.y = 8
    charge_card.hide()
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
    boss_label = Kit.label("CARLO THE CRAB",16,Color("#ffe3a1"))
    boss_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
    boss_box.add_child(boss_label)
    boss_meter = _meter(boss_box)
    boss_meter.custom_minimum_size.y = 12
    boss_hint = Kit.label("",12,Color("#bde8e3"))
    boss_hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    boss_hint.hide()
    boss_box.add_child(boss_hint)
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
    var toast := Panel.new()
    toast.name="RewardToast"
    toast.mouse_filter=Control.MOUSE_FILTER_IGNORE
    toast.size=Vector2(240,48)
    toast.add_theme_stylebox_override("panel",Kit.panel(Color("#103847"),Color("#6cbcb9"),12))
    banner.add_child(toast)
    banner_label=Kit.label("",17,Color("#ffe4b0"))
    banner_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    banner_label.position=Vector2(10,7)
    banner_label.size=Vector2(220,34)
    banner.add_child(banner_label)
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
    chapter.position = Vector2(18,130)
    route.position = Vector2(16,h-12)
    route.size = Vector2(w-32,6)
    charge_card.position = Vector2((w-230)*.5,h-92)
    charge_card.size = Vector2(230,64)
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
    banner.position = Vector2(w-258,126)
    modal_layout_signature.clear()
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
        if action in ["jump","bubble"]:
            rect.position.y-=maxf(0.0,control_size-1.0)*180.0
        rect.position.x = clampf(rect.position.x,12,game_size.x-12-rect.size.x)
    return rect
func update_hud(next_info: Dictionary) -> void:
    if info == next_info:
        skipped_redraws += 1
        return
    redraw_count += 1
    var was_paused: bool = info.get("paused",false)
    var was_victory: bool = info.get("victory",false)
    # Keep our comparison snapshot independent of callers that reuse a Dictionary.
    # An in-place pause/results update must still invalidate the visible controls.
    info = next_info.duplicate(true)
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
    var critical_boss: bool = info.get("boss_active",false) and info.get("message_priority",false) and float(info.get("message_time",0))>0
    var compact_priority := critical_boss and game_size.y<720
    combo_meter.visible = combo>1 and not portrait and not compact_priority
    combo_meter.value = float(info.get("combo_left",0))/3.0
    combo_label.visible = combo>1 and not portrait and not compact_priority
    chapter.position.y=155.0 if combo>1 else 130.0
    chapter.text = "The waterfall" if info.get("waterfall","") != "" else String(info.get("chapter","Highland Gold")).split(" · ")[0].capitalize()
    chapter.visible = not portrait and not (game_size.y<720 and info.get("boss_active",false))
    route.value = info.get("fall_progress" if info.get("waterfall","") != "" else "progress",0)
    route.visible = not portrait
    message_label.text = info.get("message","") if info.get("message_time",0)>0 else ""
    var message_width := minf(game_size.x-40,340 if compact_priority else 740)
    message_back.size.x = message_width
    message_back.position = Vector2((game_size.x-message_width)*.5,boss_card.position.y-34 if critical_boss else 174)
    message_label.position = message_back.position+Vector2(8,2)
    message_label.size.x = message_width-16
    message_label.visible = not portrait and (not info.get("boss_active",false) or critical_boss) and not info.get("paused",false) and not info.get("victory",false)
    message_back.visible = message_label.visible and not message_label.text.is_empty()
    var hint_alpha := clampf(float(info.get("message_time",0))/0.3,0.0,1.0)
    message_label.modulate.a = hint_alpha
    message_back.modulate.a = hint_alpha
    boss_card.visible = info.get("boss_active",false) and not portrait
    boss_meter.value = info.get("boss_health",1.0)
    boss_label.text = String(info.get("boss_name","Carlo the Crab")).split(" · ")[0].capitalize() + ((" · Hit now" if info.get("bubble",false) else " · Boost now") if info.get("boss_vulnerable",false) else "")
    boss_hint.text = String(info.get("boss_attack",""))
    if info.get("boss_vulnerable",false) and not boss_hint.text.is_empty(): boss_hint.text="Mint petals · Bubble or Boost now"
    boss_hint.visible = not boss_hint.text.is_empty()
    touch_layer.visible = info.get("touch",false) and not portrait and not info.get("paused",false) and not info.get("victory",false)
    touch_layer.modulate.a = control_opacity
    # Preserve every joystick/cooldown frame; unrelated score, message and
    # progress changes do not rebuild the same touch geometry and labels.
    var next_touch: Array = [game_size,control_size,info.get("pad",Vector2.ZERO),
        info.get("pressed",[]),info.get("bubble",false),float(info.get("energy",1.0))>=0.4,
        info.get("cooldowns",{}).duplicate(),info.get("charge_tier",0),
        roundi(float(info.get("charge_progress",0))*64),info.get("bubble_recovery",0.2)]
    if next_touch != touch_signature:
        touch_signature = next_touch.duplicate(true)
        touch_layer.queue_redraw()
        touch_redraws += 1
    modal.visible = info.get("paused",false) or info.get("victory",false) or portrait
    modal_card.visible = not portrait
    if modal.visible:
        banner.visible = false
        for label in floating: label.visible = false
    for action in modal_buttons:
        modal_buttons[action].visible = modal.visible and not portrait and (action != "resume" or not info.get("victory",false))
    _layout_modal()
    var cooldown := float(info.get("cooldowns",{}).get("bubble",0))
    if last_bubble_cooldown>0 and cooldown<=0 and not info.get("paused",false): ready_notice_left=0.8
    if int(info.get("charge_tier",0))>0: ready_notice_left=0
    last_bubble_cooldown=cooldown
    _refresh_charge()
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

func _layout_modal() -> void:
    var signature: Array = [game_size,modal.visible,portrait,info.get("victory",false)]
    if signature == modal_layout_signature: return
    modal_layout_signature = signature
    modal_layout_updates += 1
    if modal.visible and not portrait:
        result_scroll.visible = bool(info.get("victory",false))
        modal_card.size = Vector2(minf(game_size.x-36,540),minf(game_size.y-(135 if info.get("victory",false) else 200),430 if info.get("victory",false) else 230))
    for action in modal_buttons:
        var rect := action_rect(action)
        modal_buttons[action].position = rect.position
        modal_buttons[action].size = rect.size

func bubble_cooldown_fraction() -> float:
    return clampf(float(info.get("cooldowns",{}).get("bubble",0))/maxf(.001,float(info.get("bubble_recovery",.2))),0,1)

func bubble_button_label() -> String:
    if not info.get("bubble",false): return "LOCKED"
    if float(info.get("cooldowns",{}).get("bubble",0))>0: return "COOLING"
    var tier := int(info.get("charge_tier",0))
    return "RELEASE!" if tier==3 else "PRISM BLOOM" if tier==2 else "CHARGING" if tier==1 else "HOLD BUBBLE"

func _refresh_charge() -> void:
    var tier := int(info.get("charge_tier",0))
    var cooling: bool = float(info.get("cooldowns",{}).get("bubble",0))>0
    charge_card.visible = info.get("bubble",false) and not info.get("touch",false) and not portrait and not modal.visible and (tier>0 or cooling or ready_notice_left>0)
    if not charge_card.visible: return
    charge_label.text = ["Bubble ready","Pearl Pop · keep holding","Prism Bloom · keep holding","Royal Aurora · release!"][clampi(tier,0,3)]
    if cooling: charge_label.text = "Bubble cooling"
    charge_meter.value = 1-bubble_cooldown_fraction() if cooling else float(info.get("charge_progress",1)) if tier>0 else 1.0
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
    displayed_score = -1
    score_pulse = 0.0
func _build_results() -> void:
    for child in breakdown.get_children():
        breakdown.remove_child(child)
        child.queue_free()
    result_rows.clear()
    result_values.clear()
    var results: Dictionary = info.get("results",{})
    var finale: bool = info.get("journey_final",false)
    result_title.text = "THE CROWN IS HOME!" if finale else "STAGE CLEAR!"
    header_crest.texture = Kit.ICONS["crown" if finale else "crest"]
    var details: Dictionary = results.get("breakdown",{})
    if finale and not info.get("adventure_breakdown",{}).is_empty(): details=info["adventure_breakdown"]
    for category in details:
        if int(details[category]) == 0: continue
        var label := Kit.label("",15)
        breakdown.add_child(label)
        result_rows.append(label)
        result_values.append(int(details[category]))
        label.set_meta("category",category)
    rating_label.text = results.get("rules","1 star: clear · 2: 3,000 · 3: 6,000")
    if finale: rating_label.text = "%s chapters explored · Nessie’s crown returned\n%s" % [info.get("chapters_complete",1),rating_label.text]
    record_label.text = ("New Record!  " if results.get("new_record",false) else "Personal best  ")+Kit.number(int(results.get("best",0)))
    reward_label.text = results.get("reward","")+(" · Perfect! +250" if results.get("perfect",false) else "")+(" · Pearl Bonus! +100" if results.get("pearl_bonus",false) else "")
    if info.get("next_stage","") != "": reward_label.text += "\nNext: " + String(info["next_stage"])
    reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    for i in range(3):
        stars[i].visible = true
        stars[i].modulate = Color.WHITE if i<int(results.get("stars",1)) else Color(0.25,0.4,0.5,0.65)
    results_elapsed = 0.0
    results_settled = false
    result_seen = true
func _process(dt: float) -> void:
    if info.is_empty(): return
    var reduced: bool = info.get("reduced",false)
    var target := float(info.get("score",0))
    if target < shown_score or reduced: shown_score = target
    elif not info.get("paused",false): shown_score = move_toward(shown_score,target,maxf(1,(target-shown_score)*minf(dt*9,1)))
    if displayed_score != roundi(shown_score):
        displayed_score = roundi(shown_score)
        score_label.text = Kit.number(displayed_score)
    var score_size := 26 if score_label.text.length()<10 else 20
    if score_label.get_theme_font_size("font_size") != score_size:
        score_label.add_theme_font_size_override("font_size",score_size)
    if not info.get("paused",false): score_pulse = maxf(0,score_pulse-dt*4)
    score_label.scale = Vector2.ONE*(1.0+(0.0 if reduced else sin(score_pulse*PI)*0.055))
    if ready_notice_left>0 and not info.get("paused",false):
        ready_notice_left=maxf(0,ready_notice_left-dt)
        if ready_notice_left==0: _refresh_charge()
    if info.get("victory",false):
        banner.visible = false
        for label in floating: label.visible = false
        if not results_settled:
            results_elapsed += dt
            var factor := 1.0 if reduced else smoothstep(0,1,clampf(results_elapsed/1.4,0,1))
            for i in range(result_rows.size()): result_rows[i].text = "%s    %s" % [result_rows[i].get_meta("category"),Kit.number(roundi(result_values[i]*factor))]
            var finale: bool = info.get("journey_final",false)
            var total := float(info.get("adventure_total",target)) if finale else target
            result_total.text = ("ADVENTURE TOTAL  " if finale else "TOTAL  ")+Kit.number(roundi(total*factor))
            result_text_updates += 1
            results_settled = factor>=1.0
        return
    if info.get("paused",false):
        banner.visible = false
        for label in floating: label.visible = false
        return
    for i in range(floating.size()):
        if float_ages[i]>=0.9:
            if floating[i].visible: floating[i].hide()
            continue
        float_ages[i] += dt
        var age := float_ages[i]
        floating[i].visible = age<0.9 and not portrait
        floating[i].position = float_origins[i]+Vector2(0,0 if reduced else -age*35)
        floating[i].modulate.a = clampf((0.9-age)/0.3,0,1)
    if banner_age>=1.5:
        if banner.visible: banner.hide()
        return
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
    var radius := 58.0*factor
    touch_layer.draw_circle(center,radius,Color(.025,.12,.18,.92))
    touch_layer.draw_arc(center,radius,0,TAU,64,Color(.45,.80,.78,.85),2,true)
    for angle in [0,PI*.5,PI,PI*1.5]:
        var axis := Vector2.RIGHT.rotated(angle)
        touch_layer.draw_line(center+axis*radius*.76,center+axis*radius*.88,Color(.65,.9,.86,.65),2,true)
    var knob := center+direction*35.0*maxf(1,factor)
    if direction.length()>0.05: touch_layer.draw_line(center,knob,Color("#a5fff5"),3,true)
    touch_layer.draw_circle(knob,20*factor,Color("#75d3c6"))
    touch_layer.draw_arc(knob,20*factor,0,TAU,40,Color("#c1f4e6"),1.5,true)
    for action in ["jump","boost","bubble","pause"]:
        var rect := action_rect(action)
        var locked: bool = action == "bubble" and not info.get("bubble",false)
        var available: bool = action not in ["jump","boost"] or float(info.get("energy",1.0))>=0.4
        var pressed: bool = action in info.get("pressed",[])
        var style := touch_pressed if pressed else touch_normal
        touch_layer.draw_style_box(style,rect)
        var icon_size := minf(rect.size.x,rect.size.y)*0.64*minf(1,factor)
        var icon_at := rect.get_center()-Vector2.ONE*icon_size/2+Vector2(0,-5)
        Polish.glyph(touch_layer,"lock" if locked else action,icon_at+Vector2.ONE*icon_size*.5,icon_size*.78,Color("#789ba4") if locked or not available else Color("#c5f6e8"))
        var label: String = "LOCKED" if locked else ("RECHARGE" if not available else String(action).to_upper())
        if action=="bubble" and not locked:
            label=bubble_button_label()
        touch_layer.draw_string(Kit.BODY,rect.position+Vector2(0,rect.size.y-10),label,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,13,Color("#defdf5"))
        var cool := float(info.get("cooldowns",{}).get(action,0))
        if cool>0:
            var fraction := bubble_cooldown_fraction() if action=="bubble" else clampf(cool/(0.46 if action=="boost" and info.get("waterfall","")=="descent" else 0.55 if action=="boost" else 0.35),0,1)
            touch_layer.draw_arc(rect.get_center(),minf(rect.size.x,rect.size.y)*0.43,-PI/2,-PI/2+TAU*fraction,32,Color("#ffe2ad"),3)
        elif action=="bubble" and int(info.get("charge_tier",0))>0:
            var progress := clampf(float(info.get("charge_progress",0)),0,1)
            touch_layer.draw_arc(rect.get_center(),minf(rect.size.x,rect.size.y)*0.43,-PI/2,-PI/2+TAU*progress,48,Color("#a7fff0"),3)

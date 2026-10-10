extends CanvasLayer
## v0.5 optional real-time diagnostics; F6 toggles, never shown in screenshots.
## Numbers are measured in the running Godot window, not predicted benchmarks.
var panel: ColorRect
var label: Label
var level
var enabled := false
var refresh_clock := 0.0
var displayed_fps := 0
var refresh_count := 0

func _ready() -> void:
    layer = 12
    level = get_parent()
    panel = ColorRect.new()
    panel.name = "PerformanceBackdrop"
    panel.color = Color(0.006, 0.045, 0.075, 0.89)
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.size = Vector2(286, 144)
    add_child(panel)
    label = Label.new()
    label.name = "RealtimeFPSAndCulling"
    label.position = Vector2(13, 10)
    label.add_theme_font_size_override("font_size", 16)
    label.add_theme_color_override("font_color", Color("#d8fff2"))
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_child(label)
    get_viewport().size_changed.connect(_layout)
    _layout()
    visible = false
    set_process(false)

func _layout() -> void:
    panel.position = Vector2(maxf(6.0, get_viewport().get_visible_rect().size.x - 300.0), 188.0)

func set_monitor_visible(should_show: bool) -> void:
    enabled = should_show
    visible = enabled
    set_process(enabled)
    if enabled:
        refresh_clock = 1.0

func _process(delta: float) -> void:
    refresh_clock += delta
    if refresh_clock < 0.5:
        return
    refresh_clock = 0.0
    refresh_count += 1
    displayed_fps = Engine.get_frames_per_second()
    if not is_instance_valid(level):
        return
    var living := int(level.animated_enemies.active_count)
    var total := int(level.animated_enemies.sprites.size())
    var pool := int(level.native_fx.burst_pool.size())
    var settings := "High" if bool(level.high_depth_quality) else "Economy"
    label.text = "GODOT 4  /  LEVEL 1\nFPS   %d\nEnemy sprites  %d / %d\nParticle pool  %d\nDepth preset  %s\nF6: Hide monitor" % [
        displayed_fps, living, total, pool, settings]

extends Node2D
## Highland v0.4 native waterline detail: restrained three-line wave system.
## This replaces the previous flat line; no wallpaper-like repeating ripples.
const SEA_LEVEL := 280.0
var camera_x := 0.0
var clock := 0.0
var viewport_width := 1400.0
var enabled := true
var reduced_motion := false
var foam: Array[Dictionary] = []
var draw_accumulator := 0.0
var last_draw_camera := -100000.0
var draw_requests := 0

func _ready() -> void:
    z_index = -1
    get_viewport().size_changed.connect(_resize)
    _resize()
    for i in range(32):
        foam.append({"x": float((i * 197 + 41) % 1800),
            "phase": float(i) * 0.89, "radius": 1.4 + float(i % 4) * 0.62})

func _resize() -> void:
    viewport_width = get_viewport_rect().size.x
    queue_redraw()

func set_scene(camera_value: float, show_waterline: bool, motion_reduced: bool) -> void:
    camera_x = camera_value
    enabled = show_waterline
    reduced_motion = motion_reduced
    visible = enabled
    if enabled and (absf(camera_x - last_draw_camera) >= 9.0 or reduced_motion):
        last_draw_camera = camera_x
        draw_requests += 1
        queue_redraw()

func _process(delta: float) -> void:
    if not enabled or reduced_motion:
        return
    clock += minf(delta, 0.05)
    draw_accumulator += minf(delta, 0.05)
    if draw_accumulator < 1.0 / 30.0:
        return
    draw_accumulator = 0.0
    last_draw_camera = camera_x
    draw_requests += 1
    queue_redraw()

func _draw() -> void:
    if not enabled:
        return
    var width := viewport_width
    var t := 0.0 if reduced_motion else clock
    var segments := maxi(12, int(ceil(width / 23.0)))
    var rear := PackedVector2Array()
    var face := PackedVector2Array()
    var highlight := PackedVector2Array()
    for i in range(segments + 1):
        var x := width * float(i) / float(segments)
        var world := x + camera_x
        var low := sin(world * 0.021 + t * 1.17) * 2.5
        var fine := sin(world * 0.045 - t * 1.51) * 0.95
        rear.append(Vector2(x, SEA_LEVEL - 8.0 + low * 0.68))
        face.append(Vector2(x, SEA_LEVEL + low + fine))
        highlight.append(Vector2(x, SEA_LEVEL + 1.8 + low + fine))
    draw_polyline(rear, Color(0.72, 0.98, 1.0, 0.18), 6.0, true)
    draw_polyline(face, Color(0.78, 1.0, 0.95, 0.66), 2.3, true)
    draw_polyline(highlight, Color(0.14, 0.56, 0.68, 0.19), 3.6, true)
    for i in range(foam.size()):
        var particle := foam[i]
        var x := fposmod(float(particle["x"]) - camera_x * 0.38 + t * 8.0,
            maxf(1.0, width + 45.0)) - 25.0
        var u := x + camera_x
        var height := SEA_LEVEL - 8.0 + sin(u * 0.021 + t * 1.17) * 1.7
        var glow := 0.26 + 0.15 * sin(t * 0.83 + float(particle["phase"]))
        draw_circle(Vector2(x, height), float(particle["radius"]),
            Color(0.94, 1.0, 0.97, glow))


extends RefCounted
const FONT = preload("res://dist/fonts/treasure-display.ttf")
const BODY = preload("res://dist/fonts/story-serif.ttf")
const ICONS := {
 "shell":preload("res://godot/assets/ui-v014/shell.png"),"heart":preload("res://godot/assets/ui-v014/heart.png"),
 "crown":preload("res://godot/assets/ui-v014/crown.png"),"star":preload("res://godot/assets/ui-v014/star.png"),
 "chest":preload("res://godot/assets/ui-v014/chest.png"),"bubble":preload("res://godot/assets/ui-v014/bubble.png"),
 "jump":preload("res://godot/assets/ui-v014/jump.png"),"boost":preload("res://godot/assets/ui-v014/boost.png"),
 "pause":preload("res://godot/assets/ui-v014/pause.png"),"settings":preload("res://godot/assets/ui-v014/settings.png"),
 "home":preload("res://godot/assets/ui-v014/home.png"),"restart":preload("res://godot/assets/ui-v014/restart.png"),
 "joystick":preload("res://godot/assets/ui-v014/joystick.png"),"thumb":preload("res://godot/assets/ui-v014/thumb.png"),
 "ribbon":preload("res://godot/assets/ui-v014/ribbon.png"),"crest":preload("res://godot/assets/ui-v014/crest.png")}
static func panel(fill := Color("#082b40"), edge := Color("#60cfcf"), radius := 18) -> StyleBoxFlat:
    var p := StyleBoxFlat.new()
    p.bg_color = fill
    p.border_color = edge
    p.set_border_width_all(1)
    p.set_corner_radius_all(radius)
    p.shadow_color = Color(0.0,0.015,0.04,0.35)
    p.shadow_size = 5
    p.shadow_offset = Vector2(0,3)
    p.set_content_margin_all(10)
    return p
static func theme() -> Theme:
    var t := Theme.new()
    t.default_font = BODY
    t.default_font_size = 18
    t.set_color("font_color","Label",Color("#e7fff8"))
    for name in ["normal","hover","pressed","focus","disabled"]:
        t.set_stylebox(name,"Button",panel(Color("#164659") if name == "hover" else Color("#0b3049"),Color("#e9c880") if name == "focus" else Color("#55babb")))
    var track := panel(Color("#092234"),Color("#326a7b"),7)
    var fill := panel(Color("#67e9d8"),Color("#91ffff"),7)
    track.set_content_margin_all(0)
    fill.set_content_margin_all(0)
    t.set_stylebox("background","ProgressBar",track)
    t.set_stylebox("fill","ProgressBar",fill)
    return t
static func icon(name: String, size := Vector2(42,42)) -> TextureRect:
    var node := TextureRect.new()
    node.texture = ICONS[name]
    node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    node.custom_minimum_size = size
    node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return node
static func label(value: String, size := 18, tint := Color("#e7fff8")) -> Label:
    var node := Label.new()
    node.text = value
    node.add_theme_font_size_override("font_size",size)
    node.add_theme_color_override("font_color",tint)
    node.add_theme_color_override("font_shadow_color",Color(0.01,0.04,0.08,0.75))
    node.add_theme_constant_override("shadow_offset_y",1)
    node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return node
static func number(value: int) -> String:
    var source := str(value)
    var result := ""
    for i in range(source.length()):
        if i>0 and (source.length()-i)%3 == 0: result += ","
        result += source[i]
    return result


extends Node2D
## A presentation-only treasure actor. Rewards and saves remain owned by the level.
## All paintings use a shared transparent canvas and separate hinged lid/body layers.
const IDS := ["pearlkeeper", "coralheart", "moonshell", "kelpwood", "crystalwake", "sunken", "goldencrown"]
const NAMES := ["Pearlkeeper", "Coralheart", "Moon-Shell", "Kelpwood", "Crystalwake", "Sunken Relic", "Golden Crown"]
const HINGES := [125.34, 128.22, 133.44, 123.0, 126.0, 125.34, 126.48]
const TINTS := [Color("a7fff1"),Color("ffb8bd"),Color("eac2ff"),Color("b6f1a2"),Color("b4caff"),Color("b9e0df"),Color("ffe5a2")]
const INTERIOR: Texture2D = preload("res://godot/assets/treasure-v031/velvet_interior.png")
const REWARD_PEARL: Texture2D = preload("res://godot/assets/treasure-v031/reward_pearl.png")
const WIDTHS := [216.0, 209.0, 192.0, 197.0, 216.0, 216.0, 215.0]
const GLOW: Texture2D = preload("res://godot/assets/treasure-v031/pearl_glow.png")
const CLOSED: Array[Texture2D] = [
    preload("res://godot/assets/treasure-v031/pearlkeeper_closed.png"),
    preload("res://godot/assets/treasure-v031/coralheart_closed.png"),
    preload("res://godot/assets/treasure-v031/moonshell_closed.png"),
    preload("res://godot/assets/treasure-v031/kelpwood_closed.png"),
    preload("res://godot/assets/treasure-v031/crystalwake_closed.png"),
    preload("res://godot/assets/treasure-v031/sunken_closed.png"),
    preload("res://godot/assets/treasure-v031/goldencrown_closed.png")]
const LIDS: Array[Texture2D] = [
    preload("res://godot/assets/treasure-v031/pearlkeeper_lid.png"),
    preload("res://godot/assets/treasure-v031/coralheart_lid.png"),
    preload("res://godot/assets/treasure-v031/moonshell_lid.png"),
    preload("res://godot/assets/treasure-v031/kelpwood_lid.png"),
    preload("res://godot/assets/treasure-v031/crystalwake_lid.png"),
    preload("res://godot/assets/treasure-v031/sunken_lid.png"),
    preload("res://godot/assets/treasure-v031/goldencrown_lid.png")]
const BODIES: Array[Texture2D] = [
    preload("res://godot/assets/treasure-v031/pearlkeeper_body.png"),
    preload("res://godot/assets/treasure-v031/coralheart_body.png"),
    preload("res://godot/assets/treasure-v031/moonshell_body.png"),
    preload("res://godot/assets/treasure-v031/kelpwood_body.png"),
    preload("res://godot/assets/treasure-v031/crystalwake_body.png"),
    preload("res://godot/assets/treasure-v031/sunken_body.png"),
    preload("res://godot/assets/treasure-v031/goldencrown_body.png")]
const ART_RECT := Rect2(-128,-126,256,224)
const ART_SCALE := 0.68
const OPEN_SECONDS := 0.72
var variant := 0
var collected := false
var gentle := false
var economy := false
var nearby := false
var clock := 0.0
var open_progress := 0.0
var reveal_age := 20.0
var opening_events := 0

func configure(style: int, already_taken := false) -> void:
    variant=clampi(style,0,IDS.size()-1)
    collected=already_taken
    open_progress=1.0 if already_taken else 0.0
    reveal_age=20.0
    texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
    texture_repeat=CanvasItem.TEXTURE_REPEAT_DISABLED
    set_process(false)
    queue_redraw()

func set_collected(value: bool, animate := true) -> void:
    if not animate:
        collected=value
        open_progress=1.0 if value else 0.0
        reveal_age=20.0
    elif value != collected:
        collected=value
        open_progress=0.0
        reveal_age=0.0 if value else 20.0
        if value: opening_events+=1
    queue_redraw()

func advance(delta: float) -> void:
    var dt:=clampf(delta,0.0,0.1)
    if not gentle:clock+=dt
    if collected:
        open_progress=1.0 if gentle else minf(1.0,open_progress+dt/OPEN_SECONDS)
        reveal_age=minf(20.0,reveal_age+dt)
    queue_redraw()

func _oval(at: Vector2, radius: Vector2, tint: Color) -> void:
    var points:=PackedVector2Array()
    for i in range(32):points.append(at+Vector2(cos(i*TAU/32),sin(i*TAU/32))*radius)
    draw_colored_polygon(points,tint)

func _glint(at: Vector2, radius: float, tint: Color) -> void:
    draw_colored_polygon(PackedVector2Array([at+Vector2(0,-radius),at+Vector2(radius*.24,-radius*.24),at+Vector2(radius,0),at+Vector2(radius*.24,radius*.24),at+Vector2(0,radius),at+Vector2(-radius*.24,radius*.24),at+Vector2(-radius,0),at+Vector2(-radius*.24,-radius*.24)]),tint)

func _draw() -> void:
    var tint: Color=TINTS[variant]
    var active_burst:=collected and reveal_age<2.35 and not gentle
    var ledge: Texture2D=preload("res://godot/tutorial_atelier_art.gd").plinth([0,1,2,5,3,5,4][variant])
    var ledge_size:=Vector2(186,186.0*ledge.get_height()/ledge.get_width())
    draw_texture_rect(ledge,Rect2(Vector2(-93,54),ledge_size),false,Color(.84,.94,.93))
    # Grounding is visual only: no extra collider or change to the pickup centre.
    _oval(Vector2(0,60),Vector2(71,10),Color(.01,.035,.045,.22))
    _oval(Vector2(0,59),Vector2(55,5),Color(.01,.03,.04,.30))
    var pulse:=1.0 if gentle else .88+.12*sin(clock*1.35+variant)
    if not collected:
        draw_texture_rect(GLOW,Rect2(-98,-90,196,164),false,Color(tint,.18*pulse))
        if nearby:
            draw_arc(Vector2(0,11),92,-2.7,-.45,32,Color(tint,.36),1.2,true)
    var p:=1.0-pow(1.0-open_progress,3.0)
    if open_progress<.001:
        draw_set_transform(Vector2.ZERO,0,Vector2.ONE*ART_SCALE)
        draw_texture_rect(CLOSED[variant],ART_RECT,false)
    else:
        # Reveal a velvet-lined cavity, lifting a real separate painted lid.
        # The lower silhouette and pickup centre stay fixed during the opening.
        var hinge: float=(HINGES[variant]-126.0)*ART_SCALE
        draw_set_transform(Vector2(-1.0*p,hinge-23.0*p),-.035*p,Vector2(ART_SCALE,ART_SCALE*(1.0-.05*p)))
        draw_texture_rect(LIDS[variant],Rect2(-128,-float(HINGES[variant]),256,224),false)
        draw_set_transform(Vector2.ZERO)
        var tray_width: float=WIDTHS[variant]*ART_SCALE*.91
        var tray_height:=maxf(1.0,27.0*p)
        draw_texture_rect(INTERIOR,Rect2(-tray_width*.5,hinge-22.0*p,tray_width,tray_height+4),false)
        for side in [-1,1]:
            var bracket:=Vector2(side*tray_width*.40,hinge-20*p)
            draw_line(bracket,bracket+Vector2(-1,-5*p),Color("cfad6d"),1.7,true)
        if reveal_age<2.35:
            draw_texture_rect(GLOW,Rect2(-102,-98,204,174),false,Color(tint,.52*(1.0-reveal_age/2.35)))
            for i in range(5):
                var at:=Vector2(-37+i*18,hinge-5-float(i%2)*4)
                if i%2==0:
                    draw_texture_rect(REWARD_PEARL,Rect2(at-Vector2(5,5),Vector2(10,10)),false)
                else:
                    _oval(at,Vector2(6,2.6),Color("b67a36"))
                    draw_arc(at,5,PI,TAU,12,Color("ffdda1"),1.0,true)
        draw_set_transform(Vector2.ZERO,0,Vector2.ONE*ART_SCALE)
        draw_texture_rect(BODIES[variant],ART_RECT,false)
    draw_set_transform(Vector2.ZERO)
    # Quiet surface glints; no flashing full-screen lighting or camera shake.
    if not collected:
        for i in range(1 if economy else 3):
            var twinkle:=.40 if gentle else pow(maxf(0,sin(clock*1.1+i*2.1+variant)),4)
            var at: Vector2=[Vector2(17,-41),Vector2(-44,21),Vector2(59,42)][i]
            _glint(at,3.1+twinkle*2.1,Color(1,.96,.79,.18+twinkle*.65))
    if active_burst:
        var count:=6 if economy else 14
        var fade:=clampf(1.0-reveal_age/2.35,0,1)
        for i in range(count):
            var seed:=float(i)
            var at:=Vector2(sin(seed*2.4)*(13.0+reveal_age*24),-24.0-reveal_age*(32.0+fmod(seed*7,26)))
            var radius:=2.0+fmod(seed,3)
            if i%4==0:_glint(at,6.0,Color(tint,fade*.85))
            else:
                draw_texture_rect(REWARD_PEARL,Rect2(at-Vector2.ONE*radius,Vector2.ONE*radius*2),false,Color(tint,fade))

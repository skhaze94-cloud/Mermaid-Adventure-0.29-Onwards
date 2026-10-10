extends Node2D
## Decorative world-space schools and plankton. Never affects collision or score.
var clock := 0.0
var camera := 0.0
var waterline := 280.0
var player := Vector2.ZERO
var chapter := 0
var reduced := false
var economy := false
var active := true
var drift: Array[Dictionary] = []

func _ready() -> void:
    z_index = 1
    for i in range(24):
        drift.append({"seed":float(i)*137.9,"depth":float(i%5)})

func set_world(x: float, line: float, hero: Vector2, index: int, gentle: bool, low: bool, enabled: bool) -> void:
    camera = x
    waterline = line
    player = hero
    chapter = index
    reduced = gentle
    economy = low
    active = enabled
    visible = enabled
    queue_redraw()

func _process(dt: float) -> void:
    if active and not reduced:
        clock += dt
        queue_redraw()

func _draw() -> void:
    if not active: return
    var size := get_viewport_rect().size
    var motion := 0.0 if reduced else clock
    var first := int(floor(camera*.96/1100.0))-1
    var count := int(ceil(size.x/1100.0))+3
    for group in range(first,first+count):
        if group < 0: continue
        var direction := -1.0 if group%2 == 0 else 1.0
        var anchor := Vector2(group*1100+420+sin(motion*.12+group)*150,
            waterline+180+fposmod(group*137.0+chapter*31, maxf(80,size.y-waterline-290)))
        var tint := Color("85d9d2") if chapter in [1,3] else Color("f0d8a0")
        for fish in range(3 if economy else 6):
            var world := anchor+Vector2((fish%3)*38*direction,(fish/3)*29+sin(motion*1.5+fish)*5)
            var away := world+Vector2(camera*.04,0)-player
            if not reduced and away.length()<180:
                world += away.normalized()*(1.0-smoothstep(20.0,180.0,away.length()))*55
            var point := world-Vector2(camera*.96,0)
            if point.x < -70 or point.x > size.x+70: continue
            _fish(point, direction, 12+(fish%3)*3, tint, motion+fish)
    for i in range(8 if economy else drift.size()):
        var seed: float = drift[i]["seed"]
        var x := fposmod(seed-camera*.75+sin(motion*.3+i)*12,size.x)
        var y := waterline+45+fposmod(seed*.71-motion*(3+i%3),maxf(1,size.y-waterline-75))
        draw_circle(Vector2(x,y),1.3+(i%3)*.35,Color(.64,.96,.91,.16))

func _fish(point: Vector2, direction: float, length: float, tint: Color, motion: float) -> void:
    var tail := sin(motion*4.0)*2.0 if not reduced else 0.0
    var body := PackedVector2Array([Vector2(length,0),Vector2(length*.45,-length*.34),Vector2(-length*.55,-length*.15),Vector2(-length,tail-length*.34),Vector2(-length*.85,tail),Vector2(-length,tail+length*.34),Vector2(-length*.55,length*.15),Vector2(length*.45,length*.34)])
    for i in range(body.size()): body[i] = point+body[i]*Vector2(direction,1)
    draw_colored_polygon(body,Color(tint,.46))
    draw_line(point+Vector2(-length*.45*direction,0),point+Vector2(length*.6*direction,0),Color(1,1,.86,.25),1,true)
    draw_circle(point+Vector2(length*.58*direction,-1),1,Color(.025,.12,.2,.72))

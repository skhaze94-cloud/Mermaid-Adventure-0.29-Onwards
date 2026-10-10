extends Node2D
## Fixed ripple pool, following world-space events as the camera moves.
var pool: Array[Dictionary] = []
var camera := 0.0
var reduced := false
var active := true
var cursor := 0
func _ready() -> void:
    z_index = 4
    for i in range(20): pool.append({"age":2.0,"at":Vector2.ZERO,"kind":"pearl","direction":Vector2.RIGHT})
func burst(at: Vector2, kind: String, direction := Vector2.RIGHT) -> void:
    pool[cursor]["age"] = 0.0
    pool[cursor]["at"] = at
    pool[cursor]["kind"] = kind
    pool[cursor]["direction"] = direction.normalized()
    cursor = (cursor+1)%pool.size()
    queue_redraw()
func clear() -> void:
    for item in pool: item["age"] = 2.0
    queue_redraw()
func _process(dt: float) -> void:
    for item in pool: item["age"] = minf(2,float(item["age"])+dt)
    queue_redraw()
func _draw() -> void:
    if not active: return
    for item in pool:
        var age: float = item["age"]
        var duration := 0.24 if reduced else 0.65
        if age >= duration: continue
        var t := age/duration
        var at: Vector2 = item["at"]-Vector2(camera,0)
        var major: bool = item["kind"] in ["boss_hit","boss_defeat","treasure","checkpoint"]
        var tint := Color("f6dfa0") if major else Color("b5f9f2")
        tint.a = (1-t)*0.65
        var radius := (35.0 if major else 16.0)+(0.0 if reduced else t*(50 if major else 25))
        if item["kind"] == "boost" and not reduced:
            var heading: Vector2 = item["direction"]
            var cross := heading.orthogonal()
            for lane in [-1,0,1]:
                var start: Vector2 = at-heading*(35+t*65)+cross*lane*14
                draw_line(start,start-heading*(35*(1-t)),tint,2,true)
        else:
            for petal in range(3):
                draw_arc(at,radius,petal*TAU/3+.12,petal*TAU/3+1.5,14,tint,1.5,true)
            if not reduced:
                for dot in range(5):
                    var angle := dot*TAU/5+t*.4
                    draw_circle(at+Vector2(cos(angle),sin(angle))*radius,2*(1-t),tint)

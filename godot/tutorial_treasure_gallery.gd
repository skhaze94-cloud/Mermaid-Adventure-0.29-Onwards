extends Node2D
## Tutorial-only presentation layer. It reads existing treasure state; never awards
## points, mutates saves, adds pickups, or changes the 59px collection distance.
const Actor=preload("res://godot/tutorial_treasure_chest.gd")
var host: Node2D
var actors: Dictionary={}
var last_retry:=-1
var last_time:=0.0

func bind(level: Node2D) -> void:
    host=level
    z_index=2
    process_mode=Node.PROCESS_MODE_PAUSABLE
    last_retry=host.retry_serial
    last_time=host.time
    sync(false)

func key_for(item: Dictionary) -> String:
    return String(item.get("deep_id","surface:%.3f:%.3f" % [float(item["x"]),float(item["y"])]))

func style_for(item: Dictionary, surface_index: int) -> int:
    var key:=String(item.get("deep_id",""))
    if key.contains("nursery"):return 4
    if key.contains("bellflower"):return 6
    return posmod(surface_index,3)

func _process(delta: float) -> void:
    if not is_instance_valid(host):return
    sync(true,delta)

func sync(animate := true, delta := 0.0) -> void:
    if not is_instance_valid(host):return
    var reset: bool=host.retry_serial!=last_retry or host.time+0.001<last_time
    last_retry=host.retry_serial;last_time=host.time
    var camera_y:=0.0
    if is_instance_valid(host.deep_routes):camera_y=host.deep_routes.camera_y
    var viewport:=Rect2(Vector2(host.camera,camera_y)-Vector2(220,240),host.get_viewport_rect().size+Vector2(440,480))
    var present: Dictionary={}
    var surface_index:=0
    for item in host.treasures:
        if item.get("kind","")!="chest":continue
        var key:=key_for(item)
        present[key]=true
        var style:=style_for(item,surface_index)
        if not item.has("deep_id"):surface_index+=1
        if not actors.has(key):
            var actor:=Actor.new()
            actor.name="Treasure_"+str(actors.size())
            add_child(actor)
            actor.configure(style,bool(item.get("taken",false)))
            actors[key]=actor
        var chest=actors[key]
        chest.gentle=host.reduced_fx
        chest.economy=not host.high_depth_quality
        chest.set_collected(bool(item.get("taken",false)),animate and not reset)
        var at:=Vector2(float(item["x"]),float(item["y"]))
        chest.position=at-Vector2(host.camera,0)
        chest.nearby=not chest.collected and host.player.distance_to(at)<200.0
        chest.visible=viewport.has_point(at) and host.waterfall_phase==""
        if animate and host.state=="playing" and not get_tree().paused:chest.advance(delta)
    for key in actors.keys():
        if not present.has(key):actors[key].queue_free();actors.erase(key)

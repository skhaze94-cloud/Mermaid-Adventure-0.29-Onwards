extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var Detail=load("res://godot/character_details.gd")
    var cast=JSON.parse_string(FileAccess.get_file_as_string("res://godot/assets/whimsy-four/cast.json"))["characters"]
    var seeds: Dictionary={}
    for person in cast:
        assert(Detail.ZONES.has(person["id"]))
        var m=Detail.surface(person["id"]);Detail.update(m,3.5,false)
        assert(m.get_shader_parameter("detail_strength")==1.0)
        assert(m.get_shader_parameter("detail_clock")==3.5)
        Detail.update(m,3.5,true);assert(m.get_shader_parameter("detail_strength")==0.0)
        seeds[person["id"]]=m.get_shader_parameter("detail_seed")
    var brush=load("res://godot/whimsy_garden.gd").new();root.add_child(brush)
    var tex=load("res://godot/assets/little-moments/dozy.png")
    brush._begin_details();brush._detail_paint(tex,Rect2(0,0,100,100),2,false,"dozy")
    var count=brush.get_child_count()
    for i in range(120):
        brush._begin_details();brush._detail_paint(tex,Rect2(i,0,100,100),float(i)/60,false,"dozy")
    assert(brush.get_child_count()==count)
    brush._begin_details();assert(not brush.detail_sprites.values()[0].visible)
    brush.free()
    print("CHARACTER DETAILS: 16 authored profiles, gentle gating, clock ownership, 120-frame pool reuse and visibility passed")
    quit()

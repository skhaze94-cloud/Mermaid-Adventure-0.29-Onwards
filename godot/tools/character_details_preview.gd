extends SceneTree
var actors: Array=[]
var labels: Array=[]
var performances: Array=[]
var homes: Array=[]
func _initialize() -> void:call_deferred("run")
func frame() -> void:await process_frame;await RenderingServer.frame_post_draw
func run() -> void:
    Engine.time_scale=0;root.size=Vector2i(1280,960)
    var back:=ColorRect.new();back.color=Color("173947");back.size=Vector2(4096,4096);root.add_child(back)
    var Detail=load("res://godot/character_details.gd")
    var cast: Array=JSON.parse_string(FileAccess.get_file_as_string("res://godot/assets/whimsy-four/cast.json"))["characters"]
    for i in range(cast.size()):
        var person: Dictionary=cast[i];var tex=load("res://godot/assets/whimsy-four/"+person["file"])
        var sprite:=Sprite2D.new();sprite.texture=tex;sprite.scale=Vector2.ONE*178/tex.get_height();sprite.position=Vector2(160+(i%4)*320,140+(i/4)*230);sprite.material=Detail.surface(person["id"]);root.add_child(sprite);actors.append(sprite);homes.append(sprite.position);performances.append(load("res://godot/character_performance.gd").new(person["id"]))
        var label:=Label.new();label.text=person["name"];label.position=sprite.position+Vector2(-60,86);label.add_theme_font_size_override("font_size",20);root.add_child(label)
    await frame();await frame()
    for i in range(288):
        for k in range(actors.size()):
            var t:=float(i)/24
            var actor: Sprite2D=actors[k];var performance=performances[k]
            performance.advance(t,1.0 if t>.8+k*.08 else 0.0,t>8,false,1.0 if k%2==0 else -1.0)
            actor.position=homes[k]+performance.offset;actor.rotation=performance.tilt
            Detail.update(actor.material,t,false)
            actor.material.set_shader_parameter("expression_joy",performance.joy)
            actor.material.set_shader_parameter("expression_look",performance.look)
            actor.material.set_shader_parameter("expression_greet",performance.greeting)
        await frame();print("FRAME "+Marshalls.raw_to_base64(root.get_texture().get_image().save_jpg_to_buffer(.9)))
        if i==72:root.get_texture().get_image().save_png(OS.get_environment("CAST_PREVIEW")+"/Whimsy_Reactions_v0_24.png")
    for actor in actors:Detail.update(actor.material,0,true)
    await frame();root.get_texture().get_image().save_png(OS.get_environment("CAST_PREVIEW")+"/Whimsy_Reactions_v0_24_Gentle.png")
    print("CHARACTER REACTIONS PREVIEW COMPLETE");quit()

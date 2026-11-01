extends Node2D
## The ocean has a second storey: a vertical camera, optional room loops and
## painted underground passages sharing the actual collision source of truth.
const Data=preload("res://godot/deep_routes_data.gd")
const Ground=preload("res://godot/terrain_painter.gd")
const STONE=preload("res://godot/assets/cavern-v034/limestone.png")
var host: Node2D
var camera_node: Camera2D
var camera_y:=0.0
var clock:=0.0
var profiles: Array[Dictionary]=[]
var water_shapes: Array[PackedVector2Array]=[]
var water_meshes: Array[ArrayMesh]=[]
var water_uvs: Array[PackedVector2Array]=[]
var bounds: Array[Rect2]=[]
var last_retry:=-1
var rendered_rooms:=0
var authored_opening:=false
var tutorial_uvs: Array[PackedVector2Array]=[]

func _ready() -> void:
    z_index=1;texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
    set_process(false)
    camera_node=Camera2D.new();camera_node.anchor_mode=Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
    camera_node.position_smoothing_enabled=false;camera_node.process_callback=Camera2D.CAMERA2D_PROCESS_PHYSICS
    camera_node.name="VerticalOceanCamera";add_child(camera_node)

func bind(level: Node2D) -> void:
    host=level;profiles=Data.rooms(host._stage_index());last_retry=host.retry_serial
    for room in profiles:
        var polygon:=PackedVector2Array()
        for space in room["free"]:
            var rect: Rect2=space
            var piece:=PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
            if polygon.is_empty():polygon=piece
            else:
                var merged:=Geometry2D.merge_polygons(polygon,piece)
                if merged.size()==1:polygon=merged[0]
        var rounded:=_soft_outline(polygon,85.0)
        polygon=_natural_tutorial_outline(rounded)
        if Geometry2D.triangulate_polygon(polygon).is_empty():polygon=rounded
        water_shapes.append(polygon)
        var uv:=PackedVector2Array()
        for point in polygon:
            uv.append(Vector2((point.x-float(room["x"]))/float(room["w"]),.35+(point.y-780)/(float(room["y"])+float(room["h"])+230-780)*.61))
        water_uvs.append(uv)
        var art_uv:=PackedVector2Array()
        for point in polygon:art_uv.append(Vector2((point.x-float(room["x"]))/float(room["w"]),(point.y-float(room["y"]))/float(room["h"])))
        tutorial_uvs.append(art_uv)
        var vertices:=PackedVector3Array();var colors:=PackedColorArray()
        var tint:=Color(.1234+(water_shapes.size()-1)*.1,.4567,.7891,1)
        for point in polygon:vertices.append(Vector3(point.x,point.y,0));colors.append(tint)
        var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
        arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=art_uv;arrays[Mesh.ARRAY_COLOR]=colors
        arrays[Mesh.ARRAY_INDEX]=Geometry2D.triangulate_polygon(polygon)
        var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);water_meshes.append(mesh)
        bounds.append(Rect2(float(room["x"])-80,660,float(room["w"])+160,float(room["y"])+float(room["h"])+300-660))
    var paint:=ShaderMaterial.new();paint.shader=preload("res://godot/shaders/friends_cavern.gdshader")
    paint.set_shader_parameter("cave_wall",STONE)
    for i in range(3):
        var room: Dictionary=profiles[mini(i,profiles.size()-1)]
        var art: Texture2D=preload("res://godot/cavern_art.gd").painting(room["id"])
        paint.set_shader_parameter("room_art%s" % i,art)
        paint.set_shader_parameter("room%s" % i,Vector4(room["x"],room["y"],room["w"],room["h"]))
        paint.set_shader_parameter("openings%s" % i,Vector4(room["a"],room["b"],160.0 if host._stage_index()==7 else 130.0,0))
        paint.set_shader_parameter("tint%s" % i,preload("res://godot/cavern_art.gd").tint(room["id"]))
    material=paint
    sync(true)

static func _soft_outline(polygon: PackedVector2Array,radius: float) -> PackedVector2Array:
    var out:=PackedVector2Array()
    for i in range(polygon.size()):
        var before: Vector2=polygon[posmod(i-1,polygon.size())]
        var at: Vector2=polygon[i];var after: Vector2=polygon[(i+1)%polygon.size()]
        var d:=minf(radius,minf(at.distance_to(before),at.distance_to(after))*.3)
        var a:=at.move_toward(before,d);var b:=at.move_toward(after,d)
        for j in range(5):
            var t:=float(j)/4.0
            out.append((1-t)*(1-t)*a+2*(1-t)*t*at+t*t*b)
    return out

func desired_camera_y() -> float:
    if not is_instance_valid(host) or host.waterfall_phase!="":return 0.0
    var view:=get_viewport_rect().size
    var amount:=smoothstep(795,1090,host.player.y)
    return clampf((host.player.y-view.y*.59)*amount,0,maxf(0,Data.BOTTOM-view.y+85))

func room_camera_x(desired: float) -> float:
    if host._stage_index() not in [0,7] or host.player.y<1030:return desired
    var width:=get_viewport_rect().size.x
    for room in profiles:
        if host._stage_index()==0 and room["id"]!="roots":continue
        if not Rect2(room["body"]).grow(130).has_point(host.player):continue
        var x: float=room["x"];var w: float=room["w"]
        var framed:=clampf(desired,x-24,x+w-width+24) if w+48>width else x+(w-width)*.5
        return lerpf(desired,maxf(0,framed),smoothstep(float(room["y"])-90,float(room["y"])+40,host.player.y))
    return desired

func advance(dt: float) -> void:
    if not is_instance_valid(host) or host.state!="playing" or get_tree().paused:return
    if host.retry_serial!=last_retry:last_retry=host.retry_serial;camera_y=desired_camera_y()
    camera_y=lerpf(camera_y,desired_camera_y(),1-exp(-minf(dt,.1)*(4.6 if host.reduced_fx else 5.6)))
    if not host.reduced_fx:clock+=minf(dt,.1)
    sync()

func sync(snap:=false) -> void:
    if not is_instance_valid(host):return
    if snap:camera_y=desired_camera_y()
    camera_node.position=Vector2(0,camera_y)
    camera_node.force_update_scroll()
    # Native water sheets stay screen-aligned while particles/characters retain
    # world coordinates and are naturally carried by the real Camera2D.
    var fx=host.native_fx
    if is_instance_valid(fx):
        for key in ["water_overlay","refract_overlay","mist_overlay","cinematic_overlay","impact_overlay"]:
            var sheet: Control=fx.get(key)
            if is_instance_valid(sheet):sheet.position.y=camera_y
        var line: float=(host._water_line()-camera_y)/maxf(1,get_viewport_rect().size.y)
        for key in ["refract_material","mist_material","cinematic_material"]:
            var mat: ShaderMaterial=fx.get(key)
            if is_instance_valid(mat):mat.set_shader_parameter("surface_y",line)
        fx.caustics_material.set_shader_parameter("water_surface",line)
    visible=host.waterfall_phase=="" and host.state in ["playing","paused"]
    queue_redraw()

func area_name() -> String:
    return "Friends Cavern" if not room_name().is_empty() else ""

func room_name() -> String:
    if not is_instance_valid(host) or host.player.y<960:return ""
    for room in profiles:
        if host.player.x>=float(room["x"])-150 and host.player.x<=float(room["x"])+float(room["w"])+150:return room["name"]
    return ""

func _draw() -> void:
    if not is_instance_valid(host) or not visible:return
    var view:=get_viewport_rect().size;var camera: float=host.camera
    draw_set_transform(Vector2(-camera,0))
    var wall:=Rect2(camera,836,view.x,Data.BOTTOM+240-836)
    var wall_uv:=PackedVector2Array([wall.position/540.0,Vector2(wall.end.x,wall.position.y)/540.0,wall.end/540.0,Vector2(wall.position.x,wall.end.y)/540.0])
    draw_polygon(PackedVector2Array([wall.position,Vector2(wall.end.x,wall.position.y),wall.end,Vector2(wall.position.x,wall.end.y)]),PackedColorArray([Color(.3234,.1234,.4321,1)]),wall_uv,STONE)
    var visible_world:=Rect2(camera-180,camera_y-100,view.x+360,view.y+240)
    rendered_rooms=0
    for i in range(profiles.size()):
        if not visible_world.intersects(bounds[i]):continue
        rendered_rooms+=1
        var room: Dictionary=profiles[i];var tint: Color=room["color"]
        authored_opening=true
        var polygon: PackedVector2Array=water_shapes[i]
        draw_mesh(water_meshes[i],null)
        var rim:=polygon.duplicate();rim.append(polygon[0])
        if host._stage_index()==7:
            draw_polyline(rim,Color(.025,.09,.105,.10),22,true)
            host._dress_tutorial_grotto(self,room,i,clock)
        if host._stage_index()!=7:_reef(room["reef"],tint,i)
        for j in range(room["perches"].size()):
            _reef(room["perches"][j],tint,i+j+1 if host._stage_index()==7 else i+1)
        _room_lights(room,tint,i)
        for key in ["a","b"]:
            var x: float=room[key]
            _entrance(Vector2(x,810),tint)
            _return_marker(Vector2(x,float(room["y"])+240),tint)
    for item in host.treasures:
        if item.get("taken",false) or not item.has("deep_id"):continue
        # A chapter may supply its own persistent, animated treasure renderer.
        # All other chapters retain the original rendering path unchanged.
        if host.has_method("_owns_treasure_visual") and host._owns_treasure_visual(item):continue
        var at:=Vector2(item["x"],item["y"])
        if not visible_world.grow(70).has_point(at):continue
        var kind: String=item["kind"]
        var tex: Texture2D=preload("res://godot/assets/treasure-v031/reward_pearl.png") if kind=="pearl" else host.collectible_art[kind]
        var width:=128.0 if kind=="chest" else 21.0
        var size:=tex.get_size()*(width/tex.get_width())
        if kind=="chest":
            var pedestal:=Rect2(at+Vector2(-45,size.y*.5-2),Vector2(90,62))
            draw_texture_rect(Ground.formation(2),pedestal,false,Color(.79,.9,.94))
            draw_line(pedestal.position+Vector2(13,9),Vector2(pedestal.end.x-13,pedestal.position.y+9),Color(.76,.91,.87,.30),2,true)
            Ground.contact(self,at+Vector2(0,size.y*.5-2),width,.38)
        draw_texture_rect(tex,Rect2(at-size*.5,size),false)
    draw_set_transform(Vector2.ZERO)

func _reef(rect: Rect2,tint: Color,id: int) -> void:
    if host._stage_index()==7:
        host._paint_tutorial_perch(self,rect,id)
        return
    var support:=rect.size.y<90
    var index: int=[9,0,3][posmod(id,3)] if support else [9,0,3,6,8,10][posmod(id,6)]
    var tex: Texture2D=preload("res://godot/tutorial_atelier_art.gd").rock(index)
    var size:=Vector2(rect.size.x+8,(rect.size.x+8)*tex.get_height()/tex.get_width())
    var pivot: float={9:.088,0:.193,3:.235}.get(index,0.0) if support else 0.0
    draw_texture_rect(tex,Rect2(rect.position-Vector2(4,5+size.y*pivot),size),false,Color(.82,.93,.94))
    if support:Ground.contact(self,Vector2(rect.get_center().x,rect.position.y),rect.size.x*.4,.28)

func _room_lights(room: Dictionary,tint: Color,id: int) -> void:
    var x: float=room["x"];var y: float=room["y"];var w: float=room["w"];var h: float=room["h"]
    for i in range(4 if host.high_depth_quality else 2):
        var point:=Vector2(x+110+fposmod(i*247.7,w-220),y+100+fposmod(i*139.1-clock*2,h-180))
        draw_circle(point,1.3,Color(tint,.22))

func _entrance(at: Vector2,tint: Color) -> void:
    if host._stage_index()==7:
        host._paint_tutorial_entrance(self,at,tint,clock)
        return
    for i in range(2):
        var p:=at+Vector2(sin(clock*.3+i*2)*10,100+i*42+fposmod(clock*4,42))
        draw_circle(p,1.5,Color(tint,.3))

func _return_marker(at: Vector2,tint: Color) -> void:
    # Two restrained current marks sit inside the real return channels.
    for i in range(2):draw_arc(at-Vector2(0,45+i*42),6,PI*1.18,PI*1.82,10,Color(tint,.22),1.0,true)

static func _natural_tutorial_outline(source: PackedVector2Array) -> PackedVector2Array:
    var result:=PackedVector2Array()
    for i in range(source.size()):
        var a: Vector2=source[i];var b: Vector2=source[(i+1)%source.size()]
        var count:=maxi(1,int(ceil(a.distance_to(b)/28.0)))
        var normal: Vector2=(b-a).normalized().orthogonal()
        for j in range(count):
            var point: Vector2=a.lerp(b,float(j)/count)
            var original_x:=point.x
            point+=normal*(sin(point.x*.043+point.y*.023)*4.0+sin(point.y*.071-point.x*.019)*2.8)
            if point.y<910:
                point.x=original_x
                point.y=Ground.ground_y(point.x)+2.0
            if result.is_empty() or point.distance_to(result[-1])>1:result.append(point)
    return result

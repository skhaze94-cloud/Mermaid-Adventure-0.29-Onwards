extends Node2D
## Tiny decorative tableaux, anchored in the painted reef. No collision, rewards
## or timers: the level advances this layer only while its world is playing.
const Art = preload("res://godot/environment_art.gd")
const Terrain = preload("res://godot/terrain_painter.gd")
const SHELL: Texture2D = preload("res://godot/assets/ui-v014/shell.png")
const STAR: Texture2D = preload("res://godot/assets/ui-v014/star.png")
const MAX_STATIONS := 4
const SPACING := 780.0
const BATCH_VERTEX_CAP := 12288
const BATCH_TRIANGLE_CAP := BATCH_VERTEX_CAP / 3
const THEMES := ["pearl_clams","lantern_pods","orchid_wings","glow_corals","pearl_mobiles","rainbow_tadpoles","crown_stars","baby_shells"]
const PALETTES := [
    [Color("edc4df"),Color("a5e8e4"),Color("f8e2aa")],
    [Color("b9a4e9"),Color("91e5d9"),Color("f6cf94")],
    [Color("f1aad6"),Color("a6e7d1"),Color("dad0f7")],
    [Color("89cddd"),Color("b6eee5"),Color("baadf0")],
    [Color("f0c9ea"),Color("b5e9ee"),Color("f7e4b2")],
    [Color("aee6bc"),Color("d5c5f1"),Color("f6dba5")],
    [Color("97dfe0"),Color("c5d2f4"),Color("f5dcac")],
    [Color("edbddc"),Color("b9e9d8"),Color("f6e3ac")]]
var clock := 0.0
var camera := 0.0
var waterline := 280.0
var player := Vector2.ZERO
var chapter := 0
var reduced := false
var economy := false
var active := false
var combat := false
var station_count := 0
var station_positions: Array[Vector2] = []
var station_ids: Array[int] = []
var circle := PackedVector2Array()
var sparkle := PackedVector2Array()
var glow_vertices:=PackedVector2Array()
var glow_colours:=PackedColorArray()
var glow_triangles:=PackedInt32Array()
var circle_triangles:=PackedInt32Array()
var wing_triangles:=PackedInt32Array()
var spark_triangles:=PackedInt32Array()
var batch_mesh: ArrayMesh
var batch_vertices:=PackedVector2Array()
var batch_colours:=PackedByteArray()
var batch_used:=0
var batch_previous_used:=0
var batch_peak_used:=0
var batch_overflows:=0
var batch_updates:=0
var last_build_us:=0
var batch_bounds:=Vector2.ZERO
var pen:=Transform2D.IDENTITY
var line_points:=PackedVector2Array()
var arc_points:=PackedVector2Array()
var inner_left:=PackedVector2Array()
var inner_right:=PackedVector2Array()
var outer_left:=PackedVector2Array()
var outer_right:=PackedVector2Array()
var wing := PackedVector2Array()
var stem := PackedVector2Array()
var tail := PackedVector2Array()
var garden_frames: Array[Texture2D] = []
var prepared := false

func _ready() -> void:
    z_index = 0
    set_process(false)
    _prepare()

func _prepare() -> void:
    if prepared: return
    prepared = true
    for i in range(MAX_STATIONS):
        station_positions.append(Vector2.ZERO);station_ids.append(0)
    for i in range(24):circle.append(Vector2(cos(i*TAU/24),sin(i*TAU/24)))
    sparkle=PackedVector2Array([Vector2(0,-1.5),Vector2(.14,-.14),Vector2(1,0),Vector2(.14,.14),Vector2(0,1.5),Vector2(-.14,.14),Vector2(-1,0),Vector2(-.14,-.14)])
    _prepare_glow()
    wing=PackedVector2Array([Vector2(0,0),Vector2(4,-8),Vector2(12,-13),Vector2(19,-10),Vector2(20,-3),Vector2(15,4),Vector2(9,5),Vector2(13,11),Vector2(9,15),Vector2(4,13),Vector2(1,5)])
    for i in range(12):
        var t:=float(i)/11.0
        stem.append(Vector2(sin(t*PI)*6,-t*60))
        tail.append(Vector2(-t*30,sin(t*PI*1.7)*5*t))
    for i in [4,5,6,7]:garden_frames.append(Art.crop(Art.GARDENS,Art.GARDEN_REGIONS[i]))
    circle_triangles=Geometry2D.triangulate_polygon(circle)
    wing_triangles=Geometry2D.triangulate_polygon(wing)
    spark_triangles=Geometry2D.triangulate_polygon(sparkle)
    _prepare_batch()

func set_world(camera_x: float, line: float, hero: Vector2, chapter_index: int, gentle: bool, low: bool, enabled: bool, in_combat: bool) -> void:
    _prepare()
    camera=camera_x;waterline=line;player=hero;chapter=clampi(chapter_index,0,7)
    reduced=gentle;economy=low;active=enabled;combat=in_combat;visible=enabled
    station_count=0
    if enabled:
        var view:=get_viewport_rect().size
        var first:=maxi(0,int(floor((camera-360)/SPACING)))
        var cap:=2 if economy else MAX_STATIONS
        # Fixed four-slot cache: no nodes or textures are created when travelling.
        for id in range(first,first+MAX_STATIONS+2):
            var world_x:=float(id)*SPACING+410+sin(float(id)*2.17+chapter)*72
            var screen_x:=world_x-camera
            if screen_x < -110 or screen_x > view.x+110:continue
            if station_count>=cap:break
            station_positions[station_count]=Vector2(world_x,Terrain.ground_y(world_x)-20)
            station_ids[station_count]=id
            station_count+=1
    queue_redraw()

func advance(dt: float) -> void:
    if active and not reduced:
        clock+=maxf(0,dt)
        if station_count>0:queue_redraw()

func reset() -> void:
    clock=0;station_count=0;active=false;visible=false
    queue_redraw()

func _draw() -> void:
    if not active or not prepared:return
    var started:=Time.get_ticks_usec()
    batch_used=0;pen=Transform2D.IDENTITY
    var colour: Array=PALETTES[chapter]
    for slot in range(station_count):
        var world: Vector2=station_positions[slot]
        var at:=world-Vector2(camera,0)
        if at.y > get_viewport_rect().size.y+100:continue
        var phase:=float(station_ids[slot])*1.47+chapter*.71
        var t:=0.0 if reduced else clock
        var nearby:=0.0 if reduced else 1.0-smoothstep(70,270,player.distance_to(world-Vector2(0,60)))
        # Painted bases stay planted and unchanged as combat begins. Only the
        # small additional wisps/critters settle while attack cues matter.
        _base(at)
        if combat:continue
        match chapter:
            0:_clam(at,colour,t,phase,nearby)
            1:_lanterns(at,colour,t,phase,nearby)
            2:_orchids(at,colour,t,phase,nearby)
            3:_corals(at,colour,t,phase,nearby)
            4:_mobile(at,colour,t,phase,nearby)
            5:_tadpoles(at,colour,t,phase,nearby)
            6:_stars(at,colour,t,phase,nearby)
            7:_family(at,colour,t,phase,nearby)
    pen=Transform2D.IDENTITY
    _flush_batch()
    last_build_us=Time.get_ticks_usec()-started

func _base(at: Vector2) -> void:
    match chapter:
        0:_painting(garden_frames[0],at+Vector2(0,23),91,Color(.94,.98,1,.9))
        1:_painting(garden_frames[2],at+Vector2(0,24),73,Color(.76,.78,.92,.65))
        2:_painting(garden_frames[1],at+Vector2(0,23),70,Color(.88,.96,.94,.74))
        3:_painting(garden_frames[2],at+Vector2(0,20),83,Color(.55,.84,.88,.6))
        4:_painting(SHELL,at+Vector2(0,15),44,Color(.95,.89,1,.8))
        5:_painting(garden_frames[1],at+Vector2(0,24),61,Color(.75,1,.82,.62))
        6:_painting(STAR,at+Vector2(0,15),40,Color(.87,.94,1,.7))
        7:_painting(garden_frames[0],at+Vector2(-12,21),82,Color(.98,.95,1,.82))

func _painting(texture: Texture2D, foot: Vector2, height: float, tint:=Color.WHITE) -> void:
    var size:=texture.get_size()*(height/texture.get_height())
    draw_texture_rect(texture,Rect2(foot-Vector2(size.x*.5,size.y),size),false,tint)

func _oval(at: Vector2, size: Vector2, tint: Color, angle:=0.0) -> void:
    _set_pen(at,angle,size)
    _polygon(circle,tint)
    _set_pen(Vector2.ZERO)

func _prepare_glow() -> void:
    # One gradient mesh per layer replaces concentric per-frame glow polygons.
    var vertices:=PackedVector2Array([Vector2.ZERO])
    var colours:=PackedColorArray([Color(1,1,1,.72)])
    var indices:=PackedInt32Array()
    for ring in range(3):
        var radius: float=[.6,1.05,2.3][ring]
        var alpha: float=[.46,.16,0.0][ring]
        for i in range(20):
            vertices.append(Vector2(cos(i*TAU/20),sin(i*TAU/20))*radius)
            colours.append(Color(1,1,1,alpha))
    for i in range(20):
        indices.append_array(PackedInt32Array([0,1+i,1+(i+1)%20]))
    for ring in range(2):
        for i in range(20):
            var a:=1+ring*20+i
            var b:=1+ring*20+(i+1)%20
            indices.append_array(PackedInt32Array([a,a+20,b,b,a+20,b+20]))
    glow_vertices=vertices;glow_colours=colours;glow_triangles=indices

func _glow(at: Vector2, tint: Color, radius: float, strength:=1.0) -> void:
    var transform:=Transform2D(0,Vector2.ONE*radius,0,at)
    var colour:=Color(tint,strength)
    for i in range(0,glow_triangles.size(),3):
        var a:=glow_triangles[i];var b:=glow_triangles[i+1];var c:=glow_triangles[i+2]
        _triangle(transform*glow_vertices[a],transform*glow_vertices[b],transform*glow_vertices[c],colour*glow_colours[a],colour*glow_colours[b],colour*glow_colours[c])
    _circle(at-Vector2(radius*.18,radius*.25),radius*.38,Color(.97,1,1,.54*strength))

func _spark(at: Vector2, tint: Color, size: float, strength: float) -> void:
    _set_pen(at,0,Vector2.ONE*size)
    _polygon(sparkle,Color(tint,strength))
    _set_pen(Vector2.ZERO)

func _prepare_batch() -> void:
    # Allocate one dynamic surface once. Frame updates replace bytes in its
    # existing vertex/attribute buffers instead of issuing dozens of draw calls.
    batch_vertices.resize(BATCH_VERTEX_CAP);batch_vertices.fill(Vector2.ZERO)
    batch_colours.resize(BATCH_VERTEX_CAP*4);batch_colours.fill(0)
    var colours:=PackedColorArray();colours.resize(BATCH_VERTEX_CAP);colours.fill(Color(1,1,1,0))
    var arrays: Array=[];arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX]=batch_vertices;arrays[Mesh.ARRAY_COLOR]=colours
    batch_mesh=ArrayMesh.new()
    batch_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},Mesh.ARRAY_FLAG_USE_DYNAMIC_UPDATE)
    # Godot4.4 uses float32 XY and packed RGBA8 for this exact surface format.
    assert(RenderingServer.mesh_surface_get_format_vertex_stride(batch_mesh.surface_get_format(0),BATCH_VERTEX_CAP)==8)
    assert(RenderingServer.mesh_surface_get_format_attribute_stride(batch_mesh.surface_get_format(0),BATCH_VERTEX_CAP)==4)
    line_points.resize(2);arc_points.resize(32)
    inner_left.resize(32);inner_right.resize(32);outer_left.resize(32);outer_right.resize(32)

func _set_pen(at: Vector2, angle:=0.0, size:=Vector2.ONE) -> void:
    pen=Transform2D(angle,size,0,at)

func _triangle(a: Vector2, b: Vector2, c: Vector2, ca: Color, cb: Color, cc: Color) -> void:
    if batch_used+3>BATCH_VERTEX_CAP:
        batch_overflows+=1
        return
    batch_vertices[batch_used]=a;batch_vertices[batch_used+1]=b;batch_vertices[batch_used+2]=c
    batch_colours.encode_u32(batch_used*4,ca.to_abgr32())
    batch_colours.encode_u32((batch_used+1)*4,cb.to_abgr32())
    batch_colours.encode_u32((batch_used+2)*4,cc.to_abgr32())
    batch_used+=3

func _polygon(points: PackedVector2Array, colour: Color) -> void:
    var indices:=circle_triangles if points.size()==24 else wing_triangles if points.size()==11 else spark_triangles
    for i in range(0,indices.size(),3):
        _triangle(pen*points[indices[i]],pen*points[indices[i+1]],pen*points[indices[i+2]],colour,colour,colour)

func _circle(at: Vector2, radius: float, colour: Color) -> void:
    var previous:=pen
    pen=previous*Transform2D(0,Vector2.ONE*radius,0,at)
    _polygon(circle,colour)
    pen=previous

func _line(from: Vector2, to: Vector2, colour: Color, width:=1.0, antialias:=false) -> void:
    line_points[0]=from;line_points[1]=to
    _polyline(line_points,colour,width,antialias)

func _polyline(points: PackedVector2Array, colour: Color, width:=1.0, antialias:=false, count:=0) -> void:
    var size:=points.size() if count==0 else count
    if size<2:return
    var half:=width*.5
    for i in range(size):
        var before: Vector2=(points[i]-points[maxi(0,i-1)]).normalized()
        var after: Vector2=(points[mini(size-1,i+1)]-points[i]).normalized()
        if i==0:before=after
        if i==size-1:after=before
        var normal: Vector2=(before.orthogonal()+after.orthogonal()).normalized()
        var factor:=1.0/maxf(.5,normal.dot(before.orthogonal()))
        inner_left[i]=pen*(points[i]+normal*half*factor)
        inner_right[i]=pen*(points[i]-normal*half*factor)
        outer_left[i]=pen*(points[i]+normal*(half+.75)*factor)
        outer_right[i]=pen*(points[i]-normal*(half+.75)*factor)
    var clear:=Color(colour,0)
    for i in range(size-1):
        var j:=i+1
        _triangle(inner_left[i],inner_right[i],inner_left[j],colour,colour,colour)
        _triangle(inner_left[j],inner_right[i],inner_right[j],colour,colour,colour)
        if antialias:
            _triangle(outer_left[i],inner_left[i],outer_left[j],clear,colour,clear)
            _triangle(outer_left[j],inner_left[i],inner_left[j],clear,colour,colour)
            _triangle(inner_right[i],outer_right[i],inner_right[j],colour,clear,colour)
            _triangle(inner_right[j],outer_right[i],outer_right[j],colour,clear,clear)

func _arc(center: Vector2, radius: float, start: float, finish: float, count: int, colour: Color, width:=1.0, antialias:=false) -> void:
    for i in range(count):
        var angle:=lerpf(start,finish,float(i)/float(count-1))
        arc_points[i]=center+Vector2(cos(angle),sin(angle))*radius
    _polyline(arc_points,colour,width,antialias,count)

func _flush_batch() -> void:
    if batch_used==0:return
    # Blank the previous tail when a chapter/economy/visibility change uses less.
    for i in range(batch_used,batch_previous_used):
        batch_vertices[i]=Vector2.ZERO;batch_colours.encode_u32(i*4,0)
    batch_previous_used=batch_used;batch_peak_used=maxi(batch_peak_used,batch_used)
    var view:=get_viewport_rect().size
    if view!=batch_bounds:
        batch_bounds=view
        # Explicit bounds are essential: the original zeroed surface has no
        # useful AABB, and its streamed vertices lie around the seabed.
        batch_mesh.custom_aabb=AABB(Vector3(-256,-128,-1),Vector3(view.x+512,view.y+384,2))
    batch_mesh.surface_update_vertex_region(0,0,batch_vertices.to_byte_array())
    batch_mesh.surface_update_attribute_region(0,0,batch_colours)
    batch_updates+=1
    draw_mesh(batch_mesh,null)

func _clam(at: Vector2, c: Array, t: float, phase: float, near: float) -> void:
    # The existing painted clam rests amongst its own tiny flowers and rocks.
    var pearl:=at+Vector2(-1,-17)
    _glow(pearl,c[2],3.3, .75+near*.25)
    var count:=2 if economy else 3
    for i in range(count):
        var angle:=phase+i*2.1+t*.24
        var wisp:=pearl+Vector2(sin(angle)*26, -26-i*12+cos(angle*1.3)*5-near*8)
        _spark(wisp,c[i%3],2.1,.34+sin(t*.8+phase+i)*.12)

func _lanterns(at: Vector2, c: Array, t: float, phase: float, near: float) -> void:
    for i in range(2 if economy else 3):
        var root_at:=at+Vector2((i-1)*24,1)
        var sway:=sin(t*.7+phase+i)*.07+near*.05
        _set_pen(root_at,sway,Vector2(.8,.8+float(i%2)*.22))
        _polyline(stem,Color(.59,.78,.75,.55),1.4,true)
        _set_pen(Vector2.ZERO)
        var pod:=root_at+(Vector2(0,-60)*Vector2(.8,.8+float(i%2)*.22)).rotated(sway)
        _oval(pod,Vector2(7,11),Color(c[0],.5),sway)
        _oval(pod,Vector2(4,8),Color(c[2],.48),sway)
        _glow(pod+Vector2(0,2),c[1],2.6,.72)
        _spark(pod+Vector2(13,-16),c[2],1.8,.34)

func _wing_pair(at: Vector2, c: Array, t: float, phase: float, scale: float) -> void:
    var flutter:=.65 if reduced else .55+sin(t*2.6+phase)*.22
    for side in [-1,1]:
        _set_pen(at,float(side)*.10,Vector2(float(side)*scale*flutter,scale))
        _polygon(wing,Color(c[0],.64))
        _set_pen(at+Vector2(side*2.0,-1),float(side)*.17,Vector2(float(side)*scale*flutter*.62,scale*.65))
        _polygon(wing,Color(c[2],.42))
    _set_pen(Vector2.ZERO)
    _line(at+Vector2(0,-7*scale),at+Vector2(0,6*scale),Color(.87,.95,.84,.7),1.5,true)
    _circle(at+Vector2(0,-8*scale),1.65*scale,Color(.97,1,.92,.7))

func _orchids(at: Vector2, c: Array, t: float, phase: float, near: float) -> void:
    for i in range(1 if economy else 2):
        var flutter_at:=at+Vector2(-26+i*54+sin(t*.35+phase+i)*9,-68-i*25+cos(t*.61+phase+i)*7-near*13)
        _glow(flutter_at,c[1],3,.30)
        _wing_pair(flutter_at,c,t,phase+i*.8,.68+i*.13)
        _spark(flutter_at+Vector2(-17,16),c[1],1.6,.25)

func _corals(at: Vector2, c: Array, t: float, phase: float, near: float) -> void:
    for i in range(2 if economy else 4):
        var tip:=at+Vector2(-30+i*20,-33-float(i%2)*16)
        _glow(tip,c[i%3],2.7,.68+sin(t*.45+phase+i)*.13+near*.13)
        var mote:=tip+Vector2(sin(t*.3+phase+i)*7,-26-cos(t*.42+i)*5-near*10)
        _spark(mote,c[1],1.9,.40)

func _mobile(at: Vector2, c: Array, t: float, phase: float, near: float) -> void:
    var center:=at+Vector2(0,-67)
    _arc(center+Vector2(0,12),34,PI*1.08,PI*1.92,20,Color(c[2],.52),1,true)
    _line(center+Vector2(0,-22),at-Vector2(0,22),Color(c[2],.26),1,true)
    for i in range(2 if economy else 3):
        var attach:=center+Vector2(-26+i*26,-9-float(i%2)*9)
        var sway:=sin(t*.55+phase+i*.7)*7+near*3
        var end:=attach+Vector2(sway,20+float(i%2)*10)
        _line(attach,end,Color(c[2],.4),1,true)
        _glow(end,c[i%3],4.0,.84)
        _spark(end+Vector2(0,-1),c[2],1.5,.34)

func _tadpoles(at: Vector2, c: Array, t: float, phase: float, near: float) -> void:
    for i in range(2 if economy else 3):
        var swim:=at+Vector2(-28+i*30+sin(t*.48+phase+i)*9,-53-float(i%2)*23+cos(t*.66+phase+i)*6-near*11)
        var angle:=sin(t*.55+phase+i)*.16
        _set_pen(swim,angle,Vector2(.82,.82))
        _polyline(tail,Color(c[(i+1)%3],.5),2.1,true)
        _set_pen(Vector2.ZERO)
        _oval(swim,Vector2(8,5),Color(c[i%3],.65),angle)
        _oval(swim+Vector2(-3,-1),Vector2(4,2.5),Color(1,1,.93,.32),angle)
        _circle(swim+Vector2(4,-1),.95,Color(.09,.27,.25,.7))

func _stars(at: Vector2, c: Array, t: float, phase: float, near: float) -> void:
    for i in range(2 if economy else 3):
        var angle:=phase+i*TAU/3+t*.15
        var mote:=at+Vector2(sin(angle)*34,-53+cos(angle)*11-near*9)
        _glow(mote,c[i%3],2.8,.65)
        _spark(mote,c[2],1.9,.38)
    _arc(at+Vector2(0,-40),38,PI*1.13,PI*1.87,18,Color(c[1],.24),1,true)

func _family(at: Vector2, c: Array, t: float, phase: float, near: float) -> void:
    var baby:=at+Vector2(28,-23+sin(t*.68+phase)*2)
    _painting(SHELL,baby,25,Color(1,.94,.98,.8))
    var wing_at:=at+Vector2(16+sin(t*.4+phase)*8,-78+cos(t*.63+phase)*7-near*10)
    _wing_pair(wing_at,c,t,phase,.55)
    _glow(at+Vector2(-14,-12),c[1],2.8,.55)

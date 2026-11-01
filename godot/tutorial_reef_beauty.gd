extends RefCounted
## The tutorial's single scenery palette. Each garden has one authored placement.
const Art=preload("res://godot/tutorial_atelier_art.gd")
const SAND: Texture2D=preload("res://godot/assets/tutorial-v030/sand_pearl_tile.png")
const STONE: Texture2D=preload("res://godot/assets/tutorial-v030/reef_stone_teal_tile.png")
const PEARL: Texture2D=preload("res://godot/assets/treasure-v031/reward_pearl.png")
const GLOW: Texture2D=preload("res://godot/assets/treasure-v031/pearl_glow.png")
const MOUTHS: Array[Vector2]=[Vector2(500,820),Vector2(1000,1320),Vector2(1940,2260),Vector2(2700,3020)]
static func _ground(x: float) -> float:
    return 896.0+sin(x*.006)*4.0+sin(x*.019)*1.8+sin(x*.0017)*4.0
static func _in_mouth(x: float,padding:=0.0) -> bool:
    for gap in MOUTHS:
        if x>gap.x-padding and x<gap.y+padding:return true
    return false
static func draw_background(_canvas: CanvasItem,_camera: float,_elapsed: float,_gentle: bool,_view: Vector2) -> void:pass
static func draw_foreground(_canvas: CanvasItem,_camera: float,_elapsed: float,_gentle: bool,_view: Vector2) -> void:pass
static func draw_seabed(canvas: CanvasItem,camera: float,view: Vector2) -> void:
    var spans: Array[Vector2]=[];var begin:=camera-40.0
    for gap in MOUTHS:
        if gap.y<begin:continue
        if gap.x>camera+view.x+40:break
        if gap.x>begin:spans.append(Vector2(begin,gap.x))
        begin=maxf(begin,gap.y)
    if begin<camera+view.x+40:spans.append(Vector2(begin,camera+view.x+40))
    for span in spans:
        var edge:=PackedVector2Array();var n:=maxi(2,int(ceil((span.y-span.x)/20.0)))
        for j in range(n+1):
            var x:=lerpf(span.x,span.y,float(j)/n);edge.append(Vector2(x-camera,_ground(x)))
        var stone:=edge.duplicate();stone.append(Vector2(span.y-camera,1000));stone.append(Vector2(span.x-camera,1000))
        var uv:=PackedVector2Array()
        for point in stone:uv.append(Vector2(point.x+camera,point.y)/417.0)
        canvas.draw_polygon(stone,PackedColorArray([Color(.44,.61,.63)]),uv,STONE)
        var sand:=edge.duplicate()
        for j in range(edge.size()-1,-1,-1):sand.append(edge[j]+Vector2(0,7.0+sin((edge[j].x+camera)*.033)*2.0))
        var suv:=PackedVector2Array()
        for point in sand:suv.append(Vector2(point.x+camera,point.y)/263.0)
        canvas.draw_polygon(sand,PackedColorArray([Color(.92,.94,.83,.72)]),suv,SAND)
static func draw_rock(canvas: CanvasItem,rect: Rect2,world_x: float,index: int) -> void:
    var id:=11
    if rect.size.x<72:id=11
    elif world_x<1100:id=0
    elif world_x<1800:id=1
    elif world_x<3000:id=2
    elif world_x<3500:id=6
    elif world_x<3800:id=4
    elif world_x<4250:id=3
    elif world_x<4400:id=7
    elif world_x<4700:id=8
    elif world_x<5000:id=5
    elif world_x<5300:id=9
    else:id=10
    var tex: Texture2D=Art.rock(id)
    var size:=rect.size+Vector2(8,8)
    var top:=rect.position-Vector2(4,4)
    if rect.position.y>600:
        size.y=size.x*tex.get_height()/tex.get_width()
        if id==4:size=Vector2(rect.size.x+10,896-rect.position.y+7)
        top.y=rect.position.y-6
    canvas.draw_texture_rect(tex,Rect2(top,size),false,Color(.86,.94,.94))
static func draw_perch(canvas: CanvasItem,rect: Rect2,id: int) -> void:
    # Two different end stones retain native paint proportions within the ledge.
    var left: Texture2D=Art.rock(0 if id%2==0 else 11)
    var right: Texture2D=Art.rock(9 if id%2==0 else 3)
    var h:=rect.size.y+6.0
    var a:=Vector2(h*left.get_width()/left.get_height(),h)
    var b:=Vector2(h*right.get_width()/right.get_height(),h)
    canvas.draw_texture_rect(left,Rect2(rect.position-Vector2(4,4),a),false,Color(.84,.93,.93))
    canvas.draw_texture_rect(right,Rect2(Vector2(rect.end.x-b.x+4,rect.position.y-4),b),false,Color(.84,.93,.93))
static func draw_swim_ring(canvas: CanvasItem,at: Vector2,index: int,completed: int,elapsed: float,gentle: bool) -> void:
    var tex: Texture2D=Art.wreath(index)
    var diameter:=174.0
    var size:=tex.get_size()*(diameter/maxf(tex.get_width(),tex.get_height()))
    var tint:=Color(.75,.97,.89,.65) if index<completed else Color(1,1,1,.97)
    canvas.draw_texture_rect(tex,Rect2(at-size*.5,size),false,tint)
    if index==completed:
        var glimmer:=.22 if gentle else .20+.04*sin(elapsed*.8)
        canvas.draw_texture_rect(GLOW,Rect2(at-Vector2(65,65),Vector2(130,130)),false,Color(.93,.91,.65,glimmer))
static func draw_pearl(canvas: CanvasItem,at: Vector2,elapsed: float,gentle: bool) -> void:
    var pulse:=1.0 if gentle else 1.0+.025*sin(elapsed*1.7+at.x*.013)
    var size:=Vector2.ONE*21.0*pulse
    canvas.draw_texture_rect(GLOW,Rect2(at-Vector2(19,19),Vector2(38,38)),false,Color(.78,.97,.94,.12))
    canvas.draw_texture_rect(PEARL,Rect2(at-size*.5,size),false,Color(1,.98,.96))
static func draw_entrance(canvas: CanvasItem,at: Vector2,tint: Color,elapsed: float,gentle: bool) -> void:
    for i in range(2):
        var drift:=0.0 if gentle else fposmod(elapsed*5.0,51)
        var p:=Vector2(at.x+sin(float(i)*2.4+(0.0 if gentle else elapsed*.2))*11.0,937.0+i*51.0+drift)
        canvas.draw_circle(p,1.6,Color(tint,.33))
static func draw_cave_details(canvas: CanvasItem,room: Dictionary,id: int,elapsed: float,gentle: bool) -> void:
    var x: float=room['x'];var y: float=room['y'];var w: float=room['w'];var h: float=room['h']
    for i in range(5):
        var p:=Vector2(x+110+fposmod(float(i)*239.7,w-220),y+120+fposmod(float(i)*131-(0.0 if gentle else elapsed*3),h-220))
        canvas.draw_circle(p,1.2,Color(.80,.96,.94,.21))
static func draw_practice(canvas: CanvasItem,at: Vector2,on: bool) -> void:
    var tex: Texture2D=Art.plinth(5)
    canvas.draw_texture_rect(tex,Rect2(at+Vector2(-50,14),Vector2(100,55)),false,Color(.91,.97,.95))
    canvas.draw_texture_rect(GLOW,Rect2(at-Vector2(48,48),Vector2(96,96)),false,Color(.67,1,.89,.24 if on else .12))
    canvas.draw_texture_rect(PEARL,Rect2(at-Vector2(14,14),Vector2(28,28)),false,Color(.7,1,.85) if on else Color.WHITE)

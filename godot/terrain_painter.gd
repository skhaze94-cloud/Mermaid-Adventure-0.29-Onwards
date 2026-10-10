extends RefCounted
## Stable, world-scaled terrain art. Never changes gameplay geometry.
const STONE = preload("res://godot/assets/reef-stone-v018.png")
const Art = preload("res://godot/environment_art.gd")
const ARCH = preload("res://godot/assets/environment-portal-v011.webp")
const FORMATIONS = preload("res://godot/assets/reef-formations-v018.png")
const REGIONS := [Rect2(41,48,710,559),Rect2(800,39,695,571),
    Rect2(24,669,729,292),Rect2(788,656,727,309)]
static var formation_frames: Array[Texture2D] = []
const TINTS := {"shadow":Color(.88,.74,1), "palace":Color(1,.94,1),
    "blackwater":Color(.56,.73,.82), "rana":Color(.75,.96,.82),
    "nessie":Color(.73,.92,.91), "training":Color(.92,1,.94),
    "miguel":Color(.79,1,.92), "highland":Color(.86,.98,1)}

## The art's ground is a world plane, never a screen-bottom offset.
const GROUND_Y := 896.0
static func ground_y(world_x: float, base_y := GROUND_Y) -> float:
    return base_y + sin(world_x*.006)*4.0 + sin(world_x*.019)*1.8 + sin(world_x*.0017)*4.0

static func oval(canvas: CanvasItem, center: Vector2, radius: Vector2, colour: Color) -> void:
    var points := PackedVector2Array()
    for i in range(32): points.append(center+Vector2(cos(i*TAU/32),sin(i*TAU/32))*radius)
    canvas.draw_colored_polygon(points,colour)

static func contact(canvas: CanvasItem, base: Vector2, width: float, strength := .28) -> void:
    # Broad penumbra plus a small dark contact: neither leaves a hard sticker edge.
    for i in range(4,0,-1):
        oval(canvas,base+Vector2(3,1),Vector2(width*(.40+i*.04),2.0+i*1.2),Color(.015,.045,.065,strength*.13))
    oval(canvas,base,Vector2(width*.29,2.0),Color(.018,.04,.055,strength*.55))

static func seabed(canvas: CanvasItem, view: Vector2, camera: float, theme: String,
        base_y := GROUND_Y, opacity := 1.0) -> void:
    if base_y > view.y+15: return
    var tint: Color = TINTS.get(theme,Color.WHITE)*Color(.55,.72,.77,opacity)
    tint.a = opacity
    # Continuous uneven lip; world UVs stop stone detail sliding beneath plants.
    var points := PackedVector2Array()
    for x in range(-32,int(view.x)+65,24):
        points.append(Vector2(x,ground_y(x+camera,base_y)))
    points.append(Vector2(view.x+64,maxf(view.y+16,base_y+110)))
    points.append(Vector2(-32,maxf(view.y+16,base_y+110)))
    var uv := PackedVector2Array()
    for point in points: uv.append(Vector2((point.x+camera)/640.0,point.y/640.0))
    # Canvas texture repeat is enabled by each scenery owner.
    canvas.draw_polygon(points,PackedColorArray([tint]),uv,STONE)
    var rim := PackedVector2Array()
    for x in range(-32,int(view.x)+65,24): rim.append(Vector2(x,ground_y(x+camera,base_y)+1))
    canvas.draw_polyline(rim,Color(.27,.56,.55,.10*opacity),2,true)
    # Organic small caps conceal the horizontal atlas-foot seam in the stone bed.
    var first := int(floor(camera/210.0))-1
    for i in range(first,first+int(ceil(view.x/210.0))+3):
        var world_x := i*210.0+sin(i*2.1)*32.0
        var width := 180.0+posmod(i,3)*17.0
        var top := ground_y(world_x,base_y)-13.0
        canvas.draw_texture_rect(formation(2+posmod(i,2)),Rect2(world_x-camera-width*.5,top,width,42),false,Color(tint.r,tint.g,tint.b,.72*opacity))

static func support(canvas: CanvasItem, rect: Rect2, theme: String) -> void:
    # Recessed buttress, with fixed-size stone detail rather than a stretched sprite.
    var center := rect.get_center().x
    var top := rect.position.y+rect.size.y*.61
    var bottom := GROUND_Y+12.0
    var tint: Color = TINTS.get(theme,Color.WHITE)
    var points := PackedVector2Array()
    var uv := PackedVector2Array()
    var colours := PackedColorArray()
    for side in [-1,1]:
        for step in range(9):
            var t := step/8.0 if side<0 else 1.0-step/8.0
            var width := rect.size.x*(.20+.31*t)+sin(t*19+center)*rect.size.x*.035
            var point := Vector2(center+side*width,lerpf(top,bottom,t))
            points.append(point)
            uv.append(point/360.0)
            var light := .86 if side < 0 else .48
            colours.append(Color(tint.r*light*.68,tint.g*light*.83,tint.b*light,.28 if side < 0 else .40))
    canvas.draw_polygon(points,colours,uv,STONE)
    contact(canvas,Vector2(center,GROUND_Y+3),rect.size.x,.25)


static func rock(canvas: CanvasItem, rect: Rect2, index: int, theme: String) -> void:
    var tint: Color = TINTS.get(theme,Color.WHITE)
    var floor_rock := rect.position.y > 450.0
    if floor_rock:
        # Extend the painted foot into sediment; collision stays at its source rectangle.
        var foot := maxf(rect.end.y,GROUND_Y+10.0)
        var visual := Rect2(rect.position-Vector2(6,6),Vector2(rect.size.x+12,foot-rect.position.y+6))
        contact(canvas,Vector2(rect.get_center().x,GROUND_Y+3),rect.size.x,.40)
        canvas.draw_texture_rect(formation(2+index%2),visual,false,tint)
    else:
        # Recessed reef neck behind an elevated ledge. Soft atmosphere makes its
        # decorative support distinct from the opaque collision-bearing cap.
        support(canvas,rect,theme)
        canvas.draw_texture_rect(formation(index%2),rect.grow(6),false,tint)

static func formation(index: int) -> Texture2D:
    if formation_frames.is_empty():
        for region in REGIONS:
            var atlas := AtlasTexture.new()
            atlas.atlas = FORMATIONS
            atlas.region = region
            atlas.filter_clip = true
            formation_frames.append(atlas)
    return formation_frames[index]

static func panorama(canvas: CanvasItem, painting: Texture2D, view: Vector2,
        waterline: float, source_line: float, progress: float) -> void:
    var scale := maxf(view.x/painting.get_width(),maxf(waterline/source_line,
        (view.y-waterline)/(painting.get_height()-source_line)))*1.06
    var size := painting.get_size()*scale
    canvas.draw_texture_rect(painting,Rect2(Vector2(-(size.x-view.x)*progress,
        waterline-source_line*scale),size),false)

static func planted(canvas: CanvasItem, texture: Texture2D, base: Vector2,
        height: float, tint: Color = Color.WHITE) -> void:
    var size := texture.get_size()*(height/texture.get_height())
    contact(canvas,base-Vector2(0,4),size.x,.32)
    canvas.draw_texture_rect(texture,Rect2(base-Vector2(size.x*.5,size.y),size),false,tint)

static func garden(canvas: CanvasItem, base: Vector2, index: int, theme: String, height := 140.0) -> void:
    planted(canvas,Art.garden(index),base+Vector2(0,5),height,TINTS.get(theme,Color.WHITE))

static func portal(canvas: CanvasItem, center: Vector2, unlocked: bool) -> void:
    # The original interaction position is retained, with a recessed stone plinth.
    var foot := center+Vector2(0,133)
    var support := Rect2(Vector2(center.x-58,foot.y-14),Vector2(116,GROUND_Y+9-foot.y+14))
    canvas.draw_texture_rect(Art.rock(0),support,false,Color(.52,.72,.78,.8))
    contact(canvas,Vector2(center.x,GROUND_Y+3),145,.45)
    contact(canvas,foot,150,.30)
    var glow := PackedVector2Array()
    for i in range(48):
        glow.append(center+Vector2(cos(i*TAU/48)*52,sin(i*TAU/48)*91))
    canvas.draw_colored_polygon(glow,Color(.23,.95,.9,.22) if unlocked else Color(.05,.08,.15,.45))
    var size := ARCH.get_size()*(285.0/ARCH.get_height())
    canvas.draw_texture_rect(ARCH,Rect2(center-size*.5,size),false,
        Color.WHITE if unlocked else Color(.5,.61,.74,.85))

static func prop_pedestal(pos: Vector2, size: Vector2, world_x: float) -> Rect2:
    var foot := pos.y+size.y*.5
    var floor_y := ground_y(world_x)+10
    if foot < floor_y-110 or foot > floor_y+10: return Rect2()
    return Rect2(pos.x-size.x*.65,foot-5,size.x*1.3,maxf(8,floor_y-foot+5))

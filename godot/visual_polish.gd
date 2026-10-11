extends RefCounted
## Shared, crisp gameplay symbols. No decorative raster button or ghost actor.
static func line(canvas: CanvasItem, points: Array, center: Vector2, unit: float, tint: Color, width := 2.5) -> void:
    var path := PackedVector2Array()
    for p in points: path.append(center+Vector2(p[0],p[1])*unit)
    canvas.draw_polyline(path,tint,width,true)
static func glyph(canvas: CanvasItem, action: String, center: Vector2, size: float, tint: Color) -> void:
    var u := size*.5
    var stroke := maxf(2.0,size*.055)
    match action:
        "jump":
            line(canvas,[[0,.55],[0,-.65]],center,u,tint,stroke)
            line(canvas,[[-.38,-.25],[0,-.65],[.38,-.25]],center,u,tint,stroke)
            line(canvas,[[-.68,.72],[-.34,.62],[0,.72],[.34,.62],[.68,.72]],center,u,tint,stroke)
        "boost":
            for shift in [-.30,.30]: line(canvas,[[shift-.28,-.55],[shift+.22,0],[shift-.28,.55]],center,u,tint,stroke)
        "bubble":
            canvas.draw_arc(center+Vector2(-.12,.12)*u,u*.55,0,TAU,40,tint,stroke,true)
            canvas.draw_arc(center+Vector2(.51,-.45)*u,u*.23,0,TAU,24,tint,stroke,true)
            canvas.draw_arc(center+Vector2(-.12,.12)*u,u*.34,-2.65,-1.8,12,tint,stroke,true)
        "pause":
            for x in [-.24,.24]: line(canvas,[[x,-.58],[x,.58]],center,u,tint,stroke*1.5)
        "lock":
            canvas.draw_arc(center+Vector2(0,-.15)*u,u*.36,PI,TAU,20,tint,stroke,true)
            line(canvas,[[-.46,-.15],[.46,-.15],[.46,.60],[-.46,.60],[-.46,-.15]],center,u,tint,stroke)
        "check": line(canvas,[[-.55,.0],[-.10,.42],[.65,-.40]],center,u,tint,stroke)
static func boss_cue(canvas: CanvasItem, center: Vector2, width: float, vulnerable: bool) -> void:
    var tint := Color("#89ebbc") if vulnerable else Color("#eac695")
    tint.a=.8 if vulnerable else .38
    for side in [-1,1]:
        var at := center+Vector2(side*width,72)
        canvas.draw_polyline(PackedVector2Array([at+Vector2(0,-14),at,at+Vector2(-side*25,0)]),tint,2,true)
static func launch_hint(canvas: CanvasItem, center: Vector2) -> void:
    glyph(canvas,"jump",center,31,Color(.66,.96,.91,.65))
static func shell_switch(canvas: CanvasItem, center: Vector2, opened: bool) -> void:
    canvas.draw_circle(center,25,Color("#173c51"))
    canvas.draw_arc(center,25,0,TAU,40,Color("#91e4c3") if opened else Color("#c5b4e2"),2,true)
    glyph(canvas,"check" if opened else "bubble",center,28,Color("#aaf0d2") if opened else Color("#eadfff"))

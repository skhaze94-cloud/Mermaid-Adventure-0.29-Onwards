extends "res://godot/whimsy_garden.gd"
## Presentation only. The host/model own discovery, progress and reward ledgers.
## Reuse the Whimsy brush's fixed dynamic mesh for every small line/petal/glow.
const Kit = preload("res://godot/ui_kit.gd")
const Creature = preload("res://godot/creature_art.gd")
const GUIDE_PATH := "res://godot/assets/living-reef/pearl-seahorse.webp"
var host: Node2D
var activity: RefCounted
var view_state: Dictionary = {}
var profile: Dictionary = {}
var presentation_state := "hidden"
var caption: Panel
var caption_title: Label
var caption_hint: Label
var guide_texture: Texture2D
var guide_art_path := ""
var guide_custom := false
var quiet := false
var guide_right := true
var previous_actor := Vector2.ZERO
var caption_key := ""
var caption_anchor := Vector2.ZERO
var caption_scale := 1.0
var caption_candidates:=PackedVector2Array()
var reward_phase := 0.0

func _ready() -> void:
    super._ready()
    z_index=1
    _prepare_caption()
    visible=false

func _prepare_caption() -> void:
    if is_instance_valid(caption):return
    # This deliberately is not a Container. An autowrapping label can report a
    # huge temporary minimum at width zero; that must never resize the panel.
    caption=Panel.new();caption.name="ReefDiscoveryCaption"
    caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;caption.clip_contents=true
    caption.add_theme_stylebox_override("panel",Kit.panel(Color(.025,.12,.18,.88),Color(.79,.68,.84,.62),14))
    caption_title=Kit.label("",20,Color("f5dfbd"));caption_title.add_theme_font_override("font",Kit.FONT)
    caption_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    caption_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;caption.add_child(caption_title)
    caption_hint=Kit.label("",17,Color("e5edf4"));caption_hint.add_theme_font_override("font",Kit.BODY)
    caption_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    caption_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;caption.add_child(caption_hint)
    caption_candidates.resize(7)
    add_child(caption);caption.hide()

func bind(level: Node2D, model: RefCounted) -> void:
    host=level;activity=model
    _prepare();_prepare_caption()
    # Load the selected chapter's friend during scene setup, even while it is
    # still undiscovered/offscreen. Approaching an activity never loads art.
    var initial: Variant=activity.call("snapshot") if activity.has_method("snapshot") else {}
    var selected: Dictionary=initial.get("profile",{}) if initial is Dictionary else {}
    if String(selected.get("kind",""))=="guide":_guide_art(String(selected.get("guide_asset",GUIDE_PATH)))
    sync()

func advance(dt: float) -> void:
    if not active or not is_instance_valid(host) or host.get_tree().paused:return
    if not reduced:clock+=maxf(0,dt)
    queue_redraw()

func sync() -> void:
    if not is_instance_valid(host) or not is_instance_valid(activity):
        active=false;visible=false
        if is_instance_valid(caption):caption.hide()
        return
    var next: Variant=activity.call("snapshot") if activity.has_method("snapshot") else {}
    view_state=next if next is Dictionary else {}
    profile=view_state.get("profile",{})
    presentation_state=String(view_state.get("state","hidden"))
    camera=float(host.get("camera"));waterline=float(host.call("_water_line"));player=Vector2(host.get("player"))
    chapter=clampi(int(profile.get("chapter",0)),0,7)
    reduced=bool(host.get("reduced_fx"));economy=not bool(host.get("high_depth_quality"))
    combat=bool(host.call("_whimsy_combat_active")) if host.has_method("_whimsy_combat_active") else false
    quiet=bool(view_state.get("quiet",combat)) or presentation_state=="hidden"
    var flow:=host.get_node_or_null("/root/SceneFlow")
    var loading: bool=flow!=null and bool(flow.get("busy"))
    var phase: String=host.get("state")
    active=not profile.is_empty() and _profile_on_camera() and phase in ["playing","paused"] and String(host.get("waterfall_phase")).is_empty() and not loading and bool(view_state.get("visible",true))
    visible=active
    if not active:
        caption.hide();last_build_us=0;batch_used=0;return
    var actor: Vector2=view_state.get("actor",profile.get("at",Vector2.ZERO))
    if actor.distance_squared_to(previous_actor)>.25:guide_right=actor.x>=previous_actor.x
    previous_actor=actor
    _sync_caption()
    queue_redraw()

func _profile_on_camera() -> bool:
    var left:=camera-250.0
    var right:=camera+get_viewport_rect().size.x+250.0
    for point in profile.get("points",[]):
        var x: float=Vector2(point).x
        if x>=left and x<=right:return true
    var actor: Vector2=view_state.get("actor",profile.get("at",Vector2.ZERO))
    if actor.x>=left and actor.x<=right:return true
    var home: Vector2=profile.get("home",profile.get("at",Vector2.ZERO))
    return home.x>=left and home.x<=right

func reset() -> void:
    super.reset()
    view_state={};profile={};presentation_state="hidden";caption_key=""
    previous_actor=Vector2.ZERO
    if is_instance_valid(caption):caption.hide()

func _guide_art(path: String) -> void:
    if path==guide_art_path and guide_texture:return
    guide_art_path=path
    guide_custom=not path.is_empty() and ResourceLoader.exists(path)
    if guide_custom:
        var texture: Texture2D=load(path)
        if path==GUIDE_PATH:
            var crop:=AtlasTexture.new();crop.atlas=texture
            crop.region=Rect2(180,40,740,1450);crop.filter_clip=true
            guide_texture=crop
        else:guide_texture=texture
    else:guide_texture=Creature.atlas("puffer",0)

func _sync_caption() -> void:
    var at: Vector2=profile.get("at",Vector2.ZERO)
    var points: Array=profile.get("points",[])
    var progress:=clampi(int(view_state.get("progress",0)),0,3)
    var kind:=String(profile.get("kind","choir"))
    var completed:=bool(view_state.get("completed",false))
    if kind=="guide":at=Vector2(view_state.get("actor",at))
    elif kind=="current" and not points.is_empty():at=Vector2(points[mini(progress,points.size()-1)])
    if completed:at=Vector2(profile.get("home",at)) if kind=="guide" else Vector2(points.back()) if not points.is_empty() else at
    caption_anchor=at
    var near:=player.distance_to(at)<530 and bool(view_state.get("nearby",true)) and not quiet and presentation_state!="hidden"
    caption.visible=near
    if not near:return
    var title:=String(profile.get("title","A little reef discovery"))
    var instruction:=String(view_state.get("active_hint","Swim closer and see what happens."))
    var repeated_progress:=" · %s / 3" % progress
    instruction=instruction.replace(repeated_progress+" voices","").replace(repeated_progress,"")
    instruction=instruction.replace("numbered hoop","glowing hoop")
    if completed:title+=" · complete"
    else:title+=" · %s / 3" % progress
    var key:=title+"\n"+instruction
    var changed:=key!=caption_key
    var view:=get_viewport_rect().size
    var physical:=float(host.get_window().size.y)/maxf(1,view.y)
    caption_scale=clampf(1/maxf(.1,physical),1,2.0)
    var width:=minf(380,(view.x-48)/caption_scale)
    caption.scale=Vector2.ONE*caption_scale
    if not is_equal_approx(caption.size.x,width):changed=true
    if changed:
        caption_key=key
        var content_width:=maxf(1,width-28)
        var title_height:=ceilf(Kit.FONT.get_multiline_string_size(title,HORIZONTAL_ALIGNMENT_CENTER,content_width,20).y)+2
        var hint_height:=ceilf(Kit.BODY.get_multiline_string_size(instruction,HORIZONTAL_ALIGNMENT_CENTER,content_width,17).y)+2
        # Set real widths before assigning text. Explicit panel dimensions never
        # depend on a label's deferred minimum-size/word-wrap notification.
        caption_title.position=Vector2(14,10);caption_title.size=Vector2(content_width,title_height)
        caption_hint.position=Vector2(14,14+title_height);caption_hint.size=Vector2(content_width,hint_height)
        caption_title.text=title;caption_hint.text=instruction
        caption.size=Vector2(width,title_height+hint_height+26)
    var extent:=caption.size*caption_scale
    var screen_at:=at-Vector2(camera,0)
    var target_bounds:=Rect2(screen_at-Vector2(58,72),Vector2(116,144))
    if kind in ["choir","current"] and not points.is_empty():
        var margin:=Vector2(62,66) if kind=="choir" else Vector2(80,108)
        var first:=Vector2(points[0])-Vector2(camera,0)
        target_bounds=Rect2(first-margin,margin*2)
        for point in points:
            var centered:=Vector2(point)-Vector2(camera,0)
            target_bounds=target_bounds.merge(Rect2(centered-margin,margin*2))
    var hero_bounds:=Rect2(player-Vector2(camera,0)-Vector2(220,120),Vector2(380,240))
    var safe:=Rect2(Vector2(20,170),Vector2(maxf(1,view.x-40),maxf(1,view.y-210)))
    var middle_x:=clampf(screen_at.x-extent.x*.5,safe.position.x,maxf(safe.position.x,safe.end.x-extent.x))
    var middle_y:=clampf(screen_at.y-extent.y*.5,safe.position.y,maxf(safe.position.y,safe.end.y-extent.y))
    caption_candidates[0]=Vector2(middle_x,target_bounds.position.y-extent.y-22)
    caption_candidates[1]=Vector2(middle_x,target_bounds.end.y+22)
    caption_candidates[2]=Vector2(target_bounds.end.x+22,middle_y)
    caption_candidates[3]=Vector2(target_bounds.position.x-extent.x-22,middle_y)
    # The royal teachers occupy the middle of the family lagoon. Keep a quiet
    # upper-water placement available instead of drawing instructions behind them.
    caption_candidates[4]=Vector2(middle_x,safe.position.y)
    caption_candidates[5]=Vector2(maxf(safe.position.x,safe.end.x-extent.x),300)
    caption_candidates[6]=Vector2(safe.position.x,300)
    for location in caption_candidates:
        var bounds:=Rect2(location,extent)
        if safe.encloses(bounds) and not bounds.intersects(target_bounds) and not bounds.intersects(hero_bounds) and _clear_of_royals(bounds):
            caption.position=location
            return
    # Keep the game and targets readable in a cramped frame. A nearby player
    # can reveal the coach again by swimming clear of its placement area.
    caption.hide()

func _clear_of_royals(bounds: Rect2) -> bool:
    if chapter!=7:return true
    for key in ["king","queen_teacher"]:
        var royal: Node2D=host.get(key)
        if not is_instance_valid(royal) or not royal.visible:continue
        var half: Vector2=Vector2(royal.get("size"))*.5+Vector2(20,20)
        if bounds.intersects(Rect2(royal.position-half,half*2)):return false
    return true

func _screen(at: Vector2) -> Vector2:return at-Vector2(camera,0)
func _done(index: int) -> bool:
    var values: Array=view_state.get("activated",[])
    return index<values.size() and bool(values[index])
func _motion() -> float:return 0.0 if reduced or quiet else clock

func _draw() -> void:
    if not active or profile.is_empty():return
    var started:=Time.get_ticks_usec()
    batch_used=0;pen=Transform2D.IDENTITY
    var kind:=String(profile.get("kind","choir"))
    var points: Array=profile.get("points",[])
    var tint: Color=profile.get("color",Color("d9c4eb"))
    var t:=_motion()
    match kind:
        "choir":_choir(points,tint,t)
        "guide":_guide(points,tint,t)
        "current":_currents(points,tint,t)
    if not quiet and bool(view_state.get("completed",false)) and float(view_state.get("glow_time",0))>0:
        var at: Vector2=profile.get("home",profile.get("at",Vector2.ZERO))
        if kind!="guide" and not points.is_empty():at=points.back()
        _reward(_screen(at),tint,t)
    pen=Transform2D.IDENTITY;_flush_batch()
    last_build_us=Time.get_ticks_usec()-started

func _choir(points: Array, tint: Color, t: float) -> void:
    for i in range(mini(3,points.size())):
        var at:=_screen(Vector2(points[i]))
        if not _in_view(at,135):continue
        var played:=_done(i)
        var bob:=0.0 if reduced else sin(t*1.1+i*1.8)*2.0
        if not quiet:_glow(at+Vector2(0,8),tint,24,.10 if not played else .18)
        _painting(SHELL,at+Vector2(0,39+bob),76,Color(1,.96,1,1 if played else .88))
        if quiet:continue
        # The clam's own pearl is the invitation; music notes confirm a touch.
        if played:
            _note(at+Vector2(19,-50+sin(t*.8+i)*3),Color("f4d5a4"),.85)
            if not economy:_note(at+Vector2(-21,-64+sin(t*.9+i)*3),Color(tint,.78),.63)
        else:
            _oval(at+Vector2(0,-41),Vector2(2.4,2.4),Color("efd7bc"))
        if i<points.size()-1 and i<2:
            var next:=_screen(Vector2(points[i+1]))
            _line(at+Vector2(45,11),next-Vector2(45,-11),Color(tint,.12),1,true)

func _note(at: Vector2, tint: Color, scale: float) -> void:
    _oval(at+Vector2(0,7*scale),Vector2(4.7,3.4)*scale,tint,-.25)
    _line(at+Vector2(4*scale,6*scale),at+Vector2(4*scale,-10*scale),tint,1.5,true)
    _arc(at+Vector2(5*scale,-10*scale),8*scale,-PI*.5,PI*.25,12,tint,1.35,true)

func _guide(points: Array, tint: Color, t: float) -> void:
    var home: Vector2=profile.get("home",profile.get("at",Vector2.ZERO))
    var nest:=Vector2(home.x,Terrain.ground_y(home.x)+3)
    if _in_view(_screen(nest),140):
        _painting(garden_frames[1],_screen(nest),116,Color(.96,.96,1,.9))
        var flower:=_screen(home)
        var foot:=_screen(nest)-Vector2(0,88)
        for i in range(12):
            var blend:=float(i)/11.0
            arc_points[i]=foot.lerp(flower+Vector2(0,17),blend)+Vector2(sin(blend*PI)*11,0)
        _polyline(arc_points,Color(.50,.74,.67,.30),1.6,true,12)
        if not quiet:_flower(flower+Vector2(0,17),tint,t,12)
    var actor:=_screen(Vector2(view_state.get("actor",profile.get("at",Vector2.ZERO))))
    if _in_view(actor,120) and guide_texture:
        var bob:=0.0 if reduced else sin(t*1.7)*2.4
        var size:=guide_texture.get_size()*(91.0/guide_texture.get_height())
        var origin:=actor-Vector2(size.x*.5,size.y*.48)+Vector2(0,bob)
        if guide_right:draw_texture_rect(guide_texture,Rect2(origin,size),false,Color.WHITE)
        else:draw_texture_rect(guide_texture,Rect2(origin+Vector2(size.x,0),Vector2(-size.x,size.y)),false,Color.WHITE)
        if not quiet:_glow(actor+Vector2(0,29),tint,8,.16)
        if not quiet and not guide_custom:
            _flower(actor+Vector2(17,-25),Color("eabfdd"),t,5)
    if quiet:return
    var progress:=clampi(int(view_state.get("progress",0)),0,3)
    for i in range(mini(3,points.size())):
        var here:=_screen(Vector2(points[i]))
        if not _in_view(here,85):continue
        var reached:=i<progress
        _flower(here,tint,t+float(i),5.5 if reached else 4)
        if i==progress and not bool(view_state.get("completed",false)):
            _glow(here,tint,9,.22)

func _flower(at: Vector2, tint: Color, t: float, radius: float) -> void:
    for i in range(5):
        var angle:=i*TAU/5.0
        var center:=at+Vector2(cos(angle),sin(angle))*radius*.6
        _oval(center,Vector2(radius*.6,radius*.28),Color(tint,.56),angle)
    _glow(at,Color("f2dcae"),radius*.32,.64)

func _currents(points: Array, tint: Color, t: float) -> void:
    var progress:=clampi(int(view_state.get("progress",0)),0,3)
    for i in range(mini(3,points.size())):
        var at:=_screen(Vector2(points[i]))
        if not _in_view(at,135):continue
        var passed:=i<progress or _done(i)
        var colour:=Color("d9bce9") if not passed else Color("f2d8aa")
        # An open, lilac/gold flower gate differs from mint hit-opportunity shells.
        for j in range(32):
            var angle:=float(j)*TAU/31.0
            arc_points[j]=at+Vector2(cos(angle)*53,sin(angle)*77)
        _polyline(arc_points,Color(colour,.16 if quiet else .5 if i==progress else .28),1.6,true,32)
        if quiet:continue
        for petal in range(4):
            var angle:=float(petal)*PI*.5
            var center:=at+Vector2(cos(angle)*56,sin(angle)*80)
            _oval(center,Vector2(8,3.2),Color(colour,.68),angle+PI*.5)
        for stream in range(2 if economy else 3):
            var y: float=-42+float(stream)*40
            var start:=at+Vector2(-31,y)
            var end:=at+Vector2(31,y+sin(t*.7+stream+i)*4)
            _line(start,end,Color(tint,.13),1.2,true)
        if passed:_flower(at+Vector2(0,-94),colour,t,5.3)
        elif i==progress:
            _oval(at+Vector2(0,-99),Vector2(3.5,3.5),Color("f1d5ad"))

func _reward(at: Vector2, tint: Color, t: float) -> void:
    var count:=3 if economy else 5
    for i in range(count):
        var angle:=float(i)*TAU/count+t*.16
        var light:=at+Vector2(cos(angle)*42,sin(angle)*22-43)
        _glow(light,Color("f4dcad") if i%2==0 else tint,3.2,.65)
    _note(at+Vector2(0,-96),Color("f4dfb5"),.9)

func _in_view(at: Vector2, margin: float) -> bool:
    var size:=get_viewport_rect().size
    return at.x>=-margin and at.x<=size.x+margin and at.y>=-margin and at.y<=size.y+margin

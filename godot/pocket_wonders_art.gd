extends "res://godot/whimsy_garden.gd"
## Read-only, manually advanced presentation for the Pocketful of Wonders.
## Painted pieces are loaded at bind. Two visible tableaux share the original
## Whimsy brush's single fixed 12,288-vertex surface and three caption nodes.
const Kit = preload("res://godot/ui_kit.gd")
const Pearl = preload("res://godot/pearl_storybook.gd")
const Creature = preload("res://godot/creature_art.gd")
const MAX_RECORDS := 16
const VISIBLE_CAP := 2
const ASSET_ROOT := "res://godot/assets/pocket-wonders/"
const KINDS := ["dream","tea","village","mirror","post"]
const ART_SPECS := {
    "dream":{"whale":"dream-whale.webp","carousel":"dream-carousel.webp","rain":"dream-rain.webp"},
    "tea":{"table":"tea-table.webp","jelly":"moon-jelly.webp","butler":"octopus-butler.webp"},
    "village":{"pearl":"shell-cottage-pearl.webp","lavender":"shell-cottage-lavender.webp","coral":"shell-cottage-coral.webp"},
    "mirror":{
        "sarah":{"file":"res://godot/assets/sarah-expressions-v019.webp","region":Rect2(15,80,710,570)},
        "sarah_joy":{"file":"res://godot/assets/sarah-expressions-v019.webp","region":Rect2(735,80,700,570)},
        "sarah_dream":{"file":"res://godot/assets/sarah-expressions-v019.webp","region":Rect2(1445,80,710,570)},
        "avina":{"file":"res://godot/assets/characters-v027/avina-baby.png","region":Rect2(160,45,790,650)}},
    "post":{"postman":"sea-slug-postman.webp"}}
const EXTENTS := {"dream":Vector2(300,300),"tea":Vector2(460,320),"village":Vector2(460,204),"mirror":Vector2(260,270),"post":Vector2(278,240)}
const HOUSE_ROLES := ["pearl","lavender","coral"]
const HOUSE_HEIGHTS := [124.0,148.0,116.0]
const HOUSE_WINDOWS := [Vector2(600,650),Vector2(460,650),Vector2(520,720)]
var replacement_painter: Callable
var host: Node2D
var activity: RefCounted
var records: Array = []
var view_state: Dictionary = {}
var selected := PackedInt32Array()
var selected_distances := PackedFloat32Array()
var visible_count := 0
var textures: Dictionary = {}
var source_textures: Dictionary = {}
var asset_manifest: Dictionary = {}
var texture_regions: Dictionary = {}
var texture_load_count := 0
var atlas_count := 0
var caption: Panel
var caption_title: Label
var caption_hint: Label
var caption_key := ""
var caption_scale := 1.0
var caption_index := -1
var caption_candidates := PackedVector2Array()
var station_bounds: Array[Rect2] = []
var quiet := false
var rope := PackedVector2Array()
var wave := PackedVector2Array()
var frame_draws := 0
var caption_updates := 0
var house_feet: Array[Vector2] = [Vector2.ZERO,Vector2.ZERO,Vector2.ZERO]
var house_heights := PackedFloat32Array([124.0,148.0,116.0])

func _ready() -> void:
    super._ready()
    z_index=1
    _prepare_wonders()
    visible=false

func _prepare_wonders() -> void:
    _prepare()
    if selected.size()!=VISIBLE_CAP:
        selected.resize(VISIBLE_CAP);selected.fill(-1)
        selected_distances.resize(VISIBLE_CAP);selected_distances.fill(INF)
        for i in range(VISIBLE_CAP):station_bounds.append(Rect2())
    if rope.is_empty():rope.resize(16);wave.resize(16)
    if is_instance_valid(caption):return
    caption=Panel.new();caption.name="PocketWonderCaption"
    caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;caption.clip_contents=true
    caption.add_theme_stylebox_override("panel",Pearl.panel(Pearl.IVORY,Pearl.SEAFOAM,18,10))
    caption_title=Pearl.label("",20,Pearl.INK)
    caption_title.add_theme_font_override("font",Kit.FONT)
    caption_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    caption_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    caption.add_child(caption_title)
    caption_hint=Pearl.label("",17,Pearl.INK)
    caption_hint.add_theme_font_override("font",Kit.BODY)
    caption_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    caption_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    caption.add_child(caption_hint)
    caption_candidates.resize(9)
    add_child(caption);caption.hide()

func bind(level: Node2D, model: RefCounted) -> void:
    host=level;activity=model
    _prepare_wonders()
    if asset_manifest.is_empty() and FileAccess.file_exists(ASSET_ROOT+"manifest.json"):
        var manifest: Variant=JSON.parse_string(FileAccess.get_file_as_string(ASSET_ROOT+"manifest.json"))
        if manifest is Dictionary:asset_manifest=manifest.get("assets",{})
    _read_snapshot()
    # The selected chapter's paintings, including later reveals, are ready
    # before the player approaches. sync/advance/draw never load resources.
    for record in records:
        if not record is Dictionary:continue
        var profile: Dictionary=record.get("profile",{})
        _load_kind(String(profile.get("kind","dream")),String(profile.get("variant","whale")))
    if _has_kind("village") and not textures.has("village/crab"):
        textures["village/crab"]=Creature.atlas("crab",0);atlas_count+=1
    sync()

func _has_kind(kind: String) -> bool:
    for record in records:
        if record is Dictionary and String(record.get("profile",{}).get("kind",""))==kind:return true
    return false

func _read_snapshot() -> void:
    var value: Variant=activity.call("snapshot") if is_instance_valid(activity) and activity.has_method("snapshot") else []
    view_state=value if value is Dictionary else {}
    if value is Array:records=value
    elif value is Dictionary:records=value.get("records",value.get("stations",[]))
    else:records=[]

func _load_kind(kind: String, variant: String) -> void:
    var pieces: Dictionary=ART_SPECS.get(kind,{})
    for role in pieces:
        if kind=="dream" and String(role)!=variant:continue
        var key:=kind+"/"+String(role)
        if textures.has(key):continue
        var spec: Variant=pieces[role]
        var file:=String(spec.get("file","")) if spec is Dictionary else String(spec)
        var path:=file if file.begins_with("res://") else ASSET_ROOT+file
        if not source_textures.has(path):
            source_textures[path]=load(path) if ResourceLoader.exists(path) else null
            if source_textures[path]!=null:texture_load_count+=1
        var image: Texture2D=source_textures[path]
        var region:=Rect2(Vector2.ZERO,image.get_size()) if image!=null else Rect2()
        if spec is Dictionary and spec.has("region"):region=spec.region
        elif asset_manifest.has(file.get_basename()):
            var bounds: Array=asset_manifest[file.get_basename()].get("region",[])
            if bounds.size()==4:region=Rect2(float(bounds[0]),float(bounds[1]),float(bounds[2]),float(bounds[3]))
        texture_regions[key]=region
        if image!=null and region!=Rect2(Vector2.ZERO,image.get_size()):
            var crop:=AtlasTexture.new();crop.atlas=image;crop.region=region;crop.filter_clip=true
            textures[key]=crop;atlas_count+=1
        else:textures[key]=image

func advance(dt: float) -> void:
    if not active or not is_instance_valid(host) or host.get_tree().paused:return
    if not reduced:clock+=maxf(0,dt)
    queue_redraw()

func sync() -> void:
    if not is_instance_valid(host) or not is_instance_valid(activity):
        _hide_all();return
    _read_snapshot()
    camera=float(host.get("camera"));player=Vector2(host.get("player"))
    waterline=float(host.call("_water_line")) if host.has_method("_water_line") else 280.0
    reduced=bool(host.get("reduced_fx"));economy=not bool(host.get("high_depth_quality"))
    combat=bool(host.call("_whimsy_combat_active")) if host.has_method("_whimsy_combat_active") else false
    var flow:=host.get_node_or_null("/root/SceneFlow")
    var loading: bool=flow!=null and bool(flow.get("busy"))
    var level_state:=String(host.get("state"))
    if loading or not bool(view_state.get("visible",true)) or level_state not in ["playing","paused"] or not String(host.get("waterfall_phase")).is_empty():
        _hide_all();return
    visible_count=0;selected.fill(-1);selected_distances.fill(INF)
    var viewport:=Rect2(Vector2.ZERO,get_viewport_rect().size).grow(36)
    for index in range(mini(MAX_RECORDS,records.size())):
        var record: Variant=records[index]
        if not record is Dictionary or not bool(record.get("visible",true)):continue
        var profile: Dictionary=record.get("profile",{})
        if profile.is_empty():continue
        var bounds:=_world_bounds(profile)
        bounds.position.x-=camera
        if not viewport.intersects(bounds):continue
        var at:=Vector2(profile.get("at",Vector2.ZERO))
        var score:=at.distance_squared_to(player)
        if bool(record.get("nearby",false)):score-=100000.0
        for slot in range(VISIBLE_CAP):
            if score>=selected_distances[slot]:continue
            for move in range(VISIBLE_CAP-1,slot,-1):
                selected[move]=selected[move-1];selected_distances[move]=selected_distances[move-1]
            selected[slot]=index;selected_distances[slot]=score
            break
    for slot in range(VISIBLE_CAP):
        if selected[slot]<0:continue
        visible_count+=1
        station_bounds[slot]=_world_bounds(records[selected[slot]].get("profile",{}))
        station_bounds[slot].position.x-=camera
    active=visible_count>0;visible=active
    if not active:
        _hide_all();return
    quiet=combat
    _sync_caption()
    queue_redraw()

func _hide_all() -> void:
    active=false;visible=false;visible_count=0;caption_index=-1
    last_build_us=0;batch_used=0;frame_draws=0
    if is_instance_valid(caption):caption.hide()

func reset() -> void:
    super.reset()
    records=[];view_state={};caption_key="";caption_index=-1;visible_count=0
    if is_instance_valid(caption):caption.hide()

func _world_bounds(profile: Dictionary) -> Rect2:
    var extent: Vector2=EXTENTS.get(String(profile.get("kind","dream")),Vector2(280,240))
    var at:=Vector2(profile.get("at",Vector2.ZERO))
    var kind:=String(profile.get("kind","dream"))
    if kind=="village":at=Vector2(profile.get("prop_at",at))-Vector2(0,86)
    elif kind=="post":at=Vector2(profile.get("prop_at",at))-Vector2(0,78)
    elif kind=="tea":at+=Vector2(0,32)
    return Rect2(at-extent*.5,extent)

func _record_quiet(record: Dictionary) -> bool:
    return combat or bool(view_state.get("quiet",false)) or bool(record.get("quiet",false)) or String(record.get("state","dormant")) in ["hidden","dormant"]

func _screen(at: Vector2) -> Vector2:return at-Vector2(camera,0)

func _sync_caption() -> void:
    caption.hide();caption_index=-1
    if host.message_time>0 or not host.premium_hud.visible:return
    var nearest:=INF
    for slot in range(visible_count):
        var index:=selected[slot]
        var record: Dictionary=records[index]
        if _record_quiet(record) or not bool(record.get("nearby",true)):continue
        var profile: Dictionary=record.get("profile",{})
        var distance:=player.distance_squared_to(Vector2(profile.get("at",Vector2.ZERO)))
        if distance>460.0*460.0 or distance>=nearest:continue
        nearest=distance;caption_index=index
    if caption_index<0:return
    var record: Dictionary=records[caption_index]
    var profile: Dictionary=record.get("profile",{})
    var title:=String(profile.get("title","A pocketful of wonder"))
    var instruction:=String(record.get("active_hint",record.get("hint",profile.get("hint","Swim closer and see what happens."))))
    if instruction.strip_edges().is_empty():return
    if bool(record.get("completed",false)):
        title="Nori" if String(profile.get("kind",""))=="post" else "Bramble & Lumi" if String(profile.get("kind",""))=="tea" else title
    var key:=title+"\n"+instruction
    var view:=get_viewport_rect().size
    var physical:=float(host.get_window().size.y)/maxf(1,view.y)
    caption_scale=clampf(1.0/maxf(.1,physical),1,2)
    var width:=minf(350,(view.x-48)/caption_scale)
    var changed:=key!=caption_key or not is_equal_approx(caption.size.x,width)
    caption.scale=Vector2.ONE*caption_scale
    if changed:
        caption_key=key;caption_updates+=1
        var content_width:=maxf(1,width-28)
        var title_height:=ceilf(Kit.FONT.get_multiline_string_size(title,HORIZONTAL_ALIGNMENT_CENTER,content_width,20).y)+2
        var hint_height:=ceilf(Kit.BODY.get_multiline_string_size(instruction,HORIZONTAL_ALIGNMENT_CENTER,content_width,17).y)+2
        caption_title.position=Vector2(14,9);caption_title.size=Vector2(content_width,title_height)
        caption_hint.position=Vector2(14,12+title_height);caption_hint.size=Vector2(content_width,hint_height)
        caption_title.text=title;caption_hint.text=instruction
        caption.size=Vector2(width,title_height+hint_height+24)
    var extent:=caption.size*caption_scale
    var safe:=Rect2(Vector2(20,170),Vector2(maxf(1,view.x-40),maxf(1,view.y-210)))
    var at:=_screen(Vector2(profile.get("at",Vector2.ZERO)))
    var bounds:=_world_bounds(profile);bounds.position.x-=camera
    var center_x:=clampf(at.x-extent.x*.5,safe.position.x,maxf(safe.position.x,safe.end.x-extent.x))
    var center_y:=clampf(at.y-extent.y*.5,safe.position.y,maxf(safe.position.y,safe.end.y-extent.y))
    caption_candidates[0]=Vector2(center_x,bounds.position.y-extent.y-18)
    caption_candidates[1]=Vector2(center_x,bounds.end.y+18)
    caption_candidates[2]=Vector2(bounds.end.x+18,center_y)
    caption_candidates[3]=Vector2(bounds.position.x-extent.x-18,center_y)
    caption_candidates[4]=Vector2(center_x,safe.position.y)
    caption_candidates[5]=Vector2(safe.position.x,300)
    caption_candidates[6]=Vector2(maxf(safe.position.x,safe.end.x-extent.x),300)
    caption_candidates[7]=Vector2(safe.position.x,470)
    caption_candidates[8]=Vector2(maxf(safe.position.x,safe.end.x-extent.x),470)
    for candidate in caption_candidates:
        var panel_bounds:=Rect2(candidate,extent)
        if safe.encloses(panel_bounds) and _caption_clear(panel_bounds):
            caption.position=candidate;caption.show();return

func _caption_clear(bounds: Rect2) -> bool:
    var hero:=Rect2(player-Vector2(camera,0)-Vector2(205,112),Vector2(375,224))
    if bounds.intersects(hero):return false
    for slot in range(visible_count):
        if bounds.intersects(station_bounds[slot].grow(12)):return false
    if host.has_method("_stage_index") and int(host.call("_stage_index"))==7:
        for key in ["king","queen_teacher"]:
            var royal: Node2D=host.get(key)
            if not is_instance_valid(royal) or not royal.visible:continue
            var half:=Vector2(royal.get("size"))*.5+Vector2(20,20)
            if bounds.intersects(Rect2(royal.position-half,half*2)):return false
    var hud: Node=host.get("premium_hud")
    if not is_instance_valid(hud):return true
    var info: Dictionary=hud.get("info")
    if hud.has_method("to_game"):
        for key in ["message_back","banner","boss_card","score_card","health_card","menu_button","chapter"]:
            var overlay: Control=hud.get(key)
            if is_instance_valid(overlay) and overlay.visible:
                var overlay_bounds: Rect2=hud.call("to_game",Rect2(overlay.position,overlay.size))
                if bounds.intersects(overlay_bounds.grow(6)):return false
    if bool(info.get("touch",false)) and hud.has_method("to_game"):
        if bounds.intersects(hud.call("to_game",hud.call("pad_rect"))):return false
        for action in ["boost","jump","bubble"]:
            if bounds.intersects(hud.call("to_game",hud.call("action_rect",action))):return false
    var charge: Control=hud.get("charge_card")
    if is_instance_valid(charge) and charge.visible:
        var charge_bounds: Rect2=hud.call("to_game",Rect2(charge.position,charge.size))
        if bounds.intersects(charge_bounds):return false
    return true

func _draw() -> void:
    _begin_details()
    if not active or not prepared:return
    var started:=Time.get_ticks_usec()
    batch_used=0;frame_draws=0;pen=Transform2D.IDENTITY
    for slot in range(visible_count):
        var record: Dictionary=records[selected[slot]]
        var profile: Dictionary=record.get("profile",{})
        var kind:=String(profile.get("kind","dream"))
        var at:=_screen(Vector2(profile.get("at",Vector2.ZERO)))
        chapter=clampi(int(profile.get("chapter",0)),0,7)
        var tint: Color=profile.get("color",PALETTES[chapter][0])
        var still:=_record_quiet(record)
        var t:=0.0 if reduced or still else clock
        var progress:=clampf(float(record.get("progress",0))/3.0,0,1)
        var response:=0.0 if still else 1.0-smoothstep(70,350,player.distance_to(Vector2(profile.get("at",Vector2.ZERO))))
        match kind:
            "dream":_dream(at,tint,t,progress,response,still,record)
            "tea":_tea(at,tint,t,progress,response,still,record)
            "village":_village(at,tint,t,progress,response,still,record)
            "mirror":_mirror(at,tint,t,progress,response,still,record)
            "post":_post(at,tint,t,progress,response,still,record)
    pen=Transform2D.IDENTITY;_flush_batch()
    last_build_us=Time.get_ticks_usec()-started

func _sprite(kind: String, role: String, at: Vector2, height: float, angle:=0.0, alpha:=1.0, flip:=false) -> bool:
    if replacement_painter.is_valid() and replacement_painter.call(kind,role,at,height,angle,alpha,flip):return true
    var texture: Texture2D=textures.get(kind+"/"+role)
    if texture==null or height<=0 or alpha<=0:return false
    var size:=texture.get_size()*(height/texture.get_height())
    var rect:=Rect2(-size*.5,size)
    if flip:rect.position.x+=size.x;rect.size.x=-size.x
    draw_set_transform(at,angle)
    if role in ["whale","jelly","butler","postman"]:
        _detail_paint(texture,rect,clock,reduced or quiet,role,at,angle,alpha)
    else:draw_texture_rect(texture,rect,false,Color(1,1,1,alpha))
    draw_set_transform(Vector2.ZERO)
    frame_draws+=1
    return true

func _fit_size(kind: String, role: String, box: Vector2) -> Vector2:
    var texture: Texture2D=textures.get(kind+"/"+role)
    if texture==null:return box
    var raw:=texture.get_size()
    return raw*minf(box.x/maxf(1,raw.x),box.y/maxf(1,raw.y))

func _sprite_fit(kind: String, role: String, at: Vector2, box: Vector2, angle:=0.0, alpha:=1.0, flip:=false) -> bool:
    return _sprite(kind,role,at,_fit_size(kind,role,box).y,angle,alpha,flip)

func _sprite_foot(kind: String, role: String, foot: Vector2, box: Vector2, angle:=0.0, alpha:=1.0, flip:=false) -> bool:
    var size:=_fit_size(kind,role,box)
    return _sprite(kind,role,foot-Vector2(0,size.y*.5),size.y,angle,alpha,flip)

func _source_to_foot(kind: String, role: String, source: Vector2, foot: Vector2, box: Vector2) -> Vector2:
    var size:=_fit_size(kind,role,box)
    var region: Rect2=texture_regions.get(kind+"/"+role,Rect2(0,0,1254,1254))
    return foot-Vector2(size.x*.5,size.y)+(source-region.position)*size/region.size.max(Vector2.ONE)

func _petal(at: Vector2, tint: Color, radius: float, angle: float) -> void:
    for i in range(4):
        var turn:=angle+float(i)*PI*.5
        _oval(at+Vector2(cos(turn),sin(turn))*radius*.48,Vector2(radius*.50,radius*.25),Color(tint,.60),turn)
    _circle(at,radius*.21,Color("ffedbf"))

func _tiny_fish(at: Vector2, tint: Color, angle: float, size: float) -> void:
    _oval(at,Vector2(7,3)*size,Color(tint,.72),angle)
    _set_pen(at,angle,Vector2.ONE*size)
    var a:=pen*Vector2(-6,0);var b:=pen*Vector2(-10,-3.5);var c:=pen*Vector2(-10,3.5)
    _triangle(a,b,c,Color(tint,.58),Color(tint,.1),Color(tint,.42))
    _set_pen(Vector2.ZERO)
    _circle(at+Vector2(3,-.7).rotated(angle)*size,.7*size,Color(.13,.26,.29,.7))

func _dream(at: Vector2, tint: Color, t: float, progress: float, near: float, still: bool, record: Dictionary) -> void:
    var profile: Dictionary=record.get("profile",{})
    var variant:=String(profile.get("variant","whale"))
    if variant not in ["whale","carousel","rain"]:variant="whale"
    var dreaming:=String(record.get("state","dormant")) in ["playing","complete"]
    var center:=at+Vector2(0,sin(t*.55)*2)
    var radius:=127.0+sin(t*.42)*1.2
    # The miniature is a genuine painted cutout. Broad transparent colour is
    # only the bubble's refracting film, never a replacement for the painting.
    _oval(center,Vector2.ONE*radius,Color(.69,.79,.98,.045))
    _sprite_fit("dream",variant,center+Vector2(0,9),Vector2(211,194),sin(t*.27)*.013 if dreaming else 0.0)
    _arc(center,radius,0,TAU,32,Color(.84,.86,1,.32),3.1,true)
    _arc(center+Vector2(1,-1),radius-2,PI*1.04,PI*1.77,18,Color(.99,.74,.91,.64),1.7,true)
    _arc(center,radius+1,PI*.02,PI*.69,16,Color(.73,.95,.96,.58),2,true)
    _arc(center,radius-3,PI*.70,PI*.96,10,Color(1,.91,.64,.66),2.6,true)
    _arc(center+Vector2(-5,-7),radius-12,PI*1.11,PI*1.39,12,Color(.99,1,1,.35),4.2,true)
    _arc(center+Vector2(-7,-8),radius-18,PI*1.12,PI*1.26,8,Color(1,1,1,.64),2.6,true)
    _oval(center+Vector2(56,76),Vector2(15,4),Color(.96,.78,.96,.19),-.45)
    if still or not dreaming:return
    var c: Array=PALETTES[chapter]
    for i in range(2):
        var theta:=t*.24+float(i)*PI+.5
        var fish:=center+Vector2(cos(theta)*77,sin(theta)*36-14)
        _tiny_fish(fish,c[(i+1)%3],-sin(theta)*.19,.8)
    if variant=="rain":
        for i in range(5):
            var falling:=fposmod(t*.27+float(i)*.194,1.0)
            var drop:=center+Vector2(-62+i*30,45-falling*94)
            _line(drop,drop+Vector2(-2,7),Color(c[i%3],sin(falling*PI)*.56),1.6,true)
    elif variant=="carousel":
        for i in range(3):
            var theta:=t*.6+i*TAU/3
            _petal(center+Vector2(cos(theta)*69,48+sin(theta)*11),c[i%3],4.7,theta)
    else:
        for i in range(3):
            var lift:=fposmod(t*.11+i*.29,1.0)
            var mote:=center+Vector2(61+sin(t*.7+i)*6,43-lift*97)
            _arc(mote,2.4+i*.55,0,TAU,12,Color(.90,.96,1,sin(lift*PI)*.6),1,true)
    _glow(center+Vector2(-87,-85),tint,4.2,.32+near*.14)
    for i in range(3):
        var theta:=-1.1+i*1.9+t*.08
        _spark(center+Vector2(cos(theta),sin(theta))*(radius+9),c[i%3],2.4,.42)
    if bool(record.get("completed",false)) and float(record.get("glow_time",0))>0:
        _petal(center+Vector2(0,-radius-10),Color("f8dfac"),7.5,t*.12)

func _cup(at: Vector2, tint: Color, lift: float, t: float, scale:=1.0) -> void:
    var center:=at-Vector2(0,lift)
    _oval(at+Vector2(0,5),Vector2(15,3),Color(.86,.85,1,.55))
    _oval(center,Vector2(9.5,7.5)*scale,Color(.98,.93,.89,.96))
    _oval(center-Vector2(0,3.5)*scale,Vector2(9.5,3.7)*scale,Color(tint,.88))
    _arc(center+Vector2(9,-.5)*scale,4.7*scale,-PI*.62,PI*.60,10,Color(.97,.87,.73,.94),1.9,true)
    _arc(center,9.5*scale,0,PI,12,Color(.79,.65,.84,.65),1.0,true)
    for i in range(16):
        var f:=float(i)/15
        wave[i]=center+Vector2(sin(f*5+t*.8)*2.3,-9-f*20)*scale
    _polyline(wave,Color(.97,.94,1,.20),1.0,true)

func _tea(at: Vector2, tint: Color, t: float, progress: float, near: float, still: bool, record: Dictionary) -> void:
    var phase:=clampi(int(record.get("phase",0)),0,5)
    var profile: Dictionary=record.get("profile",{})
    var foot:=_screen(Vector2(profile.get("prop_at",Vector2(profile.get("at",Vector2.ZERO))+Vector2(0,120))))
    _sprite_fit("tea","butler",at+Vector2(-147,23),Vector2(140,166),sin(t*.63)*.026)
    _sprite_fit("tea","jelly",at+Vector2(-48,-48+sin(t*.68+.6)*2),Vector2(72,82),sin(t*.47)*.025)
    _sprite_fit("tea","jelly",at+Vector2(73,-43+sin(t*.71+1.1)*2),Vector2(69,79),sin(t*.49+.8)*.028)
    _sprite_fit("tea","jelly",at+Vector2(144,-17+sin(t*.76)*3),Vector2(96,112),sin(t*.55)*.035)
    _sprite_foot("tea","table",foot,Vector2(242,220))
    var table_size:=_fit_size("tea","table",Vector2(242,220))
    var surface:=foot-Vector2(0,table_size.y*.515)
    for i in range(3):
        var serving:=not still and phase>=1 and phase<=4 and i==mini(2,maxi(0,phase-1))
        var lift:=4.5+sin(t*1.2)*1.8 if serving else 0.0
        var growing:=1.0
        if i==1 and not still:
            if phase==3:growing=1.72 if reduced else lerpf(1,1.90,smoothstep(0,1,float(record.get("timer",0))))
            elif phase==4:growing=1.50
        _cup(surface+Vector2(-43+i*43,0),PALETTES[chapter][i%3],lift,0 if still else t+i,growing)
    # A fine sugar ribbon and individual pearls animate independently of the
    # unchanged painting; every serving pose is readable without a new control.
    if still:return
    for i in range(3):
        var f:=fposmod(t*.18+i*.3,1.0)
        var sugar:=at+Vector2(-97+f*57,1-sin(f*PI)*21)
        _circle(sugar,1.8,Color(1,.94,.81,sin(f*PI)*.70))
    if phase in [2,3]:
        var pour_start:=surface+Vector2(-18,-20)
        var pour_end:=surface+Vector2(8,-3)
        _line(pour_start,pour_end,Color(.97,.83,.67,.59),1.5,true)
    if phase==4:
        var f:=.65 if reduced else smoothstep(0,1.15,float(record.get("timer",0)))
        var burp:=surface+Vector2(sin(t*.57)*5,-34-f*31)
        var radius:=lerpf(32,57,f)
        _oval(burp,Vector2.ONE*radius,Color(.78,.82,1,.055))
        _arc(burp,radius,0,TAU,32,Color(.86,.84,1,.42),2.0,true)
        _arc(burp,radius-1,PI*1.08,PI*1.77,17,Color(1,.77,.91,.67),1.6,true)
        _arc(burp,radius+1,PI*.05,PI*.64,15,Color(.75,.94,.97,.58),1.5,true)
        _arc(burp+Vector2(-2,-3),radius-8,PI*1.10,PI*1.35,10,Color(1,1,1,.63),2.6,true)
    _glow(at+Vector2(144,-42),tint,3.1,.29+near*.14)
    _spark(at+Vector2(-160,-67),Color("f9e5b8"),2.1,.40)
    if progress>0:_petal(surface+Vector2(0,-49),tint,4.5,t*.19)

func _cloth(at: Vector2, tint: Color, angle: float, small:=false, alpha:=1.0) -> void:
    if alpha<=0:return
    var scale:=.74 if small else 1.0
    _set_pen(at,angle,Vector2.ONE*scale)
    var a:=pen*Vector2(-7,0);var b:=pen*Vector2(7,0)
    var c:=pen*Vector2(6,15);var d:=pen*Vector2(-5,13)
    _triangle(a,b,c,Color(tint,.83*alpha),Color(tint,.68*alpha),Color(tint,.90*alpha))
    _triangle(a,c,d,Color(tint,.83*alpha),Color(tint,.90*alpha),Color(tint,.56*alpha))
    _line(Vector2(-4,3),Vector2(-3,11),Color(1,1,1,.35*alpha),1,true)
    _set_pen(Vector2.ZERO)

func _village(at: Vector2, tint: Color, t: float, progress: float, near: float, still: bool, record: Dictionary) -> void:
    var profile: Dictionary=record.get("profile",{})
    var foot:=Vector2(profile.get("prop_at",profile.get("at",Vector2.ZERO)))
    var phase:=clampi(int(record.get("phase",0)),0,5)
    var laundry_alpha:=0.0 if phase==4 else 1.0
    if phase==5 and not reduced and not still:laundry_alpha=smoothstep(0,1.5,fposmod(float(record.get("timer",0)),3.0))
    for i in range(3):
        var x:=foot.x+(i-1)*133
        var screen_foot:=_screen(Vector2(x,Terrain.ground_y(x)))
        house_feet[i]=screen_foot
        house_heights[i]=_fit_size("village",HOUSE_ROLES[i],Vector2(130,HOUSE_HEIGHTS[i])).y
        _oval(screen_foot+Vector2(0,1),Vector2(45,6),Color(.10,.25,.29,.12))
        _sprite_foot("village",HOUSE_ROLES[i],screen_foot,Vector2(130,HOUSE_HEIGHTS[i]))
    _painting(garden_frames[1],house_feet[0]+Vector2(54,1),33,Color(.96,.98,.98,.88))
    _painting(garden_frames[0],house_feet[2]+Vector2(-51,2),29,Color(.98,.94,.99,.86))
    var left:=house_feet[0]+Vector2(36,-65)
    var right:=house_feet[2]+Vector2(-32,-58)
    for i in range(16):
        var f:=float(i)/15
        rope[i]=left.lerp(right,f)+Vector2(0,sin(f*PI)*9)
    _polyline(rope,Color(.91,.84,.65,.60),1.1,true)
    for i in range(3):
        var f:=.26+i*.24
        var point:=left.lerp(right,f)+Vector2(0,sin(f*PI)*9)
        _cloth(point,PALETTES[chapter][i],sin(t*.72+i)*.075,false,laundry_alpha)
        _circle(point+Vector2(-4,0),1.1,Color("ead9ad"))
        _circle(point+Vector2(4,0),1.1,Color("ead9ad"))
    var crab_x:=foot.x-48+sin(t*.34)*39
    var crab:=_screen(Vector2(crab_x,Terrain.ground_y(crab_x)-16))
    _sprite("village","crab",crab,34,sin(t*.68)*.025,1,cos(t*.34)<0)
    _cloth(crab+Vector2(13,-11),Color("efd1e1"),-.24,true,laundry_alpha)
    if still:return
    for i in range(3):
        var window:=_source_to_foot("village",HOUSE_ROLES[i],HOUSE_WINDOWS[i],house_feet[i],Vector2(130,HOUSE_HEIGHTS[i]))
        _glow(window,Color("f4dda8"),2.6,.32+near*.08)
        var parting:=4.0 if phase==0 else 8.0
        if phase!=4:
            for side in [-1,1]:_oval(window+Vector2(side*parting,0),Vector2(2.4,6.0),Color(tint,.40),side*.11+sin(t*.7+i)*.035)
        if phase in [0,1]:
            var peek:=window+Vector2(3,4+sin(t*.55+i)*.55)
            _oval(peek,Vector2(4.6,2.6),Color(.16,.23,.28,.18))
            for side in [-1,1]:
                var eye:=peek+Vector2(side*1.8,0)
                _oval(eye,Vector2(1.5,1.1),Color(.99,.95,.83,.84))
                _circle(eye+Vector2(.18,0),.67,Color(.24,.19,.24,.88))
                _circle(eye+Vector2(-.10,-.30),.23,Color(1,1,1,.82))
        _petal(house_feet[i]+Vector2(-31+i*9,-8),tint,3.2,.4+i)
    if phase==2:
        var can:=crab+Vector2(18,-7)
        _oval(can,Vector2(6,4.2),Color(.78,.76,.91,.82),-.2)
        _line(can+Vector2(4,-2),can+Vector2(12,-7),Color(.94,.85,.95,.86),2,true)
        _arc(can+Vector2(-4,-3),5,PI*.52,PI*1.55,10,Color(.93,.85,.95,.7),1.2,true)
        for i in range(3):
            var drop:=fposmod(t*.6+i*.31,1.0)
            var water:=can+Vector2(12+drop*9,-7+drop*22)
            _line(water,water+Vector2(1,3),Color(.75,.88,1,sin(drop*PI)*.65),1,true)
    if progress>0:_spark(house_feet[1]+Vector2(29,-135),Color("fae4af"),2,.47)

func _mirror(at: Vector2, tint: Color, t: float, progress: float, near: float, still: bool, record: Dictionary) -> void:
    var radius:=102.0
    var mirror: Dictionary=view_state.get("mirror",{})
    var profile: Dictionary=record.get("profile",{})
    var anchor:=Vector2(profile.get("at",Vector2.ZERO))
    var same_game:=bool(mirror.get("active",false)) and String(mirror.get("kind",""))=="bubble_game" and Vector2(mirror.get("anchor",anchor)).distance_squared_to(anchor)<256
    var phase:=clampi(int(mirror.get("phase",0)) if same_game else int(record.get("phase",0)),0,5)
    var expression: int=[0,1,0,2,1,1][phase]
    var face: String=["sarah","sarah_joy","sarah_dream"][posmod(expression,3)]
    var baby_present:=String(mirror.get("partner","fish"))=="avina"
    _oval(at,Vector2(radius,radius*1.08),Color(.70,.79,.96,.055))
    _sprite("mirror",face,at+Vector2(-37,3+sin(t*.72)*1.7),79,sin(t*.47)*.018)
    if baby_present:
        _sprite("mirror","avina",at+Vector2(43,4+sin(t*.72-.5)*1.7),87,-sin(t*.47)*.018)
    else:
        _tiny_fish(at+Vector2(43,6+sin(t*.72)*2),Color("f3cea3"),PI,3.0)
        _petal(at+Vector2(60,-19),tint,6.0,-.2)
    _arc(at,radius,0,TAU,32,Color(.87,.81,1,.50),2.4,true)
    _arc(at,radius-3,PI*1.08,PI*1.72,18,Color(.99,.84,.94,.68),2.1,true)
    _arc(at+Vector2(-5,-4),radius-12,PI*1.08,PI*1.32,10,Color(1,1,1,.58),3.2,true)
    _arc(at,radius+3,PI*.13,PI*.61,14,Color(.72,.92,.97,.48),1.5,true)
    for i in range(3):_petal(at+Vector2(-46+i*46,radius-3+absf(i-1)*-8),PALETTES[chapter][i],6.3,.3+i)
    if still:return
    _glow(at+Vector2(0,-1),tint,3.4,.20+near*.18)
    _spark(at+Vector2(-80,-75),Color("f8e6b9"),2.2,.44)
    _spark(at+Vector2(80,64),Color("e5d5fa"),1.8,.40)
    var owner:=String(mirror.get("bubble_owner","")) if same_game else ""
    if not owner.is_empty():
        var echo_at:=at+Vector2(-42 if owner=="sarah" else 43,-47)
        if owner=="passing_fish":echo_at=at+Vector2(sin(t*.8)*25,-73)
        var f:=float(mirror.get("phase_progress",0)) if not reduced else .5
        _arc(echo_at-Vector2(0,f*12),9+f*3,0,TAU,20,Color(.92,.85,1,.5),1.3,true)
    if phase==4:
        _tiny_fish(at+Vector2(sin(t*.8)*25,-64),Color("f6d3a5"),0,1.2)
    if progress>0:
        var sway:=sin(t*.73)*3
        _petal(at+Vector2(sway,-64),Color("f4d2e8"),5.2,t*.10)

func _letter(at: Vector2, tint: Color, scale: float, angle: float, alpha: float) -> void:
    _set_pen(at,angle,Vector2.ONE*scale)
    var a:=pen*Vector2(-11,-7);var b:=pen*Vector2(11,-7)
    var c:=pen*Vector2(11,7);var d:=pen*Vector2(-11,7)
    var paper:=Color(.98,.93,.86,alpha)
    _triangle(a,b,c,paper,paper,paper);_triangle(a,c,d,paper,paper,paper)
    _line(Vector2(-11,-7),Vector2(0,1),Color(tint,alpha*.76),.9,true)
    _line(Vector2(0,1),Vector2(11,-7),Color(tint,alpha*.76),.9,true)
    _set_pen(Vector2.ZERO)
    _petal(at+Vector2(0,1).rotated(angle)*scale,tint,2.2*scale,angle)

func _post(at: Vector2, tint: Color, t: float, progress: float, near: float, still: bool, record: Dictionary) -> void:
    var profile: Dictionary=record.get("profile",{})
    var foot:=_screen(Vector2(profile.get("prop_at",profile.get("at",Vector2.ZERO))))
    var phase:=clampi(int(record.get("phase",0)),0,5)
    # A contented little postal round: a tiny grounded stroll, a breathing mantle
    # and a courteous lean toward Sarah. The original painting stays untouched.
    var stroll:=0.0 if still or reduced else sin(t*.25)*7.0
    var nori_foot:=foot+Vector2(stroll,0)
    nori_foot.y=Terrain.ground_y(foot.x+camera+stroll)
    var facing_sarah:=player.x<foot.x+camera
    var bow:=0.0 if still or reduced else sin(t*.65)*.016+near*sin(t*1.1)*.012
    _oval(nori_foot+Vector2(0,-1),Vector2(54,7),Color(.1,.25,.29,.12))
    _sprite_foot("post","postman",nori_foot,Vector2(178,154+sin(t*.75)*1.3),bow,1,facing_sarah)
    _letter(foot+Vector2(67,-39),tint,.82,.16,1)
    _letter(foot+Vector2(61,-50),Color("b5d4ee"),.75,-.08,1)
    if still:return
    for i in range(3):
        var f:=fposmod(t*.16+float(i)*.32,1.0)
        var alpha:=sin(f*PI)*.85
        var letter_at:=foot+Vector2(47+f*34,-54-f*84)
        _letter(letter_at,PALETTES[chapter][i],.62,sin(t*.55+i)*.12,alpha)
    var invitation:=at+Vector2(-13,-14)
    if phase>=1:
        _letter(invitation,tint,1.20,sin(t*.45)*.025,.92)
        _glow(invitation+Vector2(0,1),Color("f9deb0"),2.8,.33+near*.15)
    if progress>0:_petal(foot+Vector2(-51,-24),tint,5.2,.3)


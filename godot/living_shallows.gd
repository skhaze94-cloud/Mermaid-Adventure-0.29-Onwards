extends "res://godot/whimsy_garden.gd"
## Opening Highland sanctuary. Fixed authored gardens and one friendly puppet;
## purely decorative, with no saved state, collision, input or score ownership.
const Kit=preload("res://godot/ui_kit.gd")
const Puppet=preload("res://godot/nori_puppet.gd")
const LIGHT=preload("res://godot/shaders/shallows_light.gdshader")
const NORI_X:=1740.0
const PATCHES:=[570.0,980.0,1410.0,1800.0,2480.0,2680.0]
const PETALS:=[Color("e8b7d7"),Color("8de0d2"),Color("d1b7ee"),Color("f4dca3")]
var host: Node2D
var nori: MeshInstance2D
var light: ColorRect
var light_paint: ShaderMaterial
var label_panel: Panel
var label_text: Label
var openings:=PackedFloat32Array()
var pollen:=PackedFloat32Array()
var flower_path:=PackedVector2Array()
var speech_clock:=0.0
var line_key:=""
var cycle:=0.0
var region_alpha:=0.0
var nori_foot:=Vector2.ZERO
var local_attention:=0.0
var last_retry:=-1
var visible_patches:=0
var letter_on_ground:=false
var interactive_post:=false
var texture_loads:=0
var wave_clock:=0.0
var petal_ring:=PackedVector2Array()
var authored_beds: Array[Texture2D]=[]

func _ready() -> void:
    super._ready();z_index=2
    openings.resize(PATCHES.size());pollen.resize(PATCHES.size());flower_path.resize(9)
    for i in range(12):petal_ring.append(Vector2(cos(i*TAU/12),sin(i*TAU/12)))
    nori=Puppet.new();nori.name="NoriLivingPainting";add_child(nori)
    light=ColorRect.new();light.name="SunlitShallows";light.color=Color.WHITE
    light.mouse_filter=Control.MOUSE_FILTER_IGNORE;light.z_index=-2
    light_paint=ShaderMaterial.new();light_paint.shader=LIGHT;light.material=light_paint;add_child(light)
    label_panel=Panel.new();label_panel.name="NoriTinyHello";label_panel.z_index=4
    label_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
    label_panel.add_theme_stylebox_override("panel",Kit.panel(Color(.025,.12,.18,.94),Color("d9c7a0"),15))
    label_text=Kit.label("",19,Color("f6e8cc"));label_text.add_theme_font_override("font",Kit.BODY)
    label_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    label_panel.add_child(label_text);add_child(label_panel);label_panel.hide()
    for id in ["fern","teapot","fan","orchid","bell","star"]:authored_beds.append(load("res://godot/assets/little-moments/"+id+".png"))
    texture_loads=7
    hide()

func bind(level: Node2D) -> void:
    host=level;last_retry=host.retry_serial;sync()

func advance(dt: float) -> void:
    if not is_instance_valid(host) or not is_finite(dt) or dt<=0:return
    if host.retry_serial!=last_retry:
        last_retry=host.retry_serial;clock=0;cycle=0;line_key="";speech_clock=0
        openings.fill(0);pollen.fill(0)
    if not active or host.state!="playing" or host.get_tree().paused:return
    var allowed:=not reduced and not combat
    if allowed:clock+=minf(dt,.1)
    cycle=fposmod(clock,28.0)
    speech_clock=maxf(0,speech_clock-dt)
    var smoothing:=1-exp(-dt*3.2)
    for i in range(PATCHES.size()):
        var at:=Vector2(PATCHES[i],Terrain.ground_y(PATCHES[i])-54)
        var response:=1-smoothstep(100,355,player.distance_to(at))
        if reduced or combat:response=0.0
        openings[i]=lerpf(openings[i],response,smoothing)
        if allowed:pollen[i]=fposmod(pollen[i]+dt*(.19+response*.12),1.0)
    _update_speech()
    queue_redraw()

func sync() -> void:
    if not is_instance_valid(host):return
    if reduced!=host.reduced_fx:speech_clock=0.0;line_key=""
    camera=host.camera;player=host.player;reduced=host.reduced_fx;economy=not host.high_depth_quality
    combat=host._whimsy_combat_active();waterline=host._water_line()
    var flow=host.get_node_or_null("/root/SceneFlow")
    active=host._stage_index()==0 and not host.fallen and host.waterfall_phase=="" and host.state in ["playing","paused"] and not flow.busy
    region_alpha=1-smoothstep(2600,3100,camera)
    visible=active and region_alpha>0
    label_panel.hide()
    if not visible:return
    var view:=get_viewport_rect().size
    light.size=view
    light_paint.set_shader_parameter("story_time",clock)
    light_paint.set_shader_parameter("camera_x",camera)
    light_paint.set_shader_parameter("view_size",view)
    light_paint.set_shader_parameter("surface_y",waterline)
    light_paint.set_shader_parameter("region_alpha",region_alpha*(.55 if combat else 1.0))
    light_paint.set_shader_parameter("detail",.35 if economy else 1.0)
    var offset:=postal_offset(cycle) if not reduced else 0.0
    nori_foot=Vector2(NORI_X+offset,Terrain.ground_y(NORI_X+offset))
    local_attention=1-smoothstep(110,360,player.distance_to(nori_foot-Vector2(0,125)))
    var near_view:=Rect2(Vector2(-180,-80),view+Vector2(360,200)).has_point(nori_foot-Vector2(camera,0))
    nori.visible=near_view
    nori.pose(nori_foot-Vector2(camera,0),193.0,clock,reduced or combat,player.x<NORI_X,local_attention)
    if nori.visible:nori.rotation=0.0 if reduced or combat else sin(clock*1.4)*.004
    _sync_speech(view)
    queue_redraw()

static func postal_offset(phase: float) -> float:
    if phase<7:return lerpf(-22,30,smoothstep(0,7,phase))
    if phase<10:return 30.0
    if phase<14:return lerpf(30,-8,smoothstep(10,14,phase))
    if phase<17:return -8.0
    if phase<22:return lerpf(-8,10,smoothstep(17,22,phase))
    return 10.0

func _update_speech() -> void:
    if interactive_post and is_instance_valid(host.little_moments) and host.little_moments.letter_phase in [1,2,3]:return
    if speech_clock>0 or combat or local_attention<.35 or host.player_velocity.length()>120:return
    if host.message_time>0 or host.opal.charge.held or host.living_reef.reactions.focus_left>0:return
    var key:="hello" if reduced else "drop" if cycle>=7 and cycle<11 else "found" if cycle>=14 and cycle<18 else "hello" if cycle>=22 else "round"
    if interactive_post and key in ["drop","found"]:key="hello"
    if key==line_key:return
    line_key=key;speech_clock=5.5
    label_text.text={"drop":"Nori: Oh! One of my letters has gone for a little swim.","found":"Nori: Found it! Special delivery requires special determination.","hello":"Nori: One tiny hello, sealed with a very big heart.","round":"Nori: Good morning, Sarah! I'm taking the scenic postal route."}[key]

func _sync_speech(view: Vector2) -> void:
    if speech_clock<=0 or combat or host.state!="playing" or host.get_tree().paused or local_attention<.3:return
    if host.message_time>0 or host.opal.charge.held:return
    var physical:=float(host.get_window().size.y)/maxf(1,view.y)
    var magnify:=clampf(1/maxf(.1,physical),1,2)
    var width:=minf(390,(view.x-64)/magnify)
    var height:=ceilf(Kit.BODY.get_multiline_string_size(label_text.text,HORIZONTAL_ALIGNMENT_CENTER,width-32,19).y)+30
    label_panel.scale=Vector2.ONE*magnify;label_panel.size=Vector2(width,height)
    label_text.position=Vector2(16,13);label_text.size=Vector2(width-32,height-26)
    var extent:=label_panel.size*magnify
    label_panel.position=Vector2(clampf((NORI_X-camera)-extent.x*.5,24,maxf(24,view.x-extent.x-24)),305)
    var hero:=Rect2(player-Vector2(camera,0)-Vector2(190,110),Vector2(360,220))
    if Rect2(label_panel.position,extent).intersects(hero):return
    var hud=host.premium_hud
    for key in ["score_card","health_card","menu_button","message_back","boss_card","banner","chapter"]:
        var overlay: Control=hud.get(key)
        if is_instance_valid(overlay) and overlay.visible and Rect2(label_panel.position,extent).intersects(hud.to_game(Rect2(overlay.position,overlay.size)).grow(6)):return
    label_panel.show()

func _draw() -> void:
    if not visible or not prepared:return
    batch_used=0;pen=Transform2D.IDENTITY;visible_patches=0
    for i in range(PATCHES.size()):
        var x: float=PATCHES[i]
        if x-camera < -230 or x-camera>get_viewport_rect().size.x+230:continue
        if visible_patches>=4:break
        visible_patches+=1
        _garden_bed(Vector2(x-camera,Terrain.ground_y(x)),i)
    _postal_details()
    _depth_motes()
    pen=Transform2D.IDENTITY;_flush_batch()

func _garden_bed(foot: Vector2,id: int) -> void:
    var heights: Array=[220.0,112.0,170.0,210.0,132.0,145.0]
    var open: float=openings[id]
    var t:=0.0 if reduced or combat else clock
    _oval(foot+Vector2(0,2),Vector2(58,7),Color(.035,.18,.19,.16))
    # Six authored silhouettes, each placed exactly once in this reach.
    _painting(authored_beds[id],foot+Vector2(0,3),heights[id]*(1+open*.025),Color.WHITE)
    if not reduced and not combat and open>.2:
        var phase:=fposmod(pollen[id],1.0)
        _arc(foot+Vector2(18*sin(t*.5+id),-heights[id]*.6-phase*48),2.2,0,TAU,12,Color(.93,.85,1,sin(phase*PI)*open*.5),1,true)

func _anemone(at: Vector2,tint: Color,radius: float,open: float,t: float) -> void:
    for petal in range(7):
        var angle:=petal*TAU/7+sin(t*.5)*.05
        var spread:=radius*(.28+open*.60)
        var tip:=at+Vector2(cos(angle)*spread,sin(angle)*spread*.55)
        _oval(tip,Vector2(radius*.55,2.8+open*1.2),Color(tint,.90),angle)
    _circle(at,2.5+open,Color("ffebba"))
    _glow(at,Color("fff0c7"),1.7,.14+open*.18)

func _oval(at: Vector2,size: Vector2,tint: Color,angle:=0.0) -> void:
    # Small botanical details use a smooth twelve-sided fan, keeping even a
    # wide phone viewport inside the existing fixed decorative surface.
    for i in range(petal_ring.size()):
        var a:=at+(petal_ring[i]*size).rotated(angle)
        var b:=at+(petal_ring[(i+1)%petal_ring.size()]*size).rotated(angle)
        _triangle(at,a,b,tint,tint,tint)

func _circle(at: Vector2,radius: float,colour: Color) -> void:
    _oval(at,Vector2.ONE*radius,colour)

func _glow(at: Vector2,tint: Color,radius: float,strength:=1.0) -> void:
    for i in range(petal_ring.size()):
        var a:=at+petal_ring[i]*radius*2.2
        var b:=at+petal_ring[(i+1)%petal_ring.size()]*radius*2.2
        _triangle(at,a,b,Color(tint,strength*.35),Color(tint,0),Color(tint,0))

func _shrimp(at: Vector2,tint: Color,open: float,t: float) -> void:
    _oval(at,Vector2(6.5,3.5),Color(tint,.86),-.15)
    for i in range(3):_line(at+Vector2(-2+i*3,2),at+Vector2(-4+i*3,5+open),Color(tint,.8),.8,true)
    _circle(at+Vector2(5,-2),1.2,Color("253f48"));_circle(at+Vector2(5.3,-2.3),.4,Color("fff3dc"))
    _line(at+Vector2(4,-3),at+Vector2(10,-8-sin(t*.9)*open),Color(tint,.75),.8,true)
    _line(at+Vector2(3,-3),at+Vector2(7,-10),Color(tint,.75),.8,true)

func _envelope(at: Vector2,angle: float,size: float) -> void:
    _set_pen(at,angle,Vector2.ONE*size)
    var paper:=Color("f2e9d5")
    _triangle(pen*Vector2(-12,-8),pen*Vector2(12,-8),pen*Vector2(12,8),paper,paper,paper)
    _triangle(pen*Vector2(-12,-8),pen*Vector2(12,8),pen*Vector2(-12,8),paper,paper,paper)
    _line(Vector2(-12,-8),Vector2(0,1),Color("b7a3ae"),1,true)
    _line(Vector2(0,1),Vector2(12,-8),Color("b7a3ae"),1,true)
    _set_pen(Vector2.ZERO)
    _circle(at+Vector2(-1.5,0).rotated(angle)*size,2.1*size,Color("df8a9f"))
    _circle(at+Vector2(1.5,0).rotated(angle)*size,2.1*size,Color("df8a9f"))
    _triangle(at+Vector2(-3,1).rotated(angle)*size,at+Vector2(3,1).rotated(angle)*size,at+Vector2(0,4).rotated(angle)*size,Color("df8a9f"),Color("df8a9f"),Color("df8a9f"))

func _postal_details() -> void:
    var foot:=nori_foot-Vector2(camera,0)
    if foot.x < -220 or foot.x>get_viewport_rect().size.x+220:return
    _oval(foot+Vector2(0,2),Vector2(67,8),Color(.03,.15,.18,.18))
    letter_on_ground=not interactive_post and not reduced and cycle>=7 and cycle<17
    if letter_on_ground:
        var drop:=Vector2(NORI_X+3-camera,Terrain.ground_y(NORI_X+3)-12)
        var f:=smoothstep(7,10,cycle)
        var letter:=drop+Vector2(sin(clock*2)*5*(1-f),-62*(1-f))
        if cycle>15:letter=letter.lerp(foot+Vector2(28,-70),smoothstep(15,17,cycle))
        _envelope(letter,sin(clock)*.12,1.0)
    if not combat and local_attention>.3 and (reduced or cycle>=22):
        var lift:=0.0 if reduced else sin(clock*.9)*3
        _envelope(foot+Vector2(0,-231+lift),.08,1.05)
        _glow(foot+Vector2(0,-230+lift),Color("f2d5b0"),5,.22)
    # Three tiny pearl route markers belong to the planting, never to the HUD.
    for i in range(3):
        var at:=Vector2(NORI_X-120+i*18-camera,Terrain.ground_y(NORI_X-120+i*18)-3)
        _oval(at,Vector2(3.5,2.0),Color("c8ded0"))

func _depth_motes() -> void:
    if reduced or combat:return
    var view:=get_viewport_rect().size
    for i in range(10 if economy else 22):
        var depth:=.56+float(i%3)*.18
        var x:=fposmod(i*137.3-camera*depth+sin(clock*.2+i)*7,view.x+80)-40
        var y:=waterline+85+fposmod(i*83.7-clock*(1+i%3),maxf(1,view.y-waterline-155))
        _circle(Vector2(x,y),.8+(i%3)*.4,Color(.91,.95,.78,.14+float(i%3)*.035))

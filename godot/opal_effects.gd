extends Node2D
## Fixed visual pools. Combat supplies every hit-permission decision.
const Art=preload("res://godot/opal_art.gd")
const Roster=preload("res://godot/opal_roster.gd")
const Lagoon=preload("res://godot/lagoon_art.gd")
const PORTRAIT=preload("res://godot/shaders/opal_portrait.gdshader")
const SHELL=preload("res://godot/shaders/opal_shell.gdshader")
const FOE_CAP:=24
const IMPACT_CAP:=12
const FRIENDLY_STYLES:=["pearl","prism","aurora"]
const FRIENDLY_EXTENTS:=[48.0,60.0,76.0]
const SHELL_SIDES:=["rear","front"]
const MELEE:=["crab","eel","swordfish","shark","ribbon-ambusher","bubble-bandit-otter","carlo","flip","blackwater","nessie"]
const PACK_KINDS:=["maraca-snapper","ribbon-ambusher","bubble-bandit-otter","orchid-hermit","drumback-turtle","disco-cuttlefish"]
static var rear_ring: ArrayMesh
static var front_ring: ArrayMesh
static var glyphs: Array[ArrayMesh]=[]
var art=Art.new()
var rear: Node2D
var actors: Node2D
var front: Node2D
var friendly: Array[Sprite2D]=[]
var hostile: Array[Sprite2D]=[]
var wakes: Array[Sprite2D]=[]
var fields: Array[Sprite2D]=[]
var pack_sprites: Array[Sprite2D]=[]
var pack_materials: Dictionary={}
var shells: Array[Dictionary]=[]
var impacts: Array[Dictionary]=[]
var preview: Sprite2D
var shell_materials: Array[ShaderMaterial]=[]
var gentle:=false
var bound:=false
var previous_friendly:=0
var previous_hostile:=0
var previous_foes:=0
var active_impacts:=0
func _ready() -> void:
    process_mode=Node.PROCESS_MODE_PAUSABLE
    if not rear_ring:
        rear_ring=_ring(PI,TAU);front_ring=_ring(0,PI)
        for i in range(3):glyphs.append(_glyph(i))
    rear=Node2D.new();rear.z_index=0;add_child(rear)
    actors=Node2D.new();actors.z_index=0;add_child(actors)
    front=Node2D.new();front.z_index=3;add_child(front)
    for state in range(4):
        var material:=ShaderMaterial.new();material.shader=SHELL;material.set_shader_parameter("state",state)
        shell_materials.append(material)
    for i in range(8):friendly.append(_sprite(front))
    for i in range(32):hostile.append(_sprite(front))
    for i in range(FOE_CAP+2):
        wakes.append(_sprite(rear))
        var back:=MeshInstance2D.new();back.mesh=rear_ring;back.light_mask=0;rear.add_child(back)
        var face:=MeshInstance2D.new();face.mesh=front_ring;face.light_mask=0;front.add_child(face)
        var icon:=MeshInstance2D.new();front.add_child(icon)
        back.hide();face.hide();icon.hide();shells.append({"rear":back,"front":face,"icon":icon})
    for i in range(FOE_CAP):pack_sprites.append(_sprite(actors))
    for i in range(4):fields.append(_sprite(front))
    preview=_sprite(front)
    for i in range(IMPACT_CAP):
        var crown:=Node2D.new();front.add_child(crown);crown.hide()
        var back:=MeshInstance2D.new();back.mesh=rear_ring;back.light_mask=0;back.material=shell_materials[2];crown.add_child(back)
        var face:=MeshInstance2D.new();face.mesh=front_ring;face.light_mask=0;face.material=shell_materials[2];crown.add_child(face)
        var drops: Array[Sprite2D]=[]
        for j in range(8):drops.append(_sprite(crown))
        impacts.append({"node":crown,"life":0.0,"duration":0.28,"tier":1,"at":Vector2.ZERO,"rear":back,"front":face,"drops":drops})
func configure(chapter: String, friendly_atlas: Texture2D=null, enemy_atlas: Texture2D=null, boss_atlas: Texture2D=null) -> void:
    art.configure(chapter,friendly_atlas,enemy_atlas,boss_atlas)
    if chapter=="miguel":
        for name in Lagoon.frames:
            if name.get_slice("/",0) not in PACK_KINDS:continue
            var frame: AtlasTexture=Lagoon.frames[name]
            var material:=ShaderMaterial.new();material.shader=PORTRAIT
            var rect:=frame.region;var size:=frame.atlas.get_size()
            material.set_shader_parameter("cell_uv",Vector4(rect.position.x/size.x,rect.position.y/size.y,rect.size.x/size.x,rect.size.y/size.y))
            pack_materials[frame]=material
    bound=true
func _sprite(parent: Node2D) -> Sprite2D:
    var sprite:=Sprite2D.new();sprite.light_mask=0;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
    parent.add_child(sprite);sprite.hide();return sprite
func _paint(sprite: Sprite2D, style: String, at: Vector2, extent: float, angle:=0.0, opacity:=1.0) -> void:
    var key:=art.key_for(style)
    var texture: AtlasTexture=art.frames[key]
    if sprite.texture!=texture:sprite.texture=texture;sprite.material=art.materials[key]
    sprite.position=at;sprite.rotation=angle;sprite.scale=Vector2.ONE*extent/maxf(texture.get_width(),texture.get_height())
    sprite.modulate=Color(1,1,1,opacity);sprite.show()
func sync(level: Node2D) -> void:
    if not bound:return
    if gentle!=level.reduced_fx:
        gentle=level.reduced_fx;art.set_gentle(gentle)
        for material in shell_materials:material.set_shader_parameter("gentle",gentle)
    var offset:=Vector2(level.camera,0)
    var view: Vector2=level.get_viewport_rect().size
    var on_lake: bool=level.waterfall_phase==""
    var friendly_count: int=mini(8,level.bubble_shots.size()) if on_lake else 0
    for i in range(friendly_count):
        var shot: Dictionary=level.bubble_shots[i]
        var tier:=clampi(int(shot.get("tier",1)),1,3)
        var baby: bool=shot.get("baby",false)
        var style: String="little" if baby else FRIENDLY_STYLES[tier-1]
        var extent: float=28.0 if baby else FRIENDLY_EXTENTS[tier-1]
        _paint(friendly[i],style,Vector2(shot["pos"])-offset,extent)
    for i in range(friendly_count,previous_friendly):friendly[i].hide()
    previous_friendly=friendly_count
    var hostile_count: int=mini(32,level.hostile_shots.size()) if on_lake else 0
    for i in range(hostile_count):
        var shot: Dictionary=level.hostile_shots[i]
        var key:=art.key_for(shot.get("style",level._opal_primary_id()))
        var angle:=Vector2(shot["velocity"]).angle()-deg_to_rad(float(art.metadata["frames"][key]["native_heading_degrees"]))
        _paint(hostile[i],key,Vector2(shot["pos"])-offset,48.0,angle)
    for i in range(hostile_count,previous_hostile):hostile[i].hide()
    previous_hostile=hostile_count
    var used:=0
    var emphatic:=0
    if on_lake:
        for enemy in level.enemies:
            if int(enemy["hp"])<=0:continue
            var at:=Vector2(enemy["x"],enemy["y"])-offset
            var fit: Vector2=Roster.ENEMY_FITS.get(enemy["kind"],Vector2(105,100))
            if at.x+fit.x+16<0 or at.x-fit.x-16>view.x or at.y+fit.y+16<0 or at.y-fit.y-16>view.y:continue
            if used>=FOE_CAP:break
            var incoming: Vector2=Vector2(enemy["x"],enemy["y"])-level.player
            var guarded: bool=preload("res://godot/opal_collision.gd").guarded(enemy,incoming)
            var cooldown:=float(enemy.get("hit_cd",0))
            var available: bool=level._bubble_context_allowed() or level._opal_boost_available()
            var mode:=3 if cooldown>0 else 0 if guarded or not available else 2
            var near: bool=incoming.length_squared()<600.0*600.0 and emphatic<4
            if near:emphatic+=1
            _shell(used,at,fit,mode,0 if level._bubble_context_allowed() else 1,0.68 if near else 0.25)
            _wake(used,enemy["kind"],at,enemy.get("mode","")=="attack",Vector2(enemy.get("aim",Vector2.RIGHT)))
            var portrait:=pack_sprites[used]
            if enemy["kind"] in PACK_KINDS:
                var frame: AtlasTexture=Lagoon.enemy_frame(enemy)
                portrait.texture=frame;portrait.material=pack_materials[frame]
                portrait.position=at;portrait.scale=Vector2.ONE*165.0/float(Lagoon.sizes[enemy["kind"]]);portrait.show()
            else:portrait.hide()
            used+=1
    for i in range(used,previous_foes):_hide_shell(i);wakes[i].hide();pack_sprites[i].hide()
    previous_foes=used
    for i in range(2):
        var slot:=FOE_CAP+i
        if not on_lake or i>=level.opal.targets.size():_hide_shell(slot);wakes[slot].hide();continue
        var target: Dictionary=level.opal.targets[i]
        var at: Vector2=target["pos"]-offset
        if not target["active"] or at.x < -500 or at.x>view.x+500:_hide_shell(slot);wakes[slot].hide();continue
        var mode:=3 if float(target["cooldown"])>0 else 2 if level._opal_target_open(target) else 1 if target["opening"] else 0
        _shell(slot,at,target["fit"],mode,0 if target["bubble"] else 1,1.0)
        _wake(slot,target["id"],at,target.get("attacking",false) and target["id"] in ["carlo","flip","blackwater","nessie"],Vector2.LEFT)
    for field_sprite in fields:field_sprite.hide()
    if on_lake:level._opal_sync_fields(self)
    if level.opal.charge.held and level._bubble_context_allowed():
        var amount: float=level.opal.charge.elapsed/1.35
        var tier: int=level.opal.charge.tier()
        var size:=38.0+38.0*pow(amount,0.70)
        if not gentle and tier==3:size*=1.0+sin(level.time*4.4)*0.018
        _paint(preview,FRIENDLY_STYLES[tier-1],level._hero_screen_position()+Vector2(level.facing*(Roster.SARAH_CAST_HAND_X+size*0.5),0),size)
    else:preview.hide()
    if active_impacts>0:
        for effect in impacts:
            if float(effect["life"])>0:effect["node"].position=Vector2(effect["at"])-offset
func _wake(slot: int, kind: String, at: Vector2, attacking: bool, aim: Vector2) -> void:
    if not attacking or kind not in MELEE:wakes[slot].hide();return
    var key:=art.key_for(kind)
    var angle:=aim.angle()-deg_to_rad(float(art.metadata["frames"][key]["native_heading_degrees"]))
    _paint(wakes[slot],key,at-aim*48,122.0 if slot<FOE_CAP else 164.0,angle,0.42)
func _shell(slot: int, at: Vector2, fit: Vector2, mode: int, glyph: int, opacity: float) -> void:
    var shell:=shells[slot]
    for side in SHELL_SIDES:
        var mesh: MeshInstance2D=shell[side];mesh.position=at;mesh.scale=fit
        if mesh.material!=shell_materials[mode]:mesh.material=shell_materials[mode]
        mesh.modulate=Color(1,1,1,opacity);mesh.show()
    var icon: MeshInstance2D=shell["icon"]
    icon.mesh=glyphs[glyph if mode==2 else 2];icon.position=at+Vector2(0,-fit.y)
    icon.scale=Vector2.ONE*(1.15 if slot>=FOE_CAP else 0.8)
    icon.modulate=Color(1,1,1,opacity) if mode==2 else Color(0.96,0.72,0.36,opacity)
    icon.visible=mode!=3
func _hide_shell(slot: int) -> void:
    shells[slot]["rear"].hide();shells[slot]["front"].hide();shells[slot]["icon"].hide()
func field(slot: int, style: String, at: Vector2, size: Vector2, opacity:=1.0, angle:=0.0) -> void:
    _paint(fields[slot],style,at,maxf(size.x,size.y),angle,opacity)
    var texture: Texture2D=fields[slot].texture
    fields[slot].scale=size/texture.get_size()
func impact(at: Vector2, tier: int, damage: bool) -> void:
    var selected:=0
    for i in range(impacts.size()):
        if float(impacts[i]["life"])<=0:selected=i;break
        if float(impacts[i]["life"])<float(impacts[selected]["life"]):selected=i
    var effect:=impacts[selected]
    if float(effect["life"])<=0:active_impacts+=1
    effect["tier"]=tier;effect["at"]=at;effect["duration"]=0.28 if tier==3 else 0.18;effect["life"]=effect["duration"]
    effect["node"].modulate=Color(1,1,1,1) if damage else Color(1.0,0.85,0.92,0.75);effect["node"].show()
    var count:=4 if tier==1 else 6 if tier==2 else 8
    for i in range(8):
        var drop: Sprite2D=effect["drops"][i]
        if i<count:_paint(drop,"little",Vector2.ZERO,7.0 if tier<3 else 10.0)
        else:drop.hide()
func advance(dt: float) -> void:
    if active_impacts==0:return
    for effect in impacts:
        if float(effect["life"])<=0:continue
        effect["life"]=maxf(0.0,float(effect["life"])-dt)
        if float(effect["life"])<=0:effect["node"].hide();active_impacts-=1;continue
        var progress:=1.0-float(effect["life"])/float(effect["duration"])
        var radius:=lerpf(10,48 if int(effect["tier"])==3 else 30,progress)
        effect["rear"].scale=Vector2(radius,radius*0.75);effect["front"].scale=Vector2(radius,radius*0.75)
        effect["node"].modulate.a=(1-progress)*0.85
        var count:=4 if int(effect["tier"])==1 else 6 if int(effect["tier"])==2 else 8
        for i in range(count):
            var angle:=float(i)/count*TAU
            effect["drops"][i].position=Vector2(cos(angle),sin(angle))*radius*(0.9 if gentle else 1.15)
func hide_preview() -> void:
    if is_instance_valid(preview):preview.hide()
func reset() -> void:
    hide_preview()
    for sprite in friendly:sprite.hide()
    for sprite in hostile:sprite.hide()
    for sprite in wakes:sprite.hide()
    for sprite in fields:sprite.hide()
    for sprite in pack_sprites:sprite.hide()
    for i in range(shells.size()):_hide_shell(i)
    for effect in impacts:effect["life"]=0.0;effect["node"].hide()
    previous_friendly=0;previous_hostile=0;previous_foes=0;active_impacts=0
static func _ring(start: float, finish: float) -> ArrayMesh:
    var vertices:=PackedVector3Array();var uvs:=PackedVector2Array();var colors:=PackedColorArray();var indices:=PackedInt32Array()
    for i in range(49):
        var angle:=lerpf(start,finish,float(i)/48)
        for j in range(2):
            var radius:=0.952 if j==0 else 1.0
            vertices.append(Vector3(cos(angle)*radius,sin(angle)*radius,0));uvs.append(Vector2(angle/TAU,float(j)));colors.append(Color.WHITE)
    for i in range(48):
        var n:=i*2;indices.append_array(PackedInt32Array([n,n+1,n+2,n+1,n+3,n+2]))
    for angle in [0.64,PI-0.64,PI+0.64,TAU-0.64]:
        if angle<start or angle>finish:continue
        var centre:=Vector2(cos(angle),sin(angle))*0.976
        var base:=vertices.size()
        vertices.append(Vector3(centre.x,centre.y,0));uvs.append(Vector2(angle/TAU,0.5));colors.append(Color(1,1,1,0.25))
        for ring in range(2):
            for point in range(17):
                var around:=point*TAU/16
                var p:=centre+Vector2(cos(around),sin(around))*(0.023 if ring==0 else 0.036)
                vertices.append(Vector3(p.x,p.y,0));uvs.append(Vector2(angle/TAU,0.5+sin(around)*0.35));colors.append(Color(1,1,1,0.90 if ring==0 else 0.0))
        for point in range(16):
            var inner:=base+1+point;var outer:=base+18+point
            indices.append_array(PackedInt32Array([base,inner,inner+1,inner,outer,inner+1,outer,outer+1,inner+1]))
    var data:=[];data.resize(Mesh.ARRAY_MAX);data[Mesh.ARRAY_VERTEX]=vertices;data[Mesh.ARRAY_TEX_UV]=uvs;data[Mesh.ARRAY_INDEX]=indices;data[Mesh.ARRAY_COLOR]=colors
    var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,data);return mesh
static func _glyph(kind: int) -> ArrayMesh:
    var points:=PackedVector2Array()
    if kind==2:points=PackedVector2Array([Vector2(-8,-4),Vector2(0,-8),Vector2(8,-4),Vector2(6,6),Vector2(0,11),Vector2(-6,6)])
    else:
        for i in range(8):
            var angle:=i*TAU/8;points.append(Vector2(cos(angle),sin(angle))*(11.0 if i%2==0 else 3.5))
    var triangles:=Geometry2D.triangulate_polygon(points);var vertices:=PackedVector3Array()
    for p in points:vertices.append(Vector3(p.x,p.y,0))
    if kind==0:
        var base:=vertices.size()
        for i in range(17):
            var angle:=float(i)/16*TAU
            vertices.append(Vector3(17+cos(angle)*5,sin(angle)*5,0));vertices.append(Vector3(17+cos(angle)*3.5,sin(angle)*3.5,0))
        for i in range(16):
            var n:=base+i*2;triangles.append_array(PackedInt32Array([n,n+1,n+2,n+1,n+3,n+2]))
    elif kind==1:
        var base:=vertices.size()
        for p in [Vector2(13,-6),Vector2(21,0),Vector2(13,6),Vector2(16,0)]:vertices.append(Vector3(p.x,p.y,0))
        triangles.append_array(PackedInt32Array([base,base+1,base+3,base+1,base+2,base+3]))
    var data:=[];data.resize(Mesh.ARRAY_MAX);data[Mesh.ARRAY_VERTEX]=vertices;data[Mesh.ARRAY_INDEX]=triangles
    var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,data);return mesh

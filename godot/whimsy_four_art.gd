extends Node2D
## Two persistent painted meshes per scene; one world-anchored caption, fixed
## decoration loops and shared cached geometry. No per-frame texture loading.
const Kit=preload("res://godot/ui_kit.gd")
const Pearl=preload("res://godot/pearl_storybook.gd")
const Ground=preload("res://godot/terrain_painter.gd")
const SHADER=preload("res://godot/shaders/whimsy_neighbour.gdshader")
var host: Node2D
var model: RefCounted
var actors: Array[MeshInstance2D]=[]
var materials: Array[ShaderMaterial]=[]
var performances: Array=[]
var sizes: Array[Vector2]=[]
var overlay: CanvasLayer
var caption: PanelContainer
var caption_title: Label
var caption_body: Label
var caption_key:=""
var tutorial_caption_content: Control
var textures_loaded:=0
var visible_actors:=0
var near_room:=false
var mesh: ArrayMesh
func _ready() -> void:
    z_index=3;set_process(false)
    mesh=_skin()
    overlay=CanvasLayer.new();overlay.layer=9;add_child(overlay)
    caption=PanelContainer.new();caption.name="OneSmallNeighbourHello";caption.theme=Kit.theme();caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
    caption.add_theme_stylebox_override("panel",Pearl.panel(Pearl.IVORY,Pearl.SEAFOAM,18,10));overlay.add_child(caption)
    var box:=VBoxContainer.new();box.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_theme_constant_override("separation",5);caption.add_child(box)
    caption_title=Pearl.label("",16,Pearl.INK);box.add_child(caption_title)
    caption_body=Pearl.label("",17,Pearl.INK);caption_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;caption_body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.add_child(caption_body)
    caption.hide()
func bind(level: Node2D,logic: RefCounted) -> void:
    host=level;model=logic
    var old_box: Node=caption_title.get_parent()
    tutorial_caption_content=Control.new();tutorial_caption_content.mouse_filter=Control.MOUSE_FILTER_IGNORE;caption.add_child(tutorial_caption_content)
    caption_title.reparent(tutorial_caption_content,false);caption_body.reparent(tutorial_caption_content,false)
    caption.remove_child(old_box);old_box.queue_free()
    for i in range(model.profile["people"].size()):
        var person: Dictionary=model.profile["people"][i]
        performances.append(preload("res://godot/character_performance.gd").new(String(person["id"])))
        var actor:=MeshInstance2D.new();actor.mesh=mesh
        var texture: Texture2D=preload("res://godot/cavern_friends_data.gd").texture(int(person["atlas"])) if person.has("atlas") else load("res://godot/assets/whimsy-four/"+person["file"])
        if texture is AtlasTexture:
            var arrays:=mesh.surface_get_arrays(0)
            var uvs: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV].duplicate()
            for point in range(uvs.size()):uvs[point]=(texture.region.position+uvs[point]*texture.region.size)/texture.atlas.get_size()
            arrays[Mesh.ARRAY_TEX_UV]=uvs
            var cropped:=ArrayMesh.new();cropped.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);actor.mesh=cropped
        actor.texture=texture;actor.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
        var size:=texture.get_size()*(float(person["height"])/texture.get_height())
        actor.scale=size;add_child(actor);actors.append(actor);sizes.append(size)
        var material:=preload("res://godot/character_details.gd").surface(String(person["id"]),texture);material.set_shader_parameter("seed",float(i)*2.3+host._stage_index());actor.material=material;materials.append(material)
        textures_loaded+=1
    sync()
func _skin() -> ArrayMesh:
    var vertices:=PackedVector3Array();var uv:=PackedVector2Array();var index:=PackedInt32Array()
    var nx:=12;var ny:=10
    for y in range(ny+1):
        for x in range(nx+1):
            var at:=Vector2(float(x)/nx,float(y)/ny);vertices.append(Vector3(at.x-.5,at.y-.5,0));uv.append(at)
    for y in range(ny):
        for x in range(nx):
            var a:=y*(nx+1)+x;var b:=a+1;var c:=a+nx+1;var d:=c+1
            index.append_array(PackedInt32Array([a,c,b,b,c,d]))
    var arrays:=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_INDEX]=index
    var result:=ArrayMesh.new();result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);return result
func sync() -> void:
    if not is_instance_valid(host):return
    var room: Dictionary=model.profile["room"]
    var world_view:=Rect2(host.camera-240,host._camera_y()-180,get_viewport_rect().size.x+480,get_viewport_rect().size.y+360)
    near_room=false
    for place in model.profile["rooms"]:
        if world_view.intersects(place["body"].grow(180)):near_room=true;break
    visible=host.waterfall_phase=="" and host.state in ["playing","paused"] and not host.get_node("/root/SceneFlow").busy and near_room
    visible_actors=0
    if not visible:
        for actor in actors:actor.hide()
        caption.hide();return
    for i in range(actors.size()):
        var person: Dictionary=model.profile["people"][i]
        var foot: Vector2=person["foot"]
        if not world_view.grow(120).has_point(foot):actors[i].hide();continue
        var still: bool=host.reduced_fx or not model.active() or model.quiet
        var at: Vector2=foot-Vector2(host.camera,sizes[i].y*.5)
        var attention:=1-smoothstep(110,310,host.player.distance_to(person["talk_at"]))
        var world_direction:=signf(host.player.x-foot.x)
        performances[i].advance(model.clock,attention,model.flourish>0,still,world_direction)
        var sway:=0.0 if still else sin(model.clock*1.25+i*2.1)*2.2
        actors[i].position=at+Vector2(0,sway)+performances[i].offset
        actors[i].scale=Vector2(sizes[i].x*(-1 if i==1 else 1),sizes[i].y)
        actors[i].rotation=0.0 if still else sin(model.clock*1.7+i)*.009*(1+attention)+performances[i].tilt
        preload("res://godot/character_details.gd").update(materials[i],model.clock,still)
        materials[i].set_shader_parameter("expression_joy",performances[i].joy)
        materials[i].set_shader_parameter("expression_look",performances[i].look*(-1.0 if i==1 else 1.0))
        materials[i].set_shader_parameter("expression_greet",performances[i].greeting)
        materials[i].set_shader_parameter("gentle",1.0 if still else 0.0)
        materials[i].set_shader_parameter("mood",attention+(.7 if model.flourish>0 else 0.0))
        actors[i].visible=visible and world_view.grow(120).has_point(foot)
        if actors[i].visible:visible_actors+=1
    _caption()
    if visible:queue_redraw()
func _caption() -> void:
    caption.hide()
    if not visible or model.hushed() or model.chat_actor<0 or model.chat_left<=0:return
    if not host.premium_hud.visible or host.player_velocity.length()>180:return
    # All optional speakers share this modest local lane; combat/UI always win.
    if is_instance_valid(host.living_shallows) and host.living_shallows.label_panel.visible:return
    if host.pocket_wonders_art.caption.visible:return
    var hud=host.premium_hud
    overlay.transform=Transform2D(0,Vector2.ONE*hud.ui_scale,0,hud.safe_frame.position)
    var person: Dictionary=model.profile["people"][model.chat_actor]
    var text: String=model.chat_line;var key:=String(person["id"])+text
    if key!=caption_key:
        caption_key=key;caption_title.text="Sarah" if model.sarah_reply else person["name"];caption_body.text=text
    var width:=minf(340,hud.game_size.x-40)
    caption.size=Vector2(width,0)
    var at: Vector2=person["foot"]-Vector2(host.camera,float(person["height"])+host._camera_y()+22)
    if model.sarah_reply:at=host.player-Vector2(host.camera,host._camera_y()+125)
    var point: Vector2=hud.to_ui(at)
    var height:=_tutorial_caption_height(width)
    var top:=112.0
    if host._stage_index()==7 and host.lesson_card.visible:top=maxf(top,host.lesson_card.position.y+host.lesson_card.size.y+16)
    var candidate:=Vector2(clampf(point.x-width*.5,16,hud.game_size.x-width-16),clampf(point.y-height,top,maxf(top,hud.game_size.y-height-190)))
    var rect:=Rect2(candidate,Vector2(width,height))
    var hero: Vector2=hud.to_ui(host.player-Vector2(host.camera,host._camera_y()))
    var half: Vector2=Vector2(140,92)/float(hud.ui_scale)
    var body:=Rect2(hero-half,half*2.0)
    if rect.grow(12).intersects(body):
        candidate.y=clampf(body.position.y-height-18,top,maxf(top,hud.game_size.y-height-190))
        rect.position=candidate
        if rect.grow(12).intersects(body):
            candidate.x=clampf(body.end.x+18,16,hud.game_size.x-width-16);rect.position=candidate
            if rect.grow(12).intersects(body):return
    caption.position=candidate;caption.modulate.a=clampf(model.chat_left/.35,0,1);caption.show()
func _tutorial_caption_height(width: float) -> float:
    # Measure at the final wrap width; do not carry a stale container minimum
    # from an earlier long line or a temporarily zero-width label.
    var inner:=width-20.0
    var title_height:=ceilf(caption_title.get_theme_font("font").get_height(16))+2.0
    var body_height:=ceilf(caption_body.get_theme_font("font").get_multiline_string_size(caption_body.text,HORIZONTAL_ALIGNMENT_LEFT,inner,17).y)+4.0
    var height:=20.0+title_height+5.0+body_height
    tutorial_caption_content.custom_minimum_size=Vector2(inner,height-20.0)
    caption_title.position=Vector2.ZERO;caption_title.size=Vector2(inner,title_height)
    caption_body.position=Vector2(0,title_height+5.0);caption_body.size=Vector2(inner,body_height)
    caption.size=Vector2(width,height)
    return height

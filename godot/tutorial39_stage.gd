extends Node2D
## Tutorial-only visual adapters. One shared 3D viewport; existing gameplay owns all state.
const Actor=preload('res://godot/tutorial39_actor.gd')
var host: Node2D
var viewport: SubViewport
var camera: Camera3D
var screen: Sprite2D
var actors: Dictionary={}
var prop_seen: Dictionary={}
var prop_counts: Dictionary={}
var prop_frame:=-1
var clock:=0.0
var last_retry:=-1
var budget:=0.0
var last_size:=Vector2.ZERO
var visible_count:=0
var active_bones:=0
var replacements:=0
var redraw_needed:=true
var last_state:=''
const PROP_MODELS={'dream/whale':7,'tea/butler':4,'tea/jelly':0,'post/postman':1,'village/pearl':5,'village/lavender':6,'village/coral':5,'village/crab':2}
func bind(level: Node2D) -> void:
    assert(level._stage_index()==7)
    host=level;z_index=3;process_mode=Node.PROCESS_MODE_ALWAYS;process_priority=10
    viewport=SubViewport.new();viewport.name='SharedTutorialModels';viewport.transparent_bg=true;viewport.own_world_3d=true;viewport.gui_disable_input=true;add_child(viewport)
    var environment:=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color('#d6ebec');environment.environment.ambient_light_energy=.8;viewport.add_child(environment)
    for entry in [[Vector3(-28,-32,0),Color('#ffeed9'),1.1],[Vector3(-12,145,0),Color('#95ddeb'),.45]]:
        var light:=DirectionalLight3D.new();light.rotation_degrees=entry[0];light.light_color=entry[1];light.light_energy=entry[2];light.shadow_enabled=false;viewport.add_child(light)
    camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.position=Vector3(0,0,20);camera.current=true;viewport.add_child(camera)
    screen=Sprite2D.new();screen.centered=false;screen.texture=viewport.get_texture();add_child(screen)
    host.pocket_wonders_art.replacement_painter=paint_replacement
    for key in PROP_MODELS:
        for i in range(3 if key=='tea/jelly' else 1):_actor(key+':'+str(i),[0,2,1][i] if key=='tea/jelly' else PROP_MODELS[key],100 if key=='tea/jelly' else 175)
    _actor('keeper',3,160);_actor('shy',0,85);_actor('friend',7,65)
    for i in range(host.neighbourhood.profile['people'].size()):_actor('neighbour:'+str(i),[1,2,4][i%3],host.neighbourhood.profile['people'][i]['height'])
    _actor('nursery-house',6,142);_actor('bellflower-house',5,160);_actor('moon-whale',7,100)
    _sync()
func _actor(key: String,id: int,height: float):
    if not actors.has(key):
        var actor:=Actor.new();viewport.add_child(actor);actor.configure(id,height,float(actors.size())*1.73);actor.hide();actors[key]=actor
    return actors[key]
func paint_replacement(kind: String,role: String,at: Vector2,height: float,angle: float,alpha: float,flip: bool) -> bool:
    var name:=kind+'/'+role
    if not PROP_MODELS.has(name):return false
    var frame:=Engine.get_process_frames()
    if frame!=prop_frame:prop_frame=frame;prop_counts.clear()
    var count: int=prop_counts.get(name,0);prop_counts[name]=count+1
    var key:=name+':'+str(count)
    if not actors.has(key):return false
    if alpha<=.01:prop_seen.erase(key);actors[key].hide();return true
    actors[key].scale=Vector3.ONE*height/actors[key].requested_height
    if name=='tea/jelly':at+=Vector2([-18,10,48][count],[-20,-30,0][count])
    prop_seen[key]={'frame':frame,'world':at+Vector2(host.camera,0),'height':height,'flip':flip,'alpha':alpha}
    return true
func _process(dt: float) -> void:
    if not is_instance_valid(host):return
    var running: bool=host.state=='playing' and not get_tree().paused
    if last_state!=host.state:last_state=host.state;redraw_needed=true
    if running:clock=host.time
    if last_retry!=host.retry_serial:
        last_retry=host.retry_serial;prop_seen.clear()
        for a in actors.values():a.first_pose=true
    budget+=dt
    _sync()
    var rate:=1.0/20 if not host.high_depth_quality else 1.0/30
    if (running and budget>=rate) or redraw_needed:
        budget=0
        for key in actors:
            var a=actors[key]
            if a.visible and (running or a.first_pose):a.perform(clock,a.get_meta('mode','idle'),host.reduced_fx,a.get_meta('attention',0.0),a.get_meta('direction',1.0),a.get_meta('opened',false))
        viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
        redraw_needed=false
    else:viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
func _place(actor,at: Vector2,shown: bool,mode: String='idle',attention:=0.0,opened:=false) -> void:
    var view:=host.get_viewport_rect().size
    var point:=at-Vector2(0,host._camera_y())
    actor.visible=shown and Rect2(Vector2(-230,-230),view+Vector2(460,460)).has_point(point)
    if not actor.visible:return
    if actor.first_pose:redraw_needed=true
    actor.position=Vector3((point.x-view.x*.5)/100.0,(view.y*.5-point.y)/100.0,0)
    actor.set_meta('mode',mode);actor.set_meta('attention',attention);actor.set_meta('opened',opened);actor.set_meta('direction',signf(host.player.x-(at.x+host.camera)))
    visible_count+=1
func _sync() -> void:
    var view:=host.get_viewport_rect().size
    var pixels:=Vector2(host.get_window().size)
    var cap:=Vector2(1280,800) if host.high_depth_quality else Vector2(960,600)
    var factor:=minf(1,minf(cap.x/maxf(1,pixels.x),cap.y/maxf(1,pixels.y)))
    var resolution:=Vector2i((pixels*factor).floor())
    if viewport.size!=resolution:viewport.size=resolution;redraw_needed=true
    if last_size!=view:last_size=view;redraw_needed=true
    screen.scale=view/Vector2(resolution);screen.position.y=host._camera_y();camera.size=view.y/100.0
    visible_count=0
    var show_world: bool=host.state in ['playing','paused'] and not host.get_node('/root/SceneFlow').busy
    screen.visible=show_world
    _place(actors['nursery-house'],Vector2(720-host.camera,1610),show_world)
    _place(actors['bellflower-house'],Vector2(2160-host.camera,1700),show_world)
    _place(actors['moon-whale'],Vector2(2780-host.camera,1340),show_world,'idle',.3)
    for key in prop_seen:
        var data: Dictionary=prop_seen[key]
        _place(actors[key],data['world']-Vector2(host.camera,0),show_world and (get_tree().paused or Engine.get_process_frames()-int(data['frame'])<3),'idle',.5)
    for key in PROP_MODELS:
        for n in range(3 if key=='tea/jelly' else 1):
            var name: String=key+':'+str(n)
            if not prop_seen.has(name):actors[name].hide()
    var people: Array=host.neighbourhood.profile['people']
    for i in range(people.size()):
        var person: Dictionary=people[i];var foot: Vector2=person['foot'];var key:='neighbour:'+str(i)
        _place(actors[key],foot-Vector2(host.camera,float(person['height'])*.5),show_world and host.neighbourhood_art.visible,'talk' if host.neighbourhood.chat_actor==i else 'idle',1-smoothstep(120,330,host.player.distance_to(person['talk_at'])))
        host.neighbourhood_art.actors[i].hide()
    var little=host.little_moments
    if is_instance_valid(little):
        _place(actors['keeper'],little.dozy_point-Vector2(host.camera,70),show_world,'idle',1-smoothstep(100,300,host.player.distance_to(little.dozy_point)))
        _place(actors['shy'],little.fish_point-Vector2(host.camera,0),show_world,'idle',little.fish_trust)
        _place(actors['friend'],little.fish_point-Vector2(host.camera-60,35),show_world and little._owned('fish') and little.fish_trust>1.2)
        little.dozy.hide();little.fish.hide();little.fish_friend.hide()
    for key in actors:
        if String(key).begins_with('enemy:'):actors[key].hide()
    for i in range(host.enemies.size()):
        var enemy: Dictionary=host.enemies[i];var a=_actor('enemy:'+str(i),[2,0,4][i%3],118)
        _place(a,Vector2(enemy['x']-host.camera,enemy['y']),show_world and int(enemy['hp'])>0,String(enemy.get('mode','idle')),1)
    host.animated_enemies.hide()
    var index:=0
    for item in host.treasures:
        if item.get('kind','')!='chest':continue
        var key: String=host.treasure_gallery.key_for(item);var old=host.treasure_gallery.actors.get(key)
        var style: int=host.treasure_gallery.style_for(item,index)
        if not item.has('deep_id'):index+=1
        var id: int={0:8,1:9,2:11,4:8,6:10}.get(style,9)
        var chest=_actor('chest:'+key,id,130)
        _place(chest,Vector2(item['x']-host.camera,item['y']-6),show_world,'idle',0,bool(item['taken']))
        if is_instance_valid(old):old.hide()
    replacements=actors.size()

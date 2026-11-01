extends Node2D
## Four optional, input-free stories in two opening areas. No gameplay timers.
const Kit=preload("res://godot/ui_kit.gd")
const Pearl=preload("res://godot/pearl_storybook.gd")
const Terrain=preload("res://godot/terrain_painter.gd")
var host: Node2D
var clock:=0.0
var retry:=-1
var active:=false
var post: Sprite2D
var fish: Sprite2D
var fish_friend: Sprite2D
var dozy: Sprite2D
var music: Sprite2D
var message_box: PanelContainer
var message_label: Label
var message_content: Control
var speech_left:=0.0
var speech_at:=Vector2.ZERO
var speech_key:=""
var greeting_left:=0.0
var fish_trust:=0.0
var fish_point:=Vector2.ZERO
var fish_cooldown:=0.0
var fish_home:=Vector2.ZERO
var letter_phase:=0
var letter_time:=0.0
var letter_point:=Vector2.ZERO
var letter_start:=Vector2.ZERO
var lantern_warmth:=0.0
var lantern_conversation:=0
var music_notes:=0
var music_cooldown:=0.0
var note_life:=0.0
var note_at:=Vector2.ZERO
var post_point:=Vector2(1990,897)
var keeper_point:=Vector2.ZERO
var dozy_point:=Vector2.ZERO
var music_point:=Vector2.ZERO
var choir_voice: AudioStreamPlayer
var ring:=PackedVector2Array()
var bubble_outline:=PackedVector2Array()
var caption_width:=-1.0
var caption_dimensions:=Vector2.ZERO
var owns_focus:=false
var last_focus:=Vector2.ZERO

func _ready() -> void:
    z_index=2;set_process(false)
    post=_sprite("post-office",150)
    fish=_sprite("shy-fish",65)
    fish_friend=_sprite("moonfish",39)
    dozy=_sprite("dozy",130)
    music=_sprite("music-pavilion",230)
    message_box=PanelContainer.new();message_box.mouse_filter=Control.MOUSE_FILTER_IGNORE;message_box.z_index=8
    message_box.add_theme_stylebox_override("panel",Pearl.panel(Pearl.IVORY,Pearl.SEAFOAM,18,10));add_child(message_box)
    message_content=Control.new();message_content.mouse_filter=Control.MOUSE_FILTER_IGNORE;message_box.add_child(message_content)
    message_label=Pearl.label("",19,Pearl.INK);message_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;message_content.add_child(message_label)
    var body_font: FontFile=Kit.BODY
    body_font.multichannel_signed_distance_field=true
    message_label.add_theme_font_override("font",Kit.BODY)
    message_label.add_theme_constant_override("shadow_offset_y",0)
    choir_voice=AudioStreamPlayer.new();choir_voice.bus="SFX";choir_voice.volume_db=-21;choir_voice.stream=preload("res://godot/assets/audio-v023/pearl.wav");add_child(choir_voice)
    for i in range(40):ring.append(Vector2(cos(i*TAU/40),sin(i*TAU/40))*26)
    bubble_outline=ring.duplicate();bubble_outline.append(ring[0])
    hide()

func _sprite(id: String,height: float) -> Sprite2D:
    var node:=Sprite2D.new();node.texture=load("res://godot/assets/little-moments/"+id+".png")
    node.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;node.scale=Vector2.ONE*height/node.texture.get_height();node.offset.y=-node.texture.get_height()*.5
    if id in ["shy-fish","moonfish","dozy"]:node.material=preload("res://godot/character_details.gd").surface(id)
    add_child(node);return node

func bind(level: Node2D) -> void:
    host=level;retry=host.retry_serial
    var training: bool=host._stage_index()==7
    fish_home=Vector2(540,635) if training else Vector2(2510,665)
    fish_point=fish_home
    keeper_point=Vector2(2530,1660) if training else Vector2(2000,1515)
    music_point=Vector2(2140,1740) if training else Vector2(1250,1705)
    dozy_point=keeper_point
    if is_instance_valid(host.living_shallows):host.living_shallows.interactive_post=true
    sync()

func _owned(key: String) -> bool:return host.score_book.seen.has("little-moments:"+str(host._stage_index())+":"+key)

func _quiet() -> bool:
    return host.state=="playing" and not get_tree().paused and not host._whimsy_combat_active() and not (host.has_method("_lesson_conversation") and host.dialogue_open) and not host.get_node("/root/SceneFlow").busy

func _can_perform() -> bool:
    return _quiet() and host.boost_time<=0 and host.leap_phase=="" and not host.opal.charge.held and host.native_rig.can_discovery_react()

func _gaze(at: Vector2,gesture: String="greet") -> void:
    if not _can_perform() or host.living_reef.reactions.focus_left>0 or host.pocket_wonders.reactions.active:return
    owns_focus=true
    host.native_rig.set_discovery_focus(at-host.player,.42)
    last_focus=host.native_rig.discovery_focus_goal
    if greeting_left<=0:
        host.native_rig.play_discovery_gesture(gesture);greeting_left=4.5

func _speak(key: String,text: String,at: Vector2) -> void:
    if speech_key==key:speech_at=at;return
    speech_key=key;message_label.text=text;speech_at=at;speech_left=5.5
    caption_width=-1.0

func _complete(key: String,at: Vector2) -> void:
    if _owned(key):return
    host._award("little-moments:"+str(host._stage_index())+":"+key,"Secrets",40,at,false)
    host._bank_living_reef()
    _gaze(at,"reward")
    if is_instance_valid(host.avina):host.avina.react_to_discovery("complete")

func hide_other_captions() -> void:
    if is_instance_valid(host.living_shallows):host.living_shallows.label_panel.hide()
    host.neighbourhood_art.caption.hide()
    host.pocket_wonders_art.caption.hide()
    host.living_reef_art.caption.hide()

func advance(dt: float) -> void:
    if not is_instance_valid(host) or not is_finite(dt) or dt<=0:return
    if retry!=host.retry_serial:
        retry=host.retry_serial;letter_phase=0;letter_time=0;fish_trust=0;fish_point=fish_home
        music_notes=0;lantern_warmth=0;lantern_conversation=0;speech_left=0;speech_key="";greeting_left=0
    if not active or not _quiet():return
    var step:=minf(dt,.1)
    if not host.reduced_fx:clock+=step
    if host.message_time<=0:speech_left=maxf(0,speech_left-step)
    greeting_left=maxf(0,greeting_left-step)
    fish_cooldown=maxf(0,fish_cooldown-step);music_cooldown=maxf(0,music_cooldown-step);note_life=maxf(0,note_life-step)
    if host._stage_index()==7:_fish_story(step)
    if host._stage_index()==0:_postal_story(step)
    _tunnel_stories(step)
    if greeting_left<=0 and owns_focus:
        if host.native_rig.discovery_focus_goal.is_equal_approx(last_focus):host.native_rig.set_discovery_focus(Vector2.ZERO,0)
        owns_focus=false
    queue_redraw()

func _fish_story(dt: float) -> void:
    var near: bool=host.player.distance_to(fish_home)<300
    var calm: bool=near and host.player_velocity.length()<105 and host.boost_time<=0 and host.leap_phase==""
    var spooked: bool=near and (host.boost_time>0 or host.player_velocity.length()>420)
    if spooked:fish_cooldown=2.5;fish_trust=maxf(0,fish_trust-dt*3)
    elif calm and fish_cooldown<=0:fish_trust=minf(3.6,fish_trust+dt)
    else:fish_trust=maxf(0,fish_trust-dt*.7)
    var target:=fish_home
    if fish_cooldown>0:target+=Vector2(155,-62)
    elif near and fish_trust>.75:target=host.player+Vector2(host.facing*95,-30)
    if not host.reduced_fx:target+=Vector2(sin(clock*1.1)*5,sin(clock*1.8)*7)
    fish_point=fish_point.lerp(target,1-exp(-dt*2.8))
    if near and fish_trust>1.3 and _can_perform():
        _gaze(fish_point)
        _speak("fish-hello","Sarah: Hello, little one. We can take our time.",fish_point)
    if fish_trust>=3.5:
        _complete("fish",fish_point)

func _postal_story(dt: float) -> void:
    if _owned("letter"):letter_phase=4;return
    var nori: Vector2=host.living_shallows.nori_foot-Vector2(0,95)
    if letter_phase==0:
        if host.message_time<=0 and host.player.distance_to(nori)<380 and host.player_velocity.length()<160:
            letter_phase=1;letter_time=0;letter_start=nori+Vector2(30,-35);letter_point=letter_start
            _speak("letter-lost","Nori: Oh! That letter wants an adventure of its own.",nori)
    elif letter_phase==1:
        letter_time+=dt
        var target:=Vector2(2140,610)
        letter_point=letter_start.lerp(target,smoothstep(0,1,letter_time/4.0))
        if not host.reduced_fx:letter_point.y+=sin(clock*2)*5
        if letter_time>=3.0 and host.player.distance_to(letter_point)<90 and _can_perform():
            letter_phase=2;letter_time=0
            _gaze(letter_point,"reward")
            _speak("letter-caught","Sarah: A little bubble will keep it safe. Back to Nori!",letter_point)
    elif letter_phase==2:
        letter_point=letter_point.lerp(host.player+Vector2(host.facing*100,-55),1-exp(-dt*5))
        if host.player.distance_to(nori)<250:
            letter_phase=3;letter_time=0;letter_start=letter_point
    elif letter_phase==3:
        letter_time+=dt;letter_point=letter_start.lerp(nori+Vector2(18,-15),smoothstep(0,1,letter_time/1.1))
        if letter_time>=1.1:
            letter_phase=4;_complete("letter",nori)
            _speak("letter-thanks","Nori: Delivered with kindness. My favourite kind of post.",nori)

func _tunnel_stories(dt: float) -> void:
    var calm: bool=host.player_velocity.length()<140 and _can_perform()
    var keeper_distance: float=host.player.distance_to(keeper_point-Vector2(0,50))
    var near_keeper: bool=host._stage_index()==7 and keeper_distance<220
    var courtesy:=1-smoothstep(170,340,keeper_distance)
    dozy_point=dozy_point.lerp(keeper_point+Vector2(70,-205)*courtesy,1-exp(-dt*3))
    if speech_key=="lantern" and speech_left>0:speech_at=dozy_point-Vector2(0,130)
    elif speech_key=="lantern-sarah" and speech_left>0:speech_at=host.player+Vector2(-140,-80)
    if near_keeper and calm:
        lantern_warmth=minf(3,lantern_warmth+dt)
        _gaze(dozy_point-Vector2(0,60))
        if lantern_conversation==0:
            _speak("lantern","Dozy: Welcome to Bellflower Hollow, Sarah. Shall we wake one gentle light?",dozy_point-Vector2(0,120));lantern_conversation=1
            if not host.score_book.seen.has("friends-cavern:7:dozy"):
                host._award("friends-cavern:7:dozy","Secrets",50,keeper_point,false)
                host._bank_living_reef()
        elif lantern_conversation==1 and speech_left<=0:
            _speak("lantern-sarah","Sarah: Just one soft glow. It is lovely in here, Dozy.",host.player+Vector2(-140,-80));lantern_conversation=2
        if lantern_warmth>=2.8:_complete("lantern",keeper_point)
    else:lantern_warmth=maxf(0,lantern_warmth-dt*.4)
    if host._stage_index()==7 or music_cooldown>0 or not _can_perform():return
    var nearest:=clampi(roundi((host.player.x-music_point.x)/78.0)+1,0,2)
    for i in range(3):
        if i!=nearest:continue
        var point:=music_point+Vector2(-78+i*78,-125)
        if host.player.distance_to(point)>105:continue
        if music_notes&(1<<i):continue
        music_notes|=1<<i;music_cooldown=.65;note_at=point;note_life=1.5
        choir_voice.pitch_scale=[1.0,1.25,1.5][i]
        if host.get_node("/root/OceanAudio").playback_enabled and host.get_node("/root/AppPreferences").sound_volume>0:choir_voice.play()
        _gaze(point,"reward")
        if music_notes==7:
            _complete("music",music_point);_speak("music","Sarah: Three little voices, one lovely song.",music_point-Vector2(0,150))
        break

func sync() -> void:
    if not is_instance_valid(host):return
    active=host._stage_index()==7 or host._stage_index()==0 and not host.fallen and host.waterfall_phase==""
    visible=active and host.state in ["playing","paused"]
    message_box.hide()
    if not visible:return
    for actor in [fish,fish_friend,dozy]:
        preload("res://godot/character_details.gd").update(actor.material,clock,host.reduced_fx or host.state!="playing" or get_tree().paused)
    var offset:=Vector2(host.camera,0)
    var view:=get_viewport_rect().size
    var camera_y: float=host.deep_routes.camera_y if is_instance_valid(host.deep_routes) else 0.0
    var window:=Rect2(Vector2(-220,camera_y-250),view+Vector2(440,500))
    post.position=post_point-offset;post.visible=host._stage_index()==0 and window.has_point(post.position)
    fish.position=fish_point-offset;fish.visible=host._stage_index()==7 and window.has_point(fish.position)
    fish.flip_h=host.player.x>fish_point.x
    fish_friend.position=fish.position+Vector2(53,-32 if host.reduced_fx else -32+sin(clock*1.5)*5)
    fish_friend.visible=fish.visible and _owned("fish") and fish_trust>1.2
    fish_friend.flip_h=host.player.x<fish_point.x
    dozy.position=dozy_point-offset;dozy.visible=host._stage_index()==7 and window.has_point(dozy.position)
    if not host.reduced_fx:dozy.rotation=sin(clock*.65)*.018;fish.rotation=sin(clock*1.1)*.025
    else:dozy.rotation=0;fish.rotation=0
    music.position=music_point-offset;music.visible=host._stage_index()==0 and window.has_point(music.position)
    if host._stage_index()==0:
        # Authored foreground beds replace repeated parallax garden stamps here.
        host.world_depth.far_gardens.visible=host.camera>3100 or host.fallen
        host.world_depth.middle_gardens.visible=host.camera>3100 or host.fallen
    if speech_left>0 and _quiet() and host.player.distance_to(speech_at)<560 and host.message_time<=0 and not host.opal.charge.held:
        var physical:=float(host.get_window().size.y)/maxf(1,view.y)
        var magnify:=clampf(1/maxf(.1,physical),1,2.5)
        var width:=minf(355,(view.x-64)/magnify)
        if absf(caption_width-width)>.1:
            var text_height:=ceilf(message_label.get_theme_font("font").get_multiline_string_size(message_label.text,HORIZONTAL_ALIGNMENT_LEFT,width-32,19).y)
            caption_dimensions=Vector2(width,maxf(62,text_height+28));caption_width=width
            message_content.custom_minimum_size=caption_dimensions-Vector2(20,20)
            message_label.position=Vector2(6,4);message_label.size=Vector2(width-32,caption_dimensions.y-28)
        message_box.scale=Vector2.ONE*magnify;message_box.size=caption_dimensions
        var extent:=message_box.size*magnify
        var top:=camera_y+165.0
        if host._stage_index()==7 and host.lesson_card.visible:
            var cue: Rect2=host.premium_hud.to_game(Rect2(host.lesson_card.position,host.lesson_card.size))
            top=maxf(top,camera_y+cue.end.y+24)
        var bottom:=maxf(top,camera_y+view.y-extent.y-175)
        var position:=speech_at-offset-Vector2(extent.x*.5,125)
        position.x=clampf(position.x,24,maxf(24,view.x-extent.x-24))
        position.y=clampf(position.y,top,bottom)
        var hero:=Rect2(host.player-offset-Vector2(130,90),Vector2(260,180))
        if Rect2(position,extent).intersects(hero):
            position.y=clampf(hero.position.y-extent.y-22,top,bottom)
        if Rect2(position,extent).intersects(hero):
            position.x=clampf(hero.end.x+24,24,maxf(24,view.x-extent.x-24))
        if Rect2(position,extent).intersects(hero):
            position.x=clampf(hero.position.x-extent.x-24,24,maxf(24,view.x-extent.x-24))
        if not Rect2(position,extent).intersects(hero):
            message_box.position=position;message_box.show();hide_other_captions()
    queue_redraw()

func _draw() -> void:
    if not visible:return
    var offset:=Vector2(host.camera,0)
    if host._stage_index()==0 and letter_phase in [1,2,3]:
        var p:=letter_point-offset
        if letter_phase>=2:
            draw_set_transform(p)
            draw_colored_polygon(ring,Color(.67,.95,1,.09));draw_polyline(bubble_outline,Color(.8,1,1,.7),1.5,true)
            draw_set_transform(Vector2.ZERO)
        draw_style_box(_letter_style,Rect2(p-Vector2(16,10),Vector2(32,20)))
        draw_line(p+Vector2(-15,-9),p,Color("b7a3ae"),1,true);draw_line(p,p+Vector2(15,-9),Color("b7a3ae"),1,true)
        draw_circle(p,2.5,Color("df8a9f"))
    if dozy.visible:
        for i in range(3):
            var p:=keeper_point-offset+Vector2(-76+i*62,-170-12*sin(i*2.2))
            var alpha:=.2+lantern_warmth*.15
            draw_line(p+Vector2(0,-36),p,Color(.65,.6,.4,.4),1,true)
            draw_circle(p,6+i,Color(.98,.8,.4,alpha));draw_arc(p,9+i,0,TAU,24,Color("e6ba76"),1,true)
    if note_life>0 and not host.reduced_fx:
        var p:=note_at-offset-Vector2(0,(1.5-note_life)*30)
        draw_circle(p,4,Color(.9,.9,1,note_life/1.5));draw_line(p+Vector2(3,0),p+Vector2(3,-16),Color(.9,.9,1,note_life/1.5),2,true)

var _letter_style: StyleBoxFlat=make_letter()
static func make_letter() -> StyleBoxFlat:
    var style:=StyleBoxFlat.new();style.bg_color=Color("f5ead1");style.border_color=Color("d9bea6");style.set_border_width_all(1);style.set_corner_radius_all(2);return style

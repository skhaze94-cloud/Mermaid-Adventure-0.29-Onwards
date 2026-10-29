extends "res://godot/tools/performance_audit.gd"
## Native, full-quality visual review of every family and authoritative shell state.
var pictures: Array[String]=[]
func snap(scene, name: String) -> void:
    for i in range(6):
        scene._sync_native_visuals();scene.native_rig._process(1.0/60)
        if scene.get("performance"):scene.performance._process(1.0/60)
        if scene.get("flip_performance"):scene.flip_performance._process(1.0/60)
        scene.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
    assert(root.get_texture().get_image().save_png(output+"/"+name+".png")==OK)
    pictures.append(name);print("OPAL VISUAL ",name)
func setup(path: String):
    var scene=load(path).instantiate();root.add_child(scene)
    var calls: Array[Node]=[];var animations: Array[AnimationPlayer]=[];freeze(scene,calls,animations)
    scene.music_player.stop();scene.state="playing";scene.invulnerable=0;scene.fallen=true;scene.time=7.5;scene.message_time=0
    scene.player=Vector2(scene._boss_home()-500,610);scene.camera=scene._boss_home()-850
    scene.boss_position=Vector2(scene._boss_home(),570);scene.player_velocity=Vector2(190,0);scene.bubble_unlocked=true
    if scene.get("lesson")!=null:
        scene.lesson=8;scene.dialogue_open=false;scene.dialogue_card.hide();scene.choice_card.hide()
        scene.king_world=scene.boss_position;scene.character_dt=1.0/60;scene._show_lesson()
    return scene
func phase(scene, mode: String) -> void:
    var opened:=mode in ["open","cooldown"]
    scene.boss_clock=8.6 if scene.get("lesson")!=null and opened else 4.4 if opened else 1.2
    scene.boss_phase="recover" if opened else "windup";scene.boss_phase_time=0.4
    scene.boss_hit_cooldown=0.4 if mode=="cooldown" else 0.0
    if mode=="opening":
        scene.boss_clock=8.1 if scene.get("lesson")!=null else 4.0 if scene._opal_primary_id()=="duke" else 3.7 if scene._opal_primary_id()=="miguel" else 3.9
        scene.boss_phase="attack";scene.boss_phase_time=0.6
func retire(scene) -> void:
    root.remove_child(scene);scene.free()
    for i in range(3):await process_frame
func families(path: String, kinds: Array, name: String) -> void:
    var scene=setup(path);scene.camera=0;scene.player=Vector2(80,600);scene.boss_hp=0;scene.enemies.clear()
    for i in range(kinds.size()):
        var at:=Vector2(430+(i%3)*325,440+(i/3)*285)
        scene.enemies.append({"kind":kinds[i],"x":at.x,"y":at.y,"bx":at.x,"by":at.y,"hp":3,"phase":float(i),
            "dir":-1 if i%2==0 else 1,"mode":"patrol","mode_time":0.3,"hit_cd":0.0})
    scene.animated_enemies.bind_enemies(scene.enemies);scene.opal.begin("audit");scene.opal.advance(1.35)
    await snap(scene,name)
    for enemy in scene.enemies:enemy["mode"]="attack";enemy["aim"]=Vector2.RIGHT
    await snap(scene,name+"-attack");await retire(scene)
func dense(scene) -> void:
    scene.bubble_shots.clear();scene.hostile_shots.clear()
    for i in range(8):scene.bubble_shots.append({"pos":Vector2(scene.camera+470+(i%4)*105,365+(i/4)*170),"direction":1.0,"life":1.8,"tier":i%3+1,"owner":"sarah"})
    for i in range(32):scene._spawn_hostile(Vector2(scene.camera+530+(i%8)*103,330+(i/8)*150),Vector2.LEFT.rotated(i*0.07),270,scene._opal_primary_id() if i%2==0 else ["jelly","puffer","eel","shark"][i%4])
    scene.opal_fx.impact(scene.boss_position-Vector2(200,0),3,true);scene.opal_fx.advance(0.07)
    scene.opal.begin("audit");scene.opal.advance(1.35)
func atlas_board(dark: bool) -> void:
    var board:=Node2D.new();root.add_child(board)
    var background:=ColorRect.new();background.color=Color("102b40") if dark else Color("f6f5f0");background.size=Vector2(1400,960);board.add_child(background)
    var metadata: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://godot/assets/opal-current/manifest.json"))
    var textures: Dictionary={}
    for id in metadata["atlases"]:textures[id]=load("res://godot/assets/opal-current/"+metadata["atlases"][id]["file"])
    var index:=0
    for id in metadata["frames"]:
        var entry: Dictionary=metadata["frames"][id];var r: Array=entry["region"]
        var texture:=AtlasTexture.new();texture.atlas=textures[entry["atlas"]];texture.region=Rect2(r[0],r[1],r[2],r[3]);texture.filter_clip=true
        var sprite:=Sprite2D.new();sprite.texture=texture;sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
        sprite.position=Vector2(100+(index%7)*200,110+(index/7)*224);sprite.scale=Vector2.ONE*95/maxf(texture.get_width(),texture.get_height());board.add_child(sprite)
        var label:=Label.new();label.text=id;label.position=sprite.position+Vector2(-75,65);label.size=Vector2(150,24);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
        label.add_theme_color_override("font_color",Color("eefafa") if dark else Color("173849"));label.add_theme_font_size_override("font_size",16);board.add_child(label);index+=1
    for i in range(3):await process_frame;await RenderingServer.frame_post_draw
    var name:="atlas-dark" if dark else "atlas-light"
    assert(root.get_texture().get_image().save_png(output+"/"+name+".png")==OK);pictures.append(name);root.remove_child(board);board.free();await process_frame
func run() -> void:
    Engine.time_scale=0;root.size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true;prefs.economy=false;prefs.reduced_motion=false
    root.get_node("OceanAudio").playback_enabled=false;root.get_node("AdventureRun").avina_along=false
    var paths: Array=root.get_node("AdventureRun").SCENES
    for index in range(paths.size()):
        var scene=setup(paths[index])
        for mode in ["guarded","opening","open","cooldown"]:phase(scene,mode);await snap(scene,"chapter-"+str(index)+"-"+mode)
        if index==0:
            phase(scene,"open")
            for tier in range(1,4):
                scene.opal.cancel();scene.opal.suppressed.clear();scene.fire_cooldown=0;scene.opal.begin("audit");scene.opal.advance([0.2,0.6,1.35][tier-1])
                await snap(scene,"sarah-held-"+str(tier))
            scene.facing=-1;scene.player_velocity=Vector2(-190,0);scene.player.x=scene._boss_home()-250;await snap(scene,"sarah-held-left")
            scene.facing=1;scene.player_velocity=Vector2(190,0);scene.player.x=scene._boss_home()-500
            scene.opal.cancel();scene.opal.suppressed.clear();scene.fire_cooldown=0;scene.opal.begin("audit");scene.opal.advance(1.35);scene.opal.release("audit")
            await snap(scene,"sarah-super-release");dense(scene);await snap(scene,"max-density-highland")
            root.size=Vector2i(960,1400)
            for i in range(4):await process_frame;await RenderingServer.frame_post_draw
            assert(scene.state=="paused" and not scene.opal.charge.held)
            assert(root.get_texture().get_image().save_png(output+"/portrait-cancel.png")==OK);pictures.append("portrait-cancel")
            paused=false;root.size=Vector2i(1400,960)
            for i in range(3):await process_frame
        if index==1:dense(scene);await snap(scene,"max-density-duo")
        if index==7:
            scene.boss_hit_cooldown=0;scene.cloud_active=true;scene.wave_active=true;scene.cloud=scene.boss_position+Vector2(-300,-50);scene.wave=scene.boss_position+Vector2(-400,130);scene.hostile_shots.clear()
            for i in range(5):scene._spawn_hostile(scene.boss_position+Vector2(-120-i*75,-170),Vector2.LEFT,105,"king-beard")
            await snap(scene,"king-cloud-wave-beard")
            scene.lesson=6;scene.cloud_active=false;scene.wave_active=false;scene.hostile_shots.clear();scene.camera=5300;scene.player=Vector2(5500,600);scene.king_world=Vector2(6240,500);scene.character_dt=0;scene._show_lesson()
            await snap(scene,"protected-royal-teachers")
        await retire(scene)
    await families(paths[0],["crab","eel","jelly","puffer","swordfish","shark"],"six-core-families")
    await families(paths[2],["maraca-snapper","ribbon-ambusher","bubble-bandit-otter","orchid-hermit","drumback-turtle","disco-cuttlefish"],"six-lagoon-families")
    await atlas_board(true);await atlas_board(false)
    var file:=FileAccess.open(output+"/visual-review.json",FileAccess.WRITE);file.store_string(JSON.stringify({"pictures":pictures,"count":pictures.size(),"quality":"full","renderer":RenderingServer.get_video_adapter_name()},"  "));file.close()
    print("OPAL VISUAL AUDIT COMPLETE ",pictures.size());quit()

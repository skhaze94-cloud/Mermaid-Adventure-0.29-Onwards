extends "res://godot/tools/opal_visual_audit.gd"
## Full-quality native presentation fixtures. Gameplay, saves and ownership are
## exercised separately by the Pocketful of Wonders integration suites.
class PresentationView extends RefCounted:
    var model: RefCounted
    var selected := 0
    var playful := false
    var partner := "avina"
    var force_quiet := false
    func snapshot() -> Dictionary:
        var result: Dictionary=model.call("snapshot").duplicate()
        var copied: Array=[]
        var original: Array=result.get("records",[])
        for i in range(original.size()):
            var record: Dictionary=original[i].duplicate()
            var profile: Dictionary=record.get("profile",{})
            record["visible"]=true
            if i==selected:
                record["state"]="playing" if playful else "invited"
                record["phase"]=4 if playful else 0
                record["timer"]=.65 if playful else .25
                record["elapsed"]=4.8 if playful else .25
                record["progress"]=2 if playful else 0
                record["completed"]=false
                record["nearby"]=true
                record["focus"]=profile.get("at",Vector2.ZERO)
                record["quiet"]=force_quiet
                record["glow_time"]=1.5 if playful else .5
                var messages: Array=profile.get("progress_lines",[])
                record["active_hint"]=String(messages[mini(2,messages.size()-1)]) if playful and not messages.is_empty() else String(profile.get("discovery_line","Swim closer and see what happens."))
                if profile.get("kind","")=="post":
                    var letter: Array=profile.get("letter",[])
                    if playful and not letter.is_empty():record["active_hint"]=String(letter[mini(1,letter.size()-1)])
            copied.append(record)
        result["records"]=copied
        result["quiet"]=force_quiet
        result["visible"]=true
        if selected<copied.size():
            var profile: Dictionary=copied[selected].get("profile",{})
            var anchor: Vector2=profile.get("at",Vector2.ZERO)
            result["mirror"]={"active":true,"kind":"bubble_game","phase":4 if playful else 1,
                "phase_time":.65,"phase_progress":.65,"elapsed":4.8 if playful else 1.2,
                "partner":partner,"anchor":anchor,"at":anchor,"hero":anchor+Vector2(-190,55),
                "partner_at":anchor+Vector2(-270,90),"fish_at":anchor+Vector2(120,-78),
                "bubble_owner":"passing_fish" if playful else "sarah","fish_mood":"surprised" if playful else "curious",
                "gentle":false}
        result["has_baby"]=partner=="avina"
        return result

var views: Dictionary={}
var examined_kinds: Dictionary={}
var caption_review: Dictionary={}

func snap(scene,name: String) -> void:
    scene.message_time=0
    if is_instance_valid(scene.avina):scene.avina.tick(0)
    if scene.native_rig.gesture_player.is_playing():scene.native_rig.gesture_player.advance(.35)
    scene.pocket_wonders_art.advance(.12)
    await super.snap(scene,name)
    var art=scene.pocket_wonders_art
    caption_review[name]={"visible":art.caption.visible,"position":art.caption.position,"size":art.caption.size,"scale":art.caption.scale}
    assert(art.visible_count<=art.VISIBLE_CAP and art.batch_overflows==0,"bounded native wonder presentation")

func world(index: int):
    var scene=setup(root.get_node("AdventureRun").SCENES[index])
    scene.enemies.clear();scene.animated_enemies.bind_enemies(scene.enemies)
    scene.player_velocity=Vector2.ZERO;scene.touch_vectors.clear();scene.boost_time=0;scene.opal.cancel()
    scene.message_time=0
    scene.living_reef.clear_transients();scene.whimsy_moments.clear()
    if index==6:scene.boss_hp=0
    if index==7:
        scene.lesson=10;scene.boss_hp=0;scene.dialogue_open=false;scene.playing_daddy=false
        scene.lesson_card.hide();scene.dialogue_card.hide();scene.choice_card.hide()
        scene.king_world=Vector2(6770,515)
        # Real lesson10 creates the protected follower while restoring family
        # extras. This frozen presentation fixture starts after that event.
        if not is_instance_valid(scene.avina):
            scene.avina=load("res://godot/avina_companion.gd").new();scene.add_child(scene.avina);scene.avina.bind(scene)
        scene.avina.follow_enabled=true
    var fixture:=PresentationView.new();fixture.model=scene.pocket_wonders
    views[scene.get_instance_id()]=fixture
    scene.pocket_wonders_art.bind(scene,fixture)
    return scene

func place(scene,index: int,playful: bool) -> Dictionary:
    var fixture: PresentationView=views[scene.get_instance_id()]
    fixture.selected=index;fixture.playful=playful
    var state: Dictionary=scene.pocket_wonders.call("snapshot")
    var record: Dictionary=state.get("records",[])[index]
    var profile: Dictionary=record.get("profile",{})
    var at: Vector2=profile.get("at",Vector2.ZERO)
    scene.player=scene.RockCollision.recover(at+Vector2(-190,65),scene.obstacles,scene.HERO_RADIUS*.73,scene._swim_bounds())
    scene.camera=scene.player.x-550;scene.player_velocity=Vector2.ZERO;scene.facing=1
    scene.native_rig.reset_performance();scene.native_rig.set_motion(Vector2(30,0),1,false,false,1)
    if is_instance_valid(scene.avina):scene.avina.reset_follow();scene.avina.speech_time=0;scene.avina.tick(0)
    scene.pocket_wonders.reactions.clear()
    scene.pocket_wonders.reactions.play("delight" if playful else "discovery",at)
    scene.pocket_wonders.reactions.advance(.2)
    scene.pocket_wonders_art.clock=4.6 if playful else 1.1
    scene._sync_native_visuals()
    examined_kinds[String(profile.get("kind",""))]=true
    return profile

func phone(scene,index: int) -> void:
    root.content_scale_size=Vector2i(1400,960)
    root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(844,390)
    for i in range(4):await process_frame
    scene.simulated_touch=true;scene._on_viewport_resized();place(scene,index,true)
    var fixture: PresentationView=views[scene.get_instance_id()]
    var profile: Dictionary=scene.pocket_wonders.snapshot()["records"][index]["profile"]
    var label: String=String(profile.get("kind","wonder"))+"-chapter-"+str(scene._stage_index())
    await snap(scene,"phone-"+label)
    assert(scene.pocket_wonders_art.caption.visible,"phone wonder guidance stays readable beside its tableau")
    scene.reduced_fx=true;scene.native_rig.reduced_motion=true
    await snap(scene,"phone-gentle-"+label)
    assert(scene.pocket_wonders_art.caption.visible,"Gentle Motion retains phone guidance")
    scene.reduced_fx=false;scene.native_rig.reduced_motion=false;fixture.force_quiet=false
    root.size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
    for i in range(4):await process_frame
    scene.simulated_touch=false;scene._on_viewport_resized()

func capture_menu() -> void:
    var menu=load("res://godot/title_screen.tscn").instantiate();root.add_child(menu)
    menu.set_process(false);menu.show_page("menu")
    if menu.reveal_tween:menu.reveal_tween.kill()
    menu.content.modulate.a=1;menu._process(2.5)
    for i in range(5):await process_frame;await RenderingServer.frame_post_draw
    assert(root.get_texture().get_image().save_png(output+"/pocketful-menu.png")==OK)
    pictures.append("pocketful-menu");root.remove_child(menu);menu.free()

func run() -> void:
    Engine.time_scale=0;root.size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
    var prefs=root.get_node("AppPreferences")
    prefs.persist_enabled=false;prefs.economy=false;prefs.reduced_motion=false;prefs.intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false
    root.get_node("AdventureRun").active=false;root.get_node("AdventureRun").avina_along=true
    var selected:=OS.get_environment("ADVENTURE_AUDIT_CASE")
    var phone_kinds: Dictionary={}
    for chapter in range(8):
        if not selected.is_empty() and selected!=str(chapter):continue
        var scene=world(chapter)
        var records: Array=scene.pocket_wonders.snapshot().get("records",[])
        assert(records.size()==2,"each chapter owns two wonder stations")
        for index in range(records.size()):
            var profile:=place(scene,index,false)
            var kind:=String(profile.get("kind","wonder"))
            var name: String="chapter-"+str(chapter)+"-station-"+str(index)+"-"+kind
            await snap(scene,name+"-invitation")
            place(scene,index,true);await snap(scene,name+"-playful")
            if not phone_kinds.has(kind):
                await phone(scene,index);phone_kinds[kind]=true
            if kind=="mirror" and views[scene.get_instance_id()].partner!="fish":
                var fixture: PresentationView=views[scene.get_instance_id()]
                fixture.partner="fish"
                if is_instance_valid(scene.avina):scene.avina.hide()
                await snap(scene,name+"-solo-fish")
                fixture.partner="avina"
                if is_instance_valid(scene.avina):scene.avina.show()
        if chapter in [0,1]:
            place(scene,0,true)
            var fixture: PresentationView=views[scene.get_instance_id()]
            fixture.force_quiet=true
            if chapter==0:scene.state="paused"
            await snap(scene,"paused-quiet" if chapter==0 else "combat-quiet-fixture")
            assert(not scene.pocket_wonders_art.caption.visible,"quiet play hides wonder guidance")
        views.erase(scene.get_instance_id());await retire(scene)
    await capture_menu()
    var file:=FileAccess.open(output+"/visual-review.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"pictures":pictures,"count":pictures.size(),"kinds":examined_kinds.keys(),
        "caption_review":caption_review,"quality":"full, except explicitly named Gentle Motion views",
        "fixture":"Read-only presentation stages; gameplay/awards/saves verified by native integration suites.",
        "renderer":RenderingServer.get_video_adapter_name()},"  "));file.close()
    print("POCKET WONDERS VISUAL AUDIT COMPLETE ",pictures.size());quit()

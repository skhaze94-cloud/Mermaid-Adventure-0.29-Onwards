extends "res://godot/tools/opal_visual_audit.gd"
## Native full-quality inspection. Fixture states do not replace gameplay tests.
func snap(scene,name: String) -> void:
    if is_instance_valid(scene.avina):scene.avina.tick(0)
    if scene.native_rig.gesture_player.is_playing():scene.native_rig.gesture_player.advance(.4)
    await super.snap(scene,name)
func world(index: int):
    var scene=setup(root.get_node("AdventureRun").SCENES[index])
    scene.enemies.clear();scene.animated_enemies.bind_enemies(scene.enemies)
    if index==6:scene.boss_hp=0
    if index==7:
        scene.lesson=10;scene.boss_hp=0;scene.dialogue_open=false
        scene.lesson_card.hide();scene.dialogue_card.hide();scene.choice_card.hide()
    var reef=scene.living_reef
    scene.player=reef.profile["at"]+Vector2(-110,90)
    scene.camera=scene.player.x-550;scene.player_velocity=Vector2(80,0)
    if is_instance_valid(scene.avina):
        scene.avina.reset_follow();scene.avina.speech_time=0;scene.avina.tick(0)
    scene.native_rig.reset_performance();scene.native_rig.set_motion(Vector2(80,0),1,false,false,1)
    reef.state="active";reef.reactions.react("discovery",reef.profile["at"])
    reef.reactions.advance(.2);scene.living_reef_art.advance(2.3)
    scene._sync_native_visuals()
    return scene

func partial(scene) -> void:
    var reef=scene.living_reef
    reef.activated.assign([true,false,false]);reef.progress=1
    if reef.profile["kind"]=="guide":reef.actor=reef.profile["points"][0]
    elif reef.profile["kind"]=="current":scene.player=reef.profile["points"][1]+Vector2(-100,50)
    scene.camera=scene.player.x-550
    scene.living_reef_art.advance(.6)

func completed(scene) -> void:
    var reef=scene.living_reef
    reef.activated.assign([true,true,true]);reef.progress=3;reef.completed=true;reef.state="complete";reef.glow_time=2
    reef.actor=reef.profile["home"];scene.player=reef.profile["home"]+Vector2(-140,60)
    scene.camera=scene.player.x-550;scene.native_rig.reset_performance()
    if is_instance_valid(scene.avina):scene.avina.reset_follow();scene.avina.speech_time=0;scene.avina.tick(0)
    reef.reactions.clear();reef.reactions.react("complete",reef.profile["home"]);reef.reactions.advance(.4)
    scene.living_reef_art.advance(.5)

func run() -> void:
    Engine.time_scale=0;root.size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.economy=false;prefs.reduced_motion=false;prefs.intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false;root.get_node("AdventureRun").active=false;root.get_node("AdventureRun").avina_along=true
    for index in range(8):
        var selected:=OS.get_environment("ADVENTURE_AUDIT_CASE")
        if not selected.is_empty() and selected!=str(index):continue
        var scene=world(index)
        await snap(scene,"chapter-"+str(index)+"-discovery")
        partial(scene);await snap(scene,"chapter-"+str(index)+"-progress")
        completed(scene);await snap(scene,"chapter-"+str(index)+"-complete")
        if index in [0,2,3,7]:
            root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(844,390)
            for i in range(4):await process_frame
            scene.simulated_touch=true;scene._on_viewport_resized()
            scene.living_reef.completed=false;scene.living_reef.state="active";scene.living_reef.progress=1;scene.living_reef.activated.assign([true,false,false])
            scene.living_reef.actor=scene.living_reef.profile["points"][0]
            scene.player=scene.living_reef.profile["points"][1]+Vector2(-80,60);scene.camera=scene.player.x-550
            await snap(scene,"phone-chapter-"+str(index))
            assert(scene.living_reef_art.caption.visible,"phone discovery keeps readable guidance clear of characters")
            scene.reduced_fx=true;scene.living_reef_art.advance(.8);await snap(scene,"phone-gentle-"+str(index))
            root.size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
            for i in range(4):await process_frame
        await retire(scene)
    var scene=world(1);scene.state="paused";await snap(scene,"paused-quiet");await retire(scene)
    scene=world(4);scene.enemies.append({"kind":"eel","x":scene.player.x+100,"y":scene.player.y,"bx":scene.player.x+100,"by":scene.player.y,"hp":3,"phase":0.,"dir":-1,"mode":"attack","mode_time":.3,"hit_cd":0.,"aim":Vector2.LEFT})
    scene.animated_enemies.bind_enemies(scene.enemies);await snap(scene,"combat-quiet");assert(not scene.living_reef_art.caption.visible);await retire(scene)
    var file:=FileAccess.open(output+"/visual-review.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"pictures":pictures,"count":pictures.size(),"quality":"full, including explicitly named Gentle Motion", "renderer":RenderingServer.get_video_adapter_name()},"  "));file.close()
    print("LIVING REEF VISUAL AUDIT COMPLETE ",pictures.size());quit()

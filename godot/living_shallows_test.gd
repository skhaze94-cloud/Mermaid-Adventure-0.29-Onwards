extends "res://godot/pocket_wonders_test.gd"
func run() -> void:
    root.size=Vector2i(1400,960)
    root.get_node("AppPreferences").persist_enabled=false
    root.get_node("OceanAudio").playback_enabled=false
    root.get_node("AdventureRun").active=false
    var scene=await create(0)
    scene.fallen=false;scene.player=Vector2(1510,756);scene.player_velocity=Vector2.ZERO;scene.camera=1090
    scene.living_reef.reactions.clear();scene.message_time=0
    var layer=scene.living_shallows
    layer.sync()
    check(layer.visible and layer.nori.visible,"opening helper and gardens are visible in Highland's first reach")
    var ledger: Dictionary=scene.score_book.checkpoint().duplicate(true)
    var player_before: Vector2=scene.player
    var checkpoint_before: float=scene.checkpoint
    var actions: Array=InputMap.get_actions()
    var node_count: int=layer.get_child_count()
    var texture_before: int=layer.texture_loads
    for i in range(600):layer.advance(1.0/60);layer.sync()
    check(layer.clock>9.9 and layer.openings[2]>.3,"nearby garden opens gradually as Sarah rests")
    check(layer.letter_on_ground==false or layer.cycle>=7,"postal timing has a deterministic dropped-letter interval")
    check(scene.player==player_before and scene.checkpoint==checkpoint_before,"scenery never moves Sarah or her checkpoint")
    check(scene.score_book.checkpoint()==ledger and InputMap.get_actions()==actions,"NPCs and flowers own no reward or input")
    check(layer.get_child_count()==node_count and layer.texture_loads==texture_before,"travelling does not create nodes or load new paintings")
    check(layer.nori.mesh.get_surface_count()==1 and layer.nori.mesh.surface_get_array_len(0)==841,"Nori uses one fixed articulated mesh")
    check(absf(layer.postal_offset(7)-layer.postal_offset(10))<.01,"Nori pauses to notice the dropped letter")
    check(layer.postal_offset(14)<layer.postal_offset(10),"Nori returns to retrieve his post")
    scene.reduced_fx=true;layer.sync();var tick: float=layer.clock
    layer.advance(.1);layer.sync()
    check(layer.clock==tick and float(layer.nori.paint.get_shader_parameter("movement"))==0,"Gentle Motion freezes puppet, particles and light clocks")
    scene.reduced_fx=false;layer.sync();layer.label_panel.show();paused=true
    scene._process(0);layer.advance(.1)
    check(layer.clock==tick,"pause freezes the independent scenery clock")
    check(not layer.label_panel.visible,"the actual host pause path hides Nori's greeting")
    paused=false;scene.fallen=true;layer.sync()
    check(not layer.visible,"waterfall departure hides the whole opening sanctuary")
    scene.fallen=false;scene.camera=10000;layer.sync()
    check(not layer.visible,"distant map sections do not draw the opening effects")
    scene.camera=1090;scene.retry_serial+=1;layer.sync();layer.advance(.1)
    check(layer.clock<=.1 and layer.last_retry==scene.retry_serial,"retry restarts the harmless postal routine")
    await dispose(scene)
    var other=await create(1)
    check(not is_instance_valid(other.living_shallows),"other chapters retain their original scene population")
    await dispose(other)
    print("LIVING SHALLOWS: ",checks," checks, ",failures," failures")
    quit(1 if failures else 0)

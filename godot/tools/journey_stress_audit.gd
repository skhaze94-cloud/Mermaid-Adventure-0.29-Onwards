extends "res://godot/tools/opal_stress_audit.gd"
## Eight chapter stress tour, retaining full quality and all original pool limits.
## Optional JOURNEY_EFFECTS_BASELINE compares an earlier effects script in-process.
var baseline_script: Script
var effects_comparisons := 0
var mismatches := 0
var mesh_shapes: Dictionary = {}
func snapshot(node: Node, rows: Array) -> void:
    if node is Node2D:
        var row: Array=[node.get_class(),node.visible,node.position,node.rotation,node.scale,node.modulate]
        if node is Sprite2D:
            var texture=node.texture
            row.append([texture.atlas.resource_path,texture.region] if texture is AtlasTexture else null)
        if node is MeshInstance2D and node.mesh:
            var id: int=node.mesh.get_instance_id()
            if not mesh_shapes.has(id):mesh_shapes[id]=hash(node.mesh.get_faces())
            row.append(mesh_shapes[id])
        if node.material is ShaderMaterial:
            row.append([node.material.shader.resource_path,node.material.get_shader_parameter("cell_uv"),node.material.get_shader_parameter("state"),node.material.get_shader_parameter("gentle")])
        rows.append(row)
    for child in node.get_children():snapshot(child,rows)
func fx_snapshot(fx: Node) -> Array:
    var rows: Array=[]
    # The root has a different script class/name, but every pooled child is authored identically.
    for child in fx.get_children():snapshot(child,rows)
    return rows
func stress_case(name: String, path: String) -> void:
    var selected:=OS.get_environment("ADVENTURE_AUDIT_CASE")
    if not selected.is_empty() and selected!=name:return
    seed(90125)
    var scene=load(path).instantiate();root.add_child(scene)
    scene.process_mode=Node.PROCESS_MODE_DISABLED;scene.music_player.stop()
    scene.invulnerable=10000;scene.fallen=true;scene.message_time=0
    scene.player=Vector2(scene._boss_home()-500,560);scene.camera=scene._boss_home()-850
    scene.bubble_unlocked=true;scene.player_velocity=Vector2(310,0)
    scene.enemies.clear()
    for i in range(6):
        var at:=Vector2(scene.camera+450+(i%3)*300,710+(i/3)*80)
        scene.enemies.append({"kind":KINDS[i],"x":at.x,"y":at.y,"bx":at.x,"by":at.y,"hp":4,"phase":float(i),"dir":-1,
            "mode":"attack" if i<2 else "windup" if i<4 else "patrol","mode_time":0.0,"cooldown":1.0,"hit_cd":0.0,"aim":Vector2.LEFT})
    scene.animated_enemies.bind_enemies(scene.enemies)
    if scene.get("lesson")!=null:
        scene.lesson=8;scene.dialogue_open=false;scene.dialogue_card.hide();scene.choice_card.hide()
        scene.king_world=scene.boss_position;scene.character_dt=1.0/60
    scene.opal.begin("audit");scene.opal.advance(1.35)
    scene.opal.refresh_targets();seed_shots(scene)
    var fx=scene.opal_fx
    var reference: Node2D
    if baseline_script:
        reference=baseline_script.new();scene.add_child(reference);reference.configure(scene._opal_art_chapter())
    var samples: Array[float]=[]
    var reference_samples: Array[float]=[]
    var objects_before: int=Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
    for frame in range(150):
        # Fill all twelve slots, not a lower-density approximation.
        if frame%8==0:
            for i in range(12):
                var at: Vector2=scene.player+Vector2(250+(i%4)*90,(i/4)*70)
                fx.impact(at,1+i%3,true)
                if reference:reference.impact(at,1+i%3,true)
        var delta:=1.0/60
        if reference and frame%2==0:
            var start:=Time.get_ticks_usec();reference.advance(delta);reference.sync(scene)
            if frame>=30:reference_samples.append((Time.get_ticks_usec()-start)/1000.0)
        var current_start:=Time.get_ticks_usec();fx.advance(delta);fx.sync(scene)
        if frame>=30:samples.append((Time.get_ticks_usec()-current_start)/1000.0)
        if reference and frame%2==1:
            var start:=Time.get_ticks_usec();reference.advance(delta);reference.sync(scene)
            if frame>=30:reference_samples.append((Time.get_ticks_usec()-start)/1000.0)
        if reference:
            effects_comparisons+=1
            if fx_snapshot(reference)!=fx_snapshot(fx):
                mismatches+=1
                if mismatches<3:push_error("Effects state differs: "+name+" frame "+str(frame))
        if frame%30==0:await process_frame
    var entry: Dictionary={"effects_update":stats(samples),"friendly_count":scene.bubble_shots.size(),"hostile_count":scene.hostile_shots.size(),
        "impact_cap":fx.impacts.size(),"peak_active_impacts":12,"live_enemies":6,"node_delta":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))-objects_before}
    if reference:entry["baseline_effects_update"]=stats(reference_samples)
    report[name]=entry
    print("AUDIT JOURNEY ",name," ",JSON.stringify(entry))
    if reference:reference.queue_free()
    root.remove_child(scene);scene.free()
    for i in range(3):await process_frame
func run() -> void:
    Engine.time_scale=0;root.size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true;prefs.economy=false;prefs.reduced_motion=false
    root.get_node("OceanAudio").playback_enabled=false;root.get_node("AdventureRun").avina_along=false
    var baseline:=OS.get_environment("JOURNEY_EFFECTS_BASELINE")
    if not baseline.is_empty():baseline_script=load(baseline)
    report["environment"]={"engine":Engine.get_version_info().string,"display":DisplayServer.get_name(),"quality":"full",
        "scope":"Effects sync and twelve pooled impacts; update CPU only, no hardware FPS inference","warmup_frames":30,"measured_frames":120,
        "friendly":8,"hostile":32,"live_enemies":6,"impact_cap":12,"alternating_baseline_order":baseline_script!=null}
    var catalog=root.get_node("AdventureRun")
    for i in range(catalog.SCENES.size()):await stress_case(["highland","shadow","miguel","blackwater","palace","rana","nessie","training"][i],catalog.SCENES[i])
    report["equivalence"]={"compared_states":effects_comparisons,"mismatches":mismatches}
    var file:=FileAccess.open(output+"/results.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
    print("JOURNEY STRESS AUDIT COMPLETE: ",effects_comparisons," compared states, ",mismatches," mismatches")
    quit(1 if mismatches else 0)

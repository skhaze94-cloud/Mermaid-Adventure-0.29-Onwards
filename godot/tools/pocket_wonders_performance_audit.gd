extends "res://godot/tools/performance_audit.gd"
## Same-scene art-only visibility/quiet comparisons. Shared-host software-render
## timings diagnose components; they do not certify physical-device frame rate.
class PresentationView extends RefCounted:
    var model: RefCounted
    var chosen := 0
    var force_quiet := false
    var pair := false
    func snapshot() -> Dictionary:
        var result: Dictionary=model.call("snapshot").duplicate()
        var original: Array=result.get("records",[])
        var copied: Array=[]
        for i in range(original.size()):
            var record: Dictionary=original[i].duplicate()
            record["visible"]=true;record["nearby"]=i==chosen or pair
            record["quiet"]=force_quiet;record["state"]="playing"
            record["phase"]=4;record["timer"]=.65;record["elapsed"]=4.8
            record["progress"]=2;record["completed"]=false;record["glow_time"]=1.2
            var profile: Dictionary=record.get("profile",{})
            if pair and i!=chosen:
                profile=profile.duplicate()
                var old_at: Vector2=profile.get("at",Vector2.ZERO)
                var main: Vector2=original[chosen].get("profile",{}).get("at",Vector2.ZERO)
                var at:=main+Vector2(350,0)
                profile["at"]=at
                profile["prop_at"]=Vector2(profile.get("prop_at",old_at))+(at-old_at)
                record["profile"]=profile
            record["focus"]=profile.get("at",Vector2.ZERO)
            record["active_hint"]=String(profile.get("discovery_line","A little reef wonder."))
            copied.append(record)
        result["records"]=copied;result["quiet"]=force_quiet;result["visible"]=true
        if chosen<copied.size():
            var anchor: Vector2=copied[chosen].get("profile",{}).get("at",Vector2.ZERO)
            result["mirror"]={"active":true,"kind":"bubble_game","phase":4,"phase_time":.65,
                "phase_progress":.65,"partner":"avina","anchor":anchor,"at":anchor,
                "hero":anchor+Vector2(-190,55),"partner_at":anchor+Vector2(-270,90),
                "fish_at":anchor+Vector2(120,-78),"bubble_owner":"passing_fish","fish_mood":"surprised","gentle":false}
        result["has_baby"]=true
        return result

var checks := 0
var failures := 0
const CHAPTERS := {"dream":0,"tea":0,"village":1,"mirror":2,"post":1}

func verify(ok: bool,note: String) -> void:
    checks+=1
    if not ok:
        failures+=1;push_error("POCKET WONDERS PERFORMANCE: "+note)

func memory() -> Dictionary:
    return {"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
        "resources":int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
        "texture_bytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))}

func identities(values: Dictionary) -> Dictionary:
    var result: Dictionary={}
    for key in values:
        var value: Variant=values[key]
        result[key]=value.get_instance_id() if is_instance_valid(value) else null
    return result

func counts(values: Array[float]) -> Dictionary:
    values.sort();var total:=0.0
    for value in values:total+=value
    return {"mean":total/values.size(),"median":values[values.size()/2],"p95":values[mini(values.size()-1,int(values.size()*.95))]}

func sample(scene: Node2D,shown: bool,count: int,warmup: int) -> Dictionary:
    var art=scene.pocket_wonders_art
    var draws: Array[float]=[];var frames: Array[float]=[]
    var syncs: Array[float]=[];var builds: Array[float]=[]
    var uploads_before: int=art.batch_updates
    var overflow_before: int=art.batch_overflows
    for frame in range(count):
        var started:=Time.get_ticks_usec();var sync_started:=started
        art.sync();var sync_ms: float=(Time.get_ticks_usec()-sync_started)/1000.0
        art.visible=shown and art.active;art.last_build_us=0
        art.queue_redraw();scene.queue_redraw()
        await process_frame
        if rendered:await RenderingServer.frame_post_draw
        if frame>=warmup:
            draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
            frames.append((Time.get_ticks_usec()-started)/1000.0)
            syncs.append(sync_ms);builds.append(float(art.last_build_us)/1000.0)
        verify(art.batch_overflows==overflow_before,"stream never overflows")
        verify(art.batch_used<=art.BATCH_VERTEX_CAP,"vertex count stays within fixed capacity")
        verify(art.visible_count<=art.VISIBLE_CAP,"visible station capacity stays bounded")
    return {"draw_calls":counts(draws),"frame":stats(frames),"snapshot_and_sync":stats(syncs),
        "geometry_build_and_upload":stats(builds),"mesh_uploads":int(art.batch_updates)-uploads_before,
        "batch_used":art.batch_used,"batch_peak":art.batch_peak_used,"visible_count":art.visible_count,"memory":memory()}

func prepare_scene(chapter: int):
    var scene=load(root.get_node("AdventureRun").SCENES[chapter]).instantiate();root.add_child(scene)
    var calls: Array[Node]=[];var animations: Array[AnimationPlayer]=[]
    freeze(scene,calls,animations)
    for i in range(4):await process_frame
    scene.music_player.stop();scene.fallen=true;scene.time=4;scene.message_time=0
    scene.player_velocity=Vector2.ZERO;scene.touch_vectors.clear();scene.boost_time=0;scene.opal.cancel()
    scene.living_reef.clear_transients();scene.whimsy_moments.clear()
    if chapter==6:scene.boss_hp=0
    if chapter==7:
        scene.lesson=10;scene.boss_hp=0;scene.dialogue_open=false;scene.playing_daddy=false
        scene.lesson_card.hide();scene.dialogue_card.hide();scene.choice_card.hide()
        if not is_instance_valid(scene.avina):
            scene.avina=load("res://godot/avina_companion.gd").new();scene.add_child(scene.avina);scene.avina.bind(scene)
        scene.avina.follow_enabled=true
    return scene

func case_run(kind: String) -> void:
    seed(90125)
    var chapter:=int(CHAPTERS[kind]);var scene=await prepare_scene(chapter)
    var model=scene.pocket_wonders;var art=scene.pocket_wonders_art
    var rows: Array=model.snapshot().get("records",[])
    var selected:=-1
    for i in range(rows.size()):
        if rows[i].get("profile",{}).get("kind","")==kind:selected=i;break
    verify(selected>=0,"representative chapter contains "+kind)
    if selected<0:scene.free();return
    var profile: Dictionary=rows[selected].get("profile",{})
    var at: Vector2=profile.get("at",Vector2.ZERO)
    var at_bind:=memory()
    var loads_at_bind: int=art.texture_load_count
    var source_ids:=identities(art.source_textures);var atlas_ids:=identities(art.textures)
    var loaded_all:=not source_ids.is_empty()
    for key in source_ids:
        if source_ids[key]==null:loaded_all=false
    verify(loaded_all,"selected kind's painted resources exist at scene bind")
    var mesh_id: int=art.batch_mesh.get_instance_id()
    var presentation:=PresentationView.new();presentation.model=model;presentation.chosen=selected
    art.bind(scene,presentation)
    verify(art.texture_load_count==loads_at_bind,"fixture binding reuses preloaded textures")
    scene.player=at+Vector2(-190,65);scene.camera=scene.player.x-550
    scene._sync_native_visuals();art.clock=4.6
    for i in range(6):
        art.sync();art.queue_redraw();await process_frame
        if rendered:await RenderingServer.frame_post_draw
    verify(art.active,"nearby "+kind+" art is active")
    var before:=memory()
    var count:=6 if quick else 12;var warmup:=2 if quick else 4
    var normal: Array[Dictionary]=[]
    var order: Array=[false,true,true,false] if chapter%2==0 else [true,false,false,true]
    for shown in order:normal.append({"shown":shown,"sample":await sample(scene,bool(shown),count,warmup)})
    var after_approach:=memory()
    verify(art.texture_load_count==loads_at_bind,"approach creates no late texture loads")
    verify(identities(art.source_textures)==source_ids and identities(art.textures)==atlas_ids,"texture and atlas identities remain stable on approach")
    presentation.force_quiet=true;art.sync()
    verify(not art.caption.visible,"quiet play removes optional hint")
    var quiet: Array[Dictionary]=[]
    for shown in [false,true]:quiet.append({"shown":shown,"sample":await sample(scene,shown,count,warmup)})
    presentation.force_quiet=false
    scene.player=Vector2(350,600);scene.camera=0;scene._sync_native_visuals();art.sync()
    verify(not art.active and not art.visible,"all chapter stations cull outside the entrance view")
    var cull_uploads: int=art.batch_updates
    var offscreen: Array[Dictionary]=[]
    for shown in [false,true]:offscreen.append({"shown":shown,"sample":await sample(scene,shown,count,warmup)})
    verify(art.batch_updates==cull_uploads and art.last_build_us==0,"offscreen art builds and uploads no geometry")
    var after:=memory()
    verify(int(after["nodes"])==int(before["nodes"]),"play/quiet/offscreen modes create no scene nodes")
    verify(int(after["resources"])==int(before["resources"]),"play/quiet/offscreen modes create no Resources")
    verify(art.batch_mesh.get_instance_id()==mesh_id and art.batch_mesh.get_surface_count()==1,"one persistent dynamic surface")
    verify(art.batch_vertices.size()==art.BATCH_VERTEX_CAP and art.batch_colours.size()==art.BATCH_VERTEX_CAP*4,"stream storage remains fixed")
    verify(art.batch_overflows==0,"all stages fit within the fixed stream")
    report[kind]={"chapter":chapter,"profile_id":profile.get("id",""),"textures_loaded_at_bind":loaded_all,
        "texture_identity_unchanged":identities(art.source_textures)==source_ids and identities(art.textures)==atlas_ids,
        "texture_loads_at_bind":loads_at_bind,"at_bind_memory":at_bind,"after_approach_memory":after_approach,
        "node_growth":int(after["nodes"])-int(before["nodes"]),"resource_growth":int(after["resources"])-int(before["resources"]),
        "vertex_cap":art.BATCH_VERTEX_CAP,"peak_vertices":art.batch_peak_used,"overflows":art.batch_overflows,
        "normal":normal,"quiet":quiet,"offscreen":offscreen}
    print("AUDIT POCKET WONDERS ",kind," ",JSON.stringify(report[kind]))
    root.remove_child(scene);scene.free()
    for i in range(3):await process_frame

func pair_run() -> void:
    var scene=await prepare_scene(0);var art=scene.pocket_wonders_art
    var fixture:=PresentationView.new();fixture.model=scene.pocket_wonders;fixture.pair=true
    art.bind(scene,fixture)
    var at: Vector2=scene.pocket_wonders.snapshot()["records"][0]["profile"]["at"]
    scene.player=at+Vector2(-190,65);scene.camera=scene.player.x-450
    scene._sync_native_visuals();art.clock=4.6
    var result:=await sample(scene,true,8,3)
    verify(art.visible_count==2,"two nearby tableaux use the two-station presentation cap")
    verify(art.batch_overflows==0,"two-station flourish fits the shared stream")
    report["two_station_fixture"]={"sample":result,"overflows":art.batch_overflows,"vertex_cap":art.BATCH_VERTEX_CAP,
        "note":"Authored chapter paintings shifted together in a read-only presentation fixture; does not alter gameplay locations."}
    root.remove_child(scene);scene.free()
    for i in range(3):await process_frame

func run() -> void:
    Engine.time_scale=0;root.size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
    if rendered:DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
    var prefs=root.get_node("AppPreferences")
    prefs.persist_enabled=false;prefs.economy=false;prefs.reduced_motion=false;prefs.intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false
    root.get_node("AdventureRun").active=false;root.get_node("AdventureRun").avina_along=true
    report["environment"]={"engine":Engine.get_version_info().string,"adapter":RenderingServer.get_video_adapter_name(),
        "display":DisplayServer.get_name(),"resolution":[1400,960],"quality":"full","fixture_clock":4.6,
        "scope":"Frozen same-scene art-only comparisons. Snapshot/sync and actual draw build/upload measured separately; no physical-device FPS claim.",
        "memory_note":"At-bind-to-approach raw texture counters may change with font caches. Stable resource identities and no late loads are checked separately.",
        "frames_per_block":6 if quick else 12,"warmup_frames":2 if quick else 4,"ordering":"ABBA/BAAB"}
    var selected:=OS.get_environment("ADVENTURE_AUDIT_CASE")
    for kind in CHAPTERS:
        if selected.is_empty() or selected==kind:await case_run(String(kind))
    if selected.is_empty() or selected=="pair":await pair_run()
    report["checks"]={"count":checks,"failures":failures}
    var file:=FileAccess.open(output+"/results.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "));file.close()
    print("POCKET WONDERS PERFORMANCE AUDIT COMPLETE: ",checks," checks, ",failures," failures")
    quit(1 if failures else 0)

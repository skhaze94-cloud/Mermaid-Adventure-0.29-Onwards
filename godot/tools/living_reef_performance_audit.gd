extends "res://godot/tools/performance_audit.gd"
## Same-scene visible/hidden activity presentation. This is a software-renderer
## diagnostic, not a device FPS claim or a human gameplay/balance playthrough.
class PresentationView extends RefCounted:
    var model: RefCounted
    var force_quiet:=false
    func snapshot() -> Dictionary:
        var result: Dictionary=model.call("snapshot").duplicate()
        if force_quiet:result["quiet"]=true
        return result

var checks:=0
var failures:=0
func verify(ok: bool, note: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error("LIVING REEF PERFORMANCE: "+note)

func memory() -> Dictionary:
    return {"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
        "resources":int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
        "texture_bytes":int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))}

func counts(values: Array[float]) -> Dictionary:
    values.sort()
    var total:=0.0
    for value in values:total+=value
    return {"mean":total/values.size(),"median":values[values.size()/2],"p95":values[mini(values.size()-1,int(values.size()*.95))]}

func sample(scene: Node2D, shown: bool, count: int, warmup: int) -> Dictionary:
    var art=scene.living_reef_art
    var draws: Array[float]=[]
    var frames: Array[float]=[]
    var syncs: Array[float]=[]
    var builds: Array[float]=[]
    var before_updates: int=art.batch_updates
    var before_overflows: int=art.batch_overflows
    for frame in range(count):
        var started:=Time.get_ticks_usec()
        var sync_start:=Time.get_ticks_usec()
        art.sync()
        var sync_ms: float=(Time.get_ticks_usec()-sync_start)/1000.0
        art.visible=shown and art.active
        art.last_build_us=0
        art.queue_redraw();scene.queue_redraw()
        await process_frame
        if rendered:await RenderingServer.frame_post_draw
        if frame>=warmup:
            draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
            frames.append((Time.get_ticks_usec()-started)/1000.0)
            syncs.append(sync_ms)
            builds.append(float(art.last_build_us)/1000.0)
        verify(art.batch_overflows==before_overflows,"stream must not overflow")
        verify(art.batch_used<=art.BATCH_VERTEX_CAP,"stream vertex capacity")
    return {"draw_calls":counts(draws),"frame":stats(frames),"snapshot_and_sync":stats(syncs),
        "geometry_build_and_upload":stats(builds),"mesh_uploads":int(art.batch_updates)-before_updates,
        "batch_used":art.batch_used,"batch_peak":art.batch_peak_used,"memory":memory()}

func case_run(index: int) -> void:
    seed(90125)
    var scene=load(root.get_node("AdventureRun").SCENES[index]).instantiate()
    root.add_child(scene)
    var calls: Array[Node]=[];var animations: Array[AnimationPlayer]=[]
    freeze(scene,calls,animations)
    for i in range(4):await process_frame
    scene.music_player.stop();scene.fallen=true;scene.time=4
    if index==6:scene.boss_hp=0
    if index==7:
        scene.lesson=10;scene.boss_hp=0;scene.dialogue_open=false
        scene.lesson_card.hide();scene.dialogue_card.hide();scene.choice_card.hide()
    var reef=scene.living_reef
    var art=scene.living_reef_art
    var profile: Dictionary=reef.profile
    verify(not profile.is_empty(),"selected chapter has activity")
    var guide_before: int=-1 if art.guide_texture==null else art.guide_texture.get_instance_id()
    var loaded_at_bind: bool=art.guide_texture!=null
    var bind_memory:=memory()
    var mesh_id: int=art.batch_mesh.get_instance_id()
    # Read-only wrapper controls only the art's quiet fixture. Gameplay/combat
    # is deliberately frozen; no enemy or original visual quality is changed.
    var presentation:=PresentationView.new();presentation.model=reef
    art.bind(scene,presentation)
    var nodes_before: int=Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
    var identity_after_bind: int=-1 if art.guide_texture==null else art.guide_texture.get_instance_id()
    verify(identity_after_bind==guide_before,"probe binding reuses preloaded guide art")
    reef.state="active";reef.progress=1;reef.activated.assign([true,false,false]);reef.completed=false;reef.glow_time=0
    reef.actor=profile["at"]
    scene.player=Vector2(profile["at"])+Vector2(-100,60);scene.camera=scene.player.x-550
    scene._sync_native_visuals();art.clock=2.3;art.sync()
    verify(art.active,"nearby activity art is active")
    var count:=8 if quick else 16
    var warmup:=3 if quick else 5
    var quiet: Array[Dictionary]=[]
    # ABBA / BAAB ordering reduces a single ordering trend without pretending
    # shared-host scheduling/llvmpipe is stable enough to certify FPS.
    var order: Array=[false,true,true,false] if index%2==0 else [true,false,false,true]
    for shown in order:
        quiet.append({"shown":shown,"sample":await sample(scene,bool(shown),count,warmup)})
    var after_approach:=memory()
    var guide_after: int=-1 if art.guide_texture==null else art.guide_texture.get_instance_id()
    verify(guide_after==guide_before,"approach does not load another guide texture")
    if profile["kind"]=="guide":verify(loaded_at_bind,"guide artwork loaded before approach")
    else:verify(not loaded_at_bind,"non-guide chapters do not load guide artwork")
    # Quiet-combat presentation is an explicit snapshot fixture, keeping the
    # rest of this exact scene unchanged for an interpretable art-only delta.
    presentation.force_quiet=true;art.sync()
    verify(art.quiet and not art.caption.visible,"quiet fixture removes activity hint")
    var combat: Array[Dictionary]=[]
    for shown in [false,true]:combat.append({"shown":shown,"sample":await sample(scene,shown,count,warmup)})
    presentation.force_quiet=false
    # Camera at the real chapter entrance makes every selected activity lie
    # outside camera±250. This phase checks culling, not a different map's FPS.
    scene.player=Vector2(350,600);scene.camera=0;scene._sync_native_visuals();art.sync()
    verify(not art.active and not art.visible,"offscreen activity entirely culled")
    var before_cull_updates: int=art.batch_updates
    var offscreen: Array[Dictionary]=[]
    for shown in [false,true]:offscreen.append({"shown":shown,"sample":await sample(scene,shown,count,warmup)})
    verify(art.batch_updates==before_cull_updates,"offscreen art does no mesh uploads")
    verify(art.last_build_us==0,"offscreen art reports no build work")
    verify(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))==nodes_before,"approach/modes create no scene nodes")
    verify(art.batch_mesh.get_instance_id()==mesh_id and art.batch_mesh.get_surface_count()==1,"one persistent dynamic surface")
    verify(art.batch_vertices.size()==art.BATCH_VERTEX_CAP and art.batch_colours.size()==art.BATCH_VERTEX_CAP*4,"stream buffers remain fixed")
    verify(art.batch_overflows==0,"all presentation states fit fixed capacity")
    var row: Dictionary={"chapter":index,"kind":profile["kind"],"guide_loaded_at_bind":loaded_at_bind,
        "guide_texture_identity_unchanged":guide_after==guide_before,"at_bind_memory":bind_memory,
        "after_approach_memory":after_approach,"node_growth":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))-nodes_before,
        "vertex_cap":art.BATCH_VERTEX_CAP,"peak_vertices":art.batch_peak_used,"overflows":art.batch_overflows,
        "quiet":quiet,"quiet_combat_fixture":combat,"offscreen":offscreen}
    report[str(index)]=row
    print("AUDIT LIVING REEF ",index," ",JSON.stringify(row))
    root.remove_child(scene);scene.free()
    for i in range(3):await process_frame

func run() -> void:
    Engine.time_scale=0;root.size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
    if rendered:DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
    var prefs=root.get_node("AppPreferences")
    prefs.persist_enabled=false;prefs.economy=false;prefs.reduced_motion=false;prefs.intro_seen=true
    root.get_node("OceanAudio").playback_enabled=false
    var run_state=root.get_node("AdventureRun");run_state.active=false;run_state.avina_along=false
    report["environment"]={"engine":Engine.get_version_info().string,"adapter":RenderingServer.get_video_adapter_name(),
        "display":DisplayServer.get_name(),"resolution":[1400,960],"quality":"full","fixture_clock":2.3,
        "scope":"Same frozen native scene, changing only Living Reef art visibility/quiet snapshot. CPU includes its sync and actual draw geometry/upload separately. No device FPS claim.",
        "guide_check":"Selected guide resource must exist at scene bind and retain identical instance identity on approach. Other chapters keep it unloaded.",
        "memory_note":"Raw texture/resource counters can also reflect native font glyph caches; guide identity is checked independently.",
        "quiet_combat_note":"Presentation snapshot fixture; actual gameplay quiet/combat integration is covered by the activity suite.",
        "frames_per_block":8 if quick else 16,"warmup_frames":3 if quick else 5,"ordering":"ABBA for even chapters, BAAB for odd chapters"}
    var selected:=OS.get_environment("ADVENTURE_AUDIT_CASE")
    var indices: Array=[0,2,3] if selected.is_empty() else [int(selected)]
    for index in indices:await case_run(int(index))
    report["checks"]={"count":checks,"failures":failures}
    var file:=FileAccess.open(output+"/results.json",FileAccess.WRITE)
    file.store_string(JSON.stringify(report,"  "));file.close()
    print("LIVING REEF PERFORMANCE AUDIT COMPLETE: ",checks," checks, ",failures," failures")
    quit(1 if failures else 0)

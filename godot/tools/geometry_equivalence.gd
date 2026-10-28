extends SceneTree
## Compare unchanged poses/UVs/topology against a separately checked-out baseline.
## Generate with ADVENTURE_GEOMETRY_WRITE=1; otherwise compare the same fixture.
var failures := 0
var maximum_error := 0.0
var compared_points := 0
var states := 0
var fixture: FileAccess
var writing := false

func _initialize() -> void: call_deferred("run")

func snapshot(rig, name: String) -> void:
    var current := {}
    for part in rig.painted_parts:
        if not (part is Polygon2D or part is MeshInstance2D): continue
        current[String(part.name)] = {"points":part.polygon,"uv":hash(part.uv),"topology":hash(part.polygons),"transform":part.global_transform}
    if writing:
        fixture.store_var({"name":name,"parts":current})
    else:
        var reference: Dictionary = fixture.get_var()
        assert(reference.name==name)
        for key in current:
            var before: Dictionary = reference.parts[key]
            var after: Dictionary = current[key]
            if before.uv!=after.uv or before.topology!=after.topology or before.points.size()!=after.points.size():
                failures+=1
                push_error(name+" / "+key+": painting or topology changed")
                continue
            for i in range(after.points.size()):
                var error: float = after.points[i].distance_to(before.points[i])
                maximum_error = maxf(maximum_error,error)
                compared_points+=1
                if error>.0001:
                    failures+=1
                    if failures<5: push_error(name+" / "+key+": geometry drift "+str(error))
            for point in [Vector2.ZERO,Vector2.RIGHT,Vector2.DOWN]:
                if (before.transform*point).distance_to(after.transform*point)>.0001:
                    failures+=1
                    push_error(name+" / "+key+": attachment transform changed")
    states+=1

func advance(rig, count: int) -> void:
    for frame in range(count):
        if rig.gesture_player.is_playing(): rig.gesture_player.advance(1.0/60)
        if rig.jump_player.is_playing(): rig.jump_player.advance(1.0/60)
        rig._process(1.0/60)

func reset(rig) -> void:
    rig.reset_jump()
    rig.reset_performance()
    rig.clock=0
    rig.swim_style_override=""
    rig.reduced_motion=false
    rig.set_quality(true)

func run() -> void:
    var path := OS.get_environment("ADVENTURE_GEOMETRY_FILE")
    assert(not path.is_empty())
    writing=OS.get_environment("ADVENTURE_GEOMETRY_WRITE")=="1"
    fixture=FileAccess.open_compressed(path,FileAccess.WRITE if writing else FileAccess.READ,FileAccess.COMPRESSION_ZSTD)
    assert(fixture!=null)
    root.get_node("AppPreferences").persist_enabled=false
    var rig = load("res://godot/sarah_rig.gd").new()
    rig.name="AuditSarah"
    root.add_child(rig)
    rig.process_mode=Node.PROCESS_MODE_DISABLED
    rig.position=Vector2(700,500)
    for direction in [1.0,-1.0]:
        for style in rig.SwimStyles.NAMES:
            reset(rig)
            rig.swim_style_override=style
            rig.set_waterfall_context("descent" if style.begins_with("waterfall") else "")
            rig.set_motion(Vector2(760 if style.begins_with("boost") else 310,45)*Vector2(direction,1),direction,style.begins_with("boost"),false,1)
            advance(rig,30)
            snapshot(rig,style+str(direction))
        for jump in range(18):
            for progress in [.24,.53,.80]:
                reset(rig)
                rig.jump_style_cursor=jump
                rig.set_motion(Vector2(310*direction,-180),direction,false,true,1)
                rig.start_jump(2,direction)
                rig.set_jump_state("airborne",progress*.88,2,direction)
                advance(rig,12)
                snapshot(rig,"jump-%s-%s-%s" % [jump,progress,direction])
        for gesture in ["greet","cast","celebrate","impact","reward"]:
            reset(rig)
            rig.set_motion(Vector2(150*direction,0),direction,false,false,1)
            rig.play_gesture(gesture)
            advance(rig,20)
            snapshot(rig,gesture+str(direction))
        for gentle in [true,false]:
            reset(rig)
            rig.set_motion(Vector2(760*direction,0),direction,true,false,1)
            advance(rig,10)
            if gentle: rig.reduced_motion=true
            else: rig.set_quality(false)
            advance(rig,1)
            snapshot(rig,"gentle-"+str(gentle)+str(direction))
    fixture.close()
    rig.free()
    var report := {"states":states,"points_compared":compared_points,"max_local_error_pixels":maximum_error,"tolerance_pixels":.0001,"failures":failures,"writing":writing}
    print("GEOMETRY EQUIVALENCE ",JSON.stringify(report))
    var out := OS.get_environment("ADVENTURE_GEOMETRY_REPORT")
    if not out.is_empty():
        var file := FileAccess.open(out,FileAccess.WRITE)
        file.store_string(JSON.stringify(report,"  "))
    quit(0 if failures==0 else 1)

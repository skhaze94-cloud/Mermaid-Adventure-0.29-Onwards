extends SceneTree
## Review the production skins, not an isolated mock arm.
const Styles = preload("res://godot/sarah_swim_styles.gd")
var checks := 0
var failures := 0
var images := {}
var opaque_triangles := {}
var min_area := {}
func check(ok: bool, why: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        if failures<12: push_error("SARAH ARMS: "+why)
func _initialize() -> void: call_deferred("run")
func prepare(mesh: Polygon2D) -> void:
    if not images.has(mesh.texture): images[mesh.texture]=mesh.texture.get_image()
    var image: Image = images[mesh.texture]
    var triangles := []
    for tri in mesh.polygons:
        var uv := (mesh.uv[tri[0]]+mesh.uv[tri[1]]+mesh.uv[tri[2]])/3.0
        if image.get_pixelv(Vector2i(uv)).a>.6: triangles.append(tri)
    opaque_triangles[mesh]=triangles
    min_area[mesh.name]=INF
func inspect(mesh: Polygon2D, context: String) -> void:
    for point in mesh.polygon: check(point.is_finite(),context+" invalid skin vertex")
    for tri in opaque_triangles[mesh]:
        var a: Vector2 = mesh.polygon[tri[0]]
        var b: Vector2 = mesh.polygon[tri[1]]
        var c: Vector2 = mesh.polygon[tri[2]]
        var r0: Vector2 = mesh.rest[tri[0]]
        var r1: Vector2 = mesh.rest[tri[1]]
        var r2: Vector2 = mesh.rest[tri[2]]
        var ratio := (b-a).cross(c-a)/(r1-r0).cross(r2-r0)
        min_area[mesh.name]=minf(min_area[mesh.name],ratio)
        check(ratio>.02,context+" painted triangle folds or collapses: "+str(mesh.name))
func alpha_at(mesh: Polygon2D, point: Vector2) -> float:
    var local := mesh.to_local(point)
    var image: Image = images[mesh.texture]
    for tri in mesh.polygons:
        var a: Vector2 = mesh.polygon[tri[0]]
        var b: Vector2 = mesh.polygon[tri[1]]
        var c: Vector2 = mesh.polygon[tri[2]]
        var area := (b-a).cross(c-a)
        if absf(area)<.00001: continue
        var u := (local-a).cross(c-a)/area
        var v := (b-a).cross(local-a)/area
        if u<0 or v<0 or u+v>1: continue
        var pixel: Vector2 = mesh.uv[tri[0]]*(1-u-v)+mesh.uv[tri[1]]*u+mesh.uv[tri[2]]*v
        return image.get_pixelv(Vector2i(pixel)).a
    return 0.0
func joins_and_face(rig, context: String) -> void:
    var waist: Vector2 = rig.torso.to_global(Vector2(18,4))
    check(alpha_at(rig.bodice,waist)>.7 and alpha_at(rig.tail_skin,waist)>.7,context+" waist paint separates")
    for i in range(2):
        var arm: Node2D = rig.far_arm if i==0 else rig.near_arm
        var shoulder: Vector2 = arm.to_global(Vector2(7,5))
        check(alpha_at(rig.bodice,shoulder)>.7 and alpha_at(rig.arm_meshes[i],shoulder)>.7,context+" sleeve paint separates")
        if arm.z_index<=rig.head_joint.z_index: continue
        for landmark in [Vector2(.71,.51),Vector2(.88,.455),Vector2(.83,.565),Vector2(.82,.67)]:
            var face: Vector2 = rig.face_details.to_global(landmark*Vector2(710,570))
            check(alpha_at(rig.arm_meshes[i],face)<.2,context+" front arm obscures face landmark")
func run() -> void:
    var rig = load("res://godot/sarah_rig.gd").new()
    root.add_child(rig)
    rig.set_process(false)
    rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.jump_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    var skins: Array = [rig.bodice,rig.tail_skin,rig.ribbons[0],rig.ribbons[1]]+rig.arm_meshes
    var original_uv := {}
    for mesh in skins:
        prepare(mesh)
        original_uv[mesh]=mesh.uv.duplicate()
    # The shader face grid is static on the CPU: validate its topology once.
    prepare(rig.face_details)
    inspect(rig.face_details,"static face topology")
    var ranges := {}
    for facing in [-1,1]:
        for style in Styles.NAMES:
            rig.reset_jump(); rig.reset_performance()
            rig.swim_style_override=style
            rig.set_waterfall_context("pull" if style.begins_with("waterfall") else "")
            rig.set_motion(Vector2(facing*345,-160 if style.begins_with("rise") else (160 if style.begins_with("dive") else 0)),facing,style.begins_with("boost") or style=="waterfall_surge",false,1)
            var low := Vector2(INF,INF)
            var high := Vector2(-INF,-INF)
            for frame in range(240):
                rig._process(1.0/60)
                var angle: Vector2 = rig.arm_dynamics.applied[1]
                low=low.min(angle); high=high.max(angle)
                for i in range(2):
                    check(absf(rig.arm_dynamics.applied[i].y)<.381,"Wrist beyond safe envelope")
                    check(rig.arm_dynamics.applied[i].x> -1.301,"Elbow beyond safe envelope")
                    var mesh: Polygon2D = rig.arm_meshes[i]
                    for point in range(mesh.rest.size()):
                        if (mesh.rest[point].x+5.0)/(88.0 if i==1 else 78.0)<=.34:
                            check(mesh.polygon[point]==mesh.rest[point],"Sleeve attachment drifts")
                joins_and_face(rig,style)
                if frame%12==0:
                    for mesh in skins:
                        inspect(mesh,style)
                        check(mesh.uv==original_uv[mesh],"Painting slides outside its crop")
            ranges[style]=high-low
            if not (style.begins_with("boost") or style=="waterfall_surge"):
                check(high.y-low.y>.16,style+" lacks wrist articulation")
    for facing in [-1,1]:
        for action in ["greet","cast","celebrate","impact","reward"]:
            rig.reset_jump(); rig.reset_performance(); rig.swim_style_override=""
            rig.set_waterfall_context(""); rig.set_motion(Vector2.ZERO,facing,false,false,1)
            rig.play_gesture(action)
            for frame in range(90):
                rig.gesture_player.advance(1.0/60); rig._process(1.0/60)
                joins_and_face(rig,action)
                if frame%12==0:
                    for mesh in skins: inspect(mesh,action)
        for style in range(18):
            rig.reset_jump(); rig.reset_performance(); rig.jump_style=style
            rig.set_motion(Vector2(facing*310,-120),facing,false,true,1)
            for frame in range(90):
                rig.set_jump_state("airborne",float(frame)/90*.88,style,facing)
                rig._process(1.0/60)
                joins_and_face(rig,"jump "+str(style))
                if frame%12==0:
                    for mesh in skins: inspect(mesh,"jump "+str(style))
    rig.reset_jump(); rig.reset_performance()
    rig.set_motion(Vector2(345,0),1,false,false,1)
    for frame in range(60): rig._process(1.0/60)
    rig.reduced_motion=true; rig._process(1.0/60)
    check(rig.arm_dynamics.applied==[Vector2.ZERO,Vector2.ZERO],"Gentle setting retains arm dynamics")
    for mesh in rig.arm_meshes: check(mesh.polygon==mesh.rest,"Gentle setting leaves bent skin")
    rig.reset_performance()
    check(rig.arm_dynamics.shoulder_speed==Vector2.ZERO,"Restart retains momentum")
    rig.reduced_motion=false
    var endpoints := []
    for fps in [30,60,120]:
        rig.reset_jump();rig.reset_performance()
        rig.swim_style_override="front_crawl"
        rig.set_waterfall_context("")
        rig.set_motion(Vector2(345,0),1,false,false,1)
        for frame in range(fps*3): rig._process(1.0/fps)
        endpoints.append(rig.arm_dynamics.applied[1])
    print("SARAH ARM REFRESH ENDPOINTS: ",endpoints)
    check(endpoints[0].distance_to(endpoints[2])<.04,"Joint follow-through differs across refresh rates")
    var held: Array = rig.arm_dynamics.applied.duplicate()
    rig._process(0.0)
    check(rig.arm_dynamics.applied==held,"Paused frame advances joint momentum")
    rig.set_quality(false);rig._process(1.0/60)
    check(rig.arm_dynamics.applied==[Vector2.ZERO,Vector2.ZERO],"Economy setting retains joint dynamics")
    for mesh in rig.arm_meshes: check(mesh.polygon==mesh.rest,"Economy setting leaves a bent skin")
    rig.set_quality(true)
    for fps in [30,60,120]:
        rig.reset_jump();rig.reset_performance();rig.swim_style_override=""
        for motion in [[Vector2(760,0),true],[Vector2(40,-330),false],[Vector2(40,330),false],[Vector2(-345,60),false],[Vector2.ZERO,false]]:
            rig.set_motion(motion[0],-1 if motion[0].x<0 else 1,motion[1],false,1)
            for frame in range(fps):
                var before: Vector2 = rig.arm_dynamics.applied[1]
                rig._process(1.0/fps)
                check(rig.arm_dynamics.applied[1].distance_to(before)<8.0/fps,"Abrupt input snaps a joint")
                if frame%12==0: joins_and_face(rig,"input transition")
    print("SARAH ARM AREA RATIOS: ",min_area)
    print("SARAH ARM JOINT RANGES: ",ranges)
    rig.free()
    print("SARAH ARM REVIEW: %d checks, %d failures" % [checks,failures])
    quit(0 if failures==0 else 1)

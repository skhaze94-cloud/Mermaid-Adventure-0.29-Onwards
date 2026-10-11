extends SceneTree
const Styles = preload("res://godot/sarah_swim_styles.gd")
var checks := 0
var failures := 0
func check(ok: bool, why: String) -> void:
    checks+=1
    if not ok:
        failures+=1
        push_error("SARAH V031: "+why)
func _initialize() -> void: call_deferred("run")
var images := {}
func alpha_at(part: Polygon2D, point: Vector2) -> float:
    var local := part.to_local(point)
    if not images.has(part.texture): images[part.texture] = part.texture.get_image()
    var source: Image = images[part.texture]
    for triangle in part.polygons:
        var a: Vector2 = part.polygon[triangle[0]]
        var b: Vector2 = part.polygon[triangle[1]]
        var c: Vector2 = part.polygon[triangle[2]]
        var area := (b-a).cross(c-a)
        if absf(area)<.00001: continue
        var u := (local-a).cross(c-a)/area
        var v := (b-a).cross(local-a)/area
        if u<-.0001 or v<-.0001 or u+v>1.0001: continue
        var pixel: Vector2 = part.uv[triangle[0]]*(1-u-v)+part.uv[triangle[1]]*u+part.uv[triangle[2]]*v
        return source.get_pixelv(Vector2i(pixel)).a
    return 0.0
func run() -> void:
    var prefs = root.get_node("AppPreferences")
    prefs.persist_enabled=false
    prefs.reduced_motion=false; prefs.economy=false; prefs.intro_seen=true
    for cycle in range(21):
        var stroke := Styles.choose(280,0,(cycle+.4)*TAU,false,"")
        check((stroke=="breaststroke")==((cycle%7) in [2,6]),"Breaststroke must follow two then three ordinary strokes")
    check(Styles.choose(760,0,TAU*2.4,true,"")!="breaststroke","Cadence overrides boost")
    check(Styles.choose(280,-330,TAU*2.4,false,"")!="breaststroke","Cadence overrides ascent")
    check(Styles.choose(280,0,TAU*2.4,false,"pull")=="waterfall_scull","Cadence overrides waterfall balancing")
    var rig = load("res://godot/sarah_rig.gd").new()
    root.add_child(rig);rig.set_process(false);rig.reset_performance()
    check(rig.ribbons[0].rest.size()==255 and rig.ribbons[1].rest.size()==255,"Hair points have not tripled")
    check(rig.face_details.rest.size()==9555 and rig.tail_skin.rest.size()==2535,"Crown or tail points have not tripled")
    rig.set_motion(Vector2(280,0),1,false,false,1)
    var seen := {}
    var entries := 0
    var last := ""
    var cup_range := Vector2(INF,-INF)
    for frame in range(1200):
        rig._process(1.0/60)
        seen[rig.swim_style]=true
        if rig.swim_style=="breaststroke" and last!="breaststroke": entries+=1
        last=rig.swim_style
        var cup: float = rig.arm_dynamics.cups[1].x
        cup_range.x=minf(cup_range.x,cup);cup_range.y=maxf(cup_range.y,cup)
        check(absf(cup)<.145,"Hand cup outside safe envelope")
        for i in range(2):
            var joint: Node2D = rig.far_arm if i==0 else rig.near_arm
            var mapping: Transform2D = rig.torso_motion.rib_transform.affine_inverse()*joint.transform
            var material: ShaderMaterial = rig.arm_meshes[i].material
            check(material.get_shader_parameter("arm_origin").distance_to(mapping.origin)<.0001,"Sleeve blend misses moving shoulder")
    check(seen.has("front_crawl") and entries>=4,"Actual gameplay lacks recurring breaststroke")
    check(cup_range.y-cup_range.x>.05,"Painted hands do not cup and release")
    check(rig.bodice.material.get_shader_parameter("join_tail_paint")==rig.NEW_TAIL,"Waist blend does not reference actual tail painting")
    rig.set_motion(Vector2(760,0),1,true,false,1)
    for frame in range(90): rig._process(1.0/60)
    var held: float = rig.horizontal_stroke_clock
    for frame in range(60): rig._process(1.0/60)
    check(is_equal_approx(held,rig.horizontal_stroke_clock),"Boost consumes ordinary swim cadence")
    rig.reset_performance()
    check(rig.horizontal_stroke_clock==0 and rig.arm_dynamics.cups==[Vector2.ZERO,Vector2.ZERO],"Restart retains cadence or hand momentum")
    rig.free()
    var menu = load("res://godot/title_screen.tscn").instantiate()
    root.add_child(menu);menu.set_process(false)
    menu.hero_rig.set_process(false)
    menu.hero_performance.reset()
    menu._process(1.0/60)
    check(menu.hero_rig.position.x<menu.hero.size.x*.3,"Sarah must enter from the opposite side")
    var wave_peak := 0.0
    for frame in range(900):
        menu._process(1.0/60)
        wave_peak=maxf(wave_peak,menu.hero_rig.camera_wave)
        if menu.hero_rig.camera_wave>0 and frame%6==0:
            for landmark in [Vector2(.71,.51),Vector2(.88,.455),Vector2(.83,.565),Vector2(.82,.67)]:
                var face: Vector2 = menu.hero_rig.face_details.to_global(landmark*Vector2(710,570))
                check(alpha_at(menu.hero_rig.arm_meshes[1],face)<.2,"Camera wave clips a facial landmark")
    check(wave_peak>.95,"Opening lacks camera-directed hand wave")
    check(menu.hero.texture!=null and menu.hero.self_modulate.a==0,"Static title portrait doubles over animated Sarah")
    check(menu.hero_rig.clock>14.9 and menu.hero_rig.arm_meshes[1].mesh_updates>600,"Opening uses a static or incomplete character")
    check(menu.hero_performance.last_event>=2,"Opening lacks greeting and swimming sequence")
    var previous_position: Vector2 = menu.hero_rig.position
    prefs.reduced_motion=true
    menu._process(1.0/60)
    var quiet_position: Vector2 = menu.hero_rig.position
    for frame in range(60): menu._process(1.0/60)
    check(menu.hero_rig.position==quiet_position and menu.hero_rig.modulate.a==1,"Gentle opening drifts or remains invisible")
    check(menu.hero_rig.camera_wave==0.0,"Gentle opening retains camera wave")
    check(menu.hero_rig.arm_dynamics.cups==[Vector2.ZERO,Vector2.ZERO],"Gentle opening retains hand cupping")
    check(previous_position.distance_to(quiet_position)<100,"Gentle setting snaps the title hero excessively")
    menu.free()
    print("SARAH V031 BUNDLE: %d checks, %d failures" % [checks,failures])
    quit(0 if failures==0 else 1)

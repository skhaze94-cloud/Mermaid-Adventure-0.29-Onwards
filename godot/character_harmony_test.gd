extends SceneTree
const PaintedMesh = preload("res://godot/sarah_painted_mesh.gd")
## Painted waist overlap, refresh-rate independence and reusable native skins.
var checks := 0
var failures := 0
var images := {}
func _initialize() -> void: call_deferred("run")
func check(ok: bool, why: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("CHARACTER HARMONY: "+why)
func alpha_at(part: PaintedMesh, point: Vector2) -> float:
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
    var rig = load("res://godot/sarah_rig.gd").new()
    root.add_child(rig)
    rig.set_process(false)
    rig.gesture_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.jump_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.reset_performance()
    check(rig.tail_skin.rest.size()==7605,"tail needs tripled v0.31 points (584 columns, 13 rows)")
    check(rig.arm_meshes[0].rest.size()==891,"arms retain the v0.5 detail: 98 columns and nine rows")
    for mode in ["idle","swim","dash","turn","jump"]:
        rig.reset_jump()
        rig.reset_performance()
        rig.set_motion(Vector2(300,0),1,mode=="dash",mode=="jump",1)
        for frame in range(180):
            if mode=="idle": rig.set_motion(Vector2.ZERO,1,false,false,1)
            if mode=="turn" and frame==30: rig.set_motion(Vector2(-300,120),-1,false,false,1)
            if mode=="jump": rig.set_jump_state("airborne",frame/180.0*.88,1,1)
            var updates: int = rig.arm_meshes[1].mesh_updates
            rig._process(1.0/120.0)
            check(rig.arm_meshes[1].mesh_updates==updates+1,"high-refresh arm frame skipped")
            var waist: Vector2 = rig.torso.to_global(Vector2(18,4))
            check(alpha_at(rig.bodice,waist)>.7 and alpha_at(rig.tail_skin,waist)>.7,"painted waist opens during "+mode)
            var shoulder: Vector2 = rig.near_arm.to_global(Vector2(7,5))
            check(alpha_at(rig.bodice,shoulder)>.7 and alpha_at(rig.arm_meshes[1],shoulder)>.7,"painted shoulder opens during "+mode)
            var far_shoulder: Vector2 = rig.far_arm.to_global(Vector2(7,5))
            check(alpha_at(rig.bodice,far_shoulder)>.7 and alpha_at(rig.arm_meshes[0],far_shoulder)>.7,"painted far shoulder opens during "+mode)
    rig.free()
    var endpoints := []
    for fps in [30,60,120]:
        var royal = load("res://godot/family_royal_actor.gd").new()
        root.add_child(royal)
        royal.configure("queen",300)
        var identity: int = royal.mesh.mesh.get_instance_id()
        check(royal.mesh.texture.get_size()==Vector2(1024,1536),"royal source is downsampled")
        var old: Vector3 = royal.pose_blend
        for frame in range(1,fps*2+1):
            royal.animate(float(frame)/fps,"wave" if frame<=fps else "cast",false)
            check(royal.pose_blend.distance_to(old)<.12,"royal gesture snaps")
            check(royal.mesh.mesh.get_instance_id()==identity,"royal mesh rebuilt during animation")
            old=royal.pose_blend
        endpoints.append(royal.pose_blend)
        royal.animate(2,"dash",false)
        check(royal.pose_blend==old,"paused clock changes pose")
        royal.animate(2.01,"wave",true)
        check(royal.surface.get_shader_parameter("strength")==0.0 and royal.mesh.rotation==0.0,"gentle royal pose")
        royal.free()
    check(endpoints[0].distance_to(endpoints[2])<.0001,"royal transition depends on refresh rate")
    var boss = load("res://godot/boss_performance.gd").new()
    root.add_child(boss)
    check(boss.body.mesh.surface_get_array_len(0)==1617,"boss mesh resolution")
    for profile in ["miguel","nessie","blackwater","flip","palace","rana","duke"]:
        boss.configure(load("res://godot/assets/characters-v027/queen-antonella.png"),Vector2(360,300),profile)
        for mode in ["windup","attack","recover"]:
            boss.set_state(3,mode,Vector2(700,500),1.0,false)
            boss._process(1.0/60.0)
            check(boss.body.scale.is_finite() and boss.position==Vector2(700,500),"boss presentation moves combat root")
    boss.set_state(3,"attack",Vector2(700,500),1.0,true)
    check(boss.surface.get_shader_parameter("strength")==0.0,"gentle boss motion")
    boss.free()
    print("CHARACTER HARMONY: %d checks, %d failures" % [checks,failures])
    quit(0 if failures==0 else 1)

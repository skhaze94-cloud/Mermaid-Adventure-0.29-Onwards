extends SceneTree
## Clip coverage, seamless interpolation, actual mesh density and integration safety.
const Motion = preload("res://godot/creature_motion.gd")
const CreatureSkin = preload("res://godot/creature_skin.gd")
const Art = preload("res://godot/creature_art.gd")
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, why: String) -> void:
    checks+=1
    if not ok: failures+=1;push_error("ARTICULATION: "+why)
func run() -> void:
    for profile in ["crab","eel","jelly","puffer","swordfish","shark","carlo","duke","miguel","nessie","blackwater","flip","rana","palace","training"]:
        var library := Motion.library(profile)
        check(library.get_animation_list().size()==16,profile+" must have four times the original four clips")
        var signatures := []
        for index in range(16):
            var clip := library.get_animation(Motion.CLIPS[index])
            check(clip.get_track_count()==2 and clip.track_get_key_count(0)==97,profile+" dense joint and posture curves")
            check(clip.loop_mode==Animation.LOOP_LINEAR,profile+" seamless cycle")
            var first: Vector4 = clip.track_get_key_value(0,0)
            var end: Vector4 = clip.track_get_key_value(0,96)
            check(first.distance_to(end)<.00001,profile+" loop seam")
            var signature: Vector4 = clip.value_track_interpolate(0,clip.length*.25)
            for previous in signatures: check(signature.distance_to(previous)>.002,profile+" duplicate clip")
            signatures.append(signature)
            var old: Vector4 = first
            for sample in range(1,193):
                var next: Vector4 = clip.value_track_interpolate(0,clip.length*sample/192.0)
                check(is_finite(next.x) and is_finite(next.y) and is_finite(next.z) and next.length()<.85,profile+" unsafe joint angle")
                check(next.distance_to(old)<.035,profile+" curve steps instead of swimming")
                old=next
        var actor := CreatureSkin.new()
        root.add_child(actor)
        var art: Texture2D = null
        if not Art.TEXTURES.has(profile):
            art=Art.atlas("carlo",0) if profile=="duke" else (Art.atlas("shark",0) if profile=="blackwater" else load("res://godot/assets/characters-v027/queen-antonella.png"))
        actor.configure(profile,art,Vector2(350,280))
        check(actor.mesh.surface_get_array_len(0)==1617,profile+" actual articulated vertices missing")
        var original_mesh: int = actor.mesh.get_instance_id()
        var original_texture: int = actor.texture.get_instance_id()
        var seen := {}
        for mode in ["patrol","windup","attack","recover"]:
            for age in ([0.0,.12,.25,.42] if mode=="attack" else [0.0,.20,.45,.80]):
                var selected := Motion.select(mode,age,age,0.0)
                if mode!="patrol":seen[selected]=true
            var previous := actor.joints
            for frame in range(120):
                var t: float = seen.size()*2.0+frame/60.0
                actor.animate(mode,t,1.0/60,1.25,false,true,true,frame/60.0)
                if frame>0:check(actor.joints.distance_to(previous)<.12,profile+" transition snaps")
                check(actor.mesh.get_instance_id()==original_mesh and actor.texture.get_instance_id()==original_texture,profile+" swaps a slide or rebuilds geometry")
                previous=actor.joints
            actor.animate(mode,actor.last_clock,1.0/60,1.25,false)
            check(actor.joints==previous,profile+" moves while paused")
        check(seen.size()==12,profile+" all combat clip variants reachable")
        for index in range(4):check(Motion.select("patrol",0,index/.38+.001,0)==index,profile+" patrol variant unreachable")
        actor.animate("attack",100,1.0/60,0,true)
        check(actor.joints==Vector4.ZERO and actor.posture==Vector4.ZERO,profile+" reduced-motion joints not still")
        actor.flip_h=true
        check(actor.surface.get_shader_parameter("facing")==-1.0,profile+" reversed facing lost")
        actor.free()
    # Body/collision root remains independent of visible limbs at every mode.
    var boss = load("res://godot/boss_performance.gd").new()
    root.add_child(boss)
    boss.configure(Art.atlas("carlo",0),Vector2(380,310),"duke")
    for frame in range(240):
        boss.set_state(5,"attack" if frame>120 else "windup",Vector2(650,480),frame/60.0,false)
        boss._process(1.0/60)
        check(boss.position==Vector2(650,480),"boss visual animation moved collision root")
    boss.set_state(4,"recover",Vector2(650,480),4.01,false)
    check(boss.hit_age==0.0,"boss hit reaction")
    boss.set_state(0,"recover",Vector2(650,480),4.02,false)
    boss._process(.9)
    check(not boss.visible,"defeated boss remains drawn")
    boss.set_state(5,"windup",Vector2(650,480),4.03,false)
    check(boss.defeat_age==-1 and boss.modulate.a==1 and boss.visible,"retry retains defeat")
    boss.free()
    print("CREATURE ARTICULATION: %d checks, %d failures" % [checks,failures])
    quit(0 if failures==0 else 1)

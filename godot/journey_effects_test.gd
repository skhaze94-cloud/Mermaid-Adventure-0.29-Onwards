extends "res://godot/opal_current_test.gd"
## Exercise full-density pooled effects and world/UI transitions without reducing art.
func run() -> void:
    root.size=Vector2i(1400,960)
    root.get_node("AppPreferences").persist_enabled=false
    root.get_node("OceanAudio").playback_enabled=false
    var level=create("res://godot/highland_level.tscn")
    clean(level)
    level.camera=0
    var fx=level.opal_fx
    var nodes: int=Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
    for i in range(8):shot(level,Vector2(200+i*70,500),[1,2,4][i%3])
    for i in range(32):
        level.hostile_shots.append({"pos":Vector2(150+(i%8)*120,300+(i/8)*100),"velocity":Vector2(-240,90),"life":3.0,"style":"crab"})
    fx.sync(level)
    check(fx.friendly.filter(func(sprite):return sprite.visible).size()==8,"all eight friendly bubbles remain visible")
    check(fx.hostile.filter(func(sprite):return sprite.visible).size()==32,"all thirty-two hostile shots remain visible")
    var hostile: Sprite2D=fx.hostile[0]
    check(is_equal_approx(hostile.scale.x*maxf(hostile.texture.get_width(),hostile.texture.get_height()),48.0),"projectile keeps original extent")
    var key: String=fx.art.key_for("crab")
    var expected: float=Vector2(-240,90).angle()-deg_to_rad(float(fx.art.metadata["frames"][key]["native_heading_degrees"]))
    check(is_equal_approx(hostile.rotation,expected),"direction remains aligned to painted heading")
    for gentle in [false,true]:
        fx.reset();fx.gentle=gentle
        for tier in range(1,4):
            fx.impact(Vector2(400+tier*80,500),tier,true)
        fx.advance(.05)
        for tier in range(1,4):
            var effect: Dictionary=fx.impacts[tier-1]
            var count: int=[4,6,8][tier-1]
            check(effect["drops"].filter(func(sprite):return sprite.visible).size()==count,"tier droplet density retained")
            var progress: float=1.0-float(effect["life"])/float(effect["duration"])
            var radius: float=lerpf(10,48 if tier==3 else 30,progress)
            var exact:=true
            for i in range(count):
                var angle:=float(i)/count*TAU
                var at:=Vector2(cos(angle),sin(angle))*radius*(.9 if gentle else 1.15)
                exact=exact and effect["drops"][i].position==at
            check(exact,"every full/gentle impact droplet keeps its original position")
    fx.reset()
    for i in range(50):fx.impact(Vector2(300+i,500),3,true)
    check(fx.impacts.size()==12 and fx.active_impacts==12,"impact recycling never grows past twelve slots")
    check(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)==nodes,"busy rendering creates no additional scene nodes")
    fx.advance(1)
    check(fx.active_impacts==0,"all pooled impacts expire")
    level.waterfall_phase="descent";fx.sync(level)
    check(fx.friendly.all(func(sprite):return not sprite.visible) and fx.hostile.all(func(sprite):return not sprite.visible),"waterfall transition hides lake projectiles")
    fx.reset()
    check(fx.get_children().size()==3 and fx.active_impacts==0,"retry returns the bounded renderer to rest")
    dispose(level)
    print("JOURNEY EFFECTS: ",checks," checks, ",failures," failures")
    quit(1 if failures else 0)

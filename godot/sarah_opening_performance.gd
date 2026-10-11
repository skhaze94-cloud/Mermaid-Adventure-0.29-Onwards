extends RefCounted
## The gameplay Sarah performs the opening; buttons never wait for this show.
var clock := 0.0
var last_event := -1
func reset() -> void:
    clock=0.0
    last_event=-1
func update(menu, dt: float) -> void:
    clock+=dt
    var rig = menu.hero_rig
    rig.reduced_motion=menu.prefs.reduced_motion
    rig.set_quality(not menu.prefs.economy)
    var quiet: bool = menu.prefs.reduced_motion or menu.prefs.economy
    rig.reduced_motion=quiet
    var entrance := smoothstep(0.0,3.0,clock)
    var lap := fposmod(maxf(0.0,clock-3.0),18.0)
    var event := int(floor(maxf(0.0,clock-3.0)/18.0))*3+(0 if lap<4.0 else (1 if lap<10.0 else 2))
    if not quiet and clock>3.0 and event!=last_event:
        last_event=event
        if lap<4.0 and clock>3.0: rig.play_gesture("greet")
        elif lap>=10.0: rig.play_gesture("reward")
    var swimming: bool = clock<3.0 or (lap>=4.0 and lap<9.0)
    rig.swim_style_override="breaststroke" if swimming else ""
    rig.set_motion(Vector2(230,-45) if swimming and not quiet else Vector2.ZERO,1,false,false,1)
    rig.camera_wave=0.0 if quiet else smoothstep(0.0,.45,lap)*(1.0-smoothstep(2.3,3.2,lap)) if clock>3.0 else 0.0
    rig.gesture_player.advance(dt)
    rig._process(dt)
    var fit: float = minf(menu.hero.size.x/315.0,menu.hero.size.y/220.0)*.92
    rig.scale*=fit
    rig.position=Vector2(menu.hero.size.x*.63,menu.hero.size.y*.53)
    if not quiet:
        rig.position+=Vector2(-(1.0-entrance)*menu.hero.size.x*.48+sin(clock*.48)*menu.hero.size.x*.025,
            sin(clock*.65)*menu.hero.size.y*.018)
    rig.modulate.a=1.0 if quiet else smoothstep(.1,1.1,clock)

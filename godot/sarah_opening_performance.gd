extends RefCounted
## Authored gestures separated by quiet rests; the menu owns timing, never input.
var clock := 0.0
var last_event := -1
func reset() -> void:clock=0;last_event=-1
func update(menu,dt: float) -> void:
    if not menu.hero.is_visible_in_tree():return
    clock+=minf(dt,.05)
    var rig=menu.hero_rig
    var quiet: bool=menu.prefs.reduced_motion
    rig.reduced_motion=quiet;rig.set_quality(not menu.prefs.economy)
    rig.definitive_21.opening=true
    var lap:=fposmod(maxf(0,clock-3),32.0)
    var block:=int(maxf(0,clock-3)/32)
    var event:=block*4+(0 if lap<5 else 1 if lap<13 else 2 if lap<22 else 3)
    if event!=last_event and not quiet and clock>3:
        last_event=event
        if lap<5:rig.play_gesture(["greet","reward","greet"][block%3])
        elif lap>=13 and lap<22:rig.play_gesture(["reward","greet","cast"][block%3])
    # Long gentle camera glances, then a small look back toward the lagoon.
    var toward:=smoothstep(1,4,lap)*(1-smoothstep(9,12,lap))
    var away:=smoothstep(21,24,lap)*(1-smoothstep(28,31,lap))
    rig.definitive_21.view_goal=0 if quiet else toward*.82-away*.65
    var arriving:=clock<2.8
    rig.swim_style_override="breaststroke" if arriving else ""
    rig.set_motion(Vector2(150,-20) if arriving and not quiet else Vector2.ZERO,1,false,false,1)
    rig.camera_wave=0 if quiet else smoothstep(.3,1.0,lap)*(1-smoothstep(2.6,3.7,lap))*.65
    rig.gesture_player.advance(dt);rig._process(dt)
    var fit: float=minf(menu.hero.size.x/335.0,menu.hero.size.y/235.0)*.92
    rig.scale*=fit;rig.position=Vector2(menu.hero.size.x*.59,menu.hero.size.y*.53)
    if not quiet:rig.position+=Vector2(-(1-smoothstep(0,3,clock))*menu.hero.size.x*.35,sin(clock*.65)*menu.hero.size.y*.009)
    rig.modulate.a=1 if quiet else smoothstep(.1,1.1,clock)

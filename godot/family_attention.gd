extends RefCounted
## Tutorial events choose cues. Actors retain exclusive ownership of their poses.
var last_lesson := -1
var lesson_elapsed := 0.0
var king_near := false
var queen_near := false
var king_cooldown := 0.0
var queen_cooldown := 0.0
var jump_cooldown := 0.0
var previous_airborne := false
var previous_demo_phase := -1
var last_cue_king := ""
var last_cue_queen := ""
var cue_count := Vector2i.ZERO

func reset() -> void:
    last_lesson=-1;lesson_elapsed=0.0;king_near=false;queen_near=false
    king_cooldown=0.0;queen_cooldown=0.0;jump_cooldown=0.0
    previous_demo_phase=-1
    previous_airborne=false;last_cue_king="";last_cue_queen="";cue_count=Vector2i.ZERO

func cue(actor,kind: String,king_role: bool) -> void:
    if not is_instance_valid(actor) or not actor.visible:return
    if actor.has_method("react"):actor.react(kind)
    if king_role:last_cue_king=kind;cue_count.x+=1
    else:last_cue_queen=kind;cue_count.y+=1

func advance(scene,dt: float) -> void:
    if dt<=0.0 or scene.dialogue_open:return
    dt=minf(dt,.05)
    king_cooldown=maxf(0,king_cooldown-dt);queen_cooldown=maxf(0,queen_cooldown-dt);jump_cooldown=maxf(0,jump_cooldown-dt)
    if scene.lesson!=last_lesson:
        if last_lesson>=1 and scene.lesson>last_lesson and scene.lesson<=10:
            cue(scene.king,"celebrate",true);king_cooldown=8.0
            # One proud speaker; Mum's smaller acknowledgement has its own timing.
            if scene.queen_world.distance_to(scene.player)<800:
                cue(scene.queen_teacher,"acknowledge",false);queen_cooldown=7.0
        last_lesson=scene.lesson;lesson_elapsed=0.0
    else:lesson_elapsed+=dt
    var king_distance: float=scene.king_world.distance_to(scene.player)
    var queen_distance: float=scene.queen_world.distance_to(scene.player)
    var entered_king: bool=scene.king.visible and king_distance<620.0
    var entered_queen: bool=scene.queen_teacher.visible and queen_distance<650.0
    if entered_king and not king_near and king_cooldown<=0:
        cue(scene.king,"wave",true);king_cooldown=12.0
    if entered_queen and not queen_near and queen_cooldown<=0:
        cue(scene.queen_teacher,"wave",false);queen_cooldown=15.0
    if king_distance>760 or not scene.king.visible:king_near=false
    elif entered_king:king_near=true
    if queen_distance>790 or not scene.queen_teacher.visible:queen_near=false
    elif entered_queen:queen_near=true
    var demo_phase: int=int((10.0-scene.queen_demo)/3.34) if scene.queen_demo>0 else -1
    if demo_phase>=0 and demo_phase!=previous_demo_phase:
        cue(scene.queen_teacher,"cast",false)
    previous_demo_phase=demo_phase
    var airborne: bool=scene.leap_phase=="airborne"
    if airborne and not previous_airborne and jump_cooldown<=0:
        if entered_king and king_cooldown<4:
            cue(scene.king,"acknowledge",true);king_cooldown=6.0
        elif entered_queen and queen_cooldown<4:
            cue(scene.queen_teacher,"acknowledge",false);queen_cooldown=7.0
        jump_cooldown=14.0
    previous_airborne=airborne

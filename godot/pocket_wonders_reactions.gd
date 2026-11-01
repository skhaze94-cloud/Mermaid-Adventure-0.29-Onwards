extends RefCounted
## A little six-beat bubble pantomime, expressed through existing painted rigs.
## Bubbles/fish are presentation data for the parent art layer, never projectiles.
const KINDS := ["bubble_game","delight","discovery","tea","village","post","dream"]
const BEAT_SECONDS := [.80,1.10,1.25,1.10,1.05,1.00]
const BEAT_JOY := [.24,.42,.66,.52,.72,.62]
const REPLAY_DELAY := 12.0
const SHORT_REPLAY_DELAY := 1.6
const MAX_DISTANCE := 360.0
const GENTLE_BEAT_SECONDS := 1.05
var level: Node2D
var active := false
var kind := ""
var phase := -1
var phase_time := 0.0
var elapsed := 0.0
var anchor := Vector2.ZERO
var partner := "fish"
var partner_at := Vector2.ZERO
var finished_serial := 0
var played_serial := 0
var cooldown := 0.0
var last_retry := -1
var owns_focus := false
var last_focus_goal := Vector2.ZERO
var last_joy_goal := 0.0
var speech_owner: Node2D
var speech_line := ""

func bind(host: Node2D) -> void:
    clear()
    level=host
    last_retry=level.retry_serial if is_instance_valid(level) else -1

func play(request: String, at: Vector2) -> bool:
    if active or cooldown>0 or request not in KINDS or not at.is_finite() or not _safe(at):return false
    kind=request;anchor=at;phase=0;phase_time=0.0;elapsed=0.0;active=true;played_serial+=1
    partner="avina" if _baby_available() else "fish"
    partner_at=level.avina.world_position if partner=="avina" else anchor+Vector2(105,-35)
    _enter_beat()
    return true

func advance(dt: float) -> void:
    if not is_instance_valid(level):return
    if not level.is_inside_tree() or level.retry_serial!=last_retry:
        clear();last_retry=level.retry_serial;return
    if not is_finite(dt) or dt<=0:return
    cooldown=maxf(0,cooldown-dt)
    if not active:return
    if not _safe(anchor) or (partner=="avina" and not _baby_available()):
        _cancel()
        return
    elapsed+=dt;phase_time+=dt
    if kind!="bubble_game":
        if phase_time>=1.15:_finish(false)
        else:_apply_focus()
        return
    # At most six transitions, even with a large developer timestep. No delayed
    # callbacks survive a scene change, and completion increments exactly once.
    for step in range(6):
        var duration:=_beat_duration()
        if phase_time<duration:break
        phase_time-=duration;phase+=1
        if phase>=6:
            _finish(true)
            return
        _enter_beat()
    _apply_focus()

func clear() -> void:
    _release_owned(true)
    active=false;kind="";phase=-1;phase_time=0.0;elapsed=0.0;cooldown=0.0
    anchor=Vector2.ZERO;partner_at=Vector2.ZERO;partner="fish"

func snapshot() -> Dictionary:
    var visible: bool=active and _context_safe(anchor)
    var hero: Vector2=level.player if is_instance_valid(level) else Vector2.ZERO
    var baby_at: Vector2=partner_at
    if partner=="avina" and _baby_available():baby_at=level.avina.world_position
    var gentle: bool=is_instance_valid(level) and level.reduced_fx
    return {"active":visible,"kind":kind,"phase":phase,"phase_time":phase_time,
        "phase_progress":clampf(phase_time/_beat_duration(),0,1) if active else 0.0,"elapsed":elapsed,
        "partner":partner,"anchor":anchor,"at":anchor,"hero":hero,"partner_at":baby_at,
        "fish_at":anchor+Vector2(120,-78),"gentle":gentle,"bubble_owner":_bubble_owner(),
        "fish_mood":"surprised" if phase==4 else "happy" if phase==5 else "curious",
        "finished_serial":finished_serial,"played_serial":played_serial}

func _beat_duration() -> float:
    if kind!="bubble_game":return 1.15
    return GENTLE_BEAT_SECONDS if is_instance_valid(level) and level.reduced_fx else float(BEAT_SECONDS[clampi(phase,0,5)])

func _bubble_owner() -> String:
    if not active or kind!="bubble_game":return ""
    if phase in [1,3]:return "sarah"
    if phase==2:return partner
    if phase==4:return "passing_fish"
    return ""

func _enter_beat() -> void:
    if not active or not _safe(anchor):return
    _apply_focus()
    if not level.reduced_fx:
        if phase==0 and kind in ["bubble_game","discovery","village","post"]:
            level.native_rig.play_discovery_gesture("greet")
        elif phase in [1,3,4] or kind in ["delight","tea","dream"]:
            level.native_rig.play_discovery_gesture("reward")
    if partner=="avina" and ((kind=="bubble_game" and phase in [2,5]) or (kind!="bubble_game" and phase==0)):
        var word: String="complete" if phase==5 else "progress" if phase==2 else "discovery"
        if level.avina.react_to_discovery(word):
            speech_owner=level.avina;speech_line=level.avina.speech

func _apply_focus() -> void:
    if not active:return
    var focus:=anchor
    if kind=="bubble_game":
        if phase in [2,5]:focus=level.avina.world_position if partner=="avina" and _baby_available() else partner_at
        elif phase==4:focus=anchor+Vector2(120,-78)
        elif phase in [1,3]:focus=anchor+Vector2(0,-45)
    var joy:=float(BEAT_JOY[clampi(phase,0,5)]) if kind=="bubble_game" else .52
    var offset: Vector2=Vector2.ZERO if level.reduced_fx else focus-level.player
    level.native_rig.set_discovery_focus(offset,joy)
    owns_focus=true
    last_focus_goal=level.native_rig.discovery_focus_goal
    last_joy_goal=level.native_rig.discovery_joy_goal

func _finish(successful_game: bool) -> void:
    if not active:return
    if successful_game and kind=="bubble_game":finished_serial+=1
    _release_owned(false)
    active=false;phase=-1;phase_time=0.0;cooldown=REPLAY_DELAY if kind=="bubble_game" else SHORT_REPLAY_DELAY

func _cancel() -> void:
    _release_owned(true)
    active=false;phase=-1;phase_time=0.0;cooldown=REPLAY_DELAY if kind=="bubble_game" else SHORT_REPLAY_DELAY

func _release_owned(immediate: bool) -> void:
    # A newly started Living Reef story owns the shared expression hooks. Yield
    # without erasing its gaze, greeting or baby acknowledgement.
    if is_instance_valid(level) and not _story_busy():
        var rig=level.native_rig
        if is_instance_valid(rig) and owns_focus and rig.discovery_focus_goal.is_equal_approx(last_focus_goal) and is_equal_approx(rig.discovery_joy_goal,last_joy_goal):
            if immediate:rig.clear_discovery_focus()
            else:rig.set_discovery_focus(Vector2.ZERO,0)
        if is_instance_valid(speech_owner) and speech_owner.discovery_speech and speech_owner.speech==speech_line:
            speech_owner.clear_discovery_reaction()
    owns_focus=false;speech_owner=null;speech_line=""

func _baby_available() -> bool:
    if not is_instance_valid(level) or not level.is_inside_tree() or not is_instance_valid(level.avina):return false
    var baby=level.avina
    if not baby.follow_enabled or not baby.visible or baby.bubble_pending:return false
    var point: Vector2=baby.world_position-Vector2(level.camera,0)
    return baby.world_position.distance_squared_to(level.player)<160000 and Rect2(Vector2.ZERO,level.get_viewport_rect().size).has_point(point)

func _story_busy() -> bool:
    if not is_instance_valid(level):return false
    var reef=level.get("living_reef")
    if reef==null:return false
    var reaction=reef.reactions
    return reaction.focus_left>0 or reaction.pending_complete_left>0

func _context_safe(at: Vector2) -> bool:
    if not is_instance_valid(level) or not level.is_inside_tree() or not is_instance_valid(level.native_rig):return false
    if level.state!="playing" or level.get_tree().paused or level.waterfall_phase!="":return false
    var flow=level.get_node_or_null("/root/SceneFlow")
    if is_instance_valid(flow) and flow.busy:return false
    if level.get("dialogue_open")==true or level.get("playing_daddy")==true:return false
    if level._stage_index()==7 and int(level.get("lesson"))<10:return false
    if level.has_method("_bubble_world_active") and not level._bubble_world_active():return false
    if level.has_method("_whimsy_combat_active") and level._whimsy_combat_active():return false
    if at.distance_squared_to(level.player)>MAX_DISTANCE*MAX_DISTANCE:return false
    return Rect2(Vector2.ZERO,level.get_viewport_rect().size).has_point(at-Vector2(level.camera,0))

func _safe(at: Vector2) -> bool:
    if not _context_safe(at) or _story_busy():return false
    if level.boost_time>0 or level.leap_phase!="" or level.opal.charge.held or not level.native_rig.can_discovery_react():return false
    if level.player_velocity.length_squared()>10000:return false
    if level.has_method("_input_vector") and level._input_vector().length_squared()>.02:return false
    if is_instance_valid(level.avina) and level.avina.bubble_pending:return false
    return true

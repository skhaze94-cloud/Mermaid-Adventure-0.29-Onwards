extends RefCounted
## Short, optional expressions for nearby reef stories. Never owns game state.
const KINDS := ["discovery","note","help","progress","complete"]
const JOY := [.38,.46,.52,.55,.68]
const HOLD := [1.35,1.15,1.45,1.35,1.65]
const REPEAT_DELAY := 2.4
const MAX_DISTANCE := 460.0
const COMPLETE_WAIT := 2.0
var level: Node2D
var focus_at := Vector2.ZERO
var focus_left := 0.0
var cooldown := 0.0
var completion_cooldown := 0.0
var active_kind := ""
var accepted_count := 0
var last_retry := -1
var pending_complete_at := Vector2.ZERO
var pending_complete_left := 0.0

func bind(host: Node2D) -> void:
    clear()
    level=host
    last_retry=level.retry_serial if is_instance_valid(level) else -1

func react(kind: String, at: Vector2) -> void:
    var index:=KINDS.find(kind)
    if index<0 or not at.is_finite() or not _context_safe(at):return
    # A completion has its own repeat guard and may bypass an ordinary note's
    # throttle. Otherwise the last note's 2.4s cooldown outlives its 2s queue.
    if kind=="complete" and completion_cooldown>0:return
    if (kind!="complete" and cooldown>0) or not _action_safe():
        # Finishing a choir with Boost should receive its celebration as soon as
        # that action finishes. One bounded slot; ordinary notes never queue.
        if kind=="complete" and pending_complete_left<=0:
            pending_complete_at=at;pending_complete_left=COMPLETE_WAIT
        return
    _start(kind,at,index)

func _start(kind: String, at: Vector2, index: int) -> void:
    focus_at=at;focus_left=float(HOLD[index]);active_kind=kind;cooldown=REPEAT_DELAY
    if kind=="complete":
        pending_complete_left=0.0;completion_cooldown=REPEAT_DELAY
    accepted_count+=1
    level.native_rig.set_discovery_focus(at-level.player,float(JOY[index]))
    level.native_rig.play_discovery_gesture("greet" if kind in ["discovery","help"] else "reward")
    if is_instance_valid(level.avina):
        var baby_at: Vector2=level.avina.world_position-Vector2(level.camera,0)
        if Rect2(Vector2.ZERO,level.get_viewport_rect().size).has_point(baby_at):
            level.avina.react_to_discovery(kind)

func advance(dt: float) -> void:
    if not is_instance_valid(level):return
    if not level.is_inside_tree() or level.retry_serial!=last_retry or level.state!="playing" or level.get_tree().paused or _loading() or _combat():
        clear();last_retry=level.retry_serial;return
    if not is_finite(dt) or dt<=0:return
    cooldown=maxf(0,cooldown-dt)
    completion_cooldown=maxf(0,completion_cooldown-dt)
    if focus_left>0:
        if not _context_safe(focus_at) or not _action_safe():_release_focus()
        else:
            focus_left=maxf(0,focus_left-dt)
            if focus_left>0:
                var index:=KINDS.find(active_kind)
                var envelope:=minf(1.0,focus_left/.4)
                level.native_rig.set_discovery_focus((focus_at-level.player)*envelope,float(JOY[index])*envelope)
            else:
                # Ordinary expiry releases the goal, keeping the existing damped
                # return to swimming gaze. Interruptions clear immediately.
                level.native_rig.set_discovery_focus(Vector2.ZERO,0)
                active_kind=""
    if pending_complete_left>0:
        pending_complete_left=maxf(0,pending_complete_left-dt)
        if not _context_safe(pending_complete_at):pending_complete_left=0.0
        elif pending_complete_left>0 and completion_cooldown<=0 and _action_safe():
            _start("complete",pending_complete_at,4)

func _release_focus() -> void:
    if is_instance_valid(level):
        if is_instance_valid(level.native_rig):level.native_rig.clear_discovery_focus()
        if is_instance_valid(level.avina):level.avina.clear_discovery_reaction()
    focus_at=Vector2.ZERO;focus_left=0.0;active_kind=""

func clear() -> void:
    _release_focus()
    cooldown=0.0;completion_cooldown=0.0;pending_complete_at=Vector2.ZERO;pending_complete_left=0.0

func _action_safe() -> bool:
    return level.boost_time<=0 and level.leap_phase=="" and level.native_rig.can_discovery_react()

func _loading() -> bool:
    var flow=level.get_node_or_null("/root/SceneFlow")
    return is_instance_valid(flow) and flow.busy

func _combat() -> bool:
    return level.has_method("_whimsy_combat_active") and level._whimsy_combat_active()

func _context_safe(at: Vector2) -> bool:
    if not is_instance_valid(level) or not level.is_inside_tree() or not is_instance_valid(level.native_rig):return false
    if level.state!="playing" or level.get_tree().paused or level.waterfall_phase!="" or _loading() or _combat():return false
    if at.distance_squared_to(level.player)>MAX_DISTANCE*MAX_DISTANCE:return false
    return Rect2(Vector2.ZERO,level.get_viewport_rect().size).has_point(at-Vector2(level.camera,0))

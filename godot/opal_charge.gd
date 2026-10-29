extends RefCounted
## Input/charge state used by the live combat controller; no node ownership.
## Prepare -> atomically admit to pool -> commit. Caller owns unlock/context gates.

const PARTIAL_SECONDS := 0.35
const SUPER_SECONDS := 1.35
const EPSILON := 0.000001
const DAMAGE := [1, 2, 3]
const BOSS_DAMAGE := [1, 1, 2]
const COOLDOWN := [0.20, 0.35, 0.65]

var held := false
var elapsed := 0.0
var cooldown := 0.0
var source_id := ""
var pending: Dictionary = {}
var serial := 0

func begin(source: String, unlocked: bool, context_allows: bool) -> bool:
    if source.is_empty() or not unlocked or not context_allows:
        return false
    if held or not pending.is_empty() or cooldown > EPSILON:
        return false
    held = true
    source_id = source
    elapsed = 0.0
    return true

func advance(dt: float, context_allows := true) -> void:
    if not context_allows:
        cancel()
        return # Paused time advances neither charge nor cooldown.
    var step := maxf(dt, 0.0)
    cooldown = maxf(0.0, cooldown - step)
    if held:
        elapsed = minf(SUPER_SECONDS, elapsed + step)

func tier() -> int:
    if elapsed + EPSILON >= SUPER_SECONDS:
        return 3
    if elapsed + EPSILON >= PARTIAL_SECONDS:
        return 2
    return 1

func prepare_release(source: String) -> Dictionary:
    if not held or source != source_id or not pending.is_empty():
        return {}
    held = false
    serial += 1
    var index := tier() - 1
    pending = {"packet_id": serial, "owner": "sarah", "team": "friendly",
        "attack": "bubble", "tier": index + 1, "damage": DAMAGE[index],
        "boss_damage": BOSS_DAMAGE[index], "charge_seconds": elapsed,
        "cooldown_seconds": COOLDOWN[index]}
    return pending.duplicate(true)

func commit_release(packet_id: int, accepted: bool) -> bool:
    if pending.is_empty() or int(pending["packet_id"]) != packet_id:
        return false
    if accepted:
        cooldown = float(pending["cooldown_seconds"])
    pending.clear()
    elapsed = 0.0
    source_id = ""
    return accepted

func cancel() -> void:
    held = false
    elapsed = 0.0
    source_id = ""
    pending.clear()
    # Existing shot cooldown survives focus loss, retries and input cancellation.

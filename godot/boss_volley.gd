extends RefCounted
## One bounded, world-locked warning; no timers, nodes or per-frame geometry.
var pending: Array[Dictionary] = []
var rays := PackedVector2Array()
var remaining := 0.0
func clear() -> void:
    pending.clear();rays.clear();remaining=0
func queue(origin: Vector2, aim: Vector2, spread: float, speed: float, warning := .5) -> bool:
    if not pending.is_empty():return false
    remaining=warning
    if aim==Vector2.ZERO:aim=Vector2.LEFT
    for angle in [-spread,0.0,spread]:
        var direction:=aim.normalized().rotated(angle)
        pending.append({"pos":origin,"direction":direction,"speed":speed})
        for segment in range(3):
            rays.append(origin+direction*(24+segment*36))
            rays.append(origin+direction*(45+segment*36))
    return true
func advance(dt: float, host: Node2D, allowed: bool) -> void:
    if not allowed:clear();return
    if pending.is_empty():return
    remaining=maxf(0,remaining-maxf(0,dt))
    if remaining>0:return
    for shot in pending:host._spawn_hostile(shot["pos"],shot["direction"],shot["speed"])
    clear()

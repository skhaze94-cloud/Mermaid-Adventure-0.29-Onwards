extends RefCounted
## Fixed-tick, analogue-preserving steering; boost and jump own their trajectories.
const SWIM_SPEED := 345.0
const ACCELERATION := 1650.0
const REVERSAL_ACCELERATION := 2300.0
const BRAKING := 2100.0
static func swim_velocity(current: Vector2, steering: Vector2, delta: float) -> Vector2:
    var input := steering.limit_length(1.0)
    var rate := ACCELERATION
    if input.length_squared() < 0.0001:
        rate = BRAKING
    elif current.dot(input) < 0.0:
        rate = REVERSAL_ACCELERATION
    return current.move_toward(input * SWIM_SPEED, maxf(delta,0.0) * rate)


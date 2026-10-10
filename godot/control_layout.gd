extends RefCounted
## Shared geometry for input and HUD: sliding pad supports one-finger diagonals.
static func pad_rect(size: Vector2) -> Rect2:
    return Rect2(16, size.y - 184, 224, 168)

static func pad_vector(point: Vector2, size: Vector2) -> Vector2:
    var offset := point - pad_rect(size).get_center()
    if offset.length() < 18.0:
        return Vector2.ZERO
    return offset.normalized() * clampf((offset.length()-18.0)/24.0,0.0,1.0)

static func radial_stick(stick: Vector2) -> Vector2:
    var magnitude := stick.length()
    if magnitude <= 0.20:
        return Vector2.ZERO
    return stick.normalized() * clampf((magnitude - 0.20) / 0.80, 0.0, 1.0)

static func rect(action: String, size: Vector2) -> Rect2:
    var y := size.y - 172.0
    match action:
        "boost": return Rect2(size.x - 225, y + 57, 102, 91)
        "jump": return Rect2(size.x - 110, y - 20, 94, 91)
        "bubble": return Rect2(size.x - 335, y - 20, 94, 91)
        "pause": return Rect2(size.x - 88, 12, 72, 66)
        "resume": return Rect2(size.x * 0.5 - minf(235, (size.x - 34) * 0.5), size.y * 0.5 + 62, minf(220, (size.x - 64) * 0.5), 64)
        "restart": return Rect2(size.x * 0.5 + 15, size.y * 0.5 + 62, minf(220, (size.x - 64) * 0.5), 64)
    return Rect2()

static func controller_id(current: int, devices: Array[int]) -> int:
    if devices.is_empty():
        return -1
    return current if current in devices else devices[0]

static func ui_scale(viewport_size: Vector2, window_size: Vector2) -> float:
    return clampf(viewport_size.y / clampf(window_size.y, 480.0, 960.0), 1.0, 4.0)

static func safe_frame(viewport_size: Vector2, window_size: Vector2, safe_pixels: Rect2) -> Rect2:
    var full := Rect2(Vector2.ZERO, window_size)
    var safe := full if safe_pixels.size == Vector2.ZERO else full.intersection(safe_pixels)
    if safe.size.x < 1.0 or safe.size.y < 1.0:
        safe = full
    var conversion := viewport_size / window_size.max(Vector2.ONE)
    return Rect2(safe.position * conversion, safe.size * conversion)

extends RefCounted
## Window/input simulations, not claims of testing named physical hardware.
static func cases() -> Array[Dictionary]:
    return [
        {"name": "phone-small", "size": Vector2i(640, 360), "safe": Rect2(12, 0, 616, 344)},
        {"name": "phone-wide", "size": Vector2i(844, 390), "safe": Rect2(30, 0, 784, 372)},
        {"name": "tablet-4x3", "size": Vector2i(1024, 768), "safe": Rect2(0, 0, 1024, 748)},
        {"name": "tablet-wide", "size": Vector2i(1280, 800), "safe": Rect2(0, 0, 1280, 780)},
        {"name": "desktop", "size": Vector2i(1920, 1080), "safe": Rect2()},
        {"name": "phone-portrait", "size": Vector2i(390, 844), "safe": Rect2(0, 30, 390, 790)}
    ]

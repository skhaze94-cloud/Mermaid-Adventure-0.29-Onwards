extends SceneTree
const Terrain = preload("res://godot/terrain_painter.gd")
const Chapter = preload("res://godot/chapter_data.gd")
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, reason: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("GROUNDING: "+reason)
func run() -> void:
    root.get_node("AppPreferences").persist_enabled = false
    root.get_node("OceanAudio").playback_enabled = false
    var catalog := root.get_node("AdventureRun")
    for index in range(catalog.SCENES.size()):
        var level = load(catalog.SCENES[index]).instantiate()
        root.add_child(level)
        level.set_physics_process(false)
        check(level.obstacles==Chapter.obstacles_for(["highland","shadow","miguel","blackwater","palace","rana","nessie","training"][index]),"Original chapter collision must survive art changes")
        for camera in [0.0,1800.0,4500.0]:
            level.camera = camera
            level._sync_native_visuals()
            if index==0:
                for entry in level.world_depth.far_entries+level.world_depth.middle_entries:
                    var sprite: Sprite2D = entry["sprite"]
                    var expected := Terrain.ground_y(sprite.position.x+camera*entry["factor"],entry["base_y"])+5
                    check(is_equal_approx(sprite.position.y,expected),"Plant and parallax terrace must share exact world height")
                    check(sprite.offset.y<0,"Sway must pivot at embedded roots")
                for entry in level.foreground_depth.entries:
                    check(is_equal_approx(entry["sprite"].position.y,Terrain.ground_y(entry["x"],909)+6),"Foreground grounding must not drift with viewport height")
                for i in range(level.relief_obstacles.sprites.size()):
                    check(level.relief_obstacles.sprites[i].texture.atlas==Terrain.FORMATIONS,"Highland must have one unified formation cap")
        level.get_parent().remove_child(level)
        level.free()
    for x in [0.0,310.0,1700.0,20000.0]:
        check(absf(Terrain.ground_y(x)-Terrain.GROUND_Y)<10,"Seabed relief must remain below swimming space")
    for x in [200.0,1700.0,9000.0]:
        var pedestal := Terrain.prop_pedestal(Vector2(x,840),Vector2(80,69),x)
        check(pedestal.has_area() and is_equal_approx(pedestal.end.y,Terrain.ground_y(x)+10),"Near-floor treasure pedestal must reach the reef bed")
    check(not Terrain.prop_pedestal(Vector2(100,400),Vector2(80,69),100).has_area(),"Mid-water rewards must not gain a floor-length pedestal")
    print("GODOT GROUNDING TEST: %s checks, %s failures" % [checks,failures])
    quit(1 if failures else 0)

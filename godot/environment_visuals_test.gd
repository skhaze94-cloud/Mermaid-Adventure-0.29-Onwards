extends SceneTree
const Art = preload("res://godot/environment_art.gd")
const Highland = preload("res://godot/highland_data.gd")
var failures := 0
func _initialize() -> void:
    call_deferred("_run")
func check(ok: bool, why: String) -> void:
    if not ok:
        failures += 1
        push_error("ENVIRONMENT TEST: " + why)
func _run() -> void:
    var level = load("res://godot/highland_level.tscn").instantiate()
    root.add_child(level)
    for group in [[Art.GARDENS, Art.GARDEN_REGIONS], [Art.ROCKS, Art.ROCK_REGIONS], [Art.PROPS, Art.PROP_REGIONS]]:
        var texture: Texture2D = group[0]
        var bounds := Rect2(0,0,texture.get_width(),texture.get_height())
        for region in group[1]:
            check(bounds.encloses(region), "Atlas crop leaves source bounds")
    var world = level.world_depth
    var lake: Texture2D = world.background.texture
    world.set_camera(4000.0,true,false)
    check(world.background.texture != lake, "Grotto must have separate cavern artwork")
    world.set_camera(4000.0,false,false)
    check(world.background.texture == lake, "Returning to lake must restore its artwork")
    for entry in world.far_entries + world.middle_entries + level.foreground_depth.entries:
        var sprite: Sprite2D = entry["sprite"]
        check(is_equal_approx(sprite.scale.x,sprite.scale.y), "Plants must preserve proportions")
        check(sprite.offset.y < 0.0, "Plant sway pivot must be rooted at its base")
        sprite.rotation = 0.2
    world.set_camera(4000.0,false,true)
    level.foreground_depth.set_camera(4000.0,true,true)
    for entry in world.far_entries + world.middle_entries + level.foreground_depth.entries:
        check(is_zero_approx(entry["sprite"].rotation), "Reduced motion must reset sway immediately")
    check(level.relief_obstacles.positions == Highland.obstacles(), "Collision geometry changed during art pass")
    for kind in ["pearl","chest","heart","boost"]:
        check(level.collectible_art[kind] is AtlasTexture, "Missing painted collectible " + kind)
    level.high_depth_quality = false
    level._apply_visual_quality()
    for material in level.relief_obstacles.materials:
        check(not material.get_shader_parameter("high_quality"), "Economy must skip normal sampling")
    check(not world.background_material.get_shader_parameter("high_quality"), "Economy must skip backdrop distortion")
    var landmarks = level.environment_landmarks
    landmarks.set_scene(Highland.PORTAL_X-700.0,true,false,true,true)
    check(landmarks.arch.visible and landmarks.opening.visible, "Victory portal must appear after Carlo")
    landmarks.set_scene(Highland.PORTAL_X-700.0,true,false,false,false)
    check(not landmarks.arch.visible, "Portal must stay hidden before Carlo defeat")
    landmarks.set_scene(2800.0,false,false,false,false)
    check(landmarks.entrance.visible, "Soft entrance curtain missing")
    landmarks.set_scene(2800.0,false,true,false,false)
    check(not landmarks.visible, "Lake landmarks must disappear during waterfall")
    level.get_parent().remove_child(level)
    level.free()
    if failures == 0:
        print("GODOT ENVIRONMENT VISUALS TEST PASSED")
    quit(1 if failures else 0)

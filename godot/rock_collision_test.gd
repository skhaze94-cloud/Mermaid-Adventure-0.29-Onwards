extends SceneTree
const Collision = preload("res://godot/rock_collision.gd")
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error("ROCK RESCUE: " + message)
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    root.get_node("AppPreferences").persist_enabled = false
    var simple: Array[Rect2] = [Rect2(100,100,40,100)]
    var bounds := Rect2(0,0,1000,1000)
    var hit := Collision.move(Vector2(50,150),Vector2(300,20),Vector2(850,100),simple,0,bounds)
    check(hit.position.x < 100 and is_equal_approx(hit.position.y,170), "fast boost must stop at rock and preserve tangent movement")
    check(hit.velocity.x == 0 and hit.velocity.y == 100, "only the blocked velocity component should stop")
    var overlap: Array[Rect2] = [Rect2(100,100,80,80),Rect2(150,100,80,80)]
    var recovered := Collision.recover(Vector2(160,140),overlap,20,bounds)
    check(not Collision.blocked(recovered,overlap,20), "recovery must clear adjacent overlapping margins")
    for scene in root.get_node("AdventureRun").SCENES:
        var level = load(scene).instantiate()
        root.add_child(level)
        level.set_physics_process(false)
        level.fallen = true
        level.boss_hp = 99
        var margin: float = level.HERO_RADIUS * .73
        for rock in level.obstacles:
            var box: Rect2 = rock.grow(margin)
            # A landing inside a collision margin previously restored the same
            # invalid previous position forever. Test all rock centers and edges.
            for point in [box.get_center(), Vector2(box.get_center().x,box.position.y+1),Vector2(box.get_center().x,box.end.y-1),Vector2(box.position.x+1,box.get_center().y),Vector2(box.end.x-1,box.get_center().y)]:
                level.player = point
                level.player_velocity = Vector2.ZERO
                level.leap_phase = ""
                level._update_swimming(0)
                check(not Collision.blocked(level.player,level.obstacles,margin),scene+" overlap recovery")
                level.player_velocity = Vector2(0,300)
                level.boost_time = .3
                for tick in range(5): level._update_swimming(1.0/60.0)
                check(not Collision.blocked(level.player,level.obstacles,margin),scene+" escape movement")
                level.boost_time = 0
                # Descend directly over every ceiling rock as a real jump.
                if rock.position.y < 340:
                    level.player = Vector2(box.get_center().x,box.position.y-2)
                    level.player_velocity = Vector2(0,500)
                    level.leap_phase = "airborne"
                    level.jump_time = 10
                    level._update_swimming(.016)
                    check(not Collision.blocked(level.player,level.obstacles,margin),scene+" jump landing")
                    level.player_velocity = Vector2(600,0)
                    level.boost_time = 1
                    level.leap_phase = ""
                    level.jump_time = 0
                    for tick in range(12): level._update_swimming(.016)
                    check(not Collision.blocked(level.player,level.obstacles,margin),scene+" post-jump movement")
                level.boost_time = 0
                level.leap_phase = ""
                level.jump_time = 0
        level.free()
    print("ROCK RESCUE: ",checks," checks, ",failures," failures")
    quit(1 if failures else 0)

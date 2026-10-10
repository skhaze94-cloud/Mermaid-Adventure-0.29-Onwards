extends SceneTree
## Actual Godot sprite/shader renders. The roster is a QA showcase, not a new level.
const Art = preload("res://godot/creature_art.gd")
const Pool = preload("res://godot/animated_enemies.gd")
const Boss = preload("res://godot/carlo_boss.gd")
var output := "res://godot/enemy-previews"
func _initialize() -> void:
    call_deferred("_capture")
func label(parent: Node, text: String, at: Vector2, size: int, width: float = 380.0) -> void:
    var line := Label.new()
    line.text = text
    line.position = at
    line.size = Vector2(width, size + 15)
    line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    line.add_theme_font_size_override("font_size", size)
    line.add_theme_color_override("font_color", Color("#fff0c9"))
    parent.add_child(line)
func save_frame(name: String) -> void:
    await process_frame
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    image.save_png(ProjectSettings.globalize_path(output + "/" + name + ".png"))
    print("ENEMY PREVIEW CAPTURED: " + name)
func _capture() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
    var board := Node2D.new()
    root.add_child(board)
    var background := Sprite2D.new()
    background.texture = load("res://godot/assets/waterfall-cavern-v07.webp")
    background.position = Vector2(700,480)
    background.scale = Vector2(1400,960) / background.texture.get_size()
    background.modulate = Color(0.28,0.45,0.53)
    board.add_child(background)
    label(board,"HIGHLAND GOLD · A LIVELIER UNDERWATER WORLD",Vector2(0,25),31,1400)
    label(board,"Six creature families, painted combat poses and a grand new Carlo",Vector2(0,72),19,1400)
    var pool := Pool.new()
    board.add_child(pool)
    var data: Array[Dictionary] = []
    var species := ["crab", "eel", "jelly", "puffer", "swordfish", "shark"]
    var names := ["Coral-claw crab", "Golden-fin eel", "Lantern jellyfish", "Pearl puffer", "Sapphire swordfish", "Gentleman shark"]
    for i in range(species.size()):
        var at := Vector2(245.0 + (i % 3) * 420.0, 245.0 + (i / 3) * 255.0)
        data.append({"kind":species[i],"x":at.x,"y":at.y,"hp":1,"phase":float(i),"dir":1,"mode":"patrol"})
        label(board,names[i],at + Vector2(-190,131 if species[i] == "jelly" else 96),23)
    pool.bind_enemies(data)
    pool.animate_visible(0,2,false,0.04)
    for sprite in pool.sprites: sprite.scale *= 1.38
    var carlo := Boss.new()
    board.add_child(carlo)
    carlo.set_boss_state(5,true,1.0,700,780,1400,"recover",0)
    label(board,"CARLO · THE CRAB KING",Vector2(65,739),28,360)
    label(board,"Top hat. Monocle. Magnificent claws.",Vector2(70,786),17,350)
    label(board,"PATROL → WARN → ATTACK → RECOVER",Vector2(995,749),19,370)
    label(board,"Poses follow the encounter",Vector2(990,787),18,375)
    await save_frame("01-creature-roster")
    for i in range(4):
        for creature in data: creature["mode"] = ["patrol","windup","attack","recover"][i]
        pool.animate_visible(0,2,false,0.04)
        for sprite in pool.sprites: sprite.scale *= 1.38
        carlo.set_boss_state(5,i==3,1,700,780,1400,["patrol","windup","attack","recover"][i],0)
        await save_frame("pose-%d" % i)
    root.remove_child(board)
    board.free()
    print("GODOT ENEMY RENDER TEST PASSED")
    quit(0)

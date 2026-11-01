extends SceneTree
var checks := 0
var failures := 0

func _initialize() -> void:
    call_deferred("run")

func check(condition: bool, message: String) -> void:
    checks += 1
    if not condition:
        failures += 1
        push_error("TUTORIAL REEF 0.30: " + message)

func run() -> void:
    var folder := "res://godot/assets/tutorial-v030/"
    var files := DirAccess.get_files_at(folder)
    check(files.size() >= 30, "tutorial asset folder contains the expected new texture and sprite set")
    for file_name in files:
        if file_name.get_extension().to_lower() not in ["png", "webp"]:
            continue
        var texture = load(folder + file_name)
        check(texture is Texture2D, "asset imports as a Texture2D: " + file_name)
        if texture is Texture2D:
            check(texture.get_width() >= 128 and texture.get_height() >= 64,
                "asset has usable dimensions: " + file_name)
    var reef_script = load("res://godot/tutorial_reef_beauty.gd")
    check(reef_script != null, "tutorial reef helper script loads")
    var tutorial_scene = load("res://godot/training_lagoon.tscn")
    check(tutorial_scene != null, "tutorial scene loads")
    if tutorial_scene:
        var tutorial = tutorial_scene.instantiate()
        root.add_child(tutorial)
        await process_frame
        check(tutorial.get_script().resource_path == "res://godot/avina_tutorial.gd",
            "only the tutorial scene uses the updated chapter controller")
        tutorial.queue_free()
        await process_frame
    print("TUTORIAL REEF 0.30: %d checks, %d failures" % [checks, failures])
    quit(0 if failures == 0 else 1)

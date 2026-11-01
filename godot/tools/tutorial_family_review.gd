extends SceneTree
const OUTPUT := "res://verification/family-tutorial"
var out_path := ProjectSettings.globalize_path(OUTPUT)
var review_clock := 0.0

func _initialize() -> void:
	call_deferred("run")

func frame() -> void:
	await process_frame
	await RenderingServer.frame_post_draw

func capture(name: String) -> void:
	await frame()
	root.get_texture().get_image().save_png(out_path + "/" + name + ".png")

func pose_pair(scene, king_mode: String, queen_mode: String, seconds: float) -> void:
	var frames := ceili(seconds * 60.0)
	for _i in range(frames):
		review_clock += 1.0 / 60.0
		scene.king.animate(review_clock, king_mode, false)
		scene.queen_teacher.animate(review_clock, queen_mode, false)
		await frame()

func run() -> void:
	DirAccess.make_dir_recursive_absolute(out_path)
	root.size = Vector2i(1400, 960)
	Engine.time_scale = 1.0
	var prefs = root.get_node("AppPreferences")
	prefs.persist_enabled = false
	prefs.reduced_motion = false
	prefs.economy = false
	root.get_node("AdventureRun").active = false
	root.get_node("OceanAudio").playback_enabled = false
	var scene = load("res://godot/training_lagoon.tscn").instantiate()
	root.add_child(scene)
	await frame()
	await frame()
	scene.music_player.stop()
	scene.music_player.stream = null
	scene.set_process(false)
	scene.set_physics_process(false)
	scene.native_rig.set_process(false)
	scene._close_dialogue()
	scene.lesson = 6
	scene.arrival_time = 2.6
	scene.player = Vector2(5500, 570)
	scene.camera = 5000
	scene.king_world = Vector2(5150, 480)
	scene.queen_world = Vector2(6100, 520)
	scene._show_lesson()
	scene._sync_native_visuals()
	scene.king.position = Vector2(245, 430)
	scene.queen_teacher.position = Vector2(980, 430)
	scene.king.visible = true
	scene.queen_teacher.visible = true
	await pose_pair(scene, "idle", "idle", 1.0)
	await capture("family-idle")
	await pose_pair(scene, "wave", "wave", 1.2)
	await capture("family-wave")
	await pose_pair(scene, "talk", "listen", 1.2)
	await capture("daddy-speaks-antonella-listens")
	await pose_pair(scene, "listen", "talk", 1.2)
	await capture("antonella-speaks-daddy-listens")
	await pose_pair(scene, "swim", "cast", 1.2)
	await capture("family-swim-and-pearl-cast")
	await pose_pair(scene, "celebrate", "celebrate", 1.0)
	await capture("family-celebrate")

	# Exercise the real tutorial dialogue pause path. The actor child nodes remain
	# process-always; the tutorial and its gameplay clock stay paused.
	scene.king.position = Vector2(245, 430)
	scene.queen_teacher.position = Vector2(980, 430)
	scene._open_dialogue("intro")
	for _i in range(75):
		await frame()
	await capture("paused-daddy-speaks")
	scene._close_dialogue()
	scene._open_dialogue("gifts")
	for _i in range(75):
		await frame()
	await capture("paused-antonella-speaks")
	scene._close_dialogue()
	scene.free()
	await frame()
	print("TUTORIAL FAMILY REVIEW COMPLETE")
	quit()

extends SceneTree
var checks:=0
func verify(value: bool,message: String) -> void:
    checks+=1
    if not value:push_error(message);quit(1)
func _initialize() -> void:call_deferred("run")
func run() -> void:
    root.get_node('AppPreferences').persist_enabled=false
    root.get_node('AppPreferences').intro_seen=true
    root.get_node('AdventureRun').persist_enabled=false
    root.get_node('OceanAudio').playback_enabled=false
    var catalog=root.get_node('AdventureRun')
    for path in catalog.SCENES:verify(ResourceLoader.exists(path),'Missing packaged chapter '+path)
    var scene=load('res://godot/training_lagoon.tscn').instantiate()
    root.add_child(scene)
    for i in range(3):await process_frame
    scene.set_process(false);scene.set_physics_process(false)
    verify(scene.treasure_gallery.actors.size()==5,'All five painted treasure actors packaged')
    verify(scene.king.model_root!=null,'King Meshy model packaged')
    verify(scene.queen_teacher.model_root!=null,'Antonella Meshy model packaged')
    verify(scene.king.mesh is Sprite2D,'Royal viewport composite active')
    verify(scene.deep_routes.profiles.size()==2,'Both tutorial grottoes packaged')
    scene._open_dialogue('gifts')
    verify(paused and scene.dialogue_card.visible,'Packaged dialogue opens')
    scene._close_dialogue()
    verify(not paused,'Packaged dialogue resumes')
    scene.player_velocity=Vector2(100,0);scene._process(4.1)
    verify(scene.lesson==1,'Packaged tutorial exploration starts lessons')
    scene.free();await process_frame
    print('EXPORTED WINDOWS PACK: ',checks,' checks, 0 failures')
    quit()

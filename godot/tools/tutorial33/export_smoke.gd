extends SceneTree
var checks:=0
var failures:=0
func verify(value: bool,message: String) -> void:
    checks+=1
    if not value:failures+=1;push_error(message)
func _initialize() -> void:call_deferred('run')
func run() -> void:
    root.get_node('AppPreferences').persist_enabled=false
    root.get_node('AppPreferences').intro_seen=true
    root.get_node('AdventureRun').persist_enabled=false
    root.get_node('OceanAudio').playback_enabled=false
    verify(ProjectSettings.get_setting('application/config/version')=='0.33.0','Correct packaged version')
    var catalog=root.get_node('AdventureRun')
    for path in catalog.SCENES:verify(ResourceLoader.exists(path),'Missing packaged chapter '+path)
    for filename in ['reef-formations','coral-gardens','treasure-plinths','swim-wreaths','descent-passages']:
        var path='res://godot/assets/tutorial-v033/'+filename+'.png'
        verify(ResourceLoader.exists(path) and load(path).get_size().x>1000,'Missing new painting '+filename)
    for path in ['res://godot/source/levels-v82.json','res://godot/assets/whimsy-four/cast.json']:
        verify(FileAccess.file_exists(path) and JSON.parse_string(FileAccess.get_file_as_string(path))!=null,'Packaged JSON data '+path)
    var scene=load('res://godot/training_lagoon.tscn').instantiate();root.add_child(scene)
    for i in range(3):await process_frame
    scene.set_process(false);scene.set_physics_process(false)
    verify(scene.art_director.gardens.size()==8,'All eight unique gardens packaged')
    verify(scene.treasure_gallery.actors.size()==5,'All five treasure actors packaged')
    verify(scene.king.model_root!=null,'King Meshy model packaged')
    verify(scene.queen_teacher.model_root!=null,'Antonella Meshy model packaged')
    verify(scene.king.mesh is Sprite2D,'Royal viewport composite active')
    verify(scene.deep_routes.profiles.size()==2,'Both tutorial grottoes packaged')
    scene._open_dialogue('gifts')
    verify(paused and scene.dialogue_card.visible,'Packaged dialogue opens')
    scene._close_dialogue();verify(not paused,'Packaged dialogue resumes')
    scene.player_velocity=Vector2(100,0);scene._process(4.1)
    verify(scene.lesson==1,'Packaged tutorial exploration starts lessons')
    scene.player=Vector2(700,1400);scene.camera=210;scene.deep_routes.sync(true);scene._sync_native_visuals()
    scene.neighbourhood.quiet=false;scene.neighbourhood._speak(0,'Hello, Sarah!');scene.neighbourhood_art.sync()
    for i in range(3):await process_frame
    scene.neighbourhood_art.sync()
    verify(scene.neighbourhood_art.caption.size.y<135,'Packaged caption shrinks to short text')
    scene.free();await process_frame
    print('EXPORTED WINDOWS PACK: ',checks,' checks, ',failures,' failures')
    quit(1 if failures else 0)

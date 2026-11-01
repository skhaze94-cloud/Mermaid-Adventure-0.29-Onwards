extends SceneTree
func _initialize() -> void:call_deferred('run')
func run() -> void:
    root.get_node('AppPreferences').persist_enabled=false;root.get_node('AppPreferences').intro_seen=true;root.get_node('AdventureRun').persist_enabled=false;root.get_node('OceanAudio').playback_enabled=false
    for chapter in [7,0,1,2,3,4,5,6]:
        var scene=load(root.get_node('AdventureRun').SCENES[chapter]).instantiate();root.add_child(scene);scene.set_process(false);scene.set_physics_process(false);await process_frame
        for i in range(scene.deep_routes.water_shapes.size()):print(chapter,' ',scene.deep_routes.profiles[i]['id'],' polygon=',scene.deep_routes.water_shapes[i].size(),' indices=',Geometry2D.triangulate_polygon(scene.deep_routes.water_shapes[i]).size())
        scene.free();await process_frame
    quit()

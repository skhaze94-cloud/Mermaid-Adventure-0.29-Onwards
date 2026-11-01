extends SceneTree
func _initialize() -> void:call_deferred('run')
func frame() -> void:await process_frame;await RenderingServer.frame_post_draw
func run() -> void:
    root.size=Vector2i(1200,900)
    root.get_node('AppPreferences').persist_enabled=false;root.get_node('OceanAudio').playback_enabled=false
    var actor=load('res://godot/family_royal_actor.gd').new();actor.role=OS.get_environment('ROYAL_ROLE');root.add_child(actor);actor.position=Vector2(600,450);actor.configure(actor.role,850)
    for i in range(8):await frame()
    actor.set_process(false)
    for yaw in [0.0,.7,-.7]:
        actor.model_root.rotation.y=yaw
        for i in range(4):await frame()
        root.get_texture().get_image().save_png(OS.get_environment('ROYAL_OUT')+'/%s-%s.png'%[actor.role,str(yaw)])
    var mesh:MeshInstance3D=actor.model_root.find_child('*',true,false)
    print('ROOT children ',actor.model_root.get_children());quit()

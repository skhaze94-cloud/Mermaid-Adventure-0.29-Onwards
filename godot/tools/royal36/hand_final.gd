extends SceneTree
func _initialize() -> void:call_deferred('run')
func frame() -> void:await process_frame;await RenderingServer.frame_post_draw
func run() -> void:
    root.size=Vector2i(1200,900);root.get_node('AppPreferences').persist_enabled=false;root.get_node('OceanAudio').playback_enabled=false
    var actor=load('res://godot/family_royal_actor.gd').new();root.add_child(actor);actor.position=Vector2(600,450);actor.configure('king',850);actor.set_process(false)
    for i in range(6):await frame()
    var clock:=0.0
    for mode in ['idle','wave','cast']:
        actor.set_attention(-.8)
        for i in range(60):clock+=1.0/60;actor.animate(clock,mode,false)
        for i in range(3):await frame()
        root.get_texture().get_image().save_png(OS.get_environment('ROYAL_OUT')+'/king-'+mode+'.png')
    actor.free();await frame();print('ROYAL FINAL AXIS-BOUND HAND REVIEW COMPLETE');quit()

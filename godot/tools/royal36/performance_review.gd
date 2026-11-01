extends SceneTree
var out:=OS.get_environment('ROYAL_OUT')
func _initialize() -> void:call_deferred('run')
func frame() -> void:await process_frame;await RenderingServer.frame_post_draw
func run() -> void:
    root.size=Vector2i(1200,900);root.get_node('AppPreferences').persist_enabled=false;root.get_node('OceanAudio').playback_enabled=false
    for role in ['king','queen']:
        var actor=load('res://godot/family_royal_actor.gd').new();actor.role=role;root.add_child(actor);actor.position=Vector2(600,450);actor.configure(role,850)
        for i in range(8):await frame()
        actor.set_process(false)
        var timeline:=0.0
        for mode in ['idle','wave','talk','listen','cast','celebrate','swim']:
            actor.set_attention(-1 if role=='king' else 1);actor.set_travel(Vector2(100,0) if mode=='swim' else Vector2.ZERO)
            for i in range(60):
                timeline+=1.0/60;actor.animate(timeline,mode,false)
            for i in range(3):await frame()
            root.get_texture().get_image().save_png(out+'/'+role+'-'+mode+'.png')
            print('ROYAL36 ',role,' ',mode,' head=',actor.connected_skin.head_motion,' hand=',actor.connected_skin.hand_motion,' bones=',actor.connected_skin.skeleton.get_bone_count(),' vertices=',actor.connected_skin.vertex_count)
        actor.free();await frame()
    print('ROYAL36 PERFORMANCE CAPTURES COMPLETE');quit()

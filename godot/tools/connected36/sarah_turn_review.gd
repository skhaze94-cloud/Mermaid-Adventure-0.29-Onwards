extends SceneTree
var output:=OS.get_environment('SARAH36_OUT')
func _initialize() -> void:call_deferred('run')
func frame() -> void:await process_frame;await RenderingServer.frame_post_draw
func run() -> void:
    root.content_scale_size=Vector2i(1000,640);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.size=Vector2i(1000,640)
    root.get_node('AppPreferences').persist_enabled=false;root.get_node('OceanAudio').playback_enabled=false
    var bg:=ColorRect.new();bg.color=Color('#173d49');bg.size=Vector2(1000,640);root.add_child(bg)
    var rig=load('res://godot/sarah_rig.gd').new();root.add_child(rig);rig.set_process(false)
    rig.gesture_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    rig.jump_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
    Engine.time_scale=0;rig.reset_performance();rig.set_steering(Vector2.RIGHT);rig.set_motion(Vector2(280,0),1,false,false,1)
    for i in range(120):rig._process(1.0/60)
    for i in range(46):
        rig.set_steering(Vector2.LEFT);rig.set_motion(Vector2(-280,0),-1,false,false,1);rig._process(1.0/60)
        rig.position=Vector2(550,270);rig.scale*=2.2
        if true:
            await frame();root.get_texture().get_image().save_png(output+'/turn_%02d.png'%i)
    rig.reset_jump();rig.reset_performance();rig.set_motion(Vector2(280,0),1,false,false,1)
    for i in range(120):rig._process(1.0/60)
    rig.position=Vector2(550,270);rig.scale*=2.2;await frame();root.get_texture().get_image().save_png(output+'/side.png')
    print('SARAH36 TURN REVIEW COMPLETE');quit()

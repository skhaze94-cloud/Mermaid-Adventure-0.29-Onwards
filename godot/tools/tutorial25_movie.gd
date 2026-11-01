extends "res://godot/tools/little_moments_movies.gd"
func run() -> void:
    Engine.time_scale=0;root.content_scale_size=Vector2i(1400,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(1280,720)
    var prefs=root.get_node("AppPreferences");prefs.persist_enabled=false;prefs.intro_seen=true;prefs.reduced_motion=false;prefs.economy=false
    root.get_node("AdventureRun").active=false;root.get_node("AdventureRun").avina_along=false;root.get_node("OceanAudio").playback_enabled=false
    var scene=await load_scene(7);scene._close_dialogue();scene.lesson=1;scene.arrival_time=2.6;scene.arrival_intro_pending=false;scene._show_lesson();place(scene,Vector2(660,770))
    for i in range(4*int(FPS)):step(scene,Vector2(660,1230));await capture("tutorial25")
    var model=scene.neighbourhood
    for resident in range(2):
        var at: Vector2=model.profile["people"][resident]["talk_at"]+Vector2(155 if resident==0 else -155,-25)
        place(scene,at);model.chat_actor=-1;model.chat_left=0;model.reply_pending="";model.chat_wait=.5
        for i in range(8*int(FPS)):step(scene,at);await capture("tutorial25")
    var keeper: Vector2=scene.little_moments.keeper_point-Vector2(150,50)
    place(scene,keeper)
    for i in range(8*int(FPS)):step(scene,keeper);await capture("tutorial25")
    scene._advance_lesson(6);scene._close_dialogue();scene.queen_demo=10;place(scene,Vector2(5500,580));scene.king_world=Vector2(5150,490);scene.queen_world=Vector2(6100,530)
    for i in range(6*int(FPS)):
        step(scene,Vector2(5500+sin(float(i)/FPS)*35,580));await capture("tutorial25")
    await retire(scene);print("TUTORIAL25 MOVIE COMPLETE 34 seconds");quit()

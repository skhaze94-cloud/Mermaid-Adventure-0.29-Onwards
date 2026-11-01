extends SceneTree
var checks:=0
var failures:=0
func verify(value: bool,note: String) -> void:
    checks+=1
    if not value:failures+=1;push_error(note)
func _initialize() -> void:call_deferred('run')
func run() -> void:
    root.get_node('AppPreferences').persist_enabled=false;root.get_node('AppPreferences').intro_seen=true
    root.get_node('AdventureRun').persist_enabled=false;root.get_node('AdventureRun').active=false
    root.get_node('OceanAudio').playback_enabled=false
    verify(ProjectSettings.get_setting('application/config/version')=='0.39.0','Packaged version')
    verify(ResourceLoader.exists('res://godot/assets/pearl38/charms.png'),'New painted charm atlas packaged')
    verify(load('res://godot/assets/pearl38/charms.png').get_width()>1000,'Full-resolution charm atlas')
    for name in ['friends','rootgarden','cathedral','archive','moonpool','coraltheatre','limestone']:
        var path='res://godot/assets/cavern-v034/'+name+'.png'
        verify(ResourceLoader.exists(path) and load(path).get_width()>1000,'Packaged painting '+name)
    for path in ['res://godot/source/levels-v82.json','res://godot/assets/whimsy-four/cast.json']:
        verify(FileAccess.file_exists(path) and JSON.parse_string(FileAccess.get_file_as_string(path))!=null,'Packaged data '+path)
    var rooms:=0;var friends:=0
    for chapter in [7,0,1,2,3,4,5,6]:
        var path: String=root.get_node('AdventureRun').SCENES[chapter]
        verify(ResourceLoader.exists(path),'Packaged chapter '+path)
        var scene=load(path).instantiate();root.add_child(scene);scene.set_process(false);scene.set_physics_process(false)
        for i in range(3):await process_frame
        paused=false;scene.message_time=0
        if chapter==6:scene.boss_hp=0
        for enemy in scene.enemies:enemy['hp']=0
        if chapter==7:
            scene._close_dialogue();verify(scene.king.model_root!=null and scene.queen_teacher.model_root!=null,'Both royal Meshy models retained')
            verify(scene.mesh_y_friends!=null and scene.mesh_y_friends.viewport!=null,'New tutorial shared viewport packaged');verify(scene.treasure_gallery.actors.size()==5 and scene.art_director.gardens.size()==8,'Tutorial chest and garden update retained')
            scene._open_dialogue('gifts');verify(paused and scene.dialogue_card.visible,'Dialogue opens');scene._close_dialogue();verify(not paused,'Dialogue resumes')
        for polygon in scene.deep_routes.water_shapes:verify(not Geometry2D.triangulate_polygon(polygon).is_empty(),'Packaged cavern geometry triangulates');rooms+=1
        verify(scene.neighbourhood_art.actors.size()==scene.neighbourhood.profile['people'].size(),'Packaged resident textures and actors')
        for index in range(scene.neighbourhood.profile['people'].size()):
            var person: Dictionary=scene.neighbourhood.profile['people'][index];friends+=1
            if chapter==0:scene.fallen=int(person['room_index'])>0
            scene.checkpoint=maxf(scene.checkpoint,scene._left_bound())
            scene.player=person['talk_at'];scene.player_velocity=Vector2.ZERO;scene.boost_time=0;scene.leap_phase='';scene.message_time=0
            scene.neighbourhood.clear_transients();scene.living_reef.reactions.clear();scene.pocket_wonders.reactions.clear()
            for tick in range(18):scene.neighbourhood.advance(.1)
            verify(scene.score_book.seen.has(scene.neighbourhood.friend_key(index)),'Packaged friend gives a saved hello: '+String(person['id']))
        verify(scene._valid_checkpoint(scene._checkpoint_bundle()),'Packaged friend checkpoint validates in chapter '+str(chapter))
        var rig=scene.native_rig;rig.set_process(false);rig.reset_jump();rig.reset_performance()
        for i in range(30):
            rig.set_steering(Vector2.RIGHT);rig.set_motion(Vector2(280,0),1,false,false,1);rig._process(1.0/60)
        verify(rig.grace_motion.phase>0 and rig.arm_pose_near.length()>.01,'Packaged Grace animation runs in chapter '+str(chapter))
        verify(rig.definitive_21.attachment_error(rig,1)<.0001,'Packaged shoulder remains attached')
        rig.set_steering(Vector2(-.12,0));rig.set_motion(Vector2(-41.4,0),-1,false,false,1)
        for i in range(20):rig._process(1.0/60)
        verify(rig.grace_motion.presentation_facing==-1,'Packaged light-stick reversal completes')
        if chapter==7:
            for actor in [scene.king,scene.queen_teacher]:
                var skeletons: Array=actor.find_children("*","Skeleton3D",true,false)
                verify(skeletons.size()>0 and skeletons[0].get_bone_count()>=16,'Packaged royal articulation has real bones')
                verify(actor.has_method('react'),'Packaged royal actor has event reactions')
            verify(scene.family_attention!=null,'Packaged tutorial owns family interaction cues')
        scene.free();await process_frame
    verify(rooms==15 and friends==22,'All caverns and neighbourhood friends packaged, plus original Dozy')
    print('EXPORTED v0.39 WINDOWS PACK: ',checks,' checks, ',failures,' failures; ',rooms,' caverns, ',friends,' residents plus Dozy')
    quit(1 if failures else 0)

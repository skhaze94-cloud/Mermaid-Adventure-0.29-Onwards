extends SceneTree
## Regression of the tutorial-only visual adapter against real gameplay state.
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred('run')
func check(ok: bool,note: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error('TUTORIAL MESHY: '+note)
func run() -> void:
    root.get_node('AppPreferences').persist_enabled=false;root.get_node('AppPreferences').intro_seen=true
    root.get_node('AdventureRun').persist_enabled=false;root.get_node('AdventureRun').active=false;root.get_node('OceanAudio').playback_enabled=false
    var scene=load('res://godot/training_lagoon.tscn').instantiate();root.add_child(scene)
    await process_frame
    scene.set_process(false);scene.set_physics_process(false)
    if scene.dialogue_open:scene._close_dialogue()
    scene.state='playing';scene.arrival_intro_pending=false
    var stage=scene.mesh_y_friends
    check(stage.viewport.own_world_3d,'shared viewport isolates tutorial models')
    check(scene.pocket_wonders_art.replacement_painter.is_valid(),'tutorial alone installs painted-character adapter')
    var score_before: int=scene.score
    var treasure_before: Array=scene.treasures.duplicate(true)
    scene.player=Vector2(900,1450);scene.camera=0;scene.deep_routes.sync(true);scene._sync_native_visuals()
    for tick in range(50):scene.time=float(tick)*.05;stage._process(.05)
    check(scene.score==score_before and scene.treasures==treasure_before,'visual animation cannot mutate pickups or rewards')
    var count:=0
    for key in stage.actors:
        var a=stage.actors[key]
        if String(key).begins_with('chest:'):
            count+=1;check(a.model_id in [8,9,10,11] and a.hinges.size()==1,'every tutorial chest has a supplied model and actual lid hinge')
        if String(key).begins_with('neighbour:'):
            check(a.joints.size()>0,'new sea friend has independently controlled joints')
    check(count==5,'all three surface and two cavern chests replaced')
    check(stage.actors['neighbour:0'].model_id==1,'beloved slug postman appears in nursery')
    check(stage.actors['keeper'].model_id==3,'frog king keeps Bellflower lantern interaction')
    for old in scene.treasure_gallery.actors.values():check(not old.visible,'old chest painting hidden')
    for old in scene.neighbourhood_art.actors:check(not old.visible,'old sea-friend painting hidden')
    scene._advance_lesson(7)
    scene.camera=5000;scene.player=Vector2(5600,580);scene.deep_routes.sync(true);scene._sync_native_visuals();stage._process(.1)
    check(scene.enemies.size()==3 and not scene.animated_enemies.visible,'practice opponents retain all three gameplay records; old sprites hidden')
    for i in range(3):
        var a=stage.actors['enemy:'+str(i)]
        check(a.model_id==[2,0,4][i] and a.joints.size()>0,'practice volunteer model is appropriate and articulated')
        scene.enemies[i].hp=0
    stage._process(.1)
    for i in range(3):check(not stage.actors['enemy:'+str(i)].visible,'completed practice volunteer visual clears')
    var chest_item: Dictionary=scene.treasures[0]
    check(chest_item.kind=='chest','test targets real first chest')
    scene.camera=0;scene.player=Vector2(chest_item.x,chest_item.y);scene.deep_routes.sync(true)
    var a=stage.actors['chest:'+scene.treasure_gallery.key_for(chest_item)]
    chest_item.taken=true
    for i in range(30):scene.time+=.05;stage._process(.05)
    check(a.open_amount>.99 and a.hinges[0].rotation.x<-.9,'collected chest lid opens structurally')
    scene.retry_serial+=1;stage._process(.1)
    check(a.open_amount==1 and chest_item.taken,'remembered chest resumes open after retry')
    stage._process(.1)
    scene.state='paused';paused=true
    var before: Quaternion=stage.actors['neighbour:0'].skeleton.get_bone_pose_rotation(stage.actors['neighbour:0'].joints[0].bone)
    for i in range(5):stage._process(.1)
    check(stage.actors['neighbour:0'].skeleton.get_bone_pose_rotation(stage.actors['neighbour:0'].joints[0].bone)==before,'pause freezes joint animation')
    check(stage.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED,'pause stops repeated 3D rendering')
    paused=false;scene.state='playing';scene.reduced_fx=true;scene.high_depth_quality=false;stage._process(.1)
    check(a.open_amount==1,'Gentle Motion and Economy retain coherent collected pose')
    root.size=Vector2i(1920,1080);await process_frame
    scene.player=Vector2(900,1450);scene.camera=0;scene.high_depth_quality=true;scene.deep_routes.sync(true);scene._sync_native_visuals();stage._process(.1)
    var size: Vector2=stage.viewport.size
    check(absf(size.x/size.y-1920.0/1080)<.003,'capped desktop viewport preserves aspect ratio')
    var friend=stage.actors['neighbour:0']
    var projected: Vector2=stage.camera.unproject_position(friend.global_position)*scene.get_viewport_rect().size/size
    var expected: Vector2=scene.neighbourhood.profile.people[0].foot-Vector2(scene.camera,scene.neighbourhood.profile.people[0].height*.5+scene._camera_y())
    check(projected.distance_to(expected)<1.0,'3D friend stays registered to its world anchor at capped resolution')
    var bone: int=friend.joints[0].bone
    friend.perform(1,'idle',false,1,1);var first: Quaternion=friend.skeleton.get_bone_pose_rotation(bone)
    friend.perform(2,'talk',false,1,1)
    check(first.angle_to(friend.skeleton.get_bone_pose_rotation(bone))>.0001,'small gestures change actual joint poses independently of root motion')
    scene.free()
    var other=load('res://godot/highland_level.tscn').instantiate();root.add_child(other);await process_frame
    check(other.get_node_or_null('LivingTutorialModels')==null,'ordinary level never creates tutorial Meshy stage')
    check(not other.pocket_wonders_art.replacement_painter.is_valid(),'ordinary level retains original paintings')
    other.free();print('TUTORIAL MESHY: ',checks,' checks, ',failures,' failures');quit(1 if failures else 0)

extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,note: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error("ROYAL CONNECTED: "+note)
func _initialize() -> void:call_deferred("run")
func run() -> void:
    root.get_node('AppPreferences').persist_enabled=false;root.get_node('OceanAudio').playback_enabled=false
    var signatures:=[]
    for role in ['king','queen']:
        var actor=load('res://godot/family_royal_actor.gd').new();actor.role=role;root.add_child(actor);actor.set_process(false)
        var skin=actor.connected_skin
        var skeleton:Skeleton3D=skin.skeleton
        check(skin.binding_valid,'runtime skin binding failed')
        check(skeleton.get_bone_count()==(22 if role=='king' else 21),'anatomical skeleton absent')
        var mesh:MeshInstance3D=actor.model_root.get_child(0)
        var original=load('res://godot/assets/characters-v028/'+('king-daddy-3d' if role=='king' else 'queen-antonella-3d')+'.glb').instantiate()
        var old:MeshInstance3D=original.get_child(0)
        var arrays:=mesh.mesh.surface_get_arrays(0);var source:=old.mesh.surface_get_arrays(0)
        check(arrays[Mesh.ARRAY_VERTEX]==source[Mesh.ARRAY_VERTEX] and arrays[Mesh.ARRAY_TEX_UV]==source[Mesh.ARRAY_TEX_UV],'original painted geometry or UV changed')
        check(mesh.mesh.surface_get_material(0)==old.mesh.surface_get_material(0),'original painted material replaced')
        check(mesh.skin.get_bind_count()==skeleton.get_bone_count(),'skin inverse binds missing')
        var weights:PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS];var joints:PackedInt32Array=arrays[Mesh.ARRAY_BONES]
        var staff_count:=0
        for v in range(0,skin.vertex_count,17):
            var sum:=0.0
            for k in range(4):
                sum+=weights[v*4+k]
                check(joints[v*4+k]>=0 and joints[v*4+k]<skeleton.get_bone_count(),'joint index outside skeleton')
            check(absf(sum-1)<.0001,'skin weights do not sum to one')
        if role=='king':
            var staff:int=skin.bone_ids['staff']
            for v in range(skin.vertex_count):
                if joints[v*4]==staff and weights[v*4]>.999:
                    staff_count+=1
            check(staff_count>2000,'held staff lost its rigid binding')
            check(skeleton.get_bone_parent(staff)==skin.bone_ids['left_hand'],'staff does not follow gripping hand')
        var time:=0.0;var node_count:int=actor.get_child_count();var peak_hand:=0.0;var peak_head:=0.0
        var identity:Vector3=actor.model_root.scale
        for mode in ['idle','wave','talk','listen','cast','celebrate','swim']:
            actor.set_attention(.8);actor.set_travel(Vector2(120,0) if mode=='swim' else Vector2.ZERO)
            for i in range(90):
                time+=1.0/60;actor.animate(time,mode,false)
                for angle in skin.rotations:check(angle.is_finite() and angle.length()<.5,'pose exceeds inspected articulation envelope')
                peak_hand=maxf(peak_hand,skin.hand_motion);peak_head=maxf(peak_head,skin.head_motion)
            skeleton.force_update_all_bone_transforms()
            check(skin.hand_global_position().is_finite(),'cast palm projection invalid')
            check(actor.model_root.scale==identity,'breathing uniformly scales the whole model')
        check(peak_hand>.04 and peak_head>.03,'upper body remains a static statue')
        signatures.append(skin.rotations.duplicate())
        actor.react('hello')
        for i in range(60):time+=1.0/60;actor.animate(time,'idle',false)
        check(actor.pose=='wave' and skin.rotations[skin.bone_ids['right_lower']].length()>.05,'encounter does not articulate forearm')
        actor.set_dialogue_pose(false);time+=1.0/60;actor.animate(time,'wave',false)
        check(actor.pose=='listen','dialogue listener fails to override greeting')
        actor.end_dialogue_pose()
        for i in range(240):time+=1.0/60;actor.animate(time,'idle',false)
        check(actor.pose=='idle' and skin.hand_motion<.005,'finite gesture does not return to a rest')
        var clock:float=actor.clock;actor.hide();time+=.2;actor.animate(time,'wave',false)
        check(actor.clock==clock and actor.viewport.render_target_update_mode==SubViewport.UPDATE_DISABLED,'hidden royal still animates or renders')
        actor.show();actor.set_quality(false);time+=1.0/60;actor.animate(time,'idle',false)
        check(actor.viewport.render_target_update_mode!=SubViewport.UPDATE_WHEN_VISIBLE,'Economy lacks bounded viewport cadence')
        check(actor.get_child_count()==node_count and skin.build_count<=1,'steady motion rebuilds geometry or adds nodes')
        var second=load('res://godot/family_royal_actor.gd').new();second.role=role;root.add_child(second);second.set_process(false)
        check(second.connected_skin.build_count==0,'second instance rebuilds cached geometry')
        check(second.model_root.get_child(0).mesh==mesh.mesh,'same-role actors do not share derivative mesh')
        second.free();original.free();actor.free()
    check(signatures[0]!=signatures[1],'royals have identical performances')
    var helper=load('res://godot/royal_connected_skin.gd')
    var reference:=PackedVector3Array([Vector3(1,2,3),Vector3(4,5,6)])
    var current:=PackedVector3Array([reference[1],reference[0]])
    var fixture_joints:=PackedInt32Array([1,2,3,4,5,6,7,8])
    var fixture_weights:=PackedFloat32Array([.4,.3,.2,.1,.1,.2,.3,.4])
    var mapped:Dictionary=helper.remap_exact(reference,current,fixture_joints,fixture_weights)
    check(not mapped.has('error'),'exact reordered fixture is rejected')
    check(mapped['joints']==PackedInt32Array([5,6,7,8,1,2,3,4]),'joint remapping differs from exact vertex order')
    check(mapped['weights']==PackedFloat32Array([.1,.2,.3,.4,.4,.3,.2,.1]),'weights do not follow reordered vertices')
    current[0]=Vector3(40,5,6)
    check(helper.remap_exact(reference,current,fixture_joints,fixture_weights).has('error'),'changed geometry silently receives approximate weights')
    reference[1]=reference[0]
    check(helper.remap_exact(reference,reference,fixture_joints,fixture_weights).has('error'),'conflicting duplicate positions are accepted')
    fixture_joints=PackedInt32Array([1,2,3,4,1,2,3,4]);fixture_weights=PackedFloat32Array([.4,.3,.2,.1,.4,.3,.2,.1])
    check(not helper.remap_exact(reference,reference,fixture_joints,fixture_weights).has('error'),'identical duplicate positions are incorrectly rejected')
    await process_frame;print('ROYAL CONNECTED: ',checks,' checks, ',failures,' failures');quit(1 if failures else 0)

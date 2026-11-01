extends SceneTree
func _initialize() -> void:call_deferred('run')
func run() -> void:
    root.get_node('AppPreferences').persist_enabled=false;root.get_node('OceanAudio').playback_enabled=false
    for role in ['king','queen']:
        var actor=load('res://godot/family_royal_actor.gd').new();actor.role=role;root.add_child(actor);actor.set_process(false)
        for i in range(90):actor.animate(float(i)/60,'wave',false)
        var skin=actor.connected_skin;skin.skeleton.force_update_all_bone_transforms()
        var transforms:=[]
        for i in range(skin.skeleton.get_bone_count()):
            var t:Transform3D=skin.skeleton.get_bone_global_pose(i)*Transform3D(Basis.IDENTITY,skin.rest_positions[i]).affine_inverse()
            transforms.append([[t.basis.x.x,t.basis.y.x,t.basis.z.x,t.origin.x],[t.basis.x.y,t.basis.y.y,t.basis.z.y,t.origin.y],[t.basis.x.z,t.basis.y.z,t.basis.z.z,t.origin.z]])
        var file:=FileAccess.open('res://../audit36/royals/'+role+'-wave-transforms.json',FileAccess.WRITE);file.store_string(JSON.stringify(transforms));file.close()
        file=FileAccess.open('res://../audit36/royals/'+role+'-indices.bin',FileAccess.WRITE);file.store_buffer(actor.model_root.get_child(0).mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].to_byte_array());file.close();actor.free()
    quit()

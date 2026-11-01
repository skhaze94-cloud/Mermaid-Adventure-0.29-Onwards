extends SceneTree
func _initialize() -> void:
    for role in ['king','queen']:
        var scene=load('res://godot/assets/characters-v028/'+('king-daddy-3d' if role=='king' else 'queen-antonella-3d')+'.glb').instantiate()
        var mesh:MeshInstance3D=scene if scene is MeshInstance3D else scene.get_child(0)
        var arrays:Array=mesh.mesh.surface_get_arrays(0)
        print(role,' root ',scene,' mesh ',mesh,' meshtransform ',mesh.transform,' n=',arrays[Mesh.ARRAY_VERTEX].size(),' material ',mesh.mesh.surface_get_material(0))
        var file:=FileAccess.open('res://../audit36/royals/'+role+'-godot-vertices.bin',FileAccess.WRITE);file.store_buffer(arrays[Mesh.ARRAY_VERTEX].to_byte_array());file.close()
        scene.free()
    quit()

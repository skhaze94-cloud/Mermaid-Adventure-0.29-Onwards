extends RefCounted
## Audited spatial skin binding for the ORIGINAL painted royal meshes.
## One-time derivative ArrayMesh, GPU-deformed by a real Skeleton3D. No CPU
## vertex deformation or texture copy occurs during the performance.
static var mesh_cache: Dictionary={}
static var skin_cache: Dictionary={}
static var metadata_cache: Dictionary={}
var skeleton: Skeleton3D
var bone_ids: Dictionary={}
var rotations: Array[Vector3]=[]
var targets: Array[Vector3]=[]
var rest_positions: Array[Vector3]=[]
var vertex_count:=0
var build_count:=0
var body_role:=""
var pose_clock:=0.0
var hand_motion:=0.0
var head_motion:=0.0
var binding_valid:=false
var reordered_binding:=false
func bind(model: Node3D,role: String) -> bool:
    body_role=role
    var mesh:=_mesh_in(model)
    if mesh==null:return _fail("Royal model must contain its original mesh")
    if not metadata_cache.has(role):
        metadata_cache[role]=JSON.parse_string(FileAccess.get_file_as_string("res://godot/assets/royal-connected36/"+role+".bind.json"))
    var meta: Dictionary=metadata_cache[role]
    skeleton=Skeleton3D.new();skeleton.name="ConnectedRoyalSkeleton";model.add_child(skeleton)
    for b in meta["bones"]:
        var index:=skeleton.get_bone_count();skeleton.add_bone(b["name"]);bone_ids[b["name"]]=index
        rest_positions.append(Vector3(b["position"][0],b["position"][1],b["position"][2]))
        var parent: int=b["parent"]
        skeleton.set_bone_parent(index,parent)
        skeleton.set_bone_rest(index,Transform3D(Basis.IDENTITY,rest_positions[index]-(rest_positions[parent] if parent>=0 else Vector3.ZERO)))
        rotations.append(Vector3.ZERO);targets.append(Vector3.ZERO)
    skeleton.reset_bone_poses()
    if not mesh_cache.has(role):
        var data:=FileAccess.get_file_as_bytes("res://godot/assets/royal-connected36/"+role+".skin36")
        if data.size()<12 or data.slice(0,8).get_string_from_ascii()!="RW36SKIN":return _fail("Royal binding header")
        vertex_count=data.decode_u32(8)
        if data.size()!=12+20*vertex_count:return _fail("Royal binding byte length")
        var arrays:=mesh.mesh.surface_get_arrays(0)
        if arrays[Mesh.ARRAY_VERTEX].size()!=vertex_count:return _fail("Royal imported vertex count differs from audited source")
        var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(arrays[Mesh.ARRAY_VERTEX].to_byte_array())
        var imported_hash:=hash.finish().hex_encode()
        var joints:=PackedInt32Array();joints.resize(vertex_count*4)
        for i in range(joints.size()):joints[i]=data[12+i]
        var weights:=data.slice(12+vertex_count*4).to_float32_array()
        if imported_hash!=meta["source_vertices_sha256"]:
            var reference_bytes:=FileAccess.get_file_as_bytes("res://godot/assets/royal-connected36/"+role+".pos36")
            hash.start(HashingContext.HASH_SHA256);hash.update(reference_bytes)
            if reference_bytes.size()!=vertex_count*12 or hash.finish().hex_encode()!=meta["source_vertices_sha256"]:return _fail("Royal reference position data is invalid")
            var floats:=reference_bytes.to_float32_array();var reference:=PackedVector3Array();reference.resize(vertex_count)
            for i in range(vertex_count):reference[i]=Vector3(floats[i*3],floats[i*3+1],floats[i*3+2])
            var mapped:=remap_exact(reference,arrays[Mesh.ARRAY_VERTEX],joints,weights)
            if mapped.has("error"):return _fail(mapped["error"])
            joints=mapped["joints"];weights=mapped["weights"];reordered_binding=true
        arrays[Mesh.ARRAY_BONES]=joints
        arrays[Mesh.ARRAY_WEIGHTS]=weights
        var derivative:=ArrayMesh.new();derivative.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
        derivative.surface_set_material(0,mesh.mesh.surface_get_material(0))
        derivative.custom_aabb=mesh.mesh.get_aabb().grow(.22)
        mesh_cache[role]=derivative
        var skin:=Skin.new()
        for i in range(rest_positions.size()):skin.add_bind(i,Transform3D(Basis.IDENTITY,rest_positions[i]).affine_inverse())
        skin_cache[role]=skin;build_count+=1
    else:vertex_count=mesh_cache[role].surface_get_array_len(0)
    mesh.mesh=mesh_cache[role];mesh.skin=skin_cache[role];mesh.skeleton=mesh.get_path_to(skeleton)
    binding_valid=true
    return true

func _mesh_in(node: Node) -> MeshInstance3D:
    if node is MeshInstance3D:return node
    for child in node.get_children():
        var found:=_mesh_in(child)
        if found:return found
    return null
func _target(name: String,rotation: Vector3) -> void:
    if bone_ids.has(name):targets[bone_ids[name]]=rotation
func advance(dt: float,clock: float,mode: String,envelope: float,attention: float,travel: Vector2,quiet: bool) -> void:
    if dt<=0 or not binding_valid:return
    pose_clock+=dt
    for i in range(targets.size()):targets[i]=Vector3.ZERO
    var strength:=.30 if quiet else 1.0
    var king:=body_role=="king"
    var phase:=clock*(.83 if king else .71)+(0.0 if king else 1.93)
    # Quiet shared breathing and attention, with a connected chest/neck response.
    _target("waist",Vector3(0,attention*.01,-sin(phase-.6)*.004)*strength)
    _target("chest",Vector3(sin(phase)*.009,attention*.025,sin(phase-.4)*.006)*strength)
    _target("neck",Vector3(sin(phase*.43)*.012,attention*.075,(-.012 if king else .018))*strength)
    _target("head",Vector3(sin(phase*.59-.8)*.012,attention*.065,sin(phase*.37)*.012)*strength)
    var near:=Vector3.ZERO;var lower:=Vector3.ZERO;var wrist:=Vector3.ZERO
    var far:=Vector3.ZERO;var far_lower:=Vector3.ZERO;var far_wrist:=Vector3.ZERO
    var talk:=0.0
    if mode=="talk":
        # Phrases separated by genuine rests; not constant nodding/waving.
        var p:=fposmod(clock+(0.0 if king else 2.1),6.8)
        talk=smoothstep(.2,.8,p)*(1.0-smoothstep(2.2,3.2,p))
        _target("head",Vector3(sin(p*2.0)*.025*talk,attention*.085,(.014 if king else -.018)*talk)*strength)
        near=Vector3(-.035,.025,.085 if king else .055)*talk
        lower=Vector3(.015,-.035,.10 if king else .075)*talk
        wrist=Vector3(-.04,.035,.035)*talk
    elif mode=="listen":
        var p:=fposmod(clock+(0.0 if king else 2.7),8.5)
        var nod:=sin(clampf((p-1.0)/1.2,0,1)*TAU)*(smoothstep(.8,1.0,p)*(1.0-smoothstep(2.0,2.3,p)))
        _target("head",Vector3(nod*.025,attention*.09,.012 if king else -.02)*strength)
    match mode:
        "wave":
            near=Vector3(-.08,-.06,.18 if king else .12)*envelope
            lower=Vector3(.03,.04,.23 if king else .18)*envelope
            wrist=Vector3(-.05,sin(clock*5.0)*.085,.03)*envelope
        "cast":
            near=Vector3(-.06,-.045,.12 if king else .08)*envelope
            lower=Vector3(.02,-.025,.14)*envelope
            wrist=Vector3(-.09,.08,.045)*envelope
        "celebrate":
            near=Vector3(-.055,-.03,.16 if king else .11)*envelope
            lower=Vector3(.04,.02,.18)*envelope
            wrist=Vector3(-.03,.06,.04)*envelope
            _target("head",Vector3(-.035,attention*.08,-.025 if king else .025)*envelope*strength)
            far=Vector3(0,0,-.018 if king else -.06)*envelope
        "acknowledge":
            _target("head",Vector3(.04*envelope,attention*.09,-.015)*strength)
            wrist=Vector3(0,.05,.03)*envelope
        "hug":
            near=Vector3(-.09,-.08,.15)*envelope;lower=Vector3(0,-.08,.18)*envelope
            far=Vector3(0,0,-.012 if king else -.10)*envelope
        "swim","dash":
            near=Vector3(-.025,travel.x*.035,sin(phase)*.035)*travel.y
            lower=Vector3(.02,0,sin(phase-.8)*.05)*travel.y
            wrist=Vector3(sin(phase-1.4)*.025,0,0)*travel.y
    # The staff-side arm is deliberately restrained; the entire staff remains
    # rigidly weighted to that hand and shares its same bone chain.
    if not king:
        far+=Vector3(.015,0,-.025)*talk
        far_lower=Vector3(.02,0,-.035)*(talk+envelope*.3)
        far_wrist=Vector3(0,-.025,.025)*(talk+envelope*.3)
    _target("right_upper",near*strength);_target("right_lower",lower*strength);_target("right_hand",wrist*strength)
    _target("left_upper",far*strength);_target("left_lower",far_lower*strength);_target("left_hand",far_wrist*strength)
    var balance:=travel.x*.025+sin(phase*.7)*.008
    _target("pelvis",Vector3(travel.y*.012,0,-balance*.35)*strength)
    _target("left_thigh",Vector3(sin(phase-1.2)*.014+travel.y*.025,0,balance*.5)*strength)
    _target("right_thigh",Vector3(-sin(phase-1.2)*.012-travel.y*.015,0,balance*.4)*strength)
    _target("left_shin",Vector3(-.012*sin(phase-.7)*travel.y,0,0)*strength)
    _target("right_shin",Vector3(.015*sin(phase-.4)*travel.y,0,0)*strength)
    _target("cloth_left",Vector3(sin(phase-.6)*.018,0,sin(phase*.8)*.014)*strength)
    _target("cloth_right",Vector3(sin(phase-1.1)*.016,0,-sin(phase*.8-.7)*.012)*strength)
    _target("cloth_back",Vector3(sin(phase-.9)*.016,-travel.x*.015,0)*strength)
    _target("hair",Vector3(sin(phase-1.3)*.012,-attention*.025,sin(phase*.7-.6)*.009)*strength)
    var ease:=1.0-exp(-dt*10.0)
    for i in range(rotations.size()):
        rotations[i]=rotations[i].lerp(targets[i],ease)
        skeleton.set_bone_pose_rotation(i,Quaternion.from_euler(rotations[i]))
    hand_motion=rotations[bone_ids["right_hand"]].length() if bone_ids.has("right_hand") else 0.0
    head_motion=rotations[bone_ids["head"]].length() if bone_ids.has("head") else 0.0

func hand_global_position() -> Vector3:
    var offset:=Vector3(.12,-.01,.09) if body_role=="king" else Vector3(.14,.04,.02)
    return skeleton.to_global(skeleton.get_bone_global_pose(bone_ids["right_hand"])*offset)

func _fail(message: String) -> bool:
    push_error(message)
    return false

static func remap_exact(reference: PackedVector3Array,current: PackedVector3Array,joints: PackedInt32Array,weights: PackedFloat32Array) -> Dictionary:
    # Importer versions may reorder identical vertex positions. Never use nearest
    # neighbours: reject changed geometry and ambiguous duplicate skin weights.
    if reference.size()!=current.size() or joints.size()!=reference.size()*4 or weights.size()!=joints.size():return {"error":"Royal remap buffer sizes disagree"}
    var lookup: Dictionary={}
    for i in range(reference.size()):
        var point:=reference[i]
        if lookup.has(point):
            var previous: int=lookup[point]
            for k in range(4):
                if joints[previous*4+k]!=joints[i*4+k] or weights[previous*4+k]!=weights[i*4+k]:return {"error":"Duplicate royal positions have conflicting skin weights"}
        else:lookup[point]=i
    var reordered_joints:=PackedInt32Array();reordered_joints.resize(joints.size())
    var reordered_weights:=PackedFloat32Array();reordered_weights.resize(weights.size())
    for i in range(current.size()):
        if not lookup.has(current[i]):return {"error":"Royal importer changed geometry; exact skin remap refused"}
        var original: int=lookup[current[i]]
        for k in range(4):
            reordered_joints[i*4+k]=joints[original*4+k];reordered_weights[i*4+k]=weights[original*4+k]
    return {"joints":reordered_joints,"weights":reordered_weights}

extends RefCounted
## Single final owner for painted shoulder anchors, camera yaw and view blending.
const Spring=preload("res://godot/sarah_spine_motion.gd")
var heading:=Vector2(1,0)
var view:=Vector2.ZERO
var view_goal:=0.0
var opening:=false
var action:="idle"
var root_pivots: Array[Vector2]=[]
var sockets: Array[Vector2]=[]
var portrait: Sprite2D
var front_tail: MeshInstance2D
var front_body: MeshInstance2D
var front_arms: Array[MeshInstance2D]=[]
var face_material: ShaderMaterial
var anchor_indices: Array[PackedInt32Array]=[]
var anchor_weights: Array[Vector4]=[]
var front_weight:=0.0
var portrait_weight:=0.0
var socket_error:=0.0
const BodyView=preload("res://godot/sarah_body_view.gd")
var body_view=BodyView.new()
var arm_restore: Array[Transform2D]=[]
var has_restore:=false
var front_face:=false
var away_face:=false
var handoff_blink:=0.0
var collar_rig:=Vector2.ZERO
var step_dt:=1.0/60.0
var baseline_centers:=PackedVector2Array()
func reset() -> void:
    heading=Vector2(1,0);view=Vector2.ZERO;view_goal=0;front_weight=0;portrait_weight=0;action="idle"
    has_restore=false;front_face=false;away_face=false;handoff_blink=0
func bind(rig) -> void:
    for i in range(2):
        var mesh=rig.arm_meshes[i]
        var pivot: Vector2=mesh.painted_pivot(Vector2(.095,.43))
        root_pivots.append(pivot)
        for j in range(mesh.rest.size()):mesh.rest[j]-=pivot
        mesh.reset_shape()
        var socket:=Vector2(34,-25) if i==0 else Vector2(22,-28)
        socket+=pivot;sockets.append(socket)
        # Locate the same UV-space point on the shaped torso; cached bilinear weights.
        var y:=clampf((socket.y+40)/60,0,1)*12
        var row:=mini(11,int(y));var x:=0.0
        var grid=rig.bodice
        var left: Vector2=grid.rest[row*75];var right: Vector2=grid.rest[row*75+74]
        x=clampf((socket.x-left.x)/(right.x-left.x),0,1)*74
        var col:=mini(73,int(x));var a:=row*75+col
        anchor_indices.append(PackedInt32Array([a,a+1,a+75,a+76]))
        anchor_weights.append(Vector4((1-x+col)*(1-y+row),(x-col)*(1-y+row),(1-x+col)*(y-row),(x-col)*(y-row)))
    rig.far_arm.position=sockets[0];rig.near_arm.position=sockets[1]
    portrait=Sprite2D.new();portrait.name="RegisteredCameraPortrait";portrait.centered=false
    portrait.texture=load("res://godot/assets/sarah-definitive-21/front.png")
    portrait.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;portrait.z_index=8;rig.add_child(portrait)
    face_material=ShaderMaterial.new();face_material.shader=load("res://godot/shaders/sarah_camera_portrait.gdshader")
    face_material.set_shader_parameter("front_blink",load("res://godot/assets/sarah-definitive-21/front-blink.png"))
    face_material.set_shader_parameter("away_paint",load("res://godot/assets/sarah-definitive-21/away.png"))
    face_material.set_shader_parameter("away_blink",load("res://godot/assets/sarah-definitive-21/away-blink.png"))
    portrait.material=face_material
    # One registered body and tail remain visible through the whole turn.
    front_body=rig.bodice;front_tail=rig.tail_skin
    body_view.bind(rig)
    baseline_centers=rig.tail_skin.centers.duplicate()
    arm_restore.resize(2)
func begin(rig,dt: float) -> void:
    step_dt=dt
    if has_restore:
        rig.far_arm.transform=arm_restore[0];rig.near_arm.transform=arm_restore[1]
    handoff_blink=maxf(0,handoff_blink-dt*9.0)
    action="impact" if rig.hit_kick>.08 else "jump" if rig.jump_phase!="" or rig.leaping else "boost" if rig.boosting else "cast" if rig.bubble_hold_goal>.01 or rig.gesture_player.is_playing() and rig.last_gesture=="cast" else "gesture" if rig.gesture_player.is_playing() else "swim" if rig.velocity_value.length()>25 else "idle"
    var facing: float=rig.grace_motion.presentation_facing
    heading=Vector2(facing,0) if rig.reduced_motion else Spring.spring(heading,facing,14.0,dt)
    if absf(heading.x-facing)<.0005:heading=Vector2(facing,0)
    var wanted:=view_goal if opening and action not in ["impact","jump","boost","cast"] else 0.0
    view=Spring.spring(view,wanted,8,dt)
func render_heading() -> float:
    # The front view takes over before chirality changes: no zero-width body.
    return (1.0 if heading.x>=0 else -1.0)*lerpf(.72,1.0,absf(heading.x))
func sample_socket(rig,index: int,projected: bool=true) -> Vector2:
    var indices:=anchor_indices[index];var weights:=anchor_weights[index]
    var point:=Vector2.ZERO
    for k in range(4):
        var source: int=indices[k]
        var mapped: int=(source/75)*75+74-source%75 if projected and rig.scale.x<0 else source
        point+=rig.bodice.polygon[mapped]*weights[k]
    return point

func apply(rig) -> void:
    for i in range(2):
        var joint=rig.far_arm if i==0 else rig.near_arm
        joint.position=sample_socket(rig,i,false);arm_restore[i]=joint.transform
    has_restore=true
    var turn:=1.0-absf(heading.x)
    var requested:=maxf(1.0-smoothstep(.20,.92,absf(heading.x)),smoothstep(.04,.80,maxf(view.x,0)))
    # Geometric view registration follows the actual continuous heading. A lagged
    # front view previously left side geometry exposed when facing changed sign.
    front_weight=requested if not rig.reduced_motion else 0.0
    if front_weight<.00001:front_weight=0
    var away:=smoothstep(.1,.65,-view.x) if not rig.reduced_motion else 0.0
    var next_front:=front_face
    if front_weight>.56:next_front=true
    elif front_weight<.44:next_front=false
    var next_away:=away_face
    if away>.60:next_away=true
    elif away<.40:next_away=false
     # Natural blinks own eyelids; turning never restarts a blink.
    front_face=next_front;away_face=next_away
    portrait_weight=1.0 if front_face or away_face else 0.0
    # Face handoff is blink-registered; the torso paint and all geometry remain continuous.
    var blink: float=rig.blink_blend
    var hx: float=rig.scale.x
    var side_collar: Vector2=rig.torso.transform*(rig.head_joint.position+Vector2(3.52,-4.04).rotated(rig.head_joint.rotation))
    collar_rig=Vector2(side_collar.x*(1.0-front_weight),side_collar.y)
    var side_hip: Vector2=rig.torso.transform*rig.torso_motion.HIP_PIVOT
    var hip: Vector2=side_hip.lerp(collar_rig+Vector2(0,48),front_weight)
    body_view.apply(rig,front_weight,collar_rig)
    # Tail and torso share the same moving hip, including projected front/three-quarter poses.
    var side_basis: Transform2D=rig.torso.transform*rig.tail_skin.transform
    # Project every existing tail vertex through the same moving pelvis frame.
    # The tail foreshortens into a curved depth arc, rather than rotating as a
    # rigid long strip downwards. The root/tangent stays registered across width.
    rig.tail_skin.transform=rig.torso.transform.affine_inverse()*side_basis
    _project_tail(rig,side_basis,side_hip,hip,hx)
    rig.head_joint.position=rig.torso.transform.affine_inverse()*collar_rig-Vector2(3.52,-4.04).rotated(rig.head_joint.rotation)
    # The long back painting travels continuously through a reversal instead of mirroring in one frame.
    rig.back_hair.scale=Vector2.ONE
    rig.back_hair.modulate.a=1.0-front_weight
    rig.bodice.visible=true;rig.tail_skin.visible=true;rig.bodice.self_modulate=Color.WHITE
    rig.face_details.visible=portrait_weight<.5;rig.face_details.modulate=Color.WHITE
    for i in range(2):
        var joint=rig.far_arm if i==0 else rig.near_arm
        var at: Vector2=sample_socket(rig,i)
        var side_arm: Transform2D=rig.torso.transform*arm_restore[i]
        # Keep the current action's shoulder pose through the registered camera view.
        var rest_angle: float=.52 if i==0 else 2.55
        var action_delta: float=clampf(arm_restore[i].get_rotation()-rig.torso_motion.rib_angle,-.7,.7)
        if hx<0:side_arm.y=-side_arm.y # Keep arm parity stable throughout the left view.
        var angle: float=rest_angle+action_delta*(1.0 if i==0 else -1.0)
        if rig.gesture_wave>.05 and i==0:angle=lerp_angle(angle,-.55-rig.gesture_wave*.35,rig.gesture_wave)
        var front_arm:=Transform2D(angle,Vector2.ZERO)
        front_arm.x.x/=hx;front_arm.y.x/=hx
        var basis:=side_arm.interpolate_with(front_arm,front_weight)
        var side_origin: Vector2=rig.torso.transform*at
        var cuff:=collar_rig+Vector2((26.0 if i==0 else -26.0)/hx,14)
        var bare: Vector2=rig.arm_meshes[i].current_point(Vector2(.23,.43))
        basis.origin=side_origin.lerp(cuff-basis.basis_xform(bare),front_weight)
        joint.transform=rig.torso.transform.affine_inverse()*basis
        joint.visible=true;joint.modulate.a=1
        rig.arm_meshes[i].root_lock_angle=(arm_restore[i].get_rotation()-rig.torso_motion.rib_angle)*(1.0-front_weight)
        rig.arm_meshes[i].material.set_shader_parameter("sleeve_connected",front_weight<.3)
        rig.arm_meshes[i].material.set_shader_parameter("front_view",front_weight)
    var face_size: Vector2=portrait.texture.get_size()
    var face_scale:=Vector2(82.764/face_size.x/hx,82.764/face_size.y)
    portrait.transform=Transform2D(0,face_scale,0,collar_rig-Vector2(face_size.x*(745.0/1254)*face_scale.x,face_size.y*(1118.0/1254)*face_scale.y))
    portrait.modulate.a=portrait_weight;portrait.visible=portrait_weight>.5
    face_material.set_shader_parameter("away_mix",1.0 if away_face else 0.0)
    face_material.set_shader_parameter("blink",blink)
    rig.face_details.surface.set_shader_parameter("blink",blink)
func _project_tail(rig,side_basis: Transform2D,side_hip: Vector2,hip: Vector2,hx: float) -> void:
    var skin=rig.tail_skin
    var weight: float=front_weight
    if weight<.00001 and heading.x>0:return
    var points: PackedVector2Array=skin.polygon
    var inverse: Transform2D=side_basis.affine_inverse()
    var count: int=skin.SEGMENTS
    skin.projected_centers.resize(count+1)
    # Use model-space distance for the depth curve so all painted rows share it.
    for column in range(count+1):
        var t:=float(column)/count
        var side: Vector2=side_basis*skin.centers[column]-side_hip
        # A compact perspective spine retains the live action curve and its wave.
        # Derive displacement from the current skinned spine, never a frozen turn pose.
        var canonical: Vector2=side_basis*baseline_centers[column]-side_hip
        var residual: Vector2=side-canonical
        var drive: float=clampf(rig.smoothed_speed/345.0,0,1)
        var depth:=Vector2((24.0*sin(t*PI*1.15)+residual.y*.55)*smoothstep(0,.16,t),
            (108.0+drive*18.0)*t+residual.x*.22+residual.y*.12)
        skin.projected_centers[column]=hip+side.lerp(Vector2(depth.x/hx,depth.y),weight)
    for col in range(count+1):
        var column: int=skin.column_map[col]
        var center: Vector2=skin.projected_centers[column]
        # Derive width from the actual projected spine, never from a competing
        # roll track that could align the painted cross-section with the spine.
        var lo:=maxi(0,column-1);var hi:=mini(count,column+1)
        var projected_direction: Vector2=skin.projected_centers[hi]-skin.projected_centers[lo]
        # Screen-space arc normals preserve fluke width around the curved tip.
        var direction:=Vector2(projected_direction.x*hx,projected_direction.y).normalized()
        # A single perpendicular frame owns the entire cross-section. Rotating
        # that frame independently can align it with the spine and flatten paint.
        var normal_screen:=Vector2(direction.y,-direction.x)
        var normal:=Vector2(normal_screen.x/hx,normal_screen.y)
        var width:=lerpf(1.0,.82,weight*smoothstep(.08,.45,float(column)/count))
        var local_center:=inverse*center
        var local_axis:=inverse.basis_xform(normal)*width
        for row in range(13):
            points[row*(count+1)+col]=local_center+local_axis*skin.row_distance[row]
    skin.polygon=points
    skin.tip_center=inverse*skin.projected_centers[count-3]
    skin.projected_hip_tangent=(skin.projected_centers[1]-skin.projected_centers[0]).normalized()

func finish_arms(rig) -> void:
    if front_weight<.00001:return
    for i in range(2):
        var joint=rig.far_arm if i==0 else rig.near_arm
        var basis: Transform2D=rig.torso.transform*joint.transform
        var at: Vector2=rig.torso.transform*sample_socket(rig,i)
        var cuff:=collar_rig+Vector2((26.0 if i==0 else -26.0)/rig.scale.x,14)
        basis.origin=at.lerp(cuff-basis.basis_xform(rig.arm_meshes[i].current_point(Vector2(.23,.43))),front_weight)
        joint.transform=rig.torso.transform.affine_inverse()*basis
func attachment_error(rig,index: int) -> float:
    var joint=rig.far_arm if index==0 else rig.near_arm
    var basis: Transform2D=rig.torso.transform*joint.transform
    var at: Vector2=rig.torso.transform*sample_socket(rig,index)
    var cuff:=collar_rig+Vector2((26.0 if index==0 else -26.0)/rig.scale.x,14)
    var bare: Vector2=rig.arm_meshes[index].current_point(Vector2(.23,.43))
    return basis.origin.distance_to(at.lerp(cuff-basis.basis_xform(bare),front_weight))

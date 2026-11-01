extends Node3D
## Shared-stage 3D actor. Rest poses are cached; only authored small joint offsets animate.
var visual: Node3D
var skeleton: Skeleton3D
var joints: Array[Dictionary]=[]
var hinges: Array[Node3D]=[]
var seed:=0.0
var model_id:=0
var fitted_height:=1.0
var open_amount:=0.0
var first_pose:=true
var requested_height:=1.0
var motion_samples:=0
var base_bounds:=AABB()
var yaw:=0.0
static var scenes: Dictionary={}
func configure(id: int,height: float,phase: float) -> void:
    model_id=id;seed=phase;requested_height=height
    if not scenes.has(id):scenes[id]=load('res://godot/assets/tutorial39/model_%02d.glb'%id)
    visual=scenes[id].instantiate();add_child(visual)
    var first:=true
    for mesh in visual.find_children('*','MeshInstance3D',true,false):
        var b: AABB=mesh.global_transform*mesh.get_aabb()
        base_bounds=b if first else base_bounds.merge(b);first=false
    var factor:=minf(height/maxf(.001,base_bounds.size.y),height*1.7/maxf(.001,base_bounds.size.x))/100.0
    visual.scale=Vector3.ONE*factor;visual.position=-base_bounds.get_center()*factor
    fitted_height=base_bounds.size.y*factor
    for skel in visual.find_children('*','Skeleton3D',true,false):
        skeleton=skel
        for i in range(skeleton.get_bone_count()):
            var at: Vector3=skeleton.get_bone_global_rest(i).origin
            var y: float=(at.y-base_bounds.position.y)/maxf(.01,base_bounds.size.y)
            var side: float=(at.x-base_bounds.get_center().x)/maxf(.01,base_bounds.size.x)
            if i>0 and (absf(side)>.12 or y>.65):
                joints.append({'bone':i,'rest':skeleton.get_bone_pose_rotation(i),'side':side,'height':y})
    for node in visual.find_children('LidHinge','Node3D',true,false):hinges.append(node)
func perform(at: float,mode: String,gentle: bool,attention: float=0.0,direction:=1.0,opened:=false) -> void:
    var amplitude:=.22 if gentle else 1.0
    var burst:=pow(maxf(0,sin(at*.59+seed)),8)
    var wave:=sin(at*1.7+seed)
    yaw=lerpf(yaw,direction*.16, .18)
    rotation=Vector3(0,yaw,0 if gentle else sin(at*.72+seed)*.012)
    if is_instance_valid(skeleton):
        for joint in joints:
            var side: float=joint['side'];var y: float=joint['height']
            var angle: float=sin(at*1.35+seed+side*3)*.018
            if absf(side)>.16:angle+=sin(at*2.0+seed+side*4)*(.035 if model_id==0 or model_id==4 else .018)
            if side>0 and absf(side)>.18:angle+=burst*attention*.085
            if y>.72:angle+=sin(at*.83+seed)*attention*.025
            if mode=='talk':angle+=sin(at*3.1+seed)*.018
            if mode=='windup':angle-=.035
            if mode=='recover':angle+=sin(at*7+seed)*.025
            skeleton.set_bone_pose_rotation(joint['bone'],joint['rest']*Quaternion(Vector3.FORWARD,angle*amplitude))
        motion_samples+=1
    if model_id in [5,6,8,9,10,11]:rotation=Vector3(0,.10,0)
    if first_pose:open_amount=1.0 if opened else 0.0;first_pose=false
    open_amount=move_toward(open_amount,1.0 if opened else 0.0,.12 if gentle else .045)
    for hinge in hinges:hinge.rotation.x=-open_amount*1.02

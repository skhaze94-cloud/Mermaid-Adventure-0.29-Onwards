extends Node2D
## 3D-rendered royal tutorial actors.
## Original GLBs remain intact; an audited cached GPU skin adds independent bones.
## A transparent SubViewport lets them participate in the existing 2D tutorial
## positioning, dialogue, camera and interaction system without changing gameplay.

const KING_MODEL := preload("res://godot/assets/characters-v028/king-daddy-3d.glb")
const QUEEN_MODEL := preload("res://godot/assets/characters-v028/queen-antonella-3d.glb")

const VIEW_SIZE := Vector2i(576, 768)
const ConnectedSkin = preload("res://godot/royal_connected_skin.gd")
var connected_skin = ConnectedSkin.new()
var reaction_mode := ""
var reaction_elapsed := 100.0
var mode_elapsed := 0.0
var previous_mode := ""
var render_elapsed := 0.0
var prefs: Node
var high_quality := true
const CAMERA_ORTHO_SIZE := 2.2

var mesh: Sprite2D
var viewport: SubViewport
var model_root: Node3D
var camera_3d: Camera3D
var role := "king"
var pose := "idle"
var clock := 0.0
var previous_external_time := -1.0
var gentle := false
var size := Vector2(288, 390)
var cast_glow := 0.0
var tutorial_life := false
var travel_goal := Vector2.ZERO
var travel_pose := Vector2.ZERO
var attention_goal := 0.0
var attention_pose := 0.0
var dialogue_active := false
var dialogue_mode := "idle"
var _target_height := 390.0
var _render_ready := false
var loaded_role := ""

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    z_index = 3
    prefs=get_node_or_null("/root/AppPreferences")
    visibility_changed.connect(_visibility_changed)
    _create_render_stage()
    configure(role,_target_height)

func _create_render_stage() -> void:
    viewport = SubViewport.new()
    viewport.name = "RoyalModelViewport"
    viewport.size = VIEW_SIZE
    viewport.transparent_bg = true
    viewport.own_world_3d = true
    viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
    viewport.gui_disable_input = true
    add_child(viewport)

    var environment_node := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0, 0, 0, 0)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.78, 0.88, 1.0)
    environment.ambient_light_energy = 0.82
    environment_node.environment = environment
    viewport.add_child(environment_node)

    var key_light := DirectionalLight3D.new()
    key_light.name = "SoftKeyLight"
    key_light.rotation_degrees = Vector3(-28, -32, 0)
    key_light.light_color = Color(1.0, 0.91, 0.77)
    key_light.light_energy = 1.10
    key_light.shadow_enabled = false
    viewport.add_child(key_light)

    var fill_light := DirectionalLight3D.new()
    fill_light.name = "CoolFillLight"
    fill_light.rotation_degrees = Vector3(-12, 145, 0)
    fill_light.light_color = Color(0.48, 0.82, 1.0)
    fill_light.light_energy = 0.50
    fill_light.shadow_enabled = false
    viewport.add_child(fill_light)

    camera_3d = Camera3D.new()
    camera_3d.name = "RoyalPortraitCamera"
    camera_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera_3d.size = CAMERA_ORTHO_SIZE
    camera_3d.position = Vector3(0, 0, 3.6)
    camera_3d.current = true
    viewport.add_child(camera_3d)
    camera_3d.look_at(Vector3(0, 0, 0), Vector3.UP)

    mesh = Sprite2D.new()
    mesh.name = "Royal3DPortrait"
    mesh.centered = true
    mesh.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    mesh.texture = viewport.get_texture()
    add_child(mesh)
    _render_ready = true

func configure(kind: String, height := 310.0) -> void:
    role = kind
    _target_height = height
    size = Vector2(height * 0.74, height)
    if not _render_ready:
        return
    if loaded_role==role and is_instance_valid(model_root):
        mesh.scale=Vector2.ONE*(height/float(VIEW_SIZE.y))
        return
    if is_instance_valid(model_root):
        model_root.queue_free()
    var packed: PackedScene = KING_MODEL if role == "king" else QUEEN_MODEL
    model_root = packed.instantiate() as Node3D
    model_root.name = "KingDaddy3D" if role == "king" else "QueenAntonella3D"
    viewport.add_child(model_root)
    loaded_role = role
    connected_skin = ConnectedSkin.new()
    connected_skin.bind(model_root,role)
    # The generated models are centred, with an approximately 1.9-unit height.
    # Keep the imported geometry intact; fit is controlled by the portrait camera.
    model_root.position = Vector3.ZERO
    model_root.scale = Vector3.ONE
    mesh.scale = Vector2.ONE*(height/float(VIEW_SIZE.y))
    previous_external_time = -1.0
    clock = 0.0
    cast_glow = 0.0
    travel_goal = Vector2.ZERO
    travel_pose = Vector2.ZERO
    attention_goal = 0.0
    attention_pose = 0.0
    dialogue_active = false
    dialogue_mode = "idle"
    reaction_mode="";reaction_elapsed=100;mode_elapsed=0;previous_mode=""
    animate(0.0, "idle", true)
    # Paint one complete initial portrait before reduced-motion cadence begins.
    if is_visible_in_tree():viewport.render_target_update_mode=SubViewport.UPDATE_ONCE

func set_dialogue_pose(speaking: bool) -> void:
    dialogue_active = true
    dialogue_mode = "talk" if speaking else "listen"

func end_dialogue_pose() -> void:
    dialogue_active = false
    dialogue_mode = "idle"

func set_attention(direction: float) -> void:
    attention_goal = clampf(direction, -1.0, 1.0)

func set_travel(velocity: Vector2) -> void:
    travel_goal = Vector2(clampf(velocity.x / 220.0, -1.0, 1.0), clampf(velocity.length() / 220.0, 0.0, 1.0))

func _process(dt: float) -> void:
    if not dialogue_active or not get_tree().paused or not is_visible_in_tree():
        return
    _advance(minf(dt, 0.05), dialogue_mode, gentle)

func animate(at: float, mode: String, reduced: bool) -> void:
    var dt := clampf(at - previous_external_time, 0.0, 0.05) if previous_external_time >= 0.0 else 0.0
    previous_external_time = at
    _advance(dt, mode, reduced)

func set_quality(high: bool) -> void:
    high_quality=high

func react(cue: String) -> void:
    var mapped: String={"hello":"wave","success":"celebrate","acknowledge":"acknowledge","return":"wave"}.get(cue,cue)
    if mapped not in ["wave","celebrate","acknowledge","cast","hug"]:return
    reaction_mode=mapped;reaction_elapsed=0.0

func _visibility_changed() -> void:
    if is_instance_valid(viewport):viewport.render_target_update_mode=SubViewport.UPDATE_ONCE if is_visible_in_tree() else SubViewport.UPDATE_DISABLED

func _advance(dt: float, mode: String, reduced: bool) -> void:
    if not is_visible_in_tree():
        viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
        return
    clock += dt
    gentle = reduced
    reaction_elapsed+=dt
    var active_mode:=dialogue_mode if dialogue_active else mode
    if reaction_elapsed<3.2 and not dialogue_active and mode in ["idle","listen","swim"]:
        active_mode=reaction_mode
    if active_mode!=previous_mode:
        mode_elapsed=0.0;previous_mode=active_mode
    else:mode_elapsed+=dt
    pose=active_mode
    var t:=reaction_elapsed if reaction_elapsed<3.2 and active_mode==reaction_mode else mode_elapsed
    var envelope:=smoothstep(.10 if role=="king" else .18,.62 if role=="king" else .78,t)*(1.0-smoothstep(1.55 if role=="king" else 1.70,2.85,t))
    attention_pose = lerpf(attention_pose, attention_goal, 1.0 - exp(-dt * 6.0))
    travel_pose = travel_pose.lerp(travel_goal, 1.0 - exp(-dt * 6.0))
    connected_skin.advance(dt,clock,active_mode,envelope,attention_pose,travel_pose,reduced)
    # Root placement stays separate from anatomy. Breathing is skeletal;
    # gestures are shoulder/elbow/wrist motion rather than uniform model sway.
    var strength:=.25 if reduced else 1.0
    var target_rotation:=Vector3(0,attention_pose*.025,-travel_pose.x*.012)*strength
    model_root.rotation=model_root.rotation.lerp(target_rotation,1.0-exp(-dt*8.0))
    model_root.position.y=sin(clock*.75)*.003*(.3+travel_pose.y)*strength
    model_root.scale=Vector3.ONE
    var economy: bool=not high_quality or prefs!=null and prefs.get("economy")==true
    if economy or reduced:
        render_elapsed+=dt
        viewport.render_target_update_mode=SubViewport.UPDATE_ONCE if render_elapsed>=1.0/20.0 else SubViewport.UPDATE_DISABLED
        if render_elapsed>=1.0/20.0:render_elapsed=0.0
    else:viewport.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE
    cast_glow=lerpf(cast_glow,envelope if active_mode=="cast" else 0.0,1.0-exp(-dt*7.0))
    queue_redraw()

func _draw() -> void:
    if cast_glow < 0.01:
        return
    var projected:=camera_3d.unproject_position(connected_skin.hand_global_position())
    var hand: Vector2=(projected-Vector2(VIEW_SIZE)*.5)*mesh.scale
    var color := Color("b4f4ff") if role == "king" else Color("ffe1cb")
    draw_arc(hand, 18.0 + (0.0 if gentle else sin(clock * 3.0) * 2.0), 0.0, TAU, 48, Color(color, cast_glow * 0.5), 2.0, true)
    for i in range(4):
        var angle := i * TAU / 4.0 + (0.0 if gentle else clock)
        var offset := Vector2(cos(angle), sin(angle)) * 25.0
        draw_circle(hand + offset, 2.0, Color(color, cast_glow))

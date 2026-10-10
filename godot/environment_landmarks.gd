extends Node2D
## Native, reused landmarks: soft flowing entrance and carved victory portal.
const Terrain = preload("res://godot/terrain_painter.gd")
const Art = preload("res://godot/environment_art.gd")
const Highland = preload("res://godot/highland_data.gd")
const FLOW: Shader = preload("res://godot/shaders/environment_flow.gdshader")
const ARCH: Texture2D = preload("res://godot/assets/environment-portal-v011.webp")
const CUTOUT: Shader = preload("res://godot/shaders/reef_material.gdshader")
var entrance: ColorRect
var opening: ColorRect
var arch: Sprite2D
func _ready() -> void:
    z_index = -1
    entrance = _flow_plane(false)
    entrance.size = Vector2(250,680)
    opening = _flow_plane(true)
    opening.size = Vector2(140,208)
    arch = Sprite2D.new()
    arch.name = "CarvedSeashellVictoryArch"
    arch.texture = ARCH
    arch.scale = Vector2.ONE * 320.0 / ARCH.get_height()
    var material := ShaderMaterial.new()
    material.shader = CUTOUT
    material.set_shader_parameter("distance_fog", 0.0)
    material.set_shader_parameter("relief", 0.04)
    arch.material = material
    add_child(arch)
func _flow_plane(is_portal: bool) -> ColorRect:
    var rect := ColorRect.new()
    rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var material := ShaderMaterial.new()
    material.shader = FLOW
    material.set_shader_parameter("portal", is_portal)
    rect.material = material
    add_child(rect)
    return rect
func set_scene(camera: float, fallen: bool, waterfall: bool, unlocked: bool, reduced: bool) -> void:
    visible = not waterfall
    var view := get_viewport_rect().size
    var fall_x := 3220.0 - camera
    entrance.position = Vector2(fall_x - 125.0,280.0)
    entrance.size.y = maxf(1.0,view.y - 280.0)
    entrance.visible = not fallen and fall_x > -250.0 and fall_x < view.x + 250.0
    var portal_x := Highland.PORTAL_X - camera
    arch.position = Vector2(portal_x,530.0)
    opening.position = Vector2(portal_x - 70.0,426.0)
    arch.visible = unlocked and portal_x > -200.0 and portal_x < view.x + 200.0
    opening.visible = arch.visible
    queue_redraw()
    entrance.material.set_shader_parameter("reduced_motion", reduced)
    opening.material.set_shader_parameter("reduced_motion", reduced)
func set_quality(high: bool) -> void:
    entrance.material.set_shader_parameter("high_quality", high)
    opening.material.set_shader_parameter("high_quality", high)

func _draw() -> void:
    if not is_instance_valid(arch) or not arch.visible: return
    var foot := arch.position+Vector2(0,148)
    draw_texture_rect(Art.rock(0),Rect2(Vector2(arch.position.x-63,foot.y-16),Vector2(126,Terrain.GROUND_Y+25-foot.y)),false,Color(.52,.72,.78,.8))
    Terrain.contact(self,Vector2(arch.position.x,Terrain.GROUND_Y+3),150,.45)
    Terrain.contact(self,foot,150,.30)

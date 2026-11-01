extends Control
## One real active effect; the game owns its timer. No ticking or invented powers here.
const Pearl=preload('res://godot/pearl_storybook.gd')
var power_id:=""
var caption:=""
var remaining:=0.0
var fraction:=0.0
var signature: Array=[]
var paint:=Pearl.panel(Pearl.IVORY,Pearl.SEAFOAM,22,8)
func _ready() -> void:
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    custom_minimum_size=Vector2(184,50)
func set_powerup(data: Dictionary,_reduced:=false) -> void:
    power_id=String(data.get('id',''))
    caption=String(data.get('label','Active gift'))
    remaining=maxf(0,float(data.get('remaining',0)))
    fraction=clampf(remaining/maxf(.001,float(data.get('duration',1))),0,1)
    var next: Array=[power_id,caption,ceili(remaining),roundi(fraction*64),size]
    if next==signature:return
    signature=next;queue_redraw()
func _draw() -> void:
    draw_style_box(paint,Rect2(Vector2.ZERO,size))
    var center:=Vector2(25,size.y*.5)
    draw_arc(center,18,-PI*.5,PI*1.5,48,Pearl.MINT,2.5,true)
    draw_arc(center,18,-PI*.5,-PI*.5+TAU*fraction,48,Pearl.GOLD,2.5,true)
    draw_texture_rect(Pearl.texture('boost'),Rect2(center-Vector2(16,16),Vector2(32,32)),false)
    draw_string(Pearl.BOLD,Vector2(50,21),caption, HORIZONTAL_ALIGNMENT_LEFT,maxf(1,size.x-60),16,Pearl.INK)
    draw_string(Pearl.FONT,Vector2(50,39),'%ss left'%ceili(remaining),HORIZONTAL_ALIGNMENT_LEFT,maxf(1,size.x-60),14,Pearl.MUTED)

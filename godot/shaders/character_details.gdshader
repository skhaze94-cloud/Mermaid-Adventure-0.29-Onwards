shader_type canvas_item;
render_mode unshaded;
#include "res://godot/shaders/character_details.gdshaderinc"
uniform float detail_clock=0.0;
uniform float detail_strength=0.0;
uniform float detail_seed=0.0;
uniform vec4 fin_zone=vec4(.3,.75,.3,.25);
uniform vec4 shell_zone=vec4(.25,.4,.22,.25);
uniform vec4 face_zone=vec4(.65,.3,.24,.20);
uniform vec4 bounds=vec4(0.,0.,1.,1.);
uniform float expression_joy=0.0;
uniform float expression_look=0.0;
uniform float expression_greet=0.0;
uniform float mood=0.0;
uniform float gentle=0.0;
varying vec4 paint_tint;
void vertex(){
 paint_tint=COLOR;
 vec2 local=(UV-bounds.xy)/bounds.zw;
 float lower=smoothstep(.35,1.0,local.y);
 VERTEX.x+=sin(detail_clock*1.6+local.y*3.0+detail_seed)*.005*lower*detail_strength;
}
void fragment(){
 vec2 p=(UV-bounds.xy)/bounds.zw;
 vec2 q=character_details(p,detail_clock,detail_seed,detail_strength,fin_zone,shell_zone,face_zone);
 q.x-=expression_look*soft_region(p,face_zone)*detail_strength;
 q.y+=sin(detail_clock*4.0+detail_seed)*.004*expression_greet*soft_region(p,fin_zone)*detail_strength;
 vec4 paint=texture(TEXTURE,bounds.xy+clamp(q,vec2(.001),vec2(.999))*bounds.zw);
 float cheek=soft_region(p,vec4(face_zone.xy+vec2(.035,.055),face_zone.zw*.32));
 paint.rgb=mix(paint.rgb,paint.rgb*vec3(1.045,.975,.985),cheek*clamp(expression_joy,0.0,1.0)*detail_strength);
 COLOR=paint*paint_tint;
}

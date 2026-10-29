shader_type canvas_item;
render_mode unshaded;
global uniform float gameplay_time;
uniform vec4 cell_uv=vec4(0.0,0.0,1.0,1.0);
uniform bool gentle=false;
varying vec4 instance_tint;
void vertex(){instance_tint=COLOR;}
void fragment(){
    vec4 paint=texture(TEXTURE,UV);
    vec2 local=(UV-cell_uv.xy)/cell_uv.zw;
    float band=max(0.0,sin(local.x*4.0-local.y*2.0+gameplay_time*1.8));
    float band2=band*band;float band4=band2*band2;
    float sweep=gentle?0.0:band4*band4*band4;
    paint.rgb+=vec3(0.035,0.055,0.065)*sweep*paint.a;
    COLOR=paint*instance_tint;
}

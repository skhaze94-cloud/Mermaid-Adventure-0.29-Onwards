shader_type canvas_item;
render_mode unshaded;
uniform vec4 cell_uv=vec4(0.0,0.0,1.0,1.0);
varying vec4 instance_tint;
void vertex(){instance_tint=COLOR;}
void fragment(){
    vec4 paint=texture(TEXTURE,UV);
    vec2 local=(UV-cell_uv.xy)/cell_uv.zw;
    float curve=sqrt(max(0.0,1.0-pow((local.y-0.5)*1.7,2.0)));
    float sheen=pow(max(0.0,1.0-abs(local.x-0.33)*2.3),3.0)*curve;
    paint.rgb+=vec3(0.015,0.028,0.035)*sheen;
    COLOR=paint*instance_tint;
}

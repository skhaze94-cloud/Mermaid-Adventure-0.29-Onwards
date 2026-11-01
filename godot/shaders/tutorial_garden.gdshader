shader_type canvas_item;
render_mode unshaded;
global uniform float gameplay_time;
uniform vec4 atlas_rect;
uniform float phase=0.0;
uniform float motion_strength=1.0;
void vertex(){
    vec2 local_uv=(UV-atlas_rect.xy)/(atlas_rect.zw-atlas_rect.xy);
    float tip=pow(clamp(1.0-local_uv.y,0.0,1.0),2.5);
    VERTEX.x+=(sin(gameplay_time*.72+phase+local_uv.y*1.4)*1.8+sin(gameplay_time*.39+phase)*.45)*tip*motion_strength;
}
void fragment(){COLOR=texture(TEXTURE,UV)*COLOR;}

shader_type canvas_item;
uniform vec4 atlas_bounds = vec4(0.0,0.0,1.0,1.0);
uniform float motion_clock = 0.0;
uniform float charge_mix : hint_range(0.0,1.0) = 0.0;
uniform float depth_turn = 0.0;
uniform bool motion_enabled = true;
void fragment() {
    vec4 painted = COLOR;
    vec2 local_uv = (UV-atlas_bounds.xy) / (atlas_bounds.zw-atlas_bounds.xy);
    float phase = motion_enabled ? motion_clock * 0.65 : 0.0;
    float sheen = pow(max(0.0,sin(local_uv.x*2.6-local_uv.y*1.4+phase)),5.0);
    vec3 pearl = mix(vec3(0.56,0.92,1.0),vec3(1.0,0.70,0.94),local_uv.y);
    vec3 rgb = mix(painted.rgb,pearl,sheen*(0.035+charge_mix*0.07));
    float roundness = sqrt(max(0.0,1.0-pow((local_uv.y-0.5)*2.0,2.0)));
    float volume = 0.88+roundness*0.12-(local_uv.y-0.5)*depth_turn*0.07;
    COLOR = vec4(rgb*(motion_enabled ? volume : 1.0),painted.a);
}


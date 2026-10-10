shader_type canvas_item;
uniform vec4 atlas_bounds = vec4(0.0,0.0,1.0,1.0);
uniform float depth_turn = 0.0;
uniform bool volume_enabled = true;
void fragment() {
    vec4 painted = COLOR;
    vec2 p = clamp((UV-atlas_bounds.xy)/(atlas_bounds.zw-atlas_bounds.xy),vec2(0.0),vec2(1.0));
    // An elliptical cross-section adds painted volume without extra textures.
    float side = (p.y-0.5)*2.0;
    float normal_z = sqrt(max(0.0,1.0-side*side));
    float light = 0.88 + normal_z*0.12 - side*(0.055+depth_turn*0.035);
    float rim = pow(max(0.0,1.0-normal_z),3.0)*0.07;
    vec3 sculpted = painted.rgb*light + vec3(0.35,0.65,0.72)*rim;
    COLOR = vec4(volume_enabled ? sculpted : painted.rgb,painted.a);
}


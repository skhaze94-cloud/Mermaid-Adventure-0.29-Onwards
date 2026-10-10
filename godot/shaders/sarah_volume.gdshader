shader_type canvas_item;
uniform vec4 atlas_bounds = vec4(0.0,0.0,1.0,1.0);
uniform float depth_turn = 0.0;
uniform bool volume_enabled = true;
// Only the two waist pieces opt in. UV-anchored colour stays attached to
// the painted scales through bending, turning and the reduced-motion setting.
uniform int waist_role = 0;
uniform bool waist_unified = true;
void fragment() {
    vec4 painted = COLOR;
    vec2 p = clamp((UV-atlas_bounds.xy)/(atlas_bounds.zw-atlas_bounds.xy),vec2(0.0),vec2(1.0));
    if (waist_unified && waist_role != 0) {
        float blend = waist_role == 1 ? smoothstep(0.57,0.96,p.y) : smoothstep(0.77,0.98,p.x);
        // Exchange violet and sea-green near the overlap, retaining the source
        // luminance and scale highlights rather than laying on a flat band.
        vec3 pearl = vec3(0.48,0.70,0.98);
        float luminance = dot(painted.rgb,vec3(0.2126,0.7152,0.0722));
        pearl *= luminance / dot(pearl,vec3(0.2126,0.7152,0.0722));
        painted.rgb = mix(painted.rgb,pearl,blend*(waist_role == 1 ? 0.62 : 0.36));
    }
    // An elliptical cross-section adds painted volume without extra textures.
    float side = (p.y-0.5)*2.0;
    float normal_z = sqrt(max(0.0,1.0-side*side));
    float light = 0.88 + normal_z*0.12 - side*(0.055+depth_turn*0.035);
    float rim = pow(max(0.0,1.0-normal_z),3.0)*0.07;
    vec3 sculpted = painted.rgb*light + vec3(0.35,0.65,0.72)*rim;
    COLOR = vec4(volume_enabled ? sculpted : painted.rgb,painted.a);
}


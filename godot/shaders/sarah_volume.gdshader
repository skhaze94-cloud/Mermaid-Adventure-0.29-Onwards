shader_type canvas_item;
uniform vec4 atlas_bounds = vec4(0.0,0.0,1.0,1.0);
uniform float depth_turn = 0.0;
uniform bool volume_enabled = true;
// Only the two waist pieces opt in. UV-anchored colour stays attached to
// the painted scales through bending, turning and the reduced-motion setting.
uniform int waist_role = 0;
uniform bool waist_unified = true;
uniform bool sleeve_connected = false;
uniform sampler2D torso_paint : source_color;
uniform sampler2D join_tail_paint : source_color;
uniform vec2 arm_origin = vec2(0.0);
uniform vec2 arm_axis_x = vec2(1.0,0.0);
uniform vec2 arm_axis_y = vec2(0.0,1.0);
varying vec2 local_paint_point;
void vertex() { local_paint_point=VERTEX; }
float torso_alpha(vec2 point) {
    vec2 p=(point-vec2(-3.0,-40.0))/vec2(60.0);
    if (p.x<0.0 || p.x>1.0 || p.y<0.0 || p.y>1.0) { return 0.0; }
    return texture(torso_paint,(vec2(8.5,19.5)+p*vec2(239.0,217.0))/1024.0).a;
}
float tail_alpha(vec2 point) {
    vec2 p=(point-vec2(-149.0,-27.0))/vec2(184.0,80.0);
    if (p.x<0.0 || p.x>1.0 || p.y<0.0 || p.y>1.0) { return 0.0; }
    return texture(join_tail_paint,(vec2(24.5,28.5)+p*vec2(2125.0,668.0))/vec2(2172.0,724.0)).a;
}
void fragment() {
    vec4 painted = COLOR;
    vec2 p = clamp((UV-atlas_bounds.xy)/(atlas_bounds.zw-atlas_bounds.xy),vec2(0.0),vec2(1.0));
    if (sleeve_connected && p.x<0.20) {
        vec2 body=arm_origin+local_paint_point.x*arm_axis_x+local_paint_point.y*arm_axis_y;
        // Feather only over conservatively opaque torso paint. The outer
        // shoulder silhouette keeps its full alpha, preventing holes.
        float cover=min(min(torso_alpha(body+vec2(1.2,0.0)),torso_alpha(body-vec2(1.2,0.0))),
            min(torso_alpha(body+vec2(0.0,1.2)),torso_alpha(body-vec2(0.0,1.2))));
        float inside=smoothstep(0.97,0.999,cover);
        painted.a*=mix(1.0,smoothstep(0.01,0.15,p.x),inside);
        painted.rgb*=1.0-inside*(1.0-smoothstep(0.06,0.20,p.x))*0.05;
    }
    if (waist_unified && waist_role != 0) {
        float blend = waist_role == 1 ? smoothstep(0.57,0.96,p.y) : smoothstep(0.77,0.98,p.x);
        // Exchange violet and sea-green near the overlap, retaining the source
        // luminance and scale highlights rather than laying on a flat band.
        vec3 pearl = vec3(0.48,0.70,0.98);
        float luminance = dot(painted.rgb,vec3(0.2126,0.7152,0.0722));
        pearl *= luminance / dot(pearl,vec3(0.2126,0.7152,0.0722));
        painted.rgb = mix(painted.rgb,pearl,blend*(waist_role == 1 ? 0.76 : 0.48));
        if (waist_role==1 && p.y>0.72) {
            float cover=min(min(tail_alpha(local_paint_point+vec2(1.5,0.0)),tail_alpha(local_paint_point-vec2(1.5,0.0))),
                min(tail_alpha(local_paint_point+vec2(0.0,1.5)),tail_alpha(local_paint_point-vec2(0.0,1.5))));
            // Reveal the actual moving tail beneath the lower scales rather
            // than drawing another connector or an opaque waist band.
            painted.a*=1.0-smoothstep(0.975,0.999,cover)*smoothstep(0.72,0.97,p.y)*0.88;
        }
    }
    // An elliptical cross-section adds painted volume without extra textures.
    float side = (p.y-0.5)*2.0;
    float normal_z = sqrt(max(0.0,1.0-side*side));
    float light = 0.88 + normal_z*0.12 - side*(0.055+depth_turn*0.035);
    float rim = pow(max(0.0,1.0-normal_z),3.0)*0.07;
    vec3 sculpted = painted.rgb*light + vec3(0.35,0.65,0.72)*rim;
    COLOR = vec4(volume_enabled ? sculpted : painted.rgb,painted.a);
}


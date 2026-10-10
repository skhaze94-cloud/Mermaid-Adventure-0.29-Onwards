shader_type canvas_item;
uniform vec4 cell_uv = vec4(0.0,0.0,0.5,0.5);
uniform float visual_clock = 0.0;
uniform int anatomy = 0;
uniform int combat_pose = 0;
uniform bool animate_detail = true;
uniform float depth_turn = 0.0;
uniform float alert_mix = 0.0;
uniform bool high_quality = true;
uniform vec4 previous_cell_uv = vec4(0.0,0.0,0.5,0.5);
uniform float pose_blend = 1.0;
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }
void fragment() {
    vec2 local = (UV - cell_uv.xy) / cell_uv.zw;
    vec2 warped = local;
    if (animate_detail && high_quality) {
        if (anatomy == 1) {
            warped.y += sin(local.x * 9.0 - visual_clock * 3.3) * 0.014 * pow(1.0 - local.x,2.0);
        } else if (anatomy == 2) {
            warped.x += sin(local.y * 14.0 - visual_clock * 2.2) * 0.012 * smoothstep(0.33,0.65,local.y);
        } else if (anatomy == 3) {
            float claws = smoothstep(0.18,0.44,abs(local.x-0.5))*(1.0-smoothstep(0.60,0.82,local.y));
            warped.y += sin(visual_clock*2.6+local.x*4.0)*0.010*claws;
        } else if (anatomy == 4) {
            float fins = smoothstep(0.18,0.38,abs(local.x-0.5));
            warped.y += sin(visual_clock*4.4+local.x*5.0)*0.009*fins;
        } else if (anatomy == 5) {
            warped.y += sin(local.x*7.0-visual_clock*3.6)*0.012*pow(1.0-local.x,3.0);
        }
    }
    vec2 uv = cell_uv.xy + clamp(warped,vec2(0.002),vec2(0.998)) * cell_uv.zw;
    vec4 painted = texture(TEXTURE,uv);
    if (pose_blend<1.0 && high_quality) {
        vec2 previous_uv = previous_cell_uv.xy+clamp(warped,vec2(0.002),vec2(0.998))*previous_cell_uv.zw;
        vec4 previous = texture(TEXTURE,previous_uv);
        float alpha = mix(previous.a,painted.a,pose_blend);
        vec3 premultiplied = mix(previous.rgb*previous.a,painted.rgb*painted.a,pose_blend);
        painted = vec4(premultiplied/max(alpha,0.0001),alpha);
    }
    if (painted.a < 0.025) { discard; }
    if (high_quality) {
        float neighbour = texture(TEXTURE,clamp(uv + vec2(TEXTURE_PIXEL_SIZE.x * 2.0,0.0),cell_uv.xy+TEXTURE_PIXEL_SIZE,cell_uv.xy+cell_uv.zw-TEXTURE_PIXEL_SIZE)).a;
        float rim = max(0.0,painted.a - neighbour);
        vec3 light = combat_pose == 1 ? vec3(1.0,0.70,0.26) : vec3(0.25,0.85,0.94);
        float curve = sqrt(max(0.0,1.0-pow((local.y-0.5)*2.0,2.0)));
        painted.rgb *= 0.90+curve*0.10-(local.y-0.5)*depth_turn*0.07;
        painted.rgb += light * rim * (0.32+alert_mix*0.08);
    }
    if (combat_pose == 1) { painted.rgb = mix(painted.rgb,vec3(1.0,0.77,0.44),0.07); }
    if (combat_pose == 3) { painted.rgb = mix(painted.rgb,vec3(0.63,0.92,0.83),0.045); }
    COLOR = painted * vertex_tint;
}


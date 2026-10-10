shader_type canvas_item;
render_mode unshaded;
uniform vec4 atlas_rect = vec4(0.0,0.0,1.0,1.0);
uniform float clock = 0.0;
uniform float strength = 0.0;
uniform int anatomy = 0;
uniform float tail_side = 1.0;
uniform float hit = 0.0;
uniform float attack_mix = 0.0;
varying vec4 tint;
void vertex() {
    tint = COLOR;
    vec2 p = VERTEX;
    if (anatomy == 1) {
        // Manta wings: a shared root and opposite soft wing beats.
        p.y += sin(clock*3.5-abs(p.x)*2.0)*pow(abs(p.x)*2.0,2.0)*strength*0.09;
    } else if (anatomy == 2) {
        // Long bodies: gentle waves near the tail, quiet around the face.
        p.y += sin(clock*3.2+p.x*5.0)*(1.0-smoothstep(-0.48,0.18,p.x*tail_side))*strength*0.065;
    } else if (anatomy == 3) {
        // Antonella's face and torso remain quiet while gown and hands respond.
        float cloth = smoothstep(0.0,0.48,p.y);
        float hand = smoothstep(0.05,0.40,p.x)*(1.0-smoothstep(-0.02,0.14,p.y))*smoothstep(-0.35,-0.22,p.y);
        p.x += sin(clock*1.65-p.y*5.0)*cloth*strength*0.011;
        p.y += (sin(clock*2.4)*0.010-attack_mix*0.018)*hand*strength;
    } else {
        // Claws/flippers move at the edges, leaving the face connected.
        p.y += sin(clock*2.4+p.x*4.0)*abs(p.x)*strength*0.035;
    }
    VERTEX = p;
    UV = atlas_rect.xy + UV*atlas_rect.zw;
}
void fragment() {
    vec4 paint = texture(TEXTURE,UV);
    paint.rgb = mix(paint.rgb,vec3(1.0,0.93,0.73),hit*0.55);
    COLOR = paint * tint;
}

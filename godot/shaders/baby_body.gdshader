shader_type canvas_item;
uniform float clock = 0.0;
uniform float wiggle = 0.0;
uniform float joy = 0.0;
uniform float strength = 1.0;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
    vec2 uv = UV;
    // The cheeks, eyes and neck stay quiet; motion grows into the short tail.
    float tail = smoothstep(0.56,0.88,UV.y);
    uv.x += strength*tail*(wiggle*sin(UV.y*8.0)+sin(clock*3.2-UV.y*7.0)*0.003);
    // Small baby paddles and a happy hand flutter, anchored at both shoulders.
    float arms = smoothstep(0.38,0.44,UV.y)*(1.0-smoothstep(0.52,0.57,UV.y));
    float hands = smoothstep(0.17,0.38,abs(UV.x-0.5));
    uv.y += strength*arms*hands*(sin(clock*3.5+UV.x*4.0)*0.004+joy*sin(clock*6.0)*0.007);
    vec4 paint = texture(TEXTURE,clamp(uv,vec2(0.001),vec2(0.999)));
    COLOR = paint*tint;
}

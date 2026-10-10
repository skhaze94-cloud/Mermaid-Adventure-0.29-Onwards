shader_type canvas_item;
render_mode unshaded;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float aspect = 1.5;
uniform bool gentle = false;
void fragment() {
    vec2 p = (UV - vec2(0.5)) * vec2(aspect, 1.0);
    float radius = length(p);
    float max_radius = length(vec2(aspect, 1.0)) * 0.5 + 0.08;
    float opening = (1.0 - progress) * max_radius;
    float alpha = smoothstep(opening - 0.025, opening + 0.025, radius);
    if (progress < 0.001) alpha = 0.0;
    if (progress > 0.999) alpha = 1.0;
    if (gentle) alpha = progress;
    float glow = exp(-abs(radius-opening)*32.0) * sin(progress*3.14159);
    vec3 sea = mix(vec3(0.025,0.09,0.14),vec3(0.035,0.19,0.24),1.0-UV.y);
    sea += vec3(0.13,0.35,0.31)*glow;
    COLOR = vec4(sea,alpha);
}

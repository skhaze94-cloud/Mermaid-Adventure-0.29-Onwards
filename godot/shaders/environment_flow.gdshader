shader_type canvas_item;
render_mode unshaded;
global uniform float gameplay_time;
uniform bool portal = false;
uniform bool reduced_motion = false;
uniform bool high_quality = true;
void fragment() {
    float t = reduced_motion ? 0.0 : gameplay_time;
    float edge = smoothstep(0.0,0.15,UV.x) * smoothstep(1.0,0.85,UV.x);
    float flow = sin(UV.x * 43.0 + UV.y * 11.0 - t * 3.2) * 0.5 + 0.5;
    float threads = high_quality ? pow(flow, 5.0) : flow * 0.4;
    vec3 colour = mix(vec3(0.13,0.63,0.76), vec3(0.79,1.0,0.95), threads);
    float alpha = edge * (0.12 + threads * 0.25);
    if (portal) {
        float radius = length((UV - vec2(0.5)) * vec2(2.0,2.0));
        edge = 1.0 - smoothstep(0.88,1.0,radius);
        float rings = sin(radius * 32.0 - t * 2.5) * 0.5 + 0.5;
        colour = mix(vec3(0.06,0.42,0.49),vec3(0.52,1.0,0.91),rings * 0.45);
        alpha = edge * 0.77;
    }
    COLOR = vec4(colour, alpha);
}


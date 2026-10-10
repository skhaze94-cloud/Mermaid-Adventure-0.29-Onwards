shader_type canvas_item;
global uniform float gameplay_time;
render_mode unshaded, blend_add;

// Godot GPU shader. Screen-space refracted light, rendered once per frame.
// Screen UV is intentionally used so the water stays coherent while the camera pans.
uniform vec3 shallow_tint : source_color = vec3(0.26, 0.87, 0.86);
uniform vec3 deep_tint : source_color = vec3(0.02, 0.17, 0.31);
uniform float caustic_strength : hint_range(0.0, 0.4) = 0.13;
uniform float haze_strength : hint_range(0.0, 0.25) = 0.055;
uniform float speed : hint_range(0.0, 3.0) = 0.65;
uniform float water_surface : hint_range(0.0, 0.7) = 0.292;

void fragment() {
    vec2 uv = UV;
    float wet = smoothstep(water_surface - 0.008, water_surface + 0.06, uv.y);
    float depth = clamp((uv.y - water_surface) / max(0.01, 1.0 - water_surface), 0.0, 1.0);
    vec2 flow = uv * vec2(22.0, 12.0);
    float t = gameplay_time * speed;
    float stripe1 = sin(flow.x * 1.35 + sin(flow.y * 1.6 + t) * 1.8 + t * 1.8);
    float stripe2 = cos(flow.x * 0.82 - flow.y * 1.62 + sin(flow.x * 1.45 - t) + t * 1.10);
    float cell = max(0.0, stripe1 * stripe2);
    float caustic = pow(cell, 5.0) * (1.0 - depth * 0.73);
    float secondary = pow(max(0.0, cos(flow.x * 2.3 + t * 0.55) * sin(flow.y + t * 1.3)), 9.0);
    vec3 tint = mix(shallow_tint, deep_tint, depth);
    float strength = wet * (caustic * caustic_strength + secondary * caustic_strength * 0.24 + haze_strength * depth);
    COLOR = vec4(tint * strength, wet * 0.72);
}


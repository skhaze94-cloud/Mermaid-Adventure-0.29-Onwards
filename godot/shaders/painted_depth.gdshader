shader_type canvas_item;
global uniform float gameplay_time;
render_mode unshaded;

// Painted Highlands remain the single opaque foundation. The shader provides
// subtle atmospheric perspective, not a second translucent copy of the art.
uniform float surface_y : hint_range(0.1, 0.5) = 0.292;
uniform float camera_progress : hint_range(0.0, 1.0) = 0.0;
uniform float grotto_mix : hint_range(0.0, 1.0) = 0.0;
uniform float motion_enabled : hint_range(0.0, 1.0) = 1.0;
uniform bool high_quality = true;
uniform float texture_contrast : hint_range(0.5, 1.5) = 1.045;
uniform float water_haze : hint_range(0.0, 0.3) = 0.11;

void fragment() {
    vec2 uv = UV;
    // Keep the painted waterline at the gameplay surface on every viewport.
    uv.y = UV.y < surface_y ? UV.y / surface_y * 0.29 : 0.29 + (UV.y - surface_y) / (1.0 - surface_y) * 0.71;
    float wet = smoothstep(surface_y - 0.015, surface_y + 0.06, uv.y);
    float depth = clamp((uv.y - surface_y) / max(0.01, 1.0 - surface_y), 0.0, 1.0);
    // Two low-frequency flow fields; less than a pixel over most of the frame.
    float phase = gameplay_time * 0.49 * motion_enabled;
    vec2 ripple = vec2(
        sin(uv.y * 23.0 + phase + camera_progress * 5.0) * 0.00048,
        cos(uv.x * 20.0 - phase * 0.67) * 0.00022
    ) * wet * (1.0 - depth * 0.3) * (high_quality ? 1.0 : 0.0);
    vec3 painted = texture(TEXTURE, clamp(uv + ripple, vec2(0.001), vec2(0.999))).rgb;
    painted = (painted - vec3(0.5)) * texture_contrast + vec3(0.5);
    // A gentle tint towards the deep blue only at greater depths.
    vec3 deep_tint = vec3(0.065, 0.25, 0.34);
    float amount = water_haze * wet * (0.25 + depth * 0.75);
    painted = mix(painted, deep_tint, amount);
    vec3 cave_tint = vec3(0.045, 0.125, 0.215);
    float cave_grade = grotto_mix * wet * (0.11 + 0.14 * depth);
    painted = mix(painted, cave_tint, cave_grade);
    COLOR = vec4(clamp(painted, vec3(0.0), vec3(1.0)), 1.0);
}


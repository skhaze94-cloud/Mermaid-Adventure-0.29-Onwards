shader_type canvas_item;
render_mode unshaded, blend_mix;

// Cinematic edge contrast with minimal loss of painted texture detail.
// No screen-texture sampling, no colour clipping, no heavy full-screen bloom.
uniform float surface_y : hint_range(0.0, 0.7) = 0.292;
uniform float edge_strength : hint_range(0.0, 0.3) = 0.12;
uniform float cavern_mix : hint_range(0.0, 1.0) = 0.0;
uniform vec4 deep_ink : source_color = vec4(0.02, 0.09, 0.16, 1.0);

void fragment() {
    vec2 centre = (UV - vec2(0.5, 0.48)) * vec2(1.14, 0.93);
    float distance_to_centre = length(centre);
    float at_edge = smoothstep(0.36, 0.77, distance_to_centre);
    float wet = smoothstep(surface_y, surface_y + 0.09, UV.y);
    float depth = clamp((UV.y - surface_y) / max(0.01, 1.0 - surface_y), 0.0, 1.0);
    float strength = edge_strength * (0.50 + depth * 0.55) + cavern_mix * 0.05;
    float alpha = at_edge * strength * (0.35 + wet * 0.65);
    COLOR = vec4(deep_ink.rgb, clamp(alpha, 0.0, 0.19));
}


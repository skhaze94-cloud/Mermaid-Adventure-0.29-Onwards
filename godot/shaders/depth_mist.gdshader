shader_type canvas_item;
global uniform float gameplay_time;
render_mode unshaded, blend_mix;

// One procedural depth veil, not another painted landscape.
// Very low-opacity rays and suspended silt, behind the bright character.
uniform float surface_y : hint_range(0.0, 0.7) = 0.292;
uniform float mist_amount : hint_range(0.0, 0.2) = 0.075;
uniform float grotto_mix : hint_range(0.0, 1.0) = 0.0;
uniform float motion_enabled : hint_range(0.0, 1.0) = 1.0;
uniform vec4 mist_colour : source_color = vec4(0.23, 0.67, 0.73, 1.0);

void fragment() {
    float wet = smoothstep(surface_y - 0.005, surface_y + 0.08, UV.y);
    float depth = clamp((UV.y - surface_y) / max(0.01, 1.0 - surface_y), 0.0, 1.0);
    float tick = gameplay_time * 0.16 * motion_enabled;
    float shaft_x = UV.x * 7.0 + UV.y * 1.75 + tick;
    float shaft = pow(max(0.0, sin(shaft_x) * cos(shaft_x * 0.49 - tick)), 6.0);
    float silt = 0.5 + 0.5 * sin(UV.x * 81.0 + sin(UV.y * 24.0 - tick) * 3.0);
    float alpha = wet * (mist_amount * (0.16 + depth * 0.58)
        + shaft * 0.047 * (1.0 - depth * 0.48)
        + silt * 0.0045);
    vec3 colour = mix(mist_colour.rgb, vec3(0.19, 0.37, 0.51), depth * 0.34 + grotto_mix * 0.35);
    COLOR = vec4(colour, clamp(alpha, 0.0, 0.19));
}


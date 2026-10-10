shader_type canvas_item;
global uniform float gameplay_time;
render_mode unshaded;

// True screen-texture refraction. Runs after terrain/enemies, before Sarah.
// Caps displacement to ~1.5 screen pixels at 1400px and fades on the surface.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float surface_y : hint_range(0.0, 0.7) = 0.292;
uniform float distortion_px : hint_range(0.0, 3.0) = 1.20;
uniform float opacity : hint_range(0.0, 1.0) = 0.46;
uniform float motion_enabled : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    float wet = smoothstep(surface_y, surface_y + 0.07, UV.y);
    float depth = clamp((UV.y - surface_y) / max(0.01, 1.0 - surface_y), 0.0, 1.0);
    float tick = gameplay_time * motion_enabled;
    float wave_a = sin(SCREEN_UV.y * 105.0 + tick * 1.08);
    float wave_b = cos(SCREEN_UV.x * 73.0 - SCREEN_UV.y * 58.0 - tick * 0.83);
    vec2 pixel_shift = vec2(wave_a + wave_b * 0.38, wave_b * 0.48);
    vec2 shifted = clamp(SCREEN_UV + pixel_shift * SCREEN_PIXEL_SIZE * distortion_px
        * wet * (0.45 + 0.55 * depth), vec2(0.001), vec2(0.999));
    vec3 refracted = texture(screen_texture, shifted).rgb;
    COLOR = vec4(refracted, wet * opacity);
}


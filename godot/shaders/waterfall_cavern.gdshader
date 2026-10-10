shader_type canvas_item;
render_mode unshaded;
global uniform float gameplay_time;
uniform float phase_opacity = 1.0;
uniform float descent_progress = 0.0;
uniform float motion_enabled = 1.0;
uniform float effect_strength = 1.0;

void fragment() {
    // Overscan samples one continuous painting; never wraps or tiles the walls.
    vec2 uv = vec2(UV.x, UV.y * 0.89 + 0.045 + descent_progress * 0.055);
    float clock = gameplay_time * motion_enabled;
    float centre = smoothstep(0.12, 0.34, UV.x) * (1.0 - smoothstep(0.66, 0.88, UV.x));
    uv.x += sin(uv.y * 14.0 + clock * 0.7) * 0.0008 * effect_strength * centre;
    vec4 painted = texture(TEXTURE, clamp(uv, vec2(0.001), vec2(0.999)));
    float veil = sin(UV.x * 31.0 + clock * 0.25 + UV.y * 1.5) * 0.5 + 0.5;
    painted.rgb += vec3(0.02, 0.09, 0.095) * veil * centre * 0.13 * effect_strength;
    painted.rgb *= 1.0 - descent_progress * 0.10;
    COLOR = vec4(painted.rgb, phase_opacity);
}


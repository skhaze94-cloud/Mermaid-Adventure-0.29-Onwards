shader_type canvas_item;
render_mode unshaded;
uniform float menu_clock = 0.0;
uniform bool gentle_motion = true;
void fragment() {
    vec2 uv = UV;
    float t = gentle_motion ? menu_clock : 0.0;
    // Moving only the distant water preserves the painted mountains and castle.
    float water = smoothstep(0.29, 0.39, uv.y);
    uv.x += sin(uv.y * 27.0 + t * 0.32) * 0.0018 * water;
    vec4 painted = texture(TEXTURE, uv);
    float shafts = pow(max(0.0, sin(uv.x * 13.0 + uv.y * 2.0 + t * 0.12)), 12.0);
    painted.rgb += vec3(0.04, 0.13, 0.11) * shafts * water;
    painted.rgb *= mix(0.42, 0.80, smoothstep(0.0, 0.90, UV.x));
    painted.rgb *= 1.0 - 0.27 * smoothstep(0.25, 0.78, distance(UV, vec2(0.54, 0.44)));
    COLOR = painted;
}


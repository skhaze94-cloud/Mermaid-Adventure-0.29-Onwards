shader_type canvas_item;
render_mode unshaded;

// Shaded relief on the source painted obstacle; sprite alpha stays unchanged.
// A cheap top-lit bevel, not a generated 3D mesh or plastic-looking gloss.
uniform bool high_quality = true;
uniform vec4 atlas_bounds = vec4(0.0, 0.0, 1.0, 1.0);
uniform float ceiling_rock : hint_range(0.0, 1.0) = 0.0;
uniform float rock_relief : hint_range(0.0, 0.5) = 0.16;
uniform vec4 light_colour : source_color = vec4(0.69, 0.95, 0.89, 1.0);
uniform vec4 shadow_colour : source_color = vec4(0.09, 0.23, 0.35, 1.0);

void fragment() {
    vec4 base = COLOR; // Godot's built-in sample already includes sprite alpha.
    if (base.a < 0.06) { discard; }
    vec2 uv = (UV - atlas_bounds.xy) / (atlas_bounds.zw - atlas_bounds.xy);
    if (high_quality) {
        vec2 step_uv = TEXTURE_PIXEL_SIZE * 1.5;
        vec2 lo = atlas_bounds.xy + step_uv;
        vec2 hi = atlas_bounds.zw - step_uv;
        vec3 weights = vec3(0.299, 0.587, 0.114);
        float left = dot(texture(TEXTURE, clamp(UV - vec2(step_uv.x,0.0),lo,hi)).rgb, weights);
        float right = dot(texture(TEXTURE, clamp(UV + vec2(step_uv.x,0.0),lo,hi)).rgb, weights);
        float up = dot(texture(TEXTURE, clamp(UV - vec2(0.0,step_uv.y),lo,hi)).rgb, weights);
        float down = dot(texture(TEXTURE, clamp(UV + vec2(0.0,step_uv.y),lo,hi)).rgb, weights);
        vec3 normal = normalize(vec3((left-right)*2.2, (up-down)*2.2, 1.0));
        float diffuse = dot(normal, normalize(vec3(-0.4,-0.6,1.0)));
        base.rgb *= 0.88 + diffuse * 0.16;
    }
    float top = mix(1.0 - uv.y, uv.y, ceiling_rock);
    float shade = smoothstep(0.0, 0.82, top);
    float bevel = pow(max(0.0, 1.0 - abs(uv.x - 0.36) * 1.7), 4.0);
    float highlight = shade * (0.48 + 0.52 * bevel) * rock_relief;
    float shadow = (1.0 - shade) * rock_relief * 0.64;
    vec3 rgb = mix(base.rgb, light_colour.rgb, highlight);
    rgb = mix(rgb, shadow_colour.rgb, shadow);
    COLOR = vec4(rgb, base.a);
}


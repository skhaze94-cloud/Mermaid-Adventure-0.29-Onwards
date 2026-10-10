shader_type canvas_item;
render_mode unshaded;

// Color-grading only: never offset atlas UVs into adjacent texture cells.
// Opacity and fake diffuse shading distinguish far/midground sculpted flora.
uniform vec4 water_tint : source_color = vec4(0.19, 0.48, 0.58, 1.0);
uniform float distance_fog : hint_range(0.0, 0.8) = 0.22;
uniform float relief : hint_range(0.0, 0.3) = 0.09;

void fragment() {
    // In Godot 4, fragment COLOR already contains the texture * sprite modulate.
    // Sampling TEXTURE and multiplying COLOR again would square the alpha.
    vec4 painted = COLOR;
    if (painted.a < 0.035) { discard; }
    float side = clamp(0.5 + 0.5 * sin(UV.x * 9.0 + UV.y * 5.0), 0.0, 1.0);
    float light = 1.0 + relief * (side - 0.5);
    vec3 graded = mix(painted.rgb * light, water_tint.rgb, distance_fog);
    COLOR = vec4(graded, painted.a);
}


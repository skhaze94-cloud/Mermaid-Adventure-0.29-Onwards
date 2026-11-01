shader_type canvas_item;
render_mode unshaded, blend_mix;
uniform float story_time = 0.0;
uniform float camera_x = 0.0;
uniform vec2 view_size = vec2(1400.0,960.0);
uniform float surface_y = 280.0;
uniform float region_alpha = 1.0;
uniform float detail = 1.0;
void fragment() {
    vec2 screen = UV*view_size;
    vec2 world = screen+vec2(camera_x,0.0);
    float wet = smoothstep(surface_y+4.0,surface_y+70.0,screen.y);
    float depth = clamp((screen.y-surface_y)/620.0,0.0,1.0);
    float rays = 0.0;
    for (int i=0; i<4; i++) {
        float f=float(i);
        float source=280.0+f*735.0;
        float axis=world.x-source+(screen.y-surface_y)*(.23+.035*f)+sin(story_time*.13+f)*21.0;
        float width=35.0+depth*(54.0+f*8.0);
        float beam=exp(-pow(axis/width,2.0));
        rays+=beam*(.22+.10*sin(f+1.0));
    }
    vec2 p=world*vec2(.026,.040);
    float caustic=pow(max(0.0,sin(p.x+sin(p.y*.7+story_time*.22))*sin(p.y+cos(p.x*.65-story_time*.19))),11.0);
    float bed=smoothstep(690.0,875.0,screen.y);
    float dapple=caustic*bed*.025*detail;
    float alpha=wet*region_alpha*(rays*.12*(1.0-depth*.47)+dapple);
    vec3 sunlight=mix(vec3(1.0,.91,.69),vec3(.43,.86,.88),depth);
    COLOR=vec4(sunlight,clamp(alpha,0.0,.10));
}

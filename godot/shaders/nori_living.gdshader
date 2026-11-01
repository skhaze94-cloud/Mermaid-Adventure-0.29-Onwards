shader_type canvas_item;
render_mode unshaded;
uniform float story_time = 0.0;
uniform float movement = 1.0;
uniform float attention = 0.0;
// Deform the original full-resolution cutout on a fixed mesh. Transparent-pixel
// colours, alpha and source artwork remain untouched; no texture is repainted.
void vertex() {
    vec2 p = UV;
    float left_horn = exp(-dot((p-vec2(.56,.25))*vec2(19.0,7.0),(p-vec2(.56,.25))*vec2(19.0,7.0)));
    float right_horn = exp(-dot((p-vec2(.86,.28))*vec2(19.0,7.0),(p-vec2(.86,.28))*vec2(19.0,7.0)));
    float bag = exp(-dot((p-vec2(.40,.77))*vec2(7.0,8.0),(p-vec2(.40,.77))*vec2(7.0,8.0)));
    float mantle = (1.0-smoothstep(.57,.90,p.y))*(1.0-smoothstep(.51,.69,p.x));
    VERTEX.x += movement*(left_horn*sin(story_time*1.8)*12.0 + right_horn*sin(story_time*1.6+.8)*10.0 + bag*sin(story_time*1.1)*5.0);
    VERTEX.y += movement*(mantle*sin(story_time*.9+p.x*8.0)*4.0 + bag*cos(story_time*1.1)*3.0);
    VERTEX.x += movement*sin(story_time*2.9)*left_horn*.9;
    VERTEX.x += movement*attention*(left_horn-right_horn)*4.0;
}

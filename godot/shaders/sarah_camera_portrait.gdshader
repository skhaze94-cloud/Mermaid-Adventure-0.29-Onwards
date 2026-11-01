shader_type canvas_item;
render_mode unshaded;
uniform sampler2D front_blink:source_color;
uniform sampler2D away_paint:source_color;
uniform sampler2D away_blink:source_color;
uniform float away_mix=0.0;
uniform float blink=0.0;
varying vec4 tint;
void vertex(){tint=COLOR;}
void fragment(){
 vec4 a=texture(TEXTURE,UV);vec4 b=texture(front_blink,UV);
 vec4 c=texture(away_paint,UV);vec4 d=texture(away_blink,UV);
 // Each frame uses one registered painting; partial opacity creates doubled eyes.
 float closed=step(.5,blink);
 COLOR=mix(mix(a,b,closed),mix(c,d,closed),step(.5,away_mix))*tint;
}

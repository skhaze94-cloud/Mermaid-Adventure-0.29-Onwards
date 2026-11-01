shader_type canvas_item;
uniform sampler2D front_paint:source_color,filter_linear,repeat_disable;
uniform float view_mix=0.0;
uniform float depth_turn=0.0;
uniform bool volume_enabled=true;
uniform bool negative_view=false;
varying vec2 reverse_uv;
varying vec2 front_uv;
varying vec4 tint;
void vertex(){front_uv=CUSTOM0.xy;reverse_uv=CUSTOM1.xy;tint=COLOR;}
void fragment(){
 vec4 side=texture(TEXTURE,negative_view?reverse_uv:UV);vec4 front=texture(front_paint,front_uv);
 float v=clamp((UV.y-19.5/1024.0)/(217.0/1024.0),0.0,1.0);
 float lum=dot(side.rgb,vec3(.2126,.7152,.0722));vec3 pearl=vec3(.48,.70,.98);pearl*=lum/dot(pearl,vec3(.2126,.7152,.0722));
 side.rgb=mix(side.rgb,pearl,smoothstep(.57,.96,v)*.76);
 // Registered alpha contours share one silhouette. Blend paint in premultiplied space.
 vec4 paint=mix(vec4(side.rgb*side.a,side.a),vec4(front.rgb*front.a,front.a),view_mix);
 vec3 rgb=paint.rgb/max(.0001,paint.a);
 float normal_z=sqrt(max(0.0,1.0-pow((v-.5)*2.0,2.0)));
 float light=.88+normal_z*.12-(v-.5)*2.0*(.055+depth_turn*.035);
 COLOR=vec4(rgb*(volume_enabled?light:1.0),paint.a)*tint;
}

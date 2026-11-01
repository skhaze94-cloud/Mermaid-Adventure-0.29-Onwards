shader_type canvas_item;
render_mode unshaded;
uniform sampler2D nursery_art:filter_linear,repeat_disable;
uniform sampler2D bellflower_art:filter_linear,repeat_disable;
uniform sampler2D cave_wall:filter_linear,repeat_enable;
uniform sampler2D shafts_art:filter_linear,repeat_disable;
uniform vec4 room_horizontal;
uniform vec4 room_metrics=vec4(1100.0,580.0,1160.0,620.0);
varying vec4 source_tint;
void vertex(){source_tint=COLOR;}
float box_distance(vec2 p,vec2 center,vec2 half_size){
    vec2 q=abs(p-center)-half_size;
    return length(max(q,vec2(0.0)))+min(max(q.x,q.y),0.0);
}
vec3 rock_color(vec2 coordinate){
    vec3 a=texture(cave_wall,coordinate*.73+vec2(.17,.31)).rgb;
    vec3 b=texture(cave_wall,coordinate*1.27+vec2(.49,.13)).rgb;
    float mineral=dot(mix(a,b,.34),vec3(.30,.50,.20));
    return mix(vec3(.075,.17,.21),vec3(.23,.38,.39),smoothstep(.06,.74,mineral));
}
void fragment(){
    bool cave=(abs(source_tint.g-.4567)<.005 && abs(source_tint.b-.7891)<.005 && source_tint.r<.24);
    bool wall=abs(source_tint.r-.3234)<.005 && abs(source_tint.g-.1234)<.005;
    if(cave){
        bool nursery=source_tint.r<.17;
        vec3 top= nursery?vec3(.10,.37,.44):vec3(.13,.32,.44);
        vec3 bottom=nursery?vec3(.055,.27,.34):vec3(.085,.24,.35);
        float depth=clamp((UV.y+.6)/1.8,0.0,1.0);
        vec3 quiet_water=mix(top,bottom,depth);
        float light=sin(UV.x*9.0+UV.y*.9)*.009+cos(UV.x*19.0-UV.y*2.0)*.006;
        float room_x=nursery?room_horizontal.x:room_horizontal.z;
        float room_w=nursery?room_horizontal.y:room_horizontal.w;
        float room_y=nursery?room_metrics.x:room_metrics.z;
        float room_h=nursery?room_metrics.y:room_metrics.w;
        float world_x=room_x+UV.x*room_w;
        float world_y=room_y+UV.y*room_h;
        vec2 water_uv=vec2(UV.x,.35+(world_y-780.0)/(room_y+room_h+230.0-780.0)*.61);
        vec3 old_water=texture(TEXTURE,water_uv).rgb*vec3(.56,.70,.78);
        vec4 water=vec4(mix(quiet_water+vec3(light),old_water,.44),1.0);
        float left=nursery?660.0:2100.0;
        float right=nursery?1160.0:2860.0;
        float atlas_y=clamp((world_y-896.0)/490.0,.002,.998);
        float join=1.0-smoothstep(room_y+30.0,room_y+200.0,world_y);
        // Overlap the two authored passages using live UVs: no hard atlas join
        // and no constant-column sampling that would smear the painted stone.
        float origin=nursery?0.0:0.5;
        float left_u=clamp(UV.x/.58,.002,.998);
        float right_u=clamp((UV.x-.42)/.58,.002,.998);
        vec4 shaft_left=texture(shafts_art,vec2(origin+left_u*.25,atlas_y));
        vec4 shaft_right=texture(shafts_art,vec2(origin+.25+right_u*.25,atlas_y));
        vec4 shaft=mix(shaft_left,shaft_right,smoothstep(.43,.57,UV.x));
        water=mix(water,shaft*vec4(.75,.86,.92,1.0),join);
        vec2 art_uv=clamp(vec2(.09,.12)+UV*vec2(.82,.74),vec2(.001),vec2(.999));
        vec4 art=nursery?texture(nursery_art,art_uv):texture(bellflower_art,art_uv);
        float blend=smoothstep(-.02,.16,UV.y)*(1.0-smoothstep(.86,1.05,UV.y));
        blend*=smoothstep(-.08,.10,UV.x)*(1.0-smoothstep(.90,1.08,UV.x));
        vec4 painted=mix(water,art,blend);
        vec2 p=vec2(world_x,world_y);
        float d=box_distance(p,vec2(room_x+room_w*.5,room_y+room_h*.5),vec2(room_w,room_h)*.5);
        float shaft_h=room_y+240.0-780.0;
        d=min(d,box_distance(p,vec2(left,780.0+shaft_h*.5),vec2(160.0,shaft_h*.5)));
        d=min(d,box_distance(p,vec2(right,780.0+shaft_h*.5),vec2(160.0,shaft_h*.5)));
        d=min(d,box_distance(p,vec2(room_x+room_w*.525,room_y+10.0),vec2(room_w*.175,155.0)));
        d=min(d,box_distance(p,vec2(room_x+room_w*.55,room_y+room_h+75.0),vec2(room_w*.16,155.0)));
        float brush=sin(world_x*.037+world_y*.019)*6.0+sin(world_y*.061-world_x*.012)*3.0;
        float feather=smoothstep(-31.0,-2.0,d+brush);
        COLOR=mix(painted,vec4(rock_color(p/540.0),1.0),feather);
    }else if(wall){
        COLOR=vec4(rock_color(UV),1.0);
    }else{COLOR=texture(TEXTURE,UV)*source_tint;}
}

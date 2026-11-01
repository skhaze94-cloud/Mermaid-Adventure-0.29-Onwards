shader_type canvas_item;
render_mode unshaded;
uniform sampler2D cave_wall:filter_linear,repeat_enable;
uniform sampler2D room_art0:filter_linear,repeat_disable;
uniform sampler2D room_art1:filter_linear,repeat_disable;
uniform sampler2D room_art2:filter_linear,repeat_disable;
uniform vec4 room0;
uniform vec4 room1;
uniform vec4 room2;
uniform vec4 openings0;
uniform vec4 openings1;
uniform vec4 openings2;
uniform vec4 tint0=vec4(1.0);
uniform vec4 tint1=vec4(1.0);
uniform vec4 tint2=vec4(1.0);
varying vec4 paint_tint;
void vertex(){paint_tint=COLOR;}
float ground(float x){return 896.0+sin(x*.006)*4.0+sin(x*.019)*1.8+sin(x*.0017)*4.0;}
float box_distance(vec2 p,vec2 c,vec2 h){vec2 q=abs(p-c)-h;return length(max(q,vec2(0.0)))+min(max(q.x,q.y),0.0);}
vec3 stone(vec2 p){
    vec2 uv=p/1100.0;
    vec3 a=texture(cave_wall,uv*.73+vec2(.17,.31)).rgb;
    vec3 b=texture(cave_wall,uv*1.27+vec2(.49,.13)).rgb;
    return mix(a,b,.28)*.67+vec3(.025,.075,.085);
}
void fragment(){
    bool room=abs(paint_tint.g-.4567)<.005 && abs(paint_tint.b-.7891)<.005;
    bool wall=abs(paint_tint.r-.3234)<.005 && abs(paint_tint.g-.1234)<.005;
    if(room){
        int index=int(round((paint_tint.r-.1234)*10.0));
        vec4 r=index==0?room0:(index==1?room1:room2);
        vec4 entrances=index==0?openings0:(index==1?openings1:openings2);
        vec2 p=r.xy+UV*r.zw;
        // One painting is sampled continuously from the descent to the pocket.
        // There is no shaft/room texture crossfade and no horizontal UV clamp.
        vec2 q=vec2(.04+UV.x*.92,.045+(p.y-780.0)/(r.y+r.w+230.0-780.0)*.91);
        q=clamp(q,vec2(.002),vec2(.998));
        vec4 art=index==0?texture(room_art0,q):(index==1?texture(room_art1,q):texture(room_art2,q));
        vec4 tint=index==0?tint0:(index==1?tint1:tint2);
        art.rgb*=tint.rgb;
        float d=box_distance(p,r.xy+r.zw*.5,r.zw*.5);
        float shaft_h=r.y+240.0-780.0;
        d=min(d,box_distance(p,vec2(entrances.x,780.0+shaft_h*.5),vec2(entrances.z,shaft_h*.5)));
        d=min(d,box_distance(p,vec2(entrances.y,780.0+shaft_h*.5),vec2(entrances.z,shaft_h*.5)));
        d=min(d,box_distance(p,vec2(r.x+r.z*.525,r.y+10.0),vec2(r.z*.175,155.0)));
        d=min(d,box_distance(p,vec2(r.x+r.z*.55,r.y+r.w+75.0),vec2(r.z*.16,155.0)));
        float grain=sin(p.x*.027+p.y*.016)*8.0+sin(p.y*.053-p.x*.014)*4.0;
        float edge=smoothstep(-88.0,1.0,d+grain);
        float arrival=smoothstep(ground(p.x)-60.0,ground(p.x)-5.0,p.y);
        COLOR=vec4(mix(art.rgb,stone(p),edge),arrival);
    }else if(wall){
        vec2 p=UV*540.0;
        float alpha=smoothstep(ground(p.x)-60.0,ground(p.x)-5.0,p.y);
        COLOR=vec4(stone(p),alpha);
    }else{COLOR=texture(TEXTURE,UV)*paint_tint;}
}

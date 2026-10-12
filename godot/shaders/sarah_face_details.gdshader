shader_type canvas_item;
uniform vec2 atlas_size = vec2(2172.0,724.0);
uniform vec4 neutral_crop = vec4(15.0,80.0,710.0,570.0);
uniform vec4 happy_crop = vec4(735.0,80.0,700.0,570.0);
uniform vec4 blink_crop = vec4(1445.0,80.0,710.0,570.0);
uniform bool detail_enabled = false;
uniform vec4 response = vec4(0.0); // Local travel x/y, shared body yaw, boost effort.
uniform float breath = 0.0;
uniform float jaw_open : hint_range(0.0,1.0) = 0.0;
uniform float neck_follow = 0.0;
uniform float body_wave = 0.0;
uniform float hair_lag = 0.0;
uniform float motion_phase = 0.0;
uniform vec2 gaze = vec2(0.0);
uniform float expression : hint_range(0.0,1.0) = 0.0;
uniform float blink : hint_range(0.0,1.0) = 0.0;
varying vec4 tint;

float feature(vec2 p, vec2 center, vec2 radius) {
    vec2 d = (p-center)/radius;
    return exp(-dot(d,d)*2.0);
}
vec2 paint_uv(vec2 p, vec4 crop) {
    return (crop.xy+vec2(.5)+clamp(p,vec2(0.0),vec2(1.0))*(crop.zw-vec2(1.0)))/atlas_size;
}
void vertex() {
    tint=COLOR;
    vec2 p=(UV*atlas_size-neutral_crop.xy-vec2(.5))/(neutral_crop.zw-vec2(1.0));
    if (detail_enabled) {
        // Every feature sits in the same surface; the collar/neck stay locked.
        float anchored=1.0-smoothstep(.78,.90,p.y);
        float ear=feature(p,vec2(.49,.70),vec2(.10,.12));
        float nose=feature(p,vec2(.83,.565),vec2(.065,.075));
        float jaw=feature(p,vec2(.80,.71),vec2(.14,.085));
        float lower_lip=feature(p,vec2(.82,.685),vec2(.11,.025));
        float cheek=feature(p,vec2(.73,.65),vec2(.20,.15));
        float brows=max(feature(p,vec2(.68,.36),vec2(.12,.05)),feature(p,vec2(.88,.31),vec2(.085,.05)));
        float hair=max(1.0-smoothstep(.38,.64,p.x),1.0-smoothstep(.10,.22,p.y));
        float free_end=(1.0-smoothstep(.12,.67,p.x))*hair*anchored;
        // Hair trails the body wave and current; its roots remain on the skull.
        float wave=sin(motion_phase*.5-.4-p.x*2.0-p.y*.7);
        vec2 drift=vec2(-response.x*.9+hair_lag*2.0,
            wave*(2.0+response.w*1.3)+hair_lag*8.0+body_wave*1.1);
        drift+=vec2(sin(motion_phase*.83-p.x*4.7)*.22+sin(motion_phase*1.27-p.y*6.3)*.10,
            sin(motion_phase*.91-p.x*5.5-p.y)*.48+sin(motion_phase*1.43-p.x*8.0+p.y)*.20);
        drift+=vec2(sin(motion_phase*.63-p.x*3.8)*.07+sin(motion_phase*1.67-p.y*8.1)*.035+sin(motion_phase*2.19-p.x*10.5)*.017,
            sin(motion_phase*.71-p.x*4.4)*.12+sin(motion_phase*1.79-p.x*10.1+p.y)*.06+sin(motion_phase*2.43-p.x*13.7)*.025);
        VERTEX+=drift*free_end;
        // Forehead locks breathe across the crown without moving eyes or brows.
        float crown=(1.0-smoothstep(.18,.32,p.y))*smoothstep(.32,.52,p.x)*(1.0-smoothstep(.92,1.0,p.x));
        VERTEX+=crown*vec2(sin(motion_phase*.47-p.x*3.2)*.65
            +sin(motion_phase*.79-p.x*5.8)*.22+sin(motion_phase*1.21-p.x*8.4)*.09,
            sin(motion_phase*.55-p.x*4.0)*.60+sin(motion_phase*.93-p.x*6.5)*.20+sin(motion_phase*1.39-p.x*9.0)*.08);
        // A soft throat bend fades out before the painted collar attachment.
        float throat=feature(p,vec2(.70,.835),vec2(.13,.065));
        VERTEX.x+=throat*neck_follow*14.0*anchored;
        // Sub-pixel game-scale parallax, rather than independent ear/nose flapping.
        VERTEX.y+=anchored*jaw_open*(jaw*3.4+lower_lip*.6);
        VERTEX.x-=anchored*jaw_open*jaw*.65;
        VERTEX.x+=anchored*(ear*(-response.z*1.2+hair_lag*.65)+nose*response.z*.8);
        VERTEX.y+=anchored*(ear*(response.y*.35+body_wave*.25)
            +nose*breath*.18+cheek*breath*.24-brows*expression*.65);
    }
}
void fragment() {
    vec2 p=(UV*atlas_size-neutral_crop.xy-vec2(.5))/(neutral_crop.zw-vec2(1.0));
    float near_eye=feature(p,vec2(.71,.51),vec2(.10,.065));
    float far_eye=feature(p,vec2(.88,.455),vec2(.075,.065));
    float eyes=clamp(max(near_eye,far_eye)*1.8,0.0,1.0);
    float mouth=clamp(feature(p,vec2(.82,.67),vec2(.15,.095))*1.8,0.0,1.0);
    float irises=max(feature(p,vec2(.714,.512),vec2(.036,.045)),feature(p,vec2(.884,.452),vec2(.031,.044)));
    vec2 look=detail_enabled ? gaze*vec2(.0022,.0016)*irises*(1.0-blink) : vec2(0.0);
    vec4 base=texture(TEXTURE,paint_uv(p-look,neutral_crop));
    vec4 smile=texture(TEXTURE,paint_uv(p-look,happy_crop));
    vec4 closed=texture(TEXTURE,paint_uv(p,blink_crop));
    // Only eyes/mouth blend: nose, ear, hair and neck retain one registered painting.
    vec4 painted=mix(base,smile,expression*max(mouth,eyes*.18));
    painted=mix(painted,closed,blink*eyes);
    float light=detail_enabled ? 1.0-abs(response.z)*.015-response.z*(p.x-.5)*.012 : 1.0;
    COLOR=vec4(painted.rgb*light,painted.a)*tint;
}

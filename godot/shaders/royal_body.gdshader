shader_type canvas_item;
render_mode unshaded;
uniform float clock = 0.0;
uniform float strength = 0.0;
uniform vec3 pose = vec3(0.0);
uniform bool is_queen = false;
vec2 rotate_about(vec2 p, vec2 pivot, float angle) {
    float c = cos(angle); float s = sin(angle);
    vec2 d = p-pivot;
    return pivot+vec2(d.x*c-d.y*s,d.x*s+d.y*c);
}
void vertex() {
    vec2 p = VERTEX;
    vec2 local = p+vec2(0.5);
    float arm_height = smoothstep(0.17,0.28,local.y)*(1.0-smoothstep(0.46,0.62,local.y));
    float near_arm = smoothstep(0.54,0.88,local.x)*arm_height;
    float far_arm = (1.0-smoothstep(0.12,0.36,local.x))*arm_height;
    float beat = sin(clock*3.0)*0.024 + sin(clock*1.3)*0.010;
    p = rotate_about(p,vec2(0.04,-0.23),(pose.x*(0.55+0.45*sin(clock*3.4))+beat)*near_arm*strength);
    p = rotate_about(p,vec2(-0.06,-0.20),(-pose.x*0.28+beat*0.4)*far_arm*strength);
    float forearm = smoothstep(0.72,0.94,local.x)*arm_height;
    p = rotate_about(p,vec2(0.22,-0.18),pose.y*forearm*strength);
    float cloth = smoothstep(0.48,0.96,local.y);
    float flow = is_queen ? 0.011 : 0.009;
    p.x += strength*(sin(clock*1.65-local.y*5.0)*flow+sin(clock*2.5-local.y*8.0)*0.003)*cloth;
    p.y += strength*sin(clock*1.4)*0.003*(1.0-cloth);
    p.y += strength*sin(clock*2.1-local.x*4.0)*0.004*cloth*abs(local.x-0.5)*2.0;
    float hair = (1.0-smoothstep(0.38,0.52,local.y))*smoothstep(0.17,0.34,local.y)*smoothstep(0.19,0.38,abs(local.x-0.5));
    p.x += strength*sin(clock*1.8-local.y*7.0)*0.006*hair;
    VERTEX = p;
}

shader_type canvas_item;
render_mode unshaded;
uniform vec4 cell_uv = vec4(0.0,0.0,1.0,1.0);
uniform int anatomy = 0;
uniform int combat_pose = 0;
uniform vec4 joints = vec4(0.0);
uniform vec4 posture = vec4(0.0);
uniform float visual_clock = 0.0;
uniform float facing = 1.0;
uniform float depth_turn = 0.0;
uniform float hit = 0.0;
uniform bool animate_detail = true;
uniform bool high_quality = true;
// Compatibility telemetry also used by boss quality checks.
uniform float strength = 1.0;
uniform float attack_mix = 0.0;
varying vec4 tint;
varying vec2 local_uv;
varying float volume;
vec2 hinge(vec2 p, vec2 pivot, float angle, float weight) {
    float a = angle*clamp(weight,0.0,1.0);
    vec2 d = p-pivot;
    return pivot+vec2(d.x*cos(a)-d.y*sin(a),d.x*sin(a)+d.y*cos(a));
}
float limb(vec2 p, vec2 pivot, vec2 tip, float width) {
    vec2 axis = tip-pivot;
    float along = dot(p-pivot,axis)/dot(axis,axis);
    float distance = length((p-pivot)-axis*clamp(along,0.0,1.0));
    return smoothstep(0.0,.45,along)*(1.0-smoothstep(width*.6,width,distance));
}
vec2 claw(vec2 p, vec2 root, vec2 palm, vec2 tip, float swing, float jaw, float spread) {
    float reach = limb(p,root,tip,.15);
    vec2 moved = hinge(p,root,swing+spread,reach);
    // Two opposed jaws rotate about the same palm; the wrist remains attached.
    vec2 axis = normalize(tip-palm);
    vec2 normal = vec2(-axis.y,axis.x);
    float edge = dot(p-palm,normal);
    float upper = smoothstep(-.018,.025,edge);
    float fingers = smoothstep(.0,.12,dot(p-palm,axis));
    moved = hinge(moved,palm,(upper*2.0-1.0)*jaw,fingers*reach);
    return moved;
}
void vertex() {
    tint=COLOR;
    local_uv=UV;
    vec2 p=UV;
    volume=0.0;
    float beat=visual_clock;
    if (animate_detail) {
        if (anatomy==1 || anatomy==5 || anatomy==7 || anatomy==9 || anatomy==10) {
            // Two connected tail hinges plus delayed flexible spine. Head/hat stays still.
            vec2 rest=UV;
            if (anatomy==10) {rest.x=1.0-rest.x;p=rest;}
            float root = anatomy==9 ? .45 : (anatomy==10 ? .43 : .51);
            float quiet = 1.0-smoothstep(root-.10,root+.20,p.x);
            float tail = 1.0-smoothstep(.15,.38,p.x);
            p=hinge(p,vec2(root,.56),joints.x,quiet);
            p=hinge(p,vec2(.25,.55),joints.x*.68+sin(beat-.7)*.06,tail);
            if (anatomy==1) {
                p.y+=sin(beat-p.x*6.0)*.045*quiet;
                p.x+=cos(beat-p.x*6.0)*.010*quiet;
            }
            vec2 pivot=vec2(.60,.62);
            vec2 tip=vec2(.47,.83);
            if (anatomy==7) {pivot=vec2(.70,.57);tip=vec2(.54,.78);}
            if (anatomy==9) {pivot=vec2(.62,.63);tip=vec2(.67,.84);}
            if (anatomy==10) {pivot=vec2(.64,.62);tip=vec2(.50,.86);}
            float fin=limb(rest,pivot,tip,.13);
            p=hinge(p,pivot,joints.y+posture.x*.18,fin);
            // Paddle changes projected length as it passes behind the body.
            p.x+=(pivot.x-rest.x)*fin*(.10+.12*sin(beat-.85));
            float dorsal=limb(rest,vec2(.48,.52),vec2(.43,.27),.15);
            p=hinge(p,vec2(.48,.52),-joints.y*.28,dorsal);
            volume=fin*sin(beat-.85)*.15;
            if (anatomy==10) {p.x=1.0-p.x;}
        } else if (anatomy==2) {
            // Bell contraction pumps from a fixed rim; each tentacle lags separately.
            float bell=1.0-smoothstep(.29,.38,UV.y);
            float pump=joints.z*1.6;
            p.x=.5+(UV.x-.5)*(1.0+sin(beat)*.10*bell);
            p.y=.32+(UV.y-.32)*(1.0-pump*bell);
            float strand=smoothstep(.31,.90,UV.y);
            float lane=floor(UV.x*9.0);
            p.x+=sin(beat-UV.y*5.8+lane*.31)*.064*strand;
            p.y+=cos(beat-UV.y*4.3+lane*.42)*.025*strand;
            volume=sin(beat)*bell*.055;
        } else if (anatomy==3 || anatomy==6) {
            vec2 left_root=vec2(.25,.38);
            vec2 left_palm=vec2(.35,.54);
            vec2 left_tip=vec2(.47,.63);
            vec2 right_root=vec2(.69,.39);
            vec2 right_palm=vec2(.78,.45);
            vec2 right_tip=vec2(.93,.59);
            if (anatomy==6) {
                left_root=vec2(.29,.46);left_palm=vec2(.32,.65);left_tip=vec2(.43,.84);
                right_root=vec2(.79,.49);right_palm=vec2(.74,.68);right_tip=vec2(.64,.86);
            }
            p=claw(p,left_root,left_palm,left_tip,joints.x,joints.z*.90,-posture.x*.32);
            p=claw(p,right_root,right_palm,right_tip,-joints.y,joints.z*.90,posture.x*.32);
            // Walking fan: legs on opposite sides alternate instead of moving as one card.
            float legs;
            // Explicit edge mask keeps the eyes and shell out of the leg wave.
            legs=smoothstep(.66,.91,UV.y)*smoothstep(.18,.40,abs(UV.x-.54));
            p.y+=sin(beat*1.6+floor(UV.x*14.0)*1.6)*legs*.025;
            p.x+=cos(beat*1.6+floor(UV.x*14.0)*1.6)*legs*.012;
            volume=sin(beat-.5)*.045;
        } else if (anatomy==4) {
            vec2 centre=vec2(.62,.55);
            float face=1.0-smoothstep(.69,.88,UV.x);
            p=centre+(p-centre)*(1.0+(joints.z+posture.x*.10)*face);
            float tail=1.0-smoothstep(.15,.37,UV.x);
            p=hinge(p,vec2(.30,.56),joints.x*1.3,tail);
            float fin=limb(UV,vec2(.54,.57),vec2(.41,.69),.11);
            p=hinge(p,vec2(.54,.57),joints.y*1.4,fin);
            volume=sin(beat)*.05;
        } else if (anatomy==8) {
            // Manta: independent shoulder and tip flexion on both large wings.
            float wing=smoothstep(.10,.42,abs(UV.x-.5));
            float tip=smoothstep(.29,.48,abs(UV.x-.5));
            float side=sign(UV.x-.5);
            p=hinge(p,vec2(.5+side*.13,.48),side*joints.x,wing);
            p.y+=sin(beat-.8)*tip*.060;
            p.x-=side*(.02+.03*cos(beat))*wing;
            float tail=smoothstep(.60,.95,UV.y)*(1.0-smoothstep(.06,.17,abs(UV.x-.5)));
            p.x+=sin(beat-UV.y*5.0)*tail*.065;
            volume=cos(beat)*wing*.09;
        } else if (anatomy==11) {
            p=hinge(p,vec2(.30,.38),joints.x-posture.x*.17,limb(UV,vec2(.30,.38),vec2(.17,.55),.16));
            p=hinge(p,vec2(.66,.38),-joints.y+posture.x*.17,limb(UV,vec2(.66,.38),vec2(.75,.55),.16));
            float tail=smoothstep(.75,.94,UV.x)*smoothstep(.40,.58,UV.y);
            p=hinge(p,vec2(.76,.59),joints.x*1.25,tail);
            p.y+=sin(beat+.6)*.018*smoothstep(.61,.84,UV.y);
            volume=sin(beat)*.04;
        } else if (anatomy==12) {
            p=hinge(p,vec2(.40,.38),joints.x,limb(UV,vec2(.40,.38),vec2(.23,.53),.12));
            p=hinge(p,vec2(.61,.37),-joints.y-posture.x*.20,limb(UV,vec2(.61,.37),vec2(.76,.51),.13));
            p.x+=sin(beat-UV.y*4.0)*.016*smoothstep(.55,.98,UV.y);
            volume=sin(beat)*.035;
        }
        // Small body bank and foreshortening, keeping the anatomical root connected.
        p=hinge(p,vec2(.55,.52),joints.w,1.0);
        p.x=.55+(p.x-.55)*(1.0-abs(posture.z)*.25);
    }
    VERTEX=(p-vec2(.5))*vec2(facing,1.0);
    UV=cell_uv.xy+UV*cell_uv.zw;
}
void fragment() {
    vec2 bounded=clamp(UV,cell_uv.xy+TEXTURE_PIXEL_SIZE*.5,cell_uv.xy+cell_uv.zw-TEXTURE_PIXEL_SIZE*.5);
    vec4 paint=texture(TEXTURE,bounded);
    if (paint.a<.025) {discard;}
    if (high_quality) {
        float curve=sqrt(max(0.0,1.0-pow((local_uv.y-.5)*1.7,2.0)));
        paint.rgb*=.94+curve*.06+volume*.55-(local_uv.y-.5)*depth_turn*.09;
        float sheen=pow(max(0.0,1.0-abs(local_uv.x-.33)*2.3),3.0)*curve;
        paint.rgb+=vec3(.015,.028,.035)*sheen;
    }
    if (combat_pose==1) {paint.rgb=mix(paint.rgb,vec3(1.0,.77,.44),.075);}
    if (combat_pose==3) {paint.rgb=mix(paint.rgb,vec3(.63,.92,.83),.045);}
    paint.rgb=mix(paint.rgb,vec3(1.0,.93,.73),hit*.40);
    COLOR=paint*tint;
}

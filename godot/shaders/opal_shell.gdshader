shader_type canvas_item;
render_mode unshaded;
global uniform float gameplay_time;
uniform int state=0;
uniform bool gentle=false;
varying vec4 instance_tint;
void vertex(){instance_tint=COLOR;}
void fragment(){
    float angle=UV.x*6.28318530718;
    float tube=sqrt(max(0.0,1.0-pow(UV.y*2.0-1.0,2.0)));
    float edge=smoothstep(0.0,0.15,UV.y)*(1.0-smoothstep(0.85,1.0,UV.y));
    float petals=1.0;vec3 tint=vec3(0.96,0.72,0.36);
    if(state==1){petals=1.0-smoothstep(0.97,0.995,abs(sin(angle)));}
    else if(state==2){tint=vec3(0.56,0.94,0.76);petals=1.0-smoothstep(0.82,0.92,abs(sin(angle)));}
    else if(state==3){tint=vec3(0.69,0.64,0.85);petals=1.0-smoothstep(0.78,0.91,sin(angle+0.5));}
    float facet=0.88+0.12*cos(angle*(state==0?10.0:3.0));
    float glint=pow(max(0.0,cos(angle+2.2)),12.0);
    float breath=gentle?1.0:0.96+0.04*sin(gameplay_time*2.0);
    float film=0.5+0.5*sin(angle*3.0+UV.y*11.0);
    vec3 pearl=mix(vec3(0.56,0.86,1.0),vec3(0.89,0.70,1.0),film);
    vec3 opal=tint*(0.74+tube*0.24)+pearl*(0.025+tube*0.045)+vec3(glint*0.56);
    float alpha=edge*petals*facet*breath*(0.30+tube*0.58);
    if(state==3){alpha*=0.55;}
    COLOR=vec4(opal,alpha)*instance_tint;
}

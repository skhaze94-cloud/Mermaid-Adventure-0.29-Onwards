float soft_region(vec2 p, vec4 zone) { return 1.0-smoothstep(.35,1.0,length((p-zone.xy)/zone.zw)); }
vec2 character_details(vec2 p,float t,float seed,float amount,vec4 fin,vec4 shell,vec4 face) {
 float guard=1.0-soft_region(p,face);
 float rest=.30+.70*pow(max(0.0,sin(t*.51+seed)),2.0);
 float a=soft_region(p,fin)*guard;
 float b=soft_region(p,shell)*guard;
 p.x+=amount*(sin(t*2.3+seed-p.y*6.0)*.006*a*rest+sin(t*.85+seed)*.0025*b);
 p.y+=amount*(sin(t*2.9+seed+p.x*5.0)*.004*a*rest+sin(t*1.1+seed+1.2)*.002*b);
 return p;
}

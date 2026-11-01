shader_type canvas_item;
uniform vec4 bounds=vec4(0.0,0.0,1.0,1.0);
void fragment(){vec4 p=COLOR;float u=(UV.x-bounds.x)/bounds.z;p.a*=smoothstep(.17,.23,u);COLOR=p;}

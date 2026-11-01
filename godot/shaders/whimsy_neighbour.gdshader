shader_type canvas_item;
render_mode unshaded;
uniform float story_time=0.0;
uniform float mood=0.0;
uniform float seed=0.0;
uniform float gentle=0.0;
void vertex(){
    float soft=(1.0-gentle);
    float lower=smoothstep(.25,1.0,UV.y);
    VERTEX.x+=sin(story_time*1.6+UV.y*3.0+seed)*.007*lower*soft;
    VERTEX.y+=sin(story_time*1.8+seed)*.004*(1.0-UV.y)*soft;
    VERTEX.x+=(UV.x-.5)*sin(story_time*2.1+seed)*.006*mood*soft;
}

uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;

#define AA_THICKNESS 2.0

vec2 screen_space(vec4 vertex)
{
    return vec2(vertex.xy / vertex.w) * get_resolution();
}
vec3 tovec3(vec2 v){return vec3(v, 0.0);}
vec3 tovec3(vec3 v){return v;}

varying vec4 frag_color;

void main()
{
    mat4 pvm = projectionMatrix * modelViewMatrix;
    vec4 point1_clip = pvm * vec4(tovec3(get_segment_start()), 1);
    vec4 point2_clip = pvm * vec4(tovec3(get_segment_end()), 1);
    vec2 point1_screen = screen_space(point1_clip);
    vec2 point2_screen = screen_space(point2_clip);
    vec2 dir = normalize(point2_screen - point1_screen);
    vec2 normal = vec2(-dir.y, dir.x);
    vec4 anchor; float thickness;
    if(position.x == 0.0){
        anchor = point1_clip;
        frag_color = get_color_start();
        thickness = get_linewidth_start();
    }else{
        anchor = point2_clip;
        frag_color = get_color_end();
        thickness = get_linewidth_end();
    }
    normal *= ((thickness + AA_THICKNESS) / 2.0) / get_resolution();
    // quadpos y (position.y) gives us the direction to expand the line
    vec4 offset = vec4(normal * position.y, 0.0, 0.0);
    // start, or end of quad, need to use current or next point as anchor

    gl_Position = anchor + offset;

}

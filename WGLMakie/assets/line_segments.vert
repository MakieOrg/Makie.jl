uniform mat4 projection;
uniform mat4 view;

vec2 screen_space(vec4 position)
{
    return vec2(position.xy / position.w) * get_resolution();
}
vec3 tovec3(vec2 v){return vec3(v, 0.0);}
vec3 tovec3(vec3 v){return v;}

vec4 tovec4(vec3 v){return vec4(v, 1.0);}
vec4 tovec4(vec4 v){return v;}

out vec4 frag_color;

void main()
{
    mat4 pvm = projection * view * get_model();
    vec4 point1_clip = pvm * vec4(tovec3(get_segment_start()), 1);
    vec4 point2_clip = pvm * vec4(tovec3(get_segment_end()), 1);
    vec2 point1_screen = screen_space(point1_clip);
    vec2 point2_screen = screen_space(point2_clip);
    vec2 dir = normalize(point2_screen - point1_screen);
    vec2 normal = vec2(-dir.y, dir.x);
    vec4 anchor;
    float thickness;

    if(position.x == 0.0){
        anchor = point1_clip;
        frag_color = tovec4(get_color_start());
        thickness = get_linewidth_start();
    }else{
        anchor = point2_clip;
        frag_color = tovec4(get_color_end());
        thickness = get_linewidth_end();
    }
    frag_color.a = frag_color.a * min(1.0, thickness * 2.0);
    // I think GLMakie is drawing the lines too thick...
    // untill we figure out who is right, we need to add 1.0 to linewidth
    thickness = thickness > 0.0 ? thickness + 1.0 : 0.0;
    normal *= (((thickness) / 2.0) / get_resolution()) * anchor.w;
    // quadpos y (position.y) gives us the direction to expand the line
    vec4 offset = vec4(normal * position.y, 0.0, 0.0);
    // start, or end of quad, need to use current or next point as anchor
    gl_Position = anchor + offset;
    gl_Position.z += gl_Position.w * get_depth_shift();

}

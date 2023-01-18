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

flat out uint frag_instance_id;

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

    // apply offset
    point1_screen -= get_length_offset_start() * dir;
    point2_screen += get_length_offset_end() * dir;
    point1_clip = vec4(point1_screen / get_resolution(), point1_clip.z / point1_clip.w, 1.0);
    point2_clip = vec4(point2_screen / get_resolution(), point2_clip.z / point2_clip.w, 1.0);

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

    normal *= (thickness / get_resolution()) * anchor.w;
    // quadpos y (position.y) gives us the direction to expand the line
    vec4 offset = vec4(normal * position.y, 0.0, 0.0);
    // start, or end of quad, need to use current or next point as anchor
    gl_Position = anchor + offset;
    gl_Position.z += gl_Position.w * get_depth_shift();

    frag_instance_id = uint(gl_InstanceID);

}

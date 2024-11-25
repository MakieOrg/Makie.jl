precision highp float;
precision highp int;

uniform mat4 projection;
uniform mat4 view;
uniform vec3 eyeposition;
uniform int num_clip_planes;
uniform vec4 clip_planes[8];

out vec3 o_normal;
out vec4 frag_color;
out vec2 frag_uv;
out vec3 o_camdir;
out float o_clip_distance[8];

vec3 qmul(vec4 q, vec3 v){
    return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v);
}

void rotate(vec4 q, inout vec3 V, inout vec3 N){
    V = qmul(q, V);
    N = normalize(qmul(q, N));
}

vec4 to_vec4(vec3 v3){return vec4(v3, 1.0);}
vec4 to_vec4(vec4 v4){return v4;}

vec3 to_vec3(vec2 v3){return vec3(v3, 0.0);}
vec3 to_vec3(vec3 v4){return v4;}

void process_clip_planes(vec3 world_pos) {
    for (int i = 0; i < num_clip_planes; i++)
        o_clip_distance[i] = dot(world_pos, clip_planes[i].xyz) - clip_planes[i].w;
}

vec4 get_color_from_cmap(float value, sampler2D color_map, vec2 colorrange) {
    float cmin = colorrange.x;
    float cmax = colorrange.y;
    if (value <= cmax && value >= cmin) {
        // in value range, continue!
    } else if (value < cmin) {
        return get_lowclip();
    } else if (value > cmax) {
        return get_highclip();
    } else {
        // isnan is broken (of course) -.-
        // so if outside value range and not smaller/bigger min/max we assume NaN
        return get_nan_color();
    }
    float i01 = clamp((value - cmin) / (cmax - cmin), 0.0, 1.0);
    // 1/0 corresponds to the corner of the colormap, so to properly interpolate
    // between the colors, we need to scale it, so that the ends are at 1 - (stepsize/2) and 0+(stepsize/2).
    float stepsize = 1.0 / float(textureSize(color_map, 0));
    i01 = (1.0 - stepsize) * i01 + 0.5 * stepsize;
    return texture(color_map, vec2(i01, 0.0));
}

vec4 vertex_color(vec3 color, bool colorrange, bool colormap){
    return vec4(color, 1.0);
}
vec4 vertex_color(vec4 color, bool colorrange, bool colormap){
    return color;
}
vec4 vertex_color(bool color, bool colorrange, bool colormap){
    // color sampling happens in fragment shader
    return vec4(0.0, 0.0, 0.0, 0.0);
}
vec4 vertex_color(bool value, vec2 colorrange, sampler2D colormap){
    // color sampling happens in fragment shader
    return vec4(0.0, 0.0, 0.0, 0.0);
}
vec4 vertex_color(float value, vec2 colorrange, sampler2D colormap){
    if (get_interpolate_in_fragment_shader()) {
        return vec4(value, 0.0, 0.0, 0.0);
    } else {
        return get_color_from_cmap(value, colormap, colorrange);
    }
}

// TODO: enable
// vec2 apply_uv_transform(Nothing t1, vec2 uv){ return uv; }
vec2 apply_uv_transform(mat3 transform, vec2 uv){ return (transform * vec3(uv, 1)).xy; }
// TODO: per element

flat out uint frag_instance_id;

void main(){
    // get_* gets the global inputs (uniform, sampler, position array)
    // those functions will get inserted by the shader creation pipeline
    vec3 vertex_position = get_markersize() * to_vec3(get_position());
    vec3 N = get_normal() / get_markersize(); // see issue #3702
    rotate(get_rotation(), vertex_position, N);
    vertex_position = get_f32c_scale() * vertex_position;
    N = N / get_f32c_scale();
    vec4 position_world;
    if (get_transform_marker())
        position_world = model * vec4(to_vec3(get_offset()) + vertex_position, 1);
    else
        position_world = model * to_vec4(to_vec3(get_offset())) + vec4(vertex_position, 0);

    process_clip_planes(position_world.xyz);
    o_normal = normalize(N);
    frag_color = vertex_color(get_color(), get_colorrange(), colormap);
    frag_uv = apply_uv_transform(get_uv_transform(), get_uv());
    // direction to camera
    o_camdir = position_world.xyz / position_world.w - eyeposition;
    // screen space coordinates of the position
    gl_Position = projection * view * position_world;
    gl_Position.z += gl_Position.w * get_depth_shift();
    frag_instance_id = uint(gl_InstanceID);
}

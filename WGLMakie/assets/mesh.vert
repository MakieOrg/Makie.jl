precision highp float;
precision highp int;

out vec2 frag_uv;
out vec3 o_normal;
out vec3 o_camdir;

out vec4 frag_color;
out float o_clip_distance[8];

uniform mat4 projection;
uniform mat4 view;
uniform vec3 eyeposition;
uniform int uniform_num_clip_planes;
uniform vec4 uniform_clip_planes[8];

vec3 tovec3(vec2 v){return vec3(v, 0.0);}
vec3 tovec3(vec3 v){return v;}
vec4 tovec4(float v){return vec4(v, 0.0, 0.0, 0.0);}
vec4 tovec4(vec3 v){return vec4(v, 1.0);}
vec4 tovec4(vec4 v){return v;}

vec4 get_color_from_cmap(float value, sampler2D color_map, vec2 colorrange) {
    float cmin = colorrange.x;
    float cmax = colorrange.y;
    if (value <= cmax && value >= cmin) {
        // in value range, continue!
    } else if (value < cmin) {
        return get_lowclip_color();
    } else if (value > cmax) {
        return get_highclip_color();
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

vec4 get_color(vec3 color, bool colorrange, bool colormap){
    return vec4(color, 1.0);
}
vec4 get_color(vec4 color, bool colorrange, bool colormap){
    return color;
}
vec4 get_color(bool color, bool colorrange, bool colormap){
    // color sampling happens in fragment shader
    return vec4(0.0, 0.0, 0.0, 0.0);
}
vec4 get_color(bool value, vec2 colorrange, sampler2D colormap){
    // color sampling happens in fragment shader
    return vec4(0.0, 0.0, 0.0, 0.0);
}
vec4 get_color(float value, vec2 colorrange, sampler2D colormap){
    if (get_interpolate_in_fragment_shader()) {
        return vec4(value, 0.0, 0.0, 0.0);
    } else {
        return get_color_from_cmap(value, colormap, colorrange);
    }
}

void process_clip_planes(vec3 world_pos) {
    for (int i = 0; i < uniform_num_clip_planes; i++)
        o_clip_distance[i] = dot(world_pos, uniform_clip_planes[i].xyz) - uniform_clip_planes[i].w;
}

// TODO: enable
// vec2 apply_uv_transform(Nothing t1, vec2 uv){ return uv; }
vec2 apply_uv_transform(mat3 transform, vec2 uv){ return (transform * vec3(uv, 1)).xy; }

void render(vec4 position_world, vec3 normal, mat4 view, mat4 projection)
{
    // normal in world space
    o_normal = get_world_normalmatrix() * normal;
    // position in clip space (w/ depth)
    process_clip_planes(position_world.xyz);
    gl_Position = projection * view * position_world; // TODO consider using projectionview directly
    gl_Position.z += gl_Position.w * get_depth_shift();
    // direction to camera
    o_camdir = position_world.xyz / position_world.w - eyeposition;
}

flat out uint frag_instance_id;

void main(){
    // get_* gets the global inputs (uniform, sampler, position array)
    // those functions will get inserted by the shader creation pipeline
    vec3 vertex_position = tovec3(get_positions_transformed_f32c());
    if (isnan(vertex_position.z)) {
        vertex_position.z = 0.0;
    }
    vec4 position_world = model_f32c * vec4(vertex_position, 1);

    render(position_world, get_normals(), view, projection);
    frag_uv = apply_uv_transform(get_wgl_uv_transform(), get_texturecoordinates());
    frag_color = get_color(get_vertex_color(), get_uniform_colorrange(), uniform_colormap);

    frag_instance_id = uint(gl_VertexID);
}

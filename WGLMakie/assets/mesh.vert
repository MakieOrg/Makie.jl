out vec2 frag_uv;
out vec3 o_normal;
out vec3 o_camdir;
out vec3 o_lightdir;

out vec4 frag_color;

uniform mat4 projection;
uniform mat4 view;

vec3 tovec3(vec2 v){return vec3(v, 0.0);}
vec3 tovec3(vec3 v){return v;}

vec4 tovec4(float v){return vec4(v, 0.0, 0.0, 0.0);}
vec4 tovec4(vec3 v){return vec4(v, 1.0);}
vec4 tovec4(vec4 v){return v;}

float _normalize(float val, float from, float to){return (val-from) / (to - from);}

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

vec4 vertex_color(float value, vec2 colorrange, sampler2D colormap){
    if (get_interpolate_in_fragment_shader()) {
        return vec4(value, 0.0, 0.0, 0.0);
    } else {
        return get_color_from_cmap(value, colormap, colorrange);
    }
}

void render(vec4 position_world, vec3 normal, mat4 view, mat4 projection, vec3 lightposition)
{
    // normal in world space
    o_normal = get_normalmatrix() * normal;
    // position in view space (as seen from camera)
    vec4 view_pos = view * position_world;
    // position in clip space (w/ depth)
    gl_Position = projection * view_pos;
    gl_Position.z += gl_Position.w * get_depth_shift();
    // direction to light
    o_lightdir = normalize(view*vec4(lightposition, 1.0) - view_pos).xyz;
    // direction to camera
    // This is equivalent to
    // normalize(view*vec4(eyeposition, 1.0) - view_pos).xyz
    // (by definition `view * eyeposition = 0`)
    o_camdir = normalize(-view_pos).xyz;
}

void main(){
    // get_* gets the global inputs (uniform, sampler, position array)
    // those functions will get inserted by the shader creation pipeline
    vec3 vertex_position = tovec3(get_position());
    if (isnan(vertex_position.z)) {
        vertex_position.z = 0.0;
    }
    vec4 position_world = model * vec4(vertex_position, 1);

    render(position_world, get_normals(), view, projection, get_lightposition());
    frag_uv = get_uv();
    frag_uv = vec2(1.0 - frag_uv.y, frag_uv.x);
    frag_color = vertex_color(get_color(), get_colorrange(), colormap);
}

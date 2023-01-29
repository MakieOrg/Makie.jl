{{GLSL_VERSION}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};
struct Grid1D{
    int lendiv;
    float start;
    float stop;
    int dims;
};
struct Grid2D{
    ivec2 lendiv;
    vec2 start;
    vec2 stop;
    ivec2 dims;
};
struct Grid3D{
    ivec3 lendiv;
    vec3 start;
    vec3 stop;
    ivec3 dims;
};

vec2 grid_pos(Grid2D position, vec2 uv){
    return vec2(
        (1-uv[0]) * position.start[0] + uv[0] * position.stop[0],
        (1-uv[1]) * position.start[1] + uv[1] * position.stop[1]
    );
}

vec2 grid_pos(Grid2D position, ivec2 uv, ivec2 size){
    return vec2(
        (1.0 - (uv.x + 0.5) / size.x) * position.start[0] + (uv.x + 0.5) / size.x * position.stop[0],
        (1.0 - (uv.y + 0.5) / size.y) * position.start[1] + (uv.y + 0.5) / size.y * position.stop[1]
    );
}

// stretch is
vec3 stretch(vec3 val, vec3 from, vec3 to){
    return from + (val * (to - from));
}
vec2 stretch(vec2 val, vec2 from, vec2 to){
    return from + (val * (to - from));
}
float stretch(float val, float from, float to){
    return from + (val * (to - from));
}

float _normalize(float val, float from, float to){return (val-from) / (to - from);}
vec2 _normalize(vec2 val, vec2 from, vec2 to){
    return (val-from) / (to - from);
}
vec3 _normalize(vec3 val, vec3 from, vec3 to){
    return (val-from) / (to - from);
}

mat4 getmodelmatrix(vec3 xyz, vec3 scale){
   return mat4(
      vec4(scale.x, 0, 0, 0),
      vec4(0, scale.y, 0, 0),
      vec4(0, 0, scale.z, 0),
      vec4(xyz, 1));
}

mat4 rotationmatrix_z(float angle){
    return mat4(
        cos(angle), -sin(angle), 0, 0,
        sin(angle), cos(angle), 0,  0,
        0, 0, 1, 0,
        0, 0, 0, 1);
}
mat4 rotationmatrix_y(float angle){
    return mat4(
        cos(angle), 0, sin(angle), 0,
        0, 1, 0, 0,
        -sin(angle), 0, cos(angle), 0,
        0, 0, 0, 1);
}

vec3 qmul(vec4 quat, vec3 vec){
    float num = quat.x * 2.0;
    float num2 = quat.y * 2.0;
    float num3 = quat.z * 2.0;
    float num4 = quat.x * num;
    float num5 = quat.y * num2;
    float num6 = quat.z * num3;
    float num7 = quat.x * num2;
    float num8 = quat.x * num3;
    float num9 = quat.y * num3;
    float num10 = quat.w * num;
    float num11 = quat.w * num2;
    float num12 = quat.w * num3;
    return vec3(
        (1.0 - (num5 + num6)) * vec.x + (num7 - num12) * vec.y + (num8 + num11) * vec.z,
        (num7 + num12) * vec.x + (1.0 - (num4 + num6)) * vec.y + (num9 - num10) * vec.z,
        (num8 - num11) * vec.x + (num9 + num10) * vec.y + (1.0 - (num4 + num5)) * vec.z
    );
}


void rotate(Nothing r, int index, inout vec3 V, inout vec3 N){} // no-op
void rotate(vec4 q, int index, inout vec3 V, inout vec3 N){
    V = qmul(q, V);
    N = normalize(qmul(q, N));
}
void rotate(samplerBuffer vectors, int index, inout vec3 V, inout vec3 N){
    vec4 r = texelFetch(vectors, index);
    rotate(r, index, V, N);
}

mat4 translate_scale(vec3 xyz, vec3 scale){
   return mat4(
      vec4(scale.x, 0, 0, 0),
      vec4(0, scale.y, 0, 0),
      vec4(0, 0, scale.z, 0),
      vec4(xyz, 1));
}

//Mapping 1D index to 1D, 2D and 3D arrays
int ind2sub(int dim, int linearindex){return linearindex;}
ivec2 ind2sub(ivec2 dim, int linearindex){
    return ivec2(linearindex % dim.x, linearindex / dim.x);
}
ivec3 ind2sub(ivec3 dim, int i){
    int z = i / (dim.x*dim.y);
    i -= z * dim.x * dim.y;
    return ivec3(i % dim.x, i / dim.x, z);
}

float linear_index(int dims, int index){
    return float(index) / float(dims);
}
vec2 linear_index(ivec2 dims, int index){
    ivec2 index2D = ind2sub(dims, index);
    return vec2(index2D) / vec2(dims);
}
vec2 linear_index(ivec2 dims, int index, vec2 offset){
    vec2 index2D = vec2(ind2sub(dims, index))+offset;
    return index2D / vec2(dims);
}
vec3 linear_index(ivec3 dims, int index){
    ivec3 index3D = ind2sub(dims, index);
    return vec3(index3D) / vec3(dims);
}
vec4 linear_texture(sampler2D tex, int index){
    return texture(tex, linear_index(textureSize(tex, 0), index));
}

vec4 linear_texture(sampler2D tex, int index, vec2 offset){
    ivec2 dims = textureSize(tex, 0);
    return texture(tex, linear_index(dims, index) + (offset/vec2(dims)));
}

vec4 linear_texture(sampler3D tex, int index){
    return texture(tex, linear_index(textureSize(tex, 0), index));
}
uvec4 getindex(usampler2D tex, int index){
    return texelFetch(tex, ind2sub(textureSize(tex, 0), index), 0);
}
vec4 getindex(samplerBuffer tex, int index){
    return texelFetch(tex, index);
}
vec4 getindex(sampler1D tex, int index){
    return texelFetch(tex, index, 0);
}
vec4 getindex(sampler2D tex, int index){
    return texelFetch(tex, ind2sub(textureSize(tex, 0), index), 0);
}
vec4 getindex(sampler3D tex, int index){
    return texelFetch(tex, ind2sub(textureSize(tex, 0), index), 0);
}



vec3 _scale(vec2 scale, int index){
    return vec3(scale.x, scale.y, 1.0);
}

vec3 _scale(vec3  scale, int index){
    return scale;
}

vec3 _scale(samplerBuffer scale, int index){
    return getindex(scale, index).xyz;
}

vec4 color_lookup(float intensity, vec4 color, vec2 norm){
    return color;
}
vec4 color_lookup(float intensity, sampler1D color_ramp, vec2 norm){
    return texture(color_ramp, _normalize(intensity, norm.x, norm.y));
}

vec4 _color(vec3 color, Nothing intensity, Nothing color_map, Nothing color_norm, int index, int len){
    return vec4(color, 1);
}
vec4 _color(vec4 color, Nothing intensity, Nothing color_map, Nothing color_norm, int index, int len){return color;}
vec4 _color(samplerBuffer color, Nothing intensity, Nothing color_norm, int index){
    return texelFetch(color, index);
}
vec4 _color(samplerBuffer color, Nothing intensity, Nothing color_map, Nothing color_norm, int index, int len){
    return texelFetch(color, index);
}
vec4 _color(Nothing color, sampler1D intensity, sampler1D color_map, vec2 color_norm, int index, int len){
    return color_lookup(texture(intensity, float(index)/float(len-1)).x, color_map, color_norm);
}
vec4 _color(Nothing color, samplerBuffer intensity, sampler1D color_map, vec2 color_norm, int index, int len){
    return vec4(texelFetch(intensity, index).x, 0.0, 0.0, 0.0);
}
vec4 _color(Nothing color, float intensity, sampler1D color_map, vec2 color_norm, int index, int len){
    return color_lookup(intensity, color_map, color_norm);
}

out vec3 o_view_pos;
out vec3 o_normal;
out vec3 o_lightdir;
out vec3 o_camdir;
// transpose(inv(view * model))
// Transformation for vectors (rather than points)
uniform mat3 normalmatrix;
uniform vec3 lightposition;
uniform vec3 eyeposition;
uniform float depth_shift;


void render(vec4 position_world, vec3 normal, mat4 view, mat4 projection, vec3 lightposition)
{
    // normal in world space
    o_normal = normalmatrix * normal;
    // position in view space (as seen from camera)
    vec4 view_pos = view * position_world;
    // position in clip space (w/ depth)
    gl_Position = projection * view_pos;
    gl_Position.z += gl_Position.w * depth_shift;
    // direction to light
    o_lightdir = normalize(view*vec4(lightposition, 1.0) - view_pos).xyz;
    // direction to camera
    // This is equivalent to
    // normalize(view*vec4(eyeposition, 1.0) - view_pos).xyz
    // (by definition `view * eyeposition = 0`)
    o_camdir = normalize(-view_pos).xyz;
    o_view_pos = view_pos.xyz / view_pos.w;
}


uniform vec4 highclip;
uniform vec4 lowclip;
uniform vec4 nan_color;

vec4 get_color_from_cmap(float value, sampler1D color_map, vec2 colorrange) {
    float cmin = colorrange.x;
    float cmax = colorrange.y;
    if (value <= cmax && value >= cmin) {
        // in value range, continue!
    } else if (value < cmin) {
        return lowclip;
    } else if (value > cmax) {
        return highclip;
    } else {
        // isnan CAN be broken (of course) -.-
        // so if outside value range and not smaller/bigger min/max we assume NaN
        return nan_color;
    }
    float i01 = clamp((value - cmin) / (cmax - cmin), 0.0, 1.0);
    // 1/0 corresponds to the corner of the colormap, so to properly interpolate
    // between the colors, we need to scale it, so that the ends are at 1 - (stepsize/2) and 0+(stepsize/2).
    float stepsize = 1.0 / float(textureSize(color_map, 0));
    i01 = (1.0 - stepsize) * i01 + 0.5 * stepsize;
    return texture(color_map, i01);
}

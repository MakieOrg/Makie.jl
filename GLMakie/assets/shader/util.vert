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
    return color_lookup(texelFetch(intensity, index).x, color_map, color_norm);
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

//
vec3 getnormal_fast(sampler2D zvalues, ivec2 uv)
{
    vec3 a = vec3(0, 0, 0);
    vec3 b = vec3(1, 1, 0);
    a.z = texelFetch(zvalues, uv, 0).r;
    b.z = texelFetch(zvalues, uv + ivec2(1, 1), 0).r;
    return normalize(a - b);
}

bool isinbounds(vec2 uv)
{
    return (uv.x <= 1.0 && uv.y <= 1.0 && uv.x >= 0.0 && uv.y >= 0.0);
}


/*
Computes normal at s0 based on four surrounding positions s1 ... s4 and the
respective uv coordinates uv, off1, ..., off4

        s2
     s1 s0 s3
        s4
*/
vec3 normal_from_points(
        vec3 s0, vec3 s1, vec3 s2, vec3 s3, vec3 s4,
        vec2 uv, vec2 off1, vec2 off2, vec2 off3, vec2 off4
    ){
    vec3 result = vec3(0);
    if(isinbounds(off1) && isinbounds(off2))
    {
        result += cross(s2-s0, s1-s0);
    }
    if(isinbounds(off2) && isinbounds(off3))
    {
        result += cross(s3-s0, s2-s0);
    }
    if(isinbounds(off3) && isinbounds(off4))
    {
        result += cross(s4-s0, s3-s0);
    }
    if(isinbounds(off4) && isinbounds(off1))
    {
        result += cross(s1-s0, s4-s0);
    }
    // normal should be zero, but needs to be here, because the dead-code
    // elimanation of GLSL is overly enthusiastic
    return normalize(result);
}

// Overload for surface(Matrix, Matrix, Matrix)
vec3 getnormal(Nothing pos, sampler2D xs, sampler2D ys, sampler2D zs, vec2 uv){
    // The +1e-6 fixes precision errors at the edge
    float du = 1.0 / textureSize(zs,0).x + 1e-6;
    float dv = 1.0 / textureSize(zs,0).y + 1e-6;

    vec3 s0, s1, s2, s3, s4;
    vec2 off1 = uv + vec2(-du, 0);
    vec2 off2 = uv + vec2(0, dv);
    vec2 off3 = uv + vec2(du, 0);
    vec2 off4 = uv + vec2(0, -dv);

    s0 = vec3(texture(xs,   uv).x, texture(ys,   uv).x,   texture(zs, uv).x);
    s1 = vec3(texture(xs, off1).x, texture(ys, off1).x, texture(zs, off1).x);
    s2 = vec3(texture(xs, off2).x, texture(ys, off2).x, texture(zs, off2).x);
    s3 = vec3(texture(xs, off3).x, texture(ys, off3).x, texture(zs, off3).x);
    s4 = vec3(texture(xs, off4).x, texture(ys, off4).x, texture(zs, off4).x);

    return normal_from_points(s0, s1, s2, s3, s4, uv, off1, off2, off3, off4);
}


// Overload for (range, range, Matrix) surface plots
// Though this is only called by surface(Matrix)
vec3 getnormal(Grid2D pos, Nothing xs, Nothing ys, sampler2D zs, vec2 uv){
    // The +1e-6 fixes precision errors at the edge
    float du = 1.0 / textureSize(zs,0).x + 1e-6;
    float dv = 1.0 / textureSize(zs,0).y + 1e-6;

    vec3 s0, s1, s2, s3, s4;
    vec2 off1 = uv + vec2(-du, 0);
    vec2 off2 = uv + vec2(0, dv);
    vec2 off3 = uv + vec2(du, 0);
    vec2 off4 = uv + vec2(0, -dv);

    s0 = vec3(grid_pos(pos,   uv).xy, texture(zs,   uv).x);
    s1 = vec3(grid_pos(pos, off1).xy, texture(zs, off1).x);
    s2 = vec3(grid_pos(pos, off2).xy, texture(zs, off2).x);
    s3 = vec3(grid_pos(pos, off3).xy, texture(zs, off3).x);
    s4 = vec3(grid_pos(pos, off4).xy, texture(zs, off4).x);

    return normal_from_points(s0, s1, s2, s3, s4, uv, off1, off2, off3, off4);
}


// Overload for surface(Vector, Vector, Matrix)
// Makie converts almost everything to this
vec3 getnormal(Nothing pos, sampler1D xs, sampler1D ys, sampler2D zs, vec2 uv){
    // The +1e-6 fixes precision errors at the edge
    float du = 1.0 / textureSize(zs,0).x + 1e-6;
    float dv = 1.0 / textureSize(zs,0).y + 1e-6;

    vec3 s0, s1, s2, s3, s4;
    vec2 off1 = uv + vec2(-du, 0);
    vec2 off2 = uv + vec2(0, dv);
    vec2 off3 = uv + vec2(du, 0);
    vec2 off4 = uv + vec2(0, -dv);

    s0 = vec3(texture(xs,   uv.x).x, texture(ys,   uv.y).x, texture(zs,   uv).x);
    s1 = vec3(texture(xs, off1.x).x, texture(ys, off1.y).x, texture(zs, off1).x);
    s2 = vec3(texture(xs, off2.x).x, texture(ys, off2.y).x, texture(zs, off2).x);
    s3 = vec3(texture(xs, off3.x).x, texture(ys, off3.y).x, texture(zs, off3).x);
    s4 = vec3(texture(xs, off4.x).x, texture(ys, off4.y).x, texture(zs, off4).x);

    return normal_from_points(s0, s1, s2, s3, s4, uv, off1, off2, off3, off4);
}

{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

struct Grid2D{
    ivec2 lendiv;
    vec2 start;
    vec2 stop;
    ivec2 dims;
};

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
} nothing;

in vec2 vertices;

{{position_type}} position;
{{position_x_type}} position_x;
{{position_y_type}} position_y;
uniform sampler2D position_z;

{{image_type}} image;
{{color_map_type}} color_map;
{{color_norm_type}} color_norm;

uniform vec4 highclip;
uniform vec4 lowclip;
uniform vec4 nan_color;

vec4 color_lookup(float intensity, sampler1D color, vec2 norm);

uniform vec3 scale;
uniform mat4 view, model, projection;
uniform bool invert_normals;

uniform uint objectid;
flat out uvec2 o_id;
flat out int o_InstanceID; // dummy for compat with meshscatter in mesh.frag
out vec4 o_color;
out vec3 o_uv;

// See util.vert for implementations
void render(vec4 position_world, vec3 normal, mat4 view, mat4 projection);
ivec2 ind2sub(ivec2 dim, int linearindex);
vec2 grid_pos(Grid2D pos, vec2 uv);
vec2 linear_index(ivec2 dims, int index);
vec2 linear_index(ivec2 dims, int index, vec2 offset);
vec4 linear_texture(sampler2D tex, int index, vec2 offset);

{{uv_transform_type}} uv_transform;
vec3 apply_uv_transform(Nothing t1, vec2 uv){
    return vec3(uv, 0.0);
}
vec3 apply_uv_transform(Nothing t1, vec3 uv) {
    return uv;
}
vec3 apply_uv_transform(mat3x2 transform, vec3 uv){
    return uv;
}
vec3 apply_uv_transform(mat3x2 transform, vec2 uv) {
    return vec3(transform * vec3(uv, 1.0), 0.0);
}
// Normal generation

vec3 getnormal_fast(sampler2D zvalues, ivec2 uv)
{
    vec3 a = vec3(0, 0, 0);
    vec3 b = vec3(1, 1, 0);
    a.z = texelFetch(zvalues, uv, 0).r;
    b.z = texelFetch(zvalues, uv + ivec2(1, 1), 0).r;
    return normalize(a - b);
}

bool isinbounds(ivec2 uv, ivec2 size)
{
    return (uv.x < size.x && uv.y < size.y && uv.x >= 0 && uv.y >= 0);
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
        ivec2 off1, ivec2 off2, ivec2 off3, ivec2 off4, ivec2 size
    ){
    vec3 result = vec3(0,0,0);
    // isnan checks should avoid darkening around NaN positions but may not
    // work with all systems
    if (!isnan(s0.z)) {
        bool check1 = isinbounds(off1, size) && !isnan(s1.x) && !isnan(s1.y) && !isnan(s1.z);
        bool check2 = isinbounds(off2, size) && !isnan(s2.x) && !isnan(s2.y) && !isnan(s2.z);
        bool check3 = isinbounds(off3, size) && !isnan(s3.x) && !isnan(s3.y) && !isnan(s3.z);
        bool check4 = isinbounds(off4, size) && !isnan(s4.x) && !isnan(s4.y) && !isnan(s4.z);
        if (check1 && check2) result += cross(s2-s0, s1-s0);
        if (check2 && check3) result += cross(s3-s0, s2-s0);
        if (check3 && check4) result += cross(s4-s0, s3-s0);
        if (check4 && check1) result += cross(s1-s0, s4-s0);
    }
    // normal should be zero, but needs to be here, because the dead-code
    // elimination of GLSL is overly enthusiastic
    return (invert_normals ? -1.0 : 1.0) * normalize(result);
}

// Overload for surface(Matrix, Matrix, Matrix)
vec3 getnormal(Nothing pos, sampler2D xs, sampler2D ys, sampler2D zs, ivec2 uv){
    vec3 s0, s1, s2, s3, s4;
    ivec2 off1 = uv + ivec2(-1, 0);
    ivec2 off2 = uv + ivec2(0, 1);
    ivec2 off3 = uv + ivec2(1, 0);
    ivec2 off4 = uv + ivec2(0, -1);

    s0 = vec3(texelFetch(xs,   uv, 0).x, texelFetch(ys,   uv, 0).x, texelFetch(zs,   uv, 0).x);
    s1 = vec3(texelFetch(xs, off1, 0).x, texelFetch(ys, off1, 0).x, texelFetch(zs, off1, 0).x);
    s2 = vec3(texelFetch(xs, off2, 0).x, texelFetch(ys, off2, 0).x, texelFetch(zs, off2, 0).x);
    s3 = vec3(texelFetch(xs, off3, 0).x, texelFetch(ys, off3, 0).x, texelFetch(zs, off3, 0).x);
    s4 = vec3(texelFetch(xs, off4, 0).x, texelFetch(ys, off4, 0).x, texelFetch(zs, off4, 0).x);

    return normal_from_points(s0, s1, s2, s3, s4, off1, off2, off3, off4, textureSize(zs, 0));
}


// Overload for (range, range, Matrix) surface plots
// Though this is only called by surface(Matrix)
vec2 grid_pos(Grid2D position, ivec2 uv, ivec2 size);

vec3 getnormal(Grid2D pos, Nothing xs, Nothing ys, sampler2D zs, ivec2 uv){
    vec3 s0, s1, s2, s3, s4;
    ivec2 off1 = uv + ivec2(-1, 0);
    ivec2 off2 = uv + ivec2(0, 1);
    ivec2 off3 = uv + ivec2(1, 0);
    ivec2 off4 = uv + ivec2(0, -1);
    ivec2 size = textureSize(zs, 0);

    s0 = vec3(grid_pos(pos,   uv, size).xy, texelFetch(zs,   uv, 0).x);
    s1 = vec3(grid_pos(pos, off1, size).xy, texelFetch(zs, off1, 0).x);
    s2 = vec3(grid_pos(pos, off2, size).xy, texelFetch(zs, off2, 0).x);
    s3 = vec3(grid_pos(pos, off3, size).xy, texelFetch(zs, off3, 0).x);
    s4 = vec3(grid_pos(pos, off4, size).xy, texelFetch(zs, off4, 0).x);

    return normal_from_points(s0, s1, s2, s3, s4, off1, off2, off3, off4, size);
}


// Overload for surface(Vector, Vector, Matrix)
// Makie converts almost everything to this
vec3 getnormal(Nothing pos, sampler1D xs, sampler1D ys, sampler2D zs, ivec2 uv){
    vec3 s0, s1, s2, s3, s4;
    ivec2 off1 = uv + ivec2(-1, 0);
    ivec2 off2 = uv + ivec2(0, 1);
    ivec2 off3 = uv + ivec2(1, 0);
    ivec2 off4 = uv + ivec2(0, -1);

    s0 = vec3(texelFetch(xs,   uv.x, 0).x, texelFetch(ys,   uv.y, 0).x, texelFetch(zs,   uv, 0).x);
    s1 = vec3(texelFetch(xs, off1.x, 0).x, texelFetch(ys, off1.y, 0).x, texelFetch(zs, off1, 0).x);
    s2 = vec3(texelFetch(xs, off2.x, 0).x, texelFetch(ys, off2.y, 0).x, texelFetch(zs, off2, 0).x);
    s3 = vec3(texelFetch(xs, off3.x, 0).x, texelFetch(ys, off3.y, 0).x, texelFetch(zs, off3, 0).x);
    s4 = vec3(texelFetch(xs, off4.x, 0).x, texelFetch(ys, off4.y, 0).x, texelFetch(zs, off4, 0).x);

    return normal_from_points(s0, s1, s2, s3, s4, off1, off2, off3, off4, textureSize(zs, 0));
}

// See main() for more information
vec3 getposition(Nothing grid, sampler2D x, sampler2D y, sampler2D z, ivec2 idx, vec2 uv) {
    vec3 center = vec3(texture(x, uv).x, texture(y, uv).x, texture(z, uv).x);
    if (isnan(center.x) || isnan(center.y) || isnan(center.z)) {
        return vec3(0);
    } else {
        return vec3(texelFetch(x, idx, 0).x, texelFetch(y, idx, 0).x, texelFetch(z, idx, 0).x);
    }
}
vec3 getposition(Nothing grid, sampler1D x, sampler1D y, sampler2D z, ivec2 idx, vec2 uv) {
    vec3 center = vec3(texture(x, uv.x).x, texture(y, uv.y).x, texture(z, uv).x);
    if (isnan(center.x) || isnan(center.y) || isnan(center.z)) {
        return vec3(0);
    } else {
        return vec3(texelFetch(x, idx.x, 0).x, texelFetch(y, idx.y, 0).x, texelFetch(z, idx, 0).x);
    }
}
vec3 getposition(Grid2D grid, Nothing x, Nothing y, sampler2D z, ivec2 idx, vec2 uv) {
    float center = texture(z, uv).x;
    if (isnan(center)) {
        return vec3(0);
    } else {
        ivec2 size = textureSize(z, 0);
        return vec3(grid_pos(grid, idx, size), texelFetch(z, idx, 0).x);
    }
}



void main()
{
    // We have (N, M) = dims positions with (N-1, M-1) rects between them. Each
    // instance refers to one rect. Each rect has vertices (0..1, 0..1) so we
    // can do `base_idx + vertex` to index positions if base_idx refers to a
    // (N-1, M-1) matrix.
    int index = gl_InstanceID;
    ivec2 dims = textureSize(position_z, 0);
    ivec2 base_idx = ind2sub(dims - 1, index);
    ivec2 vertex_index = base_idx + ivec2(vertices);

    /*
    When using uv coordinates to access textures here, we need to be careful with
    how we calculate the uvs. 0, 1 refer to the far edges of the texture:

    0    1/N   2/N   3/N  ... N/N
    |_____|_____|_____|_      _|
    |     |     |     |        |
    |_____|_____|_____|_      _|
    |     |     |     |        |

    Our textures contain one pixel per vertex though, so that the pixel centers
    correspond to vertices. I.e. we want to access (0.5/N, 0.5/M) for the first
    vertex, corresponding to index (0, 0).
    */

    // Discard rects containing a nan value by making their size zero. For this
    // we get the value at the center of the rect, which mixes all 4 vertex
    // values via texture interpolation. (If nan is part of the interpolation
    // the result will also be nan.)
    vec2 center_uv = (base_idx + vec2(1)) / dims;
    vec3 pos = getposition(position, position_x, position_y, position_z, vertex_index, center_uv);
    vec3 normalvec = getnormal(position, position_x, position_y, position_z, vertex_index);

    // Colors should correspond to vertices, so they need the 0.5 shift discussed
    // above
    vec2 vertex_uv = vec2(vertex_index + 0.5) / vec2(dims);
    o_uv = apply_uv_transform(uv_transform, vec2(vertex_uv.x, 1 - vertex_uv.y));

    o_color = vec4(0.0);
    o_id = uvec2(objectid, 0); // calculated from uv in mesh.frag
    o_InstanceID = 0; // for meshscatter uv_transforms, irrelevant here

    render(model * vec4(pos, 1), normalvec, view, projection);
}

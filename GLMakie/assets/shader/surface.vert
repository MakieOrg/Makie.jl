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

uniform vec3 lightposition;

{{image_type}} image;
{{color_map_type}} color_map;
{{color_norm_type}} color_norm;

uniform vec4 highclip;
uniform vec4 lowclip;
uniform vec4 nan_color;

vec4 color_lookup(float intensity, sampler1D color, vec2 norm);

uniform vec3 scale;

uniform mat4 view, model, projection;

// See util.vert for implementations
void render(vec4 position_world, vec3 normal, mat4 view, mat4 projection, vec3 lightposition);
ivec2 ind2sub(ivec2 dim, int linearindex);
vec2 grid_pos(Grid2D pos, vec2 uv);
vec2 linear_index(ivec2 dims, int index);
vec2 linear_index(ivec2 dims, int index, vec2 offset);
vec4 linear_texture(sampler2D tex, int index, vec2 offset);


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
        bool check1 = isinbounds(off1, size) && !isnan(s1.z);
        bool check2 = isinbounds(off2, size) && !isnan(s2.z);
        bool check3 = isinbounds(off3, size) && !isnan(s3.z);
        bool check4 = isinbounds(off4, size) && !isnan(s4.z);
        if (check1 && check2) result += cross(s2-s0, s1-s0);
        if (check2 && check3) result += cross(s3-s0, s2-s0);
        if (check3 && check4) result += cross(s4-s0, s3-s0);
        if (check4 && check1) result += cross(s1-s0, s4-s0);
    }
    // normal should be zero, but needs to be here, because the dead-code
    // elimanation of GLSL is overly enthusiastic
    return normalize(result);
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

uniform uint objectid;
uniform vec2 uv_scale;
flat out uvec2 o_id;
out vec4 o_color;
out vec2 o_uv;

void main()
{
    int index = gl_InstanceID;
    vec2 offset = vertices;
    ivec2 offseti = ivec2(offset);
    ivec2 dims = textureSize(position_z, 0);
    vec3 pos;
    {{position_calc}}

    o_id = uvec2(objectid, index1D+1);
    o_uv = index01 * uv_scale;
    vec3 normalvec = {{normal_calc}};

    o_color = vec4(0.0);
    // we still want to render NaN values... TODO: make value customizable?
    if (isnan(pos.z)) {
        pos.z = 0.0;
    }

    render(model * vec4(pos, 1), normalvec, view, projection, lightposition);
}

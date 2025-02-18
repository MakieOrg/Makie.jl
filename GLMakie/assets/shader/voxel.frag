#version 330 core
// {{GLSL VERSION}}
// {{GLSL_EXTENSIONS}}

// debug FLAGS
// #define DEBUG_RENDER_ORDER 0 // (0, 1, 2) - dimensions
// #define DEBUG_UV
{{DEBUG_FLAG_DEFINE}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

// Sets which shading procedures to use
{{shading}}

flat in vec3 o_normal;
in vec3 o_uvw;
flat in int o_side;
in vec2 o_tex_uv;

#ifdef DEBUG_RENDER_ORDER
flat in float plane_render_idx; // debug
flat in int plane_dim;
flat in int plane_front;
#endif

uniform lowp usampler3D voxel_id;
uniform uint objectid;
uniform float gap;
uniform int _num_clip_planes;
uniform vec4 clip_planes[8];

{{uv_transform_type}} uv_transform;
{{color_map_type}} color_map;
{{color_type}} color;

vec4 debug_color(uint id) {
    return vec4(
        float((id & uint(225)) >> uint(5)) / 5.0,
        float((id & uint(25)) >> uint(3)) / 3.0,
        float((id & uint(7)) >> uint(1)) / 3.0,
        1.0
    );
}
vec4 debug_color(int id) { return debug_color(uint(id)); }

// unused but compilation requires it
mat3x2 get_uv_transform_mat(Nothing uv_transform, int id, int side) {
    return mat3x2(1,0,0,1,0,0);
}
mat3x2 get_uv_transform_mat(sampler2D uv_transform, int id, int side) {
    vec2 part1 = texelFetch(uv_transform, ivec2(0, id-1), 0).xy;
    vec2 part2 = texelFetch(uv_transform, ivec2(1, id-1), 0).xy;
    vec2 part3 = texelFetch(uv_transform, ivec2(2, id-1), 0).xy;
    return mat3x2(part1, part2, part3);
}
mat3x2 get_uv_transform_mat(sampler3D uv_transform, int id, int side) {
    vec2 part1 = texelFetch(uv_transform, ivec3(0, id-1, side), 0).xy;
    vec2 part2 = texelFetch(uv_transform, ivec3(1, id-1, side), 0).xy;
    vec2 part3 = texelFetch(uv_transform, ivec3(2, id-1, side), 0).xy;
    return mat3x2(part1, part2, part3);
}

vec4 get_color_from_texture(sampler2D color, int id) {
    mat3x2 uvt = get_uv_transform_mat(uv_transform, id, o_side);
    // compute uv normalized to voxel
    // TODO: float precision causes this to wrap sometimes (e.g. 5.999..7.0002)
    vec2 voxel_uv = mod(o_tex_uv, 1.0);
    // correct for shrinking due to gap
    voxel_uv = (voxel_uv - vec2(0.5 * gap)) / vec2(1.0 - gap);
    voxel_uv = uvt * vec3(voxel_uv, 1);
    return texture(color, voxel_uv);
}

vec4 get_color(Nothing color, Nothing color_map, int id) {
    return debug_color(id);
}
vec4 get_color(Nothing color, sampler1D color_map, int id) {
    return texelFetch(color_map, id-1, 0);
}
vec4 get_color(sampler1D color, sampler1D color_map, int id) {
    return texelFetch(color, id-1, 0);
}
vec4 get_color(sampler1D color, Nothing color_map, int id) {
    return texelFetch(color, id-1, 0);
}
vec4 get_color(sampler2D color, sampler1D color_map, int id) {
    return get_color_from_texture(color, id);
}
vec4 get_color(sampler2D color, Nothing color_map, int id) {
    return get_color_from_texture(color, id);
}

bool is_clipped()
{
    float d;
    // Center of voxel
    ivec3 size = ivec3(textureSize(voxel_id, 0).xyz);
    vec3 xyz = vec3(ivec3(o_uvw * size)) + vec3(0.5);
    for (int i = 0; i < _num_clip_planes; i++) {
        // distance between clip plane and center
        d = dot(xyz, clip_planes[i].xyz) - clip_planes[i].w;

        if (d < 0.0)
            return true;
    }

    return false;
}

void write2framebuffer(vec4 color, uvec2 id);

#ifndef NO_SHADING
vec3 illuminate(vec3 normal, vec3 base_color);
#endif

void main()
{
    if (is_clipped())
        discard;

    vec2 voxel_uv = mod(o_tex_uv, 1.0);
    if (voxel_uv.x < 0.5 * gap || voxel_uv.x > 1.0 - 0.5 * gap ||
        voxel_uv.y < 0.5 * gap || voxel_uv.y > 1.0 - 0.5 * gap)
        discard;

    // grab voxel id
    int id = int(texture(voxel_id, o_uvw).x);

    // id is invisible so we simply discard
    if (id == 0) {
        discard;
    }

    // otherwise we draw. For now just some color...
    vec4 voxel_color = get_color(color, color_map, id);

#ifdef DEBUG_UV
    voxel_color = vec4(voxel_uv, 0, 1);
#endif

#ifdef DEBUG_RENDER_ORDER
    if (plane_dim != DEBUG_RENDER_ORDER)
        discard;
    voxel_color = vec4(
        plane_front * plane_render_idx,
        -plane_front * plane_render_idx,
        0,
        id == 0 ? 0.1 : 1.0
    );
    // voxel_color = vec4(o_normal, id == 0 ? 0.1 : 1.0);
    // voxel_color = vec4(plane_front, 0, 0, 1.0);
#endif

#ifndef NO_SHADING
    voxel_color.rgb = illuminate(o_normal, voxel_color.rgb);
#endif

    // index into 3d array
    ivec3 size = ivec3(textureSize(voxel_id, 0).xyz);
    ivec3 idx = clamp(ivec3(o_uvw * size), ivec3(0), size-1);
    int lin = 1 + idx.x + size.x * (idx.y + size.y * idx.z);

    // draw
    write2framebuffer(voxel_color, uvec2(objectid, lin));
}
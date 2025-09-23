precision highp float;
precision highp int;

// debug FLAGS
// #define DEBUG_RENDER_ORDER 2 // (0, 1, 2) - dimensions

flat in vec3 o_normal;
in vec3 o_uvw;
flat in int o_side;
in vec2 o_tex_uv;
in float o_clip_distance[8];

in vec3 o_camdir;

#ifdef DEBUG_RENDER_ORDER
flat in float plane_render_idx; // debug
flat in int plane_dim;
flat in int plane_front;
#endif

uniform int uniform_num_clip_planes;
uniform vec4 uniform_clip_planes[8];
uniform vec3 light_color;
uniform vec3 ambient;
uniform vec3 light_direction;

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
mat3x2 get_uv_transform_mat(bool uv_transform, int id, int side) {
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
    mat3x2 uvt = get_uv_transform_mat(wgl_uv_transform, id, o_side);
    // compute uv normalized to voxel
    // TODO: float precision causes this to wrap sometimes (e.g. 5.999..7.0002)
    vec2 voxel_uv = mod(o_tex_uv, 1.0);
    // correct for shrinking due to gap
    voxel_uv = (voxel_uv - vec2(0.5 * gap)) / vec2(1.0 - gap);
    voxel_uv = uvt * vec3(voxel_uv, 1);
    return texture(color, voxel_uv);
}

vec4 get_color(bool color, bool color_map, bool uv_transform, int id) {
    return debug_color(id);
}
vec4 get_color(bool color, sampler2D color_map, bool uv_transform, int id) {
    return texelFetch(color_map, ivec2(id-1, 0), 0);
}
vec4 get_color(sampler2D color, sampler2D color_map, bool uv_transform, int id) {
    return texelFetch(color, ivec2(id-1, 0), 0);
}
vec4 get_color(sampler2D color, bool color_map, bool uv_transform, int id) {
    return texelFetch(color, ivec2(id-1, 0), 0);
}
vec4 get_color(sampler2D color, sampler2D color_map, sampler2D uv_transform, int id) {
    return get_color_from_texture(color, id);
}
vec4 get_color(sampler2D color, bool color_map, sampler2D uv_transform, int id) {
    return get_color_from_texture(color, id);
}
vec4 get_color(sampler2D color, sampler2D color_map, sampler3D uv_transform, int id) {
    return get_color_from_texture(color, id);
}
vec4 get_color(sampler2D color, bool color_map, sampler3D uv_transform, int id) {
    return get_color_from_texture(color, id);
}

// Smoothes out edge around 0 light intensity, see GLMakie
float smooth_zero_max(float x) {
    const float c = 0.00390625, xswap = 0.6406707120152759, yswap = 0.20508383900190955;
    const float shift = 1.0 + xswap - yswap;
    float pow8 = x + shift;
    pow8 = pow8 * pow8; pow8 = pow8 * pow8; pow8 = pow8 * pow8;
    return x < yswap ? c * pow8 : x;
}

vec3 blinnphong(vec3 N, vec3 V, vec3 L, vec3 color){
    float diff_coeff = smooth_zero_max(dot(L, -N));

    // specular coefficient
    vec3 H = normalize(L + V);

    float spec_coeff = pow(max(dot(H, -N), 0.0), get_shininess());
    if (diff_coeff <= 0.0)
        spec_coeff = 0.0;

    // final lighting model
    return light_color * vec3(
        get_diffuse() * diff_coeff * color +
        get_specular() * spec_coeff
    );
}

bool is_clipped()
{
    float d;
    // get center pos of this voxel
    vec3 size = vec3(textureSize(chunk_u8, 0).xyz);
    vec3 xyz = vec3(ivec3(o_uvw * size)) + vec3(0.5);
    for (int i = 0; i < uniform_num_clip_planes; i++) {
        // distance between clip plane and voxel center
        d = dot(xyz, uniform_clip_planes[i].xyz) - uniform_clip_planes[i].w;
        if (d < 0.0)
            return true;
    }

    return false;
}

flat in uint frag_instance_id;

vec2 encode_uint_to_float(uint value) {
    float lower = float(value & 0xFFFFu) / 65535.0;
    float upper = float(value >> 16u) / 65535.0;
    return vec2(lower, upper);
}

vec4 pack_int(uint id, uint index) {
    vec4 unpack;
    unpack.rg = encode_uint_to_float(id);
    unpack.ba = encode_uint_to_float(index);
    return unpack;
}

void main()
{
    if (is_clipped())
        discard;

    vec2 voxel_uv = mod(o_tex_uv, 1.0);
    if (voxel_uv.x < 0.5 * gap || voxel_uv.x > 1.0 - 0.5 * gap ||
        voxel_uv.y < 0.5 * gap || voxel_uv.y > 1.0 - 0.5 * gap)
        discard;

    // grab voxel id
    int id = int(texture(chunk_u8, o_uvw).x);

    // id is invisible so we simply discard
    if (id == 0) {
        discard;
    }

    // otherwise we draw. For now just some color...
    vec4 voxel_color = get_color(wgl_color, wgl_colormap, wgl_uv_transform, id);

#ifdef DEBUG_RENDER_ORDER
    if (plane_dim != DEBUG_RENDER_ORDER)
        discard;
    voxel_color = vec4(plane_render_idx, 0, 0, id == 0 ? 0.01 : 1.0);
#endif

    if(get_shading()){
        vec3 L = light_direction;
        vec3 light = blinnphong(o_normal, normalize(o_camdir), L, voxel_color.rgb);
        voxel_color.rgb = ambient * voxel_color.rgb + light;
    }

    if (picking) {
        uvec3 size = uvec3(textureSize(chunk_u8, 0).xyz);
        uvec3 idx = clamp(uvec3(o_uvw * vec3(size)), uvec3(0), size - uvec3(1));
        uint lin = idx.x + size.x * (idx.y + size.y * idx.z);
        fragment_color = pack_int(object_id, lin);
        return;
    }

    fragment_color = voxel_color;
}

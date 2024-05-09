// debug FLAGS
// #define DEBUG_RENDER_ORDER 2 // (0, 1, 2) - dimensions

flat in vec3 o_normal;
in vec3 o_uvw;
flat in int o_side;
in vec2 o_tex_uv;

in vec3 o_camdir;

#ifdef DEBUG_RENDER_ORDER
flat in float plane_render_idx; // debug
flat in int plane_dim;
flat in int plane_front;
#endif

vec4 debug_color(uint id) {
    return vec4(
        float((id & uint(225)) >> uint(5)) / 5.0,
        float((id & uint(25)) >> uint(3)) / 3.0,
        float((id & uint(7)) >> uint(1)) / 3.0,
        1.0
    );
}
vec4 debug_color(int id) { return debug_color(uint(id)); }

vec4 get_color(bool color, bool color_map, bool uv_map, int id) {
    return debug_color(id);
}
vec4 get_color(bool color, sampler2D color_map, bool uv_map, int id) {
    return texelFetch(color_map, ivec2(id-1, 0), 0);
}
vec4 get_color(sampler2D color, sampler2D color_map, bool uv_map, int id) {
    return texelFetch(color, ivec2(id-1, 0), 0);
}
vec4 get_color(sampler2D color, bool color_map, bool uv_map, int id) {
    return texelFetch(color, ivec2(id-1, 0), 0);
}
vec4 get_color(sampler2D color, sampler2D color_map, sampler2D uv_map, int id) {
    vec4 lrbt = texelFetch(uv_map, ivec2(id-1, o_side), 0);
    // compute uv normalized to voxel
    // TODO: float precision causes this to wrap sometimes (e.g. 5.999..7.0002)
    vec2 voxel_uv = mod(o_tex_uv, 1.0);
    voxel_uv = mix(lrbt.xz, lrbt.yw, voxel_uv);
    return texture(color, voxel_uv);
}
vec4 get_color(sampler2D color, bool color_map, sampler2D uv_map, int id) {
    vec4 lrbt = texelFetch(uv_map, ivec2(id-1, o_side), 0);
    // compute uv normalized to voxel
    // TODO: float precision causes this to wrap sometimes (e.g. 5.999..7.0002)
    vec2 voxel_uv = mod(o_tex_uv, 1.0);
    voxel_uv = mix(lrbt.xz, lrbt.yw, voxel_uv);
    return texture(color, voxel_uv);
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
    return get_light_color() * vec3(
        get_diffuse() * diff_coeff * color +
        get_specular() * spec_coeff
    );
}

flat in uint frag_instance_id;
vec4 pack_int(uint id, uint index) {
    vec4 unpack;
    unpack.x = float((id & uint(0xff00)) >> 8) / 255.0;
    unpack.y = float((id & uint(0x00ff)) >> 0) / 255.0;
    unpack.z = float((index & uint(0xff00)) >> 8) / 255.0;
    unpack.w = float((index & uint(0x00ff)) >> 0) / 255.0;
    return unpack;
}
void main()
{
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
    vec4 voxel_color = get_color(color, color_map, uv_map, id);

#ifdef DEBUG_RENDER_ORDER
    if (plane_dim != DEBUG_RENDER_ORDER)
        discard;
    voxel_color = vec4(plane_render_idx, 0, 0, id == 0 ? 0.01 : 1.0);
#endif

    if(get_shading()){
        vec3 L = get_light_direction();
        vec3 light = blinnphong(o_normal, normalize(o_camdir), L, voxel_color.rgb);
        voxel_color.rgb = get_ambient() * voxel_color.rgb + light;
    }

    if (picking) {
        uvec3 size = uvec3(textureSize(voxel_id, 0).xyz);
        uvec3 idx = uvec3(o_uvw * vec3(size));
        uint lin = idx.x + size.x * (idx.y + size.y * idx.z);
        fragment_color = pack_int(object_id, lin);
        return;
    }

    fragment_color = voxel_color;
}
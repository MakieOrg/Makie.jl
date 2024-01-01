#version 330 core
// {{GLSL VERSION}}
// {{GLSL_EXTENSIONS}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

// Sets which shading procedures to use
{{shading}}

in vec3 o_normal;
in vec3 o_uvw;

uniform isampler3D voxel_id;
uniform uint objectid;

// TODO: uv_map and texturemap
{{color_map_type}} color_map;
{{color_type}} color;

vec3 debug_color(uint id) {
    return vec3(
        float((id & uint(225)) >> uint(5)) / 5.0,
        float((id & uint(25)) >> uint(3)) / 3.0,
        float((id & uint(7)) >> uint(1)) / 3.0
    );
}
vec3 debug_color(int id) { return debug_color(uint(id)); }

vec3 get_color(Nothing color, Nothing color_map, int id) {
    return debug_color(id);
}
vec3 get_color(Nothing color, sampler1D color_map, int id) {
    return texelFetch(color_map, id-1, 0).xyz;
}
vec3 get_color(sampler1D color, sampler1D color_map, int id) {
    return texelFetch(color, id-1, 0).xyz;
}
vec3 get_color(sampler1D color, Nothing color_map, int id) {
    return texelFetch(color, id-1, 0).xyz;
}

void write2framebuffer(vec4 color, uvec2 id);

#ifndef NO_SHADING
vec3 illuminate(vec3 normal, vec3 base_color);
#endif

void main()
{
    // grab voxel id
    int id = int(texture(voxel_id, o_uvw).x);

    // id is invisible so we simply discard
    if (id == 0) {
        discard;
    }

    // otherwise we draw. For now just some color...
    vec3 voxel_color = get_color(color, color_map, id);

    #ifndef NO_SHADING
    voxel_color = illuminate(o_normal, voxel_color);
    #endif

    // TODO: index into 3d array
    ivec3 size = ivec3(textureSize(voxel_id, 0).xyz);
    ivec3 idx = ivec3(o_uvw * size);
    int lin = 1 + idx.x + size.x * (idx.y + size.y * idx.z);

    // draw
    write2framebuffer(vec4(voxel_color, 1.0), uvec2(objectid, lin));
}
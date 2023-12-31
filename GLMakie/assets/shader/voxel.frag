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

void write2framebuffer(vec4 color, uvec2 id);

#ifndef NO_SHADING
vec3 illuminate(vec3 normal, vec3 base_color);
#endif

void main()
{
    // grab voxel id
    uint id = uint(texture(voxel_id, o_uvw).x);

    // id is invisible so we simply discard
    if (id == uint(0)) {
        discard;
    }

    // otherwise we draw. For now just some color...
    vec3 color = vec3(
        float((id & uint(225)) >> uint(5)) / 5.0,
        float((id & uint(25)) >> uint(3)) / 3.0,
        float((id & uint(7)) >> uint(1)) / 3.0
    );

    #ifndef NO_SHADING
    color = illuminate(o_normal, color);
    #endif

    // TODO: index into 3d array
    uvec3 size = uvec3(textureSize(voxel_id, 0).xyz);
    uvec3 idx = uvec3(o_uvw * size);
    uint lin = uint(1) + idx.x + size.x * (idx.y + size.y * idx.z);

    // draw
    write2framebuffer(vec4(color, 1.0), uvec2(objectid, lin));
}
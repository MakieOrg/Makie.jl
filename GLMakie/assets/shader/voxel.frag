#version 330 core
// {{GLSL VERSION}}
// {{GLSL_EXTENSIONS}}

in vec3 f_normal;
in vec3 f_uvw;

uniform isampler3D voxel_id;
uniform uint objectid;

void write2framebuffer(vec4 color, uvec2 id);

void main()
{
    // grab voxel id
    uint id = uint(texture(voxel_id, f_uvw).x);

    // id is invisible so we simply discard
    if (id == uint(0)) {
        discard;
    }

    // otherwise we draw. For now just some color...
    vec4 color = vec4(
        float((id & uint(225)) >> uint(5)) / 5.0,
        float((id & uint(25)) >> uint(3)) / 3.0,
        float((id & uint(7)) >> uint(1)) / 3.0,
        1.0
    );

    // TODO: index into 3d array
    uvec3 size = uvec3(textureSize(voxel_id, 0).xyz);
    uvec3 idx = uvec3(f_uvw * size);
    uint lin = uint(1) + idx.x + size.x * (idx.y + size.y * idx.z);

    // draw
    write2framebuffer(color, uvec2(objectid, lin));
}
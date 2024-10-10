{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

uniform sampler1D position_x;
uniform sampler1D position_y;
in vec2 vertices;

uniform mat4 projection, view, model;
uniform uint objectid;
uniform float depth_shift;

out vec2 o_uv;
flat out uvec2 o_objectid;

out vec3 o_view_pos;
out vec3 o_view_normal;

ivec2 ind2sub(ivec2 dim, int linearindex){
    return ivec2(linearindex % dim.x, linearindex / dim.x);
}

uniform int num_clip_planes;
uniform vec4 clip_planes[8];
out float gl_ClipDistance[8];

void process_clip_planes(vec3 world_pos)
{
    // distance = dot(world_pos - plane.point, plane.normal)
    // precalculated: dot(plane.point, plane.normal) -> plane.w
    for (int i = 0; i < num_clip_planes; i++)
        gl_ClipDistance[i] = dot(world_pos, clip_planes[i].xyz) - clip_planes[i].w;

    // TODO: can be skipped?
    for (int i = num_clip_planes; i < 8; i++)
        gl_ClipDistance[i] = 1.0;
}

void main(){
    //Outputs for ssao, which we don't use for 2d shaders like heatmap/image
    o_view_pos = vec3(0);
    o_view_normal = vec3(0);

    int index = gl_InstanceID;
    vec2 offset = vertices;
    ivec2 offseti = ivec2(offset);
    ivec2 dims = ivec2(textureSize(position_x, 0), textureSize(position_y, 0));
    int index1D = index + offseti.x + offseti.y * dims.x + (index/(dims.x-1));
    ivec2 index2D = ind2sub(dims, index1D);
    vec2 index01 = vec2(index2D) / (vec2(dims)-1.0);

    o_uv = vec2(index01.x, 1.0 - index01.y);
    o_objectid = uvec2(objectid, 1 + index);

    float x = texelFetch(position_x, index2D.x, 0).x;
    float y = texelFetch(position_y, index2D.y, 0).x;

    vec4 world_pos = model * vec4(x, y, 0, 1);
    process_clip_planes(world_pos.xyz);
    gl_Position = projection * view * world_pos;
    gl_Position.z += gl_Position.w * depth_shift;
}

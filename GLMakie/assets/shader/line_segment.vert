{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

in float lastlen;
{{vertex_type}} vertex;
{{thickness_type}} thickness;
{{color_type}} color;

uniform mat4 projectionview, model;
uniform uint objectid;
uniform float depth_shift;
uniform float px_per_unit;

out uvec2 g_id;
out {{stripped_color_type}} g_color;
out float g_thickness;

vec4 to_vec4(vec3 v){return vec4(v, 1);}
vec4 to_vec4(vec2 v){return vec4(v, 0, 1);}

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


void main()
{
    g_id = uvec2(objectid, gl_VertexID + 1);
    g_color = color;
    g_thickness = px_per_unit * thickness;
    vec4 world_pos = model * to_vec4(vertex);
    process_clip_planes(world_pos.xyz);
    gl_Position = projectionview * world_pos;
    gl_Position.z += gl_Position.w * depth_shift;
}

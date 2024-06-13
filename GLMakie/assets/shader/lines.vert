{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

{{define_fast_path}}

{{vertex_type}} vertex;

in float lastlen;
{{valid_vertex_type}} valid_vertex;
{{thickness_type}}  thickness;
{{color_type}}      color;

uniform mat4 projectionview, model;
uniform uint objectid;
uniform int total_length;
uniform float px_per_unit;

out uvec2 g_id;
out {{stripped_color_type}} g_color;
out float g_lastlen;
out int g_valid_vertex;
out float g_thickness;

vec4 to_vec4(vec4 v){return v;}
vec4 to_vec4(vec3 v){return vec4(v, 1);}
vec4 to_vec4(vec2 v){return vec4(v, 0, 1);}

int get_valid_vertex(float se){return int(se);}
int get_valid_vertex(Nothing se){return 1;}

uniform float depth_shift;

uniform int num_clip_planes;
uniform vec4 clip_planes[8];
out float g_clip_distance[8];

void process_clip_planes(vec3 world_pos)
{
    // distance = dot(world_pos - plane.point, plane.normal)
    // precalculated: dot(plane.point, plane.normal) -> plane.w
    for (int i = 0; i < num_clip_planes; i++)
        g_clip_distance[i] = dot(world_pos, clip_planes[i].xyz) - clip_planes[i].w;

    // TODO: can be skipped?
    for (int i = num_clip_planes; i < 8; i++)
        g_clip_distance[i] = 1.0;
}

void main()
{
    g_lastlen = lastlen;
    int index = gl_VertexID;
    g_id = uvec2(objectid, index+1);
    g_valid_vertex = get_valid_vertex(valid_vertex);
    g_thickness = px_per_unit * thickness;

    g_color = color;
    vec4 world_pos = model * to_vec4(vertex);
    process_clip_planes(world_pos.xyz);
    #ifdef FAST_PATH
        gl_Position = projectionview * world_pos;
    #else
        gl_Position = to_vec4(vertex);
    #endif
    gl_Position.z += gl_Position.w * depth_shift;
}

{{GLSL_VERSION}}

in vec3 vertices;

out vec3 frag_vert;
out vec3 o_light_dir;

uniform mat4 projectionview, model;
uniform vec3 lightposition;
uniform mat4 modelinv;
uniform float depth_shift;

out vec3 o_view_pos;
out vec3 o_normal;


struct Nothing{
    bool _;
};

struct WorldAxisLimits{
    vec3 min, max;
};

{{clip_planes_type}} clip_planes;

void set_clip(Nothing planes, vec4 world_pos){ return; }
void set_clip(WorldAxisLimits planes, vec4 world_pos)
{
    // inside positive, outside negative?
    vec3 min_dist = world_pos.xyz - planes.min;
    vec3 max_dist = planes.max - world_pos.xyz;
    gl_ClipDistance[0] = min_dist[0];
    gl_ClipDistance[1] = max_dist[0];
    gl_ClipDistance[2] = min_dist[1];
    gl_ClipDistance[3] = max_dist[1];
    gl_ClipDistance[4] = min_dist[2];
    gl_ClipDistance[5] = max_dist[2];
}

void main()
{
    // TODO set these in volume.frag
    o_view_pos = vec3(0);
    o_normal = vec3(0);
    vec4 world_vert = model * vec4(vertices, 1);
    frag_vert = world_vert.xyz;
    o_light_dir = vec3(modelinv * vec4(lightposition, 1));
    gl_Position = projectionview * world_vert;
    gl_Position.z += gl_Position.w * depth_shift;
    set_clip(clip_planes, world_vert);
}

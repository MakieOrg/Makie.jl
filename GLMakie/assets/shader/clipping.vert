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
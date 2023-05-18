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
out vec3 o_normal;

ivec2 ind2sub(ivec2 dim, int linearindex){
    return ivec2(linearindex % dim.x, linearindex / dim.x);
}


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

void main(){
    //Outputs for ssao, which we don't use for 2d shaders like heatmap/image
    o_view_pos = vec3(0);
    o_normal = vec3(0);

    int index = gl_InstanceID;
    vec2 offset = vertices;
    ivec2 offseti = ivec2(offset);
    ivec2 dims = ivec2(textureSize(position_x, 0), textureSize(position_y, 0));
    int index1D = index + offseti.x + offseti.y * dims.x + (index/(dims.x-1));
    ivec2 index2D = ind2sub(dims, index1D);
    vec2 index01 = vec2(index2D) / (vec2(dims)-1.0);

    o_uv = vec2(index01.x, 1.0 - index01.y);
    o_objectid = uvec2(objectid, index1D+1);

    float x = texelFetch(position_x, index2D.x, 0).x;
    float y = texelFetch(position_y, index2D.y, 0).x;

    vec4 world_pos = model * vec4(x, y, 0, 1);
    set_clip(clip_planes, world_pos);
    
    gl_Position = projection * view * world_pos;
    gl_Position.z += gl_Position.w * depth_shift;
}

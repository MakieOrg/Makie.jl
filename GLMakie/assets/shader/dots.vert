{{GLSL_VERSION}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

{{vertex_type}}     vertex;
{{color_type}}      color;
{{color_norm_type}} color_norm;
{{color_map_type}}  color_map;
uniform uint objectid;
uniform float depth_shift;

flat out vec4 o_color;
flat out uvec2 o_objectid;


float _normalize(float val, float from, float to){return (val-from) / (to - from);}

vec4 color_lookup(float intensity, sampler1D color_ramp, vec2 norm){
    return texture(color_ramp, _normalize(intensity, norm.x, norm.y));
}
void colorize(Nothing intensity, vec3 color, Nothing color_norm){
    o_color = vec4(color, 1);
}
void colorize(Nothing intensity, vec4 color, Nothing color_norm){
    o_color = color;
}
void colorize(sampler1D color, float intensity, vec2 color_norm){
    o_color = color_lookup(intensity, color, color_norm);
}
vec4 _position(vec3 p){return vec4(p,1);}
vec4 _position(vec2 p){return vec4(p,0,1);}

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

uniform mat4 projectionview, model;

void main(){
	colorize(color_map, color, color_norm);
    o_objectid  = uvec2(objectid, gl_VertexID+1);
    vec4 world_pos = model * _position(vertex);
	gl_Position = projectionview * world_pos;
    gl_Position.z += gl_Position.w * depth_shift;
    set_clip(clip_panes, world_pos);
}

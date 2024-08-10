{{GLSL_VERSION}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

{{vertex_type}}     vertex;
{{color_type}}      color;
{{color_norm_type}} color_norm;
{{color_map_type}}  color_map;
{{scale_type}}      scale;

uniform vec2 resolution;
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

uniform mat4 projection, projectionview, view, model;
uniform int markerspace;
uniform float px_per_unit;
uniform vec3 upvector;

void main(){
    vec4 world_position = model * _position(vertex);
    process_clip_planes(world_position.xyz);
    vec4 clip_pos = projectionview * world_position;
    gl_Position = vec4(clip_pos.xy, clip_pos.z + (clip_pos.w * depth_shift), clip_pos.w);
    if (markerspace == 0) {
        // pixelspace
        gl_PointSize = px_per_unit * scale.x;
    } else {
        // dataspace with 3D camera
        // to have a billboard, we project the upvector
        vec3 scale_vec = upvector * scale.x;
        vec4 up_clip = projectionview * vec4(world_position.xyz + scale_vec, 1);
        float yup = abs(up_clip.y - clip_pos.y) / clip_pos.w;
        gl_PointSize = ceil(0.5 * yup *  resolution.y);
    }

    colorize(color_map, color, color_norm);
    o_objectid  = uvec2(objectid, gl_VertexID+1);
}

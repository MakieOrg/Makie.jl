{{GLSL_VERSION}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

{{vertex_type}}     vertex;
{{color_type}}      color;
{{color_norm_type}} color_norm;
{{color_map_type}}  color_map;
{{scale_type}}      scale;
{{marker_offset_type}} marker_offset;

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

uniform mat4 preprojection, projectionview, model;
uniform int markerspace;
uniform float px_per_unit;
uniform vec3 upvector;
uniform vec3 f32c_scale;

#define PIXEL_SPACE 0
#define WORLD_SPACE 1

void main(){
    vec4 world_position = model * _position(vertex);
    process_clip_planes(world_position.xyz);
    // TODO: maybe do this on CPU side? Or when generating camera matrices?
    // Would be incompatible with CairoMakie though
    mat4 full_projectionview = projectionview * preprojection;

    vec4 clip_pos = full_projectionview * world_position;
    if (markerspace == PIXEL_SPACE) {
        clip_pos += vec4(2.0 * marker_offset / vec3(resolution, 1), 0);
        gl_PointSize = px_per_unit * scale.x;
    } else {
        // To get a billboard-like marker we want to know how many pixels the
        // marker spans in screen space. We project a second point offset by
        // the marker scale along the camera up-vector, then take the screen-
        // space distance between the two NDC y coordinates.
        vec3 scale_vec = upvector * f32c_scale.y * scale.x;
        vec4 up_clip = full_projectionview * vec4(world_position.xyz + scale_vec, 1);
        // Each clip-space point must be divided by its own w before the
        // subtraction (perspective divide) - otherwise points near the
        // camera plane (clip_pos.w -> 0) or behind it (clip_pos.w < 0) blow
        // gl_PointSize up to +/-Inf and on some drivers (AMD) the resulting
        // command stream triggers a hard context loss.
        float w0 = clip_pos.w;
        float w1 = up_clip.w;
        if (w0 < 1e-6 || w1 < 1e-6) {
            // Point is at or behind the near plane; emit a zero-sized point
            // so it doesn't render but also doesn't feed a bad value to the
            // rasterizer.
            gl_PointSize = 0.0;
        } else {
            float yup = abs(up_clip.y / w1 - clip_pos.y / w0);
            // gl_PointSize is clamped by the driver to GL_POINT_SIZE_RANGE,
            // but NaN/+Inf may still survive on some implementations; clamp
            // explicitly to a generous-but-finite upper bound.
            gl_PointSize = clamp(ceil(0.5 * yup * px_per_unit * resolution.y), 0.0, 1024.0);
        }
        clip_pos += full_projectionview * vec4(f32c_scale * marker_offset, 0);
    }
    gl_Position = vec4(clip_pos.xy, clip_pos.z + (clip_pos.w * depth_shift), clip_pos.w);

    colorize(color_map, color, color_norm);
    o_objectid  = uvec2(objectid, gl_VertexID+1);
}

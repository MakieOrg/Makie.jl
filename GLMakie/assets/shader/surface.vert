{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

struct Grid2D{
    ivec2 lendiv;
    vec2 start;
    vec2 stop;
    ivec2 dims;
};

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
} nothing;

in vec2 vertices;

{{position_type}} position;
{{position_x_type}} position_x;
{{position_y_type}} position_y;
uniform sampler2D position_z;

uniform vec3 lightposition;

{{image_type}} image;
{{color_map_type}} color_map;
{{color_norm_type}} color_norm;

uniform vec4 highclip;
uniform vec4 lowclip;
uniform vec4 nan_color;

vec4 color_lookup(float intensity, sampler1D color, vec2 norm);

uniform vec3 scale;

uniform mat4 view, model, projection;

// See util.vert for implementations
void render(vec4 position_world, vec3 normal, mat4 view, mat4 projection, vec3 lightposition);
ivec2 ind2sub(ivec2 dim, int linearindex);
vec2 grid_pos(Grid2D pos, vec2 uv);
vec2 linear_index(ivec2 dims, int index);
vec2 linear_index(ivec2 dims, int index, vec2 offset);
vec4 linear_texture(sampler2D tex, int index, vec2 offset);
// vec3 getnormal_fast(sampler2D zvalues, ivec2 uv);
vec3 getnormal(Grid2D pos, Nothing xs, Nothing ys, sampler2D zs, vec2 uv);
vec3 getnormal(Nothing pos, sampler2D xs, sampler2D ys, sampler2D zs, vec2 uv);
vec3 getnormal(Nothing pos, sampler1D xs, sampler1D ys, sampler2D zs, vec2 uv);

vec3 getnormal(Grid2D pos,  Nothing xs,   Nothing ys,   sampler2D zs, ivec2 uv);
vec3 getnormal(Nothing pos, sampler2D xs, sampler2D ys, sampler2D zs, ivec2 uv);
vec3 getnormal(Nothing pos, sampler1D xs, sampler1D ys, sampler2D zs, ivec2 uv);

uniform uint objectid;
uniform vec2 uv_scale;
flat out uvec2 o_id;
out vec4 o_color;
out vec2 o_uv;

void main()
{
    int index = gl_InstanceID;
    vec2 offset = vertices;
    ivec2 offseti = ivec2(offset);
    ivec2 dims = textureSize(position_z, 0);
    vec3 pos;
    {{position_calc}}

    o_id = uvec2(objectid, index1D+1);
    o_uv = index01 * uv_scale;
    vec3 normalvec = {{normal_calc}};

    o_color = vec4(0.0);
    render(model * vec4(pos, 1), normalvec, view, projection, lightposition);
}

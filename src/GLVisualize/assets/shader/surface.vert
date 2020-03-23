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
{{stroke_color_type}} stroke_color;
{{glow_color_type}} glow_color;
{{color_type}} color;
{{color_map_type}} color_map;
{{color_norm_type}} color_norm;

vec4 color_lookup(float intensity, sampler1D color, vec2 norm);
// constant color!
vec4 get_color(vec4 color, float _intensity, Nothing color_map, Nothing color_norm, int index){
    return color;
}

vec4 get_color(Nothing color, float _intensity, sampler1D color_map, vec2 color_norm, int index){
    return color_lookup(_intensity, color_map, color_norm);
}
vec4 get_color(sampler2D color, float _intensity, Nothing b, Nothing c, int index){
    return vec4(0); // we fetch the color in fragment shader
}

uniform vec3 scale;

uniform mat4 view, model, projection;

void render(vec4 vertices, vec3 normal, mat4 viewmodel, mat4 projection, vec3 lightposition);
ivec2 ind2sub(ivec2 dim, int linearindex);
vec2 linear_index(ivec2 dims, int index);
vec2 linear_index(ivec2 dims, int index, vec2 offset);
vec4 linear_texture(sampler2D tex, int index, vec2 offset);
vec3 getnormal(sampler2D zvalues, vec2 uv);

uniform bool wireframe;
uniform uint objectid;
uniform float stroke_width;
flat out uvec2 o_id;
out vec4 o_color;
out vec2 o_uv;

flat out vec2            f_scale;
flat out vec4            f_color;
flat out vec4            f_bg_color;
flat out vec4            f_stroke_color;
flat out vec4            f_glow_color;
flat out int             f_primitive_index;
flat out uvec2           f_id;

out vec2                 f_uv;
out vec2                 f_uv_offset;

void main()
{
    int index = gl_InstanceID;
    vec2 offset = vertices;
    ivec2 offseti = ivec2(offset);
    ivec2 dims = textureSize(position_z, 0);
    vec2 final_scale = ((scale.xy)/(scale.xy-stroke_width));

    const float uv_w = 0.9;

    vec3 pos;
    {{position_calc}}
    //pos           += vec3(scale.xy*vertices, 0.0);
    o_color = get_color(color, pos.z, color_map, color_norm, index);
    o_id = uvec2(objectid, index1D+1);

    if(wireframe){
        if(offset.x == 0){
            f_uv.x = -uv_w;
        }else{
            f_uv.x = uv_w;
        }
        if(offset.y == 0){
            f_uv.y = -uv_w;
        }else{
            f_uv.y = uv_w;
        }
        f_id = o_id;
        f_uv_offset = vec2(0);
        f_color = o_color;
        f_bg_color = o_color;
        f_stroke_color = stroke_color;
        f_glow_color = glow_color;
        f_scale = vec2(-0.1, 0);
        gl_Position = projection * view * model * vec4(pos, 1);
    }else{
        o_uv = index01;
        vec3 normalvec = {{normal_calc}};
        render(model * vec4(pos, 1), (model * vec4(normalvec, 0)).xyz, view, projection, lightposition);
    }
}

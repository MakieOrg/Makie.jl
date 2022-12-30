{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}
{{SUPPORTED_EXTENSIONS}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

in vec4 f_color;
in vec2 f_uv;
in float f_thickness;
flat in uvec2 f_id;
flat in int f_type; // TODO bad for performance
{{pattern_type}} pattern;

uniform float pattern_length;

const float ALIASING_CONST = 0.9;

float aastep(float threshold1, float value) {
    float afwidth = length(vec2(dFdx(value), dFdy(value))) * ALIASING_CONST;
    return smoothstep(threshold1-afwidth, threshold1+afwidth, value);
}
float aastep(float threshold1, float threshold2, float value) {
    float afwidth = length(vec2(dFdx(value), dFdy(value))) * ALIASING_CONST;
    return smoothstep(threshold1-afwidth, threshold1+afwidth, value)-smoothstep(threshold2-afwidth, threshold2+afwidth, value);
}
void write2framebuffer(vec4 color, uvec2 id);

// Signed distance fields for lines
// x/y pattern
float get_sd(sampler2D pattern, vec2 uv){
    return texture(pattern, uv).x;
}
uniform float maxlength;
// x pattern
vec2 get_sd(sampler1D pattern, vec2 uv){
    return vec2(texture(pattern, uv.x).x, uv.y);
}
// normal line type
vec2 get_sd(Nothing _, vec2 uv){
    return vec2(0.5, uv.y);
}

// Signed distance fields for caps
#define LINE              0
#define CIRCLE            4
#define RECTANGLE         5
#define TRIANGLE          6
#define MIRRORED_TRIANGLE 7

float triangle(vec2 P){
    // adjusted from distance shape, technically diamond shape <>
    P -= vec2(0.5);
    float x = P.y - P.x;
    float y = P.y + P.x;
    return 0.5 - max(abs(x), abs(y));
}
float mirrored_triangle(vec2 P){
    // Like >< for triangle markers cutting into lines
    P -= vec2(0.5);
    return min(0.5, abs(P.x)) - abs(P.y);
}
float circle(vec2 uv){
    // Radius 0.5 circle centered at (0.5, 0.5)
    return 0.5-length(uv - vec2(0.5));
}
float rectangle(vec2 uv){
    // fills 0..1 x 0..1
    vec2 d = max(-uv, uv-vec2(1));
    return -( length(max(vec2(0.0), d)) + min(0.0, max(d.x, d.y)) );
}


void main(){
    vec4 color = vec4(f_color.rgb, 0.0);
    if (f_type == CIRCLE){
        float sd = f_thickness * circle(f_uv);
        color = mix(color, f_color, smoothstep(-ALIASING_CONST, ALIASING_CONST, sd));
    } else if (f_type == RECTANGLE) {
        float sd = f_thickness * rectangle(f_uv);
        // color = mix(color, f_color, smoothstep(-ALIASING_CONST, ALIASING_CONST, sd));
        color = mix(color, f_color, aastep(0, sd));
    } else if (f_type == TRIANGLE) {
        float sd = f_thickness * triangle(f_uv);
        color = mix(color, f_color, smoothstep(-ALIASING_CONST, ALIASING_CONST, sd));
    } else if (f_type == MIRRORED_TRIANGLE) {
        float sd = f_thickness * mirrored_triangle(f_uv);
        color = mix(color, f_color, smoothstep(-ALIASING_CONST, ALIASING_CONST, sd));
    } else {
        vec2 xy = get_sd(pattern, f_uv);
        float alpha = aastep(0, xy.x);
        float alpha2 = aastep(-1, 1, xy.y);
        color = vec4(f_color.rgb, f_color.a*alpha*alpha2);
    }
    write2framebuffer(color, f_id);
}

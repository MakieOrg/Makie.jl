#version 300 es
precision mediump int;
precision mediump float;
precision mediump sampler2D;
precision mediump sampler3D;

out vec4 fragment_color;

// Uniforms: 
uniform bool uniform_color;
bool get_uniform_color(){return uniform_color;}
uniform vec2 texturecoordinates;
vec2 get_texturecoordinates(){return texturecoordinates;}
uniform bool shading;
bool get_shading(){return shading;}

in vec2 frag_uv;
in vec4 frag_color;
in vec3 frag_normal;
in vec3 frag_position;
in vec3 frag_lightdir;

vec3 blinnphong(vec3 N, vec3 V, vec3 L, vec3 color){
    float diff_coeff = max(dot(L, N), 0.0);

    // specular coefficient
    vec3 H = normalize(L+V);

    float spec_coeff = pow(max(dot(H, N), 0.0), 8.0);
    if (diff_coeff <= 0.0)
        spec_coeff = 0.0;

    // final lighting model
    return vec3(
        vec3(0.1) * vec3(0.3)  +
        vec3(0.9) * color * diff_coeff +
        vec3(0.3) * spec_coeff
    );
}


vec4 get_color(vec3 color, vec2 uv){
    return vec4(color, 1.0); // we must prohibit uv from getting into dead variable removal
}

vec4 get_color(vec4 color, vec2 uv){
    return color; // we must prohibit uv from getting into dead variable removal
}

vec4 get_color(bool color, vec2 uv){
    return frag_color;  // color not in uniform
}

vec4 get_color(sampler2D color, vec2 uv){
    return texture(color, uv);
}


void main() {
    vec4 real_color = get_color(uniform_color, frag_uv);
    vec3 shaded_color = real_color.xyz;
    if(get_shading()){
        shaded_color = blinnphong(frag_normal, frag_position, frag_lightdir, real_color.xyz);
    }

    fragment_color = vec4(shaded_color, real_color.a);
}

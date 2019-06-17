#version 300 es
precision mediump int;
precision mediump float;
precision mediump sampler2D;
precision mediump sampler3D;

out vec4 fragment_color;

// Uniforms: 
uniform sampler3D volumedata;
uniform mat4 modelinv;
mat4 get_modelinv(){return modelinv;}
uniform sampler2D colormap;
uniform vec2 colorrange;
vec2 get_colorrange(){return colorrange;}
uniform float isovalue;
float get_isovalue(){return isovalue;}
uniform float isorange;
float get_isorange(){return isorange;}
uniform vec3 light_position;
vec3 get_light_position(){return light_position;}

in vec3 frag_vert;
in vec3 frag_uv;
/*
uniform sampler3D volumedata;
uniform sampler2D colormap;
uniform vec2 colorrange;
uniform mat4 modelMatrix, modelinv;
*/

const float max_distance = 1.3;
const int num_samples = 150;
const float step_size = max_distance / float(num_samples);

uniform vec3 cameraPosition;

float range01(float val, float from, float to)
{
    return clamp((val-from) / (to - from), 0.0, 1.0);
}

vec3 gennormal(vec3 uvw, vec3 gradient_delta)
{
    vec3 a,b;
    a.x = texture(volumedata, uvw - vec3(gradient_delta.x,0.0,0.0) ).r;
    b.x = texture(volumedata, uvw + vec3(gradient_delta.x,0.0,0.0) ).r;
    a.y = texture(volumedata, uvw - vec3(0.0,gradient_delta.y,0.0) ).r;
    b.y = texture(volumedata, uvw + vec3(0.0,gradient_delta.y,0.0) ).r;
    a.z = texture(volumedata, uvw - vec3(0.0,0.0,gradient_delta.z) ).r;
    b.z = texture(volumedata, uvw + vec3(0.0,0.0,gradient_delta.z) ).r;
    return normalize(a - b);
}

vec3 blinn_phong(vec3 N, vec3 V, vec3 L, vec3 diffuse)
{
    // material properties
    vec3 Ka = vec3(0.1);
    vec3 Kd = vec3(1.0, 1.0, 1.0);
    vec3 Ks = vec3(1.0, 1.0, 1.0);
    float shininess = 50.0;

    // diffuse coefficient
    float diff_coeff = max(dot(L,N),0.0);

    // specular coefficient
    vec3 H = normalize(L+V);
    float spec_coeff = pow(max(dot(H,N), 0.0), shininess);
    if (diff_coeff <= 0.0)
        spec_coeff = 0.0;

    // final lighting model
    return  Ka * vec3(0.5) +
            Kd * diffuse * diff_coeff +
            Ks * vec3(0.3) * spec_coeff ;
}

bool is_outside(vec3 position)
{
    return (
        position.x > 1.0 || position.y > 1.0 || position.z > 1.0 ||
        position.x < 0.0 || position.y < 0.0 || position.z < 0.0
    );
}

// Simple random generator found: http://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
float rand(){
    return fract(
        sin(gl_FragCoord.x * 12.9898 + gl_FragCoord.y * 78.233) * 43758.5453
    );
}

vec4 contours(vec3 front, vec3 dir, float stepsize)
{
    vec3 stepsize_dir = normalize(dir) * stepsize;
    // The per-voxel alpha channel is specified in units of opacity/length.
    // If our voxels are not isotropic, then the distance that we trace through
    // depends on the direction.
    vec3 pos = front;
    float T = 1.0;
    vec3 Lo = vec3(0.0);
    int i = 0;
    // add random offset to counteract sampling artifacts
    pos += stepsize_dir * rand();
    for (i; i < num_samples; i++) {
        if(T <= 0.01)
            break;
        float intensity = texture(volumedata, pos).x;
        intensity = range01(intensity, colorrange.x, colorrange.y);
        vec4 density = texture(colormap, vec2(intensity, 0));
        float opacity = density.a;
        if(opacity > 0.0){
            vec3 N = gennormal(pos, vec3(stepsize));
            vec3 L = normalize(light_position - pos);
            vec3 L2 = -L;
            Lo += (T*opacity) * blinn_phong(N, pos, L, density.rgb);
            Lo += (T*opacity) * blinn_phong(N, pos, -L, density.rgb);

            T *= 1.0 - opacity;
        }
        pos += stepsize_dir;
    }
    return vec4(Lo, 1.0 - T);
}

void main()
{
    vec3 dir = normalize(frag_vert - cameraPosition);
    dir = vec3(modelinv * vec4(dir, 0.0));
    vec4 color = contours(frag_uv, dir, step_size);
    if(color.a <= 0.0)
        discard;
    fragment_color = color;
}

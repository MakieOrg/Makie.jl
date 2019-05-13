precision mediump int;
precision mediump float;
// Uniforms:
uniform vec4 strokecolor;
vec4 get_strokecolor(){return strokecolor;}
uniform float glowwidth;
float get_glowwidth(){return glowwidth;}
uniform vec2 markersize;
vec2 get_markersize(){return markersize;}
uniform int shape_type;
int get_shape_type(){return shape_type;}
uniform sampler2D distancefield;
uniform float strokewidth;
float get_strokewidth(){return strokewidth;}
uniform vec2 resolution;
vec2 get_resolution(){return resolution;}
uniform mat4 model;
mat4 get_model(){return model;}
uniform vec4 uv_offset_width;
vec4 get_uv_offset_width(){return uv_offset_width;}
uniform vec4 glowcolor;
vec4 get_glowcolor(){return glowcolor;}
uniform bool transform_marker;
bool get_transform_marker(){return transform_marker;}

varying vec4 frag_color;
varying vec2 frag_uv;

#define CIRCLE            0
#define RECTANGLE         1
#define ROUNDED_RECTANGLE 2
#define DISTANCEFIELD     3
#define TRIANGLE          4

#define M_SQRT_2          1.4142135


// Half width of antialiasing smoothstep
#define ANTIALIAS_RADIUS  0.8
// These versions of aastep assume that `dist` is a signed distance function
// which has been scaled to be in units of pixels.
float aastep(float threshold1, float dist) {
    return smoothstep(threshold1-ANTIALIAS_RADIUS, threshold1 + ANTIALIAS_RADIUS, dist);
}

float aastep(float threshold1, float threshold2, float dist) {
    return smoothstep(threshold1-ANTIALIAS_RADIUS, threshold1+ANTIALIAS_RADIUS, dist) -
           smoothstep(threshold2-ANTIALIAS_RADIUS, threshold2+ANTIALIAS_RADIUS, dist);
}


// Procedural signed distance functions on the uv coordinate patch [0,1]x[0,1]
// Note that for antialiasing to work properly these should be *scale preserving*
// (If you must rescale uv, make sure to put the scale factor back in later.)
float triangle(vec2 P){
    P -= vec2(0.5);
    float x = M_SQRT_2 * (P.x - P.y);
    float y = M_SQRT_2 * (P.x + P.y);
    float r1 = max(abs(x), abs(y)) - 1.0/(2.0*M_SQRT_2);
    float r2 = P.y;
    return -max(r1,r2);
}
float circle(vec2 uv){
    return 0.5-length(uv-vec2(0.5));
}
float rectangle(vec2 uv){
    vec2 d = max(-uv, uv-vec2(1));
    return -((length(max(vec2(0.0), d)) + min(0.0, max(d.x, d.y))));
}
float rounded_rectangle(vec2 uv, vec2 tl, vec2 br){
    vec2 d = max(tl-uv, uv-br);
    return -((length(max(vec2(0.0), d)) + min(0.0, max(d.x, d.y)))-tl.x);
}

void fill(vec4 fillcolor, vec2 uv, float infill, inout vec4 color){
    color = mix(color, fillcolor, infill);
}

varying float frag_uvscale;
varying float frag_distancefield_scale;

float scaled_distancefield(sampler2D distancefield, vec2 uv){
    // Glyph distance field units are in pixels. Convert to same distance
    // scaling as f_uv.x for consistency with the procedural signed_distance
    // calculations.
    return frag_distancefield_scale * texture2D(distancefield, uv).r;
}

float scaled_distancefield(bool distancefield, vec2 uv){
    return 0.0;
}

void main() {
    int shape = get_shape_type();
    float signed_distance = 0.0;
    vec4 uv_off = get_uv_offset_width();
    vec2 tex_uv = mix(uv_off.xy, uv_off.zw, clamp(frag_uv, 0.0, 1.0));
    if(shape == CIRCLE)
        signed_distance = circle(frag_uv);
    else if(shape == DISTANCEFIELD)
        signed_distance = scaled_distancefield(distancefield, tex_uv);
    else if(shape == ROUNDED_RECTANGLE)
        signed_distance = rounded_rectangle(frag_uv, vec2(0.2), vec2(0.8));
    else if(shape == RECTANGLE)
        signed_distance = 1.0; // rectangle(f_uv);
    else if(shape == TRIANGLE)
        signed_distance = triangle(frag_uv);

    signed_distance *= frag_uvscale;
    float inside = aastep(0.0, signed_distance);
    vec4 final_color = vec4(frag_color.xyz, 0);
    fill(frag_color, frag_uv, inside, final_color);
    gl_FragColor = final_color;
}

{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}
{{SUPPORTED_EXTENSIONS}}

// show the various regions of the rendered segment
// (anti-aliased edges, joint truncation, overlap cutoff, patterns)
// #define DEBUG

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

in vec4 f_color;
in float f_quad_sdf0;
in vec3 f_quad_sdf1;
in float f_quad_sdf2;
in vec2 f_truncation;
in vec2 f_uv;

flat in float f_linewidth;
flat in vec4 f_pattern_overwrite;
flat in uvec2 f_id;
flat in vec2 f_extrusion12;
flat in vec2 f_linelength;

{{pattern_type}} pattern;
uniform float pattern_length;
uniform bool fxaa;

// Half width of antialiasing smoothstep
#define AA_THICKNESS 4
#define ANTIALIAS_RADIUS 0.8

float aastep(float threshold1, float dist) {
    return smoothstep(threshold1-ANTIALIAS_RADIUS, threshold1+ANTIALIAS_RADIUS, dist);
}

// Pattern sampling
float get_pattern_sdf(sampler2D pattern){
    return texture(pattern, f_uv).x;
}
float get_pattern_sdf(sampler1D pattern){
    float sdf_offset, x;
    if (f_uv.x <= f_pattern_overwrite.x) {
        // below allowed range of uv.x's (end of left joint + AA_THICKNESS)
        // if overwrite.y (target sdf in joint) is
        // .. +1 we start from max(pattern[overwrite.x], -AA) and extrapolate to positive values
        // .. -1 we start from min(pattern[overwrite.x], +AA) and extrapolate to negative values
        sdf_offset = max(f_pattern_overwrite.y * texture(pattern, f_pattern_overwrite.x).x, -AA_THICKNESS);
        return f_pattern_overwrite.y * (pattern_length * (f_pattern_overwrite.x - f_uv.x) + sdf_offset);
    } else if (f_uv.x >= f_pattern_overwrite.z) {
        // above allowed range of uv.x's (start of right joint - AA_THICKNESS)
        // see above
        sdf_offset = max(f_pattern_overwrite.w * texture(pattern, f_pattern_overwrite.z).x, -AA_THICKNESS);
        return f_pattern_overwrite.w * (pattern_length * (f_uv.x - f_pattern_overwrite.z) + sdf_offset);
    } else
        // in allowed range
        return texture(pattern, f_uv.x).x;
}
float get_pattern_sdf(Nothing _){
    return -10.0;
}

void write2framebuffer(vec4 color, uvec2 id);

void main(){
    vec4 color;

#ifndef DEBUG
    // discard fragments that are "more inside" the other segment to remove
    // overlap between adjacent line segments.
    // The transformation makes the distance be "less inside" once it reaches
    // f_linelength. This limits how much one segment can cut from another
    float dist_in_prev = abs(f_quad_sdf0 + f_linelength.x) - f_linelength.x;
    float dist_in_next = abs(f_quad_sdf2 + f_linelength.y) - f_linelength.y;
    if (dist_in_prev < f_quad_sdf1.x || dist_in_next <= f_quad_sdf1.y)
        discard;

    // sdf for inside vs outside along the line direction. extrusion makes sure
    // we include enough for a joint
    float sdf = max(f_quad_sdf1.y - f_extrusion12.y, f_quad_sdf1.x - f_extrusion12.x);

    // distance in linewidth direction
    sdf = max(sdf, abs(f_quad_sdf1.z) - f_linewidth);

    // truncation of truncated joints
    sdf = max(sdf, f_truncation.x);
    sdf = max(sdf, f_truncation.y);

    // pattern application
    sdf = max(sdf, get_pattern_sdf(pattern));

    // draw
    color = f_color;

    if (!fxaa) {
        color.a *= aastep(0.0, -sdf);
    } else {
        color.a *= step(0.0, -sdf);
    }
#endif


#ifdef DEBUG
    // base color
    color = vec4(0.5, 0.5, 0.5, 0.2);

    // mark "outside" define by quad_sdf in black
    float sdf = max(f_quad_sdf1.y - f_extrusion12.y, f_quad_sdf1.x - f_extrusion12.x);
    sdf = max(sdf, abs(f_quad_sdf1.z) - f_linewidth);
    color.rgb -= vec3(0.5) * step(0.0, sdf);

    // Mark regions excluded via truncation in green
    color.g += 0.5 * step(0.0, max(f_truncation.x, f_truncation.y));

    // Mark discarded space in red/blue
    float dist_in_prev = abs(f_quad_sdf0 + f_linelength.x) - f_linelength.x;
    float dist_in_next = abs(f_quad_sdf2 + f_linelength.y) - f_linelength.y;
    if (dist_in_prev < f_quad_sdf1.x)
        color.r += 0.5;
    if (dist_in_next <= f_quad_sdf1.y) {
        color.b += 0.5;
    }

    // mark pattern in white
    color.rgb += vec3(0.5) * step(0.0, get_pattern_sdf(pattern));
#endif

    write2framebuffer(color, f_id);
}
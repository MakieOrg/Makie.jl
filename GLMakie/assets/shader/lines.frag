{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}
{{SUPPORTED_EXTENSIONS}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

in vec4 f_color;
in vec4 f_quad_sdf;
in vec4 f_joint_cutoff;
in vec2 f_uv;
flat in vec4 f_pattern_overwrite;
flat in uvec2 f_id;

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
        sdf_offset = max(f_pattern_overwrite.y * texture(pattern, f_pattern_overwrite.x).x, -AA_THICKNESS);
        return f_pattern_overwrite.y * ( // +- pos ... 0
            pattern_length * (f_pattern_overwrite.x - f_uv.x) + // pos ... 0
            sdf_offset
        );
        // subtract at most AA_THICKNES
        // if texture > -AA_THICKNESS start from there
        // return f_pattern_overwrite.y * (pattern_length * (f_pattern_overwrite.x - f_uv.x) - AA_THICKNESS);
    } else if (f_uv.x >= f_pattern_overwrite.z) {
        sdf_offset = max(f_pattern_overwrite.w * texture(pattern, f_pattern_overwrite.z).x, -AA_THICKNESS);
        return f_pattern_overwrite.w * ( // +- pos ... 0
            pattern_length * (f_uv.x - f_pattern_overwrite.z) + // pos ... 0
            sdf_offset
        );
        // return f_pattern_overwrite.w * (pattern_length * (f_uv.x - f_pattern_overwrite.z) - AA_THICKNESS);

    } else
        return texture(pattern, f_uv.x).x;
}
float get_pattern_sdf(Nothing _){
    return -10.0;
}

void write2framebuffer(vec4 color, uvec2 id);


#define DEBUG

void main(){

#ifndef DEBUG
    // We effectively start with a rectangle that's fully drawn, i.e. sdf < 0

    // Remove overlap of rects at joint
    // things that need to be cut have sdf >= 0
    if (max(f_joint_cutoff.x, f_joint_cutoff.y) >= 0.0)
        discard;

    // smoothly cut out line start, end and edge of truncated joint (if applicable)
    float sdf = max(f_quad_sdf.x, f_quad_sdf.y);

    // smoothly cut out edges at +- 0.5 * line width
    // sdf = max(sdf, abs(f_quad_sdf.z) - f_line_width);
    sdf = max(sdf, max(f_quad_sdf.z, f_quad_sdf.w));

    // smoothly cut off corners of truncated miter joints
    sdf = max(sdf, max(f_joint_cutoff.z, f_joint_cutoff.w));

    // add pattern
    sdf = max(sdf, get_pattern_sdf(pattern));

    // draw
    vec4 color = f_color;

    if (!fxaa) {
        color.a *= aastep(0.0, -sdf);
    } else {
        color.a *= step(0.0, -sdf);
    }

    // float aa = aastep(0.0, sdf);
    // vec4 color = vec4(0.0, 0.7, 0.1, 1);
    // color.rgb = mix(color.rgb, vec3(1,0,0), aa);

#endif


#ifdef DEBUG
    // show geom in white
    vec4 color = vec4(1, 1, 1, 0.5);

    // show line smooth clipping from quad_sdf
    // float sdf_width = abs(f_quad_sdf.z) - f_line_width;
    float sdf_width = max(f_quad_sdf.z, f_quad_sdf.w);
    // float sdf_width = max(f_quad_sdf.z, f_quad_sdf.w);
    color.r = 0.9 - 0.5 * aastep(0.0, sdf_width);
    color.b = 0.9 - 0.5 * aastep(0.0, f_quad_sdf.y);
    color.g = 0.9 - 0.5 * aastep(0.0, f_quad_sdf.x);

    // show how the joint overlap is cut off
    if (max(f_joint_cutoff.x, f_joint_cutoff.y) > 0.0) {
        color.r += 0.3;
        color.gb -= vec2(0.3);
    }

    // show pattern by reducing alpha heavily on off-parts
    if (get_pattern_sdf(pattern) > 0)
        color.a *= 0.2;
#endif

    write2framebuffer(color, f_id);
}
{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}
{{SUPPORTED_EXTENSIONS}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

in vec4 f_color;
in vec4 f_quad_sdf;
in vec2 f_joint_cutoff;
// in float f_line_width;
in float f_cumulative_length;
flat in uvec2 f_id;

// in vec2 f_rect_sdf;
// in vec2 f_joint_smooth;
// flat in float f_line_length;
// flat in float f_line_offset;

{{pattern_type}} pattern;

uniform float pattern_length;
uniform bool fxaa;

// Half width of antialiasing smoothstep
#define ANTIALIAS_RADIUS 0.8

float aastep(float threshold1, float dist) {
    return smoothstep(threshold1-ANTIALIAS_RADIUS, threshold1+ANTIALIAS_RADIUS, dist);
}

// Pattern sampling
float get_pattern_sdf(sampler2D pattern, vec2 uv){
    // make this texture repeating
    // TODO
    // vec2 uv2 = vec2((uv.x + f_line_offset) / pattern_length, 0.5 * uv.y / f_line_width);
    return texture(pattern, uv).x;
}
float get_pattern_sdf(sampler1D pattern, vec2 uv){
    // make this texture repeating
    return texture(pattern, uv.x / pattern_length).x;
}
float get_pattern_sdf(Nothing _, vec2 uv){
    return -10.0;
}

void write2framebuffer(vec4 color, uvec2 id);


#define DEBUG

void main(){
    // Metrics we need:
    // line length for pattern
    // line width sdf w/ AA
    // line start/end/truncation sdf w/ AA
    // hard join edge sdf


    // New version

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


    // 1. and 2. probably not mergeable because 2 needs to be an actual sdf that
    // can be cut off smoothly

    // discard join edge
    // seems like a vert/geom shader thing
    // if (f_joint_cutoff.x > 0.0 || f_joint_cutoff.y > 0.0) {
    //     // discard;
    // }

    // signed distance to edge of rect (line without join)
    // - start/end need rect_sdf to be 0 at p1/p2 (could be done with f_joint_smooth)
    // - pattern needs rect_sdf to be 0 at p1
    // - joins need rect_sdf to extend/ignore x
    //   ^- probably possible by merging sdfs correctly?
    //    - max(min(rect.x, smooth.x), min(rect.x, smooth.y))?
    //    - yea but necessitates smooth >= 0.0 outside of rect sdf
    // float sdf = max(abs(f_rect_sdf.x) - f_line_length, abs(f_rect_sdf.y) - f_line_width);

    // smooth out truncated join
    // sdf = max(sdf, dot(gl_Position.xy - P1, miter_n_a) - miter_a_offset);
    // sdf = max(sdf, max(f_joint_smooth.x, f_joint_smooth.y));

    // fix up line pattern fetch
    // float pattern_sdf = texture(pattern, mod(f_rect_sdf.x + line_length_offset, pattern_length) / pattern_length );
    // sdf = max(sdf, get_pattern_sdf(pattern, f_rect_sdf));

    // draw
    // vec4 color = f_color;

    // if (fxaa)
    //     color.a *= aastep(0.0, sdf);
    // else
    //     color.a *= step(0.0, sdf);




#ifdef DEBUG
    // show geom in white
    vec4 color = vec4(1, 1, 1, 0.5);

    // show line smooth clipping from quad_sdf
    // float sdf_width = abs(f_quad_sdf.z) - f_line_width;
    float sdf_width = max(f_quad_sdf.z, f_quad_sdf.w);
    color.r = 0.9 - 0.5 * aastep(0.0, sdf_width);
    color.b = 0.9 - 0.5 * aastep(0.0, f_quad_sdf.y);
    color.g = 0.9 - 0.5 * aastep(0.0, f_quad_sdf.x);

    // show how the joint overlap is cut off
    if (max(f_joint_cutoff.x, f_joint_cutoff.y) > 0.0) {
        color.r += 0.3;
        color.gb -= vec2(0.3);
    }
#endif


    /*
    // show geom in black
    vec4 color = vec4(0,0,0,0.6);

    // show rect sdf in red
    float rect = max(abs(f_rect_sdf.x) - f_line_length, abs(f_rect_sdf.y) - f_line_width);
    color.r = 0.5 * aastep(0.0, -rect);

    // sharp join cutoff - color yellow
    // if (max(f_joint_cutoff.x, f_joint_cutoff.y) > 0.0) {
    //     color.rg += vec2(0.7);
    // }

    // smooth cutoff - mark in blue what's considered outside
    color.b = aastep(0.0, min(f_joint_smooth.x, f_joint_smooth.y));

    // what's inside that wasn't before?
    // rect > 0 and smooth < 0

    // color.b = aastep(0.0, f_joint_smooth.x);
    // color.b = aastep(0.0, f_joint_smooth.y);

    // color.g = 0.5 * aastep(0.0, f_joint_smooth.x);
    // color.b = 0.5 * aastep(0.0, f_joint_smooth.y);
    // float smooth_join = max(min(rect.x, f_joint_smooth.x), min(rect.x, f_joint_smooth.y));
    // color.rg = vec2(0.5, 0.5) * aastep(0.0, smooth_join);
    */

    write2framebuffer(color, f_id);
}
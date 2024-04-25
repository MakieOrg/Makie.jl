{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}
{{SUPPORTED_EXTENSIONS}}

// show the various regions of the rendered segment
// (anti-aliased edges, joint truncation, overlap cutoff, patterns)
// #define DEBUG
uniform bool debug;

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

in highp vec3 f_quad_sdf;
in vec2 f_truncation;
in float f_linestart;
in float f_linelength;

flat in float f_linewidth; // half the real linewidth here because we count from center
flat in vec4 f_pattern_overwrite;
flat in vec2 f_extrusion;
flat in {{stripped_color_type}} f_color1;
flat in {{stripped_color_type}} f_color2;
flat in float f_alpha_weight;
flat in uvec2 f_id;
flat in float f_cumulative_length;
flat in ivec2 f_capmode;
flat in vec4 f_linepoints;
flat in vec4 f_miter_vecs;

{{pattern_type}} pattern;
uniform float pattern_length;
uniform bool fxaa;

{{color_map_type}} color_map;
{{color_norm_type}} color_norm;
uniform vec4 highclip;
uniform vec4 lowclip;
uniform vec4 nan_color;

// Half width of antialiasing smoothstep
const float AA_RADIUS = 0.8;
const int BUTT   = 0;
const int SQUARE = 1;
const int ROUND  = 2;
const int MITER  = 0;
const int BEVEL  = 3;

float aastep(float threshold1, float dist) {
    return smoothstep(threshold1-AA_RADIUS, threshold1+AA_RADIUS, dist);
}

////////////////////////////////////////////////////////////////////////
// Color handling
////////////////////////////////////////////////////////////////////////


vec4 get_color_from_cmap(float value, sampler1D colormap, vec2 colorrange) {
    float cmin = colorrange.x;
    float cmax = colorrange.y;
    if (value <= cmax && value >= cmin) {
        // in value range, continue!
    } else if (value < cmin) {
        return lowclip;
    } else if (value > cmax) {
        return highclip;
    } else {
        // isnan CAN be broken (of course) -.-
        // so if outside value range and not smaller/bigger min/max we assume NaN
        return nan_color;
    }
    float i01 = clamp((value - cmin) / (cmax - cmin), 0.0, 1.0);
    // 1/0 corresponds to the corner of the colormap, so to properly interpolate
    // between the colors, we need to scale it, so that the ends are at 1 - (stepsize/2) and 0+(stepsize/2).
    float stepsize = 1.0 / float(textureSize(colormap, 0));
    i01 = (1.0 - stepsize) * i01 + 0.5 * stepsize;
    return texture(colormap, i01);
}

vec4 get_color(float color, sampler1D colormap, vec2 colorrange) {
    return get_color_from_cmap(color, colormap, colorrange);
}

vec4 get_color(vec4 color, Nothing colormap, Nothing colorrange) {
    return color;
}
vec4 get_color(vec3 color, Nothing colormap, Nothing colorrange) {
    return vec4(color, 1.0);
}

////////////////////////////////////////////////////////////////////////////////
// Pattern sampling
////////////////////////////////////////////////////////////////////////////////


float get_pattern_sdf(sampler2D pattern, vec2 uv){
    return 2.0 * f_linewidth * texture(pattern, uv).x;
}
float get_pattern_sdf(sampler1D pattern, vec2 uv){

    // f_pattern_overwrite.x
    //      v           joint
    //    ----------------
    //      |          |
    //    ----------------
    // joint           ^
    //      f_pattern_overwrite.z

    float w = 2.0 * f_linewidth;
    if (uv.x <= f_pattern_overwrite.x) {
        // overwrite for pattern with "ON" to the right (positive uv.x)
        float sdf_overwrite = w * pattern_length * (f_pattern_overwrite.x - uv.x);
        // pattern value where we start overwriting
        float edge_sample = w * texture(pattern, f_pattern_overwrite.x).x;
        // offset for overwrite to smoothly connect between sampling and edge
        float sdf_offset = max(f_pattern_overwrite.y * edge_sample, -AA_RADIUS);
        // add offset and apply direction ("ON" to left or right) to overwrite
        return f_pattern_overwrite.y * (sdf_overwrite + sdf_offset);
    } else if (uv.x >= f_pattern_overwrite.z) {
        // same as above (other than mirroring overwrite direction)
        float sdf_overwrite = w * pattern_length * (uv.x - f_pattern_overwrite.z);
        float edge_sample = w * texture(pattern, f_pattern_overwrite.z).x;
        float sdf_offset = max(f_pattern_overwrite.w * edge_sample, -AA_RADIUS);
        return f_pattern_overwrite.w * (sdf_overwrite + sdf_offset);
    } else
        // in allowed range
        return w * texture(pattern, uv.x).x;
}
float get_pattern_sdf(Nothing _, vec2 uv){
    return -10.0;
}


void write2framebuffer(vec4 color, uvec2 id);

// General Notes on SDFs here:
// < 0 is considered inside the shape, i.e. drawn
// min(sdf1, sdf2) is the union shapes sdf1 and sdf2
// max(sdf1, sdf2) is the intersection of sdf1 and sdf2

void main(){
    vec4 color;

    // f_quad_sdf.x is the negative distance from p1 in v1 direction
    // (where f_cumulative_length applies) so we need to subtract here
    vec2 uv = vec2(
        (f_cumulative_length - f_quad_sdf.x + 0.5) / (2.0 * f_linewidth * pattern_length),
        0.5 + 0.5 * f_quad_sdf.z / f_linewidth
    );

// #ifndef DEBUG
if (!debug) {
    // discard fragments that are other side of the truncated joint
    float discard_sdf1 = dot(gl_FragCoord.xy - f_linepoints.xy, f_miter_vecs.xy);
    float discard_sdf2 = dot(gl_FragCoord.xy - f_linepoints.zw, f_miter_vecs.zw);
    if ((f_quad_sdf.x > 0.0 && discard_sdf1 > 0.0) ||
        (f_quad_sdf.y > 0.0 && discard_sdf2 >= 0.0))
        discard;

    float sdf;

    // f_quad_sdf.x includes everything from p1 in p2-p1 direction, i.e. >
    // f_quad_sdf.y includes everything from p2 in p1-p2 direction, i.e. <
    // <   < | >    < >    < | >   >
    // <   < 1->----<->----<-2 >   >
    // <   < | >    < >    < | >   >
    if (f_capmode.x == ROUND) {
        // in circle(p1, halfwidth) || is beyond p1 in p2-p1 direction
        sdf = min(sqrt(f_quad_sdf.x * f_quad_sdf.x + f_quad_sdf.z * f_quad_sdf.z) - f_linewidth, f_quad_sdf.x);
    } else if (f_capmode.x == SQUARE) {
        // everything in p2-p1 direction shifted by halfwidth in p1-p2 direction (i.e. include more)
        sdf = f_quad_sdf.x - f_linewidth;
    } else { // miter or bevel joint or :butt cap
        // variable shift in -(p2-p1) direction to make space for joints
        sdf = f_quad_sdf.x - f_extrusion.x;
        // do truncate joints
        sdf = max(sdf, f_truncation.x);
    }

    // Same as above but for p2
    if (f_capmode.y == ROUND) { // rounded joint or cap
        sdf = max(sdf,
            min(sqrt(f_quad_sdf.y * f_quad_sdf.y + f_quad_sdf.z * f_quad_sdf.z) - f_linewidth, f_quad_sdf.y)
        );
    } else if (f_capmode.y == SQUARE) { // :square cap
        sdf = max(sdf, f_quad_sdf.y - f_linewidth);
    } else { // miter or bevel joint or :butt cap
        sdf = max(sdf, f_quad_sdf.y - f_extrusion.y);
        sdf = max(sdf, f_truncation.y);
    }

    // distance in linewidth direction
    // f_quad_sdf.z is 0 along the line connecting p1 and p2 and increases along line-normal direction
    //  ^  |  ^      ^  | ^
    //     1------------2
    //  ^  |  ^      ^  | ^
    sdf = max(sdf, abs(f_quad_sdf.z) - f_linewidth);

    // inner truncation (AA for overlapping parts)
    // min(a, b) keeps what is inside a and b
    // where a is the smoothly cut of part just before discard triggers (i.e. visible)
    // and b is the (smoothly) cut of part just after discard triggers (i.e not visible)
    // 100.0x sdf makes the sdf much more sharply, avoiding overdraw in the center
    sdf = max(sdf, min(f_quad_sdf.x + 1.0, 100.0 * discard_sdf1 - 1.0));
    sdf = max(sdf, min(f_quad_sdf.y + 1.0, 100.0 * discard_sdf2 - 1.0));

    // pattern application
    sdf = max(sdf, get_pattern_sdf(pattern, uv));

    // draw

    //  v- edge
    //   .---------------
    //    '.
    //      p1      v1
    //        '.   --->
    //          '----------
    // -f_quad_sdf.x is the distance from p1, positive in v1 direction
    // f_linestart is the distance between p1 and the left edge along v1 direction
    // f_start_length.y is the distance between the edges of this segment, in v1 direction
    // so this is 0 at the left edge and 1 at the right edge (with extrusion considered)
    float factor = (-f_quad_sdf.x - f_linestart) / f_linelength;
    color = get_color(f_color1 + factor * (f_color2 - f_color1), color_map, color_norm);
    color.a *= f_alpha_weight;

    if (!fxaa) {
        color.a *= aastep(0.0, -sdf);
    } else {
        color.a *= step(0.0, -sdf);
    }
// #endif

} else {

// #ifdef DEBUG
    // base color
    color = vec4(0.5, 0.5, 0.5, 0.2);
    color.rgb += (2 * mod(f_id.y, 2) - 1) * 0.1;

    // mark "outside" define by quad_sdf in black
    float sdf = max(f_quad_sdf.x - f_extrusion.x, f_quad_sdf.y - f_extrusion.y);
    sdf = max(sdf, abs(f_quad_sdf.z) - f_linewidth);
    color.rgb -= vec3(0.4) * step(0.0, sdf);

    // Mark discarded space in red/blue
    float discard_sdf1 = dot(gl_FragCoord.xy - f_linepoints.xy, f_miter_vecs.xy);
    float discard_sdf2 = dot(gl_FragCoord.xy - f_linepoints.zw, f_miter_vecs.zw);
    if (f_quad_sdf.x > 0.0 && discard_sdf1 > 0.0)
        color.r += 0.5;
    if (f_quad_sdf.y > 0.0 && discard_sdf2 >= 0.0)
        color.b += 0.5;

    // remaining overlap as softer red/blue
    if (discard_sdf1 - 1.0 > 0.0)
        color.r += 0.2;
    if (discard_sdf2 - 1.0 > 0.0)
        color.b += 0.2;

    // Mark regions excluded via truncation in green
    color.g += 0.5 * step(0.0, max(f_truncation.x, f_truncation.y));

    // and inner truncation as softer green
    if (min(f_quad_sdf.x + 1.0, 100.0 * discard_sdf1 - 1.0) > 0.0)
        color.g += 0.2;
    if (min(f_quad_sdf.y + 1.0, 100.0 * discard_sdf2 - 1.0) > 0.0)
        color.g += 0.2;

    // mark pattern in white
    color.rgb += vec3(0.3) * step(0.0, get_pattern_sdf(pattern, uv));
// #endif
}

    write2framebuffer(color, f_id);
}
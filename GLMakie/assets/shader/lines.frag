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

in highp float f_quad_sdf0;
in highp vec3 f_quad_sdf1;
in highp float f_quad_sdf2;
in vec2 f_truncation;
in float f_linestart;
in float f_linelength;

flat in float f_linewidth;
flat in vec4 f_pattern_overwrite;
flat in vec2 f_extrusion;
flat in vec2 f_discard_limit;
flat in vec4 f_color1;
flat in vec4 f_color2;
flat in uvec2 f_id;
flat in float f_cumulative_length;

{{pattern_type}} pattern;
uniform float pattern_length;
uniform bool fxaa;

// Half width of antialiasing smoothstep
const float AA_RADIUS = 0.8;

float aastep(float threshold1, float dist) {
    return smoothstep(threshold1-AA_RADIUS, threshold1+AA_RADIUS, dist);
}

// Pattern sampling
float get_pattern_sdf(sampler2D pattern, vec2 uv){
    return 2.0 * f_linewidth * texture(pattern, uv).x;
}
float get_pattern_sdf(sampler1D pattern, vec2 uv){
    float w = 2.0 * f_linewidth;
    // f_pattern_overwrite.x
    //      v           joint
    //    ----------------
    //      |          |
    //    ----------------
    // joint           ^
    //      f_pattern_overwrite.z
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

void main(){
    vec4 color;

    // if (f_id.y % 2 != 1)
        // discard;

    // f_quad_sdf1.x is the negative distance from p1 in v1 direction
    // (where f_cumulative_length applies) so we need to subtract here
    vec2 uv = vec2(
        (f_cumulative_length - f_quad_sdf1.x + 0.5) / (2.0 * f_linewidth * pattern_length),
        0.5 + 0.5 * f_quad_sdf1.z / f_linewidth
    );

// #ifndef DEBUG
if (!debug) {
    // discard fragments that are "more inside" the other segment to remove
    // overlap between adjacent line segments.
    float dist_in_prev = max(f_quad_sdf0, - f_discard_limit.x);
    float dist_in_next = max(f_quad_sdf2, - f_discard_limit.y);
    if (dist_in_prev < f_quad_sdf1.x || dist_in_next < f_quad_sdf1.y)
        discard;

    // sdf for inside vs outside along the line direction. extrusion makes sure
    // we include enough for a joint
    float sdf = max(f_quad_sdf1.x - f_extrusion.x, f_quad_sdf1.y - f_extrusion.y);

    // distance in linewidth direction
    sdf = max(sdf, abs(f_quad_sdf1.z) - f_linewidth);

    // outer truncation of truncated joints (smooth outside edge)
    sdf = max(sdf, f_truncation.x);
    sdf = max(sdf, f_truncation.y);

    // inner truncation (AA for overlapping parts)
    // min(a, b) keeps what is inside a and b
    // where a is the smoothly cut of part just before discard triggers (i.e. visible)
    // and b is the (smoothly) cut of part just after discard triggers (i.e not visible)
    // 100.0x sdf makes the sdf much more sharply, avoiding overdraw in the center
    sdf = max(sdf, min(f_quad_sdf1.x + 1.0, 100.0 * (f_quad_sdf1.x - f_quad_sdf0) - 1.0));
    sdf = max(sdf, min(f_quad_sdf1.y + 1.0, 100.0 * (f_quad_sdf1.y - f_quad_sdf2) - 1.0));

    // pattern application
    sdf = max(sdf, get_pattern_sdf(pattern, uv));

    // draw

    //  v- edge
    //   .---------------
    //    '.
    //      p1      v1
    //        '.   --->
    //          '----------
    // -f_quad_sdf1.x is the distance from p1, positive in v1 direction
    // f_linestart is the distance between p1 and the left edge along v1 direction
    // f_start_length.y is the distance between the edges of this segment, in v1 direction
    // so this is 0 at the left edge and 1 at the right edge (with extrusion considered)
    float factor = (-f_quad_sdf1.x - f_linestart) / f_linelength;
    color = f_color1 + factor * (f_color2 - f_color1);

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
    float sdf = max(f_quad_sdf1.x - f_extrusion.x, f_quad_sdf1.y - f_extrusion.y);
    sdf = max(sdf, abs(f_quad_sdf1.z) - f_linewidth);
    color.rgb -= vec3(0.4) * step(0.0, sdf);

    // Mark discarded space in red/blue
    float dist_in_prev = max(f_quad_sdf0, - f_discard_limit.x);
    float dist_in_next = max(f_quad_sdf2, - f_discard_limit.y);
    if (dist_in_prev < f_quad_sdf1.x)
        color.r += 0.5;
    if (dist_in_next <= f_quad_sdf1.y) {
        color.b += 0.5;
    }

    // remaining overlap as softer red/blue
    if (f_quad_sdf1.x - f_quad_sdf0 - 1.0 > 0.0)
        color.r += 0.2;
    if (f_quad_sdf1.y - f_quad_sdf2 - 1.0 > 0.0)
        color.b += 0.2;

    // Mark regions excluded via truncation in green
    color.g += 0.5 * step(0.0, max(f_truncation.x, f_truncation.y));

    // and inner truncation as softer green
    if (min(f_quad_sdf1.x + 1.0, 100.0 * (f_quad_sdf1.x - f_quad_sdf0) - 1.0) > 0.0)
        color.g += 0.2;
    if (min(f_quad_sdf1.y + 1.0, 100.0 * (f_quad_sdf1.y - f_quad_sdf2) - 1.0) > 0.0)
        color.g += 0.2;

    // mark pattern in white
    color.rgb += vec3(0.3) * step(0.0, get_pattern_sdf(pattern, uv));
// #endif
}

    write2framebuffer(color, f_id);
}
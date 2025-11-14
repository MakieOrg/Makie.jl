precision highp float;
precision highp int;

in vec4 frag_color;
in vec2 frag_uv;

#define CIRCLE            0
#define RECTANGLE         1
#define ROUNDED_RECTANGLE 2
#define DISTANCEFIELD     3
#define TRIANGLE          4

#define M_SQRT_2          1.4142135


// Half width of antialiasing smoothstep
#define ANTIALIAS_RADIUS 0.7071067811865476

in float frag_uvscale;
in float frag_distancefield_scale;
in vec4 frag_uv_offset_width;
flat in uint frag_instance_id;
in float o_clip_distance[8];
flat in vec2 f_sprite_scale;
flat in vec4 frag_strokecolor;

uniform int uniform_num_clip_planes;

// These versions of aastep assume that `dist` is a signed distance function
// which has been scaled to be in units of pixels.
float aastep(float threshold1, float dist, float aa) {
    return smoothstep(threshold1 - aa, threshold1 + aa, dist);
}

float aastep(float threshold1, float threshold2, float dist, float aa) {
    return smoothstep(threshold1 - aa, threshold1 + aa, dist) -
           smoothstep(threshold2 - aa, threshold2 + aa, dist);
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

float rectangle(vec2 uv) {
    vec2 s = f_sprite_scale / min(f_sprite_scale.x, f_sprite_scale.y);
    vec2 d = s * max(-uv, uv - vec2(1));
    return -((length(max(vec2(0.0), d)) + min(0.0, max(d.x, d.y))));
}

float rounded_rectangle(vec2 uv, vec2 tl, vec2 br){
    vec2 d = max(tl-uv, uv-br);
    return -((length(max(vec2(0.0), d)) + min(0.0, max(d.x, d.y)))-tl.x);
}

vec4 fill(vec4 fillcolor, vec4 color, vec2 uv) {
    return color;
}
vec4 fill(vec4 fillcolor, float color, vec2 uv) {
    return fillcolor;
}
vec4 fill(vec4 fillcolor, bool image, vec2 uv) { return fillcolor; }
vec4 fill(vec4 c, sampler2D image, vec2 uv) { return texture(image, uv.yx); }

void stroke(vec4 strokecolor, float signed_distance, float width, inout vec4 color, float aa_radius){
    if (width != 0.0){
        float t = aastep(min(width, 0.0), max(width, 0.0), signed_distance, aa_radius);
        vec4 bg_color = mix(color, vec4(strokecolor.rgb, 0), float(signed_distance < 0.5 * width));
        color = mix(bg_color, strokecolor, t);
    }
}

void glow(vec4 glowcolor, float signed_distance, float inside, inout vec4 color){
    float glow_width = get_glowwidth() * get_px_per_unit();
    float stroke_width = get_strokewidth() * get_px_per_unit();
    if (glow_width > 0.0){
        float outside = (abs(signed_distance) - stroke_width) / glow_width;
        float alpha = 1.0 - outside;
        color = mix(vec4(glowcolor.rgb, glowcolor.a*alpha), color, inside);
    }
}

float scaled_distancefield(sampler2D distancefield, vec2 uv){
    // Glyph distance field units are in pixels. Convert to same distance
    // scaling as f_uv.x for consistency with the procedural signed_distance
    // calculations.
    return frag_distancefield_scale * texture(distancefield, uv).r;
}

float scaled_distancefield(bool distancefield, vec2 uv){
    return 0.0;
}

// Given a fragment derivative of f_uv (i.e. dFdx(f_uv) or dFdy(f_uv)), calculate
// the associated (squared) change in the distancefield. This is effectively the
// (squared) partial derivative of the distancefield with respect to fragment
// (pixel) coordinates
float squared_partial_derivate(float center, vec2 df_uv) {
    vec2 uv1 = mix(frag_uv_offset_width.xy, frag_uv_offset_width.zw, clamp(frag_uv + 0.5 * df_uv, 0.0, 1.0));
    vec2 uv0 = mix(frag_uv_offset_width.xy, frag_uv_offset_width.zw, clamp(frag_uv - 0.5 * df_uv, 0.0, 1.0));
    // It can happen that our fragment is close to a maximum in the distancefield
    // texture. In this case the derivate based on a point to the left and right
    // can be close to 0 when it shouldn't be. To avoid this we calculate a
    // derivative to either side and take the stronger one.
    float df1 = scaled_distancefield(distancefield, uv1) - center;
    float df2 = center - scaled_distancefield(distancefield, uv0);
    return 2.0 * max(df1 * df1, df2 * df2);
}

// Calculate the anti-aliasing radius based on how much the distance field changes
// relative to neighboring samples. If the drawn quad samples the distance field
// with some distortion, it will be picked up here and compensated in changes to
// the anti-aliasing radius.
float aspect_corrected_local_aa_radius(float signed_distance) {
    return frag_uvscale * ANTIALIAS_RADIUS * M_SQRT_2 * sqrt(
        squared_partial_derivate(signed_distance, dFdx(frag_uv)) +
        squared_partial_derivate(signed_distance, dFdy(frag_uv))
    );
}

vec2 encode_uint_to_float(uint value) {
    float lower = float(value & 0xFFFFu) / 65535.0;
    float upper = float(value >> 16u) / 65535.0;
    return vec2(lower, upper);
}

vec4 pack_int(uint id, uint index) {
    vec4 unpack;
    unpack.rg = encode_uint_to_float(id);
    unpack.ba = encode_uint_to_float(index);
    return unpack;
}

void main() {
    for (int i = 0; i < uniform_num_clip_planes; i++)
        if (o_clip_distance[i] < 0.0)
            discard;

    float signed_distance = 0.0;

    vec4 uv_off = frag_uv_offset_width;
    vec2 tex_uv = mix(uv_off.xy, uv_off.zw, clamp(frag_uv, 0.0, 1.0));
    float aa_radius = ANTIALIAS_RADIUS;

    int shape = get_sdf_marker_shape();
    if(shape == CIRCLE)
        signed_distance = circle(frag_uv);
    else if(shape == DISTANCEFIELD) {
        signed_distance = scaled_distancefield(distancefield, tex_uv);
        aa_radius = aspect_corrected_local_aa_radius(signed_distance);
        if (get_strokewidth() > 0.0 || get_glowwidth() > 0.0) {
            // Compensate for the clamping of tex_uv by an approximate
            // extension of the signed distance outside the valid texture
            // region.
            vec2 bufuv = frag_uv - clamp(frag_uv, 0.0, 1.0);
            signed_distance -= length(bufuv);
        }
    } else if(shape == ROUNDED_RECTANGLE)
        signed_distance = rounded_rectangle(frag_uv, vec2(0.2), vec2(0.8));
    else if(shape == RECTANGLE)
        signed_distance = rectangle(frag_uv); // rectangle(f_uv);
    else if(shape == TRIANGLE)
        signed_distance = triangle(frag_uv);

    signed_distance *= frag_uvscale;


    float stroke_width = get_strokewidth() * get_px_per_unit();
    float inside_start = max(-stroke_width, 0.0);
    float inside = aastep(inside_start, signed_distance, aa_radius);

    vec4 final_color = fill(frag_color, uniform_color, frag_uv);
    final_color.a = final_color.a * inside;

    stroke(frag_strokecolor, signed_distance, -stroke_width, final_color, aa_radius);
    glow(get_glowcolor(), signed_distance, aastep(-stroke_width, signed_distance, aa_radius), final_color);

    // debug - show background
    // final_color.a = clamp(final_color.a, 0.0, 1.0);
    // final_color = vec4(
    //     vec3(1,0,0) * (1.0 - final_color.a) + final_color.rgb * final_color.a,
    //     0.4 + 0.6 * final_color.a
    // );

    if (picking) {
        if (final_color.a > 0.1) {
            fragment_color = pack_int(object_id, frag_instance_id);
        } else {
            discard;
        }
        return;
    }

    if (final_color.a <= 0.0){
        discard;
    }
    fragment_color = final_color;
}

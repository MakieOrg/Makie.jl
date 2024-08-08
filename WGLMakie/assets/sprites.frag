in vec4 frag_color;
in vec2 frag_uv;

#define CIRCLE            0
#define RECTANGLE         1
#define ROUNDED_RECTANGLE 2
#define DISTANCEFIELD     3
#define TRIANGLE          4

#define M_SQRT_2          1.4142135


// Half width of antialiasing smoothstep
#define ANTIALIAS_RADIUS 0.8

in float frag_uvscale;
in float frag_distancefield_scale;
in vec4 frag_uv_offset_width;
flat in uint frag_instance_id;
flat in vec2 f_sprite_scale;
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

float rectangle(vec2 uv) {
    vec2 s = f_sprite_scale / min(f_sprite_scale.x, f_sprite_scale.y);
    vec2 d = s * max(-uv, uv - vec2(1));
    return -((length(max(vec2(0.0), d)) + min(0.0, max(d.x, d.y))));
}

float rounded_rectangle(vec2 uv, vec2 tl, vec2 br){
    vec2 d = max(tl-uv, uv-br);
    return -((length(max(vec2(0.0), d)) + min(0.0, max(d.x, d.y)))-tl.x);
}

vec4 fill(vec4 fillcolor, bool image, vec2 uv) { return fillcolor; }
vec4 fill(vec4 c, sampler2D image, vec2 uv) { return texture(image, uv.yx); }

void stroke(vec4 strokecolor, float signed_distance, float width, inout vec4 color){
    if (width != 0.0){
        float t = aastep(min(width, 0.0), max(width, 0.0), signed_distance);
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

vec4 pack_int(uint id, uint index) {
    vec4 unpack;
    unpack.x = float((id & uint(0xff00)) >> 8) / 255.0;
    unpack.y = float((id & uint(0x00ff)) >> 0) / 255.0;
    unpack.z = float((index & uint(0xff00)) >> 8) / 255.0;
    unpack.w = float((index & uint(0x00ff)) >> 0) / 255.0;
    return unpack;
}

void main() {
    float signed_distance = 0.0;

    vec4 uv_off = frag_uv_offset_width;
    vec2 tex_uv = mix(uv_off.xy, uv_off.zw, clamp(frag_uv, 0.0, 1.0));

    int shape = get_shape_type();
    if(shape == CIRCLE)
        signed_distance = circle(frag_uv);
    else if(shape == DISTANCEFIELD) {
        signed_distance = scaled_distancefield(distancefield, tex_uv);
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
    float inside = aastep(inside_start, signed_distance);

    vec4 final_color = fill(frag_color, image, frag_uv);
    final_color.a = final_color.a * inside;

    stroke(get_strokecolor(), signed_distance, -stroke_width, final_color);
    glow(get_glowcolor(), signed_distance, aastep(-stroke_width, signed_distance), final_color);

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

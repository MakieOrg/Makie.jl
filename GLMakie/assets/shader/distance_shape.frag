{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}
{{SUPPORTED_EXTENSIONS}}

// Half width of antialiasing smoothstep
#define ANTIALIAS_RADIUS 0.8

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

#define CIRCLE            0
#define RECTANGLE         1
#define ROUNDED_RECTANGLE 2
#define DISTANCEFIELD     3
#define TRIANGLE          4
#define ELLIPSE           5 // maybe we can switch to this in draw_scatter?

#define M_SQRT_2          1.4142135


{{distancefield_type}}  distancefield;
{{image_type}}          image;

uniform float           stroke_width;
uniform float           glow_width;
uniform int             shape; // shape is a uniform for now. Making them a in && using them for control flow is expected to kill performance
uniform vec2            resolution;
uniform bool            transparent_picking;

flat in float           f_viewport_from_u_scale;
flat in float           f_distancefield_scale;
flat in vec4            f_color;
flat in vec4            f_bg_color;
flat in vec4            f_stroke_color;
flat in vec4            f_glow_color;
flat in uvec2           f_id;
flat in int             f_primitive_index;
in vec2                 f_uv; // f_uv.{x,y} are in the interval [-a, 1+a]
flat in vec4            f_uv_texture_bbox;
flat in vec2            f_sprite_scale;

// These versions of aastep assume that `dist` is a signed distance function
// which has been scaled to be in units of pixels.
float aastep(float threshold1, float dist) {
    return smoothstep(threshold1-ANTIALIAS_RADIUS, threshold1+ANTIALIAS_RADIUS, dist);
}

float aastep(float threshold1, float threshold2, float dist) {
    return smoothstep(threshold1-ANTIALIAS_RADIUS, threshold1+ANTIALIAS_RADIUS, dist) -
           smoothstep(threshold2-ANTIALIAS_RADIUS, threshold2+ANTIALIAS_RADIUS, dist);
}

float step2(float edge1, float edge2, float value){
    return min(step(edge1, value), 1-step(edge2, value));
}

// Procedural signed distance functions on the uv coordinate patch [0,1]x[0,1]
// Note that for antialiasing to work properly these should be *scale preserving*
// (If you must rescale uv, make sure to put the scale factor back in later.)
float triangle(vec2 P){
    P -= vec2(0.5);
    float x = M_SQRT_2 * (P.x - P.y);
    float y = M_SQRT_2 * (P.x + P.y);
    float r1 = max(abs(x), abs(y)) - 1./(2*M_SQRT_2);
    float r2 = P.y;
    return -max(r1,r2);
}
float circle(vec2 uv){
    return 0.5 - length(uv - vec2(0.5));
}
float rectangle(vec2 uv){
    vec2 s = f_sprite_scale / min(f_sprite_scale.x, f_sprite_scale.y);
    vec2 d = s * max(-uv, uv-vec2(1));
    return -((length(max(vec2(0.0), d)) + min(0.0, max(d.x, d.y))));
}
float rounded_rectangle(vec2 uv, vec2 tl, vec2 br){
    vec2 s = f_sprite_scale / min(f_sprite_scale.x, f_sprite_scale.y);
    vec2 d = s * max(tl-uv, uv-br);
    return -((length(max(vec2(0.0), d)) + min(0.0, max(d.x, d.y))) - s.x * tl.x);
}
// See https://iquilezles.org/articles/ellipsedist/
float ellipse(vec2 uv, vec2 scale)
{
    // to central coordinates, use symmetry (quarter ellipse, 0 <= p <= wh)
    vec2 wh = scale / min(scale.x, scale.y);
    vec2 p = wh * abs(uv - vec2(0.5));
    wh = wh * 0.5;

    // initial value
    vec2 q = wh * (p - wh);
    vec2 cs = normalize( (q.x<q.y) ? vec2(0.01,1) : vec2(1,0.01) );
    
    // find root with Newton solver
    for( int i=0; i<5; i++ )
    {
        vec2 u = wh * vec2( cs.x, cs.y);
        vec2 v = wh * vec2(-cs.y, cs.x);
        float a = dot(p-u,v);
        float c = dot(p-u,u) + dot(v,v);
        float b = sqrt(c*c-a*a);
        cs = vec2( cs.x*b-cs.y*a, cs.y*b+cs.x*a )/c;
    }
    
    // compute final point and distance
    float d = length(p - wh*cs);
    
    // return signed distance
    return (dot(p/wh,p/wh)>1.0) ? -d : d;
}

void fill(vec4 fillcolor, Nothing image, vec2 uv, float infill, inout vec4 color){
    color = mix(color, fillcolor, infill);
}
void fill(vec4 c, sampler2D image, vec2 uv, float infill, inout vec4 color){
    color.rgba = mix(color, texture(image, uv.yx), infill);
}
void fill(vec4 c, sampler2DArray image, vec2 uv, float infill, inout vec4 color){
    color = mix(color, texture(image, vec3(uv.yx, f_primitive_index)), infill);
}


void stroke(vec4 strokecolor, float signed_distance, float width, inout vec4 color){
    if (width != 0.0){
        float t = aastep(min(width, 0.0), max(width, 0.0), signed_distance);
        vec4 bg_color = mix(color, vec4(strokecolor.rgb, 0), float(signed_distance < 0.5 * width));
        color = mix(bg_color, strokecolor, t);
    }
}

void glow(vec4 glowcolor, float signed_distance, float inside, inout vec4 color){
    if (glow_width > 0.0){
        float outside = (abs(signed_distance)-stroke_width)/glow_width;
        float alpha = 1-outside;
        color = mix(vec4(glowcolor.rgb, glowcolor.a*alpha), color, inside);
    }
}

float get_distancefield(sampler2D distancefield, vec2 uv){
    // Glyph distance field units are in pixels. Convert to same distance
    // scaling as f_uv.x for consistency with the procedural signed_distance
    // calculations.
    return f_distancefield_scale * texture(distancefield, uv).r;
}
float get_distancefield(Nothing distancefield, vec2 uv){
    return 0.0;
}

void write2framebuffer(vec4 color, uvec2 id);

void main(){
    float signed_distance = 0.0;

    // UV coords in the texture are clamped so that they don't stray outside
    // the valid subregion of the texture atlas containing the current glyph.
    vec2 tex_uv = mix(f_uv_texture_bbox.xy, f_uv_texture_bbox.zw,
                      clamp(f_uv, 0.0, 1.0));

    if(shape == CIRCLE)
        signed_distance = circle(f_uv);
    else if(shape == DISTANCEFIELD){
        signed_distance = get_distancefield(distancefield, tex_uv);
        if (stroke_width > 0 || glow_width > 0) {
            // Compensate for the clamping of tex_uv by an approximate
            // extension of the signed distance outside the valid texture
            // region.
            vec2 bufuv = f_uv - clamp(f_uv, 0.0, 1.0);
            signed_distance -= length(bufuv);
        }
    }
    else if(shape == ROUNDED_RECTANGLE)
        signed_distance = rounded_rectangle(f_uv, vec2(0.2), vec2(0.8));
    else if(shape == RECTANGLE)
        signed_distance = rectangle(f_uv);
    else if(shape == TRIANGLE)
        signed_distance = triangle(f_uv);
    else if(shape == ELLIPSE)
        signed_distance = ellipse(f_uv, f_sprite_scale);

    // See notes in geometry shader where f_viewport_from_u_scale is computed.
    signed_distance *= f_viewport_from_u_scale;

    float inside_start = max(-stroke_width, 0.0);
    float inside = aastep(inside_start, signed_distance);
    vec4 final_color = f_bg_color;

    fill(f_color, image, tex_uv, inside, final_color);
    stroke(f_stroke_color, signed_distance, -stroke_width, final_color);
    glow(f_glow_color, signed_distance, aastep(-stroke_width, signed_distance), final_color);
    // TODO: In 3D, we should arguably discard fragments outside the sprite
    //       But note that this may interfere with object picking.
    // if (final_color == f_bg_color)
    //    discard;

    write2framebuffer(final_color, f_id);

    // Debug tools:
    // * Show the background of the sprite.
    //   write2framebuffer(mix(final_color, vec4(1,0,0,1), 0.2), f_id);
    // * Show the antialiasing border around glyphs
    //   write2framebuffer(vec4(vec3(abs(signed_distance)),1), f_id);
}

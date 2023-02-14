{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}
{{SUPPORTED_EXTENSIONS}}

struct Nothing{ //Nothing type, to encode if some variable doesn't contain any data
    bool _; //empty structs are not allowed
};

{{define_fast_path}}

layout(lines_adjacency) in;
layout(triangle_strip, max_vertices = 9) out;

in vec4 g_color[];
in float g_lastlen[];
in uvec2 g_id[];
in int g_valid_vertex[];
in float g_thickness[];

out vec4 f_color;
out vec2 f_uv;
out float f_thickness;

flat out uvec2 f_id;
out vec4 f_uv_minmax;

uniform vec2 resolution;
uniform float pattern_length;
{{pattern_type}} pattern;

float px2uv = 0.5 / pattern_length;

#define MITER_LIMIT -0.4
#define AA_THICKNESS 4

vec2 screen_space(vec4 vertex)
{
    return vec2(vertex.xy / vertex.w) * resolution;
}

// detect pattern edges in [u - 0.5w, u + 0.5w] range (u, w pixels):
// 0.0 no edge in section
// +1 rising edge in section
// -1 falling edge in section 
float pattern_edge(Nothing _, float u, float w){return 0.0;}

float pattern_edge(sampler1D pattern, float u, float w){
    float left   = texture(pattern, u - w * px2uv).x;
    float center = texture(pattern, u).x;
    float right  = texture(pattern, u + w * px2uv).x;
    // 4 if same sign right and same sign left, 0 else
    float noedge = (1 + sign(left) * sign(center)) * (1 + sign(center) * sign(right));
    return 0.25 * (4 - noedge) * sign(right - left);
}

// Get pattern values
float fetch(Nothing _, float u){return 10.0;}
float fetch(sampler1D pattern, float u){return texture(pattern, u).x;}

// For manual usage
void emit_vertex(vec2 position, vec2 uv, int index)
{
    vec4 inpos  = gl_in[index].gl_Position;
    f_uv        = uv;
    f_color     = g_color[index];
    gl_Position = vec4(position / resolution, inpos.z, inpos.w);
    f_id        = g_id[index];
    f_thickness = g_thickness[index];
    EmitVertex();
}

// for line sections
void emit_vertex(vec2 position, float v, int index, vec2 line_unit, vec2 p1)
{
    vec4 inpos = gl_in[index].gl_Position;
    // calculate distance between this vertex and line start p1 in line direction
    // Do not rely on g_lastlen[2] here, as it is not the correct distance for 
    // solid lines.
    float vertex_offset = dot(position - p1, line_unit);
    f_uv        = vec2((g_lastlen[1] + vertex_offset) * px2uv, v);
    f_color     = g_color[index];
    gl_Position = vec4(position / resolution, inpos.z, inpos.w);
    f_id        = g_id[index];
    f_thickness = g_thickness[index];
    EmitVertex();
}

out vec3 o_view_pos;
out vec3 o_normal;

void main(void)
{
    // These need to be set but don't have reasonable values here 
    o_view_pos = vec3(0);
    o_normal = vec3(0);

    // We mark each of the four vertices as valid or not. Vertices can be
    // marked invalid on input (eg, if they contain NaN). We also mark them
    // invalid if they repeat in the index buffer. This allows us to render to
    // the very ends of a polyline without clumsy buffering the position data on the
    // CPU side by repeating the first and last points via the index buffer. It
    // just requires a little care further down to avoid degenerate normals.
    bool isvalid[4] = bool[](
        g_valid_vertex[0] == 1 && g_id[0].y != g_id[1].y,
        g_valid_vertex[1] == 1,
        g_valid_vertex[2] == 1,
        g_valid_vertex[3] == 1 && g_id[2].y != g_id[3].y
    );

    if(!isvalid[1] || !isvalid[2]){
        // If one of the central vertices is invalid or there is a break in the
        // line, we don't emit anything.
        return;
    }

    // get the four vertices passed to the shader: (screen/pixel space)
    #ifdef FAST_PATH
        vec2 p0 = screen_space(gl_in[0].gl_Position);
        vec2 p1 = screen_space(gl_in[1].gl_Position);
        vec2 p2 = screen_space(gl_in[2].gl_Position);
        vec2 p3 = screen_space(gl_in[3].gl_Position);
    #else
        vec2 p0 = gl_in[0].gl_Position.xy; // start of previous segment
        vec2 p1 = gl_in[1].gl_Position.xy; // end of previous segment, start of current segment
        vec2 p2 = gl_in[2].gl_Position.xy; // end of current segment, start of next segment
        vec2 p3 = gl_in[3].gl_Position.xy; // end of next segment
    #endif

    // linewidth with padding for anti aliasing
    float thickness_aa1 = g_thickness[1] + AA_THICKNESS;
    float thickness_aa2 = g_thickness[2] + AA_THICKNESS;

    // determine the direction of each of the 3 segments (previous, current, next)
    vec2 v1 = normalize(p2 - p1);
    vec2 v0 = v1;
    vec2 v2 = v1;

    if (p1 != p0 && isvalid[0]) {
        v0 = normalize(p1 - p0);
    }
    if (p3 != p2 && isvalid[3]) {
        v2 = normalize(p3 - p2);
    }

    // determine the normal of each of the 3 segments (previous, current, next)
    vec2 n0 = vec2(-v0.y, v0.x);
    vec2 n1 = vec2(-v1.y, v1.x);
    vec2 n2 = vec2(-v2.y, v2.x);

    /*
    The goal here is to make wide line segments join cleanly. For most
    joins, it's enough to extend/contract the buffered lines into the
    "normal miter" shape below. However, this can get really spiky if the
    lines are almost anti-parallel, in which case we want the truncated
    miter. For the truncated miter, we must emit the additional triangle
    x-a-b. *
    
            normal miter               truncated miter
          ------------------*        ----------a.
                           /                   | '.
                     x    /                    x_ '.
          ------*        /           ------.     '--b
               /        /                 /        /
              /        /                 /        /
    
    Note that the way this is done below is fairly simple but results in
    overdraw for semi transparent lines. Ideally would be nice to fix that
    somehow.
    
    * This is true without anti-aliasing. With anti-aliasing our join may 
    look something like this:

        ----------c.
        ----------a.'.
                  | '.'.
                  x_ '.'.
        ------.     '--b d
             /        / /
            /        / /
        
    The thickness of the line segments is extended by AA_THICKNESS, resulting
    in vertices c and d. Using these for the triangle results in a a smaller
    padding, so we need to add further padding to it. Extruding c and d further
    is not useful, as the distance diverges as the segments become anti-parallel.
    Instead we add anothe rectangle here.
    */

    // determine miter lines by averaging the normals of the 2 segments
    vec2 miter_a = normalize(n0 + n1);    // miter at start of current segment
    vec2 miter_b = normalize(n1 + n2);    // miter at end of current segment

    // determine the length of the miter by projecting it onto normal and then inverse it
    float length_a = thickness_aa1 / dot(miter_a, n1);
    float length_b = thickness_aa2 / dot(miter_b, n1);

    // f_uv_minmax is used to overwrite the results from pattern fetches. In the
    // fragment shader we have:
    // xy.x = ifelse(f_uv.x <= f_uv_minmax.x, (f_uv.x - f_uv_minmax.y) * pattern_length, xy.x);
    // xy.x = ifelse(f_uv.x >= f_uv_minmax.z, (f_uv_minmax.w - f_uv.x) * pattern_length, xy.x);
    // i.e. f_uv_minmax.x and z control where the replacement takes place 
    // (below/above some limit) and f_uv_minmax.y and w control the respective
    // adjustments relative to the current uv index.
    // This sets the intial action to "no adjustment"
    f_uv_minmax = vec4(-1000000.0, g_lastlen[1], 1000000.0, g_lastlen[2]); 

    float u1 = g_lastlen[1] * px2uv;
    float u2 = g_lastlen[2] * px2uv;
    float pattern_at_u1 = fetch(pattern, u1).x;
    float pattern_at_u2 = fetch(pattern, u2).x;


    if( dot( v0, v1 ) < MITER_LIMIT ){
        /*
                 n1
        gap true  :  gap false
            v0    :
        . ------> :
        */

        bool gap = dot( v0, n1 ) > 0;

        /*
        With non solid lines the truncated miter join may open up gaps which we
        want to avoid:

                du  gap we want to fill when we drawn the truncated join
               |  | /  
           _.-'\    /|
        .-'     \  / |
          p1/x _ \/  |
                  \  |  <- join
         line in   \ |
                    \|
                 _.-'
             _.-'
          .-'

        (This is padded with AA_THICKNESS to make sure we can anti-alias.)

        For this we use `pattern_edge` to detect if the pattern flips between
        "on" and "off" in the (u1 - du, u1 + du) section and check the pattern
        value at u1 to make sure te edge isn't there. We want to:
        // deny join:  edge == 0,   on_marker == 0       (pattern "off" in area)
        // deny join:  egde == +-1, on_marker == either  (edge in (u1-du, u1+du))
        // draw join:  edge == 0,   on_marker == 1       (no edge and pattern "on" in area)

        u1 is the uv.x coordinate of p1/x
        du is the distance between p1 (x) and the inner corner, which is the 
        unnormalized uv distance between u1 and the uv coordinate of the corner.
        */
        #ifndef FAST_PATH
            float du = g_thickness[1] * abs(dot(n0, v1)) + AA_THICKNESS;
            float edge = pattern_edge(pattern, u1, du);
            float on_marker = float(pattern_at_u1 > 1);
            f_uv_minmax.x = 1000000.0; // always trigger
            // offset by large positive = deny
            // offset by 0 = use raw uv.x 
            f_uv_minmax.y = 1000000.0 - 1000000.0 * (1 - abs(edge)) * on_marker;
        #endif

  
        /*
        Another view of the join:

                   uv.y = 0 in line segment
                  /
                .  -- uv.x = u0 in truncated join 
              .' '.     uv.y = thickness in line segment
            .'     '.  /   uv.y = thickness + AA_THICKNESS in line segment
          .'_________'.   /_ uv.x = 0 in truncated join (constraint for AA)
        .'_____________'.  _ uv.x = -proj_AA in truncated join (derived from line segment + constraint)
        |               |  
        |_______________|  _ uv.x = -proj_AA - AA_THICKNESS in truncated join

        Here the / annotations come from the connecting line segment and are to
        be viewed on the diagonal. The -- and _ annotations are relevant to the
        truncated join and viewed vertically.
        */
        // div by pattern_length to counter normalization
        // TODO there are factors 0.5 missing in a bunch of places I think. This is AA length normalization
        float u0      = thickness_aa1 * abs(dot(miter_a, n1)) * px2uv;
        float proj_AA = AA_THICKNESS  * abs(dot(miter_a, n1)) * px2uv;

        if(gap){
            emit_vertex(p1,                                               vec2(u0,                      0),              1);
            emit_vertex(p1 + thickness_aa1 * n0,                          vec2(-proj_AA,                +thickness_aa1), 1);
            emit_vertex(p1 + thickness_aa1 * n1,                          vec2(-proj_AA,                -thickness_aa1), 1);
            emit_vertex(p1 + thickness_aa1 * n0 + AA_THICKNESS * miter_a, vec2(-proj_AA - AA_THICKNESS, +thickness_aa1), 1);
            emit_vertex(p1 + thickness_aa1 * n1 + AA_THICKNESS * miter_a, vec2(-proj_AA - AA_THICKNESS, -thickness_aa1), 1);
            EndPrimitive();
        }else{
            emit_vertex(p1,                                               vec2(u0,                      0),              1);
            emit_vertex(p1 - thickness_aa1 * n1,                          vec2(-proj_AA,                +thickness_aa1), 1);
            emit_vertex(p1 - thickness_aa1 * n0,                          vec2(-proj_AA,                -thickness_aa1), 1);
            emit_vertex(p1 - thickness_aa1 * n1 - AA_THICKNESS * miter_a, vec2(-proj_AA - AA_THICKNESS, +thickness_aa1), 1);
            emit_vertex(p1 - thickness_aa1 * n0 - AA_THICKNESS * miter_a, vec2(-proj_AA - AA_THICKNESS, -thickness_aa1), 1);
            EndPrimitive();
        }

        /*
        Here we make adjustments to the line segment to avoid the gap. Since
        this branch checks `dot(v0, v1)` we are on an outgoing line. We have
        the following situations:
        1. The pattern flips "on" in (u1-du, u1+du). In this case we want to
           hold the AA edge in this line segment, specifically in (u1+AA, u1+du). 
        2. The pattern flips "off" in (u1-du, u1+du). In this case we want to
           deny the edge here and keep it in the other segment
        3. The pattern is consistently "on" or "off" in (u1-du, u1+du). Here 
           we want to leave the pattern unchanged.

        With our edge identifier this becomes:

        if ((edge > 0) && (fetch(pattern, u).x > -1)){
            f_uv_minmax.x = g_lastlen[1] + 2 * AA_THICKNESS;
            f_uv_minmax.y = g_lastlen[1] + AA_THICKNESS;
        } else if (edge < 0) {
            f_uv_minmax.x = g_lastlen[1] + du;
            f_uv_minmax.y = 1000000.0;
        } else {
            f_uv_minmax.x = -1000000.0;
        }

        Translated to bool math:
        */
        #ifndef FAST_PATH
            f_uv_minmax.x = g_lastlen[1] + 
                float(edge > 0 && pattern_at_u1 > -1) * 2 * AA_THICKNESS +
                float(edge < 0) * du - 1000000.0 * float(edge == 0 || pattern_at_u1 < -1);
            f_uv_minmax.y = float(edge > 0) * (g_lastlen[1] + AA_THICKNESS) + 
                            float(edge < 0) * 1000000.0;
        #endif

        // Since we drew a truncated miter join the line vertices should not be
        // extruded to meet.
        miter_a = n1;
        length_a = thickness_aa1;


    } else {
        /*
        In this case the line vertices get extruded. This branch handles 
        the start of a line so for example:

                dx = g_thickness[1] * abs(dot(miter_a, v1) / dot(miter_a, n1)) (px units)
               |  |
               .---------------------
             .' \    ;
           .'.   \   :
         .'    .  x -- u1 (uv units)
                 . \ :     line out
         line in   .\:
                    .'--------------------
                  .'
                .'
        
        Here we want to achieve the following:
        1. If the pattern flips "on" in the dotted region, move the edge just
           outside the region to the right
        2. If the pattern flips "off" in the dotted region, move it outside to
           the left, i.e. don't draw it here.
        3. If the pattern is consistently "on" or "off" in the dotted region, 
           handle it as usual.

        We handle (3) by moving the detection edge `f_uv_minmax.x` outside the 
        line segment if `abs(edge) == 0`. For (1) and (2) it is moved to 
        `u1 + dx + 2*AA`.
        To handle (1) we generate an edge at `u1 + dx + AA`. Everything to the 
        left is denied (negative signed distance).
        To handle (2) we push the edge outside the region to the right, so that
        everything is denied (negative signed distance in full region)
        */
        #ifndef FAST_PATH
            float du = g_thickness[1] * abs(dot(miter_a, v1) / dot(miter_a, n1)) + AA_THICKNESS;
            float edge = pattern_edge(pattern, u1, du);
            f_uv_minmax.x = g_lastlen[1] - du + (2 * du + AA_THICKNESS) * abs(edge);
            f_uv_minmax.y = (2 - sign(edge)) * (g_lastlen[1] + du);
        #endif
    }

    if( dot( v1, v2 ) < MITER_LIMIT ) {
        // truncated miter, incoming line
        miter_b = n1;
        length_b = thickness_aa2;
        
        // Mostly analogous to the changes made to outgoing segment, see above.
        // Here the roles of rising/falling edges switches and the region in
        // question is to the right.
        #ifndef FAST_PATH
            float du = g_thickness[2] * abs(dot(n2, v1)) + AA_THICKNESS;
            float edge = pattern_edge(pattern, u2, du);

            f_uv_minmax.z = g_lastlen[2] - 
                float(edge < 0 && pattern_at_u2 > -1) * 2 * AA_THICKNESS -
                float(edge > 0) * du + 
                float(edge == 0 || pattern_at_u2 < -1) * 1000000.0;
            f_uv_minmax.w = float(edge < 0) * (g_lastlen[2] - AA_THICKNESS) +
                            -float(edge > 0) * 1000000.0;
        #endif
                    
    } else {
        // Extruded line join, incoming, compare with above
        #ifndef FAST_PATH
            float du = g_thickness[2] * abs(dot(miter_b, v1) / dot(miter_b, n1)) + AA_THICKNESS;
            float edge = pattern_edge(pattern, u2, du);
            f_uv_minmax.z = g_lastlen[2] + du - (2 * du + AA_THICKNESS) * abs(edge) ;
            f_uv_minmax.w = -sign(edge) * (g_lastlen[2] - du);
        #endif
    }

    // Force AA at line start/end (there can't be a join here)
    vec2 off_a = vec2(0);
    if (!isvalid[0]) {
        float off_marker = float(pattern_at_u1 < -1);
        f_uv_minmax.x = g_lastlen[1] + AA_THICKNESS - 10.0 * off_marker;
        f_uv_minmax.y = g_lastlen[1] - 1000000.0 * off_marker;
        off_a = float(!isvalid[0]) * AA_THICKNESS * v1;
    }

    vec2 off_b = vec2(0);
    if (!isvalid[3]) {
        // for this to work with solid lines we must not rely on g_lastlen[2], 
        // as it is in data coordinates. Instead we calculate the pixel offset
        // from g_lastlen[1] here, which matches g_lastlen[2] for non-solid lines.
        float off_marker = float(pattern_at_u2 < -1);
        f_uv_minmax.z = g_lastlen[1] + dot(p2 - p1, v1) - AA_THICKNESS + 10.0 * off_marker;
        f_uv_minmax.w = g_lastlen[1] + dot(p2 - p1, v1) - 1000000.0 * off_marker;
        off_b = float(!isvalid[3]) * AA_THICKNESS * v1;
    }

    // apply normalization (pixel -> uv)
    f_uv_minmax *= px2uv;

    // generate two triangles for the main line visualization
    // length_a/b and miter_a/b may include extrusion
    emit_vertex(p1 + length_a * miter_a - off_a, -thickness_aa1, 1, v1, p1);
    emit_vertex(p1 - length_a * miter_a - off_a,  thickness_aa1, 1, v1, p1);
    emit_vertex(p2 + length_b * miter_b + off_b, -thickness_aa2, 2, v1, p1);
    emit_vertex(p2 - length_b * miter_b + off_b,  thickness_aa2, 2, v1, p1);
    EndPrimitive();

    // reset shifting
    // f_uv_minmax = vec4(-999999, g_lastlen[1], 999999, g_lastlen[2]); 
}

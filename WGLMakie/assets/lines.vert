#version 300 es
precision mediump int;
precision highp float;
precision mediump sampler2D;
precision mediump sampler3D;

in float position;

in vec2 linepoint_prev; // start of previous segment
in vec2 linepoint_start; // end of previous segment, start of current segment
in vec2 linepoint_end; // end of current segment, start of next segment
in vec2 linepoint_next; // end of next segment

uniform vec4 is_valid; // start of previous segment

uniform vec4 color_start; // end of previous segment, start of current segment
uniform vec4 color_end; // end of current segment, start of next segment

uniform float thickness_start;
uniform float thickness_end;

uniform vec2 resolution;
uniform mat4 projectionview;
uniform mat4 model;
uniform float pattern_length;

flat out vec2 f_uv_minmax;
out vec2 f_uv;
out vec4 f_color;
out float f_thickness;

#define MITER_LIMIT -0.4
#define AA_THICKNESS 4.0

vec3 screen_space(vec2 point) {
    vec4 vertex = projectionview * model * vec4(point, 0, 1);
    return vec3(vertex.xy * resolution, vertex.z) / vertex.w;
}

// Manual uv calculation
// - position in screen space (double resolution as generally used)
// - uv with uv.u normalized (0..1), uv.v unnormalized (0..pattern_length)
void emit_vertex(vec3 position, vec2 uv, bool is_start, float thickness) {
    f_uv = uv;
    f_color = is_start ? color_start : color_end;
    gl_Position = vec4((position.xy / resolution), position.z, 1.0f);
    // linewidth scaling may shrink the effective linewidth
    f_thickness = thickness;
}

void emit_vertex(vec3 position, vec2 uv, bool is_start) {

    f_uv = uv;

    f_color = is_start ? color_start : color_end;

    gl_Position = vec4((position.xy / resolution), position.z, 1.0f);
    // linewidth scaling may shrink the effective linewidth
    f_thickness = is_start ? thickness_start : thickness_end;
}

void emit_vertex(vec3 position, vec2 offset, vec2 line_dir, vec2 uv, bool index) {
    float px2uv = 0.5f / pattern_length;
    emit_vertex(position + vec3(offset, 0), vec2(uv.x + px2uv * dot(line_dir, offset), uv.y), index, abs(uv.y) - AA_THICKNESS);
    // abs(uv.y) - AA_THICKNESS corrects for enlarged AA padding between
    // segments of different linewidth, see #2953
}

// Generate line segment with 3 triangles
// - p1, p2 are the line start and end points in pixel space
// - miter_a and miter_b are the offsets from p1 and p2 respectively that
//   generate the line segment quad. This should include thickness and AA
// - u1, u2 are the u values at p1 and p2. These should be in uv scale (px2uv applied)
// - thickness_aa1, thickness_aa2 are linewidth at p1 and p2 with AA added. They
//   double as uv.y values, which are in pixel space
// - v1 is the line direction of this segment (xy component)
void generate_line_segment(
    vec3 p1,
    vec2 miter_a,
    float u1,
    float thickness_aa1,
    vec3 p2,
    vec2 miter_b,
    float u2,
    float thickness_aa2,
    vec2 v1,
    float segment_length
) {
    float line_offset_a = dot(miter_a, v1);
    float line_offset_b = dot(miter_b, v1);

    if (abs(line_offset_a) + abs(line_offset_b) < segment_length + 1.0f) {
        //  _________
        //  \       /
        //   \_____/
        //    <--->
        // Line segment is extensive (minimum width positive)
        if (position == 5.0f) {
            emit_vertex(p1, +miter_a, v1, vec2(u1, -thickness_aa1), true);
            return;
        }
        if (position == 6.0f) {
            emit_vertex(p1, -miter_a, v1, vec2(u1, thickness_aa1), true);
            return;
        }
        if (position == 7.0f) {
            emit_vertex(p2, +miter_b, v1, vec2(u2, -thickness_aa2), false);
            return;
        }
        if (position == 8.0f) {
            emit_vertex(p2, -miter_b, v1, vec2(u2, thickness_aa2), false);
            return;
        }

    } else {
        /*
           \  /
            \/
            /\
           >--<
        Line segment has zero or negative width on short side

        Pulled apart, we draw these two triangles (vertical lines added)
        ___      ___
        \  |    |  /
         X |    | X
          \|    |/

        where X is u1/p1 (left) and u2/p2 (right) respectively. To avoid
        drawing outside the line segment due to AA padding, we cut off the
        left triangle on the right side at u2 via f_uv_minmax.y, and
        analogously the right triangle at u1 via f_uv_minmax.x.
        These triangles will still draw over each other like this.
        */

        // incoming side
        float old = f_uv_minmax.y;
        f_uv_minmax.y = u2;
        if (position == 5.0f) {
            emit_vertex(p1, -miter_a, v1, vec2(u1, -thickness_aa1), true);
            return;
        }
        if (position == 6.0f) {
            emit_vertex(p1, +miter_a, v1, vec2(u1, +thickness_aa1), true);
            return;
        }
        if (position == 7.0f) {
            if (line_offset_a > 0.0f) { // finish triangle on -miter_a side
                emit_vertex(p1, 2.0f * line_offset_a * v1 - miter_a, v1, vec2(u1, -thickness_aa1), true);
            } else {
                emit_vertex(p1, -2.0f * line_offset_a * v1 + miter_a, v1, vec2(u1, +thickness_aa1), true);
            }
            return;
        }

        // outgoing side
        f_uv_minmax.x = u1;
        f_uv_minmax.y = old;
        if (position == 8.0f) {
            emit_vertex(p2, -miter_b, v1, vec2(u2, -thickness_aa2), false);
            return;
        }
        if (position == 9.0f) {
            emit_vertex(p2, +miter_b, v1, vec2(u2, +thickness_aa2), false);
            return;
        }

        if (line_offset_b < 0.0f) { // finish triangle on -miter_b side
            emit_vertex(p2, 2.0f * line_offset_b * v1 - miter_b, v1, vec2(u2, -thickness_aa2), false);
        } else {
            emit_vertex(p2, -2.0f * line_offset_b * v1 + miter_b, v1, vec2(u2, +thickness_aa2), false);
        }
        return;
    }
}

void main() {
    float px2uv = 0.5f / pattern_length;

    bvec4 _isvalid = bvec4(true, true, true, true);

    // This sets a min and max value foir uv.u at which anti-aliasing is forced.
    // With this setting it's never triggered.
    f_uv_minmax = vec2(-1.0e12f, 1.0e12f);

    // get the four vertices passed to the shader
    // without FAST_PATH the conversions happen on the CPU
    vec3 p0 = screen_space(linepoint_prev); // start of previous segment
    vec3 p1 = screen_space(linepoint_start); // end of previous segment, start of current segment
    vec3 p2 = screen_space(linepoint_end); // end of current segment, start of next segment
    vec3 p3 = screen_space(linepoint_next); // end of next segment

    // determine the direction of each of the 3 segments (previous, current, next)
    vec3 v1 = p2 - p1;
    float segment_length = length(v1.xy);
    v1 /= segment_length;
    vec3 v0 = v1;
    vec3 v2 = v1;

    if (p1 != p0 && _isvalid.x) {
        v0 = (p1 - p0) / length((p1 - p0).xy);
    }
    if (p3 != p2 && _isvalid.w) {
        v2 = (p3 - p2) / length((p3 - p2).xy);
    }

    // determine the normal of each of the 3 segments (previous, current, next)
    vec2 n0 = vec2(-v0.y, v0.x);
    vec2 n1 = vec2(-v1.y, v1.x);
    vec2 n2 = vec2(-v2.y, v2.x);

    // determine stretching of AA border due to linewidth change
    float temp = (thickness_end - thickness_start) / segment_length;
    float edge_scale = sqrt(1.0f + temp * temp);

    // linewidth with padding for anti aliasing (used for geometry)
    float thickness_aa1 = thickness_start + edge_scale * AA_THICKNESS;
    float thickness_aa2 = thickness_end + edge_scale * AA_THICKNESS;

    // Setup for sharp corners (see above)
    vec2 miter_a = normalize(n0 + n1);
    vec2 miter_b = normalize(n1 + n2);
    float length_a = thickness_aa1 / dot(miter_a, n1);
    float length_b = thickness_aa2 / dot(miter_b, n1);

    // truncated miter join (see above)
    if (dot(v0.xy, v1.xy) < MITER_LIMIT) {
        bool gap = dot(v0.xy, n1) > 0.0f;
        // In this case uv's are used as signed distance field values, so we
        // want 0 where we had start before.
        float u0 = thickness_aa1 * abs(dot(miter_a, n1)) * px2uv;
        float proj_AA = AA_THICKNESS * abs(dot(miter_a, n1)) * px2uv;

        // to save some space
        vec2 off0 = thickness_aa1 * n0;
        vec2 off1 = thickness_aa1 * n1;
        vec2 off_AA = AA_THICKNESS * miter_a;
        float u_AA = AA_THICKNESS * px2uv;

        if (gap) {
            if (position == 0.0f) {
                emit_vertex(p1, vec2(+u0, 0.0f), true);
                return;
            }
            if (position == 1.0f) {
                emit_vertex(p1 + vec3(off0, 0), vec2(-proj_AA, +thickness_aa1), true);
                return;
            }
            if (position == 2.0f) {
                emit_vertex(p1 + vec3(off1, 0), vec2(-proj_AA, -thickness_aa1), true);
                return;
            }
            if (position == 3.0f) {
                emit_vertex(p1 + vec3(off0 + off_AA, 0), vec2(-proj_AA - u_AA, +thickness_aa1), true);
                return;
            }
            if (position == 4.0f) {
                emit_vertex(p1 + vec3(off1 + off_AA, 0), vec2(-proj_AA - u_AA, -thickness_aa1), true);
                return;
            }
        } else {
            if (position == 0.0f) {
                emit_vertex(p1, vec2(+u0, 0), true);
                return;
            }
            if (position == 1.0f) {
                emit_vertex(p1 - vec3(off1, 0), vec2(-proj_AA, +thickness_aa1), true);
                return;
            }
            if (position == 2.0f) {
                emit_vertex(p1 - vec3(off0, 0), vec2(-proj_AA, -thickness_aa1), true);
                return;
            }
            if (position == 3.0f) {
                emit_vertex(p1 - vec3(off1 + off_AA, 0), vec2(-proj_AA - u_AA, +thickness_aa1), true);
                return;
            }
            if (position == 4.0f) {
                emit_vertex(p1 - vec3(off0 + off_AA, 0), vec2(-proj_AA - u_AA, -thickness_aa1), true);
                return;
            }
        }

        miter_a = n1;
        length_a = thickness_aa1;
    }

    // we have miter join on next segment, do normal line cut off
    if (dot(v1.xy, v2.xy) <= MITER_LIMIT) {
        miter_b = n1;
        length_b = thickness_aa2;
    }

    // Without a pattern (linestyle) we use uv.u directly as a signed distance
    // field. We only care about u1 - u0 being the correct distance and
    // u0 > AA_THICHKNESS at all times.
    float u1 = 10000.0f;
    float u2 = u1 + segment_length;

    miter_a *= length_a;
    miter_b *= length_b;

    // To treat line starts and ends we elongate the line in the respective
    // direction and enforce an AA border at the original start/end position
    // with f_uv_minmax.
    if (!_isvalid.x) {
        float corner_offset = max(0.0f, abs(dot(miter_b, v1.xy)) - segment_length);
        f_uv_minmax.x = px2uv * (u1 - corner_offset);
        p1 -= (corner_offset + AA_THICKNESS) * v1;
        u1 -= (corner_offset + AA_THICKNESS);
        segment_length += corner_offset;
    }

    if (!_isvalid.w) {
        float corner_offset = max(0.0f, abs(dot(miter_a, v1.xy)) - segment_length);
        f_uv_minmax.y = px2uv * (u2 + corner_offset);
        p2 += (corner_offset + AA_THICKNESS) * v1;
        u2 += (corner_offset + AA_THICKNESS);
        segment_length += corner_offset;
    }

    // scaling of uv.y due to different linewidths
    // the padding for AA_THICKNESS should always have AA_THICKNESS width in uv
    thickness_aa1 = thickness_start / edge_scale + AA_THICKNESS;
    thickness_aa2 = thickness_end / edge_scale + AA_THICKNESS;

    // Generate line segment
    u1 *= px2uv;
    u2 *= px2uv;

    // Normal Version
    generate_line_segment(p1, miter_a, u1, thickness_aa1, p2, miter_b, u2, thickness_aa2, v1.xy, segment_length);

    return;
}

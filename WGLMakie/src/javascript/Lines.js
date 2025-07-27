import {
    attributes_to_type_declaration,
    uniforms_to_type_declaration,
    uniform_type,
    attribute_type,
} from "./ThreeHelper.js";

import { is_typed_array } from "./Serialization.js";

function filter_by_key(dict, keys, default_value = false) {
    const result = {};
    keys.forEach((key) => {
        const val = dict[key];
        if (val) {
            result[key] = val;
        } else {
            result[key] = default_value;
        }
    });
    return result;
}

// https://github.com/glslify/glsl-aastep
// https://wwwtyro.net/2019/11/18/instanced-lines.html
// https://github.com/mrdoob/three.js/blob/dev/examples/jsm/lines/LineMaterial.js
// https://www.khronos.org/assets/uploads/developers/presentations/Crazy_Panda_How_to_draw_lines_in_WebGL.pdf
// https://github.com/gameofbombs/pixi-candles/tree/master/src
// https://github.com/wwwtyro/instanced-lines-demos/tree/master
function lines_vertex_shader(uniforms, attributes, is_linesegments) {
    const attribute_decl = attributes_to_type_declaration(attributes);
    const uniform_decl = uniforms_to_type_declaration(uniforms);
    const color =
        attribute_type(attributes.line_color_start) ||
        uniform_type(uniforms.line_color_start);

    if (is_linesegments) {
        ////////////////////////////////////////////////////////////////////////
        /// Linessegments
        ////////////////////////////////////////////////////////////////////////

        return `precision highp float;
            precision highp int;

            ${attribute_decl}

            out vec3 f_quad_sdf;
            out vec2 f_truncation;              // invalid / not needed
            out float f_linestart;              // constant
            out float f_linelength;

            flat out vec2 f_extrusion;          // invalid / not needed
            flat out float f_linewidth;
            flat out vec4 f_pattern_overwrite;  // invalid / not needed
            flat out uint f_instance_id;
            flat out ${color} f_color1;
            flat out ${color} f_color2;
            flat out float f_alpha_weight;
            flat out float f_cumulative_length;
            flat out ivec2 f_capmode;
            flat out vec4 f_linepoints;         // invalid / not needed
            flat out vec4 f_miter_vecs;         // invalid / not needed

            ${uniform_decl}
            uniform vec4 uniform_clip_planes[8];

            // Constants
            const float AA_RADIUS = 0.8;
            const float AA_THICKNESS = 2.0 * AA_RADIUS;


            ////////////////////////////////////////////////////////////////////////
            // Geometry/Position Utils
            ////////////////////////////////////////////////////////////////////////

            vec4 clip_space(vec3 point) {
                return projectionview * model_f32c * vec4(point, 1);
            }
            vec4 clip_space(vec2 point) { return clip_space(vec3(point, 0)); }

            vec3 screen_space(vec4 vertex) {
                return vec3(
                    (0.5 * vertex.xy / vertex.w + 0.5) * px_per_unit * resolution,
                    vertex.z / vertex.w + depth_shift
                );
            }

            vec2 normal_vector(in vec2 v) { return vec2(-v.y, v.x); }
            vec2 normal_vector(in vec3 v) { return vec2(-v.y, v.x); }

            void process_clip_planes(inout vec4 p1, inout vec4 p2)
            {
                float d1, d2;
                for (int i = 0; i < int(uniform_num_clip_planes); i++) {
                    // distance from clip planes with negative clipped
                    d1 = dot(p1.xyz, uniform_clip_planes[i].xyz) - uniform_clip_planes[i].w * p1.w;
                    d2 = dot(p2.xyz, uniform_clip_planes[i].xyz) - uniform_clip_planes[i].w * p2.w;

                    // both outside - clip everything
                    if (d1 < 0.0 && d2 < 0.0) {
                        p2 = p1;
                        return;
                    }

                    // one outside - shorten segment
                    else if (d1 < 0.0)
                    {
                        // solve 0 = m * t + b = (d2 - d1) * t + d1 with t in (0, 1)
                        p1       = p1       - d1 * (p2 - p1)             / (d2 - d1);
                        f_color1 = f_color1 - d1 * (f_color2 - f_color1) / (d2 - d1);
                    }
                    else if (d2 < 0.0)
                    {
                        p2       = p2       - d2 * (p1 - p2)             / (d1 - d2);
                        f_color2 = f_color2 - d2 * (f_color1 - f_color2) / (d1 - d2);
                    }
                }

                return;
            }


            ////////////////////////////////////////////////////////////////////////
            // Main
            ////////////////////////////////////////////////////////////////////////


            void main() {
                bool is_end = position.x == 1.0;

                ////////////////////////////////////////////////////////////////////
                // Handle line geometry (position, directions)
                ////////////////////////////////////////////////////////////////////


                float width = px_per_unit * (is_end ? uniform_linewidth_end : uniform_linewidth_start);
                float halfwidth = 0.5 * max(AA_RADIUS, width);

                // color at line start/end for interpolation
                f_color1 = line_color_start;
                f_color2 = line_color_end;

                // restrict to visible area (see other shader)
                vec3 p1, p2;
                {
                    vec4 _p1 = clip_space(positions_transformed_f32c_start), _p2 = clip_space(positions_transformed_f32c_end);

                    vec4 v1 = _p2 - _p1;

                    if (_p1.w < 0.0) {
                        _p1 = _p1 + (-_p1.w - _p1.z) / (v1.z + v1.w) * v1;
                        f_color1 = f_color1 + (-_p1.w - _p1.z) / (v1.z + v1.w) * (f_color2 - f_color1);
                    }
                    if (_p2.w < 0.0) {
                        _p2 = _p2 + (-_p2.w - _p2.z) / (v1.z + v1.w) * v1;
                        f_color2 = f_color2 + (-_p2.w - _p2.z) / (v1.z + v1.w) * (f_color2 - f_color1);
                    }

                    // Shorten segments to fit clip planes
                    // returns true if segments are fully clipped
                    process_clip_planes(_p1, _p2);

                    p1 = screen_space(_p1);
                    p2 = screen_space(_p2);
                }

                // line vector (xy-normalized vectors in line direction)
                // Need z component for correct depth order
                vec3 v1 = p2 - p1;
                float segment_length = length(v1);
                v1 /= segment_length;

                // line normal (i.e. in uniform_linewidth direction)
                vec2 n1 = normal_vector(v1);


                ////////////////////////////////////////////////////////////////////
                // Static vertex data
                ////////////////////////////////////////////////////////////////////


                // invalid - no joints requiring uniform_pattern adjustments
                f_pattern_overwrite = vec4(-1e12, 1.0, 1e12, 1.0);

                // invalid - no joints requiring line sdfs to be extruded
                f_extrusion = vec2(0.0);

                // used to compute width sdf
                f_linewidth = halfwidth;

                f_instance_id = lineindex_start + uint(1); // NOTE: this is correct, no need to multiple by 2

                // we restart patterns for each segment
                f_cumulative_length = 0.0;

                // no joints means these should be set to a "never discard" state
                f_linepoints = vec4(-1e12);
                f_miter_vecs = vec4(-1);


                ////////////////////////////////////////////////////////////////////
                // Varying vertex data
                ////////////////////////////////////////////////////////////////////

                // linecaps
                f_capmode = ivec2(linecap);

                // Vertex position (padded for joint & anti-aliasing)
                float v_offset = position.x * (0.5 * segment_length + halfwidth + AA_THICKNESS);
                float n_offset = (halfwidth + AA_THICKNESS) * position.y;
                vec3 point = 0.5 * (p1 + p2) + v_offset * v1 + n_offset * vec3(n1, 0);

                // SDF's
                vec2 VP1 = point.xy - p1.xy;
                vec2 VP2 = point.xy - p2.xy;

                // sdf of this segment
                f_quad_sdf.x = dot(VP1, -v1.xy);
                f_quad_sdf.y = dot(VP2,  v1.xy);
                f_quad_sdf.z = dot(VP1,  n1);

                // invalid - no joint to truncate
                f_truncation = vec2(-1e12);

                // simplified - no extrusion or joints means we just have:
                f_linestart = 0.0;
                f_linelength = segment_length;

                // for thin lines
                f_alpha_weight = min(1.0, width / AA_RADIUS);

                // clip space position
                gl_Position = vec4(2.0 * point.xy / (px_per_unit * resolution) - 1.0, point.z, 1.0);
            }
        `;

    } else {
        ////////////////////////////////////////////////////////////////////////
        /// Lines
        ////////////////////////////////////////////////////////////////////////

        return `precision highp float;
            precision highp int;

            ${attribute_decl}

            out vec3 f_quad_sdf;
            out vec2 f_truncation;
            out float f_linestart;
            out float f_linelength;

            flat out vec2 f_extrusion;
            flat out float f_linewidth;
            flat out vec4 f_pattern_overwrite;
            flat out uint f_instance_id;
            flat out ${color} f_color1;
            flat out ${color} f_color2;
            flat out float f_alpha_weight;
            flat out float f_cumulative_length;
            flat out ivec2 f_capmode;
            flat out vec4 f_linepoints;
            flat out vec4 f_miter_vecs;

            ${uniform_decl}
            uniform vec4 uniform_clip_planes[8];

            // Constants
            const float AA_RADIUS = 0.8;
            const float AA_THICKNESS = 2.0 * AA_RADIUS;
            const int BUTT   = 0;
            const int SQUARE = 1;
            const int ROUND  = 2;
            const int MITER  = 0;
            const int BEVEL  = 3;


            ////////////////////////////////////////////////////////////////////////
            // Pattern handling
            ////////////////////////////////////////////////////////////////////////


            vec2 process_pattern(bool uniform_pattern, bool[4] isvalid, vec2 extrusion, float segment_length, float halfwidth) {
                // do not adjust stuff
                f_pattern_overwrite = vec4(-1e12, 1.0, 1e12, 1.0);
                return vec2(0);
            }

            vec2 process_pattern(sampler2D uniform_pattern, bool[4] isvalid, vec2 extrusion, float segment_length, float halfwidth) {
                // samples:
                //   -ext1  p1 ext1    -ext2 p2 ext2
                //      1   2   3        4   5   6
                // prev | joint |  this  | joint | next

                // default to no overwrite
                f_pattern_overwrite.x = -1e12;
                f_pattern_overwrite.z = +1e12;
                vec2 adjust = vec2(0);
                float width = 2.0 * halfwidth;
                float uv_scale = 1.0 / (width * uniform_pattern_length);
                float left, center, right;

                if (isvalid[0]) {
                    float offset = abs(extrusion[0]);
                    left   = width * texture(uniform_pattern, vec2(uv_scale * (px_per_unit * lastlen_start - offset), 0.0)).x;
                    center = width * texture(uniform_pattern, vec2(uv_scale * (px_per_unit * lastlen_start         ), 0.0)).x;
                    right  = width * texture(uniform_pattern, vec2(uv_scale * (px_per_unit * lastlen_start + offset), 0.0)).x;

                    // cases:
                    // ++-, +--, +-+ => elongate backwards
                    // -++, --+      => shrink forward
                    // +++, ---, -+- => freeze around joint

                    if ((left > 0.0 && center > 0.0 && right > 0.0) || (left < 0.0 && right < 0.0)) {
                        // default/freeze
                        // overwrite until one AA gap past the corner/joint
                        f_pattern_overwrite.x = uv_scale * (px_per_unit * lastlen_start + abs(extrusion[0]) + AA_RADIUS);
                        // using the sign of the center to decide between drawing or not drawing
                        f_pattern_overwrite.y = sign(center);
                    } else if (left > 0.0) {
                        // elongate backwards
                        adjust.x = -1.0;
                    } else if (right > 0.0) {
                        // shorten forward
                        adjust.x = 1.0;
                    } else {
                        // default - see above
                        f_pattern_overwrite.x = uv_scale * (px_per_unit * lastlen_start + abs(extrusion[0]) + AA_RADIUS);
                        f_pattern_overwrite.y = sign(center);
                    }

                } // else there is no left segment, no left join, so no overwrite

                if (isvalid[3]) {
                    float offset = abs(extrusion[1]);
                    left   = width * texture(uniform_pattern, vec2(uv_scale * (px_per_unit * lastlen_start + segment_length - offset), 0.0)).x;
                    center = width * texture(uniform_pattern, vec2(uv_scale * (px_per_unit * lastlen_start + segment_length         ), 0.0)).x;
                    right  = width * texture(uniform_pattern, vec2(uv_scale * (px_per_unit * lastlen_start + segment_length + offset), 0.0)).x;

                    if ((left > 0.0 && center > 0.0 && right > 0.0) || (left < 0.0 && right < 0.0)) {
                        // default/freeze
                        f_pattern_overwrite.z = uv_scale * (px_per_unit * lastlen_start + segment_length - abs(extrusion[1]) - AA_RADIUS);
                        f_pattern_overwrite.w = sign(center);
                    } else if (left > 0.0) {
                        // shrink backwards
                        adjust.y = -1.0;
                    } else if (right > 0.0) {
                        // elongate forward
                        adjust.y = 1.0;
                    } else {
                        // default - see above
                        f_pattern_overwrite.z = uv_scale * (px_per_unit * lastlen_start + segment_length - abs(extrusion[1]) - AA_RADIUS);
                        f_pattern_overwrite.w = sign(center);
                    }
                }

                return adjust;
            }


            ////////////////////////////////////////////////////////////////////////
            // Geometry/Position Utils
            ////////////////////////////////////////////////////////////////////////

            vec4 clip_space(vec3 point) {
                return projectionview * model_f32c * vec4(point, 1);
            }
            vec4 clip_space(vec2 point) { return clip_space(vec3(point, 0)); }

            vec3 screen_space(vec4 vertex) {
                return vec3(
                    (0.5 * vertex.xy / vertex.w + 0.5) * px_per_unit * resolution,
                    vertex.z / vertex.w + depth_shift
                );
            }

            vec2 normal_vector(in vec2 v) { return vec2(-v.y, v.x); }
            vec2 normal_vector(in vec3 v) { return vec2(-v.y, v.x); }
            float sign_no_zero(float value) { return value >= 0.0 ? 1.0 : -1.0; }

            void process_clip_planes(inout vec4 p1, inout vec4 p2, inout bool[4] isvalid)
            {
                float d1, d2;
                for(int i = 0; i < int(uniform_num_clip_planes); i++)
                {
                    // distance from clip planes with negative clipped
                    d1 = dot(p1.xyz, uniform_clip_planes[i].xyz) - uniform_clip_planes[i].w * p1.w;
                    d2 = dot(p2.xyz, uniform_clip_planes[i].xyz) - uniform_clip_planes[i].w * p2.w;

                    // both outside - clip everything
                    if (d1 < 0.0 && d2 < 0.0) {
                        p2 = p1;
                        isvalid[1] = false;
                        isvalid[2] = false;
                        return;
                    // one outside - shorten segment
                    } else if (d1 < 0.0) {
                        // solve 0 = m * t + b = (d2 - d1) * t + d1 with t in (0, 1)
                        p1       = p1       - d1 * (p2 - p1)             / (d2 - d1);
                        f_color1 = f_color1 - d1 * (f_color2 - f_color1) / (d2 - d1);
                        isvalid[0] = false;
                    } else if (d2 < 0.0) {
                        p2       = p2       - d2 * (p1 - p2)             / (d1 - d2);
                        f_color2 = f_color2 - d2 * (f_color1 - f_color2) / (d1 - d2);
                        isvalid[3] = false;
                    }
                }

                return;
            }

            ////////////////////////////////////////////////////////////////////////
            // Main
            ////////////////////////////////////////////////////////////////////////

            void main() {
                bool is_end = position.x == 1.0;


                ////////////////////////////////////////////////////////////////////
                // Handle line geometry (position, directions)
                ////////////////////////////////////////////////////////////////////


                float width = px_per_unit * (is_end ? uniform_linewidth_end : uniform_linewidth_start);
                float halfwidth = 0.5 * max(AA_RADIUS, width);

                bool[4] isvalid = bool[4](true, true, true, true);

                // color at start/end of segment
                f_color1 = line_color_start;
                f_color2 = line_color_end;

                // To apply pixel space linewidths we transform line vertices to pixel space
                // here. This is dangerous with perspective projection as p.xyz / p.w sends
                // points from behind the camera to beyond far (clip z > 1), causing lines
                // to invert. To avoid this we translate points along the line direction,
                // moving them to the edge of the visible area.
                vec3 p0, p1, p2, p3;
                {
                    // All in clip space
                    vec4 clip_p0 = clip_space(positions_transformed_f32c_prev);
                    vec4 clip_p1 = clip_space(positions_transformed_f32c_start);
                    vec4 clip_p2 = clip_space(positions_transformed_f32c_end);
                    vec4 clip_p3 = clip_space(positions_transformed_f32c_next);

                    vec4 v1 = clip_p2 - clip_p1;

                    // With our perspective projection matrix clip.w = -view.z with
                    // clip.w < 0.0 being behind the camera.
                    // Note that if the signs in the projectionmatrix change, this may become wrong.
                    if (clip_p1.w < 0.0) {
                        // the line connects outside the visible area so we may consider it disconnected
                        isvalid[0] = false;
                        // A clip position is visible if -w <= z <= w. To move the line along
                        // the line direction v to the start of the visible area, we solve:
                        //   p.z + t * v.z = +-(p.w + t * v.w)
                        // where (-) gives us the result for the near clipping plane as p.z
                        // and p.w share the same sign and p.z/p.w = -1.0 is the near plane.
                        clip_p1 = clip_p1 + (-clip_p1.w - clip_p1.z) / (v1.z + v1.w) * v1;
                        f_color1 = f_color1 + (-clip_p1.w - clip_p1.z) / (v1.z + v1.w) * (f_color2 - f_color1);
                    }
                    if (clip_p2.w < 0.0) {
                        isvalid[3] = false;
                        clip_p2 = clip_p2 + (-clip_p2.w - clip_p2.z) / (v1.z + v1.w) * v1;
                        f_color2 = f_color2 + (-clip_p2.w - clip_p2.z) / (v1.z + v1.w) * (f_color2 - f_color1);
                    }

                    // Shorten segments to fit clip planes
                    // returns true if segments are fully clipped
                    process_clip_planes(clip_p1, clip_p2, isvalid);

                    // transform clip -> screen space, applying xyz / w normalization (which
                    // is now save as all vertices are in front of the camera)
                    p0 = screen_space(clip_p0); // start of previous segment
                    p1 = screen_space(clip_p1); // end of previous segment, start of current segment
                    p2 = screen_space(clip_p2); // end of current segment, start of next segment
                    p3 = screen_space(clip_p3); // end of next segment
                }

                // doesn't work correctly with linepoint_x...
                isvalid[0] = p0 != p1;
                isvalid[3] = p2 != p3;

                // line vectors (xy-normalized vectors in line direction)
                // Need z component here for correct depth order
                vec3 v1 = p2 - p1;
                float segment_length = length(v1);
                v1 /= segment_length;

                // We don't need the z component for these
                vec2 v0 = v1.xy, v2 = v1.xy;
                bool[2] skip_joint;
                if (isvalid[0])
                    v0 = normalize(p1.xy - p0.xy);
                if (isvalid[3])
                    v2 = normalize(p3.xy - p2.xy);

                // line normals (i.e. in uniform_linewidth direction)
                vec2 n0 = normal_vector(v0);
                vec2 n1 = normal_vector(v1);
                vec2 n2 = normal_vector(v2);


                ////////////////////////////////////////////////////////////////////
                // Handle joint geometry
                ////////////////////////////////////////////////////////////////////


                // joint information

                // Miter normals (normal of truncated edge / vector to sharp corner)
                // Note: n0 + n1 = vec(0) for a 180° change in direction. +-(v0 - v1) is the
                //       same direction, but becomes vec(0) at 0°, so we can use it instead
                vec2 miter = vec2(dot(v0, v1.xy), dot(v1.xy, v2));
                vec2 miter_n1 = miter.x < -0.0 ?
                    sign_no_zero(dot(v0.xy, n1)) * normalize(v0.xy - v1.xy) : normalize(n0 + n1);
                vec2 miter_n2 = miter.y < -0.0 ?
                    sign_no_zero(dot(v1.xy, n2)) * normalize(v1.xy - v2.xy) : normalize(n1 + n2);

                // Are we truncating the joint based on miter limit or joinstyle?
                // bevel / always truncate doesn't work with v1 == v2 (v0) so we use allow
                // miter joints a when v1 ≈ v2 (v0)
                bool[2] is_truncated = bool[2](
                    (int(joinstyle) == BEVEL) ? miter.x < 0.99 : miter.x < miter_limit,
                    (int(joinstyle) == BEVEL) ? miter.y < 0.99 : miter.y < miter_limit
                );

                // miter vectors (line vector matching miter normal)
                vec2 miter_v1 = -normal_vector(miter_n1);
                vec2 miter_v2 = -normal_vector(miter_n2);

                // distance between p1/2 and respective sharp corner
                float miter_offset1 = dot(miter_n1, n1); // = dot(miter_v1, v1)
                float miter_offset2 = dot(miter_n2, n1); // = dot(miter_v2, v1)

                // How far the line needs to extend to accomodate the joint.
                // These are calculated as prefactors to v1 so that the line quad
                // is given by:
                //      p1 + w * extrusion[0] * v1  -----  p2 + w * extrusion[1] * v1
                //                |                                 |
                //      p1 + w * extrusion[0] * v1  -----  p2 + w * extrusion[1] * v1
                // with w = halfwidth for drawn corners and w = halfwidth + AA_THICKNESS
                // for the corners of quad. The sign difference due to miter joints
                // is included based on the current vertex position (position.y).
                // (truncated miter joints do not differ here)
                vec2 extrusion;

                if (is_truncated[0]) {
                    // need to extend segment to include previous segments corners for truncated join
                    extrusion[0] = -abs(miter_offset1 / dot(miter_v1, n1));
                } else {
                    // shallow/spike join needs to include point where miter normal meets outer line edge
                    extrusion[0] = position.y * dot(miter_n1, v1.xy) / miter_offset1;
                }

                if (is_truncated[1]) {
                    extrusion[1] = abs(miter_offset2 / dot(miter_n2, v1.xy));
                } else {
                    extrusion[1] = position.y * dot(miter_n2, v1.xy) / miter_offset2;
                }


                ////////////////////////////////////////////////////////////////////
                // Joint adjustments
                ////////////////////////////////////////////////////////////////////


                // Miter joints can cause vertices to move past each other, e.g.
                //  _______
                //  '.   .'
                //     x
                //   '---'
                // To avoid drawing the "inverted" section we move the relevant
                // vertices to the crossing point (x) using this scaling factor.
                // TODO: skipping this for linestart/end avoid round and square
                //       being cut off but causes overlap...
                float shape_factor = 1.0;
                if ((isvalid[0] && isvalid[3]) || (int(linecap) == BUTT))
                    shape_factor = segment_length / max(segment_length,
                        (halfwidth + AA_THICKNESS) * (extrusion[0] - extrusion[1]));

                // If a uniform_pattern starts or stops drawing in a joint it will get
                // fractured across the joint. To avoid this we either:
                // - adjust the involved line segments so that the patterns ends
                //   on straight line quad (adjustment becomes +1.0 or -1.0)
                // - or adjust the uniform_pattern to start/stop outside of the joint
                //   (f_pattern_overwrite is set, adjustment is 0.0)
                vec2 adjustment = process_pattern(
                    uniform_pattern, isvalid, halfwidth * extrusion, segment_length, halfwidth
                );

                // If adjustment != 0.0 we replace a joint by an extruded line,
                // so we no longer need to shrink the line for the joint to fit.
                if (adjustment[0] != 0.0 || adjustment[1] != 0.0)
                    shape_factor = 1.0;

                ////////////////////////////////////////////////////////////////////
                // Static vertex data
                ////////////////////////////////////////////////////////////////////

                // For truncated miter joints we discard overlapping sections of the two
                // involved line segments. To identify which sections overlap we calculate
                // the signed distance in +- miter vector direction from the shared line
                // point in fragment shader. We pass the necessary data here. If we do not
                // have a truncated joint we adjust the data here to never discard.
                // Why not calculate the sdf here?
                // If we calculate the sdf here and pass it as an interpolated vertex output
                // the values we get between the two line segments will differ since the
                // the vertices each segment interpolates from differ. This causes the
                // discard check to rarely be true or false for both segments, resulting in
                // duplicated or missing pixel/fragment draw.
                // Passing the line point and miter vector instead should fix this issue,
                // because both of these values come from the same calculation between the
                // two segments. I.e. (previous segment).p2 == (next segment).p1 and
                // (previous segment).miter_v2 == (next segment).miter_v1 should be the case.
                if (isvalid[0] && is_truncated[0] && (adjustment[0] == 0.0)) {
                    f_linepoints.xy = p1.xy + px_per_unit * scene_origin;   // FragCoords are relative to the window
                    f_miter_vecs.xy = -miter_v1.xy;                         // but p1/p2 is relative to the scene origin
                } else {
                    f_linepoints.xy = vec2(-1e12);          // FragCoord > 0
                    f_miter_vecs.xy = normalize(vec2(-1));
                }
                if (isvalid[3] && is_truncated[1] && (adjustment[1] == 0.0)) {
                    f_linepoints.zw = p2.xy + px_per_unit * scene_origin;
                    f_miter_vecs.zw = miter_v2.xy;
                } else {
                    f_linepoints.zw = vec2(-1e12);
                    f_miter_vecs.zw = normalize(vec2(-1));
                }

                // Used to elongate sdf to include joints
                // if start/end         no elongation
                // if joint skipped     elongate to new length
                // if normal joint      elongate a lot to let shape/truncation handle joint
                f_extrusion = vec2(
                    !isvalid[0] ? 0.0 : (adjustment[0] == 0.0 ? 1e12 : halfwidth * abs(extrusion[0])),
                    !isvalid[3] ? 0.0 : (adjustment[1] == 0.0 ? 1e12 : halfwidth * abs(extrusion[1]))
                );

                // used to compute width sdf
                f_linewidth = halfwidth;

                f_instance_id = lineindex_start + uint(1);

                f_cumulative_length = px_per_unit * lastlen_start;

                // linecap + joinstyle
                f_capmode = ivec2(
                    isvalid[0] ? joinstyle : linecap,
                    isvalid[3] ? joinstyle : linecap
                );


                ////////////////////////////////////////////////////////////////////
                // Varying vertex data
                ////////////////////////////////////////////////////////////////////

                vec3 offset;
                int x = int(is_end);
                if (adjustment[x] == 0.0) {
                    if (is_truncated[x] || !isvalid[3 * x]) {
                        // handle overlap in fragment shader via SDF comparison
                        offset = shape_factor * (
                            position.x * (halfwidth * max(1.0, abs(extrusion[x])) + AA_THICKNESS) * v1 +
                            vec3(position.y * (halfwidth + AA_THICKNESS) * n1, 0)
                        );
                    } else {
                        // handle overlap by adjusting geometry
                        // TODO: should this include z in miter_n?
                        offset = position.y * shape_factor *
                            (halfwidth + AA_THICKNESS) /
                            float[2](miter_offset1, miter_offset2)[x] *
                            vec3(vec2[2](miter_n1, miter_n2)[x], 0);
                    }
                } else {
                    // discard joint for cleaner uniform_pattern handling
                    offset =
                        adjustment[x] * (halfwidth * abs(extrusion[x]) + AA_THICKNESS) * v1 +
                        vec3(position.y * (halfwidth + AA_THICKNESS) * n1, 0);
                }

                // Vertex position (padded for joint & anti-aliasing)
                vec3 point = vec3[2](p1, p2)[x] + offset;

                // SDF's
                vec2 VP1 = point.xy - p1.xy;
                vec2 VP2 = point.xy - p2.xy;

                // sdf of this segment
                f_quad_sdf.x = dot(VP1, -v1.xy);
                f_quad_sdf.y = dot(VP2,  v1.xy);
                f_quad_sdf.z = dot(VP1,  n1);

                // sdf for creating a flat cap on truncated joints
                // (sign(dot(...)) detects if line bends left or right)
                f_truncation.x = !is_truncated[0] ? -1.0 :
                    dot(VP1, sign(dot(miter_n1, -v1.xy)) * miter_n1) - halfwidth * abs(miter_offset1)
                    - abs(adjustment[0]) * 1e12;
                f_truncation.y = !is_truncated[1] ? -1.0 :
                    dot(VP2, sign(dot(miter_n2, +v1.xy)) * miter_n2) - halfwidth * abs(miter_offset2)
                    - abs(adjustment[1]) * 1e12;

                // Colors should be sampled based on the normalized distance from the
                // extruded edge (varies with offset in n direction)
                // - correcting for this with per-vertex colors results visible face border
                // - calculating normalized distance here will cause div 0/negative
                //   issues as (linelength +- (extrusion[0] + extrusion[1])) <= 0 is possible
                // So defer color interpolation to fragment shader
                f_linestart = shape_factor * halfwidth * extrusion[0];
                f_linelength = max(1.0, segment_length - shape_factor * halfwidth * (extrusion[0] - extrusion[1]));

                // for thin lines
                f_alpha_weight = min(1.0, width / AA_RADIUS);

                // clip space position
                gl_Position = vec4(2.0 * point.xy / (px_per_unit * resolution) - 1.0, point.z, 1.0);
            }
        `;
    }
}

function lines_fragment_shader(uniforms, attributes) {
    const color_uniforms = filter_by_key(uniforms, [
        "picking",
        "uniform_pattern",
        "uniform_pattern_length",
        "uniform_colorrange",
        "uniform_colormap",
        "nan_color",
        "highclip_color",
        "lowclip_color",
    ]);
    const uniform_decl = uniforms_to_type_declaration(color_uniforms);
    const color =
        attribute_type(attributes.line_color_start) ||
        uniform_type(uniforms.line_color_start);

    return `
    // uncomment for debug rendering
    // #define DEBUG

    precision highp int;
    precision highp float;
    precision mediump sampler2D;
    precision mediump sampler3D;

    in highp vec3 f_quad_sdf;
    in vec2 f_truncation;
    in float f_linestart;
    in float f_linelength;

    flat in float f_linewidth;
    flat in vec4 f_pattern_overwrite;
    flat in vec2 f_extrusion;
    flat in ${color} f_color1;
    flat in ${color} f_color2;
    flat in float f_alpha_weight;
    flat in uint f_instance_id;
    flat in float f_cumulative_length;
    flat in ivec2 f_capmode;
    flat in vec4 f_linepoints;
    flat in vec4 f_miter_vecs;

    uniform uint object_id;
    ${uniform_decl}

    out vec4 fragment_color;

    // Half width of antialiasing smoothstep
    const float AA_RADIUS = 0.8;
    // space allocated for AA
    const float AA_THICKNESS = 2.0 * AA_RADIUS;
    const int BUTT   = 0;
    const int SQUARE = 1;
    const int ROUND  = 2;
    const int MITER  = 0;
    const int BEVEL  = 3;

    float aastep(float threshold, float value) {
        return smoothstep(threshold-AA_RADIUS, threshold+AA_RADIUS, value);
    }


    ////////////////////////////////////////////////////////////////////////
    // Color handling
    ////////////////////////////////////////////////////////////////////////


    vec4 get_color_from_cmap(float value, sampler2D colormap, vec2 colorrange) {
        float cmin = colorrange.x;
        float cmax = colorrange.y;
        if (value <= cmax && value >= cmin) {
            // in value range, continue!
        } else if (value < cmin) {
            return lowclip_color;
        } else if (value > cmax) {
            return highclip_color;
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
        return texture(colormap, vec2(i01, 0.0));
    }

    vec4 get_color(float color, sampler2D colormap, vec2 colorrange) {
        return get_color_from_cmap(color, colormap, colorrange);
    }

    vec4 get_color(vec4 color, bool colormap, bool colorrange) {
        return color;
    }
    vec4 get_color(vec3 color, bool colormap, bool colorrange) {
        return vec4(color, 1.0);
    }


    ////////////////////////////////////////////////////////////////////////
    // Pattern sampling
    ////////////////////////////////////////////////////////////////////////


    float get_pattern_sdf(sampler2D uniform_pattern, vec2 uv){

        // f_pattern_overwrite.x
        //      v           joint
        //    ----------------
        //      |          |
        //    ----------------
        // joint           ^
        //      f_pattern_overwrite.z

        float w = 2.0 * f_linewidth;
        if (uv.x <= f_pattern_overwrite.x) {
            // overwrite for uniform_pattern with "ON" to the right (positive uv.x)
            float sdf_overwrite = w * uniform_pattern_length * (f_pattern_overwrite.x - uv.x);
            // uniform_pattern value where we start overwriting
            float edge_sample = w * texture(uniform_pattern, vec2(f_pattern_overwrite.x, 0.5)).x;
            // offset for overwrite to smoothly connect between sampling and edge
            float sdf_offset = max(f_pattern_overwrite.y * edge_sample, -AA_RADIUS);
            // add offset and apply direction ("ON" to left or right) to overwrite
            return f_pattern_overwrite.y * (sdf_overwrite + sdf_offset);
        } else if (uv.x >= f_pattern_overwrite.z) {
            // same as above (other than mirroring overwrite direction)
            float sdf_overwrite = w * uniform_pattern_length * (uv.x - f_pattern_overwrite.z);
            float edge_sample = w * texture(uniform_pattern, vec2(f_pattern_overwrite.z, 0.5)).x;
            float sdf_offset = max(f_pattern_overwrite.w * edge_sample, -AA_RADIUS);
            return f_pattern_overwrite.w * (sdf_overwrite + sdf_offset);
        } else
            // in allowed range
            return w * texture(uniform_pattern, uv).x;
    }

    float get_pattern_sdf(bool _, vec2 uv){
        return -10.0;
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


    void main(){
        vec4 color;

        // f_quad_sdf.x is the distance from p1, negative in v1 direction.
        vec2 uv = vec2(
            (f_cumulative_length - f_quad_sdf.x) / (2.0 * f_linewidth * uniform_pattern_length),
            0.5 + 0.5 * f_quad_sdf.z / f_linewidth
        );

    #ifndef DEBUG
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
        if (f_capmode.y == ROUND) {
            sdf = max(sdf,
                min(sqrt(f_quad_sdf.y * f_quad_sdf.y + f_quad_sdf.z * f_quad_sdf.z) - f_linewidth, f_quad_sdf.y)
            );
        } else if (f_capmode.y == SQUARE) {
            sdf = max(sdf, f_quad_sdf.y - f_linewidth);
        } else { // miter or bevel joint or :butt cap
            sdf = max(sdf, f_quad_sdf.y - f_extrusion.y);
            sdf = max(sdf, f_truncation.y);
        }

        // distance in uniform_linewidth direction
        // f_quad_sdf.z is 0 along the line connecting p1 and p2 and increases along line-normal direction
        //  ^  |  ^      ^  | ^
        //     1------------2
        //  ^  |  ^      ^  | ^
        sdf = max(sdf, abs(f_quad_sdf.z) - f_linewidth);

        // inner truncation (AA for overlapping parts)
        // min(a, b) keeps what is inside a and b
        // where a is the smoothly cut of part just before discard triggers (i.e. visible)
        // and b is the (smoothly) cut of part where the discard triggers
        // 100.0x sdf makes the sdf much more sharply, avoiding overdraw in the center
        sdf = max(sdf, min(f_quad_sdf.x + 1.0, 100.0 * discard_sdf1 - 1.0));
        sdf = max(sdf, min(f_quad_sdf.y + 1.0, 100.0 * discard_sdf2 - 1.0));

        // uniform_pattern application
        sdf = max(sdf, get_pattern_sdf(uniform_pattern, uv));

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
        color = get_color(f_color1 + factor * (f_color2 - f_color1), uniform_colormap, uniform_colorrange);

        color.a *= aastep(0.0, -sdf) * f_alpha_weight;
    #endif

    #ifdef DEBUG
        // base color
        color = vec4(0.5, 0.5, 0.5, 0.2);
        color.rgb += (2.0 * mod(float(f_instance_id), 2.0) - 1.0) * 0.1;

        // show color interpolation as brightness gradient
        // float factor = (-f_quad_sdf.x - f_linestart) / f_linelength;
        // color.rgb += (2.0 * factor - 1.0) * 0.2;

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

        // mark uniform_pattern in white
        color.rgb += vec3(0.3) * step(0.0, get_pattern_sdf(uniform_pattern, uv));
    #endif

        if (color.a <= 0.0)
            discard;

        if (picking) {
            if (color.a > 0.1) {
                fragment_color = pack_int(object_id, f_instance_id);
            }
            return;
        }
        fragment_color = vec4(color.rgb, color.a);
    }
    `;
}


function create_line_material(uniforms_des, attributes, is_linesegments) {
    const mat = new THREE.RawShaderMaterial({
        uniforms: uniforms_des,
        glslVersion: THREE.GLSL3,
        vertexShader: lines_vertex_shader(
            uniforms_des,
            attributes,
            is_linesegments
        ),
        fragmentShader: lines_fragment_shader(uniforms_des, attributes),
        transparent: true, // Enable transparency
        blending: THREE.CustomBlending,
        blendSrc: THREE.SrcAlphaFactor,
        blendDst: THREE.OneMinusSrcAlphaFactor,
        blendSrcAlpha: THREE.ZeroFactor,
        blendDstAlpha: THREE.OneFactor,
        blendEquation: THREE.AddEquation,
    });
    mat.uniforms.object_id = { value: 1 };
    return mat;
}

function attach_interleaved_line_buffer(attr_name, geometry, data, ndim, is_segments, is_position) {
    // Buffer      required                 generated
    // positions_transformed_f32c   prev, start, end, next   all
    // color       start, end               start, end
    // lastlen     start                    start, end
    // uniform_linewidth   start, end*              start, end
    // * used but not strictly needed

    const skip_elems = is_segments ? 2 * ndim : ndim;
    const buffer = new THREE.InstancedInterleavedBuffer(data, skip_elems, 1);
    buffer.count = Math.max(0, is_segments ? Math.floor(buffer.count - 1) : buffer.count - 3);

    geometry.setAttribute(
        attr_name + "_start",
        new THREE.InterleavedBufferAttribute(buffer, ndim, ndim)
    ); // xyz1

    geometry.setAttribute(
        attr_name + "_end",
        new THREE.InterleavedBufferAttribute(buffer, ndim, 2 * ndim)
    ); // xyz2

    if (is_position) {
        geometry.setAttribute(
            attr_name + "_prev",
            new THREE.InterleavedBufferAttribute(buffer, ndim, 0)
        ); // xyz0
        geometry.setAttribute(
            attr_name + "_next",
            new THREE.InterleavedBufferAttribute(buffer, ndim, 3 * ndim)
        ); // xyz3
    }
    // make sure the interleaved buffer is accessible from the geometry for updating!
    geometry.interleaved_attributes[attr_name] = buffer;
    return buffer;
}

function create_line_instance_geometry() {
    const geometry = new THREE.InstancedBufferGeometry();
    // track our interleaved buffers for updates!
    geometry.interleaved_attributes = {};
    // (-1, -1) to (+1, +1) quad
    const instance_positions = [-1,-1, 1,-1, 1,1,   -1,-1, 1,1, -1,1];
    geometry.setAttribute(
        "position",
        new THREE.Float32BufferAttribute(instance_positions, 2)
    );
    geometry.boundingSphere = new THREE.Sphere();
    // don't use intersection / culling
    geometry.boundingSphere.radius = 10000000000000;
    geometry.frustumCulled = false;
    return geometry;
}

function create_line_buffer(geometry, buffers, name, attr, is_segments, is_position) {
    const flat_buffer = attr.flat;
    const ndims = attr.type_length;
    const linebuffer = attach_interleaved_line_buffer(
        name,
        geometry,
        flat_buffer,
        ndims,
        is_segments,
        is_position
    );
    buffers[name] = linebuffer;
    return flat_buffer;
}

function create_line_buffers(geometry, buffers, attributes, is_segments) {
    for (let name in attributes) {
        const attr = attributes[name];
        create_line_buffer(geometry, buffers, name, attr, is_segments, name == "positions_transformed_f32c");
    }
}

function get_points_view(points, indices, ndim) {
    let view = new Float32Array(indices.length * ndim);

    for (let i = 0; i < indices.length; i++) {
        let index = indices[i];
        for (let j = 0; j < ndim; j++) {
            view[i * ndim + j] = points[index * ndim + j];
        }
    }
    return view;
}

function pack_array(array, data, type_length = 0) {
    if (array.flat) {
        const tl = type_length === 0 ? array.type_length : type_length;
        return { flat: data, type_length: tl };
    }
    return data;
}

function unpack_array(array) {
    if (array.flat) {
        return array.flat;
    }
    return array;
}

function compute_lastlen(points, point_ndim, pvm, res, is_lines_with_linestyle) {
    if (!is_lines_with_linestyle) return new Float32Array(points.length / point_ndim).fill(0);
    if (points.length === 0) return new Float32Array(0);

    const num_points = points.length / point_ndim;
    const output = new Float32Array(num_points);
    const scale = new THREE.Vector2(0.5 * res.x, 0.5 * res.y);

    // Get the second point (index 1 in Julia's 1-based indexing = index 1 in our 0-based indexing)
    const second_point_idx = 1 * point_ndim;
    let clip = new THREE.Vector4(
        points[second_point_idx],
        points[second_point_idx + 1],
        point_ndim === 3 ? points[second_point_idx + 2] : 0,
        1
    ).applyMatrix4(pvm);
    let prev = new THREE.Vector2(clip.x, clip.y)
        .multiply(scale)
        .divideScalar(clip.w);

    // Initialize cumulative pixel scale length
    output[0] = 0.0; // duplicated point (Julia's output[1])
    output[1] = 0.0; // start of first line segment (Julia's output[2])
    output[output.length - 1] = 0.0; // duplicated end point (Julia's output[end])

    // Start from point index 2 (Julia's i = 3, but 0-based)
    let point_i = 2;
    while (point_i < num_points) {
        const array_idx = point_i * point_ndim;
        const x = points[array_idx];
        const y = points[array_idx + 1];
        const z = point_ndim === 3 ? points[array_idx + 2] : 0;

        if (
            Number.isFinite(x) &&
            Number.isFinite(y) &&
            (point_ndim === 2 || Number.isFinite(z))
        ) {
            clip = new THREE.Vector4(x, y, z, 1).applyMatrix4(pvm);
            const current = new THREE.Vector2(clip.x, clip.y)
                .multiply(scale)
                .divideScalar(clip.w);
            const length = current.distanceTo(prev);
            output[point_i] = output[point_i - 1] + length;
            prev = current;
            point_i += 1;
        } else {
            // Handle NaN vertex section (NaN, A, B, C) does not contribute to line length
            output[point_i] = 0.0;
            output[point_i + 1] = 0.0;
            if (point_i + 2 < num_points) {
                output[Math.min(output.length - 1, point_i + 2)] = 0.0;
                const next_point_idx = (point_i + 2) * point_ndim;
                clip = new THREE.Vector4(
                    points[next_point_idx],
                    points[next_point_idx + 1],
                    point_ndim === 3 ? points[next_point_idx + 2] : 0,
                    1
                ).applyMatrix4(pvm);
                prev = new THREE.Vector2(clip.x, clip.y)
                    .multiply(scale)
                    .divideScalar(clip.w);
            }
            point_i += 3;
        }
    }

    return output;
}

function get_projectionview(cam, plot) {
    const space = plot.plot_data.cam_space;
    const identity = new THREE.Uniform(new THREE.Matrix4());
    if (space == "data") {
        return cam.projectionview;
    } else if (space == "pixel") {
        return cam.pixel_space;
    } else if (space == "relative") {
        return cam.relative_space;
    } else if (space == "clip") {
        return identity;
    } else {
        throw new Error(`Space ${space} not supported!`);
    }
}

function get_last_len(plot, points) {
    const cam = plot.scene.wgl_camera;
    // LineSegments don't need lastlen because the line pattern isn't continuous between segments
    // lines without linestyle don't need it either, because there is no pattern to continue
    const is_lines_with_linestyle = !plot.is_segments && (plot.plot_data.pattern != false);
    const pvm = get_projectionview(cam, plot);
    const res = cam.resolution;
    const point_ndim = plot.ndims["positions_transformed_f32c"] || 2;
    const space = plot.plot_data.cam_space;
    const static_space = space === "clip" || space === "relative";
    if (!cam.on_update.has(plot.uuid) && !static_space) {
        cam.on_update[plot.uuid] = (x) => {
            const geom = plot.mesh.geometry;
            const ia = geom.interleaved_attributes;
            const new_points = ia.positions_transformed_f32c.array;
            const lastlen = compute_lastlen(
                new_points,
                point_ndim,
                pvm.value,
                res.value,
                is_lines_with_linestyle
            );
        };
    }

    return compute_lastlen(points, point_ndim, pvm.value, res.value, is_lines_with_linestyle);
}

export function add_line_attributes(plot, attributes) {
    const new_data = {};
    let { lineindex } = plot;
    if (attributes.positions_transformed_f32c) {
        const {positions_transformed_f32c} = attributes;
        const val = unpack_array(positions_transformed_f32c);
        if (positions_transformed_f32c.type_length) {
            plot.ndims["positions_transformed_f32c"] = positions_transformed_f32c.type_length;
        }
        lineindex = nan_free_points_indices(val, plot.ndims["positions_transformed_f32c"]);
        plot.lineindex = lineindex;

        const points = get_points_view(val, lineindex, plot.ndims["positions_transformed_f32c"]);
        new_data["positions_transformed_f32c"] = pack_array(positions_transformed_f32c, points);
        new_data["lineindex"] = pack_array(positions_transformed_f32c, lineindex, 1);
        new_data["lastlen"] = pack_array(
            positions_transformed_f32c,
            get_last_len(plot, points),
            1
        );
    }

    function is_uniform(key) {
        return key in plot.deserialized_uniforms;
    }

    for (const [key, value] of Object.entries(attributes)) {
        const val = unpack_array(value);
        if (key === "positions_transformed_f32c") {
            continue;
        }
        if (
            (key === "line_color" || key === "uniform_linewidth") && is_uniform(key) // uniforms
        ) {
            new_data[key + "_start"] = value;
            new_data[key + "_end"] = value;
        } else if (
            is_typed_array(val) &&
            (key === "line_color" || key === "uniform_linewidth")
        ) {
            if (value.type_length) {
                plot.ndims[key] = value.type_length;
            }
            new_data[key] = pack_array(
                value,
                get_points_view(val, lineindex, plot.ndims[key])
            );
        } else {
            new_data[key] = value;
        }
    }
    return new_data;
}


export function create_line(plot_object) {
    const geometry = create_line_instance_geometry();
    const buffers = {};
    const {plot_data} = plot_object;
    create_line_buffers(
        geometry,
        buffers,
        add_line_attributes(plot_object, plot_data.attributes),
        plot_object.is_segments
    );
    const material = create_line_material(
        add_line_attributes(
            plot_object,
            plot_object.deserialized_uniforms
        ),
        geometry.attributes,
        plot_object.is_segments
    );
    material.depthTest = !plot_data.overdraw;
    material.depthWrite = !plot_data.transparency;

    material.uniforms.is_linesegments = { value: plot_object.is_segments };
    const mesh = new THREE.Mesh(geometry, material);
    mesh.geometry.instanceCount =
        geometry.attributes.positions_transformed_f32c_start.count;
    return mesh;
}

function nan_free_points_indices(points, ndim) {
    const indices = [];
    const npoints = points.length / ndim;

    let was_nan = true;
    let loop_start_idx = -1;

    for (let i = 0; i < npoints; i++) {
        const p = get_point(points, i, ndim);

        if (point_isnan(p)) {
            // line section end (last was value, now nan)
            if (!was_nan) {
                // does previous point close loop?
                // loop started && 3+ segments && start == end
                if (
                    loop_start_idx !== -1 &&
                    loop_start_idx + 2 < indices.length &&
                    points_approx_equal(
                        get_point(points, indices[loop_start_idx], ndim),
                        get_point(points, i - 1, ndim)
                    )
                ) {
                    // Loop case: add ghost vertex and adjust
                    indices.push(indices[loop_start_idx + 1]);
                    indices[loop_start_idx - 1] = i - 2;
                } else {
                    // no loop, duplicate end point
                    indices.push(i - 1);
                }
            }
            loop_start_idx = -1;
            was_nan = true;
        } else {
            if (was_nan) {
                // line section start - duplicate point
                indices.push(i);
                // first point in a potential loop
                loop_start_idx = indices.length; // Will be index of next push
            }
            was_nan = false;
        }

        // push normal line point (including nan)
        indices.push(i);
    }

    // Finish line (insert duplicate end point or close loop)
    if (!was_nan) {
        if (
            loop_start_idx !== -1 &&
            loop_start_idx + 2 < indices.length &&
            points_approx_equal(
                get_point(points, indices[loop_start_idx], ndim),
                get_point(points, npoints - 1, ndim)
            )
        ) {
            // Loop at end
            indices.push(indices[loop_start_idx + 1]);
            indices[loop_start_idx - 1] = npoints - 2;
        } else {
            // No loop at end
            indices.push(npoints - 1);
        }
    }

    return new Uint32Array(indices);
}

function get_point(points, index, ndim) {
    return points.slice(index * ndim, (index + 1) * ndim);
}

function point_isnan(p) {
    return p.some((p) => isNaN(p));
}

function points_approx_equal(p1, p2) {
    return p1.every((p, i) => approx_equal(p, p2[i]));
}

function approx_equal(a, b) {
    return Math.abs(a - b) < Number.EPSILON;
}

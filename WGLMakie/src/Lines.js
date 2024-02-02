import {
    attributes_to_type_declaration,
    uniforms_to_type_declaration,
    uniform_type,
    attribute_type,
} from "./Shaders.js";

import { deserialize_uniforms } from "./Serialization.js";
import { IntType } from "./THREE.js";

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
        attribute_type(attributes.color_start) ||
        uniform_type(uniforms.color_start);

    if (is_linesegments) {
        ////////////////////////////////////////////////////////////////////////
        /// Linessegments
        ////////////////////////////////////////////////////////////////////////
        return `precision mediump int;
            precision highp float;

            ${attribute_decl}

            out highp float f_quad_sdf0;    // invalid / not needed
            out highp vec3 f_quad_sdf1;
            out highp float f_quad_sdf2;    // invalid / not needed
            out vec2 f_truncation;          // invalid / not needed
            out float f_linestart;          // constant
            out float f_linelength;
            out vec2 f_uv;

            flat out vec2 f_extrusion;          // invalid / not needed
            flat out float f_linewidth;
            flat out vec4 f_pattern_overwrite;  // invalid / not needed
            flat out vec2 f_discard_limit;      // invalid / not needed
            flat out uint f_instance_id;
            flat out vec4 f_color1;
            flat out vec4 f_color2;

            ${uniform_decl}

            // Constants
            const float AA_RADIUS = 0.8;
            const float AA_THICKNESS = 2.0 * AA_RADIUS;


            ////////////////////////////////////////////////////////////////////////
            // Color handling
            ////////////////////////////////////////////////////////////////////////


            vec4 get_color_from_cmap(float value, sampler2D colormap, vec2 colorrange) {
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
            // Geometry/Position Utils
            ////////////////////////////////////////////////////////////////////////


            vec3 screen_space(vec3 point) {
                vec4 vertex = projectionview * model * vec4(point, 1);
                return vec3((0.5 * vertex.xy / vertex.w + 0.5) * resolution, vertex.z / vertex.w + depth_shift);
            }

            vec3 screen_space(vec2 point) {
                return screen_space(vec3(point, 0));
            }

            vec2 normal_vector(in vec2 v) { return vec2(-v.y, v.x); }
            vec2 normal_vector(in vec3 v) { return vec2(-v.y, v.x); }


            ////////////////////////////////////////////////////////////////////////
            // Main
            ////////////////////////////////////////////////////////////////////////


            void main() {
                bool is_end = position.x == 1.0;


                ////////////////////////////////////////////////////////////////////
                // Handle line geometry (position, directions)
                ////////////////////////////////////////////////////////////////////


                float width = px_per_unit * (is_end ? linewidth_end : linewidth_start);
                float halfwidth = 0.5 * width;

                vec3 p1 = screen_space(linepoint_start);
                vec3 p2 = screen_space(linepoint_end);

                // line vector (xy-normalized vectors in line direction)
                // Need z component for correct depth order
                vec3 v1 = p2 - p1;
                float segment_length = length(v1);
                v1 /= segment_length;

                // line normal (i.e. in linewidth direction)
                vec2 n1 = normal_vector(v1);


                ////////////////////////////////////////////////////////////////////
                // Static vertex data
                ////////////////////////////////////////////////////////////////////


                // invalid - no joints requiring pattern adjustments
                f_pattern_overwrite = vec4(-1e12, 1.0, 1e12, 1.0);

                // invalid - no joints that need pixels discarded
                f_discard_limit = vec2(10.0);

                // invalid - no joints requiring line sdfs to be extruded
                f_extrusion = vec2(0.0);

                // used to compute width sdf
                f_linewidth = halfwidth;

                f_instance_id = uint(2 * gl_InstanceID);


                ////////////////////////////////////////////////////////////////////
                // Varying vertex data
                ////////////////////////////////////////////////////////////////////


                // Vertex position & uv (padded for joint & anti-aliasing)
                float v_offset = position.x * (0.5 * segment_length + AA_THICKNESS);
                float n_offset = (halfwidth + AA_THICKNESS) * position.y;
                vec3 point = 0.5 * (p1 + p2) + v_offset * v1 + n_offset * vec3(n1, 0);

                // we don't generate lastlen for segments so we use
                // 0.5 * segment_length instead of the average lastlen here
                f_uv = vec2(
                    (0.5 * segment_length + v_offset) / pattern_length,
                    0.0
                );

                // SDF's
                vec2 VP1 = point.xy - p1.xy;
                vec2 VP2 = point.xy - p2.xy;

                // invalid - no joint to compute overlap with
                f_quad_sdf0 = 10.0;

                // sdf of this segment
                f_quad_sdf1.x = dot(VP1, -v1.xy);
                f_quad_sdf1.y = dot(VP2,  v1.xy);
                f_quad_sdf1.z = dot(VP1,  n1);

                // invalid - no joint to compute overlap with
                f_quad_sdf2 = 10.0;

                // invalid - no joint to truncate
                f_truncation = vec2(-10.0);

                // simplified - no extrusion or joints means we just have:
                f_linestart = 0.0;
                f_linelength = segment_length;

                // for color sampling
                f_color1 = get_color(color_start, colormap, colorrange);
                f_color2 = get_color(color_end,   colormap, colorrange);

                // clip space position
                gl_Position = vec4(2.0 * point.xy / resolution - 1.0, point.z, 1.0);
            }
        `;

    } else {
        ////////////////////////////////////////////////////////////////////////
        /// Lines
        ////////////////////////////////////////////////////////////////////////

        return `precision mediump int;
            precision highp float;

            ${attribute_decl}

            out highp float f_quad_sdf0;
            out highp vec3 f_quad_sdf1;
            out highp float f_quad_sdf2;
            out vec2 f_truncation;
            out float f_linestart;
            out float f_linelength;
            out vec2 f_uv;

            flat out vec2 f_extrusion;
            flat out float f_linewidth;
            flat out vec4 f_pattern_overwrite;
            flat out vec2 f_discard_limit;
            flat out uint f_instance_id;
            flat out vec4 f_color1;
            flat out vec4 f_color2;

            ${uniform_decl}

            // Constants
            const float MITER_LIMIT = -0.4;
            const float AA_RADIUS = 0.8;
            const float AA_THICKNESS = 2.0 * AA_RADIUS + 2.0;


            ////////////////////////////////////////////////////////////////////////
            // Pattern handling
            ////////////////////////////////////////////////////////////////////////


            vec2 process_pattern(bool pattern, bool[4] isvalid, float[2] extrusion, float halfwidth) {
                // do not adjust stuff
                f_pattern_overwrite = vec4(1e5, 1.0, -1e5, 1.0);
                return vec2(0);
            }

            vec2 process_pattern(sampler2D pattern, bool[4] isvalid, float[2] extrusion, float halfwidth) {
                // samples:
                //   -ext1  p1 ext1    -ext2 p2 ext2
                //      1   2   3        4   5   6
                // prev | joint |  this  | joint | next

                // default to no overwrite
                f_pattern_overwrite.x = -1e12;
                f_pattern_overwrite.z = +1e12;
                vec2 adjust = vec2(0);
                float left, center, right;

                if (isvalid[0]) {
                    float offset = max(abs(extrusion[0]), halfwidth);
                    left   = texture(pattern, vec2((lastlen_start - offset) / pattern_length, 0.0)).x;
                    center = texture(pattern, vec2(lastlen_start / pattern_length           , 0.0)).x;
                    right  = texture(pattern, vec2((lastlen_start + offset) / pattern_length, 0.0)).x;

                    // cases:
                    // ++-, +--, +-+ => elongate backwards
                    // -++, --+      => shrink forward
                    // +++, ---, -+- => freeze around joint

                    if ((left > 0.0 && center > 0.0 && right > 0.0) || (left < 0.0 && right < 0.0)) {
                        // default/freeze
                        // overwrite until one AA gap past the corner/joint
                        f_pattern_overwrite.x = (lastlen_start + abs(extrusion[0]) + AA_RADIUS) / pattern_length;
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
                        f_pattern_overwrite.x = (lastlen_start + abs(extrusion[0]) + AA_RADIUS) / pattern_length;
                        f_pattern_overwrite.y = sign(center);
                    }

                } // else there is no left segment, no left join, so no overwrite

                if (isvalid[3]) {
                    float offset = max(abs(extrusion[1]), halfwidth);
                    left   = texture(pattern, vec2((lastlen_end - offset) / pattern_length, 0.0)).x;
                    center = texture(pattern, vec2(lastlen_end / pattern_length           , 0.0)).x;
                    right  = texture(pattern, vec2((lastlen_end + offset) / pattern_length, 0.0)).x;

                    if ((left > 0.0 && center > 0.0 && right > 0.0) || (left < 0.0 && right < 0.0)) {
                        // default/freeze
                        f_pattern_overwrite.z = (lastlen_end - abs(extrusion[1]) - AA_RADIUS) / pattern_length;
                        f_pattern_overwrite.w = sign(center);
                    } else if (left > 0.0) {
                        // shrink backwards
                        adjust.y = -1.0;
                    } else if (right > 0.0) {
                        // elongate forward
                        adjust.y = 1.0;
                    } else {
                        // default - see above
                        f_pattern_overwrite.z = (lastlen_end - abs(extrusion[1]) - AA_RADIUS) / pattern_length;
                        f_pattern_overwrite.w = sign(center);
                    }
                }

                return adjust;
            }

            // If we don't have a pattern we don't need uv's
            vec2 generate_uv(bool pattern, float extrusion, float linewidth) { return vec2(0); }
            vec2 generate_uv(sampler2D pattern, float extrusion, float linewidth) {
                return vec2(
                    (0.5 * (lastlen_start + lastlen_end) + extrusion) / pattern_length,
                    0.0 // 0.5 + 0.5 * linewidth / abs(linewidth)
                );
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
            // Geometry/Position Utils
            ////////////////////////////////////////////////////////////////////////


            vec3 screen_space(vec3 point) {
                vec4 vertex = projectionview * model * vec4(point, 1);
                return vec3((0.5 * vertex.xy / vertex.w + 0.5) * resolution, vertex.z / vertex.w + depth_shift);
            }

            vec3 screen_space(vec2 point) {
                return screen_space(vec3(point, 0));
            }

            vec2 normal_vector(in vec2 v) { return vec2(-v.y, v.x); }
            vec2 normal_vector(in vec3 v) { return vec2(-v.y, v.x); }


            ////////////////////////////////////////////////////////////////////////
            // Main
            ////////////////////////////////////////////////////////////////////////


            void main() {
                bool is_end = position.x == 1.0;


                ////////////////////////////////////////////////////////////////////
                // Handle line geometry (position, directions)
                ////////////////////////////////////////////////////////////////////


                float width = px_per_unit * (is_end ? linewidth_end : linewidth_start);
                float halfwidth = 0.5 * width;

                vec3 p0 = screen_space(linepoint_prev);
                vec3 p1 = screen_space(linepoint_start);
                vec3 p2 = screen_space(linepoint_end);
                vec3 p3 = screen_space(linepoint_next);

                bool[4] isvalid = bool[4](p0 != p1, true, true, p2 != p3);

                // line vectors (xy-normalized vectors in line direction)
                // Need z component for correct depth order
                vec3 v1 = p2 - p1;
                float segment_length = length(v1);
                v1 /= segment_length;

                // We don't need the z component for these
                vec2 v0 = v1.xy, v2 = v1.xy;
                if (isvalid[0])
                    v0 = normalize(p1.xy - p0.xy);
                if (isvalid[3])
                    v2 = normalize(p3.xy - p2.xy);

                // line normals (i.e. in linewidth direction)
                vec2 n0 = normal_vector(v0);
                vec2 n1 = normal_vector(v1);
                vec2 n2 = normal_vector(v2);


                ////////////////////////////////////////////////////////////////////
                // Handle joint geometry
                ////////////////////////////////////////////////////////////////////


                // joint information
                // Miter normals (normal of truncated edge / vector to sharp corner)
                vec2 miter_n1 = normalize(n0 + n1);
                vec2 miter_n2 = normalize(n1 + n2);

                // miter vectors (line vector matching miter normal)
                vec2 miter_v1 = -normal_vector(miter_n1);
                vec2 miter_v2 = -normal_vector(miter_n2);

                // distance between p1/2 and respective sharp corner
                float miter_offset1 = dot(miter_n1, n1); // = dot(miter_v1, v1)
                float miter_offset2 = dot(miter_n2, n1); // = dot(miter_v2, v1)

                // Are we truncating the joint?
                bool[2] is_truncated = bool[2](
                    dot(v0.xy, v1.xy) < MITER_LIMIT,
                    dot(v1.xy, v2.xy) < MITER_LIMIT
                );

                float[2] extrusion;

                if (is_truncated[0]) {
                    // need to extend segment to include previous segments corners for truncated join
                    extrusion[0] = -halfwidth * miter_offset1 / dot(miter_v1, n1);
                } else {
                    // shallow/spike join needs to include point where miter normal meets outer line edge
                    extrusion[0] = -halfwidth * dot(miter_n1, v1.xy) / miter_offset1;
                }
                if (is_truncated[1]) {
                    extrusion[1] = halfwidth * miter_offset2 / dot(miter_v2, n1);
                } else {
                    extrusion[1] = halfwidth * dot(miter_n2, v1.xy) / miter_offset2;
                }


                ////////////////////////////////////////////////////////////////////
                // Static vertex data
                ////////////////////////////////////////////////////////////////////


                // Set up pattern overwrites at joints if patterns are used. This "freezes"
                // the pattern in either the on state (draw) or off state (no draw) to avoid
                // fragmenting it around a corner.
                vec2 adjustment = process_pattern(pattern, isvalid, extrusion, halfwidth);

                // limit range of distance sampled in prev/next segment
                // this makes overlapping segments draw over each other when reaching the limit
                // Maxiumum overlap in sharp joint is halfwidth / dot(miter_n, n) ~ 1.83 halfwidth
                // So 2 halfwidth = g_thickness[1] will avoid overdraw in sharp joints
                f_discard_limit = vec2(
                    is_truncated[0] ? 0.0 : 1e12,
                    is_truncated[1] ? 0.0 : 1e12
                );

                // used to elongate sdf to include joints
                // if start/end don't elongate
                // if joint skipped elongate to new length
                // if joint elongate a lot to let discard/truncation handle joint
                f_extrusion = vec2(
                    !isvalid[0] ? 0.0 : 1e12,
                    !isvalid[3] ? 0.0 : 1e12
                );

                // used to compute width sdf
                f_linewidth = halfwidth;

                f_instance_id = uint(gl_InstanceID);


                ////////////////////////////////////////////////////////////////////
                // Varying vertex data
                ////////////////////////////////////////////////////////////////////


                // Vertex position & uv (padded for joint & anti-aliasing)
                float v_offset, n_offset;
                if (adjustment[int(is_end)] == 0.0) {
                    v_offset = position.x * (0.5 * segment_length + abs(extrusion[int(is_end)]) + AA_THICKNESS);
                } else {
                    v_offset = position.x * 0.5 * segment_length + adjustment[int(is_end)] * (
                        max(abs(extrusion[int(is_end)]), halfwidth) +
                        AA_THICKNESS
                    );
                }
                n_offset = (halfwidth + AA_THICKNESS) * position.y;

                // round seems to fix overdraw/underdraw but introduces slight jitter
                // round(f * ...) / f reduces jitter but may reintroduce over/underdraw
                vec3 point = 0.5 * (p1 + p2) + 0.125 * round(8.0 * (v_offset * v1 + n_offset * vec3(n1, 0)));
                f_uv = generate_uv(pattern, v_offset, n_offset);


                // SDF's
                vec2 VP1 = point.xy - p1.xy;
                vec2 VP2 = point.xy - p2.xy;

                // signed distance of previous segment at shared control point in line
                // direction. Used decide which segments renders which joint fragment.
                // If the left joint is adjusted this sdf is disabled.
                f_quad_sdf0 = isvalid[0] && (adjustment[0] == 0.0) ? dot(VP1, v0) + 0.5 : 1e12;

                // sdf of this segment
                f_quad_sdf1.x = dot(VP1, -v1.xy) + 0.5;
                f_quad_sdf1.y = dot(VP2,  v1.xy) + 0.5;
                f_quad_sdf1.z = dot(VP1,  n1);

                // SDF for next segment, see quad_sdf0
                f_quad_sdf2 = isvalid[3] && (adjustment[1] == 0.0) ? dot(VP2, -v2) + 0.5 : 1e12;

                // sdf for creating a flat cap on truncated joints
                // (sign(dot(...)) detects if line bends left or right)
                // left/right adjustments disable
                f_truncation.x = !is_truncated[0] ? -1.0 :
                    dot(VP1, sign(dot(miter_n1, -v1.xy)) * miter_n1) - halfwidth * abs(miter_offset1)
                    - abs(adjustment[0]) * 1e12;
                f_truncation.y = !is_truncated[1] ? -1.0 :
                    dot(VP2, sign(dot(miter_n2, +v1.xy)) * miter_n2) - halfwidth * abs(miter_offset2)
                    - abs(adjustment[1]) * 1e12;

                // colors should be sampled based on the normalized distance from the
                // extruded edge (varies with offset in n direction)
                // - correcting for this with per-vertex colors results visible face border
                // - calculating normalized distance here will cause div 0/negative
                //   issues as (linelength +- (extrusion[0] + extrusion[1])) <= 0 is possible
                // So defer color interpolation to fragment shader
                f_linestart = position.y * extrusion[0];
                f_linelength = segment_length - position.y * (extrusion[0] + extrusion[1]);

                // for color sampling
                f_color1 = get_color(color_start, colormap, colorrange);
                f_color2 = get_color(color_end,   colormap, colorrange);

                // clip space position
                gl_Position = vec4(2.0 * point.xy / resolution - 1.0, point.z, 1.0);
            }
        `;
    }
}

function lines_fragment_shader(uniforms, attributes) {
    const color_uniforms = filter_by_key(uniforms, ["picking", "pattern", "pattern_length"]);
    const uniform_decl = uniforms_to_type_declaration(color_uniforms);

    return `
    // uncomment for debug rendering
    // #define DEBUG

    precision mediump int;
    precision highp float;
    precision mediump sampler2D;
    precision mediump sampler3D;

    in highp float f_quad_sdf0;
    in highp vec3 f_quad_sdf1;
    in highp float f_quad_sdf2;
    in vec2 f_truncation;
    in vec2 f_uv;
    in float f_linestart;
    in float f_linelength;

    flat in float f_linewidth;
    flat in vec4 f_pattern_overwrite;
    flat in vec2 f_extrusion;
    flat in vec2 f_discard_limit;
    flat in vec4 f_color1;
    flat in vec4 f_color2;
    flat in uint f_instance_id;

    uniform uint object_id;
    ${uniform_decl}

    out vec4 fragment_color;

    // Half width of antialiasing smoothstep
    const float AA_RADIUS = 0.7071067811865476;
    // space allocated for AA
    const float AA_THICKNESS = 2.0 * AA_RADIUS;

    float aastep(float threshold, float value) {
        return smoothstep(threshold-AA_RADIUS, threshold+AA_RADIUS, value);
    }

    // Pattern sampling
    float get_pattern_sdf(sampler2D pattern){
        float sdf_offset, x;
        if (f_uv.x <= f_pattern_overwrite.x) {
            // below allowed range of uv.x's (end of left joint + AA_THICKNESS)
            // if overwrite.y (target sdf in joint) is
            // .. +1 we start from max(pattern[overwrite.x], -AA) and extrapolate to positive values
            // .. -1 we start from min(pattern[overwrite.x], +AA) and extrapolate to negative values
            sdf_offset = max(f_pattern_overwrite.y * texture(pattern, vec2(f_pattern_overwrite.x, 0.0)).x, -AA_RADIUS);
            return f_pattern_overwrite.y * (pattern_length * (f_pattern_overwrite.x - f_uv.x) + sdf_offset);
        } else if (f_uv.x >= f_pattern_overwrite.z) {
            // above allowed range of uv.x's (start of right joint - AA_THICKNESS)
            // see above
            sdf_offset = max(f_pattern_overwrite.w * texture(pattern, vec2(f_pattern_overwrite.z, 0.0)).x, -AA_RADIUS);
            return f_pattern_overwrite.w * (pattern_length * (f_uv.x - f_pattern_overwrite.z) + sdf_offset);
        } else {
            // in allowed range
            return texture(pattern, f_uv).x;
        }
    }

    float get_pattern_sdf(bool _){
        return -10.0;
    }

    vec4 pack_int(uint id, uint index) {
        vec4 unpack;
        unpack.x = float((id & uint(0xff00)) >> 8) / 255.0;
        unpack.y = float((id & uint(0x00ff)) >> 0) / 255.0;
        unpack.z = float((index & uint(0xff00)) >> 8) / 255.0;
        unpack.w = float((index & uint(0x00ff)) >> 0) / 255.0;
        return unpack;
    }


    void main(){
        vec4 color;

        // if (f_instance_id % uint(2) == uint(0))
        //     discard;

    #ifndef DEBUG
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

        // truncation of truncated joints
        sdf = max(sdf, f_truncation.x);
        sdf = max(sdf, f_truncation.y);

        // inner truncation (AA for overlapping parts)
        // min(a, b) keeps what is inside a and b
        // where a is the smoothly cut of part just before discard triggers (i.e. visible)
        // and b is the (smoothly) cut of part where the discard triggers
        // 100.0x sdf makes the sdf much more sharply, avoiding overdraw in the center
        sdf = max(sdf, min(f_quad_sdf1.x + 1.0, 100.0 * (f_quad_sdf1.x - f_quad_sdf0) - 1.0));
        sdf = max(sdf, min(f_quad_sdf1.y + 1.0, 100.0 * (f_quad_sdf1.y - f_quad_sdf2) - 1.0));

        // pattern application
        sdf = max(sdf, get_pattern_sdf(pattern));

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
        // color = vec4(factor, 0, 0, 1);
        color = f_color1 + factor * (f_color2 - f_color1);

        color.a *= aastep(0.0, -sdf);
    #endif

    #ifdef DEBUG
        // base color
        color = vec4(0.5, 0.5, 0.5, 0.2);

        // show color interpolation as brightness gradient
        float factor = (-f_quad_sdf1.x - f_linestart) / f_linelength;
        color.rgb += (2.0 * factor - 1.0) * 0.2;

        // mark "outside" define by quad_sdf in black
        float sdf = max(f_quad_sdf1.x - f_extrusion.x, f_quad_sdf1.y - f_extrusion.y);
        sdf = max(sdf, abs(f_quad_sdf1.z) - f_linewidth);
        color.rgb -= vec3(0.4) * step(0.0, sdf);

        // Mark regions excluded via truncation in green
        color.g += 0.5 * step(0.0, max(f_truncation.x, f_truncation.y));

        // Mark discarded space in red/blue
        float dist_in_prev = max(f_quad_sdf0, - f_discard_limit.x);
        float dist_in_next = max(f_quad_sdf2, - f_discard_limit.y);
        if (dist_in_prev < f_quad_sdf1.x)
            color.r += 0.5;
        if (dist_in_next <= f_quad_sdf1.y) {
            color.b += 0.5;
        }

        // inner truncation - show second part as softer red/blue
        if (f_quad_sdf1.x - f_quad_sdf0 - 1.0 > 0.0)
            color.r += 0.2;
        if (f_quad_sdf1.y - f_quad_sdf2 - 1.0 > 0.0)
            color.b += 0.2;

        // and smooth inner truncation as soft green?
        if (f_quad_sdf1.x > 0.0)
            color.g += 0.2;
        if (f_quad_sdf1.y > 0.0)
            color.g += 0.2;

        // mark pattern in white
        color.rgb += vec3(0.3) * step(0.0, get_pattern_sdf(pattern));
    #endif

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

function create_line_material(uniforms, attributes, is_linesegments) {
    const uniforms_des = deserialize_uniforms(uniforms);
    const mat = new THREE.RawShaderMaterial({
        uniforms: uniforms_des,
        glslVersion: THREE.GLSL3,
        vertexShader: lines_vertex_shader(uniforms_des, attributes, is_linesegments),
        fragmentShader: lines_fragment_shader(uniforms_des, attributes),
        transparent: true,
    });
    mat.uniforms.object_id = { value: 1 };
    return mat;
}

function attach_interleaved_line_buffer(attr_name, geometry, data, ndim, is_segments) {
    // const skip_elems = is_segments ? 2 * ndim : ndim;
    const buffer = new THREE.InstancedInterleavedBuffer(data, ndim, 1);
    buffer.stride = is_segments ? 2 * ndim : ndim;
    buffer.count = buffer.count - 2; // TODO: -2?
    geometry.setAttribute(
        attr_name + "_prev",
        new THREE.InterleavedBufferAttribute(buffer, ndim, 0)
    ); // xyz0
    geometry.setAttribute(
        attr_name + "_start",
        new THREE.InterleavedBufferAttribute(buffer, ndim, ndim)
    ); // xyz1
    geometry.setAttribute(
        attr_name + "_end",
        new THREE.InterleavedBufferAttribute(buffer, ndim, 2 * ndim)
    ); // xyz2
    geometry.setAttribute(
        attr_name + "_next",
        new THREE.InterleavedBufferAttribute(buffer, ndim, 3 * ndim)
    ); // xyz3
    console.log(buffer);
    return buffer;
}

function create_line_instance_geometry() {
    const geometry = new THREE.InstancedBufferGeometry();
    // TODO: quad geometry may be more useful as -1, -1 .. 1, 1
    // const instance_positions = [
    //     0, -0.5, 1, -0.5, 1, 0.5,

    //     0, -0.5, 1, 0.5, 0, 0.5,
    // ];
    const instance_positions = [
        -1, -1, 1, -1, 1, 1,

        -1, -1, 1, 1, -1, 1
    ];
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

function create_line_buffer(geometry, buffers, name, attr, is_segments) {
    const flat_buffer = attr.value.flat;
    const ndims = attr.value.type_length;
    const linebuffer = attach_interleaved_line_buffer(
        name,
        geometry,
        flat_buffer,
        ndims,
        is_segments
    );
    buffers[name] = linebuffer;
    return flat_buffer;
}

function create_line_buffers(geometry, buffers, attributes, is_segments) {
    for (let name in attributes) {
        const attr = attributes[name];
        create_line_buffer(geometry, buffers, name, attr, is_segments);
    }
}

function attach_updates(mesh, buffers, attributes, is_segments) {
    let geometry = mesh.geometry;
    for (let name in attributes) {
        const attr = attributes[name];
        attr.on((new_points) => {
            let buff = buffers[name];
            const ndims = new_points.type_length;
            const new_line_points = new_points.flat;
            const old_count = buff.array.length;
            const new_count = new_line_points.length / ndims - 2; // TODO -2?
            if (old_count < new_line_points.length) {
                mesh.geometry.dispose();
                geometry = create_line_instance_geometry();
                buff = attach_interleaved_line_buffer(
                    name,
                    geometry,
                    new_line_points,
                    ndims,
                    is_segments
                );
                mesh.geometry = geometry;
                buffers[name] = buff;
            } else {
                buff.set(new_line_points);
            }
            const ls_factor = is_segments ? 2 : 1;
            const offset = is_segments ? 0 : 1;
            mesh.geometry.instanceCount = Math.max(0, (new_count / ls_factor) - offset);
            console.log("instance info:");
            console.log(new_line_points.length);
            console.log(ndims);
            console.log(ls_factor);
            console.log(offset);

            buff.needsUpdate = true;
            mesh.needsUpdate = true;
        });
    }
}

export function _create_line(line_data, is_segments) {
    const geometry = create_line_instance_geometry(); // generate quad for segment
    const buffers = {};
    create_line_buffers(
        geometry,
        buffers,
        line_data.attributes,
        is_segments
    );
    const material = create_line_material(
        line_data.uniforms,
        geometry.attributes,
        is_segments
    );
    console.log(geometry);

    material.uniforms.is_linesegments = {value: is_segments};
    const mesh = new THREE.Mesh(geometry, material);
    const new_count = geometry.attributes.linepoint_start.count;
    mesh.geometry.instanceCount = Math.max(0, is_segments ? new_count / 2 : new_count - 1);

    console.log("init:");
    console.log(geometry.attributes.linepoint_start.count);
    console.log(new_count);
    console.log(mesh.geometry.instanceCount);
    // console.log(offset);

    attach_updates(mesh, buffers, line_data.attributes, is_segments);
    return mesh;
}

// entrypoints
export function create_line(line_data) {
    return _create_line(line_data, false)
}

export function create_linesegments(line_data) {
    return _create_line(line_data, true)
}

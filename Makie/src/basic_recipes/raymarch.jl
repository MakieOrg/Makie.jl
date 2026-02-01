module SDF
    using LinearAlgebra
    using GeometryBasics
    using GeometryBasics: VecTypes
    using ...Makie: Quaternion, RGBA, lerp
    using ...Makie

    ############################################################################
    ### IDs
    ############################################################################

    module Commands
        @enum ID::UInt8 begin
            # prefix operations
            _reset # resets positional transformaitons (mostly prefix operations)
            op_revolution
            op_elongate
            op_rotation
            op_mirror
            op_infinite_repetition
            op_limited_repetition
            op_twist
            op_bend
            op_translation

            _start_of_shapes

            # 2D shapes
            shape2D_vesica
            shape2D_plane
            shape2D_rhombus
            shape2D_hexagonal_prism
            shape2D_triangular_prism

            # 3D Shapes
            shape3D_sphere
            shape3D_octahedron
            shape3D_pyramid
            shape3D_torus
            shape3D_capsule
            shape3D_cylinder
            shape3D_ellipsoid
            shape3D_rect
            shape3D_link
            shape3D_cone
            shape3D_capped_cone
            shape3D_solid_angle
            shape3D_box_frame
            shape3D_capped_torus

            _start_of_merge

            # merge operations
            op_union
            op_subtraction
            op_intersection
            op_xor
            op_smooth_union
            op_smooth_subtraction
            op_smooth_intersection
            op_smooth_xor

            _start_of_postfix

            # postfix operations
            op_extrusion
            op_rounding
            op_onion
        end

        # number of float parameters for each operation/command
        const id2num_param = Dict{ID, Int}(
            _reset => 0, op_revolution => 1, op_elongate => 3, op_rotation => 4,
            op_mirror => 3, op_infinite_repetition => 3, op_limited_repetition => 6,
            op_twist => 1, op_bend => 1, op_translation => 3,

            # 2D shapes
            # shape2D_vesica
            # shape2D_plane
            # shape2D_rhombus
            # shape2D_hexagonal_prism
            # shape2D_triangular_prism

            # 3D Shapes
            shape3D_sphere => 5, shape3D_octahedron => 5, shape3D_pyramid => 6,
            shape3D_torus => 6, shape3D_capsule => 6, shape3D_cylinder => 6,
            shape3D_ellipsoid => 7, shape3D_rect => 7, shape3D_link => 7,
            shape3D_cone => 6, shape3D_capped_cone => 7,
            # shape3D_solid_angle => 0,
            shape3D_box_frame => 8, shape3D_capped_torus => 7,

            # merge operations
            op_union => 0, op_subtraction => 0, op_intersection => 0, op_xor => 0,
            op_smooth_union => 1, op_smooth_subtraction => 1,
            op_smooth_intersection => 1, op_smooth_xor => 1,

            # postfix operations
            op_extrusion => 3, op_rounding => 1, op_onion => 1,
        )

        const name2id = Dict{Symbol, ID}(
            :reset => _reset, :revolution => op_revolution, :elongate => op_elongate,
            :rotation => op_rotation, :mirror => op_mirror,
            :infinite_repetition => op_infinite_repetition,
            :limited_repetition => op_limited_repetition, :twist => op_twist,
            :bend => op_bend, :translation => op_translation,

            # :Vesica => shape2D_vesica,
            # :Plane => shape2D_plane,
            # :Rhombus => shape2D_rhombus,
            # :Hexagonal_prism => shape2D_hexagonal_prism,
            # :Triangular_prism => shape2D_triangular_prism,

            :sphere => shape3D_sphere, :octahedron => shape3D_octahedron,
            :pyramid => shape3D_pyramid, :torus => shape3D_torus,
            :capsule => shape3D_capsule, :cylinder => shape3D_cylinder,
            :ellipsoid => shape3D_ellipsoid, :rect => shape3D_rect,
            :link => shape3D_link, :capped_cone => shape3D_capped_cone,
            :solid_Angle => shape3D_solid_angle, :box_frame => shape3D_box_frame,
            :capped_torus => shape3D_capped_torus, :cone => shape3D_cone,

            :union => op_union, :subtraction => op_subtraction,
            :intersection => op_intersection, :xor => op_xor,
            :smooth_union => op_smooth_union, :smooth_subtraction => op_smooth_subtraction,
            :smooth_intersection => op_smooth_intersection, :smooth_xor => op_smooth_xor,

            :extrusion => op_extrusion, :rounding => op_rounding, :onion => op_onion,
        )

        const id2name = Dict{ID, Symbol}([v => k for (k, v) in name2id])

        is_prefix(x::ID) = Int(x) < Int(_start_of_shapes)
        is_shape(x::ID) = Int(_start_of_shapes) < Int(x) < Int(_start_of_merge)
        is_merge(x::ID) = Int(_start_of_merge) < Int(x) < Int(_start_of_postfix)
        is_smooth_merge(x::ID) = x in (op_smooth_intersection, op_smooth_subtraction, op_smooth_union, op_smooth_xor)
        is_shape_or_merge(x::ID) = Int(_start_of_shapes) < Int(x) < Int(_start_of_postfix)
        is_postfix(x::ID) = Int(_start_of_postfix) < Int(x)

        get_name(id::ID) = id2name[id]
        get_id(name::Symbol) = name2id[name]
        get_id(id::ID) = id
        get_num_parameters(x) = id2num_param[get_id(x)]

        function glsl_enum()
            buffer = IOBuffer()
            for x in instances(ID)
                println(buffer, "const uint $x = ", Int(x), ';')
            end
            return String(take!(buffer))
        end
    end


    ############################################################################
    ### SDF and Command evaluation
    ############################################################################

    @fastmath begin
        sign1(x::Real) = ifelse(signbit(x), -one(x), +one(x))
        sign1(x::VecTypes) = sign1.(x)
        norm2(v::VecTypes) = dot(v, v)
        xy_norm(p) = norm(p[Vec(1, 2)])
        xy_norm2(p) = norm2(p[Vec(1, 2)])

        # SDF functions

        sphere(ray_pos, radius::Real) = norm(ray_pos) - radius

        function ellipsoid(ray_pos, scale::VecTypes{3})
            # See Inigo Quilez https://iquilezles.org/articles/ellipsoids/
            k0 = norm(ray_pos ./ scale);
            k1 = norm(ray_pos ./ (scale .* scale));
            return k0 * (k0 - 1f0) / max(0.000001f0, k1);
        end

        function rect(ray_pos, scale::VecTypes{3})
            q = abs.(ray_pos) - scale;
            # outside and inside distance?
            return norm(max.(q, 0f0)) + min(maximum(q), 0f0);
        end

        box_frame(ray_pos, scale, width) = rect_frame(ray_pos, scale, width)
        function rect_frame(ray_pos, scale::VecTypes{3}, width::Real)
            p = abs.(ray_pos) - scale;
            q = abs.(p .+ width) .- width;
            # signed distance for x/y/z frame rects
            a = norm(max.(Vec3f(p[1], q[2], q[3]), 0f0)) + min(max(p[1], q[2], q[3]), 0f0);
            b = norm(max.(Vec3f(q[1], p[2], q[3]), 0f0)) + min(max(q[1], p[2], q[3]), 0f0);
            c = norm(max.(Vec3f(q[1], q[2], p[3]), 0f0)) + min(max(q[1], q[2], p[3]), 0f0);
            return min(a, b, c);
        end

        function torus(ray_pos, r_outer::Real, r_inner::Real)
            q = Vec2f(xy_norm(ray_pos) - r_outer, ray_pos[3]);
            return norm(q) - r_inner;
        end

        # opening angle extending in both directions from 0
        function capped_torus(ray_pos, opening_angle::Real, r_outer::Real, r_inner::Real)
            s, c = sincos(opening_angle)
            p = Vec3f(abs(ray_pos[1]), ray_pos[2], ray_pos[3]);
            k = (c * p[1] > s * p[2]) ? p[1] * s + p[2] * c : xy_norm(p);
            return sqrt(dot(p, p) + r_outer * r_outer - 2f0 * r_outer * k) - r_inner;
        end

        function link(ray_pos, len::Real, r_outer::Real, r_inner::Real)
            q = Vec3f(ray_pos[1], max(abs(ray_pos[2]) - len, 0f0), ray_pos[3]);
            return norm(Vec2f(xy_norm(q) - r_outer, q[3])) - r_inner;
        end

        function cylinder(ray_pos, radius::Real, height::Real)
            # TODO: underestimates distance when we're diagonally below/above the cylinder
            #  |    |
            #..|____|.. OK
            #  : OK : wrong
            return max(xy_norm(ray_pos) - radius, abs(ray_pos[3]) - height);
        end

        # or rounded cylinder
        function capsule(ray_pos, radius::Real, height::Real)
            pos = Vec3f(ray_pos[1], ray_pos[2], max(0f0, abs(ray_pos[3]) - height));
            return norm(pos) - radius;
        end

        function cone(ray_pos, radius::Real, height::Real)
            # Quilez cone
            q = Vec2f(radius, -2.0 * height)
            w = Vec2f(xy_norm(ray_pos), ray_pos[3] - height)
            a = w - q * clamp(dot(w, q) / dot(q, q), 0f0, 1f0 )
            b = w - q .* Vec2f(clamp(w[1] / q[1], 0f0, 1f0), 1f0)
            k = sign(q[2])
            d = min(dot(a, a), dot(b,b))
            s = max(k * (w[1] * q[2] - w[2] * q[1]), k * (w[2] - q[2]))
            return sqrt(d) * sign(s);
        end

        function capped_cone(ray_pos, height::Real, radius1::Real, radius2::Real)
            ray_rh = Vec2f(xy_norm(ray_pos), ray_pos[3]);
            limits = Vec2f(radius2, height);
            delta = Vec2f(radius2 - radius1, 2f0 * height);
            ca = Vec2f(
                ray_rh[1] - min(ray_rh[1], ray_rh[2] < 0f0 ? radius1 : radius2),
                abs(ray_rh[2]) - height
            );
            cb = ray_rh - limits + delta * clamp(dot(limits - ray_rh, delta) / dot(delta, delta), 0f0, 1f0);
            s = (cb[1] < 0f0 && ca[2] < 0f0) ? -1f0 : 1f0;
            return s * sqrt(min(dot(ca, ca), dot(cb, cb)));
        end

        function octahedron(ray_pos, size::Real)
            p = abs.(ray_pos);
            boundary = sum(p) - size; # unnormalized

            q = p;
            if (3f0 * p[1] < boundary)
                # q = p.xyz;
            elseif (3f0 * p[2] < boundary)
                q = Vec3f(p[2], p[3], p[1])
            elseif (3f0 * p[3] < boundary)
                q = Vec3f(p[3], p[1], p[2])
            else
                return boundary * 0.57735027f0; # normalized
            end

            k = clamp(0.5f0 * (q[3] - q[2] + size), 0f0, size);
            return norm(Vec3f(q[1], q[2] - size + k, q[3] - k));
        end

        # TODO: doesn't work well, try Quillez version again
        function pyramid(ray_pos, w::Real, height::Real)
            h = 2f0 * height
            w2 = w*w
            m2 = h*h + w2;

            # 8x symmetry
            # after this, +x is the closest mantle plane, +y is the width
            p = Vec3f(abs(ray_pos[1]), abs(ray_pos[2]), ray_pos[3])
            p = ifelse(p[2] > p[1], Vec3f(p[2], p[1], p[3]), p)

            p = Vec3f(p[1] - w, p[2] - w, p[3] + height)

            # decompose p into plane related vectors:
            # q[1] component towards the side of the pyramid f_y = (0, 1, 0) (positive right)
            # q[2] component towards the top of the pyramid f_x = (-w, 0, h) (positive up)
            # q[3] component along the plane normal f_z = (h, 0, w) (positive outwards)
            q = Vec3f(p[2], h * p[3] - w * p[1], h * p[1] + w * p[3])
            # -w at center .. ∞ -> w at center .. 0 at edge and beyond
            s = max(-q[1], 0f0)
            # This is probably the interpolation along the mantle edge of the face
            # I.e. along k = (-w, 0, h) + (0, w, 0) = (-w, w, h)
            # dot(p, k) = t * dot(k, k)
            # (q[2] + w * q[1]) = t * (w^2 + w² + h^2)   Note: q[1]/f_y does not include w
            t = clamp((q[2] - w * q[1]) / (m2 + w2), 0f0, 1f0)
            # distance from bottom corner * m2 (this avoids normalizing/division until later)
            # q[1] / f_y direction only contributes outside
            a = m2 * (q[1] + s) * (q[1] + s) + q[2] * q[2]
            b = m2 * (q[1] + w * t) * (q[1] + w * t) + (q[2] - m2*t) * (q[2] - m2 * t)

            d2 = max(-q[2], q[1] * m2 + q[2] * w) < 0f0 ? 0f0 : min(a, b)
            mantle_dist = sqrt((d2 + q[3] * q[3]) / m2)
            bottom_dist = norm(Vec3f(max(0f0, p[1]), max(0f0, p[2]), p[3]))
            _sign = sign(max(q[3], -p[3]))
            # mantle_dist does not consider the base, so it's wrong everywhere
            # under the base of the pyramid -> use bottom_dist if p[3] < 0
            # mantle_dist also does not consider the bottom inside, so it needs
            # to that might be closer. Outside outside mantle_dist is always
            # < bottom_dist, so we can just a min / ifelse(a < b, a, b)
            # mantle_dist also doesn't do corners right sigh
            return _sign * ifelse(p[3] < 0.0 || bottom_dist < mantle_dist, bottom_dist, mantle_dist)
        end

        # ::Command resolution for positions

        function evaluate_merge_command(command, sdf1, sdf2)
            Commands.is_merge(command.id) || error("$(command.id) should be a merge command")

            if command.id == Commands.op_union
                return min(sdf1, sdf2)
            elseif command.id == Commands.op_subtraction
                return max(sdf1, -sdf2)
            elseif command.id == Commands.op_intersection
                return max(sdf1, sdf2)
            elseif command.id == Commands.op_xor
                return max(min(sdf1, sdf2), -max(sdf1, sdf2))
            else # smooth cases
                smoothing = command.data[1]
                inv_smoothing = 1f0 / smoothing
                final_sign = -1f0
                if command.id == Commands.op_smooth_union
                    final_sign = 1f0
                elseif command.id == Commands.op_smooth_subtraction
                    sdf1 = -sdf1
                elseif command.id == Commands.op_smooth_intersection
                    sdf1 = -sdf1
                    sdf2 = -sdf2
                else
                    temp = -min(sdf1, sdf2)
                    sdf2 = max(sdf1, sdf2)
                    sdf1 = temp
                end

                h = 1f0 - min(0.25f0 * abs(sdf1 - sdf2) * inv_smoothing, 1f0)
                s = h * h * smoothing
                return final_sign * (min(sdf1, sdf2) - s)
            end
        end

        function smooth_union(sdf1, sdf2, smoothing)
            h = 1f0 - min(0.25f0 * abs(sdf1 - sdf2) / smoothing, 1f0)
            w = h * h
            m = 0.5f0 * w
            s = w * smoothing
            return m, s
        end

        function evaluate_merge_command_with_color(command, sdf1, sdf2, color1, color2)
            Commands.is_merge(command.id) || error("$(command.id) should be a merge command")

            if command.id == Commands.op_union
                left = sdf1 < sdf2
                return ifelse(left, sdf1, sdf2), ifelse(left, color1, color2)
            elseif command.id == Commands.op_subtraction
                return max(sdf1, -sdf2), color1
            elseif command.id == Commands.op_intersection
                left = sdf1 > sdf2
                return ifelse(left, sdf1, sdf2), ifelse(left, color1, color2)
            elseif command.id == Commands.op_xor
                color = ifelse(
                    sdf1 < sdf2,
                    ifelse(sdf1 > -sdf2, color1, color2),
                    ifelse(sdf2 > -sdf1, color2, color1),
                )
                sdf = max(min(sdf1, sdf2), -max(sdf1, sdf2))
                return sdf, color
            elseif command.id == Commands.op_smooth_union
                m, s = smooth_union(sdf1, sdf2, command.data[1])
                color = lerp(color1, color2, ifelse(sdf1 < sdf2, m, 1 - m))
                sdf = min(sdf1, sdf2) - s
                return sdf, color
            elseif command.id == Commands.op_smooth_subtraction
                m, s = smooth_union(sdf1, -sdf2, command.data[1])
                sdf = max(sdf1, -sdf2) + s
                return sdf, color1 # removed color should not affect final color
            elseif command.id == Commands.op_smooth_intersection
                m, s = smooth_union(sdf1, sdf2, command.data[1])
                color = lerp(color1, color2, ifelse(sdf1 > sdf2, m, 1 - m))
                sdf = max(sdf1, sdf2) + s
                return sdf, color
            elseif command.id == Commands.op_smooth_xor
                # color doesn't depend on the part that removed
                color = ifelse(sdf1 < sdf2, color1, color2)
                union = min(sdf1, sdf2)
                intersection = max(sdf1, sdf2)
                m, s = smooth_union(union, -intersection, command.data[1])
                sdf = max(union, -intersection) + s
                return sdf, color
            else
                error("Unknown command $(command.id)")
                return sdf1, color1
            end
            # cubic
            # smoothing *= 6f0
            # inv_smoothing = 1f0 / smoothing
            # h = max(smoothing -  abs(sdf1 - sdf2), 0f0) * inv_smoothing;
            # m = h * h * h * 0.5f0;
            # s = m * smoothing * 0.3333333333333333f0;
            # color1 = lerp(color1, color2, ifelse(sdf1 < sdf2, m, 1f0 - m))
            # sdf1 = final_sign * ifelse(sdf1 < sdf2, sdf1 - s, sdf2 - s)
        end

        function evaluate_prefix_command(command, pos)
            if command.id == Commands.op_revolution
                # TODO: arbitrary rotation around vec3? Or just force use of op_rotation...
                # float moves the 2d object away from th center of rotation
                # TODO: What should 2D shapes do with the third coordinate? What's neutral? Inf?
                return Point3f(xy_norm(pos) - command.data[1], pos.z, 0f0);
            elseif command.id == Commands.op_elongate
                return pos - clamp.(pos, -command.data, command.data);
            elseif command.id == Commands.op_rotation
                return reinterpret(Quaternionf, command.data) * pos
            elseif command.id == Commands.op_mirror
                # vec3 input is 1 (true) if the axis should be mirrored, 0 (false) otherwise
                return Makie.lerp.(pos, abs.(pos), command.data);
            elseif command.id == Commands.op_infinite_repetition
                return pos - command.data .* round(pos ./ command.data);
            elseif command.id == Commands.op_limited_repetition
                rep_dist = Vec3f(view(command.data, 1:3))
                limit = Vec3f(view(command.data, 4:6))
                return pos - rep_dist * clamp(round(pos ./ rep_dist), -limit, limit);
            elseif command.id == Commands.op_twist
                k = command.data[1];
                c = cos(k * pos.z);
                s = sin(k * pos.z);
                T = Makie.Mat2f(c, -s, s, c);
                return Point3f((T * pos[Vec(1, 2)])..., pos.z); # Quilez has this reorder (T*xz, y)
            elseif command.id == Commands.op_bend
                k = command.data[1];
                c = cos(k * pos.z);
                s = sin(k * pos.z);
                T = Makie.Mat2f(c, -s, s, c);
                p2 = T * Point2f(pos[1], pos[3])
                return Point3f(p2[1], pos[2], p2[2]) # Quilez has this not reorder (T*xy, z)
            elseif command.id == Commands.op_translation
                return pos .- Vec3f(command.data);
            end
            return pos
        end

        function evaluate_shape_command(command, pos)
            # data = ntuple(i -> command.data[i + 4], length(command.data) - 4)
            data = command.data

            if command.id == Commands.shape3D_sphere
                return sphere(pos, data[5])::Float32
            elseif command.id == Commands.shape3D_octahedron
                return octahedron(pos, data[5])::Float32
            elseif command.id == Commands.shape3D_pyramid
                return pyramid(pos, data[5], data[6])::Float32
            elseif command.id == Commands.shape3D_torus
                return torus(pos, data[5], data[6])::Float32
            elseif command.id == Commands.shape3D_capsule
                return capsule(pos, data[5], data[6])::Float32
            elseif command.id == Commands.shape3D_cylinder
                return cylinder(pos, data[5], data[6])::Float32
            elseif command.id == Commands.shape3D_ellipsoid
                return ellipsoid(pos, Vec3f(data[5], data[6], data[7]))::Float32
            elseif command.id == Commands.shape3D_rect
                return rect(pos, Vec3f(data[5], data[6], data[7]))::Float32
            elseif command.id == Commands.shape3D_link
                return link(pos, data[5], data[6], data[7])::Float32
            elseif command.id == Commands.shape3D_cone
                return cone(pos, data[5], data[6])::Float32
            elseif command.id == Commands.shape3D_capped_cone
                return capped_cone(pos, data[5], data[6], data[7])::Float32
            elseif command.id == Commands.shape3D_box_frame
                return box_frame(pos, Vec3f(data[5], data[6], data[7]), data[8])::Float32
            elseif command.id == Commands.shape3D_capped_torus
                return capped_torus(pos, data[5], data[6], data[7])::Float32
            else
                return 10_000f0
            end
        end

        function evaluate_postfix_command(command, pos, sdf)
            if command.id == Commands.op_extrusion
                vec = Vec2f(sdf, length(abs.(pos) .- command.data));
                sdf = min(max(vec[1], vec[2]), 0f0) + norm(max(vec, 0f0));
            elseif command.id == Commands.op_rounding
                sdf = sdf - command.data[1]
            elseif command.id == Commands.op_onion
                sdf = abs(sdf) - command.data[1]
            else
                return sdf
            end
        end

        function evaluate_command(command, pos::Point3f, sdf::Float32)
            if Commands.is_prefix(command.id)
                return evaluate_prefix_command(command, pos)::Point3f, sdf
            elseif Commands.is_shape(command.id)
                return pos, evaluate_shape_command(command, pos)::Float32
            elseif Commands.is_postfix(command.id)
                return pos, evaluate_postfix_command(command, pos, sdf)::Float32
            else
                error("Could not process $command")
            end
        end

        # ::Command resolution for Rect3f
        function bbox_from_shape(command)
            # strip color
            data = ntuple(i -> command.data[i + 4], length(command.data) - 4)

            # every bbox here is scaled from -1..1
            if command.id in (Commands.shape3D_sphere, Commands.shape3D_octahedron)
                return Rect3f(-Point3f(data[1]), Vec3f(2data[1]))
            elseif command.id in (Commands.shape3D_pyramid, Commands.shape3D_cylinder, Commands.shape3D_cone)
                r, h = data
                return Rect3f(-r, -r, -h, 2r, 2r, 2h)
            elseif command.id == Commands.shape3D_torus
                R, r = data
                return Rect3f(-R-r, -R-r, -r, 2*(R+r), 2*(R+r), 2r)
            elseif command.id == Commands.shape3D_capsule
                r, h = data
                return Rect3f(-r, -r, -(h+r), 2r, 2r, 2*(h+r))
            elseif command.id in (Commands.shape3D_ellipsoid, Commands.shape3D_rect)
                ws = Vec3f(data...)
                return Rect3f(-ws, 2.0 .* ws)
            elseif command.id == Commands.shape3D_link
                l, R, r = data
                return Rect3f(-(R+r), -(l+R+r), -r, 2*(R+r), 2*(l+R+r), 2r)
            elseif command.id == Commands.shape3D_capped_cone
                h, r1, r2 = data
                R = max(r1, r2)
                return Rect3f(-R, -R, -h, 2R, 2R, 2h)
            elseif command.id == Commands.shape3D_box_frame
                ws = data[Vec(1, 2, 3)]
                # w = data[4]
                # return Rect3f(.-(ws .+ 0.5 * w), 2 .* ws .+ w)
                return Rect3f(.-ws, 2 .* ws)
            elseif command.id == Commands.shape3D_capped_torus
                angle, R, r = data
                ymin = R * cos(min(angle, pi))
                dx = R * sin(min(angle, 0.5pi))
                return Rect3f(-dx-r, ymin-r, -r, 2*(dx+r), (R - ymin) + 2r, 2r)
            else
                return Rect3f()
            end
        end

        # @fastmath replaces minimum, maximum
        function apply_prefix(command, bb::Rect3f)
            mini = GeometryBasics.minimum(bb)
            maxi = GeometryBasics.maximum(bb)
            ws = widths(bb)
            if command.id == Commands.op_revolution
                # TODO: arbitrary rotation around vec3? Or just force use of op_rotation...
                # float moves the 2d object away from th center of rotation
                # TODO: What should 2D shapes do with the third coordinate? What's neutral? Inf?
                # TODO: test
                r = xy_norm(max(abs(mini), abs(maxi)))
                return Rect3f(-r, -r, mini[3], 2r, 2r, widths(bb)[3])
            elseif command.id == Commands.op_elongate
                return Rect3f(mini .- command.data, ws .+ 2 .* commanda.data)
            elseif command.id == Commands.op_rotation
                return rotate_bbox(reinterpret(Quaternionf, command.data), bb)
            elseif command.id == Commands.op_mirror
                # vec3 input is 1 (true) if the axis should be mirrored, 0 (false) otherwise
                sym_ws = max.(abs(mini), abs(maxi))
                mini = lerp.(mini, -sym_ws, command.data)
                maxi = lerp.(maxi, sym_ws, command.data)
                return Rect3f(mini, maxi .- mini)
            elseif command.id == Commands.op_infinite_repetition
                return Rect3f(Point3f(-Inf), Vec3f(Inf))
            elseif command.id == Commands.op_limited_repetition
                rep_dist = Vec3f(command.data[1:3])
                limit = Vec3f(command.data[4:6])
                mini = (limit .- 1) * rep_dist + max.(mini, -0.5 * rep_dist)
                maxi = (limit .- 1) * rep_dist + min.(maxi, 0.5 * rep_dist)
                return Rect3f(mini, maxi .- mini)
            elseif command.id == Commands.op_twist
                r = xy_norm(max.(abs(mini), abs(maxi)))
                return Rect3f(-r, -r, mini[3], 2r, 2r, ws[3])
            elseif command.id == Commands.op_bend
                # TODO: more precise
                r = norm(max.(abs(mini[Vec(1, 3)]), abs(maxi[Vec(1, 3)])))
                return Rect3f(-r, mini[2], -r, 2r, ws[2], 2r)
            elseif command.id == Commands.op_translation
                return bb + Point3f(command.data)
            end
            return bb
        end

        function apply_postfix(command, bb::Rect3f)
            mini = GeometryBasics.minimum(bb)
            ws = widths(bb)
            if command.id == Commands.op_extrusion
                e = command.data
                return Rect3f(mini .- Vec3f(0,0, e), ws .+ Vec3f(0, 0, 2e))
            elseif command.id in (Commands.op_rounding, Commands.op_onion)
                r = command.data[1]
                return Rect3f(mini .- r, ws .+ 2r)
            else
                return bb
            end
        end

        function apply_merge(command, bbs::Vector{Rect3f})
            Commands.is_merge(command.id) || error("$(command.id) should be a merge command")

            if length(bbs) == 0
                error("Can't merge nothing")
            elseif length(bbs) == 1
                return only(bbs)
            elseif command.id in (Commands.op_union, Commands.op_smooth_union)
                mini = mapreduce(GeometryBasics.minimum, (a, b) -> min.(a, b), bbs)
                maxi = mapreduce(GeometryBasics.maximum, (a, b) -> max.(a, b), bbs)
                return Rect3f(mini, maxi .- mini)
            elseif command.id in (Commands.op_subtraction, Commands.op_smooth_subtraction)
                # TODO:
                return first(bbs)
            elseif command.id in (Commands.op_intersection, Commands.op_smooth_intersection)
                return reduce(Base.intersect, bbs)
            elseif command.id in (Commands.op_xor, Commands.op_smooth_xor)
                # TODO:
                mini = mapreduce(GeometryBasics.minimum, min, bbs)
                maxi = mapreduce(GeometryBasics.maximum, max, bbs)
                return Rect3f(mini, maxi .- mini)
            end
            return Rect3f()
        end

        function get_shape_bbox(commands)
            idx = findfirst(cmd -> Commands.is_shape(cmd.id), commands)::Int
            bb = bbox_from_shape(commands[idx])
            for i in idx-1:-1:1
                bb = apply_prefix(commands[i], bb)
            end
            for i in idx+1:length(commands)
                bb = apply_postfix(commands[i], bb)
            end
            return bb
        end

    end

    ############################################################################
    ### SDF Tree
    ############################################################################

    struct Command
        id::Commands.ID
        data::Vector{Float32}

        function Command(id::Commands.ID, args...)
            data = mapreduce((a, b) -> Vec(a..., b...), args, init = Vec{0, Float32}()) do arg
                return Float32.(make_splattable(arg))
            end

            expected = Commands.get_num_parameters(id)
            if expected != length(data)
                op_name = Commands.get_name(id)
                throw(ArgumentError("$op_name requires $expected arguments, but $(length(data)) were given."))
            end

            return new(id, collect(data))
        end
    end

    make_splattable(x) = x
    make_splattable(q::Quaternion) = q.data
    make_splattable(c::RGBA) = reinterpret(Vec4f, c)

    struct Node
        # prefixes | shape or merge | postfixes
        commands::Vector{Command}
        main_idx::Int # index of shape or merge command
        children::Vector{Node}

        # aware of this node + children
        local_bbox::Rect3f
        # aware of all operations
        global_bbox::Base.RefValue{Rect3f}
    end

    function Shape(op::Symbol, args...; color = :orange, kwargs...)
        return Shape(Commands.get_id(op), args...; color = color, kwargs...)
    end

    function Shape(op::Commands.ID, args...; color = :orange, kwargs...)
        if !Commands.is_shape(op)
            ArgumentError("bad name")
        end

        main = Command(op, reinterpret(Vec4f, to_color(color)), args...)
        # This assumes kwargs are ordered
        commands, main_idx = process_commands(main, kwargs)

        bb = SDF.get_shape_bbox(commands)

        return Node(commands, main_idx, Node[], bb, Ref{Rect3f}())
    end

    function process_commands(main, ops)
        was_postfix = false
        commands = Command[]
        main_idx = 0

        prev = :nothing
        for (name, data) in ops
            id = Commands.get_id(name)

            if Commands.is_prefix(id) && was_postfix
                error("Can not apply prefix transformation $name after postfix transformation $prev")
            elseif Commands.is_shape_or_merge(id)
                error("$name is not a transformation.")
            end

            op = Command(id, data)
            if Commands.is_postfix(id) && !was_postfix
                push!(commands, main, op)
                main_idx = length(commands)
                was_postfix = true
            else
                push!(commands, op)
            end

            prev = name
        end

        if !was_postfix
            push!(commands, main)
            main_idx = length(commands)
        end

        return commands, main_idx
    end

    function Merge(op::Commands.ID, children::Tuple, args...; kwargs...)
        return Merge(op, collect(children), args...; kwargs...)
    end

    function Merge(op::Commands.ID, children::Vector{Node}, args...; kwargs...)
        if !Commands.is_merge(op)
            error("Merge nodes must be defined with merge commands")
        end

        commands = Command[Command(op, args)]
        for (name, data) in pairs(kwargs)
            id = Commands.get_id(name)

            if Commands.is_prefix(id)
                error("Merge nodes currently don't support prefix operations")
            elseif Commands.is_shape_or_merge(id)
                error("$name is not a transformation.")
            end

            push!(commands, Command(id, data))
        end

        bbs = map(child -> child.local_bbox, children)
        bb = apply_merge(commands[1], bbs)
        for i in 2:length(commands)
            bb = apply_postfix(commands[i], bb)
        end

        return Node(commands, 1, children, bb, Ref{Rect3f}())
    end

    union(children::Node...; kwargs...) = Merge(Commands.op_union, children; kwargs...)
    diff(children::Node...; kwargs...) = Merge(Commands.op_subtraction, children; kwargs...)
    subtract(children::Node...; kwargs...) = diff(children...; kwargs...)
    intersect(children::Node...; kwargs...) = Merge(Commands.op_intersection, children; kwargs...)
    xor(children::Node...; kwargs...) = Merge(Commands.op_xor, children; kwargs...)

    function smooth_union(children::Node...; smooth, kwargs...)
        return Merge(Commands.op_smooth_union, children, smooth; kwargs...)
    end
    smooth_subtract(children::Node...; kwargs...) = smooth_diff(children...; kwargs...)
    function smooth_diff(children::Node...; smooth, kwargs...)
        return Merge(Commands.op_smooth_subtraction, children, smooth; kwargs...)
    end
    function smooth_intersect(children::Node...; smooth, kwargs...)
        return Merge(Commands.op_smooth_intersection, children, smooth; kwargs...)
    end
    function smooth_xor(children::Node...; smooth, kwargs...)
        return Merge(Commands.op_smooth_xor, children, smooth; kwargs...)
    end

    function flatten_command_tree(node::Node, command_buffer = Command[])
        if isempty(node.children) # SDF shape node, just add all commands
            push!(command_buffer, Command(Commands._reset))
            append!(command_buffer, node.commands)

        elseif length(node.children) == 1

            # guess any kind of single node merge will just return the node?
            flatten_command_tree(node.children[1], command_buffer)
            append!(command_buffer, node.commands)

        else # merge node

            op = first(node.commands)

            # apply merge op asap so we don't have to track too many sdfs
            if op.id in (Commands.op_subtraction, Commands.op_smooth_subtraction)
                flatten_command_tree(node.children[1], command_buffer)
                flatten_command_tree(node.children[2], command_buffer)

                for i in 3:length(node.children)
                    flatten_command_tree(node.children[i], command_buffer)
                    push!(command_buffer, Command(Commands.op_union))
                end

                push!(command_buffer, op)
            else
                flatten_command_tree(node.children[1], command_buffer)

                for i in 2:length(node.children)
                    flatten_command_tree(node.children[i], command_buffer)
                    push!(command_buffer, op)
                end
            end

            append!(command_buffer, view(node.commands, 2:length(node.commands)))
        end

        return command_buffer
    end

    function gpu_representation(
            command_buffer::Vector{Command},
            id_buffer = UInt8[], data_buffer = Float32[]
        )

        for command in command_buffer
            push!(id_buffer, UInt8(command.id))
            append!(data_buffer, command.data)
        end

        return id_buffer, data_buffer
    end

    # complex later...
    # 1. collect leaf bbs in vector
    # 2. apply operations
    # 3. deposit leaf bbs & compute merged bbs

    # simple first!
    deref(x) = x
    deref(x::Base.RefValue) = x[]

    function apply_merge!(cmd::Command, left::Vector{Base.RefValue{Rect3f}}, right::Vector{Base.RefValue{Rect3f}})
        if cmd.id == Commands.op_subtraction
            # left: keep (may or may not be removed depending on right)
            # right: intersect (only matters if intersecting left)
            for b in right
                affected = Rect3f()
                for a in left
                    affected = Base.union(affected, Base.intersect(a[], b[]))
                end
                b[] = affected
            end
        elseif cmd.id == Commands.op_smooth_subtraction
            # Tighter solution?
            for b in right
                affected = Rect3f()
                for a in left
                    affected = Base.union(affected, Base.union(a[], b[]))
                end
                b[] = affected
            end
        elseif cmd.id in (Commands.op_intersection, Commands.op_smooth_intersection)
            # the result could be in any intersection created from any left and
            # any right boundingbox
            sleft = deref.(left)
            sright = deref.(right)
            foreach(bb -> bb[] = Rect3f(), left)
            foreach(bb -> bb[] = Rect3f(), right)
            for (ar, a) in zip(left, sleft)
                for (br, b) in zip(right, sright)
                    if overlaps(a, b)
                        intersection = Base.intersect(a, b)
                        ar[] = Base.union(ar[], intersection)
                        br[] = Base.union(br[], intersection)
                    end
                end
            end
        # elseif cmd.id == Commands.op_union
            # result is the combination of all bboxes
        # elseif cmd.id == Commands.op_xor
            # result could be anywhere in the union of left and right bboxes
        elseif cmd.id == Commands.op_smooth_xor
            append!(left, right)
            bb = foldl((a, b) -> Base.union(deref(a), deref(b)), left)
            foreach(x -> x[] = bb, left)
            return left
        elseif cmd.id == Commands.op_smooth_union
            # only case where smoothing is not reductive
            # TODO: Can we do better and apply a lower ceiling for the amount added here?
            r = cmd.data[1] # smoothing range
            append!(left, right)
            bb = foldl((a, b) -> Base.union(deref(a), deref(b)), left)
            bb = Rect3f(minimum(bb) .- r, widths(bb) .+ 2r)
            foreach(x -> x[] = bb, left)
            return left
        end
        append!(left, right)
        return left
    end

    function calculate_global_bboxes!(node::SDF.Node, bbs = Base.RefValue{Rect3f}[])
        if isempty(node.children) # leaf node
            node.global_bbox[] = node.local_bbox
            push!(bbs, node.global_bbox)

        else
            merge_cmd = node.commands[node.main_idx]

            left = calculate_global_bboxes!(node.children[1])
            right = Base.RefValue{Rect3f}[]
            for i in 2:length(node.children)
                calculate_global_bboxes!(node.children[i], right)
                @assert !isempty(right)
                apply_merge!(merge_cmd, left, right)
                empty!(right)
            end

            for i in node.main_idx+1 : length(node.commands)
                for bb in left
                    bb[] = apply_postfix(node.commands[i], bb[])
                end
            end

            append!(bbs, left)

            node.global_bbox[] = foldl((a, b) -> Base.union(deref(a), deref(b)), left)
            push!(bbs, node.global_bbox)
        end

        return bbs
    end

    is_inside(pos::Point3, node::Node, range) = is_inside(pos, node.global_bbox[], range)
    function is_inside(pos::Point3, bb::Rect3f, range)
        ws = 0.5 .* widths(bb)
        dist = rect(pos .- minimum(bb) .- ws, ws)
        return dist < range
    end

    function copy_node_without_children(node::Node)
        return Node(
            node.commands, node.main_idx, Node[],
            node.local_bbox, node.global_bbox
        )
    end

    function trimmed_tree(region::Rect3f, ref_tree::Node)
        new_tree = copy_node_without_children(ref_tree)
        return trimmed_tree_rec!(new_tree, region, ref_tree)
    end

    function trimmed_tree_rec!(parent::Node, region::Rect3f, ref_tree::Node)
        for child in ref_tree.children
            if overlaps(child.global_bbox[], region)
                node = copy_node_without_children(child)
                push!(parent.children, node)
                trimmed_tree_rec!(node, region, child)
            end
        end
        return parent
    end

    function compute_leaf_signed_distance_at(node::SDF.Node, pos)
        for i in 1:node.main_idx-1
            pos = evaluate_prefix_command(node.commands[i], pos)::Point3f
        end

        sdf = evaluate_shape_command(node.commands[node.main_idx], pos)::Float32

        for i in node.main_idx+1:length(node.commands)
            sdf = evaluate_postfix_command(node.commands[i], pos, sdf)::Float32
        end

        return sdf
    end

    function compute_signed_distance_at(node::SDF.Node, pos)
        if isempty(node.children)
            return compute_leaf_signed_distance_at(node, pos)
        else
            sdf = compute_signed_distance_at(node.children[1], pos)
            merge_cmd = node.commands[node.main_idx]
            for i in 2:length(node.children)
                other = compute_signed_distance_at(node.children[i], pos)
                sdf = evaluate_merge_command(merge_cmd, sdf, other)
            end
            for i in 2:length(node.commands)
                pos, sdf = evaluate_command(node.commands[i], pos, sdf)
            end
            return sdf
        end
    end

    function compute_color_at(node::SDF.Node, pos)
        # TODO: inbounds should be fine?
        @inbounds if isempty(node.children)
            sdf = compute_leaf_signed_distance_at(node, pos)
            data = node.commands[node.main_idx].data
            color = RGBAf(data[1], data[2], data[3], data[4])
            return sdf, color
        else
            sdf, color = compute_color_at(node.children[node.main_idx], pos)
            merge_cmd = first(node.commands)
            for i in 2:length(node.children)
                _sdf, _color = compute_color_at(node.children[i], pos)
                sdf, color = evaluate_merge_command_with_color(
                    merge_cmd, sdf, _sdf, color, _color
                )
            end
            for i in 2:length(node.commands)
                pos, sdf = evaluate_command(node.commands[i], pos, sdf)
            end
            return sdf, color
        end
    end

end


################################################################################
### Plot that evaluates SDF functions in shader
################################################################################


@recipe SDFScatter (commands::Vector{SDF.Command},) begin
    # bounding box settings:
    # - auto: derived from commands
    # - user given: whatever Rect3f is passed
    # - global: entire viewbox
    mixin_generic_plot_attributes()...
    mixin_shading_attributes()...
    # mixin_colormap_attributes()...
end

function convert_arguments(::Type{SDFScatter}, root::SDF.Node)
    return (SDF.flatten_command_tree(root),)
end

function register_sdfscatter_boundingbox!(attr)
    # # TODO:
    # map!(attr, :marker, :raw_marker_bbox) do marker
    #     return Rect3f(-1, -1, -1, 2, 2, 2)
    # end

    # map!(
    #     attr,
    #     [:raw_marker_bbox, :positions_transformed_f32c, :markersize, :rotation],
    #     [:marker_bbox, :N_elements]
    # ) do bboxes, positions, scales, rotations
    #     bbs = makie_broadcast(bboxes, positions, scales, rotations) do bb, pos, scale, rot
    #         # TODO: to_x is non-primitive compat (use convert_attribute)
    #         return to_rotation(rot) * (bb * to_3d_scale(scale)) + pos
    #     end
    #     return bbs, length(bbs)
    # end

    # map!(attr, :marker_bbox, :boundingbox) do bbs
    #     return reduce(update_boundingbox, bbs, init = Rect3f())
    # end

    # TODO:
    ComputePipeline.add_constant!(attr, :boundingbox, Rect3f(-1, -1, -1, 2, 2, 2))
    ComputePipeline.alias!(attr, :boundingbox, :data_limits)

    return
end

function calculated_attributes!(::Type{SDFScatter}, plot::Plot)
    attr = plot.attributes
    # TODO: non-primitive compat (use convert_attribute)
    # map!(to_color, attr, :color, :converted_color)
    # register_colormapping!(attr, :converted_color)
    register_sdfscatter_boundingbox!(attr)
    map!(SDF.gpu_representation, attr, :commands, [:id_buffer, :data_buffer])
    return
end

preferred_axis_type(::SDFScatter) = LScene

# TODO: temp stuff to deal with the plot not officially being primitive

function plot!(plot::SDFScatter)
    register_camera!(parent_scene(plot), plot)
    return
end


################################################################################
### CPU Version for volume plots
################################################################################


function generate_distance_field(bb::Rect3f, root::SDF.Node, N = 512)
    if !allequal(widths(bb))
        error("Bounding box must be a cube, i.e. equal widths, but has $(widths(bb))")
    end

    field = Array{Float16, 3}(undef, N, N, N)
    ranges = range.(minimum(bb), maximum(bb), length = N)
    normalization = Float32(1.0 / norm(widths(bb))) # TODO: 1.0 or 2.0?

    for (k, z) in enumerate(ranges[3])
        for (j, y) in enumerate(ranges[2])
            for (i, x) in enumerate(ranges[1])
                dist = SDF.compute_signed_distance_at(root, Point3f(x, y, z))
                field[i, j, k] = dist * normalization
            end
        end
    end

    return field
end

# function convert_arguments(::VolumeLike, x, y, z, node::SDF.Node)
#     ep_x = to_endpoints(x, "x", VolumeLike)
#     ep_y = to_endpoints(y, "y", VolumeLike)
#     ep_z = to_endpoints(z, "z", VolumeLike)
#     bb = Rect3f(
#         ep_x[1], ep_y[1], ep_z[1],
#         ep_x[2] - ep_x[1], ep_y[2] - ep_y[1], ep_z[2] - ep_z[1]
#     )
#     field = generate_distance_field(bb, node, 128)
#     return (ep_x, ep_y, ep_z, field)
# end


################################################################################
### Brickmaps for compression + performance
################################################################################


function Brickmap{T}(bricksize, _size; kwargs...) where {T}
    return Brickmap{T}(Makie.to3tuple(bricksize), Makie.to3tuple(_size); kwargs...)
end

function Brickmap{T}(bricksize::NTuple{3, Int}, _size::NTuple{3, Int}; kwargs...) where {T}
    bricks = Array{T, 3}[]
    idx_size = cld.(_size .- 1, bricksize .- 1)
    indices = fill(UInt32(0), idx_size)
    attributes = Dict{Symbol, Any}(kwargs)

    return Brickmap{T}(indices, bricks, attributes, _size, bricksize)
end

get_brick_index(bm::Brickmap, i, j, k) = bm.indexmap[i, j, k]
is_empty_brick(brick_idx) = brick_idx == 0
is_empty_brick(bm::Brickmap, i, j, k) = is_empty_brick(get_brick_index(bm, i, j, k))
get_brick(bm::Brickmap, brick_idx::Integer) = bm.bricks[brick_idx]
get_brick(bm::Brickmap, i, j, k) = get_brick(bm, get_brick_index(bm, i, j, k))

function get_value(bm::Brickmap, i, j, k)
    brick = get_brick(bm, cld.((i, j, k), bm.bricksize)...)
    bi, bj, bk = mod1.((i, j, k), bm.bricksize)
    return brick[bi, bj, bk]
end

function delete_brick!(bm::Brickmap, i, j, k)
    # TODO: this should probably be smarter to avoid moving data downstream...
    brick_idx = get_brick_index(bm, i, j, k)
    if !is_empty_brick(brick_idx)
        bm.indexmap[i, j, k] = UInt32(0)
        deleteat!(bm.bricks, brick_idx)
    end
    return
end

function insert_brick!(bm::Brickmap{T}, i, j, k, value::Array{T, 3}) where {T}
    if is_empty_brick(bm, i, j, k)
        unchecked_add_brick!(bm, i, j, k, value)
    else
        idx = get_brick_index(bm, i, j, k)
        bm.bricks[idx] = value
    end
    return
end

function unchecked_add_brick!(bm::Brickmap{T}, i, j, k, value::Array{T, 3}) where {T}
    idx = UInt32(length(bm.bricks) + 1)
    bm.indexmap[i, j, k] = idx
    push!(bm.bricks, value)
    return
end

function get_modifiable_brick(bm::Brickmap{T}, i, j, k) where {T}
    brick_idx = get_brick_index(bm, i, j, k)
    if is_empty_brick(brick_idx)
        A = Array{3, T}(undef, bm.bricksize)
        unchecked_add_brick!(bm, i, j, k, A)
        return A
    else
        return get_brick(bm, brick_idx)
    end
end

function Base.show(io::IO, ::MIME"text/plain", brickmap::Brickmap{T}) where {T}
    N, M = size(brickmap.indexmap)
    println(io, "$(brickmap.size[1])×$(brickmap.size[2]) Brickmap{$T}:")
    println(io, "  ", N, "×", M, " indices")
    print(io, "  $(length(brickmap.bricks)) bricks of size ", brickmap.bricksize[1], "×", brickmap.bricksize[2])
end

Base.getindex(b::Brickmap, s::Symbol) = b.attributes[s]

function pack_bricks(brickmap::Makie.Brickmap)
    packed, N = pack_bricks(brickmap.bricks, brickmap.bricksize)
    return packed
end

function pack_bricks(bricks, bricksize, skip = 0)
    N = ceil(Int, cbrt(length(bricks) + skip))
    T = eltype(eltype(bricks))
    packed = Array{T, 3}(undef, (N, N, N) .* bricksize)
    cart = CartesianIndices((N, N, N))
    for (idx, brick) in enumerate(bricks)
        i, j, k = Tuple(cart[idx + skip]) .- 1
        is = i * bricksize[1] + 1 : (i + 1) * bricksize[1]
        js = j * bricksize[2] + 1 : (j + 1) * bricksize[2]
        ks = k * bricksize[3] + 1 : (k + 1) * bricksize[3]
        copyto!(view(packed, is, js, ks), brick)
    end
    return packed, N
end

struct SparseBrickmapColors
    indexmap::Vector{Tuple{Bool, UInt32}}
    static_colors::Vector{RGB{N0f8}}
    color_bricks::Vector{Array{RGB{N0f8}, 3}}
end

function maybe_add_brick!(
        brickmap::Brickmap, root::SDF.Node,
        i, j, k,
        mini, delta, brick_delta,
        bricksize,
        uint8_scale,
        brick = Array{N0f8, 3}(undef, brickmap.bricksize),
        color_buffer = Array{RGB{N0f8}, 3}(undef, brickmap.bricksize)
    )
    origin = Point3f(mini + delta .* ((i, j, k) .- 1))
    reduced_tree = SDF.trimmed_tree(Rect3f(origin, delta), root)

    # > How aggresiively can we discard bricks?
    # For a volume shape, the worst case is brick[:, :, end] .== 0.0. Two bricks
    # share these values, but one brick will be entirely > 0.0, the other
    # entirely < 0.0. (Any other case will have a sign change in one of the bricks)
    # -> need at least <=, >=
    # for 0-width objects there is no < 0.0 to find. So we'd lose the object if
    # we don't include cases where distance < cellsize
    # -> need to keep every brick with abs(dist) < cellsize
    # this costs like 50% more memory though, so:
    # TODO: check if any shape is thin enough to cause issues
    # TODO: Or maybe add it as a conversion kwarg?
    contains_positive = false
    contains_negative = false
    contains_multiple_colors = false
    first_color_set = false
    first_color = RGB{N0f8}(1,0,1)

    for bk in 1:bricksize
        z = origin[3] + brick_delta[3] * (bk - 1)
        for bj in 1:bricksize
            y = origin[2] + brick_delta[2] * (bj - 1)
            for bi in 1:bricksize
                x = origin[1] + brick_delta[1] * (bi - 1)

                sdf, color = SDF.compute_color_at(reduced_tree, Point3f(x, y, z))

                # Note: converting to 0..1 and using the normal N0f8 constructor
                # is noticably slower
                # -celldiameter .. celldiameter ->  -127.5 .. 127.5
                f_normed = uint8_scale * sdf
                brick[bi, bj, bk] = N0f8(trunc(UInt8, clamp(f_normed + 128, 0, 255.9)), nothing)
                contains_negative |= sdf <= 0
                contains_positive |= sdf >= 0

                rgb8 = RGB{N0f8}(color)
                if !contains_multiple_colors && abs(f_normed) < 127.5f0
                    if !first_color_set
                        first_color = rgb8
                        first_color_set = true
                    elseif rgb8 != first_color
                        contains_multiple_colors = true
                    end
                end
                color_buffer[bi, bj, bk] = rgb8
            end
        end
    end

    # Less aggressive discard
    if any(x -> 0 < x < 1, brick)
        # Note: needs lock for multithreading
        insert_brick!(brickmap, i, j, k, copy(brick))

        bmc = brickmap[:color]::SparseBrickmapColors
        if contains_multiple_colors
            push!(bmc.color_bricks, copy(color_buffer))
            push!(bmc.indexmap, (false, length(bmc.color_bricks)))
        else
            idx = findfirst(==(first_color), bmc.static_colors)
            if isnothing(idx)
                push!(bmc.static_colors, first_color)
                push!(bmc.indexmap, (true, length(bmc.static_colors)))
            else
                push!(bmc.indexmap, (true, idx))
            end
        end

        return true
    end

    # if contains_negative && contains_positive # contains edge
    #     insert_brick!(brickmap, i, j, k, copy(brick))
    #     return true
    # end

    return false
end

function sdf_brickmap(bb::Rect3f, root::SDF.Node, N = 512, bricksize = 8)
    if !allequal(widths(bb))
        error("Bounding box must be a cube, i.e. equal widths, but has $(widths(bb))")
    end

    # left and right edge of the brickmap map to extrema of bb
    # each brick is a cell in the brickmap, so we need N-1 bricks to create N edges
    N_blocks = cld(N-1, bricksize-1)
    N = N_blocks * (bricksize-1) + 1

    brickmap_colors = SparseBrickmapColors(
        Tuple{Bool, UInt32}[], RGB{N0f8}[], Array{RGB{N0f8}, 3}[]
    )

    brickmap = Brickmap{N0f8}(bricksize, N, color = brickmap_colors)
    @assert all(==(N), brickmap.size)
    @assert all(==(N_blocks), size(brickmap.indexmap))

    box_scale = norm(widths(bb))
    brickdiameter = sqrt(3.0) * box_scale / (N_blocks - 1) # relative to bb
    brickradius = 0.5 * brickdiameter

    # step through coarse grid (N_blocks is the number of bricks/cells)
    delta = widths(bb) ./ N_blocks
    mini = minimum(bb)
    # step through brick grid (delta is the width of the brick, bricksize is edge-like)
    brick_delta = delta / (bricksize - 1)

    # -cellsize .. cellsize -> -127.5 .. 127.5
    # where cellsize is the (1, 1, 1) distance to the next entry
    uint8_scale = 127.5f0 * bricksize / brickdiameter

    # Note: one buffer per thread for multithreading, or create them per thread?
    brick_buffer = Array{N0f8, 3}(undef, brickmap.bricksize)
    color_buffer = Array{RGB{N0f8}, 3}(undef, brickmap.bricksize)

    bbs = SDF.calculate_global_bboxes!(root)
    foreach(bbs) do bb_ref
        bb_ref[] = Rect(minimum(bb_ref[]) .- delta, widths(bb_ref[]) .+ 2delta)
    end

    content_count = 0
    content_count2 = 0

    for k in 1:N_blocks
        z = mini[3] + delta[3] * (k - 0.5)
        for j in 1:N_blocks
            y = mini[2] + delta[2] * (j - 0.5)
            for i in 1:N_blocks
                x = mini[1] + delta[1] * (i - 0.5)

                pos = Point3f(x, y, z)
                if SDF.is_inside(pos, root, brickradius)
                    content_count += 1

                    # check if brick could contain edge based on center
                    dist = SDF.compute_signed_distance_at(root, pos)
                    if abs(dist) < brickradius
                        content_count2 += maybe_add_brick!(
                            brickmap, root, i, j, k,
                            mini, delta, brick_delta,
                            bricksize, uint8_scale,
                            brick_buffer, color_buffer
                        )
                    end

                end
            end
        end
    end

    @info "Rect Skipped $(100 - 100 * content_count / (N_blocks^3))%"
    @info "SDF  Skipped $(100 - 100 * content_count2 / (N_blocks^3))%"
    @info "Relative     $(100 - 100 * content_count2 / content_count)%"

    return brickmap
end

function convert_arguments(::VolumeLike, x, y, z, node::SDF.Node)
    ep_x = to_endpoints(x, "x", VolumeLike)
    ep_y = to_endpoints(y, "y", VolumeLike)
    ep_z = to_endpoints(z, "z", VolumeLike)
    bb = Rect3f(
        ep_x[1], ep_y[1], ep_z[1],
        ep_x[2] - ep_x[1], ep_y[2] - ep_y[1], ep_z[2] - ep_z[1]
    )
    N = 512 # 1024
    @time brickmap = sdf_brickmap(bb, node, N)
    @info "$N^3 $(N^3 * 4 / 1024^2)MB ->"
    return (ep_x, ep_y, ep_z, brickmap)
end

function pack_brick_colors(brickmap::Brickmap, colors::SparseBrickmapColors)
    bricksize = brickmap.bricksize
    entries_per_brick = prod(bricksize)
    n_static_color_bricks = max(1, cld(length(colors.static_colors), entries_per_brick))

    # TODO: probably needs to be a 2D array
    pack_length = length(colors.indexmap)
    pack_height = max(1, cld(pack_length, 8192))
    pack_width = cld(pack_length, pack_height)
    packed_indices = Matrix{UInt32}(undef, pack_width, pack_height)

    map!(packed_indices, colors.indexmap) do (is_static, index)
        # -1 for zero based indices
        # +n_static_color_bricks so we skip over bricks used for static colors
        idx = index - UInt32(1) + ifelse(is_static, UInt32(0), UInt32(n_static_color_bricks))
        # left most bit marks static vs interpolated colors
        return (UInt32(is_static) << 31) | idx
    end

    # generate normal bricks, skipping n_static_color_bricks
    packed_bricks, N = pack_bricks(colors.color_bricks, bricksize, n_static_color_bricks)

    # fill out static color bricks
    cart = CartesianIndices((N, N, N))
    for n in 1:n_static_color_bricks
        ijk = Tuple(cart[n])
        rx, ry, rz = range.(((ijk .- 1) .* bricksize .+ 1), (ijk .* bricksize))
        brick = view(packed_bricks, rx, ry, rz)

        input_range = range(
            (n - 1) * entries_per_brick + 1,
            min(n * entries_per_brick, length(colors.static_colors))
        )
        for (brick_idx, color_idx) in enumerate(input_range)
            brick[brick_idx] = colors.static_colors[color_idx]
        end
    end


    return packed_indices, packed_bricks
end
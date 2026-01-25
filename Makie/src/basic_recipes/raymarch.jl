module SDF
    using LinearAlgebra
    using GeometryBasics
    using GeometryBasics: VecTypes
    using ...Makie
    using ...Makie: Quaternion, RGBA

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

    begin
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

        function evaluate_merge_command(command, sdfs)
            Commands.is_merge(command.id) || error("$(command.id) should be a merge command")

            if command.id == Commands.op_union
                return minimum(sdfs)
            elseif command.id == Commands.op_subtraction
                return max(-first(sdfs), minimum(view(sdfs, 2:length(sdfs))))
            elseif command.id == Commands.op_intersection
                return maximum(sdfs)
            elseif command.id == Commands.op_xor
                return reduce(sdfs, init = Inf32) do sdf1, sdf2
                    return max(min(sdf1, sdf2), -max(sdf1, sdf2))
                end
            else # smooth cases
                smoothing = command.data[1]
                inv_smoothing = 1f0 / smoothing
                return reduce(sdfs) do sdf1, sdf2
                    final_sign = -1f0
                    if command.id == Commands.op_smooth_union
                        final_sign = 1f0
                    elseif command.id == Commands.op_smooth_subtraction
                        sdf2 = -sdf2
                    elseif command.id == Commands.op_smooth_intersection
                        sdf1 = -sdf1
                        sdf2 = -sdf2
                    else
                        temp = min(sdf1, sdf2)
                        sdf2 = -max(sdf1, sdf2)
                        sdf1 = temp
                    end

                    h = 1f0 - min(0.25f0 * abs(sdf1 - sdf2) * inv_smoothing, 1f0)
                    w = h * h
                    # m = 0.5 * w
                    s = w * smoothing
                    return _sign * (ifelse(sdf1 < sdf2, sdf1, sdf2) - s)
                end::Float32
            end
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

        function apply_prefix(command, bb::Rect3f)
            mini = minimum(bb)
            maxi = maximum(bb)
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
            mini = minimum(bb)
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
                mini = mapreduce(minimum, (a, b) -> min.(a, b), bbs)
                maxi = mapreduce(maximum, (a, b) -> max.(a, b), bbs)
                return Rect3f(mini, maxi .- mini)
            elseif command.id in (Commands.op_subtraction, Commands.op_smooth_subtraction)
                # TODO:
                return first(bbs)
            elseif command.id in (Commands.op_intersection, Commands.op_smooth_intersection)
                return reduce(intersect, bbs)
            elseif command.id in (Commands.op_xor, Commands.op_smooth_xor)
                # TODO:
                mini = mapreduce(minimum, min, bbs)
                maxi = mapreduce(maximum, max, bbs)
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
        children::Vector{Node}
        bbox::Rect3f
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
        commands = process_commands(main, kwargs)

        bb = SDF.get_shape_bbox(commands)

        return Node(commands, Node[], bb)
    end

    function process_commands(main, ops)
        was_postfix = false
        commands = Command[]

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
                was_postfix = true
            else
                push!(commands, op)
            end

            prev = name
        end

        was_postfix || push!(commands, main)

        return commands
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

        bbs = map(child -> child.bbox, children)
        bb = apply_merge(commands[1], bbs)
        for i in 2:length(commands)
            bb = apply_postfix(commands[i], bb)
        end

        return Node(commands, children, bb)
    end

    union(children::Node...; kwargs...) = Merge(Commands.op_union, children; kwargs...)
    diff(children::Node...; kwargs...) = Merge(Commands.op_subtraction, children; kwargs...)
    intersect(children::Node...; kwargs...) = Merge(Commands.op_intersection, children; kwargs...)
    xor(children::Node...; kwargs...) = Merge(Commands.op_xor, children; kwargs...)

    function smooth_union(children::Node...; smooth, kwargs...)
        return Merge(Commands.op_smooth_union, children, smooth; kwargs...)
    end
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

    # TODO: correct merging
    function is_inside_sdf(node::SDF.Node, pos)
        if pos in node.bbox
            if isempty(node.children)
                return true
            else
                for child in node.children
                    if is_inside_sdf(child, pos)
                        return true
                    end
                end
                return false
            end
        else
            return false
        end
    end

    function is_inside_sdf(node::SDF.Node, pos, range)
        ws = 0.5 .* widths(node.bbox)
        dist = rect(pos .- minimum(node.bbox) .- ws, ws)
        if dist < range
            if isempty(node.children)
                return true
            else
                for child in node.children
                    if is_inside_sdf(child, pos, range)
                        return true
                    end
                end
                return false
            end
        else
            return false
        end
    end

    const SDF_buffer = Float32[]
    function compute_signed_distance_at(node::SDF.Node, pos)
        if isempty(node.children)
            sdf = NaN32
            for command in node.commands
                pos, sdf = evaluate_command(command, pos, sdf)
            end
            return sdf
        else
            resize!(SDF_buffer, length(node.children))
            for i in eachindex(node.children)
                SDF_buffer[i] = compute_signed_distance_at(node.children[i], pos)
            end
            sdf = evaluate_merge_command(first(node.commands), SDF_buffer)
            for i in 2:length(node.commands)
                pos, sdf = evaluate_command(node.commands[i], pos, sdf)
            end
            return sdf
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


function Brickmap{T}(bricksize, _size) where {T}
    return Brickmap{T}(Makie.to3tuple(bricksize), Makie.to3tuple(_size))
end

function Brickmap{T}(bricksize::NTuple{3, Int}, _size::NTuple{3, Int}) where {T}
    bricks = Array{T, 3}[]
    idx_size = cld.(_size .- 1, bricksize .- 1)
    indices = fill(UInt32(0), idx_size)
    brick_buffer = Array{T, 3}(undef, bricksize)

    return Brickmap{T}(indices, bricks, _size, bricksize, brick_buffer)
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

function maybe_add_brick!(
        brickmap::Brickmap, root::SDF.Node,
        i, j, k,
        mini, delta, brick_delta,
        bricksize,
        uint8_scale
    )
    brick = brickmap.brick_buffer
    origin = Point3f(mini + delta .* ((i, j, k) .- 1))

    # check if edge is contained
    # otherwise we can throw this away
    contains_positive = false
    contains_negative = false

    for bk in 1:bricksize
        z = origin[3] + brick_delta[3] * (bk - 1)
        for bj in 1:bricksize
            y = origin[2] + brick_delta[2] * (bj - 1)
            for bi in 1:bricksize
                x = origin[1] + brick_delta[1] * (bi - 1)
                dist = SDF.compute_signed_distance_at(root, Point3f(x, y, z))
                # -celldiameter .. celldiameter -> 0..255
                f_normed = clamp(uint8_scale * dist + 0.5f0, 0f0, 1f0)
                brick[bi, bj, bk] = N0f8(f_normed)
                contains_negative |= dist < 0
                contains_positive |= dist > 0
            end
        end
    end

    # Hmm...
    # Can we skip a brick that remains more than cellsize away?
    # if !all(==(0xff), brick)
    #     insert_brick!(brickmap, i, j, k, brick)
    # end

    if contains_negative && contains_positive # contains edge
        insert_brick!(brickmap, i, j, k, copy(brick))
        return true
    end

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

    brickmap = Brickmap{N0f8}(bricksize, N)
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

    uint8_scale = 0.5f0 * bricksize / brickdiameter

    content_count = 0
    content_count2 = 0

    for k in 1:N_blocks
        z = mini[3] + delta[3] * (k - 0.5)
        for j in 1:N_blocks
            y = mini[2] + delta[2] * (j - 0.5)
            for i in 1:N_blocks
                x = mini[1] + delta[1] * (i - 0.5)

                pos = Point3f(x, y, z)
                if SDF.is_inside_sdf(root, pos, brickradius)
                    content_count += 1

                    # check if brick could contain edge based on center
                    dist = SDF.compute_signed_distance_at(root, pos)
                    if abs(dist) < brickradius
                        content_count2 += maybe_add_brick!(
                            brickmap, root, i, j, k,
                            mini, delta, brick_delta,
                            bricksize, uint8_scale
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
    @info "$(N^3 * 4 / 1024^2)MB ->"
    return (ep_x, ep_y, ep_z, brickmap)
end
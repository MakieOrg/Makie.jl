module SDF
    using LinearAlgebra
    using GeometryBasics
    using GeometryBasics: VecTypes
    using ...Makie: Quaternion, RGBAf, lerp
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

    # module this?
    module OP
    @fastmath begin
        using LinearAlgebra
        using GeometryBasics
        using Makie: Quaternionf, lerp, VecTypes

        sign1(x::Real) = ifelse(signbit(x), -one(x), +one(x))
        sign1(x::VecTypes) = sign1.(x)
        norm2(v::VecTypes) = dot(v, v)
        xy_norm(p) = norm(p[Vec(1, 2)])
        xy_norm2(p) = norm2(p[Vec(1, 2)])

        ########################################################################
        # SDF functions
        ########################################################################

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


        ########################################################################
        # prefix functions
        ########################################################################

        # TODO: arbitrary rotation around vec3? Or just force use of op_rotation...
        # float moves the 2d object away from th center of rotation
        # TODO: What should 2D shapes do with the third coordinate? What's neutral? Inf?
        revolution(pos, radius::Float32) = Point3f(xy_norm(pos) - radius, pos.z, 0f0)
        elongate(pos, v::Vec3f) = pos - clamp.(pos, -v, v)
        rotation(pos, q::Quaternionf) = q * pos

        # vec3 input is 1 (true) if the axis should be mirrored, 0 (false) otherwise
        mirror(pos, should_mirror::Vec3f) = lerp.(pos, abs.(pos), should_mirror)
        infinite_repetition(pos, periods::Vec3f) = pos - periods .* round(pos ./ periods)

        function limited_repetition(pos, periods::Vec3f, limits::Vec3f)
            return pos - periods * clamp(round(pos ./ periods), -limits, limits)
        end

        function twist(pos, factor::Float32)
            c = cos(factor * pos.z);
            s = sin(factor * pos.z);
            T = Mat2f(c, -s, s, c);
            return Point3f((T * pos[Vec(1, 2)])..., pos.z); # Quilez has this reorder (T*xz, y)
        end

        function bend(pos, factor::Float32)
            c = cos(factor * pos.z);
            s = sin(factor * pos.z);
            T = Mat2f(c, -s, s, c);
            p2 = T * Point2f(pos[1], pos[3])
            return Point3f(p2[1], pos[2], p2[2]) # Quilez has this not reorder (T*xy, z)
        end

        translation(pos, offset::Vec3f) = pos .- offset

        ########################################################################
        # merge functions
        ########################################################################

        union(sdf1, sdf2) = min(sdf1, sdf2)
        difference(sdf1, sdf2) = max(sdf1, -sdf2)
        intersection(sdf1, sdf2) = max(sdf1, sdf2)
        xor(sdf1, sdf2) = max(min(sdf1, sdf2), -max(sdf1, sdf2))

        function smooth_union(sdf1, sdf2, smoothing)
                inv_smoothing = 1f0 / smoothing
                h = 1f0 - min(0.25f0 * abs(sdf1 - sdf2) * inv_smoothing, 1f0)
                s = h * h * smoothing
                return min(sdf1, sdf2) - s
        end
        smooth_difference(sdf1, sdf2, smoothing) = -smooth_union(-sdf1, sdf2, smoothing)
        smooth_intersection(sdf1, sdf2, smoothing) = -smooth_union(-sdf1, -sdf2, smoothing)
        smooth_xor(sdf1, sdf2, smoothing) = -smooth_union(-min(sdf1, sdf2), max(sdf1, sdf2), smoothing)

        # with color

        function union(sdf1, sdf2, color1, color2)
            return ifelse(sdf1 < sdf2, sdf1, sdf2), ifelse(sdf1 < sdf2, color1, color2)
        end

        # TODO: should this always be the color of what's being subtracted from?
        # Or the closest (which is always the second)?
        # Or maybe ifelse(alpha(color2) == 0, color1, color2) ?
        function difference(sdf1, sdf2, color1, color2)
            return max(sdf1, -sdf2), color1
            # return max(sdf1, -sdf2), ifelse(sdf1 > -sdf2, color1, color2)
        end

        function intersection(sdf1, sdf2, color1, color2)
            return ifelse(sdf1 > sdf2, sdf1, sdf2), ifelse(sdf1 > sdf2, color1, color2)
        end

        function xor(sdf1, sdf2, color1, color2)
            color = ifelse(
                sdf1 < sdf2,
                ifelse(sdf1 > -sdf2, color1, color2),
                ifelse(sdf2 > -sdf1, color2, color1),
            )
            sdf = max(min(sdf1, sdf2), -max(sdf1, sdf2))
            return sdf, color
        end

        function smooth_union_factors(sdf1, sdf2, smoothing)
            h = 1f0 - min(0.25f0 * abs(sdf1 - sdf2) / smoothing, 1f0)
            w = h * h
            m = 0.5f0 * w
            s = w * smoothing
            return m, s
        end

        function smooth_union(sdf1, sdf2, color1, color2, smoothing)
            m, s = smooth_union_factors(sdf1, sdf2, smoothing)
            color = lerp(color1, color2, ifelse(sdf1 < sdf2, m, 1 - m))
            sdf = min(sdf1, sdf2) - s
            return sdf, color
        end

        function smooth_difference(sdf1, sdf2, color1, color2, smoothing)
            m, s = smooth_union_factors(sdf1, -sdf2, smoothing)
            sdf = max(sdf1, -sdf2) + s
            return sdf, color1 # removed color should not affect final color
        end

        function smooth_intersection(sdf1, sdf2, color1, color2, smoothing)
            m, s = smooth_union_factors(sdf1, sdf2, smoothing)
            color = lerp(color1, color2, ifelse(sdf1 > sdf2, m, 1 - m))
            sdf = max(sdf1, sdf2) + s
            return sdf, color
        end

        function smooth_xor(sdf1, sdf2, color1, color2, smoothing)
            # color doesn't depend on the part that removed
            color = ifelse(sdf1 < sdf2, color1, color2)
            union = min(sdf1, sdf2)
            intersection = max(sdf1, sdf2)
            m, s = smooth_union_factors(union, -intersection, smoothing)
            sdf = max(union, -intersection) + s
            return sdf, color
        end

        ########################################################################
        # postfix functions
        ########################################################################

        function extrusion(pos, sdf, by::Vec3f)
            vec = Vec2f(sdf, norm(abs.(pos) .- by));
            return min(max(vec[1], vec[2]), 0f0) + norm(max(vec, 0f0))
        end

        rounding(pos, sdf, range::Float32) = sdf - range
        onion(pos, sdf, thickness::Float32) = abs(sdf) - thickness

    end # fastmath
    end

    function evaluate_prefix_command(command, pos)
        # Indexing directly is very beneficial here (indirect @inbounds)
        data = command.data
        if command.id == Commands.op_revolution
            return OP.revolution(pos, data[1])
        elseif command.id == Commands.op_elongate
            return OP.elongate(pos, Vec3f(data[1], data[2], data[3]))
        elseif command.id == Commands.op_rotation
            return OP.rotation(pos, Quaternionf(data[1], data[2], data[3], data[4]))
        elseif command.id == Commands.op_mirror
            return OP.mirror(pos, Vec3f(data[1], data[2], data[3]))
        elseif command.id == Commands.op_infinite_repetition
            return OP.infinite_repetition(pos, Vec3f(data[1], data[2], data[3]))
        elseif command.id == Commands.op_limited_repetition
            periods = Vec3f(data[1], data[2], data[3])
            limits = Vec3f(data[4], data[5], data[6])
            return OP.limited_repetition(pos, periods, limits)
        elseif command.id == Commands.op_twist
            return OP.twist(pos, data[1])
        elseif command.id == Commands.op_bend
            return OP.bend(pos, data[1])
        elseif command.id == Commands.op_translation
            return OP.translation(pos, Vec3f(data[1], data[2], data[3]))
        else
            error("Unrecognized prefix command $(command.id)")
        end
        return pos
    end

    function evaluate_shape_command(command, pos)
        # data = ntuple(i -> command.data[i + 4], length(command.data) - 4)
        data = command.data

        if command.id == Commands.shape3D_sphere
            return OP.sphere(pos, data[5])
        elseif command.id == Commands.shape3D_octahedron
            return OP.octahedron(pos, data[5])
        elseif command.id == Commands.shape3D_pyramid
            return OP.pyramid(pos, data[5], data[6])
        elseif command.id == Commands.shape3D_torus
            return OP.torus(pos, data[5], data[6])
        elseif command.id == Commands.shape3D_capsule
            return OP.capsule(pos, data[5], data[6])
        elseif command.id == Commands.shape3D_cylinder
            return OP.cylinder(pos, data[5], data[6])
        elseif command.id == Commands.shape3D_ellipsoid
            return OP.ellipsoid(pos, Vec3f(data[5], data[6], data[7]))
        elseif command.id == Commands.shape3D_rect
            return OP.rect(pos, Vec3f(data[5], data[6], data[7]))
        elseif command.id == Commands.shape3D_link
            return OP.link(pos, data[5], data[6], data[7])
        elseif command.id == Commands.shape3D_cone
            return OP.cone(pos, data[5], data[6])
        elseif command.id == Commands.shape3D_capped_cone
            return OP.capped_cone(pos, data[5], data[6], data[7])
        elseif command.id == Commands.shape3D_box_frame
            return OP.box_frame(pos, Vec3f(data[5], data[6], data[7]), data[8])
        elseif command.id == Commands.shape3D_capped_torus
            return OP.capped_torus(pos, data[5], data[6], data[7])
        else
            error("Unrecognized shape command $(command.id)")
            return 10_000f0
        end
    end

    function evaluate_merge_command(command, sdf1, sdf2)
        if command.id == Commands.op_union
            return OP.union(sdf1, sdf2)
        elseif command.id == Commands.op_subtraction
            return OP.difference(sdf1, sdf2)
        elseif command.id == Commands.op_intersection
            return OP.intersection(sdf1, sdf2)
        elseif command.id == Commands.op_xor
            return OP.xor(sdf1, sdf2)
        elseif command.id == Commands.op_smooth_union
            return OP.smooth_union(sdf1, sdf2, command.data[1])
        elseif command.id == Commands.op_smooth_subtraction
            return OP.smooth_difference(sdf1, sdf2, command.data[1])
        elseif command.id == Commands.op_smooth_intersection
            return OP.smooth_intersection(sdf1, sdf2, command.data[1])
        elseif command.id == Commands.op_smooth_xor
            return OP.smooth_xor(sdf1, sdf2, command.data[1])
        else
            error("$(command.id) is not a recognized merge command")
        end
    end

    function evaluate_merge_command(command, sdf1, sdf2, color1, color2)
        if command.id == Commands.op_union
            return OP.union(sdf1, sdf2, color1, color2)
        elseif command.id == Commands.op_subtraction
            return OP.difference(sdf1, sdf2, color1, color2)
        elseif command.id == Commands.op_intersection
            return OP.intersection(sdf1, sdf2, color1, color2)
        elseif command.id == Commands.op_xor
            return OP.xor(sdf1, sdf2, color1, color2)
        elseif command.id == Commands.op_smooth_union
            return OP.smooth_union(sdf1, sdf2, color1, color2, command.data[1])
        elseif command.id == Commands.op_smooth_subtraction
            return OP.smooth_difference(sdf1, sdf2, color1, color2, command.data[1])
        elseif command.id == Commands.op_smooth_intersection
            return OP.smooth_intersection(sdf1, sdf2, color1, color2, command.data[1])
        elseif command.id == Commands.op_smooth_xor
            return OP.smooth_xor(sdf1, sdf2, color1, color2, command.data[1])
        else
            error("$(command.id) is not a recognized merge command")
        end
    end

    function evaluate_postfix_command(command, pos, sdf)
        data = command.data
        if command.id == Commands.op_extrusion
            return OP.extrusion(pos, sdf, Vec3f(data[1], data[2], data[3]))
        elseif command.id == Commands.op_rounding
            return OP.rounding(pos, sdf, command.data[1])
        elseif command.id == Commands.op_onion
            return OP.onion(pos, sdf, command.data[1])
        else
            error("$(command.id) is not a recognized postfix command.")
            return sdf
        end
    end

    function evaluate_command(command, pos, sdf)
        if Commands.is_prefix(command.id)
            return evaluate_prefix_command(command, pos), sdf
        elseif Commands.is_shape(command.id)
            return pos, evaluate_shape_command(command, pos)
        elseif Commands.is_postfix(command.id)
            return pos, evaluate_postfix_command(command, pos, sdf)
        else
            error("Could not process $command")
        end
    end

    function evaluate_prefix_command!(command, pos::Array)
        # Indexing directly is very beneficial here (indirect @inbounds)
        data = command.data
        if command.id == Commands.op_revolution
            pos .= OP.revolution.(pos, data[1])
        elseif command.id == Commands.op_elongate
            pos .= OP.elongate.(pos, Ref(Vec3f(data[1], data[2], data[3])))
        elseif command.id == Commands.op_rotation
            pos .= OP.rotation.(pos, Ref(Quaternionf(data[1], data[2], data[3], data[4])))
        elseif command.id == Commands.op_mirror
            pos .= OP.mirror.(pos, Ref(Vec3f(data[1], data[2], data[3])))
        elseif command.id == Commands.op_infinite_repetition
            pos .= OP.infinite_repetition.(pos, Ref(Vec3f(data[1], data[2], data[3])))
        elseif command.id == Commands.op_limited_repetition
            periods = Vec3f(data[1], data[2], data[3])
            limits = Vec3f(data[4], data[5], data[6])
            pos .= OP.limited_repetition.(pos, Ref(periods), Ref(limits))
        elseif command.id == Commands.op_twist
            pos .= OP.twist.(pos, data[1])
        elseif command.id == Commands.op_bend
            pos .= OP.bend.(pos, data[1])
        elseif command.id == Commands.op_translation
            pos .= OP.translation.(pos, Ref(Vec3f(data[1], data[2], data[3])))
        else
            error("Unrecognized prefix command $(command.id)")
        end
        return pos
    end

    function evaluate_shape_command!(command, pos::Array, sdf::Array)
        # data = ntuple(i -> command.data[i + 4], length(command.data) - 4)
        data = command.data

        if command.id == Commands.shape3D_sphere
            sdf .= OP.sphere.(pos, data[5])
        elseif command.id == Commands.shape3D_octahedron
            sdf .= OP.octahedron.(pos, data[5])
        elseif command.id == Commands.shape3D_pyramid
            sdf .= OP.pyramid.(pos, data[5], data[6])
        elseif command.id == Commands.shape3D_torus
            sdf .= OP.torus.(pos, data[5], data[6])
        elseif command.id == Commands.shape3D_capsule
            sdf .= OP.capsule.(pos, data[5], data[6])
        elseif command.id == Commands.shape3D_cylinder
            sdf .= OP.cylinder.(pos, data[5], data[6])
        elseif command.id == Commands.shape3D_ellipsoid
            sdf .= OP.ellipsoid.(pos, Ref(Vec3f(data[5], data[6], data[7])))
        elseif command.id == Commands.shape3D_rect
            sdf .= OP.rect.(pos, Ref(Vec3f(data[5], data[6], data[7])))
        elseif command.id == Commands.shape3D_link
            sdf .= OP.link.(pos, data[5], data[6], data[7])
        elseif command.id == Commands.shape3D_cone
            sdf .= OP.cone.(pos, data[5], data[6])
        elseif command.id == Commands.shape3D_capped_cone
            sdf .= OP.capped_cone.(pos, data[5], data[6], data[7])
        elseif command.id == Commands.shape3D_box_frame
            sdf .= OP.box_frame.(pos, Ref(Vec3f(data[5], data[6], data[7])), data[8])
        elseif command.id == Commands.shape3D_capped_torus
            sdf .= OP.capped_torus.(pos, data[5], data[6], data[7])
        else
            error("Unrecognized shape command $(command.id)")
            sdf .= 10_000f0
        end
        return sdf
    end

    function evaluate_merge_command!(command, sdf1::Array, sdf2::Array)
        if command.id == Commands.op_union
            sdf1 .= OP.union.(sdf1, sdf2)
        elseif command.id == Commands.op_subtraction
            sdf1 .= OP.difference.(sdf1, sdf2)
        elseif command.id == Commands.op_intersection
            sdf1 .= OP.intersection.(sdf1, sdf2)
        elseif command.id == Commands.op_xor
            sdf1 .= OP.xor.(sdf1, sdf2)
        elseif command.id == Commands.op_smooth_union
            sdf1 .= OP.smooth_union.(sdf1, sdf2, command.data[1])
        elseif command.id == Commands.op_smooth_subtraction
            sdf1 .= OP.smooth_difference.(sdf1, sdf2, command.data[1])
        elseif command.id == Commands.op_smooth_intersection
            sdf1 .= OP.smooth_intersection.(sdf1, sdf2, command.data[1])
        elseif command.id == Commands.op_smooth_xor
            sdf1 .= OP.smooth_xor.(sdf1, sdf2, command.data[1])
        else
            error("$(command.id) is not a recognized merge command")
        end
        return sdf1
    end

    function evaluate_merge_command!(command, sdf1::Array, sdf2::Array, color1::Array, color2::Array)
        if command.id == Commands.op_union
            for i in eachindex(sdf1)
                sdf1[i], color1[i] = OP.union(sdf1[i], sdf2[i], color1[i], color2[i])
            end
        elseif command.id == Commands.op_subtraction
            for i in eachindex(sdf1)
                sdf1[i], color1[i] = OP.difference(sdf1[i], sdf2[i], color1[i], color2[i])
            end
        elseif command.id == Commands.op_intersection
            for i in eachindex(sdf1)
                sdf1[i], color1[i] = OP.intersection(sdf1[i], sdf2[i], color1[i], color2[i])
            end
        elseif command.id == Commands.op_xor
            for i in eachindex(sdf1)
                sdf1[i], color1[i] = OP.xor(sdf1[i], sdf2[i], color1[i], color2[i])
            end
        elseif command.id == Commands.op_smooth_union
            for i in eachindex(sdf1)
                sdf1[i], color1[i] = OP.smooth_union(sdf1[i], sdf2[i], color1[i], color2[i], command.data[1])
            end
        elseif command.id == Commands.op_smooth_subtraction
            for i in eachindex(sdf1)
                sdf1[i], color1[i] = OP.smooth_difference(sdf1[i], sdf2[i], color1[i], color2[i], command.data[1])
            end
        elseif command.id == Commands.op_smooth_intersection
            for i in eachindex(sdf1)
                sdf1[i], color1[i] = OP.smooth_intersection(sdf1[i], sdf2[i], color1[i], color2[i], command.data[1])
            end
        elseif command.id == Commands.op_smooth_xor
            for i in eachindex(sdf1)
                sdf1[i], color1[i] = OP.smooth_xor(sdf1[i], sdf2[i], color1[i], color2[i], command.data[1])
            end
        else
            error("$(command.id) is not a recognized merge command")
        end
        return sdf1, color1
    end

    function evaluate_postfix_command!(command, pos::Array, sdf::Array)
        data = command.data
        if command.id == Commands.op_extrusion
            sdf .= OP.extrusion.(pos, sdf, Ref(Vec3f(data[1], data[2], data[3])))
        elseif command.id == Commands.op_rounding
            sdf .= OP.rounding.(pos, sdf, command.data[1])
        elseif command.id == Commands.op_onion
            sdf .= OP.onion.(pos, sdf, command.data[1])
        else
            error("$(command.id) is not a recognized postfix command.")
        end
        return sdf
    end

    @fastmath begin
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
                phi, R, r = data
                ymin = R * cos(min(phi, pi))
                dx = R * sin(min(phi, 0.5pi))
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
                return Makie.rotate_bbox(Quaternionf(command.data...), bb)
            elseif command.id == Commands.op_mirror
                # vec3 input is 1 (true) if the axis should be mirrored, 0 (false) otherwise
                sym_ws = @. max(abs(mini), abs(maxi))
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
                bb2 = Rect3f(mini .- r, ws .+ 2r)
                return bb2
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
    make_splattable(c::RGBAf) = reinterpret(Vec4f, c)

    struct Node
        # prefixes | shape or merge | postfixes
        commands::Vector{Command}
        main_idx::Int # index of shape or merge command
        children::Vector{Node}

        # partially filled later
        bbox::Base.RefValue{Rect3f} # Ref used for tracking
        changed::Base.RefValue{Bool}
    end


    Node(commands, main_idx, children) = Node(commands, main_idx, children, Ref{Rect3f}(), Ref(true))

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

        return Node(commands, main_idx, Node[])
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
                main_idx = length(commands) - 1
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

        commands, main_idx = process_commands(Command(op, args), kwargs)

        return Node(commands, main_idx, children)
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

    Base.show(io::IO, ::MIME"text/plain", node::Node) = show_rec(io, node)
    function show_rec(io, node, depth = 0)
        main = node.commands[node.main_idx]
        name = Commands.get_name(main.id)
        print(io, "  "^depth, "SDF ", name, " Node")
        for child in node.children
            println(io)
            show_rec(io, child, depth+1)
        end
        return
    end

    Base.:(==)(a::Command, b::Command) = (a.id == b.id) && (a.data == b.data)
    shallow_equal(a::Node, b::Node) = a.commands == b.commands
    shallow_hash(n::Node) = hash(n.commands)

    function mark_changed_nodes!(new::Node, old::Node, bbs = Rect3f[])
        if shallow_equal(new, old)
            # This node matches, check children
            new.changed[] = false
            old.changed[] = false

            # TODO: improve this to recognize middle deletions, reordering
            N = min(length(new.children), length(old.children))
            for i in 1:N
                mark_changed_nodes!(new.children[i], old.children[i], bbs)
            end

            if length(new.children) > N
                for i in N+1 : length(new.children)
                    set_all_children_as_changed!(new.children[i], bbs)
                end
            elseif length(old.children) > N
                for i in N+1 : length(old.children)
                    set_all_children_as_changed!(old.children[i], bbs)
                end
            end

        else
            # this node changed, mark whole branch as changed
            set_all_children_as_changed!(new)
            set_all_children_as_changed!(old)

            if new.bbox[] in old.bbox[]
                push!(bbs, old.bbox[])
            elseif old.bbox[] in new.bbox[]
                push!(bbs, new.bbox[])
            else
                push!(bbs, old.bbox[], new.bbox[])
            end
        end

        return bbs
    end

    function set_all_children_as_changed!(n::Node, bbs)
        n.changed[] = true
        push!(bbs, n.bbox[])
        foreach(child -> set_all_children_as_changed!(child, bbs), n.children)
        return
    end

    function set_all_children_as_changed!(n::Node)
        n.changed[] = true
        foreach(set_all_children_as_changed!, n.children)
        return
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
            # right: intersections (only matters where it intersects with left)
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

    function calculate_global_bboxes!(node::SDF.Node)
        bbs = Base.RefValue{Rect3f}[]
        apply_prefixes!(node, bbs)
        empty!(bbs)
        apply_postfixes_and_merges!(node, bbs)
        return bbs
    end

    function apply_prefixes!(node::SDF.Node, bbs::Vector{Base.RefValue{Rect3f}})
        if isempty(node.children) # leaf node
            bb = bbox_from_shape(node.commands[node.main_idx])
            for i in node.main_idx-1 : -1 : 1
                bb = apply_prefix(node.commands[i], bb)
            end
            node.bbox[] = bb
            push!(bbs, node.bbox)
        else
            start = length(bbs) + 1
            for child in node.children
                apply_prefixes!(child, bbs)
            end

            for bb_idx in start:length(bbs)
                for op_idx in node.main_idx - 1 : -1 : 1
                    bbs[bb_idx][] = apply_prefix(node.commands[op_idx], bbs[bb_idx][])
                end
            end
        end

        return bbs
    end

    function apply_postfixes_and_merges!(node::SDF.Node, bbs)
        if isempty(node.children) # leaf node
            bb = node.bbox[]
            for i in node.main_idx+1 : length(node.commands)
                bb = apply_postfix(node.commands[i], bb)
            end
            node.bbox[] = bb
            push!(bbs, node.bbox)
        else
            merge_cmd = node.commands[node.main_idx]

            left = Base.RefValue{Rect3f}[]
            apply_postfixes_and_merges!(node.children[1], left)
            right = Base.RefValue{Rect3f}[]
            for i in 2:length(node.children)
                apply_postfixes_and_merges!(node.children[i], right)
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

            node.bbox[] = foldl((a, b) -> Base.union(deref(a), deref(b)), left, init = Rect3f())
            push!(bbs, node.bbox)
        end

        return bbs
    end

    is_inside(pos::Point3, node::Node, range) = is_inside(pos, node.bbox[], range)
    function is_inside(pos::Point3, bb::Rect3f, range)
        ws = 0.5 .* widths(bb)
        dist = OP.rect(pos .- minimum(bb) .- ws, ws)
        return dist < range
    end

    function copy_node_without_children(node::Node)
        return Node(node.commands, node.main_idx, Node[])
    end

    function trimmed_tree(region::Rect3f, ref_tree::Node)
        new_tree = copy_node_without_children(ref_tree)
        trimmed_tree_rec!(new_tree, region, ref_tree)
        keep = cleanup_empty_nodes!(new_tree)
        if keep
            return new_tree
        else
            return Node(Command[], 0, Node[])
        end
    end

    function trimmed_tree_rec!(parent::Node, region::Rect3f, ref_tree::Node)
        for child in ref_tree.children
            if overlaps(child.bbox[], region)
                node = copy_node_without_children(child)
                push!(parent.children, node)
                trimmed_tree_rec!(node, region, child)
            end
        end
        return parent
    end

    function cleanup_empty_nodes!(node)
        # cleanup every child node, remove empty nodes
        filter!(cleanup_empty_nodes!, node.children)
        # mark the node for cleanup (false) if it has no children (anymore) and
        # it is not a shape node
        if isempty(node.children)
            main = node.commands[node.main_idx]
            return Commands.is_shape(main.id)
        end
        return true # otherwise keep it
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
            for i in 1 : node.main_idx - 1
                pos = evaluate_prefix_command(node.commands[i], pos)
            end
            sdf = compute_signed_distance_at(node.children[1], pos)
            merge_cmd = node.commands[node.main_idx]
            for i in 2:length(node.children)
                other = compute_signed_distance_at(node.children[i], pos)
                sdf = evaluate_merge_command(merge_cmd, sdf, other)
            end
            for i in node.main_idx + 1 : length(node.commands)
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
            for i in 1 : node.main_idx - 1
                pos = evaluate_prefix_command(node.commands[i], pos)
            end
            sdf, color = compute_color_at(node.children[1], pos)
            merge_cmd = node.commands[node.main_idx]
            for i in 2:length(node.children)
                _sdf, _color = compute_color_at(node.children[i], pos)
                sdf, color = evaluate_merge_command(
                    merge_cmd, sdf, _sdf, color, _color
                )
            end
            for i in node.main_idx + 1 : length(node.commands)
                pos, sdf = evaluate_command(node.commands[i], pos, sdf)
            end
            return sdf, color
        end
    end


    mutable struct Cache{T}
        size::NTuple{3, Int}
        buffers::Vector{Array{T, 3}}
        current::Int
    end
    Cache{T}(size) where {T} = Cache{T}(size, Array{T, 3}[], 0)
    reset!(c::Cache) = c.current = 0
    current(c::Cache) = c.buffers[c.current]
    function get_buffer(c::Cache{T}) where {T}
        c.current += 1
        if c.current > length(c.buffers)
            b = Array{T, 3}(undef, c.size)
            push!(c.buffers, b)
            return b
        else
            return c.buffers[c.current]
        end
    end
    release!(c::Cache) = c.current -= 1
    function get_first_buffer(c::Cache)
        c.current == 1 || error("The front buffer is currently still reserved!")
        return first(c.buffers)
    end

    function compute_color_at(node::SDF.Node, pos_cache::Cache{Point3f}, sdf_cache::Cache{Float32}, color_cache::Cache{RGBAf})
        # TODO: inbounds should be fine?
        pos = current(pos_cache)

        @inbounds if isempty(node.children)
            for i in 1:node.main_idx-1
                evaluate_prefix_command!(node.commands[i], pos)
            end

            sdf = get_buffer(sdf_cache)
            evaluate_shape_command!(node.commands[node.main_idx], pos, sdf)

            for i in node.main_idx+1:length(node.commands)
                evaluate_postfix_command!(node.commands[i], pos, sdf)
            end

            data = node.commands[node.main_idx].data
            color = RGBAf(data[1], data[2], data[3], data[4])
            fill!(get_buffer(color_cache), color)
            return
        else
            parent_pos = current(pos_cache)

            for i in 1 : node.main_idx - 1
                evaluate_prefix_command!(node.commands[i], pos)
            end

            child_pos = get_buffer(pos_cache)
            copyto!(child_pos, parent_pos)

            compute_color_at(node.children[1], pos_cache, sdf_cache, color_cache)
            left_sdf = current(sdf_cache)
            left_color = current(color_cache)

            merge_cmd = node.commands[node.main_idx]
            for i in 2:length(node.children)
                copyto!(child_pos, parent_pos)
                compute_color_at(node.children[i], pos_cache, sdf_cache, color_cache)

                right_sdf = current(sdf_cache)
                right_color = current(color_cache)

                evaluate_merge_command!(
                    merge_cmd, left_sdf, right_sdf, left_color, right_color
                )

                # allow the right sdf, color buffers to be reused in the next
                # iteration
                release!(sdf_cache)
                release!(color_cache)
            end
            # allow child_pos to be reused
            release!(pos_cache)

            # uses parent_pos, left_sdf
            for i in node.main_idx+1 : length(node.commands)
                evaluate_postfix_command!(node.commands[i], pos, sdf)
            end
            return
        end
    end

end

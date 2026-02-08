module SDF
    using LinearAlgebra
    using GeometryBasics
    using GeometryBasics: VecTypes
    using ...Makie: Quaternion, RGBAf, lerp
    using ...Makie

    ############################################################################
    ### SDF Tree
    ############################################################################

    struct Command
        id::Symbol
        data::Vector{Float32}

        function Command(id::Symbol, args...)
            make_splattable(x) = x
            make_splattable(q::Quaternion) = q.data
            make_splattable(c::RGBAf) = reinterpret(Vec4f, c)

            data = mapreduce((a, b) -> Vec(a..., b...), args, init = Vec{0, Float32}()) do arg
                return Float32.(make_splattable(arg))
            end

            expected = get_num_parameters(id)
            if expected != length(data)
                throw(ArgumentError("$id requires $expected arguments, but $(length(data)) were given."))
            end

            return new(id, collect(data))
        end
    end

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

    function Node(op::Symbol, args...; children = Node[], kwargs...)
        main = Command(op, args...)
        # This assumes kwargs are ordered
        commands, main_idx = process_commands(main, kwargs)
        return Node(commands, main_idx, children)
    end

    function process_commands(main, ops)
        was_postfix = false
        commands = Command[]
        main_idx = 0

        prev = :nothing
        for (id, data) in ops
            if is_prefix(id) && was_postfix
                error("Can not apply prefix transformation $id after postfix transformation $prev")
            elseif is_shape(id) || is_merge(id)
                error("$id is not a transformation.")
            end

            op = Command(id, data)
            if is_postfix(id) && !was_postfix
                push!(commands, main, op)
                main_idx = length(commands) - 1
                was_postfix = true
            else
                push!(commands, op)
            end

            prev = id
        end

        if !was_postfix
            push!(commands, main)
            main_idx = length(commands)
        end

        return commands, main_idx
    end

    function Shape(op::Symbol, args...; color = :orange, kwargs...)
        return Node(op, Makie.to_color(color), args...; kwargs...)
    end

    function Merge(op::Symbol, children, args...; kwargs...)
        return Node(op, args...; children = collect(children), kwargs...)
    end

    ############################################################################
    ### General utils
    ############################################################################

    const prefix_ops = [
        :revolution, :elongate, :rotation, :mirror, :infinite_repetition,
        :limited_repetition, :twist, :bend, :translation,
    ]
    is_prefix(id::Symbol) = id in prefix_ops

    const shapes = [
        #:vesica, :plane, :rhombus, :hexagonal_prism, :triangular_prism,
        :sphere, :octahedron, :pyramid, :torus, :capsule, :cylinder, :ellipsoid,
        :rect, :link, :cone, :capped_cone, :box_frame, :capped_torus,
        # :solid_angle,
    ]
    is_shape(id::Symbol) = id in shapes

    const merges = [
        :union, :subtraction, :intersection, :xor,
        :smooth_union, :smooth_subtraction, :smooth_intersection, :smooth_xor,
    ]
    is_merge(id::Symbol) = id in merges

    const postfix_ops = [:extrusion, :rounding, :onion]
    is_postfix(id::Symbol) = id in postfix_ops

    const id2num_param = Dict{Symbol, Int}(
        :revolution => 1, :elongate => 3, :rotation => 4,
        :mirror => 3, :infinite_repetition => 3, :limited_repetition => 6,
        :twist => 1, :bend => 1, :translation => 3,

        # 2D shapes
        # shape2D_vesica
        # shape2D_plane
        # shape2D_rhombus
        # shape2D_hexagonal_prism
        # shape2D_triangular_prism

        # 3D Shapes
        :sphere => 5, :octahedron => 5, :pyramid => 6, :torus => 6, :capsule => 6,
        :cylinder => 6, :ellipsoid => 7, :rect => 7, :link => 7, :cone => 6,
        :capped_cone => 7,
        # shape3D_solid_angle => 0,
        :box_frame => 8, :capped_torus => 7,

        # merge operations
        :union => 0, :subtraction => 0, :intersection => 0, :xor => 0,
        :smooth_union => 1, :smooth_subtraction => 1,
        :smooth_intersection => 1, :smooth_xor => 1,

        # postfix operations
        :extrusion => 3, :rounding => 1, :onion => 1,
    )
    get_num_parameters(id::Symbol) = id2num_param[id]

    deref(x) = x
    deref(x::Base.RefValue) = x[]

    Base.show(io::IO, ::MIME"text/plain", node::Node) = show_rec(io, node)
    function show_rec(io, node, depth = 0)
        main = node.commands[node.main_idx]
        print(io, "  "^depth, main.id)
        for child in node.children
            println(io)
            show_rec(io, child, depth+1)
        end
        return
    end

    ############################################################################
    ### Calculations
    ############################################################################

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

            ####################################################################
            # SDF functions
            ####################################################################

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


            ####################################################################
            # prefix functions
            ####################################################################

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

            ####################################################################
            # merge functions
            ####################################################################

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

            ####################################################################
            # postfix functions
            ####################################################################

            function extrusion(pos, sdf, by::Vec3f)
                vec = Vec2f(sdf, norm(abs.(pos) .- by));
                return min(max(vec[1], vec[2]), 0f0) + norm(max(vec, 0f0))
            end

            rounding(pos, sdf, range::Float32) = sdf - range
            onion(pos, sdf, thickness::Float32) = abs(sdf) - thickness
        end # fastmath
    end

    ############################################################################
    ### SDF and Command evaluation (signed distance)
    ############################################################################

    function evaluate_prefix_command(command, pos)
        # Indexing directly is very beneficial here (indirect @inbounds)
        data = command.data
        if command.id == :revolution
            return OP.revolution(pos, data[1])
        elseif command.id == :elongate
            return OP.elongate(pos, Vec3f(data[1], data[2], data[3]))
        elseif command.id == :rotation
            return OP.rotation(pos, Quaternionf(data[1], data[2], data[3], data[4]))
        elseif command.id == :mirror
            return OP.mirror(pos, Vec3f(data[1], data[2], data[3]))
        elseif command.id == :infinite_repetition
            return OP.infinite_repetition(pos, Vec3f(data[1], data[2], data[3]))
        elseif command.id == :limited_repetition
            periods = Vec3f(data[1], data[2], data[3])
            limits = Vec3f(data[4], data[5], data[6])
            return OP.limited_repetition(pos, periods, limits)
        elseif command.id == :twist
            return OP.twist(pos, data[1])
        elseif command.id == :bend
            return OP.bend(pos, data[1])
        elseif command.id == :translation
            return OP.translation(pos, Vec3f(data[1], data[2], data[3]))
        else
            error("Unrecognized prefix command $(command.id)")
        end
        return pos
    end

    function evaluate_shape_command(command, pos)
        data = command.data
        if command.id == :sphere
            return OP.sphere(pos, data[5])
        elseif command.id == :octahedron
            return OP.octahedron(pos, data[5])
        elseif command.id == :pyramid
            return OP.pyramid(pos, data[5], data[6])
        elseif command.id == :torus
            return OP.torus(pos, data[5], data[6])
        elseif command.id == :capsule
            return OP.capsule(pos, data[5], data[6])
        elseif command.id == :cylinder
            return OP.cylinder(pos, data[5], data[6])
        elseif command.id == :ellipsoid
            return OP.ellipsoid(pos, Vec3f(data[5], data[6], data[7]))
        elseif command.id == :rect
            return OP.rect(pos, Vec3f(data[5], data[6], data[7]))
        elseif command.id == :link
            return OP.link(pos, data[5], data[6], data[7])
        elseif command.id == :cone
            return OP.cone(pos, data[5], data[6])
        elseif command.id == :capped_cone
            return OP.capped_cone(pos, data[5], data[6], data[7])
        elseif command.id == :box_frame
            return OP.box_frame(pos, Vec3f(data[5], data[6], data[7]), data[8])
        elseif command.id == :capped_torus
            return OP.capped_torus(pos, data[5], data[6], data[7])
        else
            error("Unrecognized shape command $(command.id)")
            return 10_000f0
        end
    end

        function evaluate_merge_command(command, sdf1, sdf2)
        if command.id == :union
            return OP.union(sdf1, sdf2)
        elseif command.id == :subtraction
            return OP.difference(sdf1, sdf2)
        elseif command.id == :intersection
            return OP.intersection(sdf1, sdf2)
        elseif command.id == :xor
            return OP.xor(sdf1, sdf2)
        elseif command.id == :smooth_union
            return OP.smooth_union(sdf1, sdf2, command.data[1])
        elseif command.id == :smooth_subtraction
            return OP.smooth_difference(sdf1, sdf2, command.data[1])
        elseif command.id == :smooth_intersection
            return OP.smooth_intersection(sdf1, sdf2, command.data[1])
        elseif command.id == :smooth_xor
            return OP.smooth_xor(sdf1, sdf2, command.data[1])
        else
            error("$(command.id) is not a recognized merge command")
        end
    end

    function evaluate_postfix_command(command, pos, sdf)
        data = command.data
        if command.id == :extrusion
            return OP.extrusion(pos, sdf, Vec3f(data[1], data[2], data[3]))
        elseif command.id == :rounding
            return OP.rounding(pos, sdf, command.data[1])
        elseif command.id == :onion
            return OP.onion(pos, sdf, command.data[1])
        else
            error("$(command.id) is not a recognized postfix command.")
            return sdf
        end
    end

    function compute_signed_distance_at(node::SDF.Node, pos)
        for i in 1:node.main_idx-1
            pos = evaluate_prefix_command(node.commands[i], pos)::Point3f
        end

        if isempty(node.children)
            sdf = evaluate_shape_command(node.commands[node.main_idx], pos)::Float32
        else
            sdf = compute_signed_distance_at(node.children[1], pos)
            merge_cmd = node.commands[node.main_idx]
            for i in 2:length(node.children)
                other = compute_signed_distance_at(node.children[i], pos)
                sdf = evaluate_merge_command(merge_cmd, sdf, other)
            end
        end

        for i in node.main_idx+1:length(node.commands)
            sdf = evaluate_postfix_command(node.commands[i], pos, sdf)::Float32
        end

        return sdf
    end

    ############################################################################
    ### SDF and Command evaluation (signed distance + color)
    ############################################################################

    function evaluate_prefix_command!(command, pos::Array)
        # Indexing directly is very beneficial here (indirect @inbounds)
        data = command.data
        if command.id == :revolution
            pos .= OP.revolution.(pos, data[1])
        elseif command.id == :elongate
            pos .= OP.elongate.(pos, Ref(Vec3f(data[1], data[2], data[3])))
        elseif command.id == :rotation
            pos .= OP.rotation.(pos, Ref(Quaternionf(data[1], data[2], data[3], data[4])))
        elseif command.id == :mirror
            pos .= OP.mirror.(pos, Ref(Vec3f(data[1], data[2], data[3])))
        elseif command.id == :infinite_repetition
            pos .= OP.infinite_repetition.(pos, Ref(Vec3f(data[1], data[2], data[3])))
        elseif command.id == :limited_repetition
            periods = Vec3f(data[1], data[2], data[3])
            limits = Vec3f(data[4], data[5], data[6])
            pos .= OP.limited_repetition.(pos, Ref(periods), Ref(limits))
        elseif command.id == :twist
            pos .= OP.twist.(pos, data[1])
        elseif command.id == :bend
            pos .= OP.bend.(pos, data[1])
        elseif command.id == :translation
            pos .= OP.translation.(pos, Ref(Vec3f(data[1], data[2], data[3])))
        else
            error("Unrecognized prefix command $(command.id)")
        end
        return pos
    end

    function evaluate_shape_command!(command, pos::Array, sdf::Array)
        data = command.data

        if command.id == :sphere
            sdf .= OP.sphere.(pos, data[5])
        elseif command.id == :octahedron
            sdf .= OP.octahedron.(pos, data[5])
        elseif command.id == :pyramid
            sdf .= OP.pyramid.(pos, data[5], data[6])
        elseif command.id == :torus
            sdf .= OP.torus.(pos, data[5], data[6])
        elseif command.id == :capsule
            sdf .= OP.capsule.(pos, data[5], data[6])
        elseif command.id == :cylinder
            sdf .= OP.cylinder.(pos, data[5], data[6])
        elseif command.id == :ellipsoid
            sdf .= OP.ellipsoid.(pos, Ref(Vec3f(data[5], data[6], data[7])))
        elseif command.id == :rect
            sdf .= OP.rect.(pos, Ref(Vec3f(data[5], data[6], data[7])))
        elseif command.id == :link
            sdf .= OP.link.(pos, data[5], data[6], data[7])
        elseif command.id == :cone
            sdf .= OP.cone.(pos, data[5], data[6])
        elseif command.id == :capped_cone
            sdf .= OP.capped_cone.(pos, data[5], data[6], data[7])
        elseif command.id == :box_frame
            sdf .= OP.box_frame.(pos, Ref(Vec3f(data[5], data[6], data[7])), data[8])
        elseif command.id == :capped_torus
            sdf .= OP.capped_torus.(pos, data[5], data[6], data[7])
        else
            error("Unrecognized shape command $(command.id)")
            sdf .= 10_000f0
        end
        return sdf
    end

     function evaluate_merge_command!(command, sdf1::Array, sdf2::Array, color1::Array, color2::Array)
        if command.id == :union
            for i in eachindex(sdf1)
                sdf1[i], color1[i] = OP.union(sdf1[i], sdf2[i], color1[i], color2[i])
            end
        elseif command.id == :subtraction
            for i in eachindex(sdf1)
                sdf1[i], color1[i] = OP.difference(sdf1[i], sdf2[i], color1[i], color2[i])
            end
        elseif command.id == :intersection
            for i in eachindex(sdf1)
                sdf1[i], color1[i] = OP.intersection(sdf1[i], sdf2[i], color1[i], color2[i])
            end
        elseif command.id == :xor
            for i in eachindex(sdf1)
                sdf1[i], color1[i] = OP.xor(sdf1[i], sdf2[i], color1[i], color2[i])
            end
        elseif command.id == :smooth_union
            for i in eachindex(sdf1)
                sdf1[i], color1[i] = OP.smooth_union(sdf1[i], sdf2[i], color1[i], color2[i], command.data[1])
            end
        elseif command.id == :smooth_subtraction
            for i in eachindex(sdf1)
                sdf1[i], color1[i] = OP.smooth_difference(sdf1[i], sdf2[i], color1[i], color2[i], command.data[1])
            end
        elseif command.id == :smooth_intersection
            for i in eachindex(sdf1)
                sdf1[i], color1[i] = OP.smooth_intersection(sdf1[i], sdf2[i], color1[i], color2[i], command.data[1])
            end
        elseif command.id == :smooth_xor
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
        if command.id == :extrusion
            sdf .= OP.extrusion.(pos, sdf, Ref(Vec3f(data[1], data[2], data[3])))
        elseif command.id == :rounding
            sdf .= OP.rounding.(pos, sdf, command.data[1])
        elseif command.id == :onion
            sdf .= OP.onion.(pos, sdf, command.data[1])
        else
            error("$(command.id) is not a recognized postfix command.")
        end
        return sdf
    end

    # This is meant to be reused for multiple blocks/bricks of SDF evaluations.
    # The first run adds as many buffers as are needed to evaluate the SDF tree.
    # Every other runs then reuses these buffers. This avoids having to allocate
    # buffers again and again for each block.
    # (If blocks use different trees later runs may add more buffers.)
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

    function compute_color_at(
            node::SDF.Node,
            pos_cache::Cache{Point3f}, sdf_cache::Cache{Float32}, color_cache::Cache{RGBAf}
        )

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

    ############################################################################
    ### SDF and Command evaluation (bounding boxes)
    ############################################################################

    # These are reordered. Instead of
    #   prefix -> shape/merge -> postfix
    # this does
    #   shape -> prefix -> postfix
    @fastmath begin
        function bbox_from_shape(command)
            # strip color
            data = ntuple(i -> command.data[i + 4], length(command.data) - 4)

            # every bbox here is scaled from -1..1
            if command.id in (:sphere, :octahedron)
                return Rect3f(-Point3f(data[1]), Vec3f(2data[1]))
            elseif command.id in (:pyramid, :cylinder, :cone)
                r, h = data
                return Rect3f(-r, -r, -h, 2r, 2r, 2h)
            elseif command.id == :torus
                R, r = data
                return Rect3f(-R-r, -R-r, -r, 2*(R+r), 2*(R+r), 2r)
            elseif command.id == :capsule
                r, h = data
                return Rect3f(-r, -r, -(h+r), 2r, 2r, 2*(h+r))
            elseif command.id in (:ellipsoid, :rect)
                ws = Vec3f(data...)
                return Rect3f(-ws, 2.0 .* ws)
            elseif command.id == :link
                l, R, r = data
                return Rect3f(-(R+r), -(l+R+r), -r, 2*(R+r), 2*(l+R+r), 2r)
            elseif command.id == :capped_cone
                h, r1, r2 = data
                R = max(r1, r2)
                return Rect3f(-R, -R, -h, 2R, 2R, 2h)
            elseif command.id == :box_frame
                ws = data[Vec(1, 2, 3)]
                # w = data[4]
                # return Rect3f(.-(ws .+ 0.5 * w), 2 .* ws .+ w)
                return Rect3f(.-ws, 2 .* ws)
            elseif command.id == :capped_torus
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
            if command.id == :revolution
                # TODO: arbitrary rotation around vec3? Or just force use of op_rotation...
                # float moves the 2d object away from th center of rotation
                # TODO: What should 2D shapes do with the third coordinate? What's neutral? Inf?
                # TODO: test
                r = xy_norm(max(abs(mini), abs(maxi)))
                return Rect3f(-r, -r, mini[3], 2r, 2r, widths(bb)[3])
            elseif command.id == :elongate
                return Rect3f(mini .- command.data, ws .+ 2 .* commanda.data)
            elseif command.id == :rotation
                return Makie.rotate_bbox(Quaternionf(command.data...), bb)
            elseif command.id == :mirror
                # vec3 input is 1 (true) if the axis should be mirrored, 0 (false) otherwise
                sym_ws = @. max(abs(mini), abs(maxi))
                mini = lerp.(mini, -sym_ws, command.data)
                maxi = lerp.(maxi, sym_ws, command.data)
                return Rect3f(mini, maxi .- mini)
            elseif command.id == :infinite_repetition
                return Rect3f(Point3f(-Inf), Vec3f(Inf))
            elseif command.id == :limited_repetition
                rep_dist = Vec3f(command.data[1:3])
                limit = Vec3f(command.data[4:6])
                mini = (limit .- 1) * rep_dist + max.(mini, -0.5 * rep_dist)
                maxi = (limit .- 1) * rep_dist + min.(maxi, 0.5 * rep_dist)
                return Rect3f(mini, maxi .- mini)
            elseif command.id == :twist
                r = xy_norm(max.(abs(mini), abs(maxi)))
                return Rect3f(-r, -r, mini[3], 2r, 2r, ws[3])
            elseif command.id == :bend
                # TODO: more precise
                r = norm(max.(abs(mini[Vec(1, 3)]), abs(maxi[Vec(1, 3)])))
                return Rect3f(-r, mini[2], -r, 2r, ws[2], 2r)
            elseif command.id == :translation
                return bb + Point3f(command.data)
            end
            return bb
        end

        function apply_postfix(command, bb::Rect3f)
            mini = GeometryBasics.minimum(bb)
            ws = widths(bb)
            if command.id == :extrusion
                e = command.data
                return Rect3f(mini .- Vec3f(0,0, e), ws .+ Vec3f(0, 0, 2e))
            elseif command.id in (:rounding, :onion)
                r = command.data[1]
                bb2 = Rect3f(mini .- r, ws .+ 2r)
                return bb2
            else
                return bb
            end
        end

        function apply_merge!(cmd::Command, left::Vector{Base.RefValue{Rect3f}}, right::Vector{Base.RefValue{Rect3f}})
            if cmd.id == :subtraction
                # left: keep (may or may not be removed depending on right)
                # right: intersections (only matters where it intersects with left)
                for b in right
                    affected = Rect3f()
                    for a in left
                        affected = Base.union(affected, Base.intersect(a[], b[]))
                    end
                    b[] = affected
                end
            elseif cmd.id == :smooth_subtraction
                # Tighter solution?
                for b in right
                    affected = Rect3f()
                    for a in left
                        affected = Base.union(affected, Base.union(a[], b[]))
                    end
                    b[] = affected
                end
            elseif cmd.id in (:intersection, :smooth_intersection)
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
            # elseif cmd.id == :union
                # result is the combination of all bboxes
            # elseif cmd.id == :xor
                # result could be anywhere in the union of left and right bboxes
            elseif cmd.id == :smooth_xor
                append!(left, right)
                bb = foldl((a, b) -> Base.union(deref(a), deref(b)), left)
                foreach(x -> x[] = bb, left)
                return left
            elseif cmd.id == :smooth_union
                # only case where smoothing is not reductive
                # TODO: Can we do better and apply a lower ceiling for the amount added here?
                r = cmd.data[1] # smoothing range
                append!(left, right)
                bb = foldl((a, b) -> Base.union(deref(a), deref(b)), left)
                bb = Rect3f(GeometryBasics.minimum(bb) .- r, widths(bb) .+ 2r)
                foreach(x -> x[] = bb, left)
                return left
            end
            append!(left, right)
            return left
        end

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

    function calculate_global_bboxes!(node::SDF.Node)
        bbs = Base.RefValue{Rect3f}[]
        apply_prefixes!(node, bbs)
        empty!(bbs)
        apply_postfixes_and_merges!(node, bbs)
        return bbs
    end

    ############################################################################
    ### Utility (tree trimming)
    ############################################################################

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
            return is_shape(main.id)
        end
        return true # otherwise keep it
    end

    ############################################################################
    ### Utility (bbox checks)
    ############################################################################

    is_inside(pos::Point3, node::Node, range) = is_inside(pos, node.bbox[], range)
    function is_inside(pos::Point3, bb::Rect3f, range)
        ws = 0.5 .* widths(bb)
        dist = OP.rect(pos .- minimum(bb) .- ws, ws)
        return dist < range
    end

    ############################################################################
    ### Tree diffing
    ############################################################################

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
end

# TODO: try to only have user facing functions here?
# Maybe also Node?
"""
TODO: list all

## 2D Shapes

## 3D Shapes

## Transformations

## Merges

"""
module CSG
    using Makie: VecTypes
    import ..SDF

    # TODO:
    """
        CSG.Sphere(position::VecTypes{3}, radius::Real; kwargs...)

    Creates a sphere with a given `radius` and `position` for constructive
    solid geometry. Keyword arguments may include `color` and any CSG
    transformation.
    """
    Sphere(radius::Real; kwargs...) = SDF.Shape(:sphere, radius; kwargs...)

    Octahedron(radius::Real; kwargs...) = SDF.Shape(:octahedron, radius; kwargs...)
    function Pyramid(height::Real, widths::Real; kwargs...)
        return SDF.Shape(:pyramid, widths, height; kwargs...)
    end
    function Torus(r_outer::Real, r_inner::Real; kwargs...)
        return SDF.Shape(:torus, r_outer, r_inner; kwargs...)
    end
    function Capsule(height::Real, radius::Real; kwargs...)
        return SDF.Shape(:capsule, radius, height; kwargs...)
    end
    function Cylinder(height::Real, radius::Real; kwargs...)
        return SDF.Shape(:cylinder, radius, height; kwargs...)
    end
    Ellipsoid(radii::VecTypes{3}; kwargs...) = SDF.Shape(:ellipsoid, radii; kwargs...)
    Rect(widths::VecTypes{3}; kwargs...) = SDF.Shape(:rect, widths; kwargs...)
    function Link(len::Real, r_outer::Real, r_inner::Real; kwargs...)
        return SDF.Shape(:link, len, r_outer, r_inner; kwargs...)
    end
    Cone(height::Real, radius::Real; kwargs...) = SDF.Shape(:cone, radius, height; kwargs...)
    function Capped_cone(height::Real, bottom_radius::Real, top_radius::Real; kwargs...)
        return SDF.Shape(:capped_cone, height, bottom_radius, top_radius; kwargs...)
    end
    # function solid_angle(; kwargs...)
    #     return SDF.Shape(:solid_angle, ; kwargs...)
    # end
    function Box_frame(box_widths::VecTypes{3}, line_width::Real; kwargs...)
        return SDF.Shape(:box_frame, box_widths, line_width; kwargs...)
    end
    function Capped_torus(opening_angle::Real, r_outer::Real, r_inner::Real; kwargs...)
        return SDF.Shape(:capped_torus, opening_angle, r_outer, r_inner; kwargs...)
    end

    union(children::SDF.Node...; kwargs...) = SDF.Merge(:union, children; kwargs...)
    diff(children::SDF.Node...; kwargs...) = SDF.Merge(:subtraction, children; kwargs...)
    subtract(children::SDF.Node...; kwargs...) = diff(children...; kwargs...)
    intersect(children::SDF.Node...; kwargs...) = SDF.Merge(:intersection, children; kwargs...)
    xor(children::SDF.Node...; kwargs...) = SDF.Merge(:xor, children; kwargs...)

    function smooth_union(children::SDF.Node...; smooth, kwargs...)
        return SDF.Merge(:smooth_union, children, smooth; kwargs...)
    end
    smooth_subtract(children::SDF.Node...; kwargs...) = smooth_diff(children...; kwargs...)
    function smooth_diff(children::SDF.Node...; smooth, kwargs...)
        return SDF.Merge(:smooth_subtraction, children, smooth; kwargs...)
    end
    function smooth_intersect(children::SDF.Node...; smooth, kwargs...)
        return SDF.Merge(:smooth_intersection, children, smooth; kwargs...)
    end
    function smooth_xor(children::SDF.Node...; smooth, kwargs...)
        return SDF.Merge(:smooth_xor, children, smooth; kwargs...)
    end
end

function update_brickmap!(
        brickmap::SDFBrickmap, bb::Rect3f, root::SDF.Node,
        regions_to_update::Vector{Rect3f}
    )
    # TODO: Is this an error?
    isempty(regions_to_update) && return

    N_blocks = size(brickmap.indices, 1)

    # coarse grid (indices) with
    # minimum = mini + 0 * delta
    # maximum = mini + N_blocks * delta
    # each bricks 1 delta large, center at (i, j, k) .+ 0.5
    delta = widths(bb) ./ N_blocks
    mini = minimum(bb)

    # TODO: maybe try to make list of
    #   merged_aligned_bb/index ranges => bbs_that_got_merged
    # and then loop based on first, check second
    # Find region that needs updating
    raw_update_bb = reduce(union, regions_to_update, init = Rect3f())
    low = trunc.(Int, clamp.(fld.(minimum(raw_update_bb) .- mini, delta), 0, N_blocks-1)) .+ 1
    high = trunc.(Int, clamp.(cld.(maximum(raw_update_bb) .- mini, delta), 1, N_blocks))
    @info "Diffed bbs: $regions_to_update"
    @info "Merged: $raw_update_bb"
    @info "Ranges: $low .. $high"

    # for node bbox and SDF based skipping
    box_scale = norm(widths(bb))
    brickdiameter = sqrt(3.0) * box_scale / (N_blocks - 1) # relative to bb
    brickradius = 0.5 * brickdiameter

    # step through brick grid (delta is the width of the brick, bricksize is edge-like)
    bricksize = brickmap.bricksize
    brick_delta = delta / (bricksize - 1)

    # -cellsize .. cellsize -> -127.5 .. 127.5
    # where cellsize is the (1, 1, 1) distance to the next entry
    uint8_scale = 127.5f0 * bricksize / brickdiameter

    # Note: one buffer per thread for multithreading, or create them per thread?
    pos_cache = SDF.Cache{Point3f}((bricksize, bricksize, bricksize))
    sdf_cache = SDF.Cache{Float32}((bricksize, bricksize, bricksize))
    color_cache = SDF.Cache{RGBAf}((bricksize, bricksize, bricksize))

    # print_bb_rec(root)

    content_count = 0
    content_count2 = 0
    content_count3 = 0

    for k in low[3]:high[3]
        z = mini[3] + delta[3] * (k - 0.5)
        for j in low[2]:high[2]
            y = mini[2] + delta[2] * (j - 0.5)
            for i in low[1]:high[1]
                x = mini[1] + delta[1] * (i - 0.5)

                pos = Point3f(x, y, z)
                local_bb = Rect3f(pos .- 0.5 .* delta, delta)
                in_changed_region = any(bb -> overlaps(local_bb, bb), regions_to_update)

                if in_changed_region
                    brick_may_contain_surface = SDF.is_inside(pos, root, brickradius)

                    if brick_may_contain_surface
                        content_count += 1

                        # check if brick could contain edge based on center
                        dist = SDF.compute_signed_distance_at(root, pos)
                        if abs(dist) < brickradius
                            content_count2 += 1
                            # Note: we already checked that this brick needs to be updated
                            content_count3 += update_brick!(
                                brickmap, root, i, j, k,
                                mini, delta, brick_delta,
                                uint8_scale,
                                pos_cache, sdf_cache, color_cache
                            )
                        else
                            free_brick!(brickmap, i, j, k)
                        end
                    else
                        free_brick!(brickmap, i, j, k)
                    end
                end

            end
        end
    end

    # TODO: merge overlapping bboxes, update indices per merge bbox
    ShaderAbstractions.update!(brickmap.indices)

    finish_update!(brickmap)

    return
end

function update_brick!(
        brickmap::SDFBrickmap, root::SDF.Node,
        i, j, k,
        mini, delta, brick_delta,
        uint8_scale,
        pos_cache::SDF.Cache{<:Point},
        sdf_cache::SDF.Cache{<:Real},
        color_cache::SDF.Cache{<:Colorant}
    )

    # cleanup leftover state
    SDF.reset!(pos_cache)
    SDF.reset!(sdf_cache)
    SDF.reset!(color_cache)

    # setup positions
    bricksize = brickmap.bricksize
    origin = Point3f(mini + delta .* ((i, j, k) .- 1))
    positions = SDF.get_buffer(pos_cache)
    @inbounds for ijk in CartesianIndices((bricksize, bricksize, bricksize))
        _ijk = Tuple(ijk)
        positions[ijk] = origin .+ brick_delta .* (_ijk .- 1)
    end

    # TODO: Can we remove unchanged bricks too? Or are they still needed for correct results?
    # compute sdfs + colors
    reduced_tree = SDF.trimmed_tree(Rect3f(origin, delta), root)
    if reduced_tree.main_idx == 0
        free_brick!(brickmap, i, j, k)
        return false # empty tree
    end
    SDF.compute_color_at(reduced_tree, pos_cache, sdf_cache, color_cache)

    # analyze results (should it create a brick?)
    sdfs = SDF.get_first_buffer(sdf_cache)
    colors = SDF.get_first_buffer(color_cache)

    contains_positive = false
    contains_negative = false
    contains_resolvable_distance = false
    contains_multiple_colors = false
    first_color_set = false
    first_color = colors[1]

    @inbounds for i in eachindex(sdfs)
        sdf = sdfs[i]
        f_normed = uint8_scale * sdf
        contains_negative |= sdf <= 0
        contains_positive |= sdf >= 0
        is_resolvable = abs(f_normed) < 127.5f0
        contains_resolvable_distance |= is_resolvable
        if !contains_multiple_colors && is_resolvable
            if !first_color_set
                first_color = colors[i]
                first_color_set = true
            elseif colors[i] != first_color
                contains_multiple_colors = true
            end
        elseif contains_multiple_colors && contains_negative && contains_positive
            break
        end
    end

    # Add data
    # or check contains_positive, contains_negative
    if contains_resolvable_distance
        # Note: needs lock for multithreading
        brick_idx, sdf_brick = get_or_create_brick(brickmap, i, j, k)
        @assert brick_idx > 0
        @inbounds for i in eachindex(sdf_brick)
            f_normed = clamp(uint8_scale * sdfs[i] + 128, 0, 255.9)
            sdf_brick[i] = N0f8(trunc(UInt8, f_normed), nothing)
        end
        finish_brick_update!(brickmap, brick_idx)

        if contains_multiple_colors
            set_interpolated_color!(brickmap, brick_idx, colors)
        else
            set_static_color!(brickmap, brick_idx, first_color)
        end

        return true

    else

        free_brick!(brickmap, i, j, k)
        return false
    end
end

"""
Plots constructive solid geometry, i.e. 3D geometry created from simpler
geometry using transformations and boolean operations. See `Makie.CSG`.
"""
@recipe CSGPlot (x::EndPoints, y::EndPoints, z::EndPoints, csg_tree::SDF.Node) begin
    "Sample density of signed distances used in rendering the geometry."
    resolution = 512
    "Minimum step length used in ray marching."
    minstep = 1e-5
    "TODO: Maximum number of steps allowed in ray marching."
    maxsteps = 1000
    "Size of bricks in the generated Brickmap (per dimension)."
    bricksize = 8
end

conversion_trait(::Type{<:CSGPlot}) = VolumeLike()

function expand_dimensions(::VolumeLike, root::SDF.Node)
    @info "called"
    SDF.calculate_global_bboxes!(root)
    bb = root.bbox[]
    # need padding so the surface isn't on the boundary
    # 0 width bbox would probably be a problem?
    ws = max.(1e-3, widths(bb))
    mini = minimum(bb)
    x, y, z = EndPoints.(mini .- 0.01ws, mini .+ 1.01ws)
    return (x, y, z, root)
end

function convert_arguments(::Type{<:CSGPlot}, x::RangeLike, y::RangeLike, z::RangeLike, root::SDF.Node)
    return (
        to_endpoints(x, "x", VolumeLike), to_endpoints(y, "y", VolumeLike),
        to_endpoints(z, "z", VolumeLike), root,
    )
end

preferred_axis_type(::CSGPlot) = LScene

function pad_tree_bbs!(node::SDF.Node, by::Vec3f)
    node.bbox[] = Rect(minimum(node.bb[]) .- by, widths(node.bb[]) .+ 2by)
    foreach(child -> pad_tree_bbs!(child, by), node.children)
    return
end

function print_bb_rec(node, depth = 0)
    main = node.commands[node.main_idx]
    name = main.id
    # println("  "^depth, name, " ", node.bbox[])
    str = "  "^depth * "$name $(node.bbox[])\n"
    printstyled(str, color = node.changed[] ? :bold : :light_black)
    foreach(child -> print_bb_rec(child, depth + 2), node.children)
end

function plot!(p::CSGPlot)

    N = p.resolution[]
    @info "$N^3 dense array: $(N^3 * 5 / 1024^2)MB"
    bricksize = p.bricksize[]
    N_blocks = cld(N-1, bricksize-1)
    N = N_blocks * (bricksize-1) + 1
    # brickmap = Brickmap{N0f8}((bricksize, bricksize, bricksize), N, color = SparseBrickmapColors())
    brickmap = SDFBrickmap(bricksize, N)


    map!(p, [:x, :y, :z], :data_limits) do x, y, z
        return Rect3f(x[1], y[1], z[1], x[2] - x[1], y[2] - y[1], z[2] - z[1])
    end

    # TODO: all node bounding boxes need to be padded asap but changes in
    # data_limits should not trigger a recalculation of bricks
    # TODO: do we actually need this?
    # onany(p.csg_tree, p.data_limits) do root, bb
    #     delta = widths(bb) ./ N_blocks
    #     pad_tree_bbs!(root, delta)
    # end

    # TODO: diffing
    register_computation!(p, [:csg_tree], [:diffed_tree, :diffed_bboxes]) do (new_tree,), changed, cached
        SDF.calculate_global_bboxes!(new_tree)
        if isnothing(cached)
            return (new_tree, Rect3f[new_tree.bbox[]])
        else
            old_tree = cached.diffed_tree
            @assert new_tree !== old_tree
            SDF.mark_changed_nodes!(new_tree, old_tree, empty!(cached.diffed_bboxes))
            @info "Old:"
            print_bb_rec(old_tree)
            @info "New:"
            print_bb_rec(new_tree)
            # TODO: optimize rects - merge overlapping, remove duplicated
            # or maybe lower to brick rects?
            return (new_tree, cached.diffed_bboxes)
        end
    end

    map!(p, [:data_limits, :diffed_tree, :diffed_bboxes], :brickmap) do bb, root, bbs
        @time update_brickmap!(brickmap, bb, root, bbs)
        return brickmap
    end

    # force this to run before connecting the backend so we don't spam updates
    # during construction
    p.brickmap[]

    volume!(p, p.x, p.y, p.z, p.brickmap, algorithm = :sdf, isorange = p.minstep)
end

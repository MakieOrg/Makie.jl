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
        xy_norm(p) = norm(p[Vec(1, 2)])

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
        function pyramid(ray_pos, radius::Real, height::Real)
            # use xy symmetry
            pos = Vec3f(abs(ray_pos[1]), abs(ray_pos[2]), height - ray_pos[3]);

            # project ray_pos onto the side surfaces where side_dir is the vector going
            # from the tip of the pyramid down one of the sides
            side_dir = Vec2f(radius, 2f0 * height);
            side_length2 = dot(side_dir, side_dir);

            # and also the edge between side surfaces
            edge_dir = Vec3f(radius, radius, 2f0 * height);
            edge_length2 = dot(edge_dir, edge_dir);

            # use projection ray_pos = a * side_dir + b * some_vec
            x_proj = side_dir * clamp(dot(pos[Vec(1, 3)], side_dir), 0f0, side_length2) / side_length2;
            y_proj = side_dir * clamp(dot(pos[Vec(2, 3)], side_dir), 0f0, side_length2) / side_length2;
            xy_proj = edge_dir * clamp(dot(pos, edge_dir), 0f0, edge_length2) / edge_length2;

            # We can further disassemble some_vec = c * side_normal + d * perp_vec
            # where perp_vec = u_y for the x surface. If d < width of the surface
            # at x_proj, c is the closest distance. Check if this is the case:
            # If it's not the case for the x or y surface, the edge must be closer(1)
            in_x_range = Float32(pos[2] * height < 0.5 * radius * x_proj[2]);
            in_y_range = Float32(pos[1] * height < 0.5 * radius * y_proj[2]);

            mantle_dist = norm(
                in_x_range * Vec3f(pos[1] - x_proj[1], pos[3] - x_proj[2], 0) +
                in_y_range * Vec3f(pos[2] - y_proj[1], pos[3] - y_proj[2], 0) +
                (1f0 - in_x_range) * (1f0 - in_y_range) * (pos - xy_proj)
            );

            # (1) ... except if the bottom face is closer
            # directly calculate the distance here, treating anything from -radius .. radius
            # as zero distance (or 0 .. radius with symmetry)
            base_dist = norm(Vec3f(
                max(pos[1] - radius, 0f0),
                max(pos[2] - radius, 0f0),
                pos[3] - 2f0 * height
            ))

            # figure out if we're inside tbe pyramid by checking if x, y < the width
            # of the pyramid at the closest point, and if we're not below the pyramid
            local_radius = in_x_range * x_proj[1] + in_y_range * y_proj[1] +
                (1f0 - in_x_range) * (1f0 - in_y_range) * xy_proj[1];
            is_inside = (pos[1] < local_radius) && (pos[2] < local_radius) && (abs(ray_pos[3]) < height);
            _sign = ifelse(is_inside, -1f0, 1f0)

            return _sign * min(mantle_dist, base_dist);
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
                rep_dist = Vec3f(command.data[1:3])
                limit = Vec3f(command.data[4:6])
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
                return pos .- command.data;
            end
            return pos
        end

        function evaluate_shape_command(command, pos)
            data = ntuple(i -> command.data[i + 4], length(command.data) - 4)

            if command.id == Commands.shape3D_sphere
                return sphere(pos, data...)::Float32
            elseif command.id == Commands.shape3D_octahedron
                return octahedron(pos, data...)::Float32
            elseif command.id == Commands.shape3D_pyramid
                return pyramid(pos, data...)::Float32
            elseif command.id == Commands.shape3D_torus
                return torus(pos, data...)::Float32
            elseif command.id == Commands.shape3D_capsule
                return capsule(pos, data...)::Float32
            elseif command.id == Commands.shape3D_cylinder
                return cylinder(pos, data...)::Float32
            elseif command.id == Commands.shape3D_ellipsoid
                return ellipsoid(pos, Vec3f(data...))::Float32
            elseif command.id == Commands.shape3D_rect
                return rect(pos, Vec3f(data...))::Float32
            elseif command.id == Commands.shape3D_link
                return link(pos, data...)::Float32
            elseif command.id == Commands.shape3D_cone
                return cone(pos, data...)::Float32
            elseif command.id == Commands.shape3D_capped_cone
                return capped_cone(pos, data...)::Float32
            elseif command.id == Commands.shape3D_box_frame
                return box_frame(pos, Vec3f(data[1:3]), data[4])::Float32
            elseif command.id == Commands.shape3D_capped_torus
                return capped_torus(pos, data...)::Float32
            else
                return 10_000f0
            end
        end

        function evaluate_postfix_command(command, pos, sdf)
            if command.id == Comamnds.op_extrusion
                vec = Vec2f(sdf, length(abs.(pos) .- command.data));
                sdf = min(max(vec[1], vec[2]), 0f0) + norm(max(vec, 0f0));
            elseif command.id == Comamnds.op_rounding
                sdf = sdf - command.data[1]
            elseif command.id == Comamnds.op_onion
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
    end


    struct Command{N}
        id::Commands.ID
        data::Vec{N, Float32}

        function Command(id::Commands.ID, args...)
            data = mapreduce((a, b) -> Vec(a..., b...), args, init = Vec{0, Float32}()) do arg
                return Float32.(make_splattable(arg))
            end

            expected = Commands.get_num_parameters(id)
            if expected != length(data)
                op_name = Commands.get_name(id)
                throw(ArgumentError("$op_name requires $expected arguments, but $(length(data)) were given."))
            end

            return new{expected}(id, data)
        end
    end

    make_splattable(x) = x
    make_splattable(q::Quaternion) = q.data
    make_splattable(c::RGBA) = reinterpret(Vec4f, c)

    struct Node
        # prefixes | shape or merge | postfixes
        commands::Vector{Command}
        children::Vector{Node}
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

        return Node(commands, Node[])
    end

    function process_commands(main, ops, reset = true)
        was_postfix = false
        commands = Command[]
        reset && push!(commands, Command(Commands._reset))

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

        return Node(commands, children)
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

    function compute_signed_distance_at(node::SDF.Node, pos)
        sdf = NaN32

        commands = if isempty(node.children)
            view(node.commands, 1:length(node.commands))
        else
            sdfs = Float32[compute_signed_distance_at(child, pos) for child in node.children]
            sdf = evaluate_merge_command(first(node.commands), sdfs)
            view(node.commands, 2:length(node.commands))
        end

        for command in commands
            pos, sdf = evaluate_command(command, pos, sdf)
        end

        return sdf
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
    idx_size = cld.(_size .- 1, bricksize)
    indices = fill(UInt32(0), idx_size)

    return Brickmap{T}(indices, bricks, _size, bricksize)
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


function sdf_brickmap(bb::Rect3f, root::SDF.Node, N = 512, bricksize = 8)
    if !allequal(widths(bb))
        error("Bounding box must be a cube, i.e. equal widths, but has $(widths(bb))")
    end

    # left and right edge of the brickmap map to extrema of bb
    # each brick is a cell in the brickmap, so we need N-1 bricks to create N edges
    N_blocks = cld(N - 1, bricksize)
    N = N_blocks * bricksize + 1

    brickmap = Brickmap{N0f8}(bricksize, N)
    @assert all(==(N), brickmap.size)
    @assert all(==(N_blocks), size(brickmap.indexmap))

    box_scale = norm(widths(bb))
    normalization = Float32(1.0 / box_scale)
    brickdiameter = sqrt(3.0) / (N_blocks - 1)
    celldiameter = brickdiameter / bricksize

    # step through coarse grid (N_blocks is the number of bricks/cells)
    delta = widths(bb) ./ N_blocks
    mini = minimum(bb)
    # step through brick grid (delta is the width of the brick, bricksize is edge-like)
    brick_delta = delta / (bricksize - 1)

    uint8_scale = 255f0 / (2f0 * celldiameter)
    @info brickdiameter
    @info celldiameter

    for k in 1:N_blocks
        z = mini[3] + delta[3] * (k - 0.5)
        for j in 1:N_blocks
            y = mini[2] + delta[2] * (j - 0.5)
            for i in 1:N_blocks
                x = mini[1] + delta[1] * (i - 0.5)

                # check if brick could contain edge based on center
                dist = normalization * SDF.compute_signed_distance_at(root, Point3f(x, y, z))
                if abs(dist) < 0.5 * brickdiameter
                    brick = Array{N0f8, 3}(undef, bricksize, bricksize, bricksize)
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
                                dist = normalization * dist
                                # -celldiameter .. celldiameter -> 0..255
                                f255 = clamp((dist + celldiameter) * uint8_scale, 0, 255)
                                brick[bi, bj, bk] = N0f8(round(UInt8, f255), nothing)
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
                        insert_brick!(brickmap, i, j, k, brick)
                    end
                end

            end
        end
    end

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
    brickmap = sdf_brickmap(bb, node, 256)
    return (ep_x, ep_y, ep_z, brickmap)
end
module SDF
    using GeometryBasics
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

end

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

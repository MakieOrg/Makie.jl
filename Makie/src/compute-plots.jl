using Base: RefValue
using ComputePipeline: AbstractComputeGraph, ComputeGraphView

# TODO: Should this be moved to ComputePipeline? Or do we want to keep
# ShaderAbstractions out of it?
function ComputePipeline.add_input!(
        attr::ComputeGraph, key::Symbol,
        value::ShaderAbstractions.UpdatableArray
    )
    x = ComputePipeline._add_input!(identity, attr, key, value)
    # Let Sampler/Buffer updates get processed first, before notifying the
    # compute graph, so that the resolved plot has the new data
    on(_ -> update!(attr, key => value), ShaderAbstractions.updater(value).update, priority = -1)
    return x
end

function ComputePipeline.add_input!(
        conversion_func, attr::ComputeGraph,
        key::Symbol, value::ShaderAbstractions.UpdatableArray
    )
    x = ComputePipeline._add_input!(conversion_func, attr, key, value)
    on(_ -> update!(attr, key => value), ShaderAbstractions.updater(value).update, priority = -1)
    return x
end

ComputePipeline.add_input!(f, p::Plot, args...; kwargs...) = add_input!(f, p.attributes, args...; kwargs...)
ComputePipeline.add_input!(p::Plot, args...; kwargs...) = add_input!(p.attributes, args...; kwargs...)

Base.haskey(x::Plot, key) = haskey(x.attributes, key)
Base.get(f::Function, x::Plot, key::Symbol) = haskey(x.attributes, key) ? x.attributes[key] : f()
Base.get(x::Plot, key::Symbol, default) = get(() -> default, x, key)

Base.getindex(plot::Plot, key::Symbol) = getproperty(plot, key)
Base.setindex!(plot::Plot, val, key::Symbol) = setproperty!(plot, key, val)
function Base.setindex!(plot::Plot, val, key::Int)
    sym = Symbol("arg", key)
    return setindex!(plot, val, sym)
end


function data_limits(plot::Plot)::Rect3d
    if haskey(plot, :data_limits)
        return plot.data_limits[]
    end
    isempty(plot.plots) && return Rect3d()
    bb_ref = Base.RefValue(data_limits(plot.plots[1]))
    for i in 2:length(plot.plots)
        update_boundingbox!(bb_ref, data_limits(plot.plots[i]))
    end
    return bb_ref[]
end

function ComputePipeline.update!(plot::Plot, dict)
    ComputePipeline.update!(plot.attributes, dict)
    return
end
function ComputePipeline.update!(plot::Plot; args...)
    ComputePipeline.update!(plot.attributes; args...)
    return
end

function ComputePipeline.update!(plot::Plot, args...; attr...)
    kw = [Pair{Symbol, Any}(Symbol(:arg, i), arg) for (i, arg) in enumerate(args)]
    for (a, v) in attr
        push!(kw, Pair{Symbol, Any}(a, v))
    end
    ComputePipeline.update!(plot.attributes, kw)
    return
end

function Base.getproperty(plot::Plot, key::Symbol)
    if key in fieldnames(typeof(plot))
        return getfield(plot, key)
    end
    return plot.attributes[key]
end

function Base.setproperty!(plot::Plot, key::Symbol, val::Observable)
    error(
        "Setting an Attribute ($key) to an Observable is no longer allowed.\n" *
            "If you are using attributes as storage in a recipe, i.e. `plot[key] = map/lift(...)` " *
            "either track the Observable as a variable `var = map/lift(...)` or consider using " *
            "`register_computation!()` or the ComputePipelines `map!()` methods.\n" *
            "If you are trying to create a new input to a ComputeGraph use `add_input!(graph, key, obs)` explicitly."
    )
end

function Base.setproperty!(plot::Plot, key::Symbol, val)
    if key in fieldnames(typeof(plot))
        return Base.setfield!(plot, key, val)
    end
    attr = plot.attributes
    if haskey(attr.inputs, key)
        setproperty!(attr, key, val)
    elseif ComputePipeline.has_nested_key(attr, key)
        nested_update!(plot, key, val)
    else
        add_input!(attr, key, val)
        # maybe best to not make assumptions about user attributes?
        # CairoMakie rasterize needs this (or be treated with more care)
        ComputePipeline.set_type!(attr[key], Any)
    end
    return plot
end

function nested_update!(plot::P, key::Symbol, val) where {P}
    doc_attr = documented_attributes(P)
    updates = Pair{Symbol, Any}[]
    prepare_nested_update!(updates, doc_attr, doc_attr.nesting.keytables[1][key], val)
    update!(plot.attributes, updates)
    return
end

function prepare_nested_update!(updates, attr, layer, val)
    @assert layer > 0 # Should be given since we check `has_nested_key` in setproperty
    for (key, idx) in attr.nesting.keytables[layer]
        haskey(val, key) || continue
        if idx > 0
            prepare_nested_update!(updates, attr, idx, to_value(val[key]))
        else
            push!(updates, attr.merged_keys[-idx] => to_value(val[key]))
        end
    end
    return
end

# This is data_limits(), not boundingbox()
# TODO: Should data_limits() be simplified to be purely based on converted arguments?
function scatter_limits(positions, space::Symbol, markerspace::Symbol, scale, offset, rotation, marker_offset)
    if space === markerspace
        bb = Rect3d()
        for (i, p) in enumerate(positions)
            marker_pos = to_ndim(Point3d, p, 0) + sv_getindex(marker_offset, i)
            quad_origin = to_ndim(Vec3d, sv_getindex(offset, i), 0)
            quad_size = Vec2d(sv_getindex(scale, i))
            quad_rotation = sv_getindex(rotation, i)

            quad_origin = quad_rotation * quad_origin
            quad_v1 = quad_rotation * Vec3d(quad_size[1], 0, 0)
            quad_v2 = quad_rotation * Vec3d(0, quad_size[2], 0)

            bb = update_boundingbox(bb, marker_pos + quad_origin)
            bb = update_boundingbox(bb, marker_pos + quad_origin + quad_v1)
            bb = update_boundingbox(bb, marker_pos + quad_origin + quad_v2)
            bb = update_boundingbox(bb, marker_pos + quad_origin + quad_v1 + quad_v2)
        end
        return bb
    else
        return Rect3d(positions)
    end
end

function meshscatter_data_limits(positions, marker_bb, scales, rotation)
    # fast path for constant markersize
    if scales isa VecTypes{3} && rotation isa Quaternion
        bb = Rect3d(positions)
        marker_bb = rotation * (marker_bb * scales)
        return Rect3d(minimum(bb) + minimum(marker_bb), widths(bb) + widths(marker_bb))
    else
        # TODO: optimize const scale, var rot and var scale, const rot
        return limits_with_marker_transforms(positions, scales, rotation, marker_bb)
    end
end

function meshscatter_boundingbox(_positions, model, transform_marker, marker_bb, scales, rotation)
    positions = _project(model, _positions)
    # fast path for constant markersize
    if scales isa VecTypes{3} && rotation isa Quaternion
        bb = Rect3d(positions)
        marker_bb = rotation * (marker_bb * scales)
        if transform_marker
            model = model[Vec(1, 2, 3), Vec(1, 2, 3)]
            corners = [model * p for p in coordinates(marker_bb)]
            mini = minimum(corners)
            maxi = maximum(corners)
            return Rect3d(minimum(bb) + mini, widths(bb) + maxi - mini)
        end
        return Rect3d(minimum(bb) + minimum(marker_bb), widths(bb) + widths(marker_bb))
    else
        # TODO: optimize const scale, var rot and var scale, const rot
        if transform_marker
            return limits_with_marker_transforms(positions, scales, rotation, model, marker_bb)
        else
            return limits_with_marker_transforms(positions, scales, rotation, marker_bb)
        end
    end
end


add_alpha(color, alpha) = add_alpha(Colors.color(color), Colors.alpha(color), alpha)
add_alpha(rgb, a::T, alpha) where {T} = RGBA(rgb, a * T(alpha))

function register_colormapping_without_color!(attr::ComputeGraph)
    map!(attr, [:colormap, :alpha], [:alpha_colormap, :raw_colormap, :color_mapping, :color_mapping_type]) do icm, a
        # Raw colormap from ColorGradient, which isn't scaled. We need to preserve this for later steps
        # This only differs from alpha_colormap in that it doesn't resample PlotUtils.ColorGradient...
        raw_colormap = _to_colormap(icm)::Vector{RGBAf}
        conv_colormap = to_colormap(icm)
        if a < 1.0
            alpha_colormap = add_alpha.(conv_colormap, a)
            raw_colormap .= add_alpha.(raw_colormap, a)
        else
            alpha_colormap = conv_colormap
        end
        color_mapping = icm isa PlotUtils.ColorGradient ? icm.values : nothing
        type = to_colormapping_type(icm)
        if length(conv_colormap) == 0
            error("Converted colormap must contain colors.")
        end
        return (alpha_colormap, raw_colormap, color_mapping, type)
    end

    for key in (:lowclip, :highclip)
        sym = Symbol(key, :_color)
        map!(attr, [key, :alpha_colormap], sym) do input, cmap
            if input === automatic || input === nothing
                return ifelse(key == :lowclip, first(cmap), last(cmap))
            else
                return to_color(input)
            end
        end
    end
    return
end

function register_colormapping!(attr::ComputeGraph, colorname = :color)
    register_colormapping_without_color!(attr)

    map!(
        attr,
        [colorname, :colorscale, :alpha],
        [:raw_color, :scaled_color, :fetch_pixel, :auto_colorrange]
    ) do color, colorscale, alpha
        auto_colorrange = nothing
        if color isa Union{AbstractArray{<:Real}, Real}
            scaled = smallfloat_convert.(apply_scale(colorscale, color))
            auto_colorrange = Vec2f(distinct_extrema_nan(scaled))
            T = eltype(scaled)
            val = clamp.(scaled, -floatmax(T), floatmax(T))
        elseif color isa AbstractPattern
            val = ShaderAbstractions.Sampler(add_alpha.(to_image(color), alpha), x_repeat = :repeat)
        elseif color isa ShaderAbstractions.Sampler
            val = color
        elseif color isa AbstractArray
            val = add_alpha.(color, alpha)
        else
            val = add_alpha(color, alpha)
        end
        return (color, val, color isa AbstractPattern, auto_colorrange)
    end

    return map!(
        attr,
        [:colorrange, :colorscale, :auto_colorrange], :scaled_colorrange
    ) do colorrange, colorscale, autorange
        if isnothing(autorange) # colors are actual colors, so no colormapping
            return nothing
        elseif colorrange === automatic
            return autorange
        elseif first(colorrange) == automatic
            return Vec2f((first(autorange), last(colorrange)))
        elseif last(colorrange) == automatic
            return Vec2f((first(colorrange), last(autorange)))
        else
            return Vec2f(apply_scale(colorscale, colorrange))
        end
    end
end

"""
    register_position_transforms!(plot[; kwargs...])

Registers computations that apply `transform_func` and `float32convert` to a
position input. Positions need to be an array of point-like data. The
`float32convert` will also always generate `:model_f32c` which should be used
instead of `model` after `float32convert` is applied.

## Keyword Arguments

- `input_name = :positions` sets the input to which `transform_func` applies
- `transformed_name = Symbol(input_name, :_transformed)` sets the name of positions after `transform_func` application
- `transformed_f32c_name = Symbol(transformed_name, :_f32c)` sets the name of positions after `float32convert` application

See also: [`register_positions_transformed!`](@ref), [`register_positions_transformed_f32c!`](@ref)
"""
function register_position_transforms!(plot::Plot; kwargs...)
    return register_position_transforms!(plot.attributes; kwargs...)
end

function register_position_transforms!(
        attr::ComputeGraph;
        input_name::Symbol = :positions,
        transformed_name::Symbol = Symbol(input_name, :_transformed),
        transformed_f32c_name::Symbol = Symbol(transformed_name, :_f32c),
    )
    register_positions_transformed!(attr; input_name, output_name = transformed_name)
    register_positions_transformed_f32c!(attr, input_name = transformed_name, output_name = transformed_f32c_name)
    return
end

"""
    register_positions_transformed!(plot[; input_name = :positions, output_name = :positions_transformed])

Registers `output_name` containing positions with the transform function of the plot applied to `input_name`.

See also: [`register_position_transforms!`](@ref), [`register_positions_transformed_f32c!`](@ref)
"""
function register_positions_transformed!(plot::Plot; input_name = :positions, output_name = :positions_transformed)
    return register_positions_transformed!(plot.attributes; input_name, output_name)
end

function register_positions_transformed!(
        attr::ComputeGraph;
        input_name::Symbol = :positions, output_name::Symbol = :positions_transformed
    )
    haskey(attr.outputs, input_name) || error("$input_name not found while trying to register positions transforms")
    map!(apply_transform, attr, [:transform_func, input_name], output_name)
    return
end

"""
    register_positions_transformed_f32c!(plot[; input_name = :positions, output_name = :positions_transformed])

Registers `output_name` containing positions with the parent scenes float32convert applied to `input_name`.
Note that this does not apply transformation functions.

See also: [`register_position_transforms!`](@ref), [`register_positions_transformed!`](@ref)
"""
function register_positions_transformed_f32c!(
        plot::Plot; input_name = :positions_transformed, output_name = :positions_transformed_f32c
    )
    return register_positions_transformed_f32c!(plot.attributes; input_name, output_name)
end

function register_positions_transformed_f32c!(
        attr::ComputeGraph;
        input_name::Symbol = :positions_transformed, output_name::Symbol = :positions_transformed_f32c
    )
    # model_f32c is the model matrix after processing f32c. Backends should rely
    # on it if it applies to :positions_transformed_f32c

    # TODO: These are simplified, skipping what's commented out
    register_model_f32c!(attr)

    register_computation!(
        attr, [input_name, :model, :f32c, :space], [output_name]
    ) do (positions, model, f32c, space), changed, last

        trans, scale = decompose_translation_scale_matrix(model)
        # is_rot_free = is_translation_scale_matrix(model)
        if !is_data_space(space) || isnothing(f32c) || (is_identity_transform(f32c) && is_float_safe(scale, trans))
            pos = changed[1] ? el32convert(positions) : nothing
            return (pos,)
        elseif false # is_identity_transform(f32c) && !is_float_safe(scale, trans)
            # edge case: positions not float safe, model not float safe but result in float safe range
            # (this means positions -> world not float safe, but appears float safe)
        elseif false # is_float_safe(scale, trans) && is_rot_free
            # fast path: can swap order of f32c and model, i.e. apply model on GPU
        elseif false # is_rot_free
            # fast path: can merge model into f32c and skip applying model matrix on CPU
        else
            # TODO: avoid reallocating?
            output = map(positions) do point
                p4d = to_ndim(Point4d, to_ndim(Point3d, point, 0), 1)
                p4d = model * p4d
                return f32_convert(f32c, p4d[Vec(1, 2, 3)])
            end
            return (output,)
        end
    end
    return
end

function register_model_f32c!(attr)
    map!(attr, [:model, :f32c, :space], :model_f32c) do model, f32c, space
        trans, scale = decompose_translation_scale_matrix(model)

        # is_rot_free = is_translation_scale_matrix(model)
        if !is_data_space(space) || isnothing(f32c) || (is_identity_transform(f32c) && is_float_safe(scale, trans))
            return Mat4f(model)
        elseif false # is_identity_transform(f32c) && !is_float_safe(scale, trans)
            # edge case: positions not float safe, model not float safe but result in float safe range
            # (this means positions -> world not float safe, but appears float safe)
        elseif false # is_float_safe(scale, trans) && is_rot_free
            # fast path: can swap order of f32c and model, i.e. apply model on GPU
        elseif false # is_rot_free
            # fast path: can merge model into f32c and skip applying model matrix on CPU
        else
            return Mat4f(I)
        end
    end

    return
end

# Split for text compat
function register_arguments!(::Type{P}, attr::ComputeGraph, user_kw, input_args) where {P}
    inputs = _register_input_arguments!(attr, input_args)
    expanded_args = _register_expand_arguments!(P, attr, inputs, to_value.(input_args))
    _register_argument_conversions!(P, attr, user_kw, expanded_args)
    return
end

function _register_input_arguments!(attr::ComputeGraph, input_args::Tuple)
    inputs = map(enumerate(input_args)) do (i, arg)
        sym = Symbol(:arg, i)
        add_input!(attr, sym, arg)
        ComputePipeline.set_type!(attr[sym], Any)
        return sym
    end
    return inputs
end

function _register_expand_arguments!(::Type{P}, attr, inputs, input_args, is_merged = false) where {P}
    # is_merged = true means that multiple arguments are collected in one input, i.e.:
    #   true:   one input where attr[input][] = (arg1, arg2, ...)
    #   false:  multiple inputs where map(k -> attr[k][], inputs) = [arg1, arg2, ...]
    # this is used in text

    PTrait = conversion_trait(P, input_args...)
    expanded = something(expand_dimensions(PTrait, input_args...), input_args)
    # call it args for backwards compatibility (plot.args)
    map!(attr, inputs, :args) do input_args...
        args = values(is_merged ? input_args[1] : input_args)
        args_exp = expand_dimensions(PTrait, args...)
        return something(args_exp, args)
    end
    # This can change types, so force Any type in Compute node
    ComputePipeline.unsafe_init!(attr.args, Ref{Any}(expanded))
    return expanded
end

# Julia 1.10 compat
function _filter(f, xs::NamedTuple)
    isempty(xs) && return xs
    fkeys = filter(k -> f(xs[k]), keys(xs))
    vals = map(k -> xs[k], fkeys)
    return NamedTuple{fkeys}(map(k -> xs[k], fkeys))
end

function add_convert_kwargs!(graph, user_kw, P, args)
    conv_attributes = used_attributes(P, args...)
    conv_attr_input = Symbol[]
    for key in conv_attributes
        if !haskey(graph.inputs, key)
            default = pop!(user_kw, key, key === :space ? :data : nothing)
            add_input!(graph, key, default)
            ComputePipeline.set_type!(graph[key], Any)
            push!(conv_attr_input, key)
        end
    end
    register_computation!(graph, conv_attr_input, [:convert_kwargs]) do inputs, changed, last
        return (_filter(!isnothing, inputs),)
    end
    ComputePipeline.set_type!(graph[:convert_kwargs], Any)
    return
end

function add_dim_converts!(::Type{P}, attr::ComputeGraph, dim_converts, args, args_converted, user_kw) where {P}
    # Get dim of each argument. This needs to be reactive if we allow dynamic
    # attributes that change dim-mapping, e.g. direction
    kwarg_names = argument_dim_kwargs(P)

    # initialize the necessary attributes early
    for key in kwarg_names
        if !haskey(attr.inputs, key)
            default = lookup_default(P, nothing, user_kw, key)
            default isa Inherit && error("$key must be initialized without `@inherit` to be used as a argument_dims kwarg.")
            # haskey(defaults, key) || error("Cannot use `argument_dim_kwargs(::$P) = (:$key, ...)` as it is not a valid recipe Attribute.")
            add_input!(attr, key, default)
        end
    end

    kwargs = NamedTuple{kwarg_names}([getproperty(attr, name)[] for name in kwarg_names])
    dim_tuple = argument_dims(P, args_converted...; kwargs...)

    if dim_tuple === nothing
        # args declared not dim-convertible by argument_dims().
        ComputePipeline.alias!(attr, :args, :dim_converted)
        return args

    elseif !(dim_tuple isa Tuple)
        # Format check
        error("`arguments_dims() must return a `Tuple` of integers or `Nothing` but returned $dim_tuple")
    end

    # If convert_arguments() caused a change in dim-convertable arguments they
    # should apply before treating dim converts
    if args_converted !== args
        map!(attr, [:args, :convert_kwargs], :recursive_convert) do args, kwargs
            return convert_arguments(P, args...; kwargs...)
        end
        ComputePipeline.unsafe_init!(attr.recursive_convert, args_converted)
        input = :recursive_convert
    else
        input = :args
    end

    # Add node for arg -> dim mapping. Should be dynamic for attributes like
    # direction at least.
    map!(attr, [input, kwarg_names...], :arg_dims) do args, kwargs...
        nt = NamedTuple{kwarg_names}(kwargs)
        return argument_dims(P, args...; nt...)
    end

    # This sets conversions per dimension if they have not already been set.
    # If a recipe has multiple arguments for one dimension that dimension may
    # be set multiple times here (but only the first one will actually be used)
    maxdim = 0
    for (i, dim) in enumerate(dim_tuple)
        dim == 0 && continue
        if dim isa Integer
            update_dim_conversion!(dim_converts, dim, args_converted[i])
            maxdim = max(maxdim, dim)
        else
            for (j, d) in enumerate(dim)
                update_dim_conversion!(dim_converts, d, args_converted[i], j)
                maxdim = max(maxdim, d)
            end
        end
    end

    # Add input containing Symbol(:dim_convert_, i) which triggers when the
    # conversion changes. (One per dimension, so use unique on dim_tuple)
    # Note that the order in dim_convert_names is important
    dim_convert_names = Symbol[]
    for i in 1:maxdim
        obs = convert(Observable{Any}, needs_tick_update_observable(Observable{Any}(dim_converts[i])))
        converts_updated = map!(x -> dim_converts[i], Observable{Any}(), obs)
        add_input!(attr, Symbol(:dim_convert_, i), converts_updated)
        push!(dim_convert_names, Symbol(:dim_convert_, i))
    end

    # Apply dim_convert
    # TODO: Do we really need last here?
    register_computation!(
        attr, [input, :arg_dims, dim_convert_names...], [:dim_converted]
    ) do (expanded, dims, converts...), changed, last

        last_vals = isnothing(last) ? ntuple(i -> nothing, length(dims)) : last.dim_converted
        result = ntuple(length(expanded)) do i
            # argument i is associated with the dim convert of dimension dims[i]
            if i <= length(dims) && dims[i] != 0
                if dims[i] isa Integer
                    return convert_dim_value(converts[dims[i]], attr, expanded[i], last_vals[i])
                else
                    # Vector{<:VecTypes} case, where dim converts are expected to
                    # return an array for VecTypes dimension
                    # These arrays are repackaged as a Point array which hopefully
                    # goes through the remaining conversions without issues
                    parts = map(eachindex(dims[i]), dims[i]) do idx, dim
                        return convert_dim_value(converts[dim], attr, expanded[i], last_vals[i], idx)
                    end
                    return Point.(parts...)
                end
            else
                return expanded[i]
            end
        end
        return (Ref{Any}(result),)
    end

    return
end

function error_check_convert_arguments(P, args, user_kw, args_converted)
    if args_converted isa Tuple
        return :Tuple
    elseif args_converted isa Union{PlotSpec, AbstractVector{PlotSpec}, GridLayoutSpec}
        return :SpecApi
    else
        _join(a, b) = "$a, $b"
        args_splatted = mapreduce(x -> "::$(typeof(x))", _join, args)
        kwargs_splatted = mapreduce(kv -> "$(kv[1])", _join, user_kw)
        if isempty(kwargs_splatted)
            call = "convert_arguments($P, $args_splatted)"
        else
            call = "convert_arguments($P, $args_splatted; $kwargs_splatted)"
        end
        error("Result of `$call` needs to be a Tuple or SpecApi object, but is `$args_converted`.")
    end
end

function _register_argument_conversions!(::Type{P}, attr::ComputeGraph, user_kw, args) where {P}
    dim_converts = to_value(get!(() -> DimConversions(), user_kw, :dim_conversions))::DimConversions
    add_input!(attr, :dim_conversions, dim_converts)

    add_convert_kwargs!(attr, user_kw, P, args)
    kw = attr.convert_kwargs[]
    args_converted = convert_arguments(P, args...; kw...)
    error_check_convert_arguments(P, args, user_kw, args_converted)
    status = got_converted(P, conversion_trait(P, args...), args_converted)

    # Controls whether the plot is forced to apply dim converts or allowed to
    # use plain data in a dim_convert scene. Typically true for plots to scenes
    # and false for plots to other plots
    force_dimconverts = pop!(user_kw, :force_dimconverts)::Bool
    doc_attr = documented_attributes(P)
    space::Symbol = if haskey(user_kw, :space)
        to_value(user_kw[:space])
    else
        default = get_flat_default(doc_attr, :space, :data)
        default isa Symbol ? default : :data
    end

    # TODO: Can't infer types here because dim_conversions[i] are of unknown type
    dim_converted = if !is_data_space(space)
        # dim converts do not apply in relative, pixel or clip space
        ComputePipeline.alias!(attr, :args, :dim_converted)
        args
    elseif force_dimconverts && needs_dimconvert(dim_converts)
        add_dim_converts!(P, attr, dim_converts, args, args_converted, user_kw)
    elseif (status === true || status === SpecApi)
        # Nothing needs to be done, since we can just use convert_arguments without dim_converts
        # And just pass the arguments through
        ComputePipeline.alias!(attr, :args, :dim_converted)
        args
    elseif isnothing(status) || status === false # we don't know (e.g. recipes) or incomplete conversion
        add_dim_converts!(P, attr, dim_converts, args, args_converted, user_kw)
    end
    # backwards compatibility for plot.converted (and not only compatibility, but it's just convenient to have)

    map!(attr, [:dim_converted, :convert_kwargs], :converted) do dim_converted, convert_kwargs
        val = convert_arguments(P, dim_converted...; convert_kwargs...)
        rtype = error_check_convert_arguments(P, dim_converted, convert_kwargs, val)
        return rtype === :Tuple ? val : (val,)
    end

    # If dim converts didn't do anything we can use the previous result of
    # `convert_arguments()` to init the node
    if attr.dim_converted[] === args
        result_type = error_check_convert_arguments(P, args, user_kw, args_converted)
        x = result_type === :Tuple ? args_converted : (args_converted,)
        ComputePipeline.unsafe_init!(attr.converted, x)
    end

    converted = attr[:converted][]
    n_args = length(converted)
    map!(attr, :converted, [argument_names(P, n_args)...]) do converted
        return converted # destructure
    end

    add_input!(attr, :transform_func, identity)
    ComputePipeline.set_type!(attr.transform_func, Any)

    add_input!(attr, :f32c, :uninitialized)

    return
end

function register_marker_computations!(attr::ComputeGraph)

    # TODO: allowing user supplied atlas for e.g. sprite animations would be nice...

    return map!(
        attr, [:marker, :markersize, :font],
        [:quad_offset, :quad_scale]
    ) do marker, markersize, font
        atlas = get_texture_atlas()
        quad_scale = rescale_marker(atlas, marker, font, markersize)
        quad_offset = offset_marker(atlas, marker, font, markersize)

        return (quad_offset, quad_scale)
    end
end

const PrimitivePlotTypes = Union{
    Scatter, Lines, LineSegments, Text, Mesh,
    MeshScatter, Image, Heatmap, Surface, Voxels, Volume,
}


function ComputePipeline.register_computation!(f, p::Plot, inputs::Vector, outputs::Vector{Symbol})
    return register_computation!(f, p.attributes, inputs, outputs)
end
function Base.map!(f, p::Plot, inputs::Union{Vector, ComputePipeline.InputNodeTypes}, outputs::Union{Vector, ComputePipeline.OutputNodeTypes})
    return map!(f, p.attributes, inputs, outputs)
end

struct AttributeConvert{Key, Plot} <: Function end
@inline AttributeConvert(key, plot) = AttributeConvert{key, plot}()
Base.nameof(::AttributeConvert{Key, Plot}) where {Key, Plot} = "AttributeConvert{$(Key), $(Plot)}"
function (::AttributeConvert{key, plot})(value) where {key, plot}
    return convert_attribute(value, Key{key}(), Key{plot}())
end
function (::AttributeConvert{key, plot})(value, @nospecialize(changed), @nospecialize(cached)) where {key, plot}
    return (convert_attribute(value[1], Key{key}(), Key{plot}()),)
end
function ComputePipeline.get_callback_info(::AttributeConvert{key, plot}, value) where {key, plot}
    return ComputePipeline.get_callback_info(convert_attribute, value, Key{key}(), Key{plot}())
end

struct CycleConvert{F} <: Function
    callback::F
    palettes::Attributes
    graph::ComputeGraph
    key::Symbol
end

(cc::CycleConvert)(val, @nospecialize(changed), @nospecialize(cached)) = (cc(val[1]),)
function (cc::CycleConvert)(value)
    if value isa Cycled
        cycle = cc.graph.cycle[]::Cycle
        x = get_cycle_attribute(cc.palettes, cc.key, value.i, cycle)
        return cc.callback(x)
    elseif value === :cycled
        cycle = cc.graph.cycle[]::Cycle
        cycle_index = cc.graph.cycle_index[]::Int
        x = get_cycle_attribute(cc.palettes, cc.key, cycle_index, cycle)
        return cc.callback(x)
    else
        return cc.callback(value)
    end
end

function get_next_cycle_index(scene, name)
    lookup = scene.compute[:cycle_counters][]::Dict{Symbol, Int}
    cycle_index = get(lookup, name, 0) + 1
    lookup[name] = cycle_index
    return cycle_index
end

function add_theme!(::Type{T}, user_kw, graph::ComputeGraph, scene::Scene) where {T <: Plot}
    # So far we have set attributes based on the plot defaults and keyword
    # arguments. In this function we now resolve `@inherit`ed attributes and
    # apply `theme[plotsym(T)]` if it exists.

    attr = documented_attributes(T)
    name = plotsym(T)

    # Handle cycling
    if has_flat_key(attr, :cycle)
        # This will increment the scenes cycle counter for this plot type (plotsym)
        # when the first CycleConvert uses it. After that it will just grab the
        # cached cycle index.
        map!(() -> get_next_cycle_index(scene, name), graph, Symbol[], :cycle_index)

        if !haskey(user_kw, :cycle)
            _cycle = to_value(lookup_default(attr, scene, name, NamedTuple(), :cycle))
            graph.cycle = _cycle
        end
    else
        add_constant!(graph, :cycle_index, 0)
        graph.cycle = Cycle([])
    end

    cycle = graph.cycle[]::Cycle

    # Because we only adjust the callbacks of inputs that are in Cycle at this
    # point in time, adding more attributes to cycle after creating the plot does
    # not work. Adjusting which palettes are used for each attribute works though
    for name in attrsyms(cycle)
        # Should passthroughs be able to cycle?
        # (i.e. should we change graph[name].parent instead?)
        if haskey(graph.inputs, name)
            input = graph.inputs[name]
            input.f = CycleConvert(input.f, scene.theme.palette, graph, name)
        end
    end

    exclude = Set{Symbol}([:transformation, :model, :transform_func])

    # TODO: Should add_theme!() be allowed to set used_attributes?
    # That would require add_convert_kwargs!() to not delete them from kwargs
    # so that user input doesn't get overwritten here
    conv_attributes = used_attributes(T, graph.args[]...)
    union!(exclude, conv_attributes)

    add_theme!(graph, attr, T, scene, exclude, user_kw, cycle)

    return
end

register_camera!(scene::Scene, plot::Plot) = register_camera!(plot.attributes, scene.compute)

function argument_error(PTrait, P, attr, user_kw, converted)
    args = attr.args[]
    used_attr = used_attributes(P, args...) # ensure that P is registered
    kw = Dict([k => v for (k, v) in user_kw if k in used_attr])
    kw_str = isempty(kw) ? "" : " and kw: $(kw)"
    kw_convert = isempty(kw) ? "" : "; kw..."
    conv_trait = PTrait isa NoConversion ? "" : " (With conversion trait $(PTrait))"
    types = types_for_plot_arguments(P, PTrait)
    dim_converts_info = if haskey(attr, :arg_dims)
        """
        If the result contains dim convert related types, e.g. Unitful types, \
        Dates types or Categorical values, the application of dim converts likely \
        failed. Dim converts were called with
            $(typeof(attr.dim_converted.parent.inputs[1][]))
        which were mapped to dimensions $(attr.arg_dims[]). If this is not the \
        correct mapping argument_dims(::Type{<:$(P)}, args...) may need to be \
        implemented or convert_arguments(...) may need stricter typing to \
        prevent early conversions.
        """
    else
        space = haskey(attr, :space) ? attr[:space][] : :data
        """
        (Dim converts were not applied. This happens if `space = $space` \
        is not in data space or if the target type of the conversion is reachable \
        without dim converts.)
        """
    end
    throw(
        ArgumentError(
            """

            Conversion failed for $(P)$(conv_trait) with args:
                $(typeof(args)) $(kw_str)
            Got converted to:
                $(typeof(converted))
            $(P) requires to convert to argument types
                $(types),
            which convert_arguments didn't succeed in. To fix this overload \
            convert_arguments(P, args...$(kw_convert)) for Type{<:$(P)} or $(PTrait) \
            and return an object of the correct type.
            $dim_converts_info
            """
        )
    )
end

function Plot{Func}(user_args::Tuple, user_attributes::Union{Dict, NamedTuple}) where {Func}
    isempty(user_args) && throw(ArgumentError("Failed to construct plot: No plot arguments given."))

    P = Plot{Func}

    if first(user_args) isa Attributes
        # This should keep user_args[1] unchanged, in case they get reused.
        attr = convert(Dict{Symbol, Any}, attributes(first(user_args)))
        foreach(p -> get!(user_attributes, p[1], p[2]), pairs(attr))
        return build_plot(P, nothing, Base.tail(user_args), user_attributes)
    elseif first(user_args) isa AbstractComputeGraph
        return build_plot(P, user_args[1], Base.tail(user_args), user_attributes)
    else
        return build_plot(P, nothing, user_args, user_attributes)
    end
end

function init_graph!(build_callback, graph, attr, is_primitive, kwargs, parent)
    exclude = (:transformation, :transform_func)
    prepare_graph_for_attributes!(graph, attr, exclude, is_primitive = is_primitive)
    add_from_kwargs!(build_callback, graph, attr, kwargs, exclude)
    if !isnothing(parent)
        exclude_from_parent = (:model, :transformation, :transform_func, :model_f32c)
        connect_parent!(build_callback, graph, parent, attr, exclude_from_parent)
    end
    add_remaining_inputs!(build_callback, graph, attr, exclude)
    return
end

function add_attributes!(::Type{P}, graph, parent, kwargs) where {P <: Plot}
    attr = documented_attributes(P)
    name = Makie.plotkey(P)
    is_primitive = P <: PrimitivePlotTypes

    # Cycle is added here to allow `plot(..., cycle = Observable(...))`. Updating
    # cycle may only change which attribute maps to which, not which attributes
    # are cycled (see add_theme!())
    if !haskey(graph, :cycle)
        _cycle = get(kwargs, :cycle, :uninitialized)
        add_input!(AttributeConvert(:cycle, name), graph, :cycle, _cycle)
    end

    if is_primitive
        init_graph!(key -> AttributeConvert(key, name), graph, attr, true, kwargs, parent)
    else
        init_graph!(key -> compute_identity, graph, attr, false, kwargs, parent)
    end

    if !haskey(graph, :model)
        add_input!(graph, :model, Mat4d(I))
    end

    return
end

function build_plot(::Type{P}, parent, user_args, user_attributes) where {P}
    graph = ComputeGraph()

    register_arguments!(P, graph, user_attributes, user_args)
    converted = graph.converted[]
    PTrait = conversion_trait(P, graph.args[]...)
    if got_converted(P, PTrait, converted) == false
        argument_error(PTrait, P, graph, user_attributes, converted)
    end

    # compiler can't infer this, but FinalPlotFunc may differ (e.g. qqnorm -> qqplot)
    ArgTyp = typeof(converted)
    FinalPlotFunc = plotfunc(plottype(P, converted...))

    add_attributes!(Plot{FinalPlotFunc}, graph, parent, user_attributes)

    return Plot{FinalPlotFunc, ArgTyp}(user_attributes, graph)
end

# should this just be connect_plot?
function connect_plot!(parent::SceneLike, plot::Plot{Func}) where {Func}
    scene = parent_scene(parent)
    attr = plot.attributes
    add_theme!(Plot{Func}, plot.kw, attr, scene)
    plot.parent = parent

    if attr.inputs[:f32c].value !== :uninitialized
        error("plot.f32c must not be resolved before the scene is connected!")
    end
    if scene.float32convert === nothing # this is statically a Nothing or Float32Convert
        attr.f32c = nothing
    else
        on(plot, scene.float32convert.scaling, update = true) do f32c
            attr.f32c = f32c
            return
        end
    end

    handle_transformation!(plot, parent)

    if plot isa PrimitivePlotTypes
        register_camera!(scene, plot)
    end
    calculated_attributes!(Plot{Func}, plot)

    plot!(plot)

    # Used to add things like `label` for Legend
    for (k, v) in plot.kw
        if !haskey(plot.attributes, k)
            add_input!(plot.attributes, k, v)
        end
    end

    return
end

function collect_all_connected_nodes(computed::ComputePipeline.Computed, tracked = Set{Symbol}())
    push!(tracked, computed.name)
    for edge in computed.parent.dependents
        for node in edge.outputs
            collect_all_connected_nodes(node)
        end
    end
    return tracked
end

Observables.to_value(computed::ComputePipeline.Computed) = computed[]
function Base.notify(computed::ComputePipeline.Computed)
    nodes = collect_all_connected_nodes(computed)
    graph = computed.parent.graph
    to_notify = intersect(nodes, keys(graph.observables))
    foreach(to_notify) do key
        notify(graph.observables[key])
    end
    return
end


function attribute_per_pos!(attr, attribute::Symbol, output_name::Symbol)
    return map!(attr, [attribute, :positions], output_name) do vec, positions
        if !(vec isa AbstractVector)
            return vec
        end
        NP = length(positions)
        NC = length(vec)
        NP == NC && return vec
        if NP ÷ 2 == NC
            output = [vec[div(i + 1, 2)] for i in 1:NP]
            return output
        end
        error("Color vector length $(NC) does not match position length $(NP)")
        return vec
    end
end


function color_per_mesh(ccolors, vertes_per_mesh)
    result = similar(ccolors, float32type(ccolors), sum(vertes_per_mesh))
    i = 1
    for (cs, len) in zip(ccolors, vertes_per_mesh)
        for j in 1:len
            result[i] = cs
            i += 1
        end
    end
    return result
end

function register_mesh_decomposition!(attr)
    # :arg1 is user input, :mesh is after convert_arguments and dim converts (?)
    map!(attr, :mesh, [:positions, :faces, :normals, :texturecoordinates]) do merged
        pos = coordinates(merged)
        faces = decompose(GLTriangleFace, merged)
        normies = normals(merged)
        texturecoords = texturecoordinates(merged)
        return (pos, faces, normies, texturecoords)
    end

    return map!(
        attr, [:arg1, :mesh, :color], [:mesh_color, :interpolate_in_fragment_shader]
    ) do meshes, merged, color

        if hasproperty(merged, :color)
            return (merged.color, true)
        elseif meshes isa Vector{<:AbstractGeometry} && color isa Vector && length(color) == length(meshes)
            _color = color_per_mesh(color, map(x -> length(coordinates(x)), meshes))
            return (_color, false)
        else
            return (color, true)
        end
    end
end

function canonical_vertex_ids(positions)
    canonical = Dict{eltype(positions), Int}()
    return Int[get!(canonical, p, i) for (i, p) in enumerate(positions)]
end

function count_mesh_edges(faces, canonical_ids)
    counts = Dict{NTuple{2, Int}, Int}()
    for f in faces
        n = length(f)
        for i in 1:n
            edge = minmax(canonical_ids[f[i]], canonical_ids[f[mod1(i + 1, n)]])
            edge[1] == edge[2] && continue
            counts[edge] = get(counts, edge, 0) + 1
        end
    end
    return counts
end

function corner_wings(incident_edges, positions, v, o1, o2)
    at(u) = to_ndim(Point3d, positions[u], 0)
    direction(u) = normalize(Vec3d(at(u) - at(v)))
    d1 = direction(o1)
    d2 = direction(o2)
    plane_normal = normalize(cross(d1, d2))

    # A wing that leaves the triangle's plane belongs to a face seen at an angle, so its
    # stroke band should not continue onto this triangle (it would project as a stray
    # band across the face). Slight non-planarity is allowed for curved surfaces.
    function is_in_plane((u, _))
        out_of_plane = abs(dot(plane_normal, direction(u)))
        return !isnan(out_of_plane) && out_of_plane < 0.3
    end
    wings = filter(((u, _),) -> u != o1 && u != o2, incident_edges)
    wings = filter(is_in_plane, wings)
    length(wings) <= 2 && return wings

    function wedge_closeness((u, _))
        du = direction(u)
        score = max(dot(du, d1), dot(du, d2))
        return isnan(score) ? -Inf : score
    end
    return partialsort(wings, 1:2; by = wedge_closeness, rev = true)
end

"""
    stroke_edge_data(mesh, gl_faces, strokeedges)

Computes the per-triangle edge information needed to stroke visible mesh edges in a
backend shader. A stroked edge gets a width multiplier of 1 if it lies on the mesh
boundary (belongs to exactly one face of `mesh`) and 0.5 if it is shared between faces
and `strokeedges === :all` (so both adjacent faces together render one full stroke width).
Edges that do not appear in `faces(mesh)`, i.e. those introduced by triangulating
non-triangular faces, are never stroked. Vertices are matched by position, so edges
remain shared even if faces reference duplicated vertices.

Returns three vectors with one element per triangle in `gl_faces`:

- `edge_widths::Vector{Vec3f}`: width multipliers of the triangle's own edges,
  ordered 1-2, 2-3, 3-1, with 0 for edges that are not stroked.
- `wing_indices::Vector{Vec{6, Int32}}` and `wing_widths::Vector{Vec{6, Float32}}`:
  per corner (two slots each), stroked edges that are incident to the corner vertex but
  are not edges of the triangle itself, given as the vertex index of the other edge
  endpoint and the edge's width multiplier. Index 0 marks an unused slot. Without these
  "wings", a stroke band that continues past a corner into a neighboring triangle would
  be cut off at the triangulation edge, leaving notches. Only edges roughly coplanar with
  the triangle qualify, and if more than two remain, the two closest in angle to the
  triangle's own edges at that corner are kept, since those are the ones whose bands can
  reach into the triangle.
"""
function stroke_edge_data(mesh, gl_faces, strokeedges::Symbol)
    positions = coordinates(mesh)
    canonical_ids = canonical_vertex_ids(positions)
    counts = count_mesh_edges(faces(mesh), canonical_ids)
    shared_width = strokeedges === :all ? 0.5f0 : 0.0f0
    edge_width(count) = count == 0 ? 0.0f0 : (count == 1 ? 1.0f0 : shared_width)

    incident = Dict{Int, Vector{Tuple{Int, Float32}}}()
    for (edge, count) in counts
        width = edge_width(count)
        width == 0.0f0 && continue
        push!(get!(Vector{Tuple{Int, Float32}}, incident, edge[1]), (edge[2], width))
        push!(get!(Vector{Tuple{Int, Float32}}, incident, edge[2]), (edge[1], width))
    end

    no_wings = Tuple{Int, Float32}[]
    edge_widths = Vector{Vec3f}(undef, length(gl_faces))
    wing_indices = Vector{Vec{6, Int32}}(undef, length(gl_faces))
    wing_widths = Vector{Vec{6, Float32}}(undef, length(gl_faces))

    for (t, f) in enumerate(gl_faces)
        corners = (canonical_ids[f[1]], canonical_ids[f[2]], canonical_ids[f[3]])
        edge_widths[t] = Vec3f(
            ntuple(3) do i
                edge_width(get(counts, minmax(corners[i], corners[mod1(i + 1, 3)]), 0))
            end
        )

        indices = zeros(Int32, 6)
        widths = zeros(Float32, 6)
        for i in 1:3
            v = corners[i]
            o1 = corners[mod1(i + 1, 3)]
            o2 = corners[mod1(i + 2, 3)]
            wings = corner_wings(get(incident, v, no_wings), positions, v, o1, o2)
            for (j, (u, width)) in enumerate(wings)
                indices[2 * (i - 1) + j] = u
                widths[2 * (i - 1) + j] = width
            end
        end
        wing_indices[t] = Vec{6, Int32}(indices)
        wing_widths[t] = Vec{6, Float32}(widths)
    end

    return edge_widths, wing_indices, wing_widths
end

function register_mesh_stroke!(attr)
    return map!(
        attr, [:mesh, :faces, :strokeedges, :strokewidth],
        [:stroke_edge_widths, :stroke_wing_indices, :stroke_wing_widths]
    ) do mesh, gl_faces, strokeedges, strokewidth
        if iszero(strokewidth)
            return (Vec3f[], Vec{6, Int32}[], Vec{6, Float32}[])
        end
        return stroke_edge_data(mesh, gl_faces, strokeedges)
    end
end

# Packs stroke data into 9 texture texels per triangle for backend shaders: 3x the corner
# positions with the width multiplier of the edge from that corner to the next, then per
# corner 2x wing edge endpoints with their width multipliers (width 0 = unused slot).
function register_stroke_data!(attr)
    haskey(attr, :stroke_data_packed) && return attr[:stroke_data_packed]
    return map!(
        attr,
        [:positions_transformed_f32c, :faces, :stroke_edge_widths, :stroke_wing_indices, :stroke_wing_widths],
        :stroke_data_packed
    ) do positions, faces, edge_widths, wing_indices, wing_widths
        isempty(edge_widths) && return fill(Vec4f(0), 9)
        at(idx) = to_ndim(Point3f, positions[idx], 0.0f0)
        data = Vector{Vec4f}(undef, 9 * length(faces))
        for (t, f) in enumerate(faces)
            base = 9 * (t - 1)
            for i in 1:3
                p = at(f[i])
                data[base + i] = Vec4f(p[1], p[2], p[3], edge_widths[t][i])
            end
            for k in 1:6
                idx = wing_indices[t][k]
                if idx == 0
                    data[base + 3 + k] = Vec4f(0)
                else
                    p = at(idx)
                    data[base + 3 + k] = Vec4f(p[1], p[2], p[3], wing_widths[t][k])
                end
            end
        end
        return data
    end
end

# optionally converts uv_transform to the one used with patterns (different defaults)
function register_pattern_uv_transform!(attr; modelname = :model_f32c, colorname = :color)
    register_computation!(
        attr,
        [:uv_transform, :projectionview, :viewport, modelname, colorname, :fetch_pixel],
        [:pattern_uv_transform]
    ) do (uvt, pv, vp, model, pattern, is_pattern), changed, cached

        needs_update = isnothing(cached) || changed.fetch_pixel || is_pattern || changed.uv_transform
        if needs_update
            if is_pattern
                # This changes what `automatic` converts to
                input_uvt = haskey(attr.inputs, :uv_transform) ? attr.inputs[:uv_transform].value : uvt
                new_uvt = pattern_uv_transform(input_uvt, pv * model, widths(vp), pattern)
                return (new_uvt,)
            else
                return (uvt,)
            end
        else
            return nothing
        end
    end
    return
end


function calculated_attributes!(::Type{Image}, plot::Plot)
    attr = plot.attributes
    calculated_attributes!(Heatmap, plot)
    # this must not sort to preserve inverse value ranges (e.g. 1..0), data_limits
    # must must sort to generate non-negative widths in that case
    map!(attr, [:x, :y], :positions) do x, y
        mini = Vec3d(first(x), first(y), 0)
        maxi = Vec3d(last(x), last(y), 0)
        return decompose(Point2d, Rect2d(mini, maxi .- mini))
    end
    return register_position_transforms!(attr)
end

function calculated_attributes!(::Type{Heatmap}, plot::Plot)
    attr = plot.attributes
    register_colormapping!(attr, :image)
    return map!(attr, [:x, :y], :data_limits) do x, y
        mini = Vec3d(minimum(x), minimum(y), 0)
        maxi = Vec3d(maximum(x), maximum(y), 0)
        return Rect3d(mini, maxi .- mini)
    end
end

function calculated_attributes!(::Type{Surface}, plot::Plot)
    attr = plot.attributes
    map!(attr, [:z, :color], :color_with_default) do z, color
        return isnothing(color) ? z : color
    end
    register_colormapping!(attr, :color_with_default)
    return map!(attr, [:x, :y, :z], :data_limits) do x, y, z
        xlims = extrema_nan(x)
        ylims = extrema_nan(y)
        zlims = extrema_nan(z)
        mini, maxi = Vec3d.(xlims, ylims, zlims)
        return Rect3d(mini, maxi .- mini)
    end
end

function calculated_attributes!(::Type{Scatter}, plot::Plot)
    attr = plot.attributes
    register_marker_computations!(attr)
    register_colormapping!(attr)
    register_position_transforms!(attr)
    map!(attr, :rotation, [:converted_rotation, :billboard]) do rotation
        return (convert_attribute(rotation, key"rotation"()), rotation isa Billboard)
    end
    return map!(attr, [:positions, :space, :markerspace, :quad_scale, :quad_offset, :converted_rotation, :marker_offset], :data_limits) do args...
        return scatter_limits(args...)
    end

end

function calculated_attributes!(::Type{MeshScatter}, plot::Plot)
    attr = plot.attributes
    register_colormapping!(attr)
    register_position_transforms!(attr)
    register_pattern_uv_transform!(attr)
    map!(Rect3d, attr, :marker, :marker_bb)
    map!(meshscatter_data_limits, attr, [:positions, :marker_bb, :markersize, :rotation], :data_limits)
    return map!(
        meshscatter_boundingbox, attr, [
            :positions_transformed, :model,
            :transform_marker, :marker_bb, :markersize, :rotation,
        ], :boundingbox
    )
end


function calculated_attributes!(::PointBased, plot::Plot)
    attr = plot.attributes
    map!(attr, :positions, :data_limits) do positions
        return Rect3d(positions)
    end
    return register_position_transforms!(attr)
end


function calculated_attributes!(::Type{Lines}, plot::Plot)
    attr = plot.attributes
    register_colormapping!(attr)
    ComputePipeline.alias!(attr, :linewidth, :uniform_linewidth)
    return calculated_attributes!(PointBased(), plot)
end

function calculated_attributes!(::Type{LineSegments}, plot::Plot)
    attr = plot.attributes
    attribute_per_pos!(attr, :color, :synched_color)
    register_colormapping!(attr, :synched_color)
    attribute_per_pos!(attr, :linewidth, :uniform_linewidth)
    return calculated_attributes!(PointBased(), plot)
end

function calculated_attributes!(::Type{Mesh}, plot::Plot)
    attr = plot.attributes
    register_mesh_decomposition!(attr)
    register_mesh_stroke!(attr)
    register_colormapping!(attr, :mesh_color)
    calculated_attributes!(PointBased(), plot)
    return register_pattern_uv_transform!(attr, colorname = :mesh_color)
end

function calculated_attributes!(::Type{Volume}, plot::Plot)
    attr = plot.attributes
    ComputePipeline.alias!(attr, :model, :model_f32c)
    register_colormapping!(attr, :volume)
    return map!(attr, [:x, :y, :z], :data_limits) do x, y, z
        mini, maxi = Vec3.(x, y, z)
        return Rect3d(mini, maxi .- mini)
    end
end


get_colormapping(plot::Plot) = get_colormapping(plot, plot.attributes)
function get_colormapping(plot, attr::ComputePipeline.ComputeGraph)
    isnothing(attr[:scaled_colorrange][]) && return nothing
    haskey(attr, :cb_colormapping) && return attr[:cb_colormapping][]

    map!(attr, [:colorrange, :raw_color], :unscaled_colorrange) do colorrange, color
        if colorrange === automatic
            return isempty(color) ? Vec2f(0, 10) : Vec2f(distinct_extrema_nan(color))
        elseif first(colorrange) == automatic
            return Vec2f(first(distinct_extrema_nan(color)), last(colorrange))
        elseif last(colorrange) == automatic
            return Vec2f(first(colorrange), last(distinct_extrema_nan(color)))
        else
            return Vec2f(colorrange)
        end
    end

    attributes = [
        :raw_color, :alpha_colormap, :raw_colormap, :colorscale, :color_mapping, :unscaled_colorrange,
        :lowclip, :highclip, :nan_color, :color_mapping_type, :scaled_colorrange, :scaled_color,
    ]

    # keep it cached somewhere so we don't recreate it multiple times
    return get!(attr.observables, :_ColorMapping_obs) do
        N = ndims(attr[:raw_color][])
        Cin = typeof(attr[:raw_color][])
        Cout = typeof(attr[:scaled_color][])
        observables = map(name -> ComputePipeline.get_observable!(attr[name]), attributes)
        return Observable(ColorMapping{N, Cin, Cout}(observables...))
    end[]
end

function register_world_normalmatrix!(attr, modelname = :model_f32c)
    return map!(attr, modelname, :world_normalmatrix) do m
        return Mat3f(transpose(inv(m[Vec(1, 2, 3), Vec(1, 2, 3)])))
    end
end

function register_view_normalmatrix!(attr, modelname = :model_f32c)
    return map!(attr, [:view, modelname], :view_normalmatrix) do view, model
        i3 = Vec3(1, 2, 3)
        nm = transpose(inv(view[i3, i3] * Mat3f(model[i3, i3])))
        return nm
    end
end

# For precompilation we want a second resolve
# Since that compiles a few more functions
# TODO, make this unnecessary by a better ComputeGraph implementation?
second_resolve(fig::Figure, resolve_symbol) = second_resolve(Makie.get_scene(fig), resolve_symbol)
second_resolve(fig, resolve_symbol) = second_resolve(fig.figure, resolve_symbol)
function second_resolve(scene::Scene, resolve_symbol)
    return for_each_atomic_plot(scene) do plot
        for (k, input) in plot.attributes.inputs
            ComputePipeline.mark_dirty!(input)
        end
        if haskey(plot, resolve_symbol)
            plot[resolve_symbol][]
        end
    end
end

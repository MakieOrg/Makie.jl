using Base: RefValue
using LinearAlgebra
using GeometryBasics
using ComputePipeline

################################################################################

# Sketching usage with scatter

const ComputePlots = Union{Scatter, Lines, LineSegments}

Base.get(f::Function, x::ComputePlots, key::Symbol) = haskey(x.args[1], key) ? x.args[1][key] : f()
Base.get(x::ComputePlots, key::Symbol, default) = get(()-> default, x, key)

Base.getindex(plot::ComputePlots, idx::Integer) = plot.args[1][Symbol(:arg, idx)]
function Base.getindex(plot::ComputePlots, idx::UnitRange{<:Integer})
    return ntuple(i -> plot.converted[Symbol(:arg, i)], idx)
end

# temp fix axis selection
function args_preferred_axis(::Type{PT}, attr::ComputeGraph) where {PT <: Plot}
    result = args_preferred_axis(PT, attr[:positions][])
    isnothing(result) && return Axis
    return result
end

function _boundingbox(positions, space::Symbol, markerspace::Symbol, scale, offset, rotation)
    if space === markerspace
        bb = Rect3d()
        for (i, p) in enumerate(positions)
            marker_pos = to_ndim(Point3d, p, 0)
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

function add_alpha(color, alpha)
    return RGBAf(Colors.color(color), alpha * Colors.alpha(color))
end

function register_colormapping!(attr::ComputeGraph)
    register_computation!(attr, [:colormap, :alpha],
                          [:alpha_colormap, :raw_colormap, :color_mapping]) do (colormap, a), changed, last
        icm = colormap[] # the raw input colormap e.g. :viridis
        raw_colormap = _to_colormap(icm)::Vector{RGBAf} # Raw colormap from ColorGradient, which isn't scaled. We need to preserve this for later steps
        if a[] < 1.0
            alpha_colormap = add_alpha.(colormap[], a[])
            raw_colormap .= add_alpha.(raw_colormap, a[])
        else
            alpha_colormap = colormap[]
        end
        color_mapping = icm isa PlotUtils.ColorGradient ? icm.values : nothing
        return (alpha_colormap, raw_colormap, color_mapping)
    end

    for key in (:lowclip, :highclip)
        sym = Symbol(:_, key)
        register_computation!(attr, [key, :colormap], [sym]) do (input, cmap), changed, _
            if input[] === automatic
                (ifelse(key == :lowclip, first(cmap[]), last(cmap[])),)
            else
                (to_color(input[]),)
            end
        end
    end

    register_computation!(attr, [:color, :colorrange], [:_colorrange]) do (color, colorrange), changed, last
        (color[] isa AbstractVector{<:Real} || color[] isa Real) || return nothing
        if colorrange[] === automatic
            (Vec2d(distinct_extrema_nan(color[])),)
        else
            (Vec2d(colorrange[]),)
        end
    end

    register_computation!(attr, [:_colorrange, :colorscale],
                          [:scaled_colorrange]) do (colorrange, colorscale), changed, last
        isnothing(colorrange[]) && return nothing
        return (Vec2f(apply_scale(colorscale[], colorrange[])),)
    end

    register_computation!(attr, [:color, :colorscale, :alpha],
                          [:scaled_color]) do (color, colorscale, alpha), changed, last

        if color[] isa Union{AbstractArray{<: Real}, Real}
            return (el32convert(apply_scale(colorscale[], color[])),)
        elseif color[] isa AbstractArray
            return (add_alpha.(color[], alpha[]),)
        else
            return (add_alpha(color[], alpha[]),)
        end
    end
end

function register_arguments!(::Type{P}, attr::ComputeGraph, user_kw, input_args...) where {P}
    # TODO expand_dims + dim_converts
    # Only 2 and 3d conversions are supported, and only
    args = map(to_value, input_args)
    PTrait = conversion_trait(P, args...)

    if all(arg -> arg isa Computed, input_args)

        inputs = map(enumerate(input_args)) do (i, arg)
            sym = Symbol(:arg, i)
            add_input!(attr, sym, arg)
            return sym
        end

    elseif !any(arg -> arg isa Computed, input_args)

        inputs = map(enumerate(args)) do (i, arg)
            sym = Symbol(:arg, i)
            add_input!(attr, sym, arg)
            if input_args[i] isa Observable
                on(input_args[i]) do arg
                    setproperty!(attr, Symbol(:arg, i), arg)
                    return
                end
            end
            return sym
        end
    else
        error("args should be either all Computed or all other things. $input_args")
    end

    register_computation!(attr, inputs, [:expanded_args]) do input_args, changed, last
        args = map(getindex, input_args)
        expanded_args = expand_dimensions(PTrait, args...)
        if isnothing(expanded_args)
            return (args,)
        else
            return (expanded_args,)
        end
    end

    converts = get!(() -> DimConversions(), user_kw, :dim_conversions)
    register_computation!(attr, [:expanded_args], [:dim_converted]) do input_args, changed, last
        args = input_args[1][]
        return (args,)
    end

    register_computation!(attr, [:dim_converted],
                          [MakieCore.argument_names(P, 10)...]) do args, changed, last
        return convert_arguments(P, args[1][]...)
    end

    add_input!(attr, :transform_func, identity)
    # Hack-fix variable type
    attr[:transform_func].value = RefValue{Any}(identity)

    add_input!(attr, :model, Mat4d(I))
    # TODO: connect to scene: on(update!(...), scene.float32convert.scaling)
    add_input!(attr, :f32c, LinearScaling(Vec3d(1.0), Vec3d(0.0)))

    # TODO:
    # - :positions may not be compatible with all primitive plot types
    #   probably need specialization, e.g. for heatmap, image, surface
    # - recipe plots may want this too for boundingbox
    if P <: PrimitivePlotTypes

        register_computation!(attr, [:positions, :transform_func, :space],
                            [:positions_transformed]) do (positions, func, space), changed, last
            return (apply_transform(func[], positions[], space[]),)
        end

        # TODO: backends should rely on model_f32c if they use :positions_transformed_f32c
        register_computation!(attr,
            [:positions_transformed, :model, :f32c],
            [:positions_transformed_f32c, :model_f32c]
        ) do (positions, model, f32c), changed, last
            # TODO: this should be done in one nice function
            # This is simplified, skipping what's commented out

            # trans, scale = decompose_translation_scale_matrix(model)
            # is_rot_free = is_translation_scale_matrix(model)
            if is_identity_transform(f32c[]) # && is_float_safe(scale, trans)
                m = changed[2] ? Mat4f(model[]) : nothing
                return (el32convert(positions[]), m)
            # elseif is_identity_transform(f32c) && !is_float_safe(scale, trans)
                # edge case: positions not float safe, model not float safe but result in float safe range
                # (this means positions -> world not float safe, but appears float safe)
            # elseif is_float_safe(scale, trans) && is_rot_free
                # fast path: can swap order of f32c and model, i.e. apply model on GPU
            # elseif is_rot_free
                # fast path: can merge model into f32c and skip applying model matrix on CPU
            else
                # TODO: avoid reallocating?
                output = Vector{Point3f}(undef, length(positions[]))
                @inbounds for i in eachindex(output)
                    p4d = to_ndim(Point4d, to_ndim(Point3d, positions[][i], 0), 1)
                    p4d = model[] * p4d
                    output[i] = f32_convert(f32c[], p4d[Vec(1, 2, 3)])
                end
                m = isnothing(last) ? Mat4f(I) : nothing
                return (output, m)
            end
        end

    end
end

function register_marker_computations!(attr::ComputeGraph)

    register_computation!(attr, [:marker, :markersize],
                          [:quad_offset, :quad_scale]) do (marker, markersize), changed, last
        atlas = get_texture_atlas()
        font = defaultfont()
        mm_changed = changed[1] || changed[2]
        quad_scale = mm_changed ? rescale_marker(atlas, marker[], font, markersize[]) : nothing
        quad_offset = offset_marker(atlas, marker[], font, markersize[])

        return (quad_offset, quad_scale)
    end
end

# TODO: this won't work because Text is both primitive and not
const PrimitivePlotTypes = Union{Scatter, Lines, LineSegments, Text, Mesh,
    MeshScatter, Heatmap, Image, Surface, Voxels, Volume}

obs_to_value(obs::Observables.AbstractObservable) = to_value(obs)
obs_to_value(x) = x

function add_attributes!(::Type{T}, attr, kwargs) where {T}
    documented_attr = MakieCore.documented_attributes(T).d
    name = plotkey(T)
    is_primitive = T <: PrimitivePlotTypes

    # Hack-fix variable types
    abstract_type_init = Dict{Symbol, RefValue}(
        :lowclip => RefValue{Union{Automatic, Colorant}}(automatic),
        :highclip => RefValue{Union{Automatic, Colorant}}(automatic),
        :colorrange => RefValue{Union{Automatic, Vec2f}}(automatic),
        :colorscale => RefValue{Any}(identity),
    )

    for (k, v) in documented_attr
        if haskey(kwargs, k)
            value = kwargs[k]
        else
            val = v.default_value
            value = val isa MakieCore.Inherit ? val.fallback : val
        end

        # primitives use convert_attributes, recipe plots don't
        if is_primitive
            add_input!(attr, k, obs_to_value(value)) do key, value
                return convert_attribute(value, Key{key}(), Key{name}())
            end
        else
            add_input!(attr, k, obs_to_value(value))
        end

        if value isa Observable
            on(value) do new_val
                old = getproperty(attr, k)[]
                if old != new_val
                    setproperty!(attr, k, new_val)
                end
            end
        end

        # Hack-fix variable type
        if haskey(abstract_type_init, k)
            attr[k].value = abstract_type_init[k]
        end
    end
end

# function gscatter end

# const GScatter{ARGS} = Scatter{gscatter, ARGS}

function add_theme!(plot::T, scene::Scene) where {T}
    plot_attr = MakieCore.documented_attributes(T).d
    scene_theme = theme(scene)
    plot_scene_theme = get(scene_theme, plotsym(plot), (;))
    gattr = plot.args[1]
    for (k, v) in plot_attr
        # attributes from user (kw), are already set
        if !haskey(plot.kw, k)
            if haskey(plot_scene_theme, k)
                setproperty!(gattr, k, to_value(plot_scene_theme[k]))
            elseif v.default_value isa MakieCore.Inherit
                default = v.default_value
                if haskey(scene_theme, default.key)
                    setproperty!(gattr, k, to_value(scene_theme[default.key]))
                elseif !isnothing(default.fallback)
                    setproperty!(gattr, k, default.fallback)
                else
                    error("No fallback + theme for $(k)")
                end
            else
                #  v.default_value  is not a Inherit, so the value should already be set
            end
        end
    end
    return
end

plot!(parent::SceneLike, plot::ComputePlots) = computed_plot!(parent, plot)

function computed_plot!(parent, plot::T) where {T}
    scene = parent_scene(parent)
    add_theme!(plot, scene)
    plot.parent = parent
    attr = plot.args[1]
    if scene.float32convert !== nothing # this is statically a Nothing or Float32Convert
        on(plot, scene.float32convert.scaling) do f32c
            println("kilo: $(attr.f32c[])")
            attr.f32c = f32c
        end
    end

    # from connect_plot!()
    t_user = to_value(get(attributes(plot), :transformation, automatic))
    if t_user isa Transformation
        plot.transformation = t_user
    else
        if t_user isa Union{Nothing, Automatic}
            plot.transformation = Transformation()
        else
            t = Transformation()
            transform!(t, t_user)
            plot.transformation = t
        end
        if is_space_compatible(plot, parent)
            obsfunc = connect!(transformation(parent), transformation(plot))
            append!(plot.deregister_callbacks, obsfunc)
        end
    end

    # TODO: Consider removing Transformation() and handling this in compute graph
    # connect updates
    on(model -> attr.model = model, plot, plot.transformation.model, update = true)
    on(tf -> update!(plot.args[1], transform_func = tf), plot, plot.transformation.transform_func, update = true)

    push!(parent, plot)
    plot!(plot)

    if !isnothing(scene) && haskey(plot.args[1], :cycle)
        add_cycle_attribute!(plot, scene, get_cycle_for_plottype(plot.args[1][:cycle][]))
    end

    documented_attr = MakieCore.documented_attributes(T).d
    for (k, v) in plot.kw
        if !haskey(plot.args[1].outputs, k)
            if haskey(documented_attr, k)
                error("User Attribute $k did not get registered.")
            else
                add_input!(plot.args[1], k, v)
            end
        end
    end

    return
end

function data_limits(plot::ComputePlots)
    return plot.args[1][:data_limits][]
end

function Base.getproperty(plot::ComputePlots, key::Symbol)
    if key in fieldnames(typeof(plot))
        return getfield(plot, key)
    end
    return plot.args[1][key]
end

function Base.setproperty!(plot::ComputePlots, key::Symbol, val)
    if key in fieldnames(typeof(plot))
        return Base.setfield!(plot, key, val)
    end
    attr = plot.args[1]
    if haskey(attr.inputs, key)
        setproperty!(attr, key, val)
    else
        add_input!(attr, key, val)
        # maybe best to not make assumptions about user attributes?
        # CairoMakie rasterize needs this (or be treated with more care)
        attr[key].value = RefValue{Any}(nothing)
    end
    return plot
end

Base.getindex(plot::ComputePlots, key::Symbol) = getproperty(plot, key)
Base.setindex!(plot::ComputePlots, val, key::Symbol) = setproperty!(plot, key, val)


Observables.to_value(computed::ComputePipeline.Computed) = computed[]


function Scatter(args::Tuple, user_kw::Dict{Symbol,Any})
    attr = ComputeGraph()
    add_attributes!(Scatter, attr, user_kw)
    register_arguments!(Scatter, attr, user_kw, args...)
    register_marker_computations!(attr)
    register_colormapping!(attr)
    register_computation!(attr, [:positions, :space, :markerspace, :quad_scale, :quad_offset, :rotation],
                          [:data_limits]) do args, changed, last
        return (_boundingbox(getindex.(args)...),)
    end
    T = typeof(attr[:positions][])
    p = Plot{scatter,Tuple{T}}(user_kw, Observable(Pair{Symbol,Any}[]), Any[attr], Observable[])
    p.transformation = Transformation()
    return p
end

function Lines(args::Tuple, user_kw::Dict{Symbol,Any})
    if !isempty(args) && first(args) isa Attributes
        attr = attributes(first(args))
        merge!(user_kw, attr)
        return Lines(Base.tail(args), user_kw)
    end
    attr = ComputeGraph()
    add_attributes!(Lines, attr, user_kw)
    register_arguments!(Lines, attr, user_kw, args...)
    register_colormapping!(attr)
    register_computation!(attr, [:positions], [:data_limits]) do (positions,), changed, last
        return (Rect3d(positions[]),)
    end
    T = typeof(attr[:positions][])
    p = Plot{lines,Tuple{T}}(user_kw, Observable(Pair{Symbol,Any}[]), Any[attr], Observable[])
    p.transformation = Transformation()
    return p
end

function LineSegments(args::Tuple, user_kw::Dict{Symbol,Any})
    if !isempty(args) && first(args) isa Attributes
        attr = attributes(first(args))
        merge!(user_kw, attr)
        return LineSegments(Base.tail(args), user_kw)
    end
    attr = ComputeGraph()
    add_attributes!(LineSegments, attr, user_kw)
    register_arguments!(LineSegments, attr, user_kw, args...)
    register_colormapping!(attr)
    register_computation!(attr, [:positions], [:data_limits]) do (positions,), changed, last
        return (Rect3d(positions[]),)
    end

    # allow color/linewidth per segment (like calculated_attributes! did)
    for (in, out) in zip([:scaled_color, :linewidth], [:synched_color, :synched_linewidth])
        register_computation!(attr, [:positions, in], [out]) do (positions, input), changed, last
            N = length(positions[])
            output = isnothing(last) ? copy(input[]) : last[1][]
            if changed[2] && (output isa AbstractVector) && (div(N, 2) == length(input[]))
                resize!(output, N)
                for i in eachindex(output) # TODO: @inbounds
                    output[i] = input[][div(i+1, 2)]
                end
            end
            return (output,)
        end
    end

    T = typeof(attr[:positions][])
    p = Plot{linesegments,Tuple{T}}(user_kw, Observable(Pair{Symbol,Any}[]), Any[attr], Observable[])
    p.transformation = Transformation()
    return p
end

function ComputePipeline.update!(plot::ComputePlots; args...)
    return ComputePipeline.update!(plot.args[1]; args...)
end

using Base: RefValue
using LinearAlgebra
using GeometryBasics

################################################################################

# Sketching usage with scatter

Base.haskey(x::Plot, key) = haskey(x.attributes, key)
Base.get(f::Function, x::Plot, key::Symbol) = haskey(x.attributes, key) ? x.attributes[key] : f()
Base.get(x::Plot, key::Symbol, default) = get(()-> default, x, key)

Base.getindex(plot::Plot, key::Symbol) = getproperty(plot, key)
Base.setindex!(plot::Plot, val, key::Symbol) = setproperty!(plot, key, val)
function Base.setindex!(plot::Plot, val, key::Int)
    sym = Symbol("arg", key)
    setindex!(plot, val, sym)
end


function data_limits(plot::Plot)
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
    kw = Dict{Symbol, Any}(Symbol(:arg, i) => arg for (i, arg) in enumerate(args))
    merge!(kw, attr)
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
    else
        add_input!(attr, key, val)
        # maybe best to not make assumptions about user attributes?
        # CairoMakie rasterize needs this (or be treated with more care)
        attr[key].value = RefValue{Any}(nothing)
    end
    return plot
end

# temp fix axis selection
args_preferred_axis(::Type{<: Voxels}, attr::ComputeGraph) = LScene
function args_preferred_axis(::Type{<: Surface}, attr::ComputeGraph)
    lims = attr[:data_limits][]
    return widths(lims)[3] == 0 ? Axis : LScene
end
function args_preferred_axis(::Type{PT}, attr::ComputeGraph) where {PT <: Plot}
    result = args_preferred_axis(PT, attr[:positions][])
    isnothing(result) && return Axis
    return result
end

# TODO: is this data_limits or boundingbox()?
function scatter_limits(positions, space::Symbol, markerspace::Symbol, scale, offset, rotation)
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

function meshscatter_data_limits(positions, marker, markersize, rotation)
    # TODO: avoid mesh generation here if possible
    marker_bb = Rect3d(marker)
    scales = markersize
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


function add_alpha(color, alpha)
    return RGBAf(Colors.color(color), alpha * Colors.alpha(color))
end

function register_colormapping!(attr::ComputeGraph, colorname=:color)
    register_computation!(attr, [:colormap, :alpha], [:alpha_colormap, :raw_colormap, :color_mapping, :color_mapping_type]) do (icm, a), changed, last
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
        register_computation!(attr, [key, :alpha_colormap], [sym]) do (input, cmap), changed, _
            if input === automatic
                return (ifelse(key == :lowclip, first(cmap), last(cmap)),)
            else
                return (to_color(input),)
            end
        end
    end

    register_computation!(
            attr,
            [colorname, :colorscale, :alpha],
            [:raw_color, :scaled_color, :fetch_pixel]
        ) do (color, colorscale, alpha), changed, last
        val = if color isa Union{AbstractArray{<: Real}, Real}
            el32convert(apply_scale(colorscale, color))
        elseif color isa AbstractPattern
            ShaderAbstractions.Sampler(add_alpha.(to_image(color), alpha), x_repeat=:repeat)
        elseif color isa ShaderAbstractions.Sampler
            color # TODO: Should we skip alpha in this case?
        elseif color isa AbstractArray
            add_alpha.(color, alpha)
        else
            add_alpha(color, alpha)
        end
        return (color, val, isnothing(last) ? color isa AbstractPattern : nothing)
    end

    # TODO: if colorscale is defined, should it act on user supplied colorrange?
    register_computation!(attr,
            [:colorrange, :colorscale, :scaled_color], [:scaled_colorrange]
        ) do (colorrange, colorscale, color), changed, last
        (color isa AbstractArray{<:Real} || color isa Real) || return (nothing,)
        if colorrange === automatic
            return (isempty(color) ? Vec2f(0, 10) : Vec2f(distinct_extrema_nan(color)),)
        else
            return (Vec2f(apply_scale(colorscale, colorrange)),)
        end
    end
end

function register_position_transforms!(attr, input_name = :positions)
    haskey(attr.outputs, input_name) || return
    register_computation!(attr, [input_name, :transform_func],
                        [:positions_transformed]) do (positions, func), changed, last
        return (apply_transform(func, positions),)
    end

    # TODO: f32c should be identity or not get applied here if space != :data
    # TODO: backends should rely on model_f32c if they use :positions_transformed_f32c
    register_computation!(attr,
        [:positions_transformed, :model, :f32c],
        [:positions_transformed_f32c, :model_f32c]
    ) do (positions, model, f32c), changed, last
        # TODO: this should be done in one nice function
        # This is simplified, skipping what's commented out

        # trans, scale = decompose_translation_scale_matrix(model)
        # is_rot_free = is_translation_scale_matrix(model)
        if is_identity_transform(f32c) # && is_float_safe(scale, trans)
            m = changed[2] ? Mat4f(model) : nothing
            pos = changed[1] ? el32convert(positions) : nothing
            return (pos, m)
        # elseif is_identity_transform(f32c) && !is_float_safe(scale, trans)
            # edge case: positions not float safe, model not float safe but result in float safe range
            # (this means positions -> world not float safe, but appears float safe)
        # elseif is_float_safe(scale, trans) && is_rot_free
            # fast path: can swap order of f32c and model, i.e. apply model on GPU
        # elseif is_rot_free
            # fast path: can merge model into f32c and skip applying model matrix on CPU
        else
            # TODO: avoid reallocating?
            output = map(positions) do point
                p4d = to_ndim(Point4d, to_ndim(Point3d, point, 0), 1)
                p4d = model * p4d
                return f32_convert(f32c, p4d[Vec(1, 2, 3)])
            end
            m = isnothing(last) ? Mat4f(I) : nothing
            return (output, m)
        end
    end
end

# Split for text compat
function register_arguments!(::Type{P}, attr::ComputeGraph, user_kw, input_args) where {P}
    inputs = _register_input_arguments!(P, attr, input_args)
    _register_expand_arguments!(P, attr, inputs)
    _register_argument_conversions!(P, attr, user_kw)
    return
end

function _register_input_arguments!(::Type{P}, attr::ComputeGraph, input_args::Tuple) where {P}
    inputs = map(enumerate(input_args)) do (i, arg)
        sym = Symbol(:arg, i)
        add_input!(attr, sym, arg)
        attr[sym].value = RefValue{Any}(arg)
        return sym
    end
    return inputs
end

function _register_expand_arguments!(::Type{P}, attr, inputs, is_merged = false) where P
    # is_merged = true means that multiple arguments are collected in one input, i.e.:
    # true:  one input where attr[input][] = (arg1, arg2, ...)
    # false: multiple inputs where map(k -> attr[k][], inputs) = [arg1, arg2, ...]
    # this is used in text
    # TODO expand_dims + dim_converts
    # Only 2 and 3d conversions are supported, and only
    PTrait = if is_merged
        @assert length(inputs) == 1
        conversion_trait(P, attr[inputs[1]][]...)
    else
        conversion_trait(P, map(k -> attr[k][], inputs)...)
    end
    # call it args for backwards compatibility (plot.args)
    register_computation!(attr, inputs, [:args]) do input_args, changed, last
        args = values(is_merged ? input_args[1] : input_args)
        args_exp = expand_dimensions(PTrait, args...)
        if isnothing(args_exp)
            # TODO, this can change types...
            # Is Ref any a good idea for this, or should
            return (Ref{Any}(args),)
        else
            return (Ref{Any}(args_exp),)
        end
    end
    return
end

# Julia 1.10 compat
function _filter(f, xs::NamedTuple)
    isempty(xs) && return xs
    return xs[filter(k -> f(xs[k]), keys(xs))]
end

function _register_argument_conversions!(::Type{P}, attr::ComputeGraph, user_kw) where {P}
    dim_converts = to_value(get!(() -> DimConversions(), user_kw, :dim_conversions))
    args = attr[:args][]
    if length(args) in (2, 3)
        inputs = Symbol[]
        for (i, arg) in enumerate(args)
            update_dim_conversion!(dim_converts, i, arg)
            obs = convert(Observable{Any}, needs_tick_update_observable(Observable{Any}(dim_converts[i])))
            converts_updated = map!(x-> dim_converts[i], Observable{Any}(), obs)
            add_input!(attr, Symbol(:dim_convert_, i), converts_updated)
            push!(inputs, Symbol(:dim_convert_, i))
        end
        register_computation!(attr, [:args, inputs...], [:dim_converted]) do (expanded, converts...), changed, last
            last_vals = isnothing(last) ? ntuple(i-> nothing, length(converts)) : last.dim_converted
            result = ntuple(length(converts)) do i
                return convert_dim_value(converts[i], attr, expanded[i], last_vals[i])
            end
            return (Ref{Any}(result),)
        end
    else
        register_computation!(attr, [:args], [:dim_converted]) do args, changed, last
            return (Ref{Any}(args.args),)
        end
    end
    #  backwards compatibility for plot.converted (and not only compatibility, but it's just convenient to have)
    conv_attributes = used_attributes(P, args...)
    for key in conv_attributes
        if !haskey(attr.inputs, key) # can be added from plot attributes
            add_input!(attr, key, pop!(user_kw, key, nothing))
        end
    end
    register_computation!(attr, Symbol[conv_attributes...], [:convert_kwargs]) do inputs, changed, last
        return (_filter(!isnothing, inputs),)
    end
    register_computation!(attr, [:dim_converted, :convert_kwargs], [:converted]) do args, changed, last
        x = convert_arguments(P, args.dim_converted...; args.convert_kwargs...)
        if x isa Tuple
            return (x,)
        elseif x isa Union{PlotSpec,AbstractVector{PlotSpec}, GridLayoutSpec}
            return ((x,),)
        else
            error("Result needs to be Tuple or SpecApi")
        end
    end
    converted = attr[:converted][]
    n_args = length(converted)
    register_computation!(attr, [:converted], [MakieCore.argument_names(P, n_args)...]) do args, changed, last
        return args.converted # destructure
    end

    add_input!((k, v) -> Ref{Any}(v), attr, :transform_func, identity)

    # TODO: Should we get rid of model as a documented attribute?
    #       (On master, it acts as an overwrite, making translate!() etc not work)
    @assert haskey(attr, :model) ":model is currently assumed to be initialized from default attributes"
    # TODO: connect to scene: on(update!(...), scene.float32convert.scaling)
    add_input!(attr, :f32c, LinearScaling(Vec3d(1.0), Vec3d(0.0)))

    return
end

function register_marker_computations!(attr::ComputeGraph)

    # TODO: allowing user supplied atlas for e.g. sprite animations would be nice...

    register_computation!(attr, [:marker, :markersize, :font],
                          [:quad_offset, :quad_scale]) do (marker, markersize, font), changed, last
        atlas = get_texture_atlas()
        quad_scale = rescale_marker(atlas, marker, font, markersize)
        quad_offset = offset_marker(atlas, marker, font, markersize)

        return (quad_offset, quad_scale)
    end
end

# TODO: this won't work because Text is both primitive and not
# TODO: Also true for mesh (see poly.jl, mesh.jl)
const PrimitivePlotTypes = Union{Scatter, Lines, LineSegments, Text, Mesh,
    MeshScatter, Image, Heatmap, Surface, Voxels, Volume}


function ComputePipeline.register_computation!(f, p::Plot, inputs::Vector{Symbol}, outputs::Vector{Symbol})
    register_computation!(f, p.attributes, inputs, outputs)
end

function default_attribute(user_attributes, (key, value))
    if haskey(user_attributes, key)
        if value isa Attributes
            return merge(value, Attributes(pairs(user_attributes[key])))
        else
            return user_attributes[key]
        end
    elseif value isa MakieCore.AttributeMetadata
        val = value.default_value
        return val isa MakieCore.Inherit ? val.fallback : val
    else
        return to_value(value)
    end
end

function add_attributes!(::Type{T}, attr, kwargs) where {T <: Plot}
    documented_attr = MakieCore.plot_attributes(nothing, T)
    name = plotkey(T)
    is_primitive = T <: PrimitivePlotTypes
    inputs = Dict((kv[1] => default_attribute(kwargs, kv) for kv in documented_attr))
    delete!(inputs, :cycle)
    _cycle = to_value(get(kwargs, :cycle) do
        MakieCore.lookup_default(T, nothing, :cycle)
    end)
    add_input!(attr, :cycle, _cycle) do key, value
        # TODO, better convert_attribute to just return nothing for the different ways of disabling cycle?
        cyc = convert_attribute(value, Key{key}(), Key{name}())
        return isempty(cyc.cycle) ? nothing : cyc
    end
    # Cycle attributes are get set to plot, and then set in connect_plot!
    add_input!(attr, :plot_position, 0)
    add_input!(attr, :palettes, nothing)
    cycle = attr.cycle[]
    if !isnothing(cycle)
        asc = attrsyms(cycle)
        ps = palettesyms(cycle)
        # flatten to attribute -> palette
        lookup = Dict([b for syms in asc for b in zip(syms, ps)])
        add_input!(attr, :palette_lookup, lookup)
        for (k, p) in lookup
            # If user explicitely passes values, we should not do anything
            let plotcycle = cycle
                add_input!(attr, k, get(kwargs, k, nothing)) do key, value
                    palettes = attr.palettes[]
                    value isa Cycled && return get_cycle_attribute(palettes, key, value.i, plotcycle)
                    if !isnothing(value)
                        return convert_attribute(value, Key{key}(), Key{name}())
                    end
                    pos = attr.plot_position[]
                    cyc = get_cycle_attribute(palettes, key, pos, plotcycle)
                    return convert_attribute(cyc, Key{key}(), Key{name}())
                end
                delete!(inputs, k)
            end
        end
    end
    for (k, v) in inputs
        # primitives use convert_attributes, recipe plots don't
        if is_primitive
            add_input!(attr, k, v) do key, value
                return convert_attribute(value, Key{key}(), Key{name}())
            end
        else
            add_input!((k,v) -> Ref{Any}(v), attr, k, v)
        end
    end
    if !haskey(attr, :model)
        add_input!(attr, :model, Mat4d(I))
    end
end

# function gscatter end

# const GScatter{ARGS} = Scatter{gscatter, ARGS}

function add_theme!(plot::T, scene::Scene) where {T}
    plot_attr = MakieCore.plot_attributes(scene, T)
    scene_theme = theme(scene)
    plot_scene_theme = get(scene_theme, plotsym(T), (;))
    gattr = plot.attributes
    for (k, v) in plot_attr
        # attributes from user (kw), are already set
        if !haskey(plot.kw, k)
            # dont set theme values for cycled attributes
            if haskey(gattr.inputs, :palette_lookup) && haskey(gattr.palette_lookup[], k)
                continue
            end
            if haskey(plot_scene_theme, k)
                setproperty!(gattr, k, to_value(plot_scene_theme[k]))
            elseif v isa Observable
                setproperty!(gattr, k, v[])
            elseif v isa Attributes
                setproperty!(gattr, k, v)
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

register_camera!(scene::Scene, plot::Plot) = register_camera!(plot.attributes, scene.compute)

function Plot{Func}(user_args::Tuple, user_attributes::Dict) where {Func}
    # Handle plot!(plot, attributes::Attributes, args...) here
    if !isempty(user_args) && first(user_args) isa Attributes
        attr = attributes(first(user_args)) # TODO: Should this copy to keep user_args[1] unchanged?
        merge!(attr, user_attributes)
        return Plot{Func}(Base.tail(user_args), user_attributes)
    end

    P = Plot{Func}

    # And also plot!(plot, ::ComputeGraph, args...)
    if !isempty(user_args) && first(user_args) isa ComputeGraph
        # shallow copy with generalized type (avoid changing graph, allow non Computed types)
        attr = Dict{Symbol, Any}(pairs(first(user_args).outputs))

        # TODO: Do we just blacklist these, because they are controlled by Transformations()?
        filter!(kv -> !in(kv[1], [:model, :transform_func]), attr)

        # remove attributes that the parent graph has but don't apply to this plot
        valid_keys = keys(MakieCore.plot_attributes(nothing, P))
        filter!(kv -> in(kv[1], valid_keys), attr)

        merge!(attr, user_attributes)
        return Plot{Func}(Base.tail(user_args), attr)
    end

    attr = ComputeGraph()
    add_attributes!(P, attr, user_attributes)
    register_arguments!(P, attr, user_attributes, user_args)
    converted = attr[:converted][]
    ArgTyp = typeof(converted)
    FinalPlotFunc = plotfunc(plottype(P, converted...))
    return Plot{FinalPlotFunc,ArgTyp}(user_attributes, attr)
end

function get_plot_position(scene::Scene, plot::Plot)
    # TODO, this may not reproduce the exact same cycle index as on master
    cycle = plot.cycle[]
    isnothing(cycle) && return 0
    syms = [s for ps in attrsyms(cycle) for s in ps]
    pos = 1
    for p in scene.plots
        p === plot && return pos
        if haskey(p, :cycle) && !isnothing(p.cycle[]) && plotfunc(p) === plotfunc(plot)
            is_cycling = any(syms) do x
                return haskey(p.attributes.inputs, x) && isnothing(p.attributes.inputs[x].value)
            end
            if  is_cycling
                pos += 1
            end
        end
    end
    # not inserted yet
    return pos
end
# For recipes we use the recipes position?
function get_plot_position(parent::Plot, ::Plot)
    get_plot_position(get_scene(parent), parent)
end

# should this just be connect_plot?
function connect_plot!(parent::SceneLike, plot::Plot{Func}) where {Func}
    scene = parent_scene(parent)
    add_theme!(plot, scene)
    plot.parent = parent
    attr = plot.attributes
    if scene.float32convert !== nothing # this is statically a Nothing or Float32Convert
        on(plot, scene.float32convert.scaling, update = true) do f32c
            attr.f32c = f32c
            return
        end
    end
    # TODO, do this for recipes?
    plot.plot_position = get_plot_position(parent, plot)
    plot.palettes = get_scene(parent).theme.palette

    handle_transformation!(plot, parent)
    if plot isa PrimitivePlotTypes
        register_camera!(scene, plot)
    end
    calculated_attributes!(Plot{Func}, plot)

    plot!(plot)


    documented_attr = MakieCore.plot_attributes(scene, Plot{Func})
    for (k, v) in plot.kw
        if !haskey(plot.attributes.outputs, k)
            if haskey(documented_attr, k)
                error("User Attribute $k did not get registered.")
            else
                add_input!(plot.attributes, k, v)
            end
        end
    end

    return
end

Observables.to_value(computed::ComputePipeline.Computed) = computed[]
Base.notify(computed::ComputePipeline.Computed) = computed


function attribute_per_pos!(attr, attribute::Symbol, output_name::Symbol)
    register_computation!(
        attr,
        [attribute, :positions],
        [output_name],
    ) do (vec, positions), changed, last
        any(changed) || return nothing
        if !(vec isa AbstractVector)
            !isnothing(last) && vec == last[1] && return nothing
            return (vec,)
        end
        NP = length(positions)
        NC = length(vec)
        NP == NC && return (vec,)
        if NP ÷ 2 == NC
            output = [vec[div(i + 1, 2)] for i in 1:NP]
            return (output,)
        end
        error("Color vector length $(NC) does not match position length $(NP)")
        return (vec,)
    end
end


# TODO: it may make sense to just remove Mesh in convert_arguments?
# TODO: this could probably be reused by meshscatter

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
    register_computation!(attr, [:mesh], [:positions, :faces, :normals, :texturecoordinates]) do (merged,), changed, cached
        pos = coordinates(merged)
        faces = decompose(GLTriangleFace, merged)
        normies = normals(merged)
        texturecoords = texturecoordinates(merged)
        return (pos, faces, normies, texturecoords)
    end

    register_computation!(attr, [:arg1, :mesh, :color], [:mesh_color, :interpolate_in_fragment_shader]) do (meshes, merged, color), changed, cached
        if hasproperty(merged, :color)
            return (merged.color, true)
        elseif meshes isa Vector{<:AbstractGeometry} && color isa Vector && length(color) == length(meshes)
            _color = color_per_mesh(color, map(x-> length(coordinates(x)), meshes))
            return (_color, false)
        else
            return (color, true)
        end
    end
end


function calculated_attributes!(::Type{Image}, plot::Plot)
    attr = plot.attributes
    calculated_attributes!(Heatmap, plot)
    register_position_transforms!(attr)
end

function calculated_attributes!(::Type{Heatmap}, plot::Plot)
    attr = plot.attributes
    register_colormapping!(attr, :image)
    register_computation!(attr, [:x, :y], [:data_limits]) do mini_maxi, changed, _
        mini = Vec3d(first.(values(mini_maxi))..., 0)
        maxi = Vec3d(last.(values(mini_maxi))..., 0)
        return (Rect3d(mini, maxi .- mini),)
    end
end

function calculated_attributes!(::Type{Surface}, plot::Plot)
    attr = plot.attributes
    register_computation!(attr, [:z, :color], [:color_with_default]) do (z, color), changed, cached
        return (isnothing(color) ? z : color,)
    end
    register_colormapping!(attr, :color_with_default)
    register_computation!(attr, [:x, :y, :z], [:data_limits]) do (x, y, z), changed, _
        xlims = extrema(x)
        ylims = extrema(y)
        zlims = extrema(z)
        mini, maxi = Vec3d.(xlims, ylims, zlims)
        return (Rect3d(mini, maxi .- mini),)
    end
end

function calculated_attributes!(::Type{Scatter}, plot::Plot)
    attr = plot.attributes
    register_marker_computations!(attr)
    register_colormapping!(attr)
    register_position_transforms!(attr)
    register_computation!(attr, [:rotation], [:converted_rotation, :billboard]) do (rotation,), changed, cached
        return (convert_attribute(rotation, key"rotation"()), rotation isa Billboard)
    end
    register_computation!(attr, [:positions, :space, :markerspace, :quad_scale, :quad_offset, :converted_rotation],
                          [:data_limits]) do args, changed, last
        return (scatter_limits(args...),)
    end

end

function calculated_attributes!(::Type{MeshScatter}, plot::Plot)
    attr = plot.attributes
    register_colormapping!(attr)
    register_position_transforms!(attr)
    register_computation!(attr, [:positions, :marker, :markersize, :rotation],
                          [:data_limits]) do args, changed, last
        return (meshscatter_data_limits(args...),)
    end
end


function calculated_attributes!(::PointBased, plot::Plot)
    attr = plot.attributes
    register_computation!(attr, [:positions], [:data_limits]) do (positions,), changed, last
        return (Rect3d(positions),)
    end
    register_position_transforms!(attr)
end


function calculated_attributes!(::Type{Lines}, plot::Plot)
    attr = plot.attributes
    register_colormapping!(attr)
    map!(identity, attr, :linewidth, :uniform_linewidth)
    calculated_attributes!(PointBased(), plot)
end

function calculated_attributes!(::Type{LineSegments}, plot::Plot)
    attr = plot.attributes
    attribute_per_pos!(attr, :color, :synched_color)
    register_colormapping!(attr, :synched_color)
    attribute_per_pos!(attr, :linewidth, :uniform_linewidth)
    calculated_attributes!(PointBased(), plot)
end

function calculated_attributes!(::Type{Mesh}, plot::Plot)
    attr = plot.attributes
    register_mesh_decomposition!(attr)
    register_colormapping!(attr, :mesh_color)
    calculated_attributes!(PointBased(), plot)
end

function calculated_attributes!(::Type{Volume}, plot::Plot)
    attr = plot.attributes
    register_position_transforms!(attr) # TODO: isn't this skipped
    register_colormapping!(attr, :volume)
    register_computation!(attr, [:x, :y, :z], [:data_limits]) do (x, y, z), changed, last
        mini, maxi = Vec3.(x, y, z)
        return (Rect3d(mini, maxi .- mini),)
    end
end


get_colormapping(plot::Plot) = get_colormapping(plot, plot.attributes)
function get_colormapping(plot, attr::ComputePipeline.ComputeGraph)
    isnothing(attr[:scaled_colorrange][]) && return nothing
    haskey(attr, :cb_colormapping) && return attr[:cb_colormapping][]

    map!(attr, [:colorrange, :raw_color], :unscaled_colorrange) do colorrange, color
        if colorrange === automatic
            return isempty(color) ? Vec2f(0, 10) : Vec2f(distinct_extrema_nan(color))
        else
            return Vec2f(colorrange)
        end
    end

    attributes = [
        :raw_color, :alpha_colormap, :raw_colormap, :colorscale, :color_mapping, :unscaled_colorrange,
        :lowclip, :highclip, :nan_color, :color_mapping_type, :scaled_colorrange, :scaled_color]
    register_computation!(attr, attributes, [:cb_colormapping, :cb_observables]) do args, changed, cached
        dict = Dict(zip(attributes, values(args)))
        N = ndims(dict[:raw_color])
        Cin = typeof(dict[:raw_color])
        Cout = typeof(dict[:scaled_color])
        if isnothing(cached)
            observables = map(attributes) do name
                name === :colorscale ? Observable{Any}(dict[name]) : Observable(dict[name])
            end
            observable_dict = Dict(zip(attributes, observables))
            cm = ColorMapping{N,Cin,Cout}(observables...)
            return (cm, observable_dict)
        else
            observable_dict = cached.cb_observables
            for (name, value, ischanged) in zip(attributes, args, changed)
                if ischanged
                    observable_dict[name][] = value
                end
            end
            return (cached.cb_colormapping, nothing)
        end
    end
    on(plot, attr.onchange) do _
        attr[:cb_colormapping][]
    end
    return attr[:cb_colormapping][]
end

# This one plays nice with out system, only needs model
function register_world_normalmatrix!(attr, modelname = :model_f32c)
    register_computation!(attr, [modelname], [:world_normalmatrix]) do (m,), _, __
        return (Mat3f(transpose(inv(m[Vec(1,2,3), Vec(1,2,3)]))), )
    end
end

# This one does not, requires the who-knows-when-it-updates view matrix...
function add_view_normalmatrix!(data, attr, modelname = :model_f32c)
    model = Observable(Mat3f)
    register_computation!(attr, [modelname], Symbol[]) do (model,), _, __
        model[] = model[Vec(1,2,3), Vec(1,2,3)]
        return nothing
    end
    data[:view_normalmatrix] = map(data[:view], model) do v, m
        return Mat3f(transpose(inv(v[Vec(1,2,3), Vec(1,2,3)] * m)))
    end
end

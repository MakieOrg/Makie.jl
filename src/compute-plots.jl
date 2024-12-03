using Base: RefValue
using LinearAlgebra
using GeometryBasics
using ComputePipeline

################################################################################

# Sketching usage with scatter

const ComputePlots = Union{Scatter, Lines, LineSegments}

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
        icm = attr.colormap[] # the raw input colormap e.g. :viridis
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
end

function register_arguments!(::Type{P}, attr::ComputeGraph, user_kw, input_args...) where {P}
    # TODO expand_dims + dim_converts
    # Only 2 and 3d conversions are supported, and only
    args = map(to_value, input_args)
    PTrait = conversion_trait(P, args...)
    inputs = map(enumerate(args)) do (i, arg)
        sym = Symbol(:arg, i)
        add_input!(attr, sym, arg)
        return sym
    end
    onany(input_args...) do args...
        kw = [Symbol(:arg, i) => args[i] for i in 1:length(args)]
        update!(attr; kw...)
        return
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
    register_computation!(attr, [:positions, :transform_func, :space],
                          [:positions_transformed]) do (positions, func, space), changed, last
        return (apply_transform(func[], positions[], space[]),)
    end
    add_input!(attr, :f32c, nothing)

    register_computation!(attr, [:positions_transformed, :f32c],
                          [:positions_transformed_f32c]) do (positions, f32c), changed, last
        return (inv_f32_convert(f32c[], positions[]),)
    end
end

function register_marker_computations!(attr::ComputeGraph)
    # Special case: calculated_attributes - marker_offset
    register_computation!(attr, [:marker_offset, :markersize],
                          [:_marker_offset]) do (offset, size), changed, last
        if offset[] isa Automatic
            (to_2d_scale(map(x -> x .* -0.5f0, size[])),)
        else
            (to_2d_scale(offset[]),)
        end
    end

    register_computation!(attr, [:marker, :markersize, :_marker_offset],
                          [:quad_offset, :quad_scale]) do (marker, markersize, marker_offset), changed, last
        atlas = get_texture_atlas()
        font = defaultfont()
        mm_changed = changed[1] || changed[2]
        quad_scale = mm_changed ? rescale_marker(atlas, marker[], font, markersize[]) : nothing
        quad_offset = offset_marker(atlas, marker[], font, markersize[], marker_offset[])

        return (quad_offset, quad_scale)
    end
end

function add_attibutes!(::Type{T}, attr, kwargs) where {T}
    documented_attr = MakieCore.documented_attributes(T).d
    for (k, v) in documented_attr
        if haskey(kwargs, k)
            value = kwargs[k]
        else
            val = v.default_value
            value = val isa MakieCore.Inherit ? val.fallback : val
        end
        add_input!(attr, k, to_value(value)) do key, value
            return convert_attribute(value, Key{key}(), Key{:scatter}())
        end
        if value isa Observable
            on(value) do new_val
                setproperty!(attr, k, new_val)
            end
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

function plot!(scene::Scene, plot::ComputePlots)
    add_theme!(plot, scene)
    plot.parent = scene
    push!(scene.plots, plot)
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

Observables.to_value(computed::ComputePipeline.Computed) = computed[]


function Scatter(args::Tuple, user_kw::Dict{Symbol,Any})
    attr = ComputeGraph()
    add_attibutes!(Scatter, attr, user_kw)
    register_arguments!(Scatter, attr, user_kw, args...)
    register_marker_computations!(attr)
    register_colormapping!(attr)
    register_computation!(attr, [:positions, :space, :markerspace, :quad_scale, :quad_offset, :rotation],
                          [:data_limits]) do args, changed, last
        return (_boundingbox(getindex.(args)...),)
    end
    T = typeof(attr[:positions][])
    p = Plot{scatter,Tuple{T}}(user_kw, Observable(Pair{Symbol,Any}[]), Any[attr], Observable[])
    add_input!(attr, :model, Mat4f(I))
    add_input!(attr, :clip_planes, Plane3f[])
    p.transformation = Transformation()
    return p
end

function Lines(args::Tuple, user_kw::Dict{Symbol,Any})
    attr = ComputeGraph()
    add_attibutes!(Lines, attr, user_kw)
    register_arguments!(Lines, attr, user_kw, args...)
    register_colormapping!(attr)
    register_computation!(attr, [:positions], [:data_limits]) do (positions,), changed, last
        return (Rect3d(positions[]),)
    end
    T = typeof(attr[:positions][])
    p = Plot{lines,Tuple{T}}(user_kw, Observable(Pair{Symbol,Any}[]), Any[attr], Observable[])
    add_input!(attr, :model, Mat4f(I))
    add_input!(attr, :clip_planes, Plane3f[])
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
    add_attibutes!(LineSegments, attr, user_kw)
    register_arguments!(LineSegments, attr, user_kw, args...)
    register_colormapping!(attr)
    register_computation!(attr, [:positions], [:data_limits]) do (positions,), changed, last
        return (Rect3d(positions[]),)
    end
    T = typeof(attr[:positions][])
    p = Plot{linesegments,Tuple{T}}(user_kw, Observable(Pair{Symbol,Any}[]), Any[attr], Observable[])
    add_input!(attr, :model, Mat4f(I))
    add_input!(attr, :clip_planes, Plane3f[])
    p.transformation = Transformation()
    return p
end

function ComputePipeline.update!(plot::ComputePlots; args...)
    return ComputePipeline.update!(plot.args[1]; args...)
end

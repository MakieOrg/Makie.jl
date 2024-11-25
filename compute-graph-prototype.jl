using GLMakie
using GLMakie: gl_texture_atlas
using Makie: defaultfont, Mat4f
using LinearAlgebra
using Makie
using Makie: automatic, Automatic, Key
using Makie: convert_attribute
using Makie: PlotUtils, Colors, Colorant
using Makie: to_2d_scale, to_color, colormapping_type, to_colormap, _to_colormap,
    distinct_extrema_nan, apply_scale, convert_attribute, update_boundingbox, to_ndim, sv_getindex
using Base: RefValue
using LinearAlgebra
using GeometryBasics
using ComputePipeline

################################################################################

# Sketching usage with scatter

function _boundingbox(positions, space::Symbol, markerspace::Symbol, scale, offset, rotation)
    if space === markerspace
        bb = Rect3d()
        for (i, p) in enumerate(positions)
            marker_pos = to_ndim(Point3d, p, 0)
            quad_origin = to_ndim(Vec3d, sv_getindex(offset[], i), 0)
            quad_size = Vec2d(sv_getindex(scale[], i))
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
    register_computation!(attr, [:colormap, :alpha], [:alpha_colormap, :raw_colormap, :color_mapping]) do (colormap, a), changed, last
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
        sym = Symbol("_$key")
        register_computation!(attr, [key, :colormap], [sym]) do (input, cmap), changed, _
            if input[] === Makie.automatic
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
    register_computation!(attr, [:_colorrange, :colorscale], [:scaled_colorrange]) do (colorrange, colorscale), changed, last
        isnothing(colorrange[]) && return nothing
        (Vec2f(apply_scale(colorscale[], colorrange[])),)
    end
end

function register_arguments!(::Type{P}, attr::ComputeGraph, user_kw, input_args...) where P
    # TODO expand_dims + dim_converts
    # Only 2 and 3d conversions are supported, and only
    args = map(to_value, input_args)
    PTrait = Makie.conversion_trait(P, args...)
    inputs = map(enumerate(args)) do (i, arg)
        sym = Symbol(:arg, i)
        add_input!(attr, sym, arg)
        return sym
    end
    register_computation!(attr, inputs, [:expanded_args]) do input_args, changed, last
        args = map(getindex, input_args)
        expanded_args = Makie.expand_dimensions(PTrait, args...)
        if isnothing(expanded_args)
            return (args,)
        else
            return (expanded_args,)
        end
    end

    converts = get!(() -> Makie.DimConversions(), user_kw, :dim_conversions)
    register_computation!(attr, [:expanded_args], [:dim_converted]) do input_args, changed, last
        args = input_args[1][]
        if (length(args) in (2, 3))
            converted = ntuple(length(args)) do i
                arg = args[i]
                # We only convert if we have a conversion struct (which isn't NoDimConversion),
                # or if we we should dim_convert
                if !isnothing(converts[i]) || Makie.should_dim_convert(P, arg) || Makie.should_dim_convert(PTrait, arg)
                    return Makie.convert_dim_observable(converts, i, arg)
                end
                return arg
            end
            return (converted,)
        else
            return (args,)
        end
    end


    register_computation!(attr, [:dim_converted], [Makie.MakieCore.argument_names(P, 10)...]) do args, changed, last
        return Makie.convert_arguments(P, args[1][]...)
    end
    add_input!(attr, :transform_func, identity)
    register_computation!(attr, [:positions, :transform_func, :space], [:positions_transformed]) do (positions, func, space), changed, last
        return (Makie.apply_transform(func[], positions[], space[]),)
    end
    add_input!(attr, :f32c, nothing)

    register_computation!(attr, [:positions_transformed, :f32c], [:positions_transformed_f32c]) do (positions, f32c), changed, last
        return (Makie.inv_f32_convert(f32c[], positions[]),)
    end
end


function register_marker_computations!(attr::ComputeGraph)
    # Special case: calculated_attributes - marker_offset
    register_computation!(attr, [:marker_offset, :markersize], [:_marker_offset]) do (offset, size), changed, last
        if offset[] isa Automatic
            (to_2d_scale(map(x -> x .* -0.5f0, size[])),)
        else
            (to_2d_scale(offset[]),)
        end
    end

    register_computation!(attr, [:marker, :markersize, :_marker_offset], [:quad_offset, :quad_scale]) do (marker, markersize, marker_offset), changed, last
        atlas = gl_texture_atlas()
        font = defaultfont()
        changed = changed[1] || changed[2]
        quad_scale = changed ? Makie.rescale_marker(atlas, marker[], font, markersize[]) : nothing
        quad_offset = Makie.offset_marker(atlas, marker[], font, markersize[], marker_offset[])
        return (quad_offset, quad_scale)
    end
end


function add_attibutes!(::Type{T}, attr, kwargs) where T
    documented_attr = Makie.MakieCore.documented_attributes(T).d
    for (k, v) in documented_attr
        if haskey(kwargs, k)
            value = kwargs[k]
        else
            val = v.default_value
            value = val isa Makie.MakieCore.Inherit ? val.fallback : val
        end
        add_input!(attr, k, value) do key, value
            convert_attribute(value, Makie.Key{key}(), Makie.Key{:scatter}())
        end
    end
end

# function gscatter end

# const GScatter{ARGS} = Makie.Scatter{gscatter, ARGS}

function add_theme!(plot::T, scene::Scene) where T
    plot_attr = Makie.MakieCore.documented_attributes(T).d
    scene_theme = theme(scene)
    plot_scene_theme = get(scene_theme, Makie.plotsym(plot), (;))
    gattr = plot.args[1]
    for (k, v) in plot_attr
        # attributes from user (kw), are already set
        if !haskey(plot.kw, k)
            if haskey(plot_scene_theme, k)
                setproperty!(gattr, k, to_value(plot_scene_theme[k]))
            elseif v.default_value isa Makie.MakieCore.Inherit
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

function cscatter end
const CScatter{ARGS} = Plot{cscatter, ARGS}

Makie.MakieCore.documented_attributes(::Type{<:CScatter}) = Makie.MakieCore.documented_attributes(Scatter)

function cscatter(args...; kw...)
    return Makie.MakieCore._create_plot(cscatter, Dict{Symbol, Any}(kw), args...)
end

function cscatter!(args...; kw...)
    return Makie.MakieCore._create_plot!(cscatter, Dict{Symbol,Any}(kw), args...)
end

function Makie.plot!(scene::Scene, plot::CScatter)
    add_theme!(plot, scene)
    plot.parent = scene
    push!(scene.plots, plot)
    return
end

function Makie.data_limits(plot::CScatter)
    return plot.args[1][:data_limits][]
end

function CScatter(args::Tuple, user_kw::Dict{Symbol,Any})
    attr = ComputeGraph()
    add_attibutes!(Scatter, attr, user_kw)
    register_arguments!(Scatter, attr, user_kw, args...)
    register_marker_computations!(attr)
    register_colormapping!(attr)
    register_computation!(attr, [:positions, :space, :markerspace, :quad_scale, :quad_offset, :rotation], [:data_limits]) do args, changed, last
        return (_boundingbox(getindex.(args)...),)
    end
    T = typeof(attr[:positions][])
    p = Plot{cscatter,Tuple{T}}(user_kw, Observable(Pair{Symbol,Any}[]), Any[attr], Observable[])
    p.attributes[:model] = Observable{Mat4f}(Mat4f(I))
    p.attributes[:clip_planes] = Makie.Plane3f[]
    p.transformation = Makie.Transformation()
    return p
end

function assemble_scatter_robj(scene, screen, positions, colormap, color, colornorm, scale, transparency)
    cam = scene[].camera
    needs_mapping = !(colornorm[] isa Nothing)
    data = Dict(
        :vertex => positions[],
        :color_map => needs_mapping ? colormap[] : nothing,
        :color => color[],
        :color_norm => colornorm[],
        :scale => scale[],
        :transparency => transparency[],
        :resolution => cam.resolution,
        :projection => Mat4f(cam.projection[]),
        :projectionview => Mat4f(cam.projectionview[]),
        :view => Mat4f(cam.view[]),
        :model => Mat4f(I),
        :markerspace => Cint(0),
        :px_per_unit => screen[].px_per_unit,
        :upvector => Vec3f(0),
        :ssao => false,
    )
    return GLMakie.draw_pixel_scatter(screen[], positions[], data)
end

function GLMakie.draw_atomic(screen::GLMakie.Screen, scene::Scene, plot::CScatter)
    screen_name = Symbol(string(objectid(screen)))
    attr = plot.args[1]
    # We register the screen under a unique name. If the screen closes
    # Any computation that depens on screen gets removed

    register_computation!(attr, Symbol[], [screen_name]) do args, changed, last
        (screen,)
    end
    scene_name = Symbol(string(objectid(scene)))
    register_computation!(attr, Symbol[], [scene_name]) do args, changed, last
        (scene,)
    end
    inputs = [scene_name, screen_name, :positions_transformed_f32c, :colormap, :color, :_colorrange,
              :markersize, :transparency]
    gl_names = [:vertex, :color_map, :color, :color_norm, :scale, :transparency]
    register_computation!(attr, inputs, [:gl_renderobject]) do args, changed, last
        screen = args[2][]
        !isopen(screen) && return :deregister
        robj = if isnothing(last)
            robj = assemble_scatter_robj(args...)
        else
            robj = last[1][]
            for (name, arg, has_changed) in zip(gl_names, args[3:end], changed[3:end])
                if has_changed
                    if haskey(robj.uniforms, name)
                        robj.uniforms[name] = arg[]
                    elseif haskey(robj.vertexarray.buffers, string(name))
                        GLMakie.update!(robj.vertexarray.buffers[string(name)], arg[])
                    end
                end
            end
            robj
        end
        screen.requires_update = true
        return (robj,)
    end
    robj = attr[:gl_renderobject][]
    screen.cache2plot[robj.id] = plot

    push!(screen, scene, robj)
    return robj
end

begin
    cscatter(-1:0.1:1, -1:0.1:1)
end


# update!(attr; arg1=-1:0.1:1, arg2=-1:0.1:1, color=1:0.1:1, markersize=22);


# function test()
#     for i in 1:10000
#         update!(attr; arg2=sin.((-1:0.1:1)), markersize=10);
#         attr.outputs[:gl_renderobject][]
#     end
#     return
# end
# using BenchmarkTools
# update!(attr; arg2=sin.((-1:0.1:1)), markersize=10);
# @btime attr.outputs[:gl_renderobject][]


# x = attr.outputs[:gl_renderobject].parent

## Bechmark
# Unoptimized Graph
#8.100 μs (87 allocations: 3.55 KiB)
# Makie
#6.600 μs (79 allocations: 3.38 KiB)
# Optimzed Graph:
#2.678 μs (23 allocations: 1.34 KiB)


# attr = ComputeGraph() do key, value
#     return value
# end

# # Adding inputs - default_theme effectively does this
# add_inputs!(attr, attr1=1, attr2=3, attr3=5)

# register_computation!(attr, [:attr1, :attr2, :attr3], [:a1changed, :a2changed, :a3changed]) do args, last
#     return map(x-> x.has_changed, args)
# end

# register_computation!(attr, [:a1changed, :a2changed, :a3changed], [:out]) do args, last
#     return (map(x -> x[], args),)
# end


# attr.outputs[:out][]

# update!(attr; attr1=2, attr2=4)

# attr.outputs[:a3changed].parent.outputs_dirty

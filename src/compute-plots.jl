using Base: RefValue
using LinearAlgebra
using GeometryBasics
using ComputePipeline

################################################################################

# Sketching usage with scatter

const ComputePlots = Union{Scatter, Lines, LineSegments, Image, Heatmap, Mesh, Surface, Voxels, Volume, MeshScatter}

Base.get(f::Function, x::ComputePlots, key::Symbol) = haskey(x.args[1], key) ? x.args[1][key] : f()
Base.get(x::ComputePlots, key::Symbol, default) = get(()-> default, x, key)

Base.getindex(plot::ComputePlots, key::Symbol) = getproperty(plot, key)
Base.setindex!(plot::ComputePlots, val, key::Symbol) = setproperty!(plot, key, val)

Base.getindex(plot::ComputePlots, idx::Integer) = plot.args[1][MakieCore.argument_names(typeof(plot), 10)[idx]]

function Base.getindex(plot::ComputePlots, idx::UnitRange{<:Integer})
    return ntuple(i -> plot.converted[Symbol(:arg, i)], idx)
end
plot!(parent::SceneLike, plot::ComputePlots) = computed_plot!(parent, plot)
data_limits(plot::ComputePlots) = plot[:data_limits][]

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
        if attr[key][] != val
            setproperty!(attr, key, val)
        end
    else
        add_input!(attr, key, val)

        # maybe best to not make assumptions about user attributes?
        # CairoMakie rasterize needs this (or be treated with more care)
        attr[key].value = RefValue{Any}(nothing)
    end
    return plot
end

# temp fix axis selection
args_preferred_axis(::Type{<: Surface}, attr::ComputeGraph) = LScene
args_preferred_axis(::Type{<: Voxels}, attr::ComputeGraph) = LScene
function args_preferred_axis(::Type{PT}, attr::ComputeGraph) where {PT <: Plot}
    result = args_preferred_axis(PT, attr[:positions][])
    isnothing(result) && return Axis
    return result
end

# TODO: is this data_limits or boundingbox()?
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

function _meshscatter_data_limits(positions, marker, markersize, rotation)
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

    register_computation!(
        attr, [colorname, :colorrange], [:_colorrange]
    ) do (color, colorrange), changed, last
        (color[] isa AbstractArray{<:Real} || color[] isa Real) || return nothing
        crange = if colorrange[] === automatic
            Vec2d(distinct_extrema_nan(color[]))
        else
            Vec2d(colorrange[])
        end
        if !isnothing(last) && last[1][] == crange
            return nothing
        else
            return (crange,)
        end
    end

    register_computation!(attr, [:_colorrange, :colorscale],
                          [:scaled_colorrange]) do (colorrange, colorscale), changed, last
        isnothing(colorrange[]) && return nothing
        return (Vec2f(apply_scale(colorscale[], colorrange[])),)
    end

    register_computation!(
        attr,
        [colorname, :colorscale, :alpha],
                          [:scaled_color]) do (color, colorscale, alpha), changed, last
        all(changed) || return nothing

        val = if color[] isa Union{AbstractArray{<: Real}, Real}
            el32convert(apply_scale(colorscale[], color[]))
        elseif color[] isa AbstractArray
            add_alpha.(color[], alpha[])
        else
            add_alpha(color[], alpha[])
        end
        if !isnothing(last) && last[1][] == val
            return nothing
        else
            return (val,)
        end
    end
end

function register_position_transforms!(attr)
    haskey(attr.outputs, :positions) || return
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
            pos = changed[1] ? el32convert(positions[]) : nothing
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


function register_arguments!(::Type{P}, attr::ComputeGraph, user_kw, input_args...) where {P}
    # TODO expand_dims + dim_converts
    # Only 2 and 3d conversions are supported, and only
    PTrait = conversion_trait(P, map(to_value, input_args)...)

    if all(arg -> arg isa Computed, input_args)

        inputs = map(enumerate(input_args)) do (i, arg)
            sym = Symbol(:arg, i)
            add_input!(attr, sym, arg)
            return sym
        end

    elseif !any(arg -> arg isa Computed, input_args)

        inputs = map(enumerate(input_args)) do (i, arg)
            sym = Symbol(:arg, i)
            add_input!(attr, sym, arg)
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
        new_args = convert_arguments(P, args[1][]...)
        return new_args
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
        register_position_transforms!(attr)
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
# TODO: Also true for mesh (see poly.jl, mesh.jl)
const PrimitivePlotTypes = Union{Scatter, Lines, LineSegments, Text, Mesh,
    MeshScatter, Image, Heatmap, Surface, Voxels, Volume}

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
            add_input!(attr, k, value) do key, value
                return convert_attribute(value, Key{key}(), Key{name}())
            end
        else
            add_input!(attr, k, value)
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

resolve_shading_default!(scene::Scene, attr::ComputeGraph) = resolve_shading_default!(attr, scene.lights)
function resolve_shading_default!(attr::ComputeGraph, lights::Vector{<: AbstractLight})
    haskey(attr, :shading) || return

    # shading is a compile time adjustment so it doesn't make sense to add
    # dynamic comoputations for it. Instead we just replace the initial value

    # Bad type
    # TODO: This is hacky - we don't want to resolve shading and pin it to a potentially bad type
    shading = attr.inputs[:shading].value
    if !(shading isa MakieCore.ShadingAlgorithm || shading === automatic)
        prev = shading
        if (shading isa Bool) && (shading == false)
            shading = NoShading
        else
            shading = automatic
        end
        @warn "`shading = $prev` is not valid. Use `Makie.automatic`, `NoShading`, `FastShading` or `MultiLightShading`. Defaulting to `$shading`."
    end

    # automatic conversion
    if shading === automatic
        ambient_count = 0
        dir_light_count = 0

        for light in lights
            if light isa AmbientLight
                ambient_count += 1
            elseif light isa DirectionalLight
                dir_light_count += 1
            elseif light isa EnvironmentLight
                continue
            else
                update!(attr, shading = MultiLightShading)
                return
            end
            if ambient_count > 1 || dir_light_count > 1
                update!(attr, shading = MultiLightShading)
                return
            end
        end

        if dir_light_count + ambient_count == 0
            shading = NoShading
        else
            shading = FastShading
        end
    end

    update!(attr, shading = shading)

    return
end

function computed_plot!(parent, plot::T) where {T}
    scene = parent_scene(parent)
    add_theme!(plot, scene)
    plot.parent = parent
    attr = plot.args[1]
    if scene.float32convert !== nothing # this is statically a Nothing or Float32Convert
        on(plot, scene.float32convert.scaling) do f32c
            attr.f32c = f32c
        end
    end

    # from connect_plot!()
    t_user = to_value(get(attributes(plot), :transformation, automatic))
    if t_user isa Automatic
        t_user = to_value(get(plot.kw, :transformation, t_user))
    end
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
    on(tf -> update!(attr; transform_func=tf), plot, plot.transformation.transform_func; update=true)

    resolve_shading_default!(scene, plot.args[1])

    push!(parent, plot)
    plot!(plot)

    if !isnothing(scene) && haskey(attr, :cycle)
        add_cycle_attribute!(plot, scene, get_cycle_for_plottype(attr[:cycle][]))
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

Observables.to_value(computed::ComputePipeline.Computed) = computed[]
Base.notify(computed::ComputePipeline.Computed) = computed


function compute_plot(::Type{Image}, args::Tuple, user_kw::Dict{Symbol,Any})
    attr = ComputeGraph()
    add_attributes!(Image, attr, user_kw)
    register_arguments!(Image, attr, user_kw, args...)
    register_computation!(attr, [:x, :y], [:positions]) do (x, y), changed, cached
        x0, x1 = x[]
        y0, y1 = y[]
        return (decompose(Point2d, Rect2d(x0, y0, x1-x0, y1-y0)),)
    end
    register_position_transforms!(attr)

    register_colormapping!(attr, :image)
    register_computation!(
        attr,
        [:x, :y],
        [:data_limits],
    ) do args, changed, _
        mini_maxi = args[1][], args[2][]
        mini = Vec3d(first.(mini_maxi)..., 0)
        maxi = Vec3d(last.(mini_maxi)..., 0)
        return (Rect3d(mini, maxi .- mini),)
    end
    T = typeof((attr[:x][], attr[:y][], attr[:image][]))
    p = Plot{image,Tuple{T}}(user_kw, Observable(Pair{Symbol,Any}[]), Any[attr], Observable[])
    p.transformation = Transformation()
    return p
end

function compute_plot(::Type{Heatmap}, args::Tuple, user_kw::Dict{Symbol,Any})
    attr = ComputeGraph()
    add_attributes!(Heatmap, attr, user_kw)
    register_arguments!(Heatmap, attr, user_kw, args...)
    register_colormapping!(attr, :image)
    register_computation!(attr, [:x, :y], [:data_limits]) do args, changed, _
        mini_maxi = args[1][], args[2][]
        mini = Vec3d(first.(mini_maxi)..., 0)
        maxi = Vec3d(last.(mini_maxi)..., 0)
        return (Rect3d(mini, maxi .- mini),)
    end
    T = typeof((attr[:x][], attr[:y][], attr[:image][]))
    p = Plot{heatmap,Tuple{T}}(user_kw, Observable(Pair{Symbol,Any}[]), Any[attr], Observable[])
    p.transformation = Transformation()
    return p
end

function compute_plot(::Type{Surface}, args::Tuple, user_kw::Dict{Symbol,Any})
    attr = ComputeGraph()
    add_attributes!(Surface, attr, user_kw)
    register_arguments!(Surface, attr, user_kw, args...)
    register_computation!(attr, [:z, :color], [:color_with_default]) do (z, color), changed, cached
        return (isnothing(color[]) ? z[] : color[],)
    end
    register_colormapping!(attr, :color_with_default)
    register_computation!(attr, [:x, :y, :z], [:data_limits]) do (x, y, z), changed, _
        xlims = extrema(x)
        ylims = extrema(y)
        zlims = extrema(z)
        return (Rect3d(Vec3d.(xlims, ylims, zlims)...),)
    end
    T = typeof((attr[:x][], attr[:y][], attr[:z][]))
    p = Plot{surface,Tuple{T}}(user_kw, Observable(Pair{Symbol,Any}[]), Any[attr], Observable[])
    p.transformation = Transformation()
    return p
end

function compute_plot(::Type{Scatter}, args::Tuple, user_kw::Dict{Symbol,Any})
    attr = ComputeGraph()
    add_attributes!(Scatter, attr, user_kw)
    register_arguments!(Scatter, attr, user_kw, args...)
    register_marker_computations!(attr)
    register_colormapping!(attr)
    register_computation!(attr, [:positions, :space, :markerspace, :quad_scale, :quad_offset, :rotation],
                          [:data_limits]) do args, changed, last
        return (_boundingbox(map(getindex, args)...),)
    end
    T = typeof(attr[:positions][])
    p = Plot{scatter,Tuple{T}}(user_kw, Observable(Pair{Symbol,Any}[]), Any[attr], Observable[])
    p.transformation = Transformation()
    return p
end

function compute_plot(::Type{MeshScatter}, args::Tuple, user_kw::Dict{Symbol,Any})
    attr = ComputeGraph()
    add_attributes!(MeshScatter, attr, user_kw)
    register_arguments!(MeshScatter, attr, user_kw, args...)
    register_marker_computations!(attr)
    register_colormapping!(attr)
    register_computation!(attr, [:positions, :marker, :markersize, :rotation],
                          [:data_limits]) do args, changed, last
        return (_meshscatter_data_limits(map(getindex, args)...),)
    end
    T = typeof(attr[:positions][])
    p = Plot{meshscatter,Tuple{T}}(user_kw, Observable(Pair{Symbol,Any}[]), Any[attr], Observable[])
    p.transformation = Transformation()
    return p
end

function attribute_per_pos!(attr, attribute::Symbol, output_name::Symbol)
    register_computation!(
        attr,
        [attribute, :positions],
        [output_name],
    ) do (vec, positions), changed, last
        all(changed) || return nothing
        if !(vec[] isa AbstractVector)
            !isnothing(last) && vec[] == last[1][] && return nothing
            return (vec[],)
        end
        NP = length(positions[])
        NC = length(vec[])
        NP == NC && return (vec[],)
        if NP ÷ 2 == NC
            output = [vec[][div(i + 1, 2)] for i in 1:NP]
            return (output,)
        end
        error("Color vector length $(NC) does not match position length $(NP)")
        return (vec[],)
    end
end

function compute_plot(::Type{Lines}, args::Tuple, user_kw::Dict{Symbol,Any})
    attr = ComputeGraph()
    add_attributes!(Lines, attr, user_kw)
    register_arguments!(Lines, attr, user_kw, args...)
    register_colormapping!(attr)
    attribute_per_pos!(attr, :scaled_color, :synched_color)
    attribute_per_pos!(attr, :linewidth, :synched_linewidth)
    register_computation!(attr, [:positions], [:data_limits]) do (positions,), changed, last
        return (Rect3d(positions[]),)
    end
    T = typeof(attr[:positions][])
    p = Plot{lines,Tuple{T}}(user_kw, Observable(Pair{Symbol,Any}[]), Any[attr], Observable[])
    p.transformation = Transformation()
    return p
end

function compute_plot(::Type{LineSegments}, args::Tuple, user_kw::Dict{Symbol,Any})
    attr = ComputeGraph()
    add_attributes!(LineSegments, attr, user_kw)
    register_arguments!(LineSegments, attr, user_kw, args...)
    register_colormapping!(attr)
    attribute_per_pos!(attr, :scaled_color, :synched_color)
    attribute_per_pos!(attr, :linewidth, :synched_linewidth)
    register_computation!(attr, [:positions], [:data_limits]) do (positions,), changed, last
        return (Rect3d(positions[]),)
    end

    T = typeof(attr[:positions][])
    p = Plot{linesegments,Tuple{T}}(user_kw, Observable(Pair{Symbol,Any}[]), Any[attr], Observable[])
    p.transformation = Transformation()
    return p
end

# TODO: it may make sense to just remove Mesh in convert_arguments?
# TODO: this could probably be reused by meshscatter
function register_mesh_decomposition!(attr)
    register_computation!(attr, [:mesh], [:positions, :faces]) do (mesh,), changed, cached
        if mesh[] isa Vector
            @info "TODO: Vector{Mesh}"
            return (coordinates(mesh[][1]), decompose(GLTriangleFace, mesh[][1]))
        else
            return (coordinates(mesh[]), decompose(GLTriangleFace, mesh[]))
        end
    end

    # texturecoordinates, normals return nothing when no data is present and
    # reflect types in mesh. May need further conversions

    # TODO: if we're throwing away normals when they are not used we should throw away uvs too...
    register_computation!(attr, [:mesh], [:texturecoordinates]) do (mesh,), changed, cached
        if mesh[] isa Vector
            return (texturecoordinates(mesh[][1]),)
        else
            return (texturecoordinates(mesh[]),) # will be nothing if none exist
        end
    end

    register_computation!(attr, [:mesh, :matcap, :shading], [:normals]) do (mesh, matcap, shading), changed, cached
        if shading[] != NoShading || matcap !== nothing
            if mesh[] isa Vector
                return (normals(mesh[][1]),)
            else
                return (normals(mesh[]),)
            end
        else
            return nothing
        end
    end
end

function compute_plot(::Type{Mesh}, args::Tuple, user_kw::Dict{Symbol,Any})
    attr = ComputeGraph()
    add_attributes!(Mesh, attr, user_kw)
    register_arguments!(Mesh, attr, user_kw, args...)
    register_mesh_decomposition!(attr)
    register_position_transforms!(attr)
    register_colormapping!(attr)
    register_computation!(attr, [:positions], [:data_limits]) do (positions,), changed, last
        return (Rect3d(positions[]),)
    end
    T = typeof(attr[:arg1][])
    p = Plot{mesh,Tuple{T}}(user_kw, Observable(Pair{Symbol,Any}[]), Any[attr], Observable[])
    p.transformation = Transformation()
    return p
end

function compute_plot(::Type{Volume}, args::Tuple, user_kw::Dict{Symbol,Any})
    attr = ComputeGraph()
    add_attributes!(Volume, attr, user_kw)
    register_arguments!(Volume, attr, user_kw, args...)
    register_position_transforms!(attr)
    register_colormapping!(attr, :volume)
    register_computation!(attr, [:x, :y, :z], [:data_limits]) do (x, y, z), changed, last
        return (Rect3d(Vec3.(x[], y[], z[])...),)
    end
    T = typeof((attr[:x][], attr[:y][], attr[:z][], attr[:volume][]))
    p = Plot{volume,Tuple{T}}(user_kw, Observable(Pair{Symbol,Any}[]), Any[attr], Observable[])
    p.transformation = Transformation()
    return p
end

function ComputePipeline.update!(plot::ComputePlots; args...)
    new_values = filter(pairs(args)) do (k, v)
        return plot[k][] != v
    end
    if isempty(new_values)
        return
    end
    ComputePipeline.update!(plot.args[1]; new_values...)
    return
end


get_colormapping(plot::Plot) = get_colormapping(plot, plot.args[1])
function get_colormapping(plot, attr::ComputePipeline.ComputeGraph)
    isnothing(attr[:_colorrange][]) && return nothing
    register_computation!(attr, [:colormap], [:colormapping_type]) do args, changed, last
        return (colormapping_type(args[1][]),)
    end
    attributes = [:color, :alpha_colormap, :raw_colormap, :colorscale, :color_mapping, :_colorrange, :lowclip, :highclip, :nan_color, :colormapping_type, :scaled_colorrange, :scaled_color]
    register_computation!(attr, attributes, [:cb_colormapping, :cb_observables]) do args, changed, cached
        dict = Dict(zip(attributes, getindex.(args)))

        N = ndims(dict[:color])
        Cin = typeof(dict[:color])
        Cout = typeof(dict[:scaled_color])

        if isnothing(cached)
            observables = map(attributes) do name
                Observable(dict[name])
            end
            observable_dict = Dict(zip(attributes, observables))
            cm = ColorMapping{N,Cin,Cout}(observables...)
            return (cm, observable_dict)
        else
            observable_dict = cached[2][]
            for (name, value, ischanged) in zip(attributes, args, changed)
                if ischanged
                    observable_dict[name][] = value[]
                end
            end
            return (cached[1][], nothing)
        end
    end
    on(plot, attr.onchange) do _
        attr[:cb_colormapping][]
    end
    return attr[:cb_colormapping][]
end

# Note: GLMakie version of this in backend-functionality.
# TODO: check if reusable?
# function apply_transform_and_model(plot::Heatmap, data, output_type=Point3d)
#     return apply_transform_and_model(
#         to_value(plot.model[]), plot.transform_func[], data, to_value(get(plot, :space, :data)), output_type
#     )
# end


# function boundingbox(plot::Heatmap, space::Symbol=:data)
#     # Assume primitive plot
#     if isempty(plot.plots)
#         raw_bb = apply_transform_and_model(plot, data_limits(plot))
#         return raw_bb
#     end

#     # Assume combined plot
#     bb_ref = Base.RefValue(boundingbox(plot.plots[1], space))
#     for i in 2:length(plot.plots)
#         update_boundingbox!(bb_ref, boundingbox(plot.plots[i], space))
#     end

#     return bb_ref[]
# end

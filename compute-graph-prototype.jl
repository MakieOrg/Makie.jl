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


mutable struct ComputedValue{P}
    value::RefValue
    parent::P
    parent_idx::Int # index of parent.outputs this value refers to
    ComputedValue{P}(value::RefValue) where {P} = new{P}(value)
    function ComputedValue{P}(value::RefValue, parent::P, idx::Integer) where {P}
        return new{P}(value, parent, idx)
    end
end

hasparent(computed::ComputedValue) = isdefined(computed, :parent)

struct ComputeEdge
    callback::Function
    inputs::Vector{ComputedValue{ComputeEdge}}
    inputs_dirty::Vector{Bool}
    outputs::Vector{ComputedValue{ComputeEdge}}
    outputs_dirty::Vector{Bool}
    got_resolved::RefValue{Bool}
    # edges, that rely on outputs from this edge
    # Mainly needed for mark_dirty!(edge) to propagate to all dependents
    dependents::Set{ComputeEdge}
end

function Base.show(io::IO, edge::ComputeEdge)
    print(io, "ComputeEdge(")
    println("  inputs:")
    for v in edge.inputs
        println("    ", v)
    end
    println("  outputs:")
    for v in edge.outputs
        println("    ", v)
    end
    println(io, ")")
end
# Can only make this alias after ComputeEdge & ComputedValue are created
# We're going to ignore that ComputedValue has a type parameter,
# which it only has to resolve the circular dependency
const Computed = ComputedValue{ComputeEdge}

ComputeEdge(f) = ComputeEdge(f, Computed[])
function ComputeEdge(f, inputs::Vector{Computed})
    return ComputeEdge(f, inputs, fill(true, length(inputs)), Computed[], Bool[], RefValue(false), Set{ComputeEdge}())
end

function Base.show(io::IO, computed::Computed)
    if isassigned(computed.value)
        print(io, "Computed($(typeof(computed.value[])))")
    else
        print(io, "Computed(#undef)")
    end
end

struct ComputeGraph
    inputs::Dict{Symbol,ComputeEdge}
    outputs::Dict{Symbol,Computed}
    default::Function
end

function Base.show(io::IO, graph::ComputeGraph)
    print(io, "ComputeGraph(")
    println("  inputs:")
    for (k, v) in graph.inputs
        val = getproperty(graph, k)[]
        println("    ", k, "=>", typeof(val))
    end
    println("  outputs:")
    for (k, out) in graph.outputs
        println("    ", k, "=>", out)
    end
    println(io, ")")
end


function ComputeGraph(default::Function)
    return ComputeGraph(
        Dict{Symbol,ComputeEdge}(), Dict{Symbol,Computed}(), default,
    )
end

function isdirty(computed::Computed)
    hasparent(computed) || return false
    parent = computed.parent
    # Can't be dirty if inputs have changed

    if parent.got_resolved[]
        # resolved is always true if nothing needs to be done (not dirty)
        return computed.parent.outputs_dirty[computed.parent_idx]
    else
        return any(parent.inputs_dirty)
    end
end

function isdirty(edge::ComputeEdge)
    # If resolve hasn't run, it has to be dirty
    edge.got_resolved[] || return true
    # Otherwise it's dirty if the input changed
    return any(edge.inputs_dirty)
end

function mark_dirty!(edge::ComputeEdge)
    edge.got_resolved[] = false
    for (i, input) in enumerate(edge.inputs)
        isdirty(input) && (edge.inputs_dirty[i] = true)
    end
    for computed in edge.outputs
        if hasparent(computed) && computed.parent !== edge
            mark_dirty!(computed.parent)
        end
    end
    for dep in edge.dependents
        mark_dirty!(dep)
    end
    return
end

function mark_dirty!(computed::Computed)
    hasparent(computed) || return
    mark_dirty!(computed.parent)
end

function Base.setindex!(computed::Computed, value)
    computed.value[] = value
    mark_dirty!(computed)
end

function Base.setproperty!(attr::ComputeGraph, key::Symbol, value)
    edge = attr.inputs[key]
    edge.inputs[1][] = value
    edge.inputs_dirty[1] = true
    mark_dirty!(edge)
    return value
end

Base.haskey(attr::ComputeGraph, key::Symbol) = haskey(attr.inputs, key)

function Base.getproperty(attr::ComputeGraph, key::Symbol)
    # more efficient to hardcode?
    key === :inputs && return getfield(attr, :inputs)
    key === :outputs && return getfield(attr, :outputs)
    key === :default && return getfield(attr, :default)
    return attr.inputs[key].inputs[1]
end

Base.getindex(computed::Computed) = resolve!(computed)

struct Resolved{T}
    ref::RefValue{T}
    has_changed::Bool
end

Base.getindex(resolved::Resolved) = resolved.ref[]

# do we want this type stable?
# This is how we could get a type stable callback body for resolve
function inner_resolve(edge, inputs, outputs)
    needs_init = false
    if all(x -> isassigned(x.value), edge.outputs)
        @show inputs
        result = edge.callback(inputs, outputs)
        @show result
    else
        needs_init = true
        result = edge.callback(inputs, nothing)
    end
    if result === :deregister
        # TODO
    elseif result isa Tuple
        @assert length(result) === length(outputs)
        ntuple(length(outputs)) do i
            v = result[i]
            if isnothing(v)
                edge.outputs_dirty[i] = false
            else
                edge.outputs_dirty[i] = true
                if needs_init
                    edge.outputs[i].value = RefValue(v)
                else
                    edge.outputs[i].value[] = v
                end
            end
        end
    elseif isnothing(result)
        fill!(edge.outputs_dirty, false)
    else
        error("Needs to return a Tuple with one element per output, or nothing")
    end
end

function resolve!(computed::Computed)
    if hasparent(computed)
        resolve!(computed.parent)
    end
    return computed.value[]
end



function resolve!(edge::ComputeEdge)
    edge.got_resolved[] && return false
    isdirty(edge) || return false

    inputs = ntuple(length(edge.inputs)) do i
        input = edge.inputs[i]
        # This comes from `mark_dirty!`
        # But we only really know if the value has changed if we run resolve!
        # has_changed = edge.inputs_dirty[i]
        resolve!(input)
        return Resolved(input.value, isdirty(input))
    end
    # We pass the refs, so that no boxing accours and code that actually needs Ref{T}(value) can directly use those (ccall/opengl)
    # TODO, can/should we store this tuple?
    outputs = ntuple(i -> edge.outputs[i].value, length(edge.outputs))
    inner_resolve(edge, inputs, outputs)
    edge.got_resolved[] = true
    fill!(edge.inputs_dirty, false)
    return true
end

function update!(attr::ComputeGraph; kwargs...)
    for (key, value) in pairs(kwargs)
        if haskey(attr.inputs, key)
            setproperty!(attr, key, value)
        else
            throw(Makie.AttributeNameError(key))
        end
    end
    return attr
end

function add_input!(attr::ComputeGraph, key::Symbol, value)
    edge = ComputeEdge() do (input,), last
        (attr.default(key, input[]),)
    end
    # Needs to be Any, since input can change type
    input = Computed(RefValue{Any}(value))
    # Outputs need to be type stable
    output = Computed(RefValue(attr.default(key, value)), edge, 1)
    push!(edge.inputs, input)
    push!(edge.inputs_dirty, false) # we already run default!
    push!(edge.outputs, output)
    push!(edge.outputs_dirty, true)

    # We assign the parent, since if we gave input a parent, we would get a circle/stackoverflow
    attr.inputs[key] = edge
    attr.outputs[key] = output
    return
end

function add_inputs!(attr::ComputeGraph; kw...)
    for (k, v) in pairs(kw)
        add_input!(attr, k, v)
    end
end

function register_computation!(f, attr::ComputeGraph, inputs::Vector{Symbol}, outputs::Vector{Symbol})
    if any(x-> haskey(attr.outputs, x), outputs)
        bad_outputs = filter(x -> haskey(attr.outputs, x), outputs)
        # TODO, allow double registration of exactly the same computation?
        error("Only one computation is allowed to be registered for an output. Found: $(bad_outputs)")
    end
    _inputs = [attr.outputs[k] for k in inputs]
    new_edge = ComputeEdge(f, _inputs)
    for input in _inputs
        hasparent(input) && push!(input.parent.dependents, new_edge)
    end
    # use order of namedtuple, which should not change!
    for (i, symbol) in enumerate(outputs)
        # create an uninitialized Ref, which gets replaced by the correctly strictly typed Ref on first resolve
        value = Computed(RefValue{Any}(), new_edge, i)
        attr.outputs[symbol] = value
        push!(new_edge.outputs, value)
        push!(new_edge.outputs_dirty, true)
    end
    return
end

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

function create_backend_object(buffers, uniforms)
    # TODO
    (buffers, uniforms)
end

begin

    attr = ComputeGraph() do key, value
        return convert_attribute(value, Makie.Key{key}(), Makie.Key{:scatter}())
    end

    # Adding inputs - default_theme effectively does this
    add_inputs!(attr,
        color=1:4, colormap=:viridis, colorscale=identity, colorrange=automatic,
        lowclip=automatic, highclip=automatic, nan_color=:transparent, alpha=1.0, marker=:circle, markersize=8,
        strokecolor=:black, strokewidth=0,
        glowcolor=:yellow, glowwidth=0, f32c=nothing, transform_func=identity, space=:data, markerspace=:pixel,
        rotation=Billboard(), marker_offset=automatic, transparency=false, arg1=-1:0.1:1, arg2=-1:0.1:1,
    )

    # Special case: calculated_attributes - marker_offset
    register_computation!(attr, [:marker_offset, :markersize], [:_marker_offset]) do (offset, size), last
        if offset[] isa Automatic
            (to_2d_scale(map(x -> x .* -0.5f0, size[])),)
        else
            (to_2d_scale(offset[]),)
        end
    end

    # Static?
    register_computation!(attr, [:colormap, :alpha], [:alpha_colormap, :raw_colormap, :color_mapping]) do (colormap, a), last
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
        register_computation!(attr, [key, :colormap], [sym]) do (input, cmap), _
            if input[] === Makie.automatic
                (ifelse(key == :lowclip, first(cmap[]), last(cmap[])),)
            else
                (to_color(input[]),)
            end
        end
    end

    register_computation!(attr, [:color, :colorrange], [:_colorrange]) do (color, colorrange), last
        (color[] isa AbstractVector{<:Real} || color[] isa Real) || return nothing
        if colorrange[] === automatic
            (Vec2d(distinct_extrema_nan(color[])),)
        else
            (Vec2d(colorrange[]),)
        end
    end
    register_computation!(attr, [:_colorrange, :colorscale], [:scaled_colorrange]) do (colorrange, colorscale), last
        isnothing(colorrange[]) && return nothing
        (Vec2f(apply_scale(colorscale[], colorrange[])),)
    end

    # Step 1 - Setup extra computed stuff
    register_computation!(attr, [:marker, :markersize, :_marker_offset], [:quad_offset, :quad_scale]) do (marker, markersize, marker_offset), last
        atlas = gl_texture_atlas()
        font = defaultfont()
        changed = marker.has_changed || markersize.has_changed
        quad_scale = changed ? Makie.rescale_marker(atlas, marker[], font, markersize[]) : nothing
        quad_offset = Makie.offset_marker(atlas, marker[], font, markersize[], marker_offset[])
        return (quad_offset, quad_scale)
    end


    args = Symbol[]
    for i in 1:100
        # this is a bit awkward :(
        sym = Symbol("arg$i")
        if haskey(attr, sym)
            push!(args, sym)
        else
            break
        end
    end
    # TODO expand_dims + dim_converts
    register_computation!(attr, args, [:positions]) do args, last
        return Makie.convert_arguments(Scatter, getindex.(args)...)
    end

    register_computation!(attr, [:positions, :transform_func, :space], [:positions_transformed]) do (positions, func, space), last
        return (Makie.apply_transform(func[], positions[], space[]),)
    end

    register_computation!(attr, [:positions_transformed, :f32c], [:positions_transformed_f32c]) do (positions, f32c), last
        return (Makie.inv_f32_convert(f32c[], positions[]),)
    end
    register_computation!(attr, [:positions, :space, :markerspace, :quad_scale, :quad_offset, :rotation], [:data_limits]) do args, last
        return (_boundingbox(getindex.(args)...),)
    end

    inputs = [:color, :alpha_colormap, :_colorrange, :_lowclip, :_highclip, :nan_color, :marker, :markersize,
        :strokecolor, :strokewidth, :glowcolor, :glowwidth, :rotation, :marker_offset, :positions_transformed_f32c]

    register_computation!(attr, inputs, [:uniforms_buffers]) do args, last
        println("running uniform buffers")
        # On first run, we collect all uniforms & buffers, with has to be an operations that can't be typed
        # But on second run, we already have the fully typed namedtuple, which allows us to have a fully typed buffers + uniforms struct
        if isnothing(last)
            uniforms = []
            buffers = []
            changeset = Set{Symbol}()
            positions = args[end]
            for (k, value) in zip(inputs, args)
                v = value[]
                isnothing(v) && continue # unused colorrange... Better to filter already in `inputs`?
                if v isa AbstractVector && length(v) == length(positions[])
                    push!(buffers, k => value.ref)
                else
                    push!(uniforms, k => value.ref) # keep the ref, tlo save allocations for e.g. Ref(Vec2f)
                end
                push!(changeset, k)
            end
            return ((uniforms=(; uniforms...), buffers=(; buffers...), changeset=changeset),)
        else
            changeset = Set{Symbol}()
            for (k, value) in zip(inputs, args)
                value.has_changed && push!(changeset, k)
            end
            return ((uniforms=last[1][].uniforms, buffers=last[1][].buffers, changeset=changeset),)
        end
    end
end;

update!(attr; arg1=-1:0.1:1, arg2=-1:0.1:1, color=1:0.1:1, markersize=22);

bb = attr.outputs[:uniforms_buffers][].changeset

bb = attr.outputs[:uniforms_buffers][].buffers.positions_transformed_f32c[]
bb = attr.outputs[:uniforms_buffers][].uniforms.color[]
bb = attr.outputs[:quad_scale][]
attr.outputs[:data_limits][]

function assemble_scatter_robj(scene, screen, positions, colormap, color, colornorm, scale, transparency)
    cam = scene[].camera
    data = Dict(
        :vertex => positions[],
        :color_map => colormap[],
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

function create_robj(screen::GLMakie.Screen, scene, attr)
    screen_name = Symbol(string(objectid(screen)))
    # We register the screen under a unique name. If the screen closes
    # Any computation that depens on screen gets removed

    register_computation!(attr, Symbol[], [screen_name]) do args, last
        (screen,)
    end
    scene_name = Symbol(string(objectid(scene)))
    register_computation!(attr, Symbol[], [scene_name]) do args, last
        (scene,)
    end
    register_computation!(attr, [scene_name, screen_name, :positions_transformed_f32c, :colormap, :color, :_colorrange, :markersize, :transparency], [:gl_renderobject]) do args, last
        scene = args[1][]
        screen = args[2][]
        !isopen(screen) && return :deregister
        if isnothing(last)
            robj = assemble_scatter_robj(args...)
            push!(screen, scene, robj)
            return (robj,)
        else
            robj = last[1][]
            # for key in changeset
            #     if haskey(uniforms, key)
            #         update_uniform!(robj[1][key], uniforms[key])
            #     else
            #         update_buffers!(robj[2][key], buffers[key])
            #     end
            # end
        end
    end
end

attr.color = -1:0.1:1

update!(attr, color=-1:0.1:1);

attr.outputs[:color][]

scene = Scene();
empty!(screen.renderlist)
GLMakie.closeall()
screen = display(scene; vsync=true, render_on_demand=false)
create_robj(screen, scene, attr)
robj = attr.outputs[:gl_renderobject][]

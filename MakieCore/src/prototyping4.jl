#=
# Assertions:
1. all necessary inputs must exist when a callback is added
2. the callback immediately creates specialized outputs
    => this implies static output types after plot!()
=#

struct UpdateFunction
    inputs::Vector{Symbol}
    outputs::Vector{Symbol}
    callback::Function
end

function UpdateFunction(inputs, outputs, f::Function)
    return UpdateFunction(collect(inputs)::Vector{Symbol}, collect(outputs)::Vector{Symbol}, f)
end

function (task::UpdateFunction)(inputs::Dict, outputs::NamedTuple)
    task.callback(getindex.(Ref(inputs), task.inputs), getindex.(Ref(outputs), task.outputs))
    return
end

# probably don't want Ref's as inputs
function (task::UpdateFunction)(inputs::NamedTuple, outputs::NamedTuple)
    task.callback(
        getindex.(getindex.(Ref(inputs), task.inputs)), # deref them too
        getindex.(Ref(outputs), task.outputs)
    )
    return
end


struct UpdatableAttributes
    inputs::Dict{Symbol, Any}
    changed_inputs::Set{Symbol}
    input_callbacks::Vector{UpdateFunction}

    outputs::Base.RefValue{NamedTuple} # NamedTuple of RefValues
    changed_outputs::Set{Symbol}
    # TODO: Does this need to be ref counted so that backends can use the same UpdateFunction?
    output_callbacks::Vector{UpdateFunction}
end

function UpdatableAttributes()
    return UpdatableAttributes(
        Dict{Symbol, Any}(), Set{Symbol}(), UpdateFunction[],
        Base.RefValue{NamedTuple}(NamedTuple()), Set{Symbol}(), UpdateFunction[]
    )
end


function Base.setproperty!(attr::UpdatableAttributes, key::Symbol, value)
    if haskey(attr.inputs, key)
        update!(attr; NamedTuple{(key,)}(value)...) # Is there a better way?
    else
        attr.inputs[key] = value
    end
end

# simpler for bulk adding inputs
function add_inputs!(attr::UpdatableAttributes; kwargs...)
    merge!(attr.inputs, pairs(kwargs))
    return attr
end

function update!(attr::UpdatableAttributes; kwargs...)
    for (key, value) in pairs(kwargs)
        if haskey(attr.inputs, key)
            attr.inputs[key] = value
            push!(attr.changed_inputs, key)
        else
            throw(AttributeNameError(key))
        end
    end
    return attr
end

# Assumption: all inputs and outputs exist
function resolve_updates!(attr::UpdatableAttributes)
    isempty(attr.changed_inputs) && return

    # parent update (R2)
    # convert_arguments, convert_attributes
    # colormapping
    # calculated_attributes
    for task in attr.input_callbacks
        if any(name -> name in attr.changed_inputs, task.inputs)
            task(attr.inputs, attr.outputs[])
            union!(attr.changed_outputs, task.outputs)
        end
    end

    empty!(attr.changed_inputs)
    isempty(attr.changed_outputs) && return

    # user callbacks
    # friend callbacks (Colorbar, Axis, Legend, ...)
    # cached backend callbacks (marker offset + scale, f32c + transform_func application, patch_model)
    # backend callbacks (update Texture, GLBuffer, maybe uniforms)
    for task in attr.output_callbacks
        if any(name -> name in attr.changed_outputs, task.inputs)
            task(attr.outputs[], attr.outputs[])
            union!(attr.changed_outputs, task.outputs)
        end
    end

    empty!(attr.changed_outputs)

    return
end

# Explicit adding of outputs for mutables (e.g. an Array output)
# Could consider not Ref-wrapping these...?
function add_output!(attr::UpdatableAttributes; kwargs...)
    wrapped = [k => v isa Base.RefValue ? v : Ref(v) for (k, v) in pairs(kwargs)]
    attr.outputs[] = merge(attr.outputs[], NamedTuple(wrapped))
    return attr
end
function add_output!(attr::UpdatableAttributes, kwargs::Pair{Symbol}...)
    wrapped = [k => v isa Base.RefValue ? v : Ref(v) for (k, v) in kwargs]
    attr.outputs[] = merge(attr.outputs[], NamedTuple(wrapped))
    return attr
end

# automatic version creates an empty Ref and assumes the callback fills it
function automatic_outputs(task, inputs, outputs)
    @assert all(in(keys(inputs)), task.inputs)
    missing_names = setdiff(task.outputs, keys(outputs))
    outputs = merge(outputs, NamedTuple((k => Ref{Any}() for k in missing_names)))
    task(inputs, outputs)
    # TODO: Error check for nested refs
    outputs = merge(outputs, NamedTuple((k => Ref(outputs[k][]) for k in missing_names)))
    return outputs
end

# register update function (and generate missing outputs)
# TODO: How do we differentiate these nicely?
function register_input_update!(callback::Function, attr::UpdatableAttributes, inputs, outputs)
    update = UpdateFunction(inputs, outputs, callback)
    if !in(update, attr.input_callbacks)
        attr.outputs[] = automatic_outputs(update, attr.inputs, attr.outputs[])
        push!(attr.input_callbacks, update)
    end
    return
end
function register_output_update!(callback::Function, attr::UpdatableAttributes, inputs, outputs)
    update = UpdateFunction(inputs, outputs, callback)
    if !in(update, attr.output_callbacks)
        attr.outputs[] = automatic_outputs(update, attr.outputs[], attr.outputs[])
        push!(attr.output_callbacks, update)
    end
    return
end


################################################################################

# Sketching usage with scatter

using Makie
using Makie: automatic, Automatic, Key
using Makie: convert_attribute
using Makie: PlotUtils, Colors, Colorant
using Makie: to_2d_scale, to_color, colormapping_type, to_colormap, _to_colormap,
            distinct_extrema_nan, apply_scale

attr = UpdatableAttributes()

# Adding inputs - default_theme effectively does this
add_inputs!(attr,
    color = :blue, colormap = :viridis, colorscale = identity, colorrange = automatic,
    lowclip = automatic, highclip = automatic, nan_color = :transparent, alpha = 1.0,

    marker = :circle, markersize = 8,
    strokecolor = :black, strokewidth = 0,
    glowcolor = :yellow, glowwidth = 0,
    rotation = Billboard(), marker_offset = automatic
)

# simple input -> output conversions
# TODO: maybe we can add a simplified version that uses return values?
for key in [:marker, :markersize, :strokecolor, :strokewidth, :glowcolor, :glowwidth, :rotation]
    init = convert_attribute(attr.inputs[key], Key{key}(), Key{:scatter}())
    register_input_update!(attr, (key,), (key,)) do (input,), (output,)
        output[] = convert_attribute(input, Key{key}(), Key{:scatter}())
    end
end

# Special case: calculated_attributes - marker_offset
register_input_update!(attr, (:marker_offset, :markersize), (:marker_offset,)) do (offset, size), (output,)
    if offset isa Automatic
        output[] = to_2d_scale(map(x -> x .* -0.5f0, size))
    else
        output[] = convert_attribute(offset, Key{:marker_offset}(), Key{:scatter}())
    end
end

# Special case: colors (all of this would be a generic setup function)
begin
    @inline function add_alpha(color, alpha)
        return RGBAf(Colors.color(color), alpha * Colors.alpha(color))
    end

    register_input_update!(attr, (:nan_color,), (:nan_color,)) do (input,), (output,)
        output[] = to_color(input)
    end

    register_input_update!(attr, (:colorscale,), (:colorscale,)) do (input,), (output,)
        output[] = input
    end

    # Static?
    add_output!(attr, :color_mapping_type => colormapping_type(attr.inputs[:colormap]))

    add_output!(attr, :colormap => RGBAf[], :raw_colormap => RGBAf[]) # Idk what mapping is
    register_input_update!(attr, (:colormap, :alpha), (:colormap, :raw_colormap, :mapping)) do (icm, a), (ocm, rcm, m)
        cmap     = to_colormap(icm)::Vector{RGBAf}
        raw_cmap = _to_colormap(icm)::Vector{RGBAf}
        resize!(ocm[], length(cmap))
        resize!(rcm[], length(cmap))
        if a < 1.0
            ocm[] .= add_alpha.(cmap)
            rcm[] .= add_alpha.(raw_cmap)
        else
            ocm[] .= cmap
            rcm[] .= raw_cmap
        end

        if icm isa PlotUtils.ColorGradient
            m[] = plot.colormap[].values
        else
            m[] = nothing
        end
    end

    # TODO: Hacky `attr.outputs[][name][]` to avoid either:
    # - double conversion of input
    # - unnecessary update of "name" if some other input changes
    for key in (:lowclip, :highclip)
        register_input_update!(attr, (key, :colormap), (key,)) do (input, _), (output,)
            if input === Makie.automatic
                cmap = attr.outputs[][:colormap][]
                output[] = ifelse(key == :lowclip, first(cmap), last(cmap))
            else
                output[] = to_color(input)
            end
        end
    end


    if attr.inputs[:color] isa Union{Real, AbstractVector{<: Real}}
        add_output!(attr, :color => Float64[], :color_scaled => Float32[])
        register_input_update!(attr, (:color,), (:color,)) do (input, ), (output,)
            resize!(output[], length(input))
            if input isa Real
                output[][1] = input[1]
            else
                output[] .= input
            end
        end
        register_input_update!(attr, (:color, :colorrange), (:colorrange,)) do (_, colorrange), (output,)
            if colorrange[] === automatic
                output[] = Vec2{Float64}(distinct_extrema_nan(attr.output[:color][]))
            else
                output[] = Vec2{Float64}(colorrange)
            end
        end

        register_input_update!(attr, (:color, :colorrange, :colorscale), (:colorrange,)) do (_, _, colorscale), (output,)
            output[] = Vec2f(apply_scale(colorscale, attr.outputs[][:colorrange][]))
        end

        register_input_update!(attr, (:color, :colorscale), (:colorrange,)) do (_, colorscale), (output,)
            resize!(output[], length(attr.outputs[][:color][]))
            output[] = el32convert(apply_scale(plot.colorscale[], attr.outputs[][:color][]))
        end

    elseif attr.inputs[:color] isa Union{Colorant, Symbol}
        register_input_update!(attr, (:color, :alpha), (:color,)) do (color, alpha), (output,)
            output[] = add_alpha(to_color(color), alpha)
        end
    else
        add_output!(attr, :color => RGBAf[])
        register_input_update!(attr, (:color, :alpha), (:color,)) do (color, alpha), (output,)
            resize!(output[], length(color))
            output[] .= add_alpha(to_color(color), alpha) # TODO: vectorize
        end
    end
end

# Let's try update all
union!(attr.changed_inputs, keys(attr.inputs))
resolve_updates!(attr)
# foreach(println, pairs(attr.outputs[]))

# RenderObject side

using GLMakie
using GLMakie: gl_texture_atlas
using Makie: defaultfont, Mat4f
using LinearAlgebra

begin
    # Step 1 - Setup extra computed stuff
    register_output_update!(attr, (:marker, :markersize, :marker_offset), (:quad_offset, :quad_scale)) do (marker, markersize, marker_offset), (quad_offset, quad_scale)
        atlas = gl_texture_atlas()
        font = defaultfont()
        quad_scale[] = Makie.rescale_marker(atlas, marker, font, markersize)
        quad_offset[] = Makie.offset_marker(atlas, marker, font, markersize, marker_offset)
    end
    # transformed positions, model, ...

    # Step 2 - Setup defaults for uniforms, vertex buffers
    outputs = attr.outputs[]
    gl_attributes = Dict{Symbol, Any}(
        # stuff that exists in output
        :scale => outputs[:quad_scale][],         # => GLBuffer
        :quad_offset => outputs[:quad_offset][],  # => GLBuffer
        # from scene
        :projectionview => Mat4f(I),
    )

    # Step 2.5 - make robj, throw away unused stuff, maybe make statically typed NamedTuple
    # robj = assemble_shader(gl_attributes)

    # Step 3 - setup callbacks
    register_output_update!(attr, (:quad_offset, :quad_scale), Symbol[]) do (quad_offset, quad_scale), _
        # technically should be update!(buffer, ...)
        gl_attributes[:scale] = quad_scale
        gl_attributes[:quad_offset] = quad_offset
    end

    # Could check if haskey(robj.uniforms, name); register...
    # Could pull out type based branching as well
end

#
union!(attr.changed_inputs, keys(attr.inputs))
resolve_updates!(attr)
gl_attributes
update!(attr, markersiz = 20) # name error
update!(attr, markersize = 20) # OK
attr.changed_inputs # should contain markersize
resolve_updates!(attr)
gl_attributes # different from before
attr.changed_inputs

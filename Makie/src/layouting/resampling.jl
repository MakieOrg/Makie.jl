abstract type AbstractResampler end

# TODO: fill out a reasonable set of default methods

"""
    mandatory_resampling_inputs(::Type{<:Plot}, ::AbstractResampler)

Defines a minimal set of inputs required to resample the plot. These should be
given as a `Vector{Symbol}` and typically just include `[:positions]`.
"""
mandatory_resampling_inputs(::Type{<:Plot}, ::AbstractResampler) = Symbol[]
mandatory_resampling_inputs(::Type{<:Plot}, ::Nothing) = Symbol[]

"""
    resample(::Type{<:Plot}, ::AbstractResampler, transform_func, inputs...)

This function processes the inputs defined in `mandatory_resampling_inputs`. It
produces two things:
1. A resampler that can be used to resample attributes.
2. A resampled output for each input.
"""
resample(::Type{<:Plot}, ::AbstractResampler, transform_func, args...) = (nothing, args...)
resample(::Type{<:Plot}, ::Nothing, transform_func) = (nothing,)

# TODO: Might be preferable to give this the graph so it can check what attributes
# are appropriately sized?
# Or the Resampler can just save a length for `resample` to check
"""
    resampled_attributes(::Type{<:Plot}, ::AbstractResampler)

Defines all attributes of a plot that resampling could apply to.
"""
resampled_attributes(::Type{<:Plot}, ::AbstractResampler) = Symbol[]
resampled_attributes(::Type{<:Plot}, ::Nothing) = tuple()

"""
    resample(resampler, data[, ::Makie.key"attribute_name", ::Makie.key"plot_name"])

Resamples `data` using a given `resampler`. May optionally contain an attribute
name key and a plot name key for dispatch.
"""
resample(interp, data, attrib_key, plot_key) = resample(interp, data, attrib_key)
resample(interp, data, attrib_key) = resample(interp, data)
resample(interp, data) = data

################################################################################

# More or less an example...
struct Resampler <: AbstractResampler end


struct LinearResampler <: AbstractResampler
    samples::Vector{Float64}
    N::Int
end

mandatory_resampling_inputs(::Type{<:Scatter}, ::AbstractResampler) = [:positions]
function resample(::Type{<:Plot}, ::Resampler, transform_func, positions)
    steps = [i + di for i in eachindex(positions) for di in (0.0, 0.5)]
    interp = LinearResampler(steps, length(positions))
    new_pos = resample(interp, positions)
    return interp, new_pos
end


resampled_attributes(::Type{<:Scatter}, ::AbstractResampler) = [:color, :markersize]

function resample(interp::LinearResampler, data::AbstractVector)
    N = length(data)
    if N == interp.N
        return map(interp.samples) do sample
            i0 = clamp(floor(Int, sample), 1, N)
            i1 = clamp(ceil(Int, sample), 1, N)
            return lerp(data[i0], data[i1], sample - i0)
        end
    else
        return data
    end
end

################################################################################

struct ResampleCallback{attr_key, plot_key} <: Function end
function (::ResampleCallback{attr_key, plot_key})(interp, data) where {attr_key, plot_key}
    return resample(interp, data, attr_key, plot_key)
end

function register_resampling!(plot::PlotType) where {PlotType}
    graph = plot.attributes

    if !haskey(graph, :resampler)
        add_input!((k, v) -> Ref{Any}(v), graph, :resampler, Resampler())
    end

    map!(graph, [:resampler, :transform_func], [:interpolator]) do args...
        return resample(PlotType, args...)
    end

    reset_info = Symbol[]
    on(graph.resampler, update = true) do resampler
        @lock graph.lock begin
            # Step 1: Reset previously deferred nodes
            for name in reset_info
                deferred_name = Symbol(:deferred_, name)
                parent = graph[deferred_name].parent
                ComputePipeline.replace_output!(parent, deferred_name => name)
            end
            empty!(reset_info)

            # Step 2: Build up the core resampling edge
            update_resample_producer!(graph, PlotType, resampler, reset_info)

            # Step 3: splice in resample edges for attributes
            update_resampled_attributes!(graph, PlotType, resampler, reset_info)

            return
        end
    end

    return
end

function update_resample_producer!(graph, PlotType, resampler, reset_info)
    outputs = mandatory_resampling_inputs(PlotType, resampler)
    if !all(haskey.(Ref(graph), outputs))
        failed = filter(name -> !haskey(graph, name), outputs)
        error("Failed to get inputs $failed for $resampler in $PlotType. These nodes don't exist.")
    end

    # Gather/create deferred inputs
    inputs = Symbol[:resampler, :transform_func]
    for name in outputs
        node = graph[name]
        input = Symbol(:deferred_, name)
        haskey(graph, input) || ComputePipeline.add_orphaned_node!(graph, input)
        ComputePipeline.replace_output!(node.parent, name => input)
        push!(inputs, input)
    end

    # Update core resampling edge
    pushfirst!(outputs, :interpolator)
    ComputePipeline.modify_edge!(graph.interpolator.parent; inputs, outputs)

    append!(reset_info, outputs)

    return
end

function update_resampled_attributes!(graph, PlotType, resampler, reset_info)
    outputs = resampled_attributes(PlotType, resampler)
    if !all(haskey.(Ref(graph), outputs))
        failed = filter(name -> !haskey(graph, name), outputs)
        error("Failed to get inputs $failed for $resampler in $PlotType. These nodes don't exist.")
    end

    # Gather/create deferred inputs
    inputs = Symbol[]
    for name in outputs
        node = graph[name]
        input = Symbol(:deferred_, name)
        haskey(graph, input) || ComputePipeline.add_orphaned_node!(graph, input)
        ComputePipeline.replace_output!(node.parent, name => input)
        push!(inputs, input)
    end

    plot_key = Key{plotsym(PlotType)}()

    for (input, output) in zip(inputs, outputs)
        attr_key = Key{output}()
        callback = ResampleCallback{attr_key, plot_key}()
        ComputePipeline.modify_edge!(
            graph[output].parent,
            callback = callback,
            inputs = [:interpolator, input],
            outputs = [output],
            packed = true
        )
    end

    append!(reset_info, outputs)

    return
end

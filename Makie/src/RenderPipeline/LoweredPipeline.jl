# This validates the RenderPipeline and tries to optimize for memory usage by
# reusing buffers. I.e. if a buffer is only used between stage 1 and 2, this
# tries to reuse it after stage 2.

"""
    struct LoweredStage end

This is the lowered version of a `Stage` as used in `LoweredRenderPipeline`.
Contains the same `name` and `attributes` as the `Stage` it represents. The
`inputs` and `outputs` hold `name => index` pairs where the names match the
respective `Stage` inputs and outputs and `index` refers to the buffer/format
in the parent `LoweredRenderPipeline`s `formats`. The order of inputs and
outputs is preserved and unused ones are removed.
"""
struct LoweredStage
    name::Symbol
    inputs::Vector{Pair{Symbol, Int64}}
    outputs::Vector{Pair{Symbol, Int64}}
    attributes::Dict{Symbol, Any}
end

# - same stages represented by different types
# - optimized formats/buffers
struct LoweredRenderPipeline
    stages::Vector{LoweredStage}
    formats::Vector{BufferFormat}
end

function LoweredRenderPipeline()
    return LoweredRenderPipeline(LoweredStage[], BufferFormat[])
end

"""
    LoweredRenderPipeline(pipeline::RenderPipeline)

Creates a lower level representation of the given render pipeline for use in backends.

The new representation optimizes the number of buffers used by reusing them when
they are free to be reused. Stages directly refer to these buffers here, and
they drop information about which buffer formats they originally wanted.
"""
function LoweredRenderPipeline(pipeline::RenderPipeline)
    buffers, mapping = generate_buffers(pipeline)

    stages = map(enumerate(pipeline.stages)) do (stage_idx, stage)
        return LoweredStage(
            stage.name,
            apply_remapping(pipeline, mapping, stage_idx, stage.inputs, -1),
            apply_remapping(pipeline, mapping, stage_idx, stage.outputs, 1),
            stage.attributes
        )
    end

    return LoweredRenderPipeline(stages, buffers)
end

function apply_remapping(
        pipeline::RenderPipeline, mapping::Vector{<:Integer},
        stage_idx::Integer, name2idx::Dict{Symbol, <:Integer}, sign
    )
    # get input/output names in order
    old_names = Vector{Symbol}(undef, length(name2idx))
    for (name, idx) in name2idx
        old_names[idx] = name
    end

    # get the index into the new `buffers` from the index into the old
    # `pipeline.formats` and associate it with the respective stage input/output
    # name. Any unused inputs/outputs are removed here
    buffer_idx_name = Pair{Symbol, Int64}[]
    for (io_idx, name) in enumerate(old_names)
        if haskey(pipeline.stageio2idx, (stage_idx, sign * io_idx))
            format_idx = pipeline.stageio2idx[(stage_idx, sign * io_idx)]
            remapped_idx = mapping[format_idx]
            push!(buffer_idx_name, name => remapped_idx)
        end
    end

    return buffer_idx_name
end

format_complexity(f::BufferFormat) = format_complexity(f.dims, f.type)
format_complexity(dims, type) = dims * BFT.bytesize(type)
# complexity of merged, not max of either
format_complexity(f1::BufferFormat, f2::BufferFormat) = max(f1.dims, f2.dims) * max(BFT.bytesize(f1.type), BFT.bytesize(f2.type))

function validate_pipeline(pipeline::RenderPipeline)
    for (i, stage) in enumerate(pipeline.stages)
        # Confirm that all outputs have the same number of samples
        if !allequal(format -> format.samples, stage.output_formats)
            error("Stage $stage does not have a consistent sample count for all outputs.")
        end

        # Confirm that there are at most 1 stencil and depth buffer
        depth = 0
        stencil = 0
        for format in stage.output_formats
            depth += is_depth_format(format) || is_depth_stencil_format(format)
            stencil += is_stencil_format(format) || is_depth_stencil_format(format)
        end
        if depth > 1 || stencil > 1
            error("Stage $stage has more than one depth or stencil buffer. ($depth depth, $stencil stencil)")
        end
    end

    # Confirm that all buffer types are valid
    # if they are not try to bump the bytesize by one (which only actually affects depth24)
    for i in eachindex(pipeline.formats)
        format = pipeline.formats[i]
        bft_type = format.type
        if BFT.to_type(bft_type) === Nothing
            while BFT.can_advance(bft_type) && BFT.to_type(bft_type) === Nothing
                bft_type = BFT.unsafe_advance(bft_type)
            end

            if BFT.to_type(bft_type) === Nothing
                error("Invalid format found: $format (invalid type)")
            else
                pipeline.formats[i] = BufferFormat(format, type = bft_type)
            end
        end
    end

    # Verify that outputs are continuously connected, i.e. that if stage.outputs[N]
    # is connected all the outputs from 1:N-1 are too. (Otherwise there may be
    # mapping issues in the backend, because output[i] != shader output i)
    output_max = zeros(Int, length(pipeline.stages))
    output_sum = zeros(Int, length(pipeline.stages))
    for (stage_idx, io_idx) in keys(pipeline.stageio2idx)
        # io_idx < 0 signifies inputs which are not relevant for this
        io_idx < 0 && continue

        output_max[stage_idx] = max(output_max[stage_idx], io_idx)
        output_sum[stage_idx] = output_sum[stage_idx] + io_idx # or use max(0, io_idx) and skip continue?
    end

    # If all outputs are connected we get a sum: 1 + 2 + ... + n = n(n+1)/2
    # check that we calculated that sum with n = maximum output index
    for i in eachindex(output_sum)
        s = output_sum[i]
        m = output_max[i]
        if s != div(m * (m + 1), 2)
            error("Stage $i has an incomplete set of output connections.")
        end
    end

    return
end

"""
    generate_buffers(pipeline)

Maps the connections in the given pipeline to a vector of buffer formats and
returns them together with a connection-to-index map. This will attempt to
optimize buffers for the lowest memory overhead. I.e. it will reuse buffers for
multiple connections and upgrade them if it is cheaper than creating a new one.
"""
function generate_buffers(pipeline::RenderPipeline)
    validate_pipeline(pipeline)

    # Group connections that exist between stages

    # Find the first output writing to and the last input reading from each connection
    endpoints = [(999_999, 0) for _ in pipeline.formats]
    for ((stage_idx, io_idx), format_idx) in pipeline.stageio2idx
        start, stop = endpoints[format_idx]
        start = min(start, stage_idx + (io_idx < 0) * 999_999) # always pick start if stage_idx is input
        stop = max(stop, (io_idx < 0) * stage_idx - 1) # pick stop if io_idx is output
        endpoints[format_idx] = (start, stop)
    end

    # TODO: merge depth + stencil pairs with the same ... endpoint?

    # Collect the connection indices used between each pair of stages (transfer)
    usage_per_transfer = [Int[] for _ in 1:(length(pipeline.stages) - 1)]
    for (conn_idx, (start, stop)) in enumerate(endpoints)
        # This implies the connection has not been set, i.e. it is unused. Skip those.
        # (Filtering those beforehand could mess up conn_idx)
        start > stop && continue

        for i in start:stop
            push!(usage_per_transfer[i], conn_idx)
        end
    end

    # Generate the minimal* set of buffers needed for the pipeline. This allows
    # buffers to be reused and types to be widened for reuse.
    # *minimal is the goal, not a guarantee

    buffers = BufferFormat[]
    conn2merged = fill(-1, length(pipeline.formats))
    needs_buffer = Int[]
    available = Int[]

    for i in eachindex(usage_per_transfer)
        # prepare:
        # - collect used connections without buffers
        # - collect available buffers (not in use now or last iteration)
        copyto!(resize!(available, length(buffers)), eachindex(buffers))
        empty!(needs_buffer)
        for j in max(1, i - 1):i
            for conn_idx in usage_per_transfer[j]
                if conn2merged[conn_idx] != -1
                    idx = conn2merged[conn_idx]
                    filter!(!=(idx), available)
                elseif j == i
                    push!(needs_buffer, conn_idx)
                end
            end
        end

        # Handle most expensive connections first
        sort!(needs_buffer, by = i -> format_complexity(pipeline.formats[i]), rev = true)

        # for each connection, look for a free matching buffer, a compatible
        # buffer (which might need its type widened) or create a new buffer
        for conn_idx in needs_buffer
            # search for most compatible buffer
            best_match = 0
            prev_comp = 999999
            prev_delta = 999999
            conn_format = pipeline.formats[conn_idx]
            conn_comp = format_complexity(conn_format)
            for i in available
                if buffers[i] == conn_format # exact match
                    best_match = i
                    break
                elseif is_compatible(buffers[i], conn_format)
                    # found compatible buffer, but we only use it if
                    # - using it is cheaper than using the last
                    # - using it is not more expensive than creating a new buffer
                    # - it is more compatible than the last when both are 0 cost
                    #   (i.e prefer (3, Float16) over (3, Float8) for (3, Float16) target)
                    updated_comp = format_complexity(buffers[i], conn_format)
                    buffer_comp = format_complexity(buffers[i])
                    delta = updated_comp - buffer_comp
                    is_cheaper_than_last = delta < prev_delta # in terms of added bits
                    is_cheaper_than_new = delta <= conn_comp
                    is_cheaper = is_cheaper_than_last && is_cheaper_than_new
                    # delta = 0 means the buffer we check is bigger than it needs to be
                    # if it's smaller than the last it's thus more compatible
                    is_more_compatible = (delta == prev_delta == 0) && (buffer_comp < prev_comp)
                    if is_cheaper || is_more_compatible
                        best_match = i
                        prev_comp = updated_comp
                        prev_delta = delta
                    end
                end
            end

            if best_match == 0
                # nothing compatible found/available, add format
                push!(buffers, conn_format)
                best_match = length(buffers)
            elseif buffers[best_match] != conn_format
                # found upgradeable format, upgrade it (or use it)
                new_format = BufferFormat(buffers[best_match], conn_format)
                buffers[best_match] = new_format
            end

            # Link to new found or upgraded format
            conn2merged[conn_idx] = best_match

            # Can't use a buffer twice in one transfer
            filter!(!=(best_match), available)
        end
    end

    return buffers, conn2merged
end

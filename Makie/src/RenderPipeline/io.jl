# just printing

function Base.show(io::IO, format::BufferFormat)
    print(io, "BufferFormat($(format.dims), $(format.type))")
    return io
end

function Base.show(io::IO, ::MIME"text/plain", format::BufferFormat)
    print(io, "BufferFormat($(format.dims), $(format.type)")

    print(io, ", minfilter = :$(format.minfilter)")
    print(io, ", magfilter = :$(format.magfilter)")
    print(io, ", repeat = $(format.repeat)")
    print(io, ", mipmap = $(format.mipmap))")
    return io
end

Base.show(io::IO, stage::Stage) = print(io, "Stage($(stage.name))")
function Base.show(io::IO, ::MIME"text/plain", stage::Stage)
    print(io, "Stage($(stage.name))")

    if !isempty(stage.inputs)
        print(io, "\ninputs:")
        ks = collect(keys(stage.inputs))
        sort!(ks, by = k -> stage.inputs[k])
        pad = mapreduce(k -> length(string(k)), max, ks)
        for (i, k) in enumerate(ks)
            print(io, "\n  [?] ", lpad(string(k), pad), "::", stage.input_formats[i])
        end
    end

    if !isempty(stage.outputs)
        print(io, "\noutputs:")
        ks = collect(keys(stage.outputs))
        sort!(ks, by = k -> stage.outputs[k])
        pad = mapreduce(k -> length(string(k)), max, ks)
        for (i, k) in enumerate(ks)
            print(io, "\n  [?] ", lpad(string(k), pad), "::", stage.output_formats[i])
        end
    end

    if !isempty(stage.attributes)
        print(io, "\nattributes:")
        pad = mapreduce(k -> length(":$k"), max, keys(stage.attributes))
        for (k, v) in pairs(stage.attributes)
            print(io, "\n  ", lpad(":$k", pad), " = ", v)
        end
    end

    return
end

function Base.show(io::IO, ::MIME"text/plain", pipeline::RenderPipeline)
    return show_resolved(io, pipeline, pipeline.formats, collect(eachindex(pipeline.formats)))
end

function show_resolved(pipeline::RenderPipeline, buffers, remap)
    return show_resolved(stdout, pipeline, buffers, remap)
end

function show_resolved(io::IO, pipeline::RenderPipeline, buffers, remap)
    println(io, "RenderPipeline():")
    print(io, "Stages:")
    pad = isempty(buffers) ? 0 : 1 + floor(Int, log10(length(buffers)))

    for (stage_idx, stage) in enumerate(pipeline.stages)
        print(io, "\n  Stage($(stage.name))")

        if !isempty(stage.input_formats)
            print(io, "\n    inputs: ")
            strs = map(eachindex(stage.input_formats)) do i
                k = findfirst(==(i), stage.inputs)
                if haskey(pipeline.stageio2idx, (stage_idx, -i))
                    conn = string(remap[pipeline.stageio2idx[(stage_idx, -i)]])
                else
                    conn = " "
                end
                return "[$conn] $k"
            end
            while length(strs) > 0 && startswith(last(strs), "[ ]")
                pop!(strs)
            end
            join(io, strs, ", ")
        end

        if !isempty(stage.output_formats)
            print(io, "\n    outputs: ")
            strs = map(eachindex(stage.output_formats)) do i
                k = findfirst(==(i), stage.outputs)
                if haskey(pipeline.stageio2idx, (stage_idx, i))
                    conn = string(remap[pipeline.stageio2idx[(stage_idx, i)]])
                else
                    conn = "#undef"
                end
                return "[$conn] $k"
            end
            while length(strs) > 0 && startswith(last(strs), "[#undef]")
                pop!(strs)
            end
            join(io, strs, ", ")
        end
    end

    println(io, "\nConnection Formats:")
    for (i, c) in enumerate(buffers)
        s = lpad("$i", pad)
        println(io, "  [$s] ", c)
    end

    return
end

function Base.show(io::IO, ::MIME"text/plain", pipeline::LoweredRenderPipeline)
    println(io, "LoweredRenderPipeline():")
    print(io, "Stages:")
    pad = isempty(pipeline.formats) ? 0 : 1 + floor(Int, log10(length(pipeline.formats)))

    for stage in pipeline.stages
        print(io, "\n  Stage($(stage.name))")

        if !isempty(stage.inputs)
            print(io, "\n    inputs: ")
            strs = map(idx_name -> "[$(idx_name[1])] $(idx_name[2])", stage.inputs)
            join(io, strs, ", ")
        end

        if !isempty(stage.outputs)
            print(io, "\n    outputs: ")
            strs = map(idx_name -> "[$(idx_name[1])] $(idx_name[2])", stage.outputs)
            join(io, strs, ", ")
        end
    end

    println(io, "\nConnection Formats:")
    for (i, c) in enumerate(pipeline.formats)
        s = lpad("$i", pad)
        println(io, "  [$s] ", c)
    end

    return
end
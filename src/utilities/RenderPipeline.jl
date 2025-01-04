# Note: This file could easily be moved out into a mini-package.

import FixedPointNumbers: N0f8

module BFT
    import FixedPointNumbers: N0f8

    @enum BufferFormatType::UInt8 begin
        float8 = 0; float16 = 1; float32 = 3;
        int8 = 4; int16 = 5; int32 = 7;
        uint8 = 8; uint16 = 9; uint32 = 11;
    end

    # lowest 2 bits do variation between 8, 16 and 32 bit types, others do variation of base type
    is_compatible(a::BufferFormatType, b::BufferFormatType) = (UInt8(a) & 0b11111100) == (UInt8(b) & 0b11111100)

    # assuming compatible types (max is a bitwise thing here btw)
    _promote(a::BufferFormatType, b::BufferFormatType) = BufferFormatType(max(UInt8(a), UInt8(b)))

    # we matched the lowest 2 bits to bytesize
    bytesize(x::BufferFormatType) = Int((UInt8(x) & 0b11) + 1)

    const type_lookup = (N0f8, Float16, Nothing, Float32, Int8, Int16, Nothing, Int32, UInt8, UInt16, Nothing, UInt32)
    to_type(t::BufferFormatType) = type_lookup[Int(t) + 1]
end


# TODO: try `BufferFormat{T} ... type::Type{T}` for better performance?
# TODO: consider adding a "immediately reusable" flag here or to Stage so that
#       Stage can communicate that it allows output = input
struct BufferFormat
    dims::Int
    type::BFT.BufferFormatType
    extras::Dict{Symbol, Any}
end

"""
    BufferFormat([dims = 4, type = N0f8]; extras...)

Creates a `BufferFormat` which encodes requirements for an input or output of a
`Stage`. For example, a color output may require 3 (RGB) N0f8's (8 bit "float"
normalized to a 0..1 range).

The `BufferFormat` may also include extra requirements such as
`x_minfilter = :nearest` or `mipmap = true`.
"""
function BufferFormat(dims::Integer = 4, type::DataType = N0f8; extras...)
    return BufferFormat(dims, type, Dict{Symbol, Any}(extras))
end
@generated function BufferFormat(dims::Integer, ::Type{T}, extras::Dict{Symbol, Any}) where {T}
    type = BFT.BufferFormatType(UInt8(findfirst(x -> x === T, BFT.type_lookup)) - 0x01)
    return :(BufferFormat(dims, $type, extras))
end

function Base.:(==)(f1::BufferFormat, f2::BufferFormat)
    return (f1.dims == f2.dims) && (f1.type == f2.type) && (f1.extras == f2.extras)
end

"""
    BufferFormat(f1::BufferFormat, f2::BufferFormat)

Creates a new `BufferFormat` combining two given formats. For this the formats
need to be compatible, but not the same.

Rules:
- The output size is `dims = max(f1.dims, f2.dims)`
- Types must come from the same base type (AbstractFloat, Signed, Unsigned) where N0f8 counts as a float.
- The output type is the larger one of the two
- Extra requirements must match if both formats have them.
- If only one format contains a specific extra requirement it is accepted and copied to the output.
"""
function BufferFormat(f1::BufferFormat, f2::BufferFormat)
    if BFT.is_compatible(f1.type, f2.type)
        dims = max(f1.dims, f2.dims)
        type = BFT._promote(f1.type, f2.type)
        extras = deepcopy(f1.extras)
        for (k, v) in f2.extras
            get!(extras, k, v) == v || error("Failed to merge BufferFormat: Extra requirement $(extras[k]) != $v.")
        end
        return BufferFormat(dims, type, extras)
    else
        error("Failed to merge BufferFormat: $f1 and $f2 are not compatible.")
    end
end

function is_compatible(f1::BufferFormat, f2::BufferFormat)
    BFT.is_compatible(f1.type, f2.type) || return false
    extras_compat = true
    for (k, v) in f1.extras
        extras_compat = extras_compat && (get(f2.extras, k, v) == v)
    end
    return extras_compat
end

function format_to_type(format::BufferFormat)
    eltype = BFT.to_type(format.type)
    return format.dims == 1 ? eltype : Vec{format.dims, eltype}
end


struct Stage
    name::Symbol

    # order matters for outputs
    # these are "const" after init
    inputs::Dict{Symbol, Int}
    outputs::Dict{Symbol, Int}
    input_formats::Vector{BufferFormat}
    output_formats::Vector{BufferFormat}

    # const for caching (which does quite a lot actually)
    attributes::Dict{Symbol, Any} # TODO: rename -> settings?
end

"""
    Stage(name::Symbol[; inputs = Pair{Symbol, BufferFormat}[], outputs = Pair{Symbol, BufferFormat}[])

Creates a new `Stage` from the given `name`, `inputs` and `outputs`. A `Stage`
represents an action taken during rendering, e.g. rendering (a subset of) render
objects, running a post processor or sorting render objects.
"""
function Stage(name; inputs = Pair{Symbol, BufferFormat}[], outputs = Pair{Symbol, BufferFormat}[], kwargs...)
    return Stage(Symbol(name),
        Dict{Symbol, Int}([k => idx for (idx, (k, v)) in enumerate(inputs)]),
        BufferFormat[v for (k, v) in inputs],
        Dict{Symbol, Int}([k => idx for (idx, (k, v)) in enumerate(outputs)]),
        BufferFormat[v for (k, v) in outputs];
        kwargs...
    )
end
function Stage(name, inputs, input_formats, outputs, output_formats; kwargs...)
    return Stage(
        Symbol(name),
        inputs, outputs,
        input_formats, output_formats,
        Dict{Symbol, Any}(pairs(kwargs))
    )
end

get_input_format(stage::Stage, key::Symbol) = stage.input_formats[stage.inputs[key]]
get_output_format(stage::Stage, key::Symbol) = stage.output_formats[stage.outputs[key]]

function Base.:(==)(s1::Stage, s2::Stage)
    # For two stages to be equal:
    # name & format must match as they define the backend implementation and required buffers
    # outputs don't strictly need to match as they are just names.
    # inputs do as they are used as uniform names (could change)
    # attributes probably should match because they change uniforms and compile time constants
    # (this may allow us to merge pipelines later)
    return (s1.name == s2.name) && (s1.input_formats == s2.input_formats) &&
        (s1.output_formats == s2.output_formats) &&
        (s1.inputs == s2.inputs) && (s1.outputs == s2.outputs) &&
        (s1.attributes == s2.attributes)
end

struct Pipeline
    stages::Vector{Stage}

    # (stage_idx, negative input index or positive output index) -> connection format index
    stageio2idx::Dict{Tuple{Int, Int}, Int}
    formats::Vector{BufferFormat} # of connections
    # TODO: consider adding:
    # endpoints::Vector{Tuple{Int, Int}}
end

"""
    Pipeline([stages::Stage...])

Creates a `Pipeline` from the given `stages` or an empty pipeline if none are
given. The pipeline represents a series of actions (stages) executed during
rendering.
"""
function Pipeline()
    return Pipeline(Stage[], Dict{Tuple{Int, Int}, Int}(), BufferFormat[])
end
function Pipeline(stages::Stage...)
    pipeline = Pipeline()
    foreach(stage -> push!(pipeline, stage), stages)
    return pipeline
end


# Stages are allowed to be duplicates. E.g. you could have something like this:
# render -> effect 1 -.
#                     |-> combine
# render -> effect 2 -'
# where render is the same (name/task, inputs, outputs)
function Base.push!(pipeline::Pipeline, stage::Stage)
    push!(pipeline.stages, stage)
    return stage # for convenience
end
function Base.push!(pipeline::Pipeline, other::Pipeline)
    N = length(pipeline.stages); M = length(pipeline.formats)
    append!(pipeline.stages, other.stages)
    for ((stage_idx, io_idx), format_idx) in other.stageio2idx
        pipeline.stageio2idx[(stage_idx + N, io_idx)] = M + format_idx
    end
    append!(pipeline.formats, other.formats)
    return other # for convenience
end


"""
    connect!(pipeline::Pipeline, source::Union{Pipeline, Stage}, target::Union{Pipeline, Stage})

Connects every output in `source` to every `input` in `target` that shares the
same name. For example, if `:a, :b, :c, :d` exist in source and `:b, :d, :e`
exist in target, `:b, :d` will get connected.
"""
function Observables.connect!(pipeline::Pipeline, src::Union{Pipeline, Stage}, trg::Union{Pipeline, Stage})
    stages(pipeline::Pipeline) = pipeline.stages
    stages(stage::Stage) = [stage]

    outputs = Set(mapreduce(stage -> keys(stage.outputs), union, stages(src)))
    inputs = Set(mapreduce(stage -> keys(stage.inputs), union, stages(trg)))
    for key in intersect(outputs, inputs)
        connect!(pipeline, src, trg, key)
    end
    return
end
function Observables.connect!(pipeline::Pipeline, src::Union{Pipeline, Stage, Integer}, trg::Union{Pipeline, Stage, Integer}, key::Symbol)
    return connect!(pipeline, src, key, trg, key)
end

# TODO: Not sure about this... Maybe it should be first/last instead? But what
#       then it wouldn't really work with e.g. SSAO, which needs color as an
#       input in step 2.
"""
    connect!(pipeline, source, output, target, input)

Connects an `output::Union{Symbol, Integer}` from `source::Union{Stage, Integer}`
to an `input` of `target`. If either already has a connection the new connection
will be merged with the old. The source and target stage as well as the pipeline
will be updated appropriately.

`source` and `target` can also be `Pipeline`s if both output and input are
`Symbol`s. In this case every stage in source with an appropriately named output
is connected to every stage in target with an appropriately named input. Use with
caution.
"""
function Observables.connect!(pipeline::Pipeline,
        src::Union{Pipeline, Stage}, output::Symbol,
        trg::Union{Pipeline, Stage}, input::Symbol
    )

    iterable(pipeline::Pipeline) = pipeline.stages
    iterable(stage::Stage) = Ref(stage)

    for source in iterable(src)
        if haskey(source.outputs, output)
            output_idx = source.outputs[output]
            for target in iterable(trg)
                if haskey(target.inputs, input)
                    input_idx = target.inputs[input]
                    connect!(pipeline, source, output_idx, target, input_idx)
                end
            end
        end
    end

    return
end

function Observables.connect!(pipeline::Pipeline, src::Integer, output::Symbol, trg::Integer, input::Symbol)
    return connect!(pipeline, src, output, trg, input)
end
function Observables.connect!(pipeline::Pipeline, source::Stage, output::Integer, target::Stage, input::Integer)
    src = findfirst(x -> x === source, pipeline.stages)
    trg = findfirst(x -> x === target, pipeline.stages)
    return connect!(pipeline, src, output, trg, input)
end

function Observables.connect!(pipeline::Pipeline, source::Stage, output::Symbol, target::Stage, input::Symbol)
    haskey(source.outputs, output) || error("output $output does not exist in source stage")
    haskey(target.inputs, input) || error("input $input does not exist in target stage")
    output_idx = source.outputs[output]
    input_idx = target.inputs[input]
    return connect!(pipeline, source, output_idx, target, input_idx)
end

function Observables.connect!(pipeline::Pipeline, src::Integer, output::Integer, trg::Integer, input::Integer)
    @boundscheck begin
        checkbounds(pipeline.stages, src)
        checkbounds(pipeline.stages, trg)
    end

    @boundscheck begin
        checkbounds(pipeline.stages[src].output_formats, output)
        checkbounds(pipeline.stages[trg].input_formats, input)
    end

    # Don't make a new connection if the connection already exists
    # (the format must be correct if it exists)
    if get(pipeline.stageio2idx, (src, output), 0) ===
        get(pipeline.stageio2idx, (trg, -input), -1)
        return
    end

    # format for the requested connection
    format = BufferFormat(pipeline.stages[src].output_formats[output], pipeline.stages[trg].input_formats[input])

    # Resolve format and update existing connection of src & trg
    if haskey(pipeline.stageio2idx, (src, output))
        # at least src exists, update format
        format_idx = pipeline.stageio2idx[(src, output)]
        format = BufferFormat(pipeline.formats[format_idx], format)
        pipeline.formats[format_idx] = format

        if haskey(pipeline.stageio2idx, (trg, -input))
            # both exist - update
            other_idx = pipeline.stageio2idx[(src, output)]
            format = BufferFormat(pipeline.formats[other_idx], format)
            # replace format of lower index
            format_idx, other_idx = minmax(format_idx, other_idx)
            pipeline.formats[format_idx] = format
            # connect higher index to format and adjust later indices
            for (k, v) in pipeline.stageio2idx
                pipeline.stageio2idx[k] = ifelse(v == other_idx, format_idx, ifelse(v > other_idx, v - 1, v))
            end
            # remove orphaned format
            deleteat!(pipeline.formats, other_idx)
        else
            # src exists, trg doesn't -> connect trg
            pipeline.stageio2idx[(trg, -input)] = format_idx
        end

    elseif haskey(pipeline.stageio2idx, (trg, -input))

        # src doesn't exist, trg does, modify target and connect src
        format_idx = pipeline.stageio2idx[(trg, -input)]
        format = BufferFormat(pipeline.formats[format_idx], format)
        pipeline.formats[format_idx] = format
        pipeline.stageio2idx[(src, output)] = format_idx

    else

        # neither exists, add new and connect both
        push!(pipeline.formats, format)
        pipeline.stageio2idx[(src, output)] = length(pipeline.formats)
        pipeline.stageio2idx[(trg, -input)] = length(pipeline.formats)

    end

    return
end

format_complexity(f::BufferFormat) = format_complexity(f.dims, f.type)
format_complexity(dims, type) = dims * BFT.bytesize(type)
# complexity of merged, not max of either
format_complexity(f1::BufferFormat, f2::BufferFormat) = max(f1.dims, f2.dims) * max(BFT.bytesize(f1.type), BFT.bytesize(f2.type))

"""
    generate_buffers(pipeline)

Maps the connections in the given pipeline to a vector of buffer formats and
returns them together with a connection-to-index map. This will attempt to
optimize buffers for the lowest memory overhead. I.e. it will reuse buffers for
multiple connections and upgrade them if it is cheaper than creating a new one.
"""
function generate_buffers(pipeline::Pipeline)
    # Verify that outputs are continuously connected (i.e. if N then 1..N-1 as well)
    output_max = zeros(Int, length(pipeline.stages))
    output_sum = zeros(Int, length(pipeline.stages))
    for (stage_idx, io_idx) in keys(pipeline.stageio2idx)
        io_idx > 0 || continue # inputs irrelevant
        output_max[stage_idx] = max(output_max[stage_idx], io_idx)
        output_sum[stage_idx] = output_sum[stage_idx] + io_idx # or use max(0, io_idx) and skip continue?
    end
    # sum must be 1 + 2 + ... + n = n(n+1)/2
    for i in eachindex(output_sum)
        s = output_sum[i]; m = output_max[i]
        if s != div(m*(m+1), 2)
            error("Stage $i has an incomplete set of output connections.")
        end
    end

    # Group connections that exist between stages
    endpoints = [(999_999, 0) for _ in pipeline.formats]
    for ((stage_idx, io_idx), format_idx) in pipeline.stageio2idx
        start, stop = endpoints[format_idx]
        start = min(start, stage_idx + (io_idx < 0) * 999_999) # always pick start if stage_idx is input
        stop = max(stop, (io_idx < 0) * stage_idx - 1) # pick stop if io_idx is output
        endpoints[format_idx] = (start, stop)
    end
    filter!(x -> x != (999_999, 0), endpoints)

    usage_per_transfer = [Int[] for _ in 1:length(pipeline.stages)-1]
    for (conn_idx, (start, stop)) in enumerate(endpoints)
        start <= stop || error("Connection $conn_idx is read before it is written to. $start $stop")
        for i in start:stop
            push!(usage_per_transfer[i], conn_idx)
        end
    end

    buffers = BufferFormat[]
    conn2merged = fill(-1, length(pipeline.formats))
    needs_buffer = Int[]
    available = Int[]

    # Let's simplify to get correct behavior first...

    for i in eachindex(usage_per_transfer)
        # prepare:
        # - collect connections without buffers
        # - collect available buffers (not in use now or last iteration)
        copyto!(resize!(available, length(buffers)), eachindex(buffers))
        empty!(needs_buffer)
        for j in max(1, i-1):i
        # for j in i:min(length(usage_per_transfer), i+1) # reverse
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
                    # - using it is cheaper than creating a new buffer
                    # - it is more compatible than the last when both are 0 cost
                    #   (i.e prefer 3, Float16 over 3 Float8 for 3 Float16 target)
                    updated_comp = format_complexity(buffers[i], conn_format)
                    buffer_comp = format_complexity(buffers[i])
                    delta = updated_comp - buffer_comp
                    is_cheaper = (delta < prev_delta) && (delta <= conn_comp)
                    more_compatible = (delta == prev_delta == 0) && (buffer_comp < prev_comp)
                    if is_cheaper || more_compatible
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


################################################################################
### show
################################################################################


function Base.show(io::IO, format::BufferFormat)
    print(io, "BufferFormat($(format.dims), $(format.type)")
    for (k, v) in format.extras
        print(io, ", :", k, " => ", v)
    end
    print(io, ")")
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

function Base.show(io::IO, ::MIME"text/plain", pipeline::Pipeline)
    return show_resolved(io, pipeline, pipeline.formats, collect(eachindex(pipeline.formats)))
end

function show_resolved(pipeline::Pipeline, buffers, remap)
    return show_resolved(stdout, pipeline, buffers, remap)
end

function show_resolved(io::IO, pipeline::Pipeline, buffers, remap)
    println(io, "Pipeline():")
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


################################################################################
### Defaults
################################################################################


SortStage() = Stage(:ZSort)

function RenderStage(; kwargs...)
    outputs = Dict(:color => 1, :objectid => 2, :position => 3, :normal => 4)
    output_formats = [BufferFormat(4, N0f8), BufferFormat(2, UInt32), BufferFormat(3, Float16), BufferFormat(3, Float16)]
    return Stage(:Render, Dict{Symbol, Int}(), BufferFormat[], outputs, output_formats; kwargs...)
end

function TransparentRenderStage()
    outputs = Dict(:weighted_color_sum => 1, :objectid => 2, :alpha_product => 3)
    output_formats = [BufferFormat(4, Float16), BufferFormat(2, UInt32), BufferFormat(1, N0f8)]
    return Stage(:TransparentRender, Dict{Symbol, Int}(), BufferFormat[], outputs, output_formats)
end

function SSAOStage(; kwargs...)
    inputs = Dict(:position => 1, :normal => 2)
    input_formats = [BufferFormat(3, Float32), BufferFormat(3, Float16)]
    stage1 = Stage(:SSAO1, inputs, input_formats, Dict(:occlusion => 1), [BufferFormat(1, N0f8)]; kwargs...)

    inputs = Dict(:occlusion => 1, :color => 2, :objectid => 3)
    input_formats = [BufferFormat(1, N0f8), BufferFormat(4, N0f8), BufferFormat(2, UInt32)]
    stage2 = Stage(:SSAO2, inputs, input_formats, Dict(:color => 1), [BufferFormat()]; kwargs...)

    pipeline = Pipeline(stage1, stage2)
    connect!(pipeline, stage1, 1, stage2, 1)

    return pipeline
end

function OITStage(; kwargs...)
    inputs = Dict(:weighted_color_sum => 1, :alpha_product => 2)
    input_formats = [BufferFormat(4, Float16), BufferFormat(1, N0f8)]
    outputs = Dict(:color => 1)
    output_formats = [BufferFormat(4, N0f8)]
    return Stage(:OIT, inputs, input_formats, outputs, output_formats; kwargs...)
end

function FXAAStage(; kwargs...)
    stage1 = Stage(:FXAA1,
        Dict(:color => 1, :objectid => 2), [BufferFormat(4, N0f8), BufferFormat(2, UInt32)],
        Dict(:color_luma => 1), [BufferFormat(4, N0f8)]; kwargs...
    )

    stage2 = Stage(:FXAA2,
        Dict(:color_luma => 1), [BufferFormat(4, N0f8, minfilter = :linear)],
        Dict(:color => 1), [BufferFormat(4, N0f8)]; kwargs...
    )

    pipeline = Pipeline(stage1, stage2)
    connect!(pipeline, stage1, 1, stage2, 1)

    return pipeline
end

function DisplayStage()
    return Stage(:Display,
        Dict(:color => 1, :objectid => 2), [BufferFormat(4, N0f8), BufferFormat(2, UInt32)],
        Dict{Symbol, Int}(), BufferFormat[])
end


# TODO: caching is dangerous with mutable attributes...
const PIPELINE_CACHE = Dict{Symbol, Pipeline}()

function default_pipeline(; ssao = false, fxaa = true, oit = true)
    name = Symbol(:default_pipeline, Int(ssao), Int(fxaa), Int(oit))

    # Mimic GLMakie's old hard coded render pipeline
    get!(PIPELINE_CACHE, name) do

        pipeline = Pipeline()
        push!(pipeline, SortStage())

        # Note - order important!
        # TODO: maybe add insert!()?
        if ssao
            render1 = push!(pipeline, RenderStage(ssao = true, transparency = false))
            _ssao = push!(pipeline, SSAOStage())
            render2 = push!(pipeline, RenderStage(ssao = false, transparency = false))
        else
            render2 = push!(pipeline, RenderStage(transparency = false))
        end
        if oit
            render3 = push!(pipeline, TransparentRenderStage())
            _oit = push!(pipeline, OITStage())
        else
            render3 = push!(pipeline, RenderStage(transparency = true))
        end
        if fxaa
            _fxaa = push!(pipeline, FXAAStage(filter_in_shader = true))
        end
        display = push!(pipeline, DisplayStage())


        if ssao
            connect!(pipeline, render1, _ssao)
            connect!(pipeline, render1, display, :objectid)
            connect!(pipeline, _ssao, fxaa ? _fxaa : display, :color)
        end
        connect!(pipeline, render2, fxaa ? _fxaa : display)
        connect!(pipeline, render2, display, :objectid) # make sure this merges with other objectids
        if oit
            connect!(pipeline, render3, _oit)
            connect!(pipeline, _oit, fxaa ? _fxaa : display, :color)
        else
            connect!(pipeline, render3, fxaa ? _fxaa : display, :color)
        end
        connect!(pipeline, render3, display, :objectid)
        if fxaa
            connect!(pipeline, _fxaa, display, :color)
        end

        return pipeline
    end
end

function test_pipeline_3D()
    pipeline = Pipeline()

    render1 = push!(pipeline, RenderStage(ssao = true, transparency = false, fxaa = true))
    ssao = push!(pipeline, SSAOStage())
    render2 = push!(pipeline, RenderStage(ssao = false, transparency = false, fxaa = true))
    render3 = push!(pipeline, TransparentRenderStage())
    oit = push!(pipeline, OITStage())
    fxaa = push!(pipeline, FXAAStage(filter_in_shader = false))
    # dedicated fxaa = false render improves sdf (lines, scatter, text) intersections with FXAA
    render4 = push!(pipeline, RenderStage(transparency = false, fxaa = false))
    display = push!(pipeline, DisplayStage())

    connect!(pipeline, render1, ssao)
    connect!(pipeline, render1, fxaa,    :objectid)
    connect!(pipeline, render1, display, :objectid)
    connect!(pipeline, ssao,    fxaa,    :color)
    connect!(pipeline, render2, fxaa,    :color)
    connect!(pipeline, render2, display, :objectid)
    connect!(pipeline, render3, oit)
    connect!(pipeline, render3, display, :objectid)
    connect!(pipeline, oit,     fxaa,    :color)
    connect!(pipeline, fxaa,    display, :color)
    connect!(pipeline, render4, display)

    return pipeline
end

function test_pipeline_2D()
    pipeline = Pipeline()

    # dedicated fxaa = false pass + no SSAO
    render1 = push!(pipeline, RenderStage(transparency = false, fxaa = true))
    render2 = push!(pipeline, TransparentRenderStage())
    oit = push!(pipeline, OITStage())
    fxaa = push!(pipeline, FXAAStage(filter_in_shader = false))
    render3 = push!(pipeline, RenderStage(transparency = false, fxaa = false))
    display = push!(pipeline, DisplayStage())

    connect!(pipeline, render1, fxaa)
    connect!(pipeline, render1, display, :objectid)
    connect!(pipeline, render2, oit)
    connect!(pipeline, render2, display, :objectid)
    connect!(pipeline, oit,     fxaa,    :color)
    connect!(pipeline, fxaa,    display, :color)
    connect!(pipeline, render3, display)

    return pipeline
end

function test_pipeline_GUI()
    pipeline = Pipeline()

    # GUI elements don't need OIT because they are (usually?) layered plot by
    # plot, rather than element by element. Do need FXAA occasionally, e.g. Toggle
    render1 = push!(pipeline, RenderStage(fxaa = true))
    fxaa = push!(pipeline, FXAAStage(filter_in_shader = false))
    render2 = push!(pipeline, RenderStage(fxaa = false))
    display = push!(pipeline, DisplayStage())

    connect!(pipeline, render1, display)
    connect!(pipeline, render1, fxaa)
    connect!(pipeline, fxaa, display)
    connect!(pipeline, render2, display)

    return pipeline
end

function test_pipeline_minimal()
    pipeline = Pipeline()

    # GUI elements don't need OIT because they are (usually?) layered plot by
    # plot, rather than element by element. Do need FXAA occasionally, e.g. Toggle
    render = push!(pipeline, RenderStage())
    display = push!(pipeline, DisplayStage())
    connect!(pipeline, render, display)

    return pipeline
end

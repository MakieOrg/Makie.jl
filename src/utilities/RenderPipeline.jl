# Note: This file could easily be moved out into a mini-package.

import FixedPointNumbers: N0f8

# TODO: try `BufferFormat{T} ... type::Type{T}` for better performance?
# TODO: consider adding a "immediately reusable" flag here or to Stage so that
#       Stage can communicate that it allows output = input
struct BufferFormat
    dims::Int
    type::DataType
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
    if is_compatible(f1, f2)
        dims = max(f1.dims, f2.dims)
        T1 = f1.type; T2 = f2.type
        type = if T1 == T2;                         T1
        elseif (T1 == Float32) || (T2 == Float32);  Float32
        elseif (T1 == Float16) || (T2 == Float16);  Float16
        elseif (T1 == N0f8)  || (T2 == N0f8);       N0f8
        elseif (T1 == Int32) || (T2 == Int32);      Int32
        elseif (T1 == Int16) || (T2 == Int16);      Int16
        elseif (T1 == Int8)  || (T2 == Int8);       Int8
        elseif (T1 == UInt32) || (T2 == UInt32);    UInt32
        elseif (T1 == UInt16) || (T2 == UInt16);    UInt16
        elseif (T1 == UInt8)  || (T2 == UInt8);     UInt8
        else error("Failed to merge BufferFormat: Types $T1 and $T2 are not allowed.")
        end
        extras = copy(f1.extras)
        for (k, v) in f2.extras
            get!(extras, k, v) == v || error("Failed to merge BufferFormat: Extra requirement $(extras[k]) != $v.")
        end
        return BufferFormat(dims, type, extras)
    else
        error("Failed to merge BufferFormat: $f1 and $f2 are not compatible.")
    end
end


function is_compatible(f1::BufferFormat, f2::BufferFormat)
    # About 10% faster for default_SSAO_pipeline() (with no caching) than
    # is_compatible(f1.type, f2.type), but still does runtime dispatch on ==
    T1 = f1.type
    T2 = f2.type
    return (
        ((T1 == N0f8) || (T1 == Float16) || (T1 == Float32)) &&
        ((T2 == N0f8) || (T2 == Float16) || (T2 == Float32))
    ) || (
        ((T1 == Int8) || (T1 == Int16) || (T1 == Int32)) &&
        ((T2 == Int8) || (T2 == Int16) || (T2 == Int32))
    ) || (
        ((T1 == UInt8) || (T1 == UInt16) || (T1 == UInt32)) &&
        ((T2 == UInt8) || (T2 == UInt16) || (T2 == UInt32))
    )
end

# Connections can have multiple inputs and outputs
# e.g. multiple Renders write to objectid and FXAA, SSAO, Display/pick read it
struct ConnectionT{T}
    inputs::Vector{Pair{T, Int}}
    outputs::Vector{Pair{T, Int}}
    format::BufferFormat # derived from inputs & outputs formats
end

struct Stage
    name::Symbol

    # order matters for outputs
    # these are "const" after init
    inputs::Dict{Symbol, Int}
    outputs::Dict{Symbol, Int}
    input_formats::Vector{BufferFormat}
    output_formats::Vector{BufferFormat}

    # "const" after setting up connections
    input_connections::Vector{ConnectionT{Stage}}
    output_connections::Vector{ConnectionT{Stage}}

    # const for caching (which does quite a lot actually)
    attributes::NamedTuple
end

const Connection = ConnectionT{Stage}

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
        Connection[], Connection[],
        NamedTuple{keys(kwargs)}(values(kwargs))
    )
end

get_input_connection(stage::Stage, key::Symbol) = stage.input_connections[stage.inputs[key]]
get_output_connection(stage::Stage, key::Symbol) = stage.output_connections[stage.outputs[key]]
get_input_format(stage::Stage, key::Symbol) = stage.input_formats[stage.inputs[key]]
get_output_format(stage::Stage, key::Symbol) = stage.output_formats[stage.outputs[key]]

"""
    Connection(source::Stage, output::Integer, target::Stage, input::Integer)

Creates a `Connection` between the `output` of a `source` stage and the `input`
of a `target` Stage. The `output` and `input` can be either the name of that
output/input or the index.

Note: This constructor does not update the given stages or make any checks. It
should be considered internal. Use `connect!()` instead.
"""
function Connection(source::Stage, input::Integer, target::Stage, output::Integer)
    format = BufferFormat(source.output_formats[input], target.input_formats[output])
    return Connection([source => input], [target => output], format)
end

struct Pipeline
    stages::Vector{Stage}
    connections::Vector{Connection}
end

"""
    Pipeline([stages::Stage...])

Creates a `Pipeline` from the given `stages` or an empty pipeline if none are
given. The pipeline represents a series of actions (stages) executed during
rendering.
"""
function Pipeline()
    return Pipeline(Stage[], Connection[])
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
    isempty(stage.input_connections) || error("Pushed stage $(stage.name) must not have input connections.")
    isempty(stage.output_connections) || error("Pushed stage $(stage.name) must not have output connections.")
    push!(pipeline.stages, stage)
    return stage # for convenience
end
function Base.push!(pipeline::Pipeline, other::Pipeline)
    append!(pipeline.stages, other.stages)
    append!(pipeline.connections, other.connections)
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
    function sources(pipeline::Pipeline, output)
        return [(stage, stage.outputs[output]) for stage in pipeline.stages if haskey(stage.outputs, output)]
    end
    sources(stage::Stage, output) = [(stage, stage.outputs[output])]

    function targets(pipeline::Pipeline, input)
        return [(stage, stage.inputs[input]) for stage in pipeline.stages if haskey(stage.inputs, input)]
    end
    targets(stage::Stage, input) = [(stage, stage.inputs[input])]

    for (source, output_idx) in sources(src, output)
        for (target, input_idx) in targets(trg, input)
            @inbounds connect!(pipeline, source, output_idx, target, input_idx)
        end
    end

    return
end

function Observables.connect!(pipeline::Pipeline, src::Integer, output::Symbol, trg::Integer, input::Symbol)
    return connect!(pipeline, pipeline.stages[src], output, pipeline.stages[trg], input)
end
function Observables.connect!(pipeline::Pipeline, src::Integer, output::Integer, trg::Integer, input::Integer)
    return connect!(pipeline, pipeline.stages[src], output, pipeline.stages[trg], input)
end

function Observables.connect!(pipeline::Pipeline, source::Stage, output::Symbol, target::Stage, input::Symbol)
    haskey(source.outputs, output) || error("output $output does not exist in source stage")
    haskey(target.inputs, input) || error("input $input does not exist in target stage")
    output_idx = source.outputs[output]
    input_idx = target.inputs[input]
    return @inbounds connect!(pipeline, source, output_idx, target, input_idx)
end

function Observables.connect!(pipeline::Pipeline,
        source::Stage, output_idx::Integer, target::Stage, input_idx::Integer)

    @boundscheck begin
        checkbounds(source.output_formats, output_idx)
        checkbounds(target.input_formats, input_idx)
    end

    # resize if too small (this allows later connections to be skipped)
    if length(source.output_connections) < output_idx
        resize!(source.output_connections, output_idx)
    end
    if length(target.input_connections) < input_idx
        resize!(target.input_connections, input_idx)
    end

    # Don't make a new connection if the connection already exists
    # (the format must be correct if it exists)
    if isassigned(source.output_connections, output_idx) &&
        isassigned(target.input_connections, input_idx) &&
        (source.output_connections[output_idx] === target.input_connections[input_idx])
        return source.output_connections[output_idx]
    end

    function unsafe_merge(c1::Connection, c2::Connection)
        for (stage, idx) in c2.inputs
            any(kv -> kv[1] === stage, c1.inputs) || push!(c1.inputs, stage => idx)
        end
        for (stage, idx) in c2.outputs
            any(kv -> kv[1] === stage, c1.outputs) || push!(c1.outputs, stage => idx)
        end

        return Connection(c1.inputs, c1.outputs, BufferFormat(c1.format, c2.format))
    end

    # create requested connection
    connection = Connection(source, output_idx, target, input_idx)

    # if the input or output already has an edge, merge it with the create edge
    # e.g. the color output of source is used for a second stage
    # or   the color input of target is written to by second stage
    if isassigned(source.output_connections, output_idx)
        old = source.output_connections[output_idx]
        # There should be exactly one matching connection, and it's probably
        # near the end?
        idx = findlast(c -> c === old, pipeline.connections)::Int
        deleteat!(pipeline.connections, idx)
        connection = unsafe_merge(connection, old)
    end
    if isassigned(target.input_connections, input_idx)
        old = target.input_connections[input_idx]
        idx = findlast(c -> c === old, pipeline.connections)::Int
        deleteat!(pipeline.connections, idx)
        connection = unsafe_merge(connection, old)
    end

    # attach connection to every input and output
    for (stage, idx) in connection.inputs
        stage.output_connections[idx] = connection
    end
    for (stage, idx) in connection.outputs
        stage.input_connections[idx] = connection
    end

    push!(pipeline.connections, connection)

    return connection
end

# This checks that no connection goes backwards, i.e. every connection is written
# to before being read.
function verify(pipeline::Pipeline)
    for connection in pipeline.connections
        earliest_input = length(pipeline.stages)
        for (stage, _) in connection.inputs
            idx = findfirst(==(stage), pipeline.stages)
            isnothing(idx) && error("Could not find $(stage.name) in pipeline.")
            earliest_input = min(earliest_input, idx)
        end

        earliest_output = length(pipeline.stages)
        for (stage, _) in connection.outputs
            idx = findfirst(==(stage), pipeline.stages)
            isnothing(idx) && error("Could not find $(stage.name) in pipeline.")
            earliest_output = min(earliest_output, idx)
        end

        if earliest_input >= earliest_output
            inputs = join(("$(stage.name).$idx" for (stage, idx) in connection.inputs), ", ")
            outputs = join(("$(stage.name).$idx" for (stage, idx) in connection.outputs), ", ")
            error("Connection ($inputs) -> ($outputs) is read before being written to. Not allowed. ($earliest_input ≥ $earliest_output)")
        end
    end

    return true
end

"""
    generate_buffers(pipeline)

Maps the connections in the given pipeline to a vector of buffer formats and
returns them together with a connection-to-index map. This will attempt to
optimize buffers for the lowest memory overhead. I.e. it will reuse buffers for
multiple connections and upgrade them if it is cheaper than creating a new one.
"""
function generate_buffers(pipeline::Pipeline)
    format_complexity(c::Connection) = format_complexity(c.format)
    format_complexity(f::BufferFormat) = f.dims * sizeof(f.type)

    verify(pipeline)

    # We can make this more efficient later...
    stage2idx = Dict([stage => i for (i, stage) in enumerate(pipeline.stages)])

    # Group connections that exist between stages
    usage_per_transfer = [Connection[] for _ in 1:length(pipeline.stages)-1]
    for connection in pipeline.connections
        first = mapreduce(kv -> stage2idx[kv[1]], min, connection.inputs)
        last = mapreduce(kv -> stage2idx[kv[1]]-1, max, connection.outputs)
        for i in first:last
            push!(usage_per_transfer[i], connection)
        end
    end

    buffers = BufferFormat[]
    connection2idx = Dict{Connection, Int}() # into buffer
    needs_buffer = Connection[]
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
            for connection in usage_per_transfer[j]
                if haskey(connection2idx, connection)
                    idx = connection2idx[connection]
                    filter!(!=(idx), available)
                elseif j == i
                    push!(needs_buffer, connection)
                end
            end
        end

        # Handle most expensive connections first
        sort!(needs_buffer, by = format_complexity, rev = true)

        for connection in needs_buffer
            # search for most compatible buffer
            best_match = 0
            prev_comp = 999999
            prev_delta = 999999
            conn_comp = format_complexity(connection.format)
            for i in available
                if buffers[i] == connection.format # exact match
                    best_match = i
                    break
                elseif is_compatible(buffers[i], connection.format)
                    # found compatible buffer, but we only use it if
                    # - using it is cheaper than using the last
                    # - using it is cheaper than creating a new buffer
                    # - it is more compatible than the last when both are 0 cost
                    #   (i.e prefer 3, Float16 over 3 Float8 for 3 Float16 target)
                    updated_comp = format_complexity(BufferFormat(buffers[i], connection.format))
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
                push!(buffers, connection.format)
                best_match = length(buffers)
            elseif buffers[best_match] != connection.format
                # found upgradeable format, upgrade it (or use it)
                new_format = BufferFormat(buffers[best_match], connection.format)
                buffers[best_match] = new_format
            end

            # Link to new found or upgraded format
            connection2idx[connection] = best_match

            # Can't use a buffer twice in one transfer
            filter!(!=(best_match), available)
        end
    end

    return buffers, connection2idx
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
            mark = isassigned(stage.input_connections, i) ? 'x' : ' '
            print(io, "\n  [$mark] ", lpad(string(k), pad), "::", stage.input_formats[i])
        end
    end

    if !isempty(stage.outputs)
        print(io, "\noutputs:")
        ks = collect(keys(stage.outputs))
        sort!(ks, by = k -> stage.outputs[k])
        pad = mapreduce(k -> length(string(k)), max, ks)
        for (i, k) in enumerate(ks)
            mark = isassigned(stage.output_connections, i) ? 'x' : ' '
            print(io, "\n  [$mark] ", lpad(string(k), pad), "::", stage.output_formats[i])
        end
    end

    return
end

function _names(connection::Connection)
    names = Set{Symbol}()
    for (stage, idx) in connection.inputs
        for (k, i) in stage.outputs
            if idx == i
                push!(names, k)
                break
            end
        end
    end
    for (stage, idx) in connection.outputs
        for (k, i) in stage.inputs
            if idx == i
                push!(names, k)
                break
            end
        end
    end
    return collect(names)
end

function Base.show(io::IO, connection::Connection)
    names = _names(connection)
    print(io, "Connection(")
    if length(names) == 1
        print(io, names[1])
    else
        print(io, names)
    end
    print(io, " -> $(connection.format))")
end

function Base.show(io::IO, ::MIME"text/plain", connection::Connection)
    print(io, "Connection($(connection.format))")

    if !isempty(connection.inputs)
        print(io, "\ninputs:")
        elements = map(connection.inputs) do (stage, idx)
            key = :temp
            for (k, i) in stage.outputs
                if idx == i
                    key = k
                    break
                end
            end
            return (string(stage.name), string(key), stage.output_formats[idx])
        end
        pad1 = mapreduce(x -> length(x[1]), max, elements)
        pad2 = mapreduce(x -> length(x[2]), max, elements)
        for (name, key, format) in elements
            print(io, "\n  ", rpad(name, pad1), " -> ", lpad(key, pad2), "::", format)
        end
    end

    if !isempty(connection.outputs)
        print(io, "\noutputs:")
        elements = map(connection.outputs) do (stage, idx)
            key = :temp
            for (k, i) in stage.inputs
                if idx == i
                    key = k
                    break
                end
            end
            return (string(stage.name), string(key), stage.input_formats[idx])
        end
        pad1 = mapreduce(x -> length(x[1]), max, elements)
        pad2 = mapreduce(x -> length(x[2]), max, elements)
        for (name, key, format) in elements
            print(io, "\n  ", rpad(name, pad1), " -> ", lpad(key, pad2), "::", format)
        end
    end

    return
end

function Base.show(io::IO, ::MIME"text/plain", pipeline::Pipeline)
    conn2idx = Dict{Connection, Int}([c => i for (i, c) in enumerate(pipeline.connections)])
    return show_resolved(io, pipeline, pipeline.connections, conn2idx)
end
function show_resolved(pipeline::Pipeline, buffers, conn2idx::Dict{Connection, Int})
    return show_resolved(stdout, pipeline, buffers, conn2idx)
end
function show_resolved(io::IO, pipeline::Pipeline, buffers, conn2idx::Dict{Connection, Int})
    println(io, "Pipeline():")
    print(io, "Stages:")
    pad = 1 + floor(Int, log10(length(buffers)))

    for stage in pipeline.stages
        print(io, "\n  Stage($(stage.name))")
        if !isempty(stage.input_connections)
            print(io, "\n    inputs: ")
            # keep order
            strs = map(eachindex(stage.input_connections)) do i
                k = findfirst(==(i), stage.inputs)
                c = stage.input_connections[i]
                ci = string(conn2idx[c])
                return "[$ci] $k"
            end
            join(io, strs, ", ")
        end
        if !isempty(stage.output_connections)
            print(io, "\n    outputs: ")
            strs = map(eachindex(stage.output_connections)) do i
                k = findfirst(==(i), stage.outputs)
                c = stage.output_connections[i]
                ci = string(conn2idx[c])
                return "[$ci] $k"
            end
            join(io, strs, ", ")
        end
    end

    println(io, "\nConnections:")
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

function FXAAStage()
    inputs = Dict(:color => 1, :objectid => 2)
    input_formats = [BufferFormat(4, N0f8), BufferFormat(2, UInt32)]
    stage1 = Stage(:FXAA1, inputs, input_formats, Dict(:color_luma => 1), [BufferFormat(4, N0f8)])

    stage2 = Stage(:FXAA2,
        Dict(:color_luma => 1), [BufferFormat(4, N0f8, minfilter = :linear)],
        Dict(:color => 1), [BufferFormat(4, N0f8)]
    )

    pipeline = Pipeline(stage1, stage2)
    connect!(pipeline, stage1, 1, stage2, 1)

    return pipeline
end

function DisplayStage()
    inputs = Dict(:color => 1, :objectid => 2)
    input_formats = [BufferFormat(4, N0f8), BufferFormat(2, UInt32)]
    return Stage(:Display, inputs, input_formats, Dict{Symbol, Int}(), BufferFormat[])
end


# TODO: caching is dangerous with mutable attributes...
const PIPELINE_CACHE = Dict{Symbol, Pipeline}()

function default_SSAO_pipeline()
    return get!(PIPELINE_CACHE, :default_SSAO_pipeline) do
        # matching master with SSAO enabled
        pipeline = Pipeline()

        push!(pipeline, SortStage())
        render1 = push!(pipeline, RenderStage(target = :SSAO))
        ssao = push!(pipeline, SSAOStage())
        render2 = push!(pipeline, RenderStage(target = :FXAA))
        render3 = push!(pipeline, TransparentRenderStage())
        oit = push!(pipeline, OITStage())
        fxaa = push!(pipeline, FXAAStage())
        display = push!(pipeline, DisplayStage())

        connect!(pipeline, render1, ssao)
        connect!(pipeline, render1, fxaa,    :objectid)
        connect!(pipeline, render1, display, :objectid)
        connect!(pipeline, ssao,    fxaa,    :color)
        connect!(pipeline, render2, fxaa,    :color)
        connect!(pipeline, render2, display, :objectid) # will get bundled so we don't need to repeat
        connect!(pipeline, render3, oit)
        connect!(pipeline, render3, display, :objectid)
        connect!(pipeline, oit,     fxaa,    :color)
        connect!(pipeline, fxaa,    display, :color)

        return pipeline
    end
end

function default_pipeline()
    return get!(PIPELINE_CACHE, :default_pipeline) do
        # matching master
        pipeline = Pipeline()

        push!(pipeline, SortStage())
        render1 = push!(pipeline, RenderStage(target = :FXAA))
        render2 = push!(pipeline, TransparentRenderStage())
        oit = push!(pipeline, OITStage())
        fxaa = push!(pipeline, FXAAStage())
        display = push!(pipeline, DisplayStage())

        connect!(pipeline, render1, fxaa)
        connect!(pipeline, render1, display, :objectid)
        connect!(pipeline, render2, oit)
        connect!(pipeline, render2, display, :objectid)
        connect!(pipeline, oit,  fxaa, :color)
        connect!(pipeline, fxaa, display, :color)

        return pipeline
    end
end

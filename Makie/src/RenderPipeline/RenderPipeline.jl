# This handles the higher level RenderPipeline representation. It contains
# multiple `Stage`s which each define the input and output formats they need.
# The main work here is connecting inputs and outputs of stages such that buffers
# get shared correctly. I.e. if two outputs connect to one input, they need to
# use a shared buffer.

struct Stage
    name::Symbol

    # input/output name -> index into input/output_formats
    # these are "const" after init
    inputs::Dict{Symbol, Int}
    outputs::Dict{Symbol, Int}

    # formats of inputs and outputs
    # order matters for stageio2idx in RenderPipeline
    # order matters for outputs also matters for OpenGL
    input_formats::Vector{BufferFormat}
    output_formats::Vector{BufferFormat}

    # Optional settings/uniforms
    attributes::Dict{Symbol, Any}
end

"""
    Stage(name::Symbol[; inputs = [], outputs = []; kwargs...)

Creates a new `Stage` from the given `name`, `inputs` and `outputs`. A `Stage`
represents an action taken during rendering, e.g. rendering (a subset of) render
objects, running a post processor or sorting render objects. Inputs and outputs
are given as a `Vector{Pair{Symbol, BufferFormat}}` containing their name and
data format. Keyword arguments are treated as attributes/settings for the stage
with the exception of `samples` which acts as an overwrite for all output formats.
"""
function Stage(name; inputs = Pair{Symbol, BufferFormat}[], outputs = Pair{Symbol, BufferFormat}[], kwargs...)
    return Stage(name, inputs, outputs; kwargs...)
end

function Stage(name, inputs::Vector, outputs::Vector; samples = 0, kwargs...)
    if samples > 0
        for i in eachindex(outputs)
            outputs[i] = outputs[i][1] => BufferFormat(outputs[i][2], samples = samples)
        end
    end

    return Stage(
        Symbol(name),
        Dict{Symbol, Int}([k => idx for (idx, (k, v)) in enumerate(inputs)]),
        BufferFormat[v for (k, v) in inputs],
        Dict{Symbol, Int}([k => idx for (idx, (k, v)) in enumerate(outputs)]),
        BufferFormat[v for (k, v) in outputs];
        kwargs...
    )
end

function Stage(name, inputs, input_formats, outputs, output_formats; samples = 0, kwargs...)
    if samples > 0
        for i in eachindex(output_formats)
            output_formats[i] = BufferFormat(output_formats[i], samples = samples)
        end
    end

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

struct RenderPipeline
    stages::Vector{Stage}

    # maps a stage input or output to an index into `formats`
    # input: (stage index, input/output index)
    # where negative indices are inputs, positive outputs
    stageio2idx::Dict{Tuple{Int, Int}, Int}

    # resolved buffer format of an edge connecting one or multiple inputs & outputs
    formats::Vector{BufferFormat}
end

"""
    RenderPipeline([stages::Stage...])

Creates a `RenderPipeline` from the given `stages` or an empty pipeline if none are
given. The pipeline represents a series of actions (stages) executed during
rendering.
"""
function RenderPipeline()
    return RenderPipeline(Stage[], Dict{Tuple{Int, Int}, Int}(), BufferFormat[])
end
function RenderPipeline(stages::Stage...)
    pipeline = RenderPipeline()
    foreach(stage -> push!(pipeline, stage), stages)
    return pipeline
end


# Stages are allowed to be duplicates. E.g. you could have something like this:
# render -> effect 1 -.
#                     |-> combine
# render -> effect 2 -'
# where render is the same (name/task, inputs, outputs)
function Base.push!(pipeline::RenderPipeline, stage::Stage)
    push!(pipeline.stages, stage)
    return stage # for convenience
end
function Base.push!(pipeline::RenderPipeline, stages::Stage...)
    for stage in stages
        push!(pipeline, stage)
    end
    return stages
end
function Base.push!(pipeline::RenderPipeline, other::RenderPipeline)
    N = length(pipeline.stages); M = length(pipeline.formats)
    append!(pipeline.stages, other.stages)
    for ((stage_idx, io_idx), format_idx) in other.stageio2idx
        pipeline.stageio2idx[(stage_idx + N, io_idx)] = M + format_idx
    end
    append!(pipeline.formats, other.formats)
    return other # for convenience
end

function get_connection_index(pipeline::RenderPipeline; from = nothing, to = nothing)
    if from !== nothing
        stage_index, name = from
        stage = pipeline.stages[stage_index]
        output_index = stage.outputs[name]
        return pipeline.stageio2idx[(stage_index, output_index)]
    elseif to !== nothing
        stage_index, name = to
        stage = pipeline.stages[stage_index]
        input_index = stage.inputs[name]
        return pipeline.stageio2idx[(stage_index, -input_index)]
    else
        error("Either `from` or `to` must be given as (stage index, input/output name).")
    end
end

function get_connection_buffer(pipeline::RenderPipeline; from = nothing, to = nothing)
    return pipeline.format[get_connection_index(pipeline; from, to)]
end


"""
    connect!(pipeline::RenderPipeline, source::Union{RenderPipeline, Stage}, target::Union{RenderPipeline, Stage})

Connects every output in `source` to every input in `target` that shares the
same name. For example, if `:a, :b, :c, :d` exist in source and `:b, :d, :e`
exist in target, `:b, :d` will get connected.
"""
function Observables.connect!(pipeline::RenderPipeline, src::Union{RenderPipeline, Stage}, trg::Union{RenderPipeline, Stage})
    stages(pipeline::RenderPipeline) = pipeline.stages
    stages(stage::Stage) = [stage]

    outputs = Set(mapreduce(stage -> keys(stage.outputs), union, stages(src)))
    inputs = Set(mapreduce(stage -> keys(stage.inputs), union, stages(trg)))
    for key in intersect(outputs, inputs)
        connect!(pipeline, src, trg, key)
    end
    return
end

"""
    connect!(pipeline::RenderPipeline, [source = pipeline, target = pipeline], name::Symbol)

Connects every output in `source` that uses the given `name` to every input in
`target` with the same `name`. `source` and `target` can be a pipeline, stage
or integer referring to stage in `pipeline`. If both are omitted inputs and
outputs from `pipeline` get connected.
"""
function Observables.connect!(pipeline::RenderPipeline, src::Union{RenderPipeline, Stage, Integer}, trg::Union{RenderPipeline, Stage, Integer}, key::Symbol)
    return connect!(pipeline, src, key, trg, key)
end
Observables.connect!(pipeline::RenderPipeline, key::Symbol) = connect!(pipeline, pipeline, key, pipeline, key)


"""
    connect!(pipeline, source, output, target, input)

Connects an `output::Union{Symbol, Integer}` from `source::Union{Stage, Integer}`
to an `input` of `target`. If either already has a connection the new connection
will be merged with the old. The source and target stage as well as the pipeline
will be updated appropriately.

`source` and `target` can also be `RenderPipeline`s if both output and input are
`Symbol`s. In this case every stage in source with an appropriately named output
is connected to every stage in target with an appropriately named input. Use with
caution.
"""
function Observables.connect!(
        pipeline::RenderPipeline,
        src::Union{RenderPipeline, Stage}, output::Symbol,
        trg::Union{RenderPipeline, Stage}, input::Symbol
    )

    iterable(pipeline::RenderPipeline) = pipeline.stages
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

function Observables.connect!(pipeline::RenderPipeline, src::Integer, output::Symbol, trg::Integer, input::Symbol)
    return connect!(pipeline, src, output, trg, input)
end
function Observables.connect!(pipeline::RenderPipeline, source::Stage, output::Integer, target::Stage, input::Integer)
    src = findfirst(x -> x === source, pipeline.stages)
    trg = findfirst(x -> x === target, pipeline.stages)
    return connect!(pipeline, src, output, trg, input)
end

function Observables.connect!(pipeline::RenderPipeline, source::Stage, output::Symbol, target::Stage, input::Symbol)
    haskey(source.outputs, output) || error("output $output does not exist in source stage")
    haskey(target.inputs, input) || error("input $input does not exist in target stage")
    output_idx = source.outputs[output]
    input_idx = target.inputs[input]
    return connect!(pipeline, source, output_idx, target, input_idx)
end

function Observables.connect!(pipeline::RenderPipeline, src::Integer, output::Integer, trg::Integer, input::Integer)
    @boundscheck begin
        checkbounds(pipeline.stages, src)
        checkbounds(pipeline.stages, trg)
    end

    @boundscheck begin
        checkbounds(pipeline.stages[src].output_formats, output)
        checkbounds(pipeline.stages[trg].input_formats, input)
    end

    # Don't make a new connection if the connection already exists
    # (the format has already been checked when this connection was created)
    if get(pipeline.stageio2idx, (src, output), 0) ===
            get(pipeline.stageio2idx, (trg, -input), -1)
        return
    end

    # (joint) format for the requested connection
    format = BufferFormat(
        pipeline.stages[src].output_formats[output],
        pipeline.stages[trg].input_formats[input]
    )

    # Resolve format and update existing connection of src & trg
    # I.e. check if there is already a connection associated with the source
    # output or target input and merge the new connection with it if it exists.
    # Otherwise create a new connection
    if haskey(pipeline.stageio2idx, (src, output))
        # at least src exists, update format
        format_idx = pipeline.stageio2idx[(src, output)]
        format = BufferFormat(pipeline.formats[format_idx], format)
        pipeline.formats[format_idx] = format

        if haskey(pipeline.stageio2idx, (trg, -input))
            # both exist - update
            other_idx = pipeline.stageio2idx[(trg, -input)]
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

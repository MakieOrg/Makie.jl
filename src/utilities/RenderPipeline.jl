using FixedPointNumbers
Float8 = N0f8

_promote_type(T1, T2) = promote_type(T1, T2)
# otherwise you get Float32 here... maybe there's a better solution for this?
# maybe just introduce struct Float8 end as a stand-in?
_promote_type(::Type{Float8}, ::Type{Float16}) = Float16
_promote_type(::Type{Float16}, ::Type{Float8}) = Float16


# TODO: consider adding a "reuse immediately" flag so Stage can communicate that
#       it allows output = input
struct Format
    dims::Int
    type::DataType
    Format(dims = 4, type = Float8) = new(dims, type)
end

function Format(input::Format, output::Format)
    if is_compatible(input, output)
        dims = max(input.dims, output.dims)
        type = _promote_type(input.type, output.type)
        return Format(dims, type)
    end
    error("Could not generate compatible Format between $input and $output")
end

function is_compatible(f1::Format, f2::Format)
    is_compatible_with(f1.type, f2.type) || is_compatible_with(f2.type, f1.type)
end

function is_compatible_with(f::Format, requirement::Format)
    return (f.dims <= requirement.dims) && is_compatible_with(f.type, requirement.type)
end

# given, required
is_compatible_with(::Type{<: Union{N0f8, Float16, Float32}}, ::Type{N0f8}) = true
is_compatible_with(::Type{<: Union{Float16, Float32}}, ::Type{Float16}) = true
is_compatible_with(::Type{Float32}, ::Type{Float32}) = true

is_compatible_with(::Type{<: Union{Int8, Int16, Int32}}, ::Type{Int8}) = true
is_compatible_with(::Type{<: Union{Int16, Int32}}, ::Type{Int16}) = true
is_compatible_with(::Type{Int32}, ::Type{Int32}) = true

is_compatible_with(::Type{<: Union{UInt8, UInt16, UInt32}}, ::Type{UInt8}) = true
is_compatible_with(::Type{<: Union{UInt16, UInt32}}, ::Type{UInt16}) = true
is_compatible_with(::Type{UInt32}, ::Type{UInt32}) = true

is_compatible_with(::Type, ::Type) = false


# Connections can have multiple inputs and outputs
# e.g. multiple Renders write to objectid and FXAA, SSAO, Display/pick read it
struct ConnectionT{T}
    inputs::Dict{T, Int}  # stage => output Index
    outputs::Dict{T, Int} # stage => input Index
    format::Format # derived from inputs & outputs formats
end

struct Stage
    name::Symbol

    # order matters for outputs
    inputs::Dict{Symbol, Int}
    outputs::Dict{Symbol, Int}
    input_formats::Vector{Format}
    output_formats::Vector{Format}
    # ^ technically all of these are constants

    # v these are not
    input_connections::Vector{ConnectionT{Stage}}
    output_connections::Vector{ConnectionT{Stage}}
end

const Connection = ConnectionT{Stage}

function Stage(name; inputs = NTuple{0, Pair{Symbol, Format}}(), outputs = NTuple{0, Pair{Symbol, Format}}())
    stage = Stage(Symbol(name),
        Dict{Symbol, Int}(), Dict{Symbol, Int}(),
        Format[], Format[],
        Connection[], Connection[]
    )
    foreach(enumerate(inputs)) do (i, (k, v))
        stage.inputs[k] = i
        push!(stage.input_formats, v)
    end
    foreach(enumerate(outputs)) do (i, (k, v))
        stage.outputs[k] = i
        push!(stage.output_formats, v)
    end
    return stage
end

function Connection(source::Stage, input::Integer, target::Stage, output::Integer)
    format = Format(source.output_formats[input], target.input_formats[output])
    return Connection(Dict(source => input), Dict(target => output), format)
end

function Base.merge(c1::Connection, c2::Connection)
    return Connection(
        merge!(c1.inputs, c2.inputs),
        merge!(c1.outputs, c2.outputs),
        Format(c1.format, c2.format)
    )
end

function Base.hash(stage::Stage, h::UInt)
    # inputs, outputs are static after init
    # connections are not, and should not be relevant to identifying a stage
    return hash(stage.name, hash(stage.inputs, hash(stage.outputs, h)))
end

struct Pipeline
    stages::Vector{Stage}
    connections::Vector{Connection}
end
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
    return other.stages # for convernience
end


# function connect!(source::Stage, output::Symbol, target::Stage, input::Symbol)
function connect!(pipeline::Pipeline, src::Integer, output::Symbol, trg::Integer, input::Symbol)
    source = pipeline.stages[src]
    target = pipeline.stages[trg]

    haskey(source.outputs, output) || error("output $output does not exist in source stage")
    haskey(target.inputs, input) || error("input $input does not exist in target stage")

    # intialize if not yet initialized
    isempty(source.output_connections) && resize!(source.output_connections, length(source.output_formats))
    isempty(target.input_connections) && resize!(target.input_connections, length(target.input_formats))

    output_idx = source.outputs[output]
    input_idx = target.inputs[input]

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
        connection = merge(connection, old)
    end
    if isassigned(target.input_connections, input_idx)
        old = target.input_connections[input_idx]
        idx = findlast(c -> c === old, pipeline.connections)::Int
        deleteat!(pipeline.connections, idx)
        connection = merge(connection, old)
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

# TODO: make it impossible to break order
# TODO: Is this even a necessary condition?
function verify(pipeline::Pipeline)
    for connection in pipeline.connections
        earliest_input = length(pipeline.stages)
        for stage in keys(connection.inputs)
            idx = findfirst(==(stage), pipeline.stages)
            isnothing(idx) && error("Could not find $(stage.name) in pipeline.")
            earliest_input = min(earliest_input, idx)
        end

        earliest_output = length(pipeline.stages)
        for stage in keys(connection.outputs)
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

format_complexity(c::Connection) = format_complexity(c.format)
format_complexity(f::Format) = f.dims * sizeof(f.type)

function generate_buffers(pipeline::Pipeline)
    # TODO: is this necessary?
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

    buffers = Format[]
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
                    updated_comp = format_complexity(Format(buffers[i], connection.format))
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
                new_format = Format(buffers[best_match], connection.format)
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

# Usage:
# stages become tasks in the renderloop (mostly postprocessors)
# returned buffers become color attachments
# returned connection2idx is used to find input and output buffers
# Stage -> RenderStage, Framebuffer <-----------------------------------------------------.
#  |-> inputs -> (name, connection) -> (name, idx) -> (name, buffer) -> (name, Texture) --|
#  '-> outputs -> (name, connection) -> (name, idx) -> (name, buffer) -> (name, Texture) -'


################################################################################
### show
################################################################################


function Base.show(io::IO, format::Format)
    print(io, "Format($(format.dims), $(format.type))")
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
        elements = map(keys(connection.inputs), values(connection.inputs)) do stage, idx
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
        elements = map(keys(connection.outputs), values(connection.outputs)) do stage, idx
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


################################################################################
### Defaults
################################################################################


SortStage() = Stage("z-sort")

# I guess we should have multiple versions of this? Because SSAO render and OIT render don't really fit?
# SSAO   color     objectid position normal
# simple color     objectid
# OIT    HDR_color objectid weight
function RenderStage()
    outputs = (
        :color => Format(4, Float8),
        :objectid => Format(2, UInt32),
        :position => Format(3, Float16),
        :normal => Format(3, Float16),
    )
    Stage("render", outputs = outputs)
end
function TransparentRenderStage()
    outputs = (
        :weighted_color_sum => Format(4, Float16),
        :objectid => Format(2, UInt32),
        :alpha_product => Format(1, Float8),
    )
    Stage("transparent render", outputs = outputs)
end

# Want a MultiSzage kinda thing
function SSAOStage()
    inputs = (
        :position => Format(3, Float32),
        :normal => Format(3, Float16)
    )
    stage1 = Stage("SSAO occlusion"; inputs, outputs = (:occlusion => Format(1, Float8),))

    inputs = (:occlusion => Format(1, Float8), :color => Format(4, Float8), :objectid => Format(2, UInt32))
    stage2 = Stage("SSAO blur", inputs = inputs, outputs = (:color => Format(),))

    pipeline = Pipeline(stage1, stage2)
    connect!(pipeline, 1, :occlusion, 2, :occlusion)

    return pipeline
end

function OITStage()
    inputs = (:weighted_color_sum => Format(4, Float16), :alpha_product => Format(1, Float8))
    outputs = (:color => Format(4, Float8),)
    return Stage("OIT"; inputs, outputs)
end

function FXAAStage()
    inputs = (:color => Format(4, Float8), :objectid => Format(2, UInt32))
    outputs = (:color_luma => Format(4, Float8),)
    stage1 = Stage("FXAA luma"; inputs, outputs)

    inputs = (:color_luma => Format(4, Float8),)
    outputs = (:color => Format(4, Float8),)
    stage2 = Stage("FXAA apply"; inputs, outputs)

    pipeline = Pipeline(stage1, stage2)
    connect!(pipeline, 1, :color_luma, 2, :color_luma)

    return pipeline
end

function DisplayStage()
    inputs = (:color => Format(4, Float8), :objectid => Format(2, UInt32))
    return Stage("display"; inputs)
end


function default_SSAO_pipeline()
    # matching master with SSAO enabled
    pipeline = Pipeline()

    push!(pipeline, SortStage())                # 1
    push!(pipeline, RenderStage())              # 2
    push!(pipeline, SSAOStage())                # 3, 4
    push!(pipeline, RenderStage())              # 5
    push!(pipeline, TransparentRenderStage())   # 6
    push!(pipeline, OITStage())                 # 7
    push!(pipeline, FXAAStage())                # 8, 9
    push!(pipeline, DisplayStage())             # 10

    connect!(pipeline, 2, :position, 3, :position)
    connect!(pipeline, 2, :normal, 3, :normal)
    connect!(pipeline, 2, :color, 4, :color)
    connect!(pipeline, 2, :objectid, 4, :objectid)
    connect!(pipeline, 2, :objectid, 8, :objectid)
    connect!(pipeline, 2, :objectid, 10, :objectid)
    connect!(pipeline, 4, :color, 8, :color)
    connect!(pipeline, 5, :color, 8, :color)
    connect!(pipeline, 5, :objectid, 10, :objectid) # will get bundled so we don't need to repeat
    connect!(pipeline, 6, :weighted_color_sum, 7, :weighted_color_sum)
    connect!(pipeline, 6, :objectid, 10, :objectid)
    connect!(pipeline, 6, :alpha_product, 7, :alpha_product)
    connect!(pipeline, 7, :color, 8, :color)
    connect!(pipeline, 9, :color, 10, :color)

    return pipeline
end

function default_pipeline()
    # matching master
    pipeline = Pipeline()

    push!(pipeline, SortStage())
    push!(pipeline, RenderStage())
    push!(pipeline, RenderStage())
    push!(pipeline, TransparentRenderStage())
    push!(pipeline, OITStage())
    push!(pipeline, FXAAStage())
    push!(pipeline, DisplayStage())

    connect!(pipeline, 2, :color, 6, :color)
    connect!(pipeline, 2, :objectid, 6, :objectid)
    connect!(pipeline, 2, :objectid, 8, :objectid)
    connect!(pipeline, 3, :color, 6, :color)
    connect!(pipeline, 3, :objectid, 8, :objectid)
    connect!(pipeline, 4, :weighted_color_sum, 5, :weighted_color_sum)
    connect!(pipeline, 4, :objectid, 8, :objectid)
    connect!(pipeline, 4, :alpha_product, 5, :alpha_product)
    connect!(pipeline, 5, :color, 6, :color)
    connect!(pipeline, 7, :color, 8, :color)

    return pipeline
end

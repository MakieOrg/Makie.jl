module ComputePipeline

using Observables

using Base: RefValue

abstract type AbstractEdge end

mutable struct Computed
    name::Symbol
    # if a parent edge got resolved and updated this computed, dirty is temporarily true
    # so that the edges dependents can update their inputs accordingly
    dirty::Bool

    value::RefValue
    parent::AbstractEdge
    parent_idx::Int # index of parent.outputs this value refers to
    Computed(name) = new(name, false)
    Computed(name, value::RefValue) = new(name, false, value)
    function Computed(name, value::RefValue, parent::AbstractEdge, idx::Integer)
        return new(name, false, value, parent, idx)
    end
    function Computed(name, edge::AbstractEdge, idx::Integer)
        p = new(name, false)
        p.parent = edge
        p.parent_idx = idx
        return p
    end
end

hasparent(computed::Computed) = isdefined(computed, :parent)
getparent(computed::Computed) = hasparent(computed) ? computed.parent : nothing

struct ResolveException{E <: Exception} <: Exception
    start::Computed
    error::E
end

struct TypedEdge{InputTuple,OutputTuple,F}
    callback::F
    inputs::InputTuple
    inputs_dirty::Vector{Bool}
    outputs::OutputTuple
    output_nodes::Vector{Computed}
end

struct ComputeEdge <: AbstractEdge
    callback::Function

    inputs::Vector{Computed}
    inputs_dirty::Vector{Bool}

    outputs::Vector{Computed}
    got_resolved::RefValue{Bool}

    # edges, that rely on outputs from this edge
    # Mainly needed for mark_dirty!(edge) to propagate to all dependents
    dependents::Vector{ComputeEdge}
    typed_edge::RefValue{TypedEdge}
end

function ComputeEdge(f, input, output)
    return ComputeEdge(
        f, [input], [true], [output], RefValue(false),
        ComputeEdge[], RefValue{TypedEdge}()
    )
end

function TypedEdge(edge::ComputeEdge)
    inputs = ntuple(i -> edge.inputs[i].value, length(edge.inputs))
    result = edge.callback(inputs, edge.inputs_dirty, nothing)

    if result isa Tuple
        if length(result) != length(edge.outputs)
            m = first(methods(edge.callback))
            line = string(m.file, ":", m.line)
            error("Result needs to have same length. Found: $(result), for func $(line)")
        end
        outputs = ntuple(length(edge.outputs)) do i
            v = RefValue(result[i])
            edge.outputs[i].value = v # initialize to fully typed RefValue
            return v
        end
        foreach(node -> node.dirty = true, edge.outputs)
    elseif isnothing(result)
        outputs = ntuple(length(edge.outputs)) do i
            v = RefValue(nothing)
            edge.outputs[i].value = v # initialize to fully typed RefValue
            return v
        end
        foreach(node -> node.dirty = false, edge.outputs)
    else
        error("Wrong type as result $(typeof(result)). Needs to be Tuple with one element per output or nothing. Value: $result")
    end

    return TypedEdge(edge.callback, inputs, edge.inputs_dirty, outputs, edge.outputs)
end


ComputeEdge(f) = ComputeEdge(f, Computed[])
function ComputeEdge(f, inputs::Vector{Computed})
    return ComputeEdge(f, inputs, fill(true, length(inputs)), Computed[], RefValue(false),
                       ComputeEdge[], RefValue{TypedEdge}())
end

mutable struct Input <: AbstractEdge
    name::Symbol
    value::Any
    f::Function
    output::Computed
    dirty::Bool
    dependents::Vector{ComputeEdge}
end

function Input(name, value, f, output)
    @assert !(value isa Computed)
    return Input(name, value, f, output, true, ComputeEdge[])
end

struct ComputeGraph
    inputs::Dict{Symbol,Input}
    outputs::Dict{Symbol,Computed}
    onchange::Observable{Nothing}
end

function ComputeGraph()
    return ComputeGraph(Dict{Symbol,ComputeEdge}(), Dict{Symbol,Computed}(), Observable{Nothing}())
end

function isdirty(computed::Computed)
    return hasparent(computed) && isdirty(computed.parent)
end

function isdirty(edge::ComputeEdge)
    # If resolve hasn't run, it has to be dirty
    edge.got_resolved[] || return true
    # Otherwise it's dirty if the input changed
    return any(edge.inputs_dirty)
end

function mark_dirty!(edge::ComputeEdge)
    edge.got_resolved[] = false
    for dep in edge.dependents
        mark_dirty!(dep)
    end
    return
end

function mark_dirty!(computed::Computed)
    hasparent(computed) || return
    return mark_dirty!(computed.parent)
end

function resolve!(input::Input)
    input.dirty || return
    value = input.f(input.value)
    if isassigned(input.output.value)
        input.output.value[] = value
    else
        input.output.value = RefValue(value)
    end
    input.dirty = false
    input.output.dirty = true
    for edge in input.dependents
        mark_input_dirty!(input, edge)
    end
    input.output.dirty = false
    return input.output.value[]
end

function mark_dirty!(input::Input)
    input.dirty = true
    for edge in input.dependents
        mark_dirty!(edge)
    end
    return
end

function Base.setindex!(computed::Computed, value)
    computed.value[] = value
    return mark_dirty!(computed)
end

function _setproperty!(attr::ComputeGraph, key::Symbol, value)
    input = attr.inputs[key]
    input.value = value
    mark_dirty!(input)
    return value
end

function Base.setproperty!(attr::ComputeGraph, key::Symbol, value)
    _setproperty!(attr, key, value)
    notify(attr.onchange)
    return value
end

function update!(attr::ComputeGraph; kwargs...)
    for (key, value) in pairs(kwargs)
        if haskey(attr.inputs, key)
            _setproperty!(attr, key, value)
        else
            throw(Makie.AttributeNameError(key))
        end
    end
    notify(attr.onchange)
    return attr
end

Base.haskey(attr::ComputeGraph, key::Symbol) = haskey(attr.inputs, key)

function Base.getproperty(attr::ComputeGraph, key::Symbol)
    # more efficient to hardcode?
    key === :inputs && return getfield(attr, :inputs)
    key === :outputs && return getfield(attr, :outputs)
    key === :onchange && return getfield(attr, :onchange)
    return attr.inputs[key].output
end

function Base.getindex(attr::ComputeGraph, key::Symbol)
    return attr.outputs[key]
end
isdirty(input::Input) = input.dirty

Base.getindex(computed::Computed) = resolve!(computed)

function mark_input_dirty!(parent::ComputeEdge, edge::ComputeEdge)
    @assert parent.got_resolved[] # parent should only call this after resolve!
    for i in eachindex(edge.inputs)
        edge.inputs_dirty[i] |= getfield(edge.inputs[i], :dirty)
    end
end

function mark_input_dirty!(parent::Input, edge::ComputeEdge)
    @assert !parent.dirty # should got resolved
    for i in eachindex(edge.inputs)
        edge.inputs_dirty[i] |= getfield(edge.inputs[i], :dirty)
    end
end

function set_result!(edge::TypedEdge, result, i, value)
    if isnothing(value)
        edge.output_nodes[i].dirty = false
    else
        edge.output_nodes[i].dirty = true
        edge.outputs[i][] = value
    end
    if !isempty(result)
        next_val = first(result)
        rem = Base.tail(result)
        set_result!(edge, rem, i + 1, next_val)
    end
    return
end

function set_result!(edge::TypedEdge, result)
    next_val = first(result)
    rem = Base.tail(result)
    return set_result!(edge, rem, 1, next_val)
end
# do we want this type stable?
# This is how we could get a type stable callback body for resolve
function resolve!(edge::TypedEdge)
    result = edge.callback(edge.inputs, edge.inputs_dirty, edge.outputs)
    if result === :deregister
        # TODO
    elseif result isa Tuple
        if length(result) != length(edge.outputs)
            error("Did not return correct length: $(result), $(edge.callback)")
        end
        set_result!(edge, result)
    elseif isnothing(result)
        foreach(x -> x.dirty = false, edge.output_nodes)
    else
        error("Needs to return a Tuple with one element per output, or nothing")
    end
end

function resolve!(computed::Computed)
    try
        return _resolve!(computed)
    catch e
        rethrow(ResolveException(computed, e))
    end
end

function _resolve!(computed::Computed)
    if hasparent(computed)
        resolve!(computed.parent)
    end
    return computed.value[]
end

function resolve!(edge::ComputeEdge)
    edge.got_resolved[] && return false
    isdirty(edge) || return false
    # Resolve inputs first
    foreach(_resolve!, edge.inputs)
    # We pass the refs, so that no boxing accours and code that actually needs Ref{T}(value) can directly use those (ccall/opengl)
    # TODO, can/should we store this tuple?
    if !isassigned(edge.typed_edge)
        # constructor does first resolve to determine fully typed outputs
        edge.typed_edge[] = TypedEdge(edge)
    else
        resolve!(edge.typed_edge[])
    end
    edge.got_resolved[] = true
    fill!(edge.inputs_dirty, false)
    for dep in edge.dependents
        mark_input_dirty!(edge, dep)
    end
    foreach(comp -> comp.dirty = false, edge.outputs)
    return true
end

add_input!(attr::ComputeGraph, key::Symbol, value) = add_input!((k, v)-> v, attr, key, value)

# TODO: error tracking would be better if we didn't wrap the user function
function add_input!(conversion_func, attr::ComputeGraph, key::Symbol, value)
    @assert !(value isa Computed)
    haskey(attr.inputs, key) && return # TODO: Should this error/warn?

    output = Computed(key, RefValue{Any}())
    input = Input(key, value, (v) -> conversion_func(key, v), output)
    output.parent = input
    output.parent_idx = 1
    # Needs to be Any, since input can change type
    attr.inputs[key] = input
    attr.outputs[key] = output
    return
end

function add_inputs!(conversion_func, attr::ComputeGraph; kw...)
    for (k, v) in pairs(kw)
        add_input!(conversion_func, attr, k, v)
    end
end

# for recipe -> recipe (mostly)
function add_input!(attr::ComputeGraph, key::Symbol, value::Computed)
    attr.outputs[key] = value
    return
end

# for recipe -> primitive (mostly)
function add_input!(conversion_func, attr::ComputeGraph, key::Symbol, value::Computed)
    input_name = Symbol(:parent_, key)
    attr.outputs[input_name] = value
    register_computation!(attr, [input_name], [key]) do (input,), changed, last
        return (conversion_func(key, input[]),)
    end
    return
end

get_callback(computed::Computed) = hasparent(computed) ? computed.parent.callback : nothing

function register_computation!(f, attr::ComputeGraph, inputs::Vector{Symbol}, outputs::Vector{Symbol})
    if any(k -> haskey(attr.outputs, k), outputs)
        valid = [k for k in outputs if haskey(attr.outputs, k) && hasparent(attr.outputs[k])]
        if length(valid) == 0
            # fine, we won't be overwriting an edge
        elseif length(valid) != length(outputs)
            existing = join(valid, ", ")
            error("Cannot register computation because some outputs already have parent edges: $existing")
        else
            e1 = attr.outputs[outputs[1]].parent
            if !all(attr.outputs[k].parent == e1 for k in outputs)
                bad_keys = join([k for k in outputs if attr.outputs[k].parent != e1], ", ")
                error("Not all outputs are computed from the same edge. $bad_keys do not match first output.")
            end

            if e1.callback != f
                # We should only care about input arg types...
                func1, loc1 = edge_callback_to_string(f)
                func2, loc2 = edge_callback_to_string(e1.callback)
                error(
                    "The callback function of the edge does not match the already registered callback.\n" *
                    "  $func1 $loc1\n  $func2 $loc2\n  $(methods(f))"
                )
            end

            # edge already exists
            return
        end
    end

    _inputs = Computed[attr.outputs[k] for k in inputs]
    new_edge = ComputeEdge(f, _inputs)
    for (k, input) in zip(inputs, _inputs)
        if hasparent(input)
            push!(input.parent.dependents, new_edge)
        else
            push!(attr.inputs[k].dependents, new_edge)
        end
    end

    # use order of namedtuple, which should not change!
    for (i, symbol) in enumerate(outputs)
        # create an uninitialized Ref, which gets replaced by the correctly strictly typed Ref on first resolve
        value = get!(attr.outputs, symbol, Computed(symbol))
        value.parent = new_edge
        value.parent_idx = i
        value.dirty = true
        push!(new_edge.outputs, value)
    end
    return
end

# TODO:
# What exactly should these do? Just remove the specific object, or clean up
# invalid dependents as well? Or maybe both should be possible?

# GLMakie only *requires* an endpoint to be deleted atm so lets keep this simple
# for now
function Base.delete!(attr::ComputeGraph, key::Symbol)
    haskey(attr.outputs, key) || return attr

    computed = attr.outputs[key]
    if hasparent(computed)
        delete!(attr, computed.parent)
    else
        delete!(attr.outputs, key)
    end

    return attr
end

function Base.delete!(attr::ComputeGraph, edge::ComputeEdge)
    # deregister this edge as a dependency of its parents
    for computed in edge.inputs
        if hasparent(computed)
            parent_edge = computed.parent
            filter!(e -> e === edge, parent_edge.dependents)
        end
    end

    # all dependents become invalid as their parent computation no longer runs
    for dependent in edge.dependents
        delete!(attr, dependent)
    end

    # All outputs lose their parent computation so they should probably be removed
    # Could also disconnect them, but what's the point of a loose node?
    for computed in edge.outputs
        for (k, v) in attr.outputs
            if v === computed
                delete!(attr.outputs, k)
                break
            end
        end
    end

    return attr
end

function Base.delete!(attr::ComputeGraph, edge::Input)
    # all dependents become invalid as their parent computation no longer runs
    for dependent in edge.dependents
        delete!(attr, dependent)
    end

    # All outputs lose their parent computation so they should probably be removed
    # Could also disconnect them, but what's the point of a loose node?
    for computed in edge.outputs
        for (k, v) in attr.outputs
            if v === computed
                delete!(attr.outputs, k)
                break
            end
        end
    end

    # Input also exists in attr.input, so delete that
    for (k, v) in attr.inputs
        if v === edge
            delete!(attr.inputs, k)
            break
        end
    end

    return attr
end

include("io.jl")

export Computed, Computed, ComputeEdge, ComputeGraph, register_computation!, add_input!, add_inputs!, update!

end

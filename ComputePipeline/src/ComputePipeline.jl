module ComputePipeline

using Base: RefValue

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

struct TypedEdge{InputTuple,OutputTuple,F}
    callback::F
    inputs::InputTuple
    inputs_dirty::Vector{Bool}
    outputs::OutputTuple
    outputs_dirty::Vector{Bool}
end

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
    typed_edge::RefValue{TypedEdge}
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
        fill!(edge.outputs_dirty, true)
    elseif isnothing(result)
        outputs = ntuple(length(edge.outputs)) do i
            v = RefValue(nothing)
            edge.outputs[i].value = v # initialize to fully typed RefValue
            return v
        end
        fill!(edge.outputs_dirty, false)
    else
        error("Wrong type as result $(typeof(result)). Needs to be Tuple with one element per output or nothing")
    end

    return TypedEdge(edge.callback, inputs, edge.inputs_dirty, outputs, edge.outputs_dirty)
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
    return println(io, ")")
end
# Can only make this alias after ComputeEdge & ComputedValue are created
# We're going to ignore that ComputedValue has a type parameter,
# which it only has to resolve the circular dependency
const Computed = ComputedValue{ComputeEdge}

ComputeEdge(f) = ComputeEdge(f, Computed[])
function ComputeEdge(f, inputs::Vector{Computed})
    return ComputeEdge(f, inputs, fill(true, length(inputs)), Computed[], Bool[], RefValue(false),
                       Set{ComputeEdge}(), RefValue{TypedEdge}())
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
    return println(io, ")")
end

function ComputeGraph()
    return ComputeGraph(Dict{Symbol,ComputeEdge}(), Dict{Symbol,Computed}())
end

function isdirty(computed::Computed)
    hasparent(computed) || return false
    parent = computed.parent
    # Can't be dirty if inputs have changed

    if parent.got_resolved[]
        # if resolved is true, the computed value is dirty if the output is dirty
        return computed.parent.outputs_dirty[computed.parent_idx]
    else
        # if resolved is false, the computed value is dirty if any of the inputs have changed
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
    for dep in edge.dependents
        mark_dirty!(dep)
    end
    return
end

function mark_dirty!(computed::Computed)
    hasparent(computed) || return
    return mark_dirty!(computed.parent)
end

function Base.setindex!(computed::Computed, value)
    computed.value[] = value
    return mark_dirty!(computed)
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

function Base.getindex(attr::ComputeGraph, key::Symbol)
    return attr.outputs[key]
end

Base.getindex(computed::Computed) = resolve!(computed)

function mark_input_dirty!(parent::ComputeEdge, edge::ComputeEdge)
    for (i, input) in enumerate(edge.inputs)
        # This gets called from resolve!(parent), so we should only mark dirty if the input is a child of parent
        hasparent(input) && input.parent === parent && (edge.inputs_dirty[i] = isdirty(input))
    end
end

function set_result!(edge::TypedEdge, result, i, value)
    if isnothing(value)
        edge.outputs_dirty[i] = false
    else
        edge.outputs_dirty[i] = true
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
    # Resolve inputs first
    foreach(resolve!, edge.inputs)
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


add_input!(attr::ComputeGraph, key::Symbol, value) = add_input!((k, v)-> v, attr::ComputeGraph, key::Symbol, value)

function add_input!(conversion_func, attr::ComputeGraph, key::Symbol, value)
    edge = ComputeEdge() do (input,), changed, last
        return (conversion_func(key, input[]),)
    end
    # Needs to be Any, since input can change type
    input = Computed(RefValue{Any}(value))
    # Outputs need to be type stable
    output = Computed(RefValue{Any}(), edge, 1)
    edge.got_resolved[] = false
    push!(edge.inputs, input)
    push!(edge.inputs_dirty, true) # we already run default!
    push!(edge.outputs, output)
    push!(edge.outputs_dirty, true)
    # We assign the parent, since if we gave input a parent, we would get a circle/stackoverflow
    attr.inputs[key] = edge
    attr.outputs[key] = output
    return
end

function add_inputs!(conversion_func, attr::ComputeGraph; kw...)
    for (k, v) in pairs(kw)
        add_input!(conversion_func, attr, k, v)
    end
end

function register_computation!(f, attr::ComputeGraph, inputs::Vector{Symbol}, outputs::Vector{Symbol})
    if any(x -> haskey(attr.outputs, x), outputs)
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

export Computed, ComputedValue, ComputeEdge, ComputeGraph, register_computation!, add_input!, add_inputs!, update!

end

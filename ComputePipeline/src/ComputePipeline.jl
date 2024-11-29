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
    function ComputedValue{P}() where {P}
        return new{P}()
    end
    function ComputedValue{P}(edge::P, idx::Integer) where {P}
        p = new{P}()
        p.parent = edge
        p.parent_idx = idx
        return p
    end
end

hasparent(computed::ComputedValue) = isdefined(computed, :parent)
getparent(computed::ComputedValue) = hasparent(computed) ? computed.parent : nothing

struct TypedEdge{InputTuple,OutputTuple,F}
    callback::F
    inputs::InputTuple
    inputs_dirty::Vector{Bool}
    outputs::OutputTuple
    outputs_dirty::Vector{Bool}
end

struct ComputeEdge
    callback::Function
    inputs::Vector{ComputedValue}
    inputs_dirty::Vector{Bool}
    outputs::Vector{ComputedValue{ComputeEdge}}
    outputs_dirty::Vector{Bool}
    got_resolved::RefValue{Bool}
    # edges, that rely on outputs from this edge
    # Mainly needed for mark_dirty!(edge) to propagate to all dependents
    dependents::Vector{ComputeEdge}
    typed_edge::RefValue{TypedEdge}
end

function ComputeEdge(f, input, output)
    return ComputeEdge(
        f, ComputedValue[input], [true], [output], [true], RefValue(false),
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
function ComputeEdge(f, inputs::Vector{ComputedValue})
    return ComputeEdge(f, inputs, fill(true, length(inputs)), ComputedValue[], Bool[], RefValue(false),
                       ComputeEdge[], RefValue{TypedEdge}())
end

function Base.show(io::IO, computed::Computed)
    if isassigned(computed.value)
        print(io, "Computed($(typeof(computed.value[])))")
    else
        print(io, "Computed(#undef)")
    end
end

mutable struct Input
    value::Any
    f::Function
    output::ComputedValue{Input}
    dirty::Bool
    dependents::Vector{ComputeEdge}
end

function Input(value, f, output)
    return Input(value, f, output, true, ComputeEdge[])
end

struct ComputeGraph
    inputs::Dict{Symbol,Input}
    outputs::Dict{Symbol,ComputedValue}
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

function resolve!(input::Input)
    if isassigned(input.output.value)
        input.output.value[] = input.f(input.value)
    else
        input.output.value = RefValue(input.f(input.value))
    end
    input.dirty = false
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

function Base.setproperty!(attr::ComputeGraph, key::Symbol, value)
    input = attr.inputs[key]
    input.value = value
    mark_dirty!(input)
    return value
end

Base.haskey(attr::ComputeGraph, key::Symbol) = haskey(attr.inputs, key)

function Base.getproperty(attr::ComputeGraph, key::Symbol)
    # more efficient to hardcode?
    key === :inputs && return getfield(attr, :inputs)
    key === :outputs && return getfield(attr, :outputs)
    key === :default && return getfield(attr, :default)
    return attr.inputs[key].output
end

function Base.getindex(attr::ComputeGraph, key::Symbol)
    return attr.outputs[key]
end

Base.getindex(computed::ComputedValue) = resolve!(computed)

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

function resolve!(computed::ComputedValue)
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

add_input!(attr::ComputeGraph, key::Symbol, value) = add_input!((k, v)-> v, attr, key, value)

function add_input!(conversion_func, attr::ComputeGraph, key::Symbol, value)
    output = ComputedValue{Input}(RefValue{Any}())
    input = Input(value, (v)-> conversion_func(key, v), output)
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

get_callback(computed::ComputedValue) = hasparent(computed) ? computed.parent.callback : nothing

function stringify_callback(f)
    m = first(methods(f))
    return string(m.file, ":", m.line)
end

function register_computation!(f, attr::ComputeGraph, inputs::Vector{Symbol}, outputs::Vector{Symbol})
    if all(x -> haskey(attr.outputs, x), outputs)
        function throw_error()
            callbacks = join([string(k, "=>", stringify_callback(get_callback(attr.outputs[k]))) for k in outputs], ", ")
            current = stringify_callback(f)
            cf_equal = f == get_callback(attr.outputs[first(outputs)])
            return error("Only one computation is allowed to be registered for an output. Callbacks: $(callbacks). Current: $(current), isequal: $(cf_equal)")
        end
        # We check if all outputs have the same parent + callback, which means this computation is already registered
        # Which we allow, and simply ignore the new registration
        out1 = attr.outputs[first(outputs)]
        !hasparent(out1) && throw_error()
        edge1 = out1.parent
        edge1.callback !== f && throw_error()
        all_same = all(outputs) do k
            out = attr.outputs[k]
            return hasparent(out) && out.parent === edge1
        end
        all_same || throw_error()
        return # ignore new registration
    end
    _inputs = ComputedValue[attr.outputs[k] for k in inputs]
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
        value = Computed(new_edge, i)
        attr.outputs[symbol] = value
        push!(new_edge.outputs, value)
        push!(new_edge.outputs_dirty, true)
    end
    return
end

export Computed, ComputedValue, ComputeEdge, ComputeGraph, register_computation!, add_input!, add_inputs!, update!

end

function Base.show(io::IO, computed::Computed)
    return if isdefined(computed, :value) && isassigned(computed.value)
        print(IOContext(io, :limit => true), "Computed(:", computed.name, ", ", computed.value[], ")")
    else
        print(io, "Computed(:", computed.name, ", #undef)")
    end
end

function Base.show(io::IO, ::MIME"text/plain", computed::Computed)
    println(io, "Computed:")
    println(io, "  name = :", computed.name)
    if hasparent(computed)
        if computed.parent isa Input
            println(io, "  parent = ", computed.parent)
        else
            println(io, "  parent = ", computed.parent, " @ output ", computed.parent_idx)
        end
    else
        println(io, "parent = #undef")
    end
    v = isdefined(computed, :value) && isassigned(computed.value) ? computed.value[] : "#undef"
    print(io, "  value = ")
    print(IOContext(io, :limit => true), v)
    return print(io, "\n  dirty = ", isdirty(computed))
end


edge_callback_name(f::Function, call = "(…)") = "$(nameof(f))$call"
edge_callback_name(f::InputFunctionWrapper, call = "(…)") = "(::InputFunctionWrapper(:$(f.key), $(nameof(f.user_func))))$call"
edge_callback_name(f::MapFunctionWrapper, call = "(…)") = "(::MapFunctionWrapper($(nameof(f.user_func))))$call"
edge_callback_name(functor, call = "(…)") = "(::$(nameof(functor)))$call"


# This should mirror the inputs and outputs a ComputeEdge callback uses
_get_named_inputs(edge::ComputeEdge) = _get_named_data(edge.inputs, NamedTuple())
_get_named_outputs(edge::ComputeEdge) = _get_named_data(edge.outputs, nothing)
function _get_named_data(collection, fallback)
    if all(c -> isdefined(c, :value) && isassigned(c.value), collection)
        N = length(collection)
        names = ntuple(i -> collection[i].name, N)
        values = ntuple(i -> collection[i].value[], N)
        return NamedTuple{names}(values)
    else
        return fallback
    end
end

# Get the function called by the edge with its input types
# This skips over InputFunctionWrapper to give users more relevant function locations
get_callback_info(edge::Input) = get_callback_info(edge.f, edge.value)
function get_callback_info(edge::ComputeEdge)
    input = _get_named_inputs(edge)
    changed = NamedTuple{keys(input)}(ntuple(x -> true, length(keys(input))))
    output = _get_named_outputs(edge)
    return get_callback_info(edge.callback, input, changed, output)
end

# catch-all for the final user function being called.
# could be:
#   f(inputs, changed, cached) from register_computation!()
#   f(key, input) from InputFunctionWrapper in Input
#   f(input) from MapFunctionWrapper in map!()
# or some other syntax due to a wrapper created in another package
get_callback_info(f, args...) = f, typeof.(args)

# ComputeEdge with InputFunctionWrapper which drops changed and cached
# from add_input!(f, key, ::Computed)
function get_callback_info(f::InputFunctionWrapper, inputs, changed, outputs)
    # if the edge inputs aren't initialized yet we fall back onto am empty namedtuple
    return get_callback_info(f.user_func, f.key, length(inputs) > 0 ? inputs[1] : nothing)
end

# Input with InputFunctionWrapper adding Symbol to the callback
# for add_input!(f, key, value)
function get_callback_info(f::InputFunctionWrapper, input)
    return get_callback_info(f.user_func, f.key, input)
end

# map!(f, attr, ...) call which drops changed, cached and NamedTuple
# for add_input!(f, key, value)
function get_callback_info(f::MapFunctionWrapper, inputs, changed, outputs)
    return get_callback_info(f.user_func, values(inputs))
end

# add_input!(key, value)
get_callback_info(f::typeof(identity), arg) = f, (typeof(arg),)


# Generate a string pointing to the location of the callback function in edge.
# This skips over InputFunctionWrapper and MapFunctionWrapper to give more relevant locations
function edge_callback_location(edge)
    f, arg_types = get_callback_info(edge)
    return edge_callback_location(f, arg_types)
end
function edge_callback_location(f, arg_types::Tuple)
    if hasmethod(f, arg_types)
        file, line = Base.functionloc(f, arg_types)
        return "$file:$line"
    else
        return "unknown method location"
    end
end

# Generate a string with the edges callback function signature and location.
# This skips over InputFunctionWrapper and MapFunctionWrapper to give more relevant locations
function edge_callback_to_string(edge)
    f, arg_types = get_callback_info(edge)
    return edge_callback_to_string(f, arg_types)
end
function edge_callback_to_string(f, arg_types::Tuple)
    arg_str = join(("::$T" for T in arg_types), ", ")
    arg_str = replace(arg_str, "Base.RefValue" => "Ref")
    func = edge_callback_name(f, "($arg_str)")
    loc = edge_callback_location(f, arg_types)
    return "$func", "@ $loc"
end

function Base.show(io::IO, edge::ComputeEdge)
    N1 = length(edge.inputs)
    N2 = length(edge.outputs)
    N3 = length(edge.dependents)
    return print(
        io, "ComputeEdge(",
        edge_callback_name(edge.callback), ", ",
        N1, " input$(N1 == 1 ? "" : 's'), ",
        N2, " output$(N2 == 1 ? "" : 's'), ",
        N3, " dependent$(N3 == 1 ? "" : 's'))"
    )
end

function Base.show(io::IO, ::MIME"text/plain", edge::ComputeEdge)
    println(io, "ComputeEdge:")

    f, loc = edge_callback_to_string(edge)
    println(io, "  callback:\n    $f")
    printstyled(io, "    $loc\n", color = :light_black)

    print(io, "  inputs:")
    for (dirty, v) in zip(edge.inputs_dirty, edge.inputs)
        if dirty
            printstyled(io, "\n    ↻ $v", color = :light_black)
        else
            print(io, "\n    ✓ ", v)
        end
    end

    print(io, "\n  outputs:")
    for v in edge.outputs
        if isdirty(v)
            printstyled(io, "\n    ↻ $v", color = :light_black)
        else
            print(io, "\n    ✓ ", v)
        end
    end

    print(io, "\n  dependents:")
    for v in edge.dependents
        if isdirty(v)
            printstyled(io, "\n    ↻ $v", color = :light_black)
        else
            print(io, "\n    ✓ ", v)
        end
    end
    return
end


function Base.show(io::IO, input::Input)
    return print(io, "Input(:", input.name, ", ", input.value, ")")
end

function Base.show(io::IO, ::MIME"text/plain", input::Input)
    println(io, "Input:")
    println(io, "  name:     :", input.name)
    println(io, "  value:    ", input.value)
    f, loc = edge_callback_to_string(input)
    print(io, "  callback: $f")
    printstyled(io, " $loc\n", color = :light_black)
    print(io, "  output:   ")
    if isdirty(input)
        printstyled(io, "↻ $(input.output)\n", color = :light_black)
    else
        println(io, "✓ ", input.output)
    end
    print(io, "  dependents:")
    for v in input.dependents
        if isdirty(v)
            printstyled(io, "\n    ↻ $v", color = :light_black)
        else
            println(io, "\n    ✓ ", v)
        end
    end
    return
end


# TODO: Maybe keep track of edges in Graph?
function collect_edges(graph::ComputeGraph)
    cache = Set{ComputeEdge}()
    # recipes skip inputs when connecting so just checking inputs is not enough
    foreach(computed -> collect_edges(computed, cache), values(graph.outputs))
    return cache
end
function collect_edges(computed::Computed, cache::Set{ComputeEdge} = Set{ComputeEdge}())
    return collect_edges(computed.parent, cache)
end
function collect_edges(input::Input, cache::Set{ComputeEdge} = Set{ComputeEdge}())
    for edge in input.dependents
        collect_edges(edge, cache)
    end
    return cache
end
function collect_edges(edge::ComputeEdge, cache::Set{ComputeEdge})
    if !(edge in cache)
        push!(cache, edge)
        foreach(e -> collect_edges(e, cache), edge.dependents)
    end
    return
end
count_edges(graph::ComputeGraph) = length(collect_edges(graph))
count_edges(input::Input) = length(collect_edges(input))


function Base.show(io::IO, graph::ComputeGraph)
    N1 = length(graph.inputs)
    N2 = length(graph.outputs)
    N3 = count_edges(graph)
    return print(
        io, "ComputeGraph(",
        N1, " input$(N1 == 1 ? "" : 's'), ",
        N2, " output$(N2 == 1 ? "" : 's'), ",
        N3, " edge$(N3 == 1 ? "" : 's'))"
    )
end

function Base.show(io::IO, ::MIME"text/plain", graph::ComputeGraph)
    if isempty(graph.inputs) && isempty(graph.outputs)
        print(io, "ComputeGraph()")
        return io
    end

    println(io, "ComputeGraph():")

    print(io, "  Inputs:")
    ks = sort!(collect(keys(graph.inputs)), by = string)
    pad = mapreduce(k -> length(string(k)), max, ks, init = 0)
    for k in ks
        print(io, "\n    :", rpad(string(k), pad), " => ", graph.inputs[k])
    end

    print(io, "\n\n  Outputs:")
    ks = sort!(collect(keys(graph.outputs)), by = string)
    pad = mapreduce(k -> length(string(k)), max, ks, init = 0)
    for k in ks
        output = graph.outputs[k]
        print(io, "\n    :", rpad(string(k), pad), " => ")
        printstyled(io, "$output", color = ifelse(isdirty(output), :light_black, :normal))
    end
    return io
end


function Base.showerror(io::IO, re::ResolveException)
    trace_error(io, re.start)
    print(io, "Due to ")
    printstyled(io, "ERROR: ", color = :light_red, bold = true)
    Base.showerror(io, re.error)
end

function collect_dirty(computed::Computed, marked = Set{Symbol}())
    hasparent(computed) && collect_dirty(computed.parent, marked)
    return marked
end
function collect_dirty(edge::ComputeEdge, marked = Set{Symbol}())
    if !edge.got_resolved[] || any(edge.inputs_dirty)
        foreach(output -> push!(marked, output.name), edge.outputs)
        foreach(input -> collect_dirty(input, marked), edge.inputs)
    end
    return marked
end
function collect_dirty(edge::Input, marked = Set{Symbol}())
    edge.dirty && push!(marked, edge.name)
    return marked
end

# Error handling tools
function trace_error(io::IO, computed::Computed)
    print(io, "Failed to resolve ")
    printstyled(io, "$(computed.name):\n", color = :red)
    if hasparent(computed)
        marked = collect_dirty(computed)
        push!(marked, computed.name)
        trace_error(io, computed.parent, marked)
    end
    return
end
trace_error(io::IO, edge::ComputeEdge) = trace_error(io, edge, collect_dirty(edge))

function trace_error(io::IO, computed::Computed, marked)
    hasparent(computed) && trace_error(io, computed.parent, marked)
    return
end

function trace_error(io::IO, edge::ComputeEdge, marked)
    if isdirty(edge)
        print(io, "[ComputeEdge] ")

        outputs = join((output.name for output in edge.outputs), ", ")
        printstyled(io, outputs, color = :red)

        func = edge_callback_name(edge.callback, "")
        print(io, " = ", func, "((")

        N = length(edge.inputs)
        was_dirty = false
        for i in eachindex(edge.inputs)
            name = edge.inputs[i].name
            c = ifelse(was_dirty, :light_black, ifelse(name in marked, :red, :light_green))
            was_dirty |= name in marked # only mark first unresolved input
            printstyled(io, name, color = c)
            print(io, ", ")
        end
        println(io, "), changed, cached)")

        printstyled(io, "  @ $(edge_callback_location(edge))\n", color = :light_black)

        idx = findfirst(computed -> computed.name in marked, edge.inputs)
        if idx === nothing # All resolved
            print(io, "  with edge inputs:")
            ioc = IOContext(io, :limit => true)
            for input in edge.inputs
                print(io, "\n    ", input.name, " = ")
                show(ioc, input.value[])
            end
            println(io)
            print_root_inputs(io, edge)
        else # idx is first dirty
            trace_error(io, edge.inputs[idx], marked)
        end
    end
    return
end

function print_root_inputs(io::IO, edge::ComputeEdge)
    root_inputs = Symbol[]
    for input in edge.inputs
        trace_inputs!(input, root_inputs)
    end
    return println(io, "Triggered by update of:\n  ", join(root_inputs, ", ", " or "))
end
function trace_inputs!(edge::ComputeEdge, root_inputs)
    foreach(c -> trace_inputs!(c, root_inputs), edge.inputs)
    return
end
function trace_inputs!(computed::Computed, root_inputs)
    hasparent(computed) && trace_inputs!(computed.parent, root_inputs)
    return
end
function trace_inputs!(input::Input, root_inputs)
    push!(root_inputs, input.name)
    return
end

function trace_error(io::IO, edge::Input, marked = nothing)
    print(io, "[Input] ")
    if edge.dirty
        printstyled(io, edge.name, color = :red)
        func = edge_callback_name(edge.f, "")
        println(io, " = ", func, '(', edge.value, ")")
        printstyled(io, "  @ $(edge_callback_location(edge))\n", color = :light_black)
    else
        printstyled(io, "$(edge.name)\n", color = :green)
    end
    return
end

"""
    show_inputs(node)

Traces and prints all recursive inputs to a node.
"""
show_inputs(node::Computed) = show_inputs(stdout, node)
function show_inputs(io::IO, node::Computed, tab = 0)
    println(io, "    "^tab, node)
    return show_inputs(io, node.parent, tab + 1)
end
function show_inputs(io::IO, node::Input, tab = 0)
    return println(io, "    "^tab, node)
end
function show_inputs(io::IO, edge::ComputeEdge, tab = 0)
    for node in edge.inputs
        show_inputs(io, node, tab)
    end
    return
end

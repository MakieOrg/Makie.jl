function Base.show(io::IO, computed::Computed)
    if isdefined(computed, :value) && isassigned(computed.value)
        print(io, "Computed(:", computed.name, ", ", computed.value[], ")")
    else
        print(io, "Computed(:", computed.name, ", #undef)")
    end
end

function Base.show(io::IO, ::MIME"text/plain", computed::Computed)
    println(io, "Computed:")
    println(io, "  name: :", computed.name)
    if hasparent(computed)
        if computed.parent isa Input
            println(io, "  parent = ", computed.parent)
        else
            println(io, "  parent = ", computed.parent, " @ output ", computed.parent_idx)
        end
    else
        println(io, "parent = #undef")
    end
    if isdefined(computed, :value) && isassigned(computed.value)
        print(io, "  value = ", computed.value[])
    else
        print(io, "  value = #undef")
    end
end



edge_callback_name(f::Function, call = "(…)") = "$(nameof(f))$call"
edge_callback_name(functor, call = "(…)") = "(::$(nameof(functor)))$call"

function edge_callback_location(edge::ComputeEdge)
    inputT = if all(c -> isdefined(c, :value), edge.inputs)
        typeof(ntuple(i -> edge.inputs[i].value, length(edge.inputs)))
    else
        Tuple
    end
    outputT = isassigned(edge.typed_edge) ? typeof(edge.typed_edge[].outputs) : Nothing
    return edge_callback_location(edge.callback, inputT, outputT)
end
edge_callback_location(input::Input) = edge_callback_location(input.f, (typeof(input.value),))

edge_callback_location(f, arg1, arg3) = edge_callback_location(f, (arg1, Vector{Bool}, arg3))

function edge_callback_location(f, args)
    file, line = Base.functionloc(f, args)
    return "$file:$line"
end


function edge_callback_to_string(edge::ComputeEdge)
    inputT = if all(c -> isdefined(c, :value), edge.inputs)
        typeof(ntuple(i -> edge.inputs[i].value, length(edge.inputs)))
    else
        Tuple
    end
    outputT = isassigned(edge.typed_edge) ? typeof(edge.typed_edge[].outputs) : Nothing
    return edge_callback_to_string(edge.callback, inputT, outputT)
end
function edge_callback_to_string(input::Input)
    return edge_callback_to_string(input.f, (typeof(input.value),))
end

function edge_callback_to_string(f, argT1 = Tuple, argT3 = Nothing)
    return edge_callback_to_string(f, (argT1, Vector{Bool}, argT3))
end
function edge_callback_to_string(f, args::Tuple)
    arg_str = join(("::$T" for T in args), ", ")
    arg_str = replace(arg_str, "Base.RefValue" => "Ref")
    func = edge_callback_name(f, "($arg_str)")
    file, line = Base.functionloc(f, args)
    return "$func", "@ $file:$line"
end

function Base.show(io::IO, edge::ComputeEdge)
    N1 = length(edge.inputs)
    N2 = length(edge.outputs)
    N3 = length(edge.dependents)
    print(io, "ComputeEdge(",
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
        print(io, "\n    ", dirty ? '↻' : '✓', ' ', v)
    end

    print(io, "\n  outputs:")
    for v in edge.outputs
        print(io, "\n    ", isdirty(v) ? '↻' : '✓', ' ', v)
    end

    print(io, "\n  dependents:")
    for v in edge.dependents
        print(io, "\n    ", isdirty(v) ? '↻' : '✓', ' ', v)
    end
end



function Base.show(io::IO, input::Input)
    print(io, "Input(:", input.name, ", ", input.value, ")")
end

function Base.show(io::IO, ::MIME"text/plain", input::Input)
    println(io, "Input:")
    println(io, "  name:     :", input.name)
    println(io, "  value:    ", input.value)
    f, loc = edge_callback_to_string(input)
    print(io, "  callback: $f")
    printstyled(io, " $loc\n", color = :light_black)
    println(io, "  output:   ", input.dirty ? '↻' : '✓', ' ', input.output)
    print(io, "  dependents:")
    for v in input.dependents
        print(io, "\n    ", isdirty(v) ? '↻' : '✓', ' ', v)
    end
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
    print(io, "ComputeGraph(",
        N1, " input$(N1 == 1 ? "" : 's'), ",
        N2, " output$(N2 == 1 ? "" : 's'), ",
        N3, " edge$(N3 == 1 ? "" : 's'))"
    )
end

function Base.show(io::IO, ::MIME"text/plain", graph::ComputeGraph)
    println(io, "ComputeGraph():")

    print(io, "  Inputs:")
    ks = sort!(collect(keys(graph.inputs)), by = string)
    pad = mapreduce(k -> length(string(k)), max, ks)
    for k in ks
        print(io, "\n    :", rpad(string(k), pad), " => ", graph.inputs[k])
    end

    print(io, "\n\n  Outputs:")
    ks = sort!(collect(keys(graph.outputs)), by = string)
    pad = mapreduce(k -> length(string(k)), max, ks)
    for k in ks
        print(io, "\n    :", rpad(string(k), pad), " => ", graph.outputs[k])
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
            i != N && print(", ")
        end
        println(io, "), …)")

        printstyled(io, "  @ $(edge_callback_location(edge))\n", color = :light_black)

        idx = findfirst(computed -> computed.name in marked, edge.inputs)
        if idx === nothing # All resolved
            println(io, "  with edge inputs:")
            for input in edge.inputs
                println(io, "    ", input.name, " = ", typeof(input.value[]))
            end
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
    println(io, "Triggered by update of:\n  ", join(root_inputs, ", ", " or "))
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

show_inputs(node::Computed) = show_inputs(stdout, node)
function show_inputs(io::IO, node::Computed, tab = 0)
    println(io, "    "^tab, node)
    show_inputs(io, node.parent, tab+1)
end
function show_inputs(io::IO, node::Input, tab = 0)
    println(io, "    "^tab, node)
end
function show_inputs(io::IO, edge::ComputeEdge, tab = 0)
    for node in edge.inputs
        show_inputs(io, node, tab)
    end
end
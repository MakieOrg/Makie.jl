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



edge_callback_name(f::Function, args = "…") = "$(nameof(f))($args)"
edge_callback_name(functor, args = "…") = "(::$(nameof(functor)))($args)"

function edge_callback_to_string(edge::ComputeEdge)
    inputT = typeof(ntuple(i -> edge.inputs[i].value, length(edge.inputs)))
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
    func = edge_callback_name(f, arg_str)
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
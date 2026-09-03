invalid_callback(args...) = error("The output node related to this callback is invalid and cannot not be resolved.")

"""
    modify_edge!(edge::ComputeEdge[; callback, inputs, outputs])

Modifies an existing compute edge.

## Keyword Arguments

`callback` can be given to replace the callback of the edge. If one or more
outputs have already been initialized the new callback must produce matching
types for those outputs. Note that for `map!` callbacks `packed` can be set to
`true` to mark the callback as returning a value that needs to be packed into
a tuple. Without this the callback is assumed to return a tuple.

`inputs` can be given to replace the inputs of the edge. The new inputs must
exist beforehand. This is generally safe to do assuming the callback can handle
the new inputs.

`outputs` can be given to replace the outputs of the edge. The new outputs must
exist beforehand. For each new output that has already been initialized the edge
must produce a value of matching type in its callback. Any old output that is
orphaned by replacing the edge outputs is considered invalid and will error when
resolved.
"""
function modify_edge!(edge::ComputeEdge; kwargs...)
    graph = edge.graph::ComputeGraph

    @lock graph.lock begin
        if haskey(kwargs, :inputs)
            if !all(name -> haskey(graph.outputs, name), kwargs[:inputs])
                error("Some inputs in $(kwargs[:inputs]) do not exist")
            end

            # disconnect old input.parent.dependents -> edge connections
            for old in edge.inputs
                filter!(e -> e !== edge, old.parent.dependents)
            end

            # replace inputs
            resize!(edge.inputs, length(kwargs[:inputs]))
            map!(name -> graph[name], edge.inputs, kwargs[:inputs])
            resize!(edge.inputs_dirty, length(kwargs[:inputs]))
            fill!(edge.inputs_dirty, true)

            # connect new inputs.parent.dependents -> edge connections
            for new in edge.inputs
                push!(new.parent.dependents, edge)
            end
        end

        # Note: This is quite unsafe when orphaned outputs have computations depending
        # on them. If those are pulled without the output being attached to something
        # no reasonable result can be produced.
        if haskey(kwargs, :outputs)
            if !all(name -> haskey(graph.outputs, name), kwargs[:outputs])
                error("Some outputs in $(kwargs[:outputs]) do not exist")
            end

            # disconnect all outputs
            # to keep track of dependencies we create dummy edges
            for node in edge.outputs
                dependents = filter(dep -> node in dep.inputs, edge.dependents)
                node.parent = ComputeEdge(
                    graph, invalid_callback,
                    Computed[], Bool[], [node],
                    Ref(true), dependents, Ref{TypedEdge}()
                )
                node.parent_idx = 1
            end

            # replace and connect outputs
            empty!(edge.dependents)
            resize!(edge.outputs, length(kwargs[:outputs]))
            for (i, name) in enumerate(kwargs[:outputs])
                node = graph[name]
                for dep in node.parent.dependents
                    if !in(dep, edge.dependents)
                        push!(edge.dependents, dep)
                    end
                end
                node.parent = edge
                node.parent_idx = i
                edge.outputs[i] = node
            end
        end

        if haskey(kwargs, :callback)
            # TODO: How do we deal with invalid_callback?
            # TODO: Or more generally decide between map-like and
            # TODO: register_computation-like callback handling?
            callback = kwargs[:callback]
            if !isa(callback, MapFunctionWrapper) && (isa(edge.callback, MapFunctionWrapper) || haskey(kwargs, :packed))
                callback = MapFunctionWrapper(callback, get(kwargs, :packed, false))
            end

            # Can't set callback, so need to replace edge
            new_edge = ComputeEdge(
                graph, callback,
                edge.inputs, edge.inputs_dirty, edge.outputs,
                Ref(false), edge.dependents, Ref{TypedEdge}()
            )
            for input in edge.inputs
                replace!(input.parent.dependents, edge => new_edge)
            end
            foreach(output -> output.parent = new_edge, edge.outputs)

            edge = new_edge
        end

        # If the edge has been initialized before we need to reinitialize it
        mark_dirty!(edge)
        if isassigned(edge.typed_edge)
            # Note: This is a locked resolve that sets edge.typed_edge
            foreach(_resolve!, edge.inputs)
            edge.typed_edge[] = TypedEdge(edge)
            edge.got_resolved[] = true
            fill!(edge.inputs_dirty, false)
            for dep in edge.dependents
                mark_input_dirty!(edge, dep)
            end
            foreach(comp -> comp.dirty = false, edge.outputs)
        end
    end

    return
end

"""
    modify_edge!(edge::Input[; callback, output])

Modifies an existing Input edge.

## Keyword Arguments

`callback` can be given to replace the callback of the edge. If one or more
outputs have already been initialized the new callback must produce matching
types for those outputs. Note that for `map!` callbacks `packed` can be set to
`true` to mark the callback as returning a value that needs to be packed into
a tuple. Without this the callback is assumed to return a tuple.

`outputs` can be given to replace the outputs of the edge. The new outputs must
exist beforehand. For each new output that has already been initialized the edge
must produce a value of matching type in its callback. Any old output that is
orphaned by replacing the edge outputs is considered invalid and will error when
resolved.
"""
function modify_edge!(edge::Input; kwargs...)
    graph = edge.graph::ComputeGraph

    @lock graph.lock begin
        # Note: This is quite unsafe when orphaned outputs have computations depending
        # on them. If those are pulled without the output being attached to something
        # no reasonable result can be produced.
        if haskey(kwargs, :output)
            name = kwargs[:output]
            if !haskey(graph.outputs, name)
                error("Node $name does not exist.")
            end

            # disconnect output
            # to keep track of dependencies we create dummy edges
            node = edge.output
            node.parent = ComputeEdge(
                graph, invalid_callback,
                Computed[], Bool[], [node],
                Ref(true), copy(node.parent.dependents), Ref{TypedEdge}()
            )
            node.parent_idx = 1

            # replace and connect outputs
            empty!(edge.dependents)
            node = graph[name]
            append!(edge.dependents, node.parent.dependents)
            setfield!(edge, :output, node)
            node.parent = edge
            node.parent_idx = 1
        end

        if haskey(kwargs, :callback)
            edge.callback = kwargs[:callback]
        end

        mark_dirty!(edge)
    end

    return
end

"""
    add_orphaned_node!(graph, name)

Creates a `Computed` node in the compute graph that is not connected to anything.
Such a node can not be resolved but it can be used as input with the promise
that it will later become an output via `modify_edge!`.
"""
function add_orphaned_node!(graph, name)
    node = Computed(name)
    node.parent = ComputeEdge(
        graph, invalid_callback,
        Computed[], Bool[], [node],
        Ref(true), ComputeEdge{ComputeGraph}[], Ref{TypedEdge}()
    )
    node.parent_idx = 1
    graph.outputs[name] = node
    return node
end

function replace_output!(edge::ComputeEdge, replacements::Pair{Symbol, Symbol}...)
    outputs = getproperty.(edge.outputs, :name)
    for (old, new) in replacements
        idx = findfirst(==(old), outputs)
        if isnothing(idx)
            new in outputs || error("Could not find $old in edge outputs $outputs.")
        else
            outputs[idx] = new
        end
    end
    modify_edge!(edge; outputs)
    return
end

function replace_output!(edge::Input, replacement::Pair{Symbol, Symbol})
    if !in(edge.output.name, replacement)
        error("Could not replace $(replacement[1]) as the given Input writes to $(edge.output.name).")
    end
    modify_edge!(edge; output = replacement[2])
    return
end

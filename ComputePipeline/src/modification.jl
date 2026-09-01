
function Base.empty!(attr::ComputeGraph)
    # empty!(attr.inputs)
    # empty!(attr.outputs)
    for (name, obs) in attr.observables
        Observables.clear(obs)
    end
    empty!(attr.observables)
    for of in attr.observerfunctions
        Observables.off(of)
    end
    return empty!(attr.observerfunctions)
end

"""
    delete!(graph::ComputeGraph, key::Symbol[; force = false, recursive = false])

Deletes a node from the given graph based on its name.

If `recursive = true` all child nodes of the selected node are deleted. If
`force = true` all siblings (outputs from the same parent edge) are deleted.
If either exists without the respective option being true an error will be thrown.
"""
function Base.delete!(attr::ComputeGraph, key::Symbol; force::Bool = false, recursive::Bool = false)
    haskey(attr.outputs, key) || throw(KeyError(key))
    @lock GLOBAL_LOCK begin
        _delete!(attr, attr.outputs[key], force, recursive)
    end
    return attr
end

function _delete!(attr::ComputeGraph, node::Computed, force::Bool, recursive::Bool)
    @assert hasparent(node)
    _delete!(attr, node.parent, force, recursive)
    return attr
end

function validate_deletion(edge::ComputeEdge, force::Bool, recursive::Bool)
    force && recursive && return
    if !(length(edge.outputs) == 1 || force)
        error("Cannot delete node because it or one of its dependents has siblings. Set `force = true` to also delete siblings.")
    end
    if !(recursive || isempty(edge.dependents))
        error("Cannot delete node because it has children. Set `recursive = true` to also delete its children.")
    end
    return foreach(e -> validate_deletion(e, force, recursive), edge.dependents)
end

function validate_deletion(edge::Input, force::Bool, recursive::Bool)
    force && recursive && return
    if !(recursive || isempty(edge.dependents))
        error("Cannot delete node because it has children. Set `recursive = true` to also delete its children.")
    end
    return foreach(e -> validate_deletion(e, force, recursive), edge.dependents)
end

function _delete!(attr::ComputeGraph, edge::AbstractEdge, force::Bool, recursive::Bool)
    validate_deletion(edge, force, recursive)
    return unsafe_delete!(attr, edge)
end

function unsafe_delete!(attr::ComputeGraph, edge::ComputeEdge)
    # all dependents become invalid as their parent computation no longer runs
    for dependent in edge.dependents
        unsafe_delete!(attr, dependent)
    end

    # deregister this edge as a dependency of its parents
    for computed in edge.inputs
        @assert hasparent(computed)
        parent_edge = computed.parent
        filter!(e -> e !== edge, parent_edge.dependents)
    end

    # Delete output nodes of this edge
    for computed in edge.outputs
        k = computed.name
        @assert haskey(attr.outputs, k) && attr.outputs[k] === computed
        delete!(attr.outputs, k)
    end

    return attr
end

function unsafe_delete!(attr::ComputeGraph, edge::Input)
    # all dependents become invalid as their parent computation no longer runs
    for dependent in edge.dependents
        unsafe_delete!(attr, dependent)
    end

    # Delete output node of this edge
    k = edge.name
    @assert haskey(attr.outputs, k) && attr.outputs[k] === edge.output
    delete!(attr.outputs, k)

    # Delete Input
    @assert haskey(attr.inputs, k) && attr.inputs[k] === edge
    delete!(attr.inputs, k)

    return attr
end


"""
    disconnect!(graph)

Removes every connection from this graph to another graph.

After calling this function, parts or all of the given `graph` may no longer be
resolvable. Any graph that depends on the given `graph` may also be partially
or fully unresolvable due to missing connetions.

Note that this "deletes" any edge that involves this `graph` and another graph.
Edges that output to multiple other graphs will therefore be deleted for all
other graphs as well. Same for edges that input from this and other graphs.
"""
function disconnect!(attr::ComputeGraph)
    for comp in values(attr.outputs)
        if hasparent(comp)
            disconnect_cross_graph!(attr, comp.parent)
        end
    end
    return
end

disconnect_cross_graph!(attr::ComputeGraph, edge::Input) = nothing
function disconnect_cross_graph!(attr::ComputeGraph, edge::ComputeEdge)
    for input in edge.inputs
        # could skip the haskey, but maybe good for performance?
        if !haskey(attr.outputs, input.name) || !in(input, values(attr.outputs))
            delete!(edge)
        end
    end
    for dep in edge.dependents
        if dep.graph !== attr
            delete!(dep)
        end
    end
    return
end

@deprecate unsafe_disconnect_from_parents!(graph) disconnect!(graph) false

is_initialized(node::Computed) = isdefined(node, :value) && isassigned(node.value)

"""
    unsafe_init!(node::Computed, value)

Initializes a node to the given value. If this causes all outputs of the parent
compute edge to be initialized, the edge will be initialized without calling its
callback.

This function makes no checks to confirm that the given value matches the type
returned by the parent edge callback.
"""
function unsafe_init!(node::Computed, value)
    if isdefined(node, :value)
        error("Node already initialized.")
    else
        node.value = value isa RefValue ? value : RefValue(value)
    end

    return unsafe_init!(node.parent)
end

function unsafe_init!(edge::ComputeEdge)
    # We can only mark the edge as initialized if all the outputs have been
    # initialized
    if !all(is_initialized, edge.outputs)
        return false
    end

    @lock GLOBAL_LOCK begin
        foreach(locked_resolve!, edge.inputs)
        edge.typed_edge[] = TypedEdge_no_call(edge)
        edge.got_resolved[] = true
        for dep in edge.dependents
            mark_input_dirty!(edge, dep)
        end
        foreach(comp -> comp.dirty = false, edge.outputs)
    end
    return true
end

function unsafe_init!(input::Input)
    input.dirty = false
    input.output.dirty = true
    for edge in input.dependents
        mark_input_dirty!(input, edge)
    end
    input.output.dirty = false
    return true
end

function TypedEdge_no_call(edge::ComputeEdge)
    inputs = let
        N = length(edge.inputs)
        names = ntuple(i -> edge.inputs[i].name, N)
        values = ntuple(i -> edge.inputs[i].value, N)
        NamedTuple{names}(values)
    end

    outputs = let
        N = length(edge.outputs)
        names = ntuple(i -> edge.outputs[i].name, N)
        values = ntuple(i -> edge.outputs[i].value, N)
        NamedTuple{names}(values)
    end

    return TypedEdge(edge.callback, inputs, edge.inputs_dirty, outputs, edge.outputs)
end

"""
    set_type!(node::Computed, type)

Initialize a compute graph `node` to the given `type`.

```
map!(x -> rand([1, 1.0, "1"]), graph, :input, :output)
set_type!(graph.output, Union{Int, Float64, String})
```
"""
function set_type!(node::Computed, T::Type)
    if isdefined(node, :value)
        error("Node already initialized.")
    else
        node.value = Ref{T}()
    end
    return
end

"""
    set_type!(view::ComputeGraphView, type)

Initialize every uninitialized node in the view to the given `type`.
"""
function set_type!(view::ComputeGraphView, T::Type)
    for (k, element) in view
        maybe_set_type!(element, T)
    end
    return
end

################################################################################
# TODO: test this:

maybe_set_type!(view::ComputeGraphView, T) = set_type!(view, T)
function maybe_set_type!(node::Computed, T)
    if !isdefined(node, :value)
        set_type!(node, T)
    end
    return
end

invalid_callback(args...) = error("The output node related to this callback is invalid and cannot not be resolved.")

# Warning: This does not completely disconnect the edge. Its outputs may still
# refer to it
function _disconnect_edge_from_inputs!(edge::ComputeEdge)
    # disconnect old input.parent.dependents -> edge connections
    for old in edge.inputs
        filter!(e -> e !== edge, old.parent.dependents::Vector{ComputeEdge{ComputeGraph}})
    end
    return
end

# Warning: This does not completely disconnect the parent edge. It may still
# exist in dependents of its inputs.
function _disconnect_node_from_parent!(node::Computed, callback = invalid_callback)
    # To preserve the connections from node -> other nodes, we keep track of all
    # of the parent edge dependents that rely on this node
    graph = node.parent.graph::ComputeGraph
    dependents = filter(dep -> node in dep.inputs, node.parent.dependents)
    node.parent = ComputeEdge(
        graph, callback,
        Computed[], Bool[], [node],
        Ref(true), dependents, Ref{TypedEdge}()
    )
    node.parent_idx = 1
    return
end

function _replace_edge!(edge, new_edge)
    for input in edge.inputs
        replace!(input.parent.dependents, edge => new_edge)
    end
    foreach(output -> output.parent = new_edge, edge.outputs)
    return
end

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

    @lock GLOBAL_LOCK begin
        if haskey(kwargs, :inputs)
            new_inputs = kwargs[:inputs]
            if !isa(new_inputs, AbstractVector{Computed})
                error("`inputs` must be a Vector of `Computed` nodes.")
            end

            _disconnect_edge_from_inputs!(edge)

            # replace inputs
            resize!(edge.inputs, length(new_inputs))
            copyto!(edge.inputs, new_inputs)
            resize!(edge.inputs_dirty, length(new_inputs))
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
            new_outputs = kwargs[:outputs]
            if !isa(new_outputs, AbstractVector{Computed})
                error("`outputs` must be a Vector of `Computed` nodes.")
            end

            # disconnect all outputs
            foreach(_disconnect_node_from_parent!, edge.outputs)

            # replace and connect outputs
            empty!(edge.dependents)
            resize!(edge.outputs, length(new_outputs))
            for (i, node) in enumerate(new_outputs)
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

            _replace_edge!(edge, new_edge)

            edge = new_edge
        end

        # If the edge has been initialized before we need to reinitialize it
        mark_dirty!(edge)
        if isassigned(edge.typed_edge)
            # Note: This is a locked resolve that sets edge.typed_edge
            foreach(locked_resolve!, edge.inputs)
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

    @lock GLOBAL_LOCK begin
        # Note: This is quite unsafe when orphaned outputs have computations depending
        # on them. If those are pulled without the output being attached to something
        # no reasonable result can be produced.
        if haskey(kwargs, :output)
            new_output = kwargs[:output]
            if !isa(new_output, Computed)
                error("`output` must be a `Computed` node.")
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
            append!(edge.dependents, new_node.parent.dependents)
            setfield!(edge, :output, new_node)
            new_node.parent = edge
            new_node.parent_idx = 1
        end

        if haskey(kwargs, :callback)
            edge.callback = kwargs[:callback]
        end

        mark_dirty!(edge)
    end

    return
end

function replace_input!(_callback, new_sources, output::Computed)
    input = output.parent::Input
    graph = output.parent.graph

    # Build new edge
    inputs = convert_to_nodes(graph, new_sources)
    output.parent = ComputeEdge(
        graph, MapFunctionWrapper(_callback),
        inputs, fill(true, length(inputs)), [output],
        Ref(false), input.dependents, Ref{TypedEdge}()
    )
    output.parent_idx = 1
    for input in inputs
        push!(input.parent.dependents, output.parent)
    end

    # Remove Input/make it GC-able
    delete!(graph.inputs, output.name)
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
    graph = edge.graph::ComputeGraph
    outputs = getproperty.(edge.outputs, :name)
    for (old, new) in replacements
        idx = findfirst(node -> node.name == old, outputs)
        if isnothing(idx)
            new in outputs || error("Could not find $old in edge outputs $outputs.")
        else
            outputs[idx] = graph[new]
        end
    end
    modify_edge!(edge; outputs)
    return
end

function replace_output!(edge::Input, replacement::Pair{Symbol, Symbol})
    graph = edge.graph::ComputeGraph
    if !in(edge.output.name, replacement)
        error("Could not replace $(replacement[1]) as the given Input writes to $(edge.output.name).")
    end
    modify_edge!(edge; output = graph[replacement[2]])
    return
end

function push_input!(edge::ComputeEdge, node::Computed)
    inputs = push!(copy(edge.inputs), node)
    modify_edge!(edge; inputs)
    return
end

function delete_input!(edge::ComputeEdge, node::Computed)
    inputs = filter(x -> x !== node, edge.inputs)
    modify_edge!(edge; inputs)
    return
end

function delete_output!(edge::ComputeEdge, node::Computed)
    outputs = filter(x -> x !== node, edge.outputs)
    modify_edge!(edge; outputs)
    return
end

function Base.delete!(edge::ComputeEdge)
    # Remove references into this edge
    _disconnect_edge_from_inputs!(edge)

    # Replace output references to this edge so it can be GC'd
    # Note: Does this keep outputs resolved so they can still be used?
    foreach(_disconnect_node_from_parent!, edge.outputs)

    return
end

function _validate_node_move(target::ComputeGraph, source::ComputeGraph, node::Computed)
    exists_in_source = haskey(source.outputs, node.name)
    space_in_target = !haskey(target.outputs, node.name)
    path = Symbol.(split(string(node.name), '.'))
    if length(path) != 1
        exists_in_source &= haskey(source.nesting, path)
    end
    return exists_in_source && space_in_target
end
function _move_node!(target::ComputeGraph, source::ComputeGraph, node::Computed)
    delete!(source.outputs, node.name)
    target.outputs[node.name] = node
    path = Symbol.(split(string(node.name), '.'))
    if length(path) != 1
        delete_key!(source.nesting, path)
        add_key!(target.nesting, path)
    end
    return
end

function move!(target::ComputeGraph, node::Computed, move_siblings = true)
    edge = node.parent
    source = edge.graph

    if move_siblings
        for _node in edge.outputs
            _validate_node_move(target, source, _node)
        end
        for _node in edge.outputs
            _move_node!(target, source, _node)
        end
    else
        _validate_node_move(target, source, node)
        _move_node!(target, source, node)
    end

    new_edge = ComputeEdge(
        target, edge.callback,
        edge.inputs, edge.inputs_dirty, edge.outputs,
        edge.got_resolved, edge.dependents, edge.typed_edge
    )

    _replace_edge!(edge, new_edge)

    return
end
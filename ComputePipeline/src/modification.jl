"""
    unsafe_replace_input!(target::ComputeEdge, new_input::Computed[, n = 1])
    unsafe_replace_input!(target::Computed, new_input::Computed[, n = 1])

Replaces the `n`-th input node of a `target` edge with the given `new_input`
node. If `target` is a `Computed`, the n-th node in its parent compute edge
will be replaced. I.e. `target` is the node whose input changes.

Note that this function does not validate if the operation is legal. If the
edge callback can not process the content of `new_input` or if the replacement
causes the output type to change, the next resolve may error. It may make
sense to immediately resolve `target` after this to check.
"""
function unsafe_replace_input!(target::Computed, new_input::Computed, n = 1)
    return unsafe_replace_input!(target.parent, new_input, n)
end

function unsafe_replace_input!(target::ComputeEdge, new_input::Computed, n = 1)
    # Should maybe type check compatibility of old and new_input?
    # Or maybe not, because the edge could be able to process various types?

    # make sure things are initialized
    new_input[]
    target.outputs[1][]

    @lock target.graph.lock begin
        # replace edge information
        old = target.inputs[n]
        target.inputs[n] = new_input
        filter!(e -> e !== target, old.parent.dependents)
        push!(new_input.parent.dependents, target)

        # replace typed_edge
        rebuild_typed_edge!(target, n)
    end

    # notify dependents
    mark_dirty!(new_input)

    return
end

function rebuild_typed_edge!(target::ComputeEdge, indices = eachindex(target.inputs))
    return rebuild_typed_edge!(target.callback, target, indices)
end

function rebuild_typed_edge!(callback, target::ComputeEdge, indices = eachindex(target.inputs))
    te = target.typed_edge[]
    if isa(te.callback, MapFunctionWrapper) && !isa(callback, MapFunctionWrapper)
        return rebuild_typed_edge!(
            MapFunctionWrapper(callback, ispacked(te.callback)), target, indices
        )
    end

    inputs = let
        N = length(target.inputs)
        names = ntuple(i -> target.inputs[i].name, N)
        values = ntuple(i -> target.inputs[i].value, N)
        NamedTuple{names}(values)
    end

    if te.callback === compute_identity || callback === compute_identity
        if te.callback !== callback
            error("Switching to or away from `compute_identity` callbacks is currently not implemented.")
        end

        # compute_identity skips the computation and just duplicates the ref
        # of the input node in the output node.
        # Technically we don't need to update target.typed_edge[] at all
        # because of this, because it never accesses the node data. But
        # it's probably better to keep it up to date...
        target.typed_edge[] = TypedEdge(
            callback,
            inputs,
            te.inputs_dirty,
            inputs,
            te.output_nodes
        )

        # What we do have to update is the ref held by the output:
        for n in indices
            te.output_nodes[n].value = target.inputs[n].value
        end

        # The ref held by outputs also ends up in the typed_edge of each
        # dependent, so we need to replace those too:
        for dep in target.dependents
            te = dep.typed_edge[]
            inputs = let
                N = length(dep.inputs)
                names = ntuple(i -> dep.inputs[i].name, N)
                values = ntuple(i -> dep.inputs[i].value, N)
                NamedTuple{names}(values)
            end
            dep.typed_edge[] = TypedEdge(
                te.callback,
                inputs,
                te.inputs_dirty,
                te.outputs,
                te.output_nodes
            )
        end
    else
        target.typed_edge[] = TypedEdge(
            callback,
            inputs,
            te.inputs_dirty,
            te.outputs,
            te.output_nodes
        )
        for n in indices
            target.typed_edge[].inputs_dirty[n] = true
        end
    end
end

"""
    unsafe_replace_inputs!([callback], target::ComputeEdge, new_inputs)
    unsafe_replace_inputs!([callback], target::Computed, new_inputs)

Replaces all input nodes of a `target` edge with the given `new_inputs`. If
`callback` is given it will be replaced as well. If `target` is a `Computed`,
its parent compute edge will be changed.

Note that this function does not validate if the operation is legal. If the (new)
edge callback can not process the content of any new input node or if the replacement
causes the output type to change, the next resolve may error. It may make
sense to immediately resolve `target` after this to check.
"""
function unsafe_replace_inputs!(target::Computed, new_inputs::Union{AbstractArray, Tuple})
    return unsafe_replace_inputs!(target.parent, new_inputs)
end

function unsafe_replace_inputs!(callback, target::Computed, new_inputs::Union{AbstractArray, Tuple})
    return unsafe_replace_inputs!(callback, target.parent, new_inputs)
end

function unsafe_replace_inputs!(target::Union{Computed, ComputeEdge}, new_inputs::Computed...)
    return unsafe_replace_inputs!(target.parent, new_inputs)
end

function unsafe_replace_inputs!(callback, target::Union{Computed, ComputeEdge}, new_inputs::Computed...)
    return unsafe_replace_inputs!(callback, target.parent, new_inputs)
end

function unsafe_replace_inputs!(target::ComputeEdge, new_inputs::Union{AbstractArray, Tuple})
    return unsafe_replace_inputs!(target.callback, target, new_inputs)
end

function unsafe_replace_inputs!(callback, target::ComputeEdge, new_inputs::Union{AbstractArray, Tuple})
    # make sure things are initialized
    foreach(getindex, new_inputs)
    target.outputs[1][]

    @lock target.graph.lock begin
        # replace edge information
        for old in target.inputs
            filter!(e -> e !== target, old.parent.dependents)
        end
        resize!(target.inputs, length(new_inputs))
        target.inputs .= new_inputs
        for new in new_inputs
            push!(new.parent.dependents, target)
        end

        # replace typed_edge
        rebuild_typed_edge!(callback, target)
    end

    # notify dependents
    foreach(mark_dirty!, new_inputs)

    return
end

# Consider adding:
# - remove_edge, validation of graph connectivity (and extend map!() to work
#   for connecting existing nodes)
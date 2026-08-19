struct ExplicitUpdate{T}
    data::T
    rule::Symbol

    function ExplicitUpdate{T}(data::T, rule::Symbol) where {T}
        if !in(rule, (:force, :auto, :deny))
            error("Invalid value for should_update: :$should_update. Must be :force, :auto or :deny")
        end
        return new{T}(data, rule)
    end
end

"""
    ExplicitUpdate(data, strategy)

Wraps a value in ComputeGraph to mark its update strategy. Can be:
- `:force`: always propagate update
- `:deny`: never propagate update
- `:auto`: propagate update if `is_same(previous_data, new_data)` is false

Unmarked data uses `:auto`.

See also [`unwrap_explicit_update`](@ref)
"""
function ExplicitUpdate(data::T, rule::Symbol = :auto) where {T}
    return ExplicitUpdate{T}(data, rule)
end

is_same(old::ExplicitUpdate, new) = is_same(old.data, new)
is_same(old::ExplicitUpdate, new::ExplicitUpdate) = is_same(old.data, new)
function is_same(old, new::ExplicitUpdate)
    if new.rule == :auto
        return is_same(old, new.data)
    else
        # force should always fail the is_same discard, deny should always pass
        return new.rule == :deny
    end
end

"""
    unwrap_explicit_update(x)

Returns the value contained in an ExplicitUpdate `x` if one is passed. Otherwise
return `x`.
"""
unwrap_explicit_update(x) = x
unwrap_explicit_update(x::ComputePipeline.ExplicitUpdate) = x.data

export ExplicitUpdate, unwrap_explicit_update

"""
    pick_ifelse(graph, condition, choice1, choice2, output)

Calls `map!(ifelse, graph, [condition, choice1, choice2], output)` which sets
`output` to `choice1` or `choice2` based on `condition` when resolved.

This uses a special path in `resolve!` to only evaluate one of the two branches.
"""
function pick_ifelse(graph, condition, choice1, choice2, output::Symbol)
    map!(ifelse, graph, [condition, choice1, choice2], output)
    return
end

"""
    pick_ifelse(callback, graph, condition_inputs, choice1, choice2, output)

Adds `map!(callback, graph, condition_inputs, anon_node)` to map the
`condition_inputs` to a boolean node using `callback` and
`map!(ifelse, graph, [anon_node, choice1, choice2], output)` to pick `choice1`
or `choice2` based on the result.

This uses a special path in `resolve!` to only evaluate one of the two branches.
"""
function pick_ifelse(callback, graph, condition_inputs, choice1, choice2, output::Symbol)
    condition = Symbol(output, :_picker)
    map!(callback, graph, condition_inputs, condition)
    map!(ifelse, graph, [condition, choice1, choice2], output)
    return
end

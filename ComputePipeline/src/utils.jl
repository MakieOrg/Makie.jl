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

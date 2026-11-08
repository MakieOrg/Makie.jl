mutable struct ComponentState
    lock::ReentrantLock
    # Union-find parent for lock groups, independent of compute dependencies.
    @atomic parent::Union{Nothing, ComponentState}
    depth::Int
    pending::Vector{Function}
    notifications::Vector{Observable}
end
ComponentState() = ComponentState(ReentrantLock(), nothing, 0, Function[], Observable[])

function component(state::ComponentState)
    while true
        parent = @atomic :acquire state.parent
        isnothing(parent) && return state
        state = parent
    end
    return
end

function lock_component(graph)
    state = getfield(graph, :state)
    while true
        state = component(state)
        lock(state.lock)
        # A merge may have moved this root while we waited for its lock.
        isnothing(@atomic :acquire state.parent) && return state
        unlock(state.lock)
    end
    return
end

macro graphlock(graph, state, body)
    return esc(
        quote
            local $state = lock_component($graph)
            try
                $body
            finally
                unlock($state.lock)
            end
        end
    )
end

function connect_components!(graph, source)
    while true
        a = component(getfield(graph, :state))
        b = component(getfield(source, :state))
        a === b && return
        first, second = objectid(a) < objectid(b) ? (a, b) : (b, a)
        lock(first.lock)
        try
            lock(second.lock)
            try
                # Retry if another connection changed either root.
                if !isnothing(@atomic :acquire a.parent) || !isnothing(@atomic :acquire b.parent)
                    continue
                end
                a.depth == b.depth == 0 || error("Cannot connect graphs from a computation callback")
                @atomic :release second.parent = first
                return
            finally
                unlock(second.lock)
            end
        finally
            unlock(first.lock)
        end
    end
    return
end

function finish_resolve!(state)
    state.depth -= 1
    if state.depth == 0 && !isempty(state.pending)
        pending = copy(state.pending)
        empty!(state.pending)
        foreach(f -> f(), pending)
    end
    return
end

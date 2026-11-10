mutable struct ComponentState
    lock::ReentrantLock
    # Union-find parent for lock groups, independent of compute dependencies.
    @atomic parent::Union{Nothing, ComponentState}
    depth::Int
    active_callback::Any
    active_callbacks::Vector{Any}
    pending::Vector{Function}
    notifications::Vector{Observable}
end
ComponentState() = ComponentState(ReentrantLock(), nothing, 0, nothing, Any[], Function[], Observable[])

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
        lock_resolution_state(state)
        # A merge may have moved this root while we waited for its lock.
        isnothing(@atomic :acquire state.parent) && return state
        unlock(state.lock)
    end
    return
end

mutable struct ResolutionTaskState
    current::Union{Nothing, ComponentState}
end

@inline function task_resolution_state()
    storage = task_local_storage()
    value = get(storage, :ComputePipeline_resolution, nothing)
    value isa ResolutionTaskState && return value
    value = ResolutionTaskState(nothing)
    storage[:ComputePipeline_resolution] = value
    return value
end

function current_resolution()
    value = get(task_local_storage(), :ComputePipeline_resolution, nothing)
    return value isa ResolutionTaskState ? value.current : nothing
end

# Only the contended path consults task-local state; cached reads keep the fast path.
@inline function lock_resolution_state(state)
    trylock(state.lock) && return
    return wait_resolution_state(state)
end

@noinline function wait_resolution_state(state)
    isnothing(current_resolution()) ||
        throw(ArgumentError("Cannot wait for another graph from a computation callback; declare it as an input."))
    lock(state.lock)
    return
end

@inline function begin_resolve!(state)
    previous = nothing
    if state.depth == 0
        task_state = task_resolution_state()
        previous = task_state.current
        task_state.current = state
    end
    state.depth += 1
    return previous
end

function take_notifications!(state)
    state.depth == 0 && !isempty(state.notifications) || return ()
    result = copy(state.notifications)
    empty!(state.notifications)
    return result
end

macro resolvelock(graph, state, body)
    return esc(
        quote
            local $state = lock_component($graph)
            local notifications = ()
            try
                local previous = begin_resolve!($state)
                try
                    $body
                finally
                    finish_resolve!($state, previous)
                    notifications = take_notifications!($state)
                end
            finally
                unlock($state.lock)
                foreach(notify, notifications)
            end
        end
    )
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
        active = current_resolution()
        if active === a || active === b
            throw(ArgumentError("Cannot connect graphs from a computation callback"))
        end
        first, second = objectid(a) < objectid(b) ? (a, b) : (b, a)
        lock_resolution_state(first)
        try
            lock_resolution_state(second)
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

function finish_resolve!(state, previous)
    state.depth -= 1
    if state.depth == 0
        try
            if !isempty(state.pending)
                pending = copy(state.pending)
                empty!(state.pending)
                foreach(f -> f(), pending)
            end
        finally
            task_resolution_state().current = previous
        end
    end
    return
end

function check_callback_cycle(state, output)
    (state.active_callback === output || any(active -> active === output, state.active_callbacks)) &&
        throw(ArgumentError("Recursive resolution of a computation already executing its callback."))
    return
end

@inline function enter_callback!(state, output)
    previous = state.active_callback
    isnothing(previous) || push!(state.active_callbacks, previous)
    state.active_callback = output
    return previous
end

@inline function leave_callback!(state, previous)
    state.active_callback = previous
    isnothing(previous) || pop!(state.active_callbacks)
    return
end

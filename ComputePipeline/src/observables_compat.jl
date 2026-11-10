@inline function Observables.on(f, x::Computed; kwargs...)
    obs = get_initial_observable!(x)
    listener = on(f, obs; kwargs...)
    refresh_initial_observable!(x)
    return listener
end

@inline function refresh_initial_observable!(x)
    x isa Computed && refresh_initial_observable!(x, x.parent)
    return
end

function refresh_initial_observable!(x::Computed, parent::AbstractEdge, only_clean::Bool = false)
    graph = parent.graph
    local pending
    @graphlock graph state begin
        dirty = isdirty(parent)
        queued = x.name in graph.onchange.val
        only_clean && (dirty || !queued) && return
        if dirty || queued
            push!(graph.onchange.val, x.name)
            graph.onchange in graph.obs_to_update || push!(graph.obs_to_update, graph.onchange)
        end
        pending = take_updates!(graph)
        if state.depth > 0
            for obs in pending
                obs in state.notifications || push!(state.notifications, obs)
            end
            return
        end
    end
    foreach(notify, pending)
    return
end

@inline function refresh_clean_observable!(x)
    x isa Computed && refresh_initial_observable!(x, x.parent, true)
    return
end

# Reconcile clean values before installing listeners, then propagate deferred
# dirty values afterward to preserve initialization events such as [1, 2].
function prepare_observable_binding!(args)
    length(args) > 1 || return
    foreach(refresh_clean_observable!, args)
    return
end

function finish_observable_binding!(result, args)
    foreach(refresh_initial_observable!, args)
    return result
end

function Observables.connect!(target::Observables.AbstractObservable, source::Computed)
    result = Observables.connect!(target, get_initial_observable!(source))
    refresh_initial_observable!(source)
    return result
end

Base.convert(::Type{T}, c::Computed) where {T <: Observable} = get_observable!(c)

# This generates all the functions below, as strings, and appends them to this file.

# They are needed to catch cases where functions like `onany` are called with N
# `Observables` before the first `Computed`. E.g.
#    onany(f, obs1, obs2, obs3, graph.computed)
# Technically we need infinitely many of these to cover all possible call
# signatures. This file currently includes up to 10 Observables before the first
# computed

#=
open(@__FILE__, "a") do file
    for N in 0:10
        arglist = ["arg$i::AbstractObservable" for i in 1:N]
        push!(arglist, "arg$(N+1)::Computed, rest::Union{AbstractObservable, Computed}...")
        args = join(arglist, ", ")

        arg_tuple = "args = tuple($(join(["arg$i" for i in 1:N+1], ", ")), rest...)"

        funcs = """

        function Observables.onany(f, $args; kwargs...)
            $arg_tuple
            obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
            prepare_observable_binding!(args)
            @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
            return finish_observable_binding!(onany(f, obsies...; kwargs...), args)
        end

        function Observables.map!(f, target::Observable, $args; kwargs...)
            $arg_tuple
            obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
            prepare_observable_binding!(args)
            @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
            return finish_observable_binding!(map!(f, target, obsies...; kwargs...), args)
        end

        function Observables.map(f, $args; kwargs...)
            $arg_tuple
            obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
            prepare_observable_binding!(args)
            @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
            return finish_observable_binding!(map(f, obsies...; kwargs...), args)
        end
        """

        print(file, funcs)
    end
end
=#

function Observables.onany(f, arg1::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(onany(f, obsies...; kwargs...), args)
end

function Observables.map!(f, target::Observable, arg1::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(map!(f, target, obsies...; kwargs...), args)
end

function Observables.map(f, arg1::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(map(f, obsies...; kwargs...), args)
end

function Observables.onany(f, arg1::AbstractObservable, arg2::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(onany(f, obsies...; kwargs...), args)
end

function Observables.map!(f, target::Observable, arg1::AbstractObservable, arg2::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(map!(f, target, obsies...; kwargs...), args)
end

function Observables.map(f, arg1::AbstractObservable, arg2::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(map(f, obsies...; kwargs...), args)
end

function Observables.onany(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(onany(f, obsies...; kwargs...), args)
end

function Observables.map!(f, target::Observable, arg1::AbstractObservable, arg2::AbstractObservable, arg3::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(map!(f, target, obsies...; kwargs...), args)
end

function Observables.map(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(map(f, obsies...; kwargs...), args)
end

function Observables.onany(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(onany(f, obsies...; kwargs...), args)
end

function Observables.map!(f, target::Observable, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(map!(f, target, obsies...; kwargs...), args)
end

function Observables.map(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(map(f, obsies...; kwargs...), args)
end

function Observables.onany(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(onany(f, obsies...; kwargs...), args)
end

function Observables.map!(f, target::Observable, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(map!(f, target, obsies...; kwargs...), args)
end

function Observables.map(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(map(f, obsies...; kwargs...), args)
end

function Observables.onany(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(onany(f, obsies...; kwargs...), args)
end

function Observables.map!(f, target::Observable, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(map!(f, target, obsies...; kwargs...), args)
end

function Observables.map(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(map(f, obsies...; kwargs...), args)
end

function Observables.onany(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(onany(f, obsies...; kwargs...), args)
end

function Observables.map!(f, target::Observable, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(map!(f, target, obsies...; kwargs...), args)
end

function Observables.map(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(map(f, obsies...; kwargs...), args)
end

function Observables.onany(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(onany(f, obsies...; kwargs...), args)
end

function Observables.map!(f, target::Observable, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(map!(f, target, obsies...; kwargs...), args)
end

function Observables.map(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(map(f, obsies...; kwargs...), args)
end

function Observables.onany(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::AbstractObservable, arg9::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(onany(f, obsies...; kwargs...), args)
end

function Observables.map!(f, target::Observable, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::AbstractObservable, arg9::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(map!(f, target, obsies...; kwargs...), args)
end

function Observables.map(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::AbstractObservable, arg9::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(map(f, obsies...; kwargs...), args)
end

function Observables.onany(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::AbstractObservable, arg9::AbstractObservable, arg10::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(onany(f, obsies...; kwargs...), args)
end

function Observables.map!(f, target::Observable, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::AbstractObservable, arg9::AbstractObservable, arg10::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(map!(f, target, obsies...; kwargs...), args)
end

function Observables.map(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::AbstractObservable, arg9::AbstractObservable, arg10::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(map(f, obsies...; kwargs...), args)
end

function Observables.onany(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::AbstractObservable, arg9::AbstractObservable, arg10::AbstractObservable, arg11::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(onany(f, obsies...; kwargs...), args)
end

function Observables.map!(f, target::Observable, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::AbstractObservable, arg9::AbstractObservable, arg10::AbstractObservable, arg11::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(map!(f, target, obsies...; kwargs...), args)
end

function Observables.map(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::AbstractObservable, arg9::AbstractObservable, arg10::AbstractObservable, arg11::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, rest...)
    obsies = map(x -> x isa Computed ? get_initial_observable!(x) : x, args)
    prepare_observable_binding!(args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return finish_observable_binding!(map(f, obsies...; kwargs...), args)
end

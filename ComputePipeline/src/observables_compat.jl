function Observables.on(f, x::Computed; kwargs...)
    obs = get_observable!(x)
    return on(f, obs; kwargs...)
end

function Observables.connect!(target::Observables.AbstractObservable, source::Computed)
    return Observables.connect!(target, get_observable!(source))
end

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
            obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
            @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
            return onany(f, obsies...; kwargs...)
        end

        function Observables.map!(f, target::Observable, $args; kwargs...)
            $arg_tuple
            obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
            @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
            return map!(f, target, obsies...; kwargs...)
        end

        function Observables.map(f, $args; kwargs...)
            $arg_tuple
            obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
            @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
            return map(f, obsies...; kwargs...)
        end
        """

        print(file, funcs)
    end
end
=#

function Observables.onany(f, arg1::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return onany(f, obsies...; kwargs...)
end

function Observables.map!(f, target::Observable, arg1::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return map!(f, target, obsies...; kwargs...)
end

function Observables.map(f, arg1::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return map(f, obsies...; kwargs...)
end

function Observables.onany(f, arg1::AbstractObservable, arg2::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return onany(f, obsies...; kwargs...)
end

function Observables.map!(f, target::Observable, arg1::AbstractObservable, arg2::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return map!(f, target, obsies...; kwargs...)
end

function Observables.map(f, arg1::AbstractObservable, arg2::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return map(f, obsies...; kwargs...)
end

function Observables.onany(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return onany(f, obsies...; kwargs...)
end

function Observables.map!(f, target::Observable, arg1::AbstractObservable, arg2::AbstractObservable, arg3::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return map!(f, target, obsies...; kwargs...)
end

function Observables.map(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return map(f, obsies...; kwargs...)
end

function Observables.onany(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return onany(f, obsies...; kwargs...)
end

function Observables.map!(f, target::Observable, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return map!(f, target, obsies...; kwargs...)
end

function Observables.map(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return map(f, obsies...; kwargs...)
end

function Observables.onany(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return onany(f, obsies...; kwargs...)
end

function Observables.map!(f, target::Observable, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return map!(f, target, obsies...; kwargs...)
end

function Observables.map(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return map(f, obsies...; kwargs...)
end

function Observables.onany(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return onany(f, obsies...; kwargs...)
end

function Observables.map!(f, target::Observable, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return map!(f, target, obsies...; kwargs...)
end

function Observables.map(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return map(f, obsies...; kwargs...)
end

function Observables.onany(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return onany(f, obsies...; kwargs...)
end

function Observables.map!(f, target::Observable, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return map!(f, target, obsies...; kwargs...)
end

function Observables.map(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return map(f, obsies...; kwargs...)
end

function Observables.onany(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return onany(f, obsies...; kwargs...)
end

function Observables.map!(f, target::Observable, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return map!(f, target, obsies...; kwargs...)
end

function Observables.map(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return map(f, obsies...; kwargs...)
end

function Observables.onany(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::AbstractObservable, arg9::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return onany(f, obsies...; kwargs...)
end

function Observables.map!(f, target::Observable, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::AbstractObservable, arg9::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return map!(f, target, obsies...; kwargs...)
end

function Observables.map(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::AbstractObservable, arg9::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return map(f, obsies...; kwargs...)
end

function Observables.onany(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::AbstractObservable, arg9::AbstractObservable, arg10::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return onany(f, obsies...; kwargs...)
end

function Observables.map!(f, target::Observable, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::AbstractObservable, arg9::AbstractObservable, arg10::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return map!(f, target, obsies...; kwargs...)
end

function Observables.map(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::AbstractObservable, arg9::AbstractObservable, arg10::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return map(f, obsies...; kwargs...)
end

function Observables.onany(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::AbstractObservable, arg9::AbstractObservable, arg10::AbstractObservable, arg11::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return onany(f, obsies...; kwargs...)
end

function Observables.map!(f, target::Observable, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::AbstractObservable, arg9::AbstractObservable, arg10::AbstractObservable, arg11::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return map!(f, target, obsies...; kwargs...)
end

function Observables.map(f, arg1::AbstractObservable, arg2::AbstractObservable, arg3::AbstractObservable, arg4::AbstractObservable, arg5::AbstractObservable, arg6::AbstractObservable, arg7::AbstractObservable, arg8::AbstractObservable, arg9::AbstractObservable, arg10::AbstractObservable, arg11::Computed, rest::Union{AbstractObservable, Computed}...; kwargs...)
    args = tuple(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, rest...)
    obsies = map(x -> x isa Computed ? get_observable!(x) : x, args)
    @assert all(obs -> obs isa Observable, obsies) "Failed to create Observables for all entries"
    return map(f, obsies...; kwargs...)
end

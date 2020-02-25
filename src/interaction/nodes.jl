# I don't want to use map anymore, it's so ambigious, especially to newcomers.
# TODO should this become it's own function?
function lift(
        f, o1::Observables.AbstractObservable, rest...;
        init = f(to_value(o1), to_value.(rest)...), typ = typeof(init),
        name = :node # name ignored for now
    )
    result = Observable{typ}(init)
    map!(f, result, o1, rest...)
end

# TODO remove this and play by Observables rules
function Base.push!(x::Node, value)
    @warn "`push!(x::Union{Node, Observable}, value)`` is deprecated. Use: `x[] = value` instead"
    x[] = value
end

Base.close(node::Node) = empty!(node.listeners)
function close_all_nodes(any::T) where T
    for field in fieldnames(T)
        value = getfield(any, field)
        (value isa Node) && close(value)
    end
end

function disconnect!(s::Node)
    # empty!(Observables.listeners(s))
    return
end

"""
Observables.off but without throwing an error
"""
function safe_off(o::Observables.AbstractObservable, f)
    l = listeners(o)
    for i in 1:length(l)
        if f === l[i]
            deleteat!(l, i)
            for g in Observables.removehandler_callbacks
                g(o, f)
            end
            return
        end
    end
end
"""
    map_once(closure, inputs::Node....)::Node

Like Reactive.foreach, in the sense that it will be preserved even if no reference is kept.
The difference is, that you can call map once multiple times with the same closure and it will
close the old result Node and register a new one instead.

```
function test(s1::Node)
    s3 = map_once(x-> (println("1 ", x); x), s1)
    s3 = map_once(x-> (println("2 ", x); x), s1)

end
test(Node(1), Node(2))
>

"""
function map_once(
        f, input::Node, inputrest::Node...;
        init = f(to_value.((input, inputrest...))...),
        typ = typeof(init)
    )
    for arg in (input, inputrest...)
        safe_off(arg, f)
    end
    lift(f, input, inputrest..., init = init, typ = typ)
end

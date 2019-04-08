
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
Base.push!(x::Node, value) = (x[] = value)
to_value(x::Node) = x[]
to_value(x) = x

to_node(::Type{T1}, x::Node{T2}, name = :node) where {T1, T2} = signal_convert(Node{T1}, x, name)
to_node(x::T, name = :node) where T = to_node(T, x)
to_node(::Type{T}, x, name = :node) where T = to_node(T, Node{T}(x))
to_node(x::Node) = x

signal_convert(::Type{Node{T1}}, x::Node{T1}, name = :node) where T1 = x
signal_convert(::Type{Node{T1}}, x::Node{T2}, name = :node) where {T1, T2} = lift(convert, Node(T1), x, typ = T1)
signal_convert(::Type{Node{T1}}, x::T2, name = :node) where {T1, T2} = Node{T1}(convert(T1, x))
signal_convert(t, x, name = :node) = x

node(name, node) = Node(node)
node(name, node::Node) = lift(identity, node)
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
using Observables: listeners

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

#
# call_count = Ref(1)
# io = IOBuffer()
# noyield_println(x...) = println(io, x...)
# function example1(s1)
#     # only works with closure, which will have it's unique,
#     # which stays consistent per call
#     cc = call_count[]
#     s2 = map_once(v-> noyield_println("func 1 call $cc :", v), s1)
#     push!(s1, 22)
#     # this is a unique closure, so it won't disconnect s2
#     s3 = map_once(v-> noyield_println("func 2 call $cc :", v), s1)
#     push!(s1, 33)
#     call_count[] = call_count[] + 1
#     s2, s3
# end
# s1 = Node(1)
# call_count[] = 1
# s2 = example1(s1)
# yield() # give a chance to run event loop
# println(String(take!(io)))
# func 1 call 1 :1
# func 2 call 1 :1
# func 1 call 1 :22
# func 2 call 1 :22
# func 1 call 1 :33
# func 2 call 1 :33
# s2 = example1(s1)
# func 1 call 2 :33 # first call to maponce
# func 2 call 2 :33 # first call to maponce
# func 2 call 1 :22 # first call to push!, func 2 from call 1 is still registered
# func 1 call 2 :22 # first call to push!, call 2
# func 1 call 2 :33 # second call to push!, call 1 is gone now!
# func 2 call 2 :33
#
# function no_closure(v)
#     println("func 1 ", v)
# end
# function example2(s1)
#     # println is a function which will stay the same
#     s2 = map_once(no_closure, s1)
#     push!(s1, 22)
#     # so it will globally replace any map_once(println, call, s1)
#     # (need to be those exact signals)
#     s3 = map_once(no_closure, s1)
#     push!(s1, 33)
#     s2
# end
#
# s1 = Node(1)
# s2 = example2(s1)
#
# function example3(s1, call)
#     # normal behaviour doesn't disconnect (with map instead of foreach it will disconnect )
#     # whenever gc thinks it should
#     s2 = foreach(println, call, s1)
#     push!(s1, 22)
#     s2
# end
# s1 = Node(1)
# c = Node("call 1 value: ")
# s2 = example1(c, s1)
# call 1 value: 1 # from init 1
# call 1 value: 1 # from init 2
# call 1 value: 22 # from first push
# call 1 value: 33 # from second push call 1
# call 1 value: 33 # from second push call 2
#
# s3 = example1(c, s1)
#     call 1 value: 22
#     call 1 value: 22
#     call 1 value: 22
#     call 1 value: 22
#     call 1 value: 22
#     call 1 value: 22
#
# s1 = Node(1)
# c  = Node("call 1, value ")
# s2 = example2(s1, c)
# >call 1, value 1
# >call 1, value 22
# s3 = example2(s1, 2)
# >call 2, value 22
# >call 1, value 22 # old signal still firing
# >call 2, value 22
# # same as above
# s1 = Node(1)
# c = Node("call 1, value ")
# s2 = example3(s1, c)
# s3 = example3(s1, c)
# >call 2, value 22
# >call 1, value 22 # old signal still firing
# >call 2, value 22
# get_children(c)[1] == s2
# get_children(s1)[1] == s2
# s2.parents  == (c, s1)
# c.id
# s1.id
# s2.parents[2].id
#
# s1 = Node(1)
# s2 = Node("sada")
# s1.id
# s2.id
# s3 = map(string, s1, s2)
# s3.parents == (s1, s2)

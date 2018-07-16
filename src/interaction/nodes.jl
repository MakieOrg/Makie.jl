import Reactive: set_value!

Base.getindex(x::Node) = value(x)
function Base.setindex!(x::Node{T}, value) where T
    set_value!(x, convert(T, value))
    force_update!()
    push!(x, value)
end

# I don't want to use map anymore, it's so ambigious, especially to newcomers.
# TODO should this become it's own function?
const lift = Reactive.map

to_value(x) = value(x)
to_value(x::Void) = x

to_node(::Type{T1}, x::Node{T2}, name = :node) where {T1, T2} = signal_convert(Node{T1}, x, name)
to_node(x::T, name = :node) where T = to_node(T, x)
to_node(::Type{T}, x, name = :node) where T = to_node(T, Node(T, x, name = string(name)))

signal_convert(::Type{Signal{T1}}, x::Signal{T1}, name = :node) where T1 = x
signal_convert(::Type{Signal{T1}}, x::Signal{T2}, name = :node) where {T1, T2} = map(x-> convert(T1, x), x, typ = T1, name = string(name))
signal_convert(::Type{Signal{T1}}, x::T2, name = :node) where {T1, T2} = Node(T1, convert(T1, x), name = string(name))
signal_convert(t, x, name = :node) = x

node(name, node) = Node(node, name = string(name))
node(name, node::Node) = map(identity, node, name = string(name))

function close_all_nodes(any::T) where T
    for field in fieldnames(T)
        value = getfield(any, field)
        (value isa Node) && close(value, true)
    end
end


function disconnect!(s::Node)
    unpreserve(s)#; empty!(s.actions)
    s.parents = (); close(s, false)
    return
end

function get_children(x::Signal)
    filter!(x-> x != nothing, map(x-> x.value, Reactive.nodes[Reactive.edges[x.id]]))
end
function children_with(action::AT, signal::Signal, rest::Signal...) where AT
    c = filter!(get_children(signal)) do x
        any(y-> isa(y, AT), x.actions)
    end
    isempty(c) && return false, Signal(nothing)
    node = first(c) # what if more?
    has_node = all(rest) do signal
        node in get_children(signal)
    end
    has_node, node
end

"""
    map_once(closure, inputs::Signal....)::Signal

Like Reactive.foreach, in the sense that it will be preserved even if no reference is kept.
The difference is, that you can call map once multiple times with the same closure and it will
close the old result Signal and register a new one instead.

```
function test(s1::Signal)
    s3 = map_once(x-> (println("1 ", x); x), s1)
    s3 = map_once(x-> (println("2 ", x); x), s1)

end
test(Signal(1), Signal(2))
>

"""
function map_once(
        f, input::Signal, inputsrest::Signal...;
        init = f(map(value, (input,inputsrest...))...),
        typ = typeof(init), name = Reactive.auto_name!("map", input, inputsrest...)
    )
    output = Signal(typ, init, (input, inputsrest...); name = name)
    action_func = function ()
        Reactive.set_value!(output, f(value.((input, inputsrest...))...))
    end
    # The action func should be unique regarding the types of inputs + f!
    # so we can use it to figure out if map_once was already called with this f + input types.
    # At least for closures, the name should be unique once per function body,
    # so exactly the kind of uniqueness we need!
    has, prev_output = children_with(action_func, input, inputsrest...)
    # if all input nodes have the action_func, then `node` must be the result
    # of a previous call to map_once, meaning we're about to replace this node!
    # clean up previously connected signal!
    has && disconnect!(prev_output)
    # add the action to the new output
    Reactive.add_action!(action_func, output)
    preserve(output)
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
# s1 = Signal(1)
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
# s1 = Signal(1)
# s2 = example2(s1)
#
# function example3(s1, call)
#     # normal behaviour doesn't disconnect (with map instead of foreach it will disconnect )
#     # whenever gc thinks it should
#     s2 = foreach(println, call, s1)
#     push!(s1, 22)
#     s2
# end
# s1 = Signal(1)
# c = Signal("call 1 value: ")
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
# s1 = Signal(1)
# c  = Signal("call 1, value ")
# s2 = example2(s1, c)
# >call 1, value 1
# >call 1, value 22
# s3 = example2(s1, 2)
# >call 2, value 22
# >call 1, value 22 # old signal still firing
# >call 2, value 22
# # same as above
# s1 = Signal(1)
# c = Signal("call 1, value ")
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
# s1 = Signal(1)
# s2 = Signal("sada")
# s1.id
# s2.id
# s3 = map(string, s1, s2)
# s3.parents == (s1, s2)

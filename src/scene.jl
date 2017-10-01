using Reactive, GLWindow, GeometryTypes, GLVisualize, Colors
import Base: setindex!, getindex, map, haskey

immutable Scene
    data::Dict{Symbol, Any}
end
const global_scene = Scene[]


function get_global_scene()
    if isempty(global_scene)
        Scene()
    else
        global_scene[]
    end
end


function render_loop(scene, screen, framerate = 1/60)
    while isopen(screen)
        t = time()
        GLWindow.poll_glfw() # GLFW poll
        scene[:time] = t
        if Base.n_avail(Reactive._messages) > 0
            GLWindow.reactive_run_till_now()
            GLWindow.render_frame(screen)
            GLWindow.swapbuffers(screen)
        end
        t = time() - t
        GLWindow.sleep_pessimistic(framerate - t)
    end
    destroy!(screen)
    return
end


function Scene()
    if !isempty(global_scene)
        oldscene = global_scene[]
        GLWindow.destroy!(oldscene[:screen])
        empty!(oldscene.data)
        empty!(global_scene)
    end
    w = Screen()
    GLWindow.add_complex_signals!(w)
    dict = copy(w.inputs)
    dict[:screen] = w
    push!(dict[:window_open], true)
    dict[:time] = Signal(0.0)
    scene = Scene(dict)
    push!(global_scene, scene)
    @async render_loop(scene, w)
    scene
end
to_signal(obj) = Signal(obj)
to_signal(obj::Signal) = obj

function setindex!(s::Scene, obj, key::Symbol, tail::Symbol...)
    s2 = Scene(Dict{Symbol, Any}())
    s.data[key] = s2
    s2[tail...] = obj
end
function setindex!(s::Scene, obj, key::Symbol)
    if haskey(s, key) # if in dictionary, just push a new value to the signal
        push!(s[key], obj)
    else
        s.data[key] = to_signal(obj)
    end
end

haskey(s::Scene, key::Symbol) = haskey(s.data, key)
getindex(s::Scene, key::Symbol) = s.data[key]
getindex(s::Scene, key::Symbol, tail::Symbol...) = s.data[key][tail...]


function Base.map(f, x::Signal{T}) where T <: AbstractArray
    invoke(map, (Function, Signal), x-> f(x), x)
end

function unique_predictable_name(scene, name)
    i = 1
    unique = name
    while haskey(scene, unique)
        unique = Symbol("$name$i")
        i += 1
    end
    return unique
end

function extract_fields(expr, fields = [])
    if expr.head == :(.)
        push!(fields, expr.args[1])
        extract_fields(expr.args[2], fields)
    elseif isa(expr, Symbol)
        push!(fields, QuoteNode(expr))
    elseif isa(expr, Expr) && expr.head == :quote && length(expr.args) == 1 && isa(expr.args[1], Symbol)
        push!(fields, expr)
    else
        error("Not a getfield expr: $expr, $(typeof(expr)) $(expr.head)")
    end
    fields
end


macro ref(arg)
    fields = extract_fields(arg)
    println(fields)
    expr = :(getindex($(fields...)))
    println(expr)
    expr
end

struct Hehe
    test::String
end

Lol = Hehe("haha")

@ref Lol.test


macro ref(arg, args...)
    args = (arg, args...)
    result = Expr(:tuple)
    for elem in args


end

# s = Scene()
# viz = scatter(
#     map((mpos, t)-> [Point2f0((sin(x + t), cos(x + t)) .* 50f0) .+ Point2f0(mpos) for x in linspace(0, 2pi, 30)], s[:mouseposition], s[:time]),
#     scale = Vec2f0(5)
# )

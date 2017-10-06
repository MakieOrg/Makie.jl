using Reactive, GLWindow, GeometryTypes, GLVisualize, Colors, ColorBrewer
import Base: setindex!, getindex, map, haskey

include("colors.jl")
include("defaults.jl")
immutable Scene
    data::Dict{Symbol, Any}
end

include("signals.jl")

const global_scene = Scene[]


function (::Type{Scene})(pair1::Pair, tail::Pair...)
    args = (pair1, tail...)
    Scene(Dict(map(x-> x[1] => to_signal(x[2]), args)))
end


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


include("themes.jl")

function Scene(; theme = default_theme)
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
    dict[:theme] = theme
    scene = Scene(dict)
    push!(global_scene, scene)
    @async render_loop(scene, w)
    scene
end

function insert_scene!(scene, name, viz, attributes)
    name = unique_predictable_name(scene, :scatter)
    scene.data[name] = attributes
    _view(viz, scene[:screen], camera = :orthographic_pixel)
end

# function setindex!(s::Scene, obj, key::Symbol, tail::Symbol...)
#     s2 = get(s, key) do
#         s2 = Scene(Dict{Symbol, Any}())
#         s.data[key] = s2
#         s2
#     end
#     s2[tail...] = obj
# end

function setindex!(s::Scene, obj, key::Symbol)
    if haskey(s, key) # if in dictionary, just push a new value to the signal
        push!(s[key], obj)
    else
        s.data[key] = to_signal(obj)
    end
end

haskey(s::Scene, key::Symbol) = haskey(s.data, key)
function haskey(s::Scene, key::Symbol, tail::Symbol...)
    res = haskey(s, key)
    res || return false
    haskey(s[key], tail...)
end
getindex(s::Scene, key::Symbol) = s.data[key]
getindex(s::Scene, key::Symbol, tail::Symbol...) = s.data[key][tail...]

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
    if isa(expr, Symbol)
        push!(fields, QuoteNode(expr))
    elseif isa(expr, QuoteNode)
        push!(fields, expr)
    elseif isa(expr, Expr)
        if expr.head == :(.)
            push!(fields, expr.args[1])
            return extract_fields(expr.args[2], fields)
        elseif expr.head == :quote && length(expr.args) == 1 && isa(expr.args[1], Symbol)
            push!(fields, expr)
        end
    else
        error("Not a getfield expr: $expr, $(typeof(expr)) $(expr.head)")
    end
    return :(getindex($(fields...)))
end
extract_fields(:(a.b))


"""
    @ref(arg)

    ```julia
        @ref Variable = Value # Inserts Value under name Variable into Scene

        @ref Scene.Name1.Name2 # Syntactic sugar for `Scene[:Name1, :Name2]`
        @ref Expr1, Expr1 # Syntactic sugar for `(@ref Expr1, @ref Expr2)`
    ```
"""
macro ref(arg)
    extract_fields(arg)
end

macro ref(args...)
elseif expr.head == :tuple
    tup = Expr(:tuple)
    tup.args = extract_fields.(expr.args)
    return tup
    #:($(extract_fields.(args)...))
end

"""
Extract a default for `func` + `attribute`.
If the attribute is in kw_args that will be selected.]
Else will search in scene.theme.func for `attribute` and if not found there it will
search one level higher (scene.theme).
"""
function find_default(scene, kw_args, func, attribute)
    if haskey(kw_args, attribute)
        return kw_args[attribute]
    end
    if haskey(scene, :theme)
        theme = scene[:theme]
        if haskey(theme, Symbol(func), attribute)
            return theme[Symbol(func), attribute]
        elseif haskey(theme, attribute)
            return theme[attribute]
        else
            error("theme doesn't contain a default for $attribute. Please provide $attribute for $func")
        end
    else
        error("Scene doesn't contain a theme and therefore doesn't provide any defaults.
            Please provide attribute $attribute for $func")
    end
end

using Reactive, GLWindow, GeometryTypes, GLVisualize, Colors, ColorBrewer, GLFW
import Base: setindex!, getindex, map, haskey

include("colors.jl")
include("defaults.jl")

"""
A Makie flavored Signal that can be used to link attributes
"""
struct Node{T, F}
    signal::Signal{T}
    # Conversion function for push! This is a bit a hack around the fact that you can't do things like
    # signal = map(conversion_func, Signal(RGB(0, 0, 0))); push!(signal, :red)
    # since the signal won't have the correct type. so we give the chance to pass a conversion function
    # at creation which will be called in push!
    convert::F
end

"""
A scene is a holder of attributes which are all of the type Node.
A scene can contain attributes, which are themselves scenes.
Nodes can be connected, since they're signals under the hood, which can be created from other nodes.
"""
immutable Scene{Backend}
    name::Symbol
    parent::Nullable{Scene}
    data::Dict{Symbol, Any}
    visual
end

attributes(scene::Scene) = copy(scene.data)

const current_backend = Ref(:makie)

function Scene(args...)
    Scene{current_backend[]}(args...)
end

"""
Creates a child scene containing a new window!
"""
function Scene(parent::Scene{Backend}, area, name = :scene, data = Dict{Symbol, Any}(); screen_kw_args...) where Backend
    screen = getscreen(parent)
    newscreen = Screen(screen; area = to_signal(area), screen_kw_args...)
    data[:screen] = newscreen
    Scene{Backend}(name, parent, data, nothing)
end


function (::Type{Scene{Backend}})(data::Dict, name = :scene) where Backend
    Scene{Backend}(name, Nullable{Scene{Backend}}(), data, nothing)
end

function (::Type{Scene{Backend}})(pair1::Pair, tail::Pair...) where Backend
    args = [pair1, tail...]
    Scene(Dict(map(x-> x[1] => to_node(x[2]), args)))
end


"""
Inserts `childscene` into the scene graph of `scene`. This will display the
`childscene` in `scene`, when it is visible.
`show!` will get called by default for any plotting command, and can be disabled
and manually added via `show` by doing e.g.
    ```
    scene = Scene()
    scatplot = scatter(rand(10), rand(10), show = false)
    view!(scene, scatplot)
    ```
"""
function show!(scene::Scene{Backend}, childscene::Scene{Backend}) where Backend
    camera = to_value(childscene, :camera) # should always be available!
    screen = scene[:screen]
    cams = collect(keys(screen.cameras))
    viz = native_visual(childscene)
    viz == nothing && error("`childscene` does not contain any visual, so can't be added to `scene` with `show!`!")
    cam = if camera == :auto
        if isempty(cams)
            bb = value(GLAbstraction.boundingbox(viz))
            # infer if it's 3D
            widths(bb)[3] ≈ 0 ? :orthographic_pixel : :perspective
        else
            # use the already present cam
            first(cams)
        end
    elseif camera == :pixel
        :fixed_pixel
    elseif camera == :orthographic
        :orthographic_pixel
    else
        :perspective
    end
    _view(viz, screen, camera = cam)
    if isempty(cams)
        scene[:camera] = first(screen.cameras)[2] # The camera just got created by _view
    end
    childscene
end

function insert_scene!(scene::Scene{Backend}, name, viz, attributes) where Backend
    uname = unique_predictable_name(scene, name)
    childscene = Scene{Backend}(name, scene, attributes, viz)
    scene.data[uname] = childscene

    to_value(childscene, :show) && show!(scene, childscene)

    childscene
end

"""
Get's the backend native visual belonging to a scene. If
it isn't a visual, it will return nothing!
"""
native_visual(scene::Scene) = scene.visual

function Base.delete!(scene::Scene, name::Symbol)
    if haskey(scene, name)
        obj = scene[name]
        delete!(scene.data, name)
        visual = native_visual(obj)
        if visual != nothing
            # Also delete the visual from renderlist
            delete!(rootscreen(scene), visual)
        end
    end
end

parent(scene::Scene) = get(scene.parent)

function rootscene(scene::Scene)
    while !isnull(scene.parent)
        scene = parent(scene)
    end
    scene
end
function rootscreen(scene::Scene)
    getscreen(rootscene(scene))
end
function getscreen(scene::Scene)
    while !isnull(scene.parent) && !haskey(scene, :screen)
        scene = parent(scene)
    end
    get(scene, :screen, nothing)
end

include("signals.jl")

function Base.show(io::IO, mime::MIME"text/plain", scene::Scene)
    println(io, "Scene $(scene.name):")
    show(io, mime, scene.data)
end

function Base.show(io::IO, scene::Scene)
    print(io, "Scene: $(scene.name)")
end



const global_scene = Scene[]

function GLAbstraction.center!(scene::Scene, border = 0.1)
    screen = scene[:screen]
    camsym = first(keys(screen.cameras))
    center!(screen, camsym, border = border)
    scene
end

export center!

function get_global_scene()
    if isempty(global_scene)
        Scene()
    else
        global_scene[]
    end
end

render_frame(scene::Scene) = render_frame(rootscreen(scene))
function render_frame(screen::GLWindow.Screen)
    GLWindow.reactive_run_till_now()
    GLWindow.render_frame(screen)
    GLWindow.swapbuffers(screen)
end

function render_loop(tsig, screen, framerate = 1/60)
    while isopen(screen)
        t = time()
        GLWindow.poll_glfw() # GLFW poll
        push!(tsig, t)
        if Base.n_avail(Reactive._messages) > 0
            render_frame(screen)
        end
        t = time() - t
        GLWindow.sleep_pessimistic(framerate - t)
    end
    GLWindow.destroy!(screen)
    return
end


include("themes.jl")

close_all_nodes(x::AbstractNode) = closenode!(x)
close_all_nodes(x) = x

function close_all_nodes(x::Scene)
    for (k, v) in x.data
        close_all_nodes(v)
    end
end

function Base.empty!(scene::Scene)
    close_all_nodes(scene)
    empty!(scene.data)
end

const render_task = RefValue{Task}()

function block(scene::Scene)
    wait(render_task[])
end

function Scene(;
        theme = default_theme,
        resolution = nothing,
        position = nothing,
        color = :white,
        monitor = nothing
    )

    tsig = to_node(0.0)
    w = nothing
    if !isempty(global_scene)
        oldscene = global_scene[]
        oldscreen = oldscene[:screen]
        nw = GLWindow.nativewindow(oldscreen)
        if position == nothing && isopen(nw)
            position = GLFW.GetWindowPos(nw)
        end
        if resolution == nothing && isopen(nw)
            resolution = GLFW.GetWindowSize(nw)
        end
        # GLWindow.destroy!(oldscene[:screen])
        empty!(oldscreen)
        empty!(oldscreen.cameras)
        GLVisualize.empty_screens!()
        empty!(oldscene)
        empty!(global_scene)
        oldscreen.color = to_color(nothing, color)
        w = oldscreen
    end
    if w == nothing || !isopen(w)
        if resolution == nothing
            resolution = GLWindow.standard_screen_resolution()
        end
        w = Screen("Makie", resolution = resolution, color = to_color(nothing, color))
        GLWindow.add_complex_signals!(w)
        render_task[] = @async render_loop(tsig, w)
    end

    nw = GLWindow.nativewindow(w)
    if resolution == nothing
        resolution = GLWindow.standard_screen_resolution()
    end
    if position == nothing
        position = GLFW.GetWindowPos(nw)
    end
    GLFW.SetWindowPos(nw, position...)
    resize!(w, Int.(resolution)...)

    GLVisualize.add_screen(w)

    dict = map(w.inputs) do k_v
        k_v[1] => to_node(k_v[2])
    end
    dict[:screen] = w
    push!(dict[:window_open], true)
    dict[:time] = tsig
    scene = Scene(dict)
    theme(scene) # apply theme
    push!(global_scene, scene)
    scene
end



Base.get(f, x::Scene, key::Symbol) = haskey(x, key) ? x[key] : f()
Base.get(x::Scene, key::Symbol, default) = haskey(x, key) ? x[key] : default

function setindex!(s::Scene, obj, key::Symbol, tail::Symbol...)
    s2 = get(s.data, key) do
        s2 = Scene(Dict{Symbol, Any}())
        s.data[key] = s2
        s2
    end
    s2[tail...] = obj
end


function Base.push!(s::Scene, obj::Scene)
    for (k, v) in obj.data
        s[k] = v
    end
end
function setindex!(s::Scene, obj, key::Symbol)
    if haskey(s, key) # if in dictionary, just push a new value to the signal
        push!(s[key], obj)
    else
        s.data[key] = to_node(obj)
    end
end

haskey(s::Scene, key::Symbol) = haskey(s.data, key)
function haskey(s::Scene, key::Symbol, tail::Symbol...)
    res = haskey(s, key)
    res || return false
    haskey(s[key], tail...)
end
getindex(s::Scene, key::NTuple{N, Symbol}) where N = getindex(s, key...)
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

to_value(scene::Scene, s1::Symbol, srest::Symbol...) = to_value(scene[s1, srest...])

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
    Expr(:tuple, extract_fields.(args)...)
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
    root = rootscene(scene) # theme is in root!
    if haskey(root, :theme)
        theme = root[:theme]
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

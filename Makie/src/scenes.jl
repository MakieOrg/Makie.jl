struct SSAO
    """
    sets the range of SSAO. You may want to scale this up or
    down depending on the limits of your coordinate system
    """
    radius::Observable{Float32}

    """
    sets the minimum difference in depth required for a pixel to
    be occluded. Increasing this will typically make the occlusion
    effect stronger.
    """
    bias::Observable{Float32}

    """
    sets the (pixel) range of the blur applied to the occlusion texture.
    The texture contains a (random) pattern, which is washed out by
    blurring. Small `blur` will be faster, sharper and more patterned.
    Large `blur` will be slower and smoother. Typically `blur = 2` is
    a good compromise.
    """
    blur::Observable{Int32}
end

function Base.show(io::IO, ssao::SSAO)
    println(io, "SSAO:")
    println(io, "    radius: ", ssao.radius[])
    println(io, "    bias:   ", ssao.bias[])
    return println(io, "    blur:   ", ssao.blur[])
end

function SSAO(; radius = nothing, bias = nothing, blur = nothing)
    defaults = theme(nothing, :SSAO)
    _radius = isnothing(radius) ? defaults.radius[] : radius
    _bias = isnothing(bias) ? defaults.bias[] : bias
    _blur = isnothing(blur) ? defaults.blur[] : blur
    return SSAO(_radius, _bias, _blur)
end

"""
    Scene TODO document this

## Constructors
$(SIGNATURES)

## Fields
$(FIELDS)
"""
mutable struct Scene <: AbstractScene
    "The parent of the Scene; if it is a top-level Scene, `parent == nothing`."
    parent::Union{Nothing, Scene}

    "[`Events`](@ref) associated with the Scene."
    events::Events

    "The current pixel area of the Scene."
    viewport::Observable{Rect2i}

    "Whether the scene should be cleared."
    clear::Observable{Bool}

    "The `Camera` associated with the Scene."
    camera::Camera

    "The controls for the camera of the Scene."
    camera_controls::AbstractCamera

    "The [`Transformation`](@ref) of the Scene."
    transformation::Transformation

    "A transformation rescaling data to a Float32-save range."
    float32convert::Union{Nothing, Float32Convert}

    "The plots contained in the Scene."
    plots::Vector{Plot}

    theme::Attributes

    "Children of the Scene inherit its transformation."
    children::Vector{Scene}

    """
    The Screens which the Scene is displayed to.
    """
    current_screens::Vector{MakieScreen}

    # Attributes
    backgroundcolor::Observable{RGBAf}
    visible::Observable{Bool}
    ssao::SSAO
    deregister_callbacks::Vector{Observables.ObserverFunction}
    compute::ComputeGraph

    conversions::DimConversions
    isclosed::Bool
    # Cant type this, dont have the type yet
    data_inspector::Any

    function Scene(
            parent::Union{Nothing, Scene},
            events::Events,
            viewport::Observable{Rect2i},
            clear::Observable{Bool},
            camera::Camera,
            camera_controls::AbstractCamera,
            transformation::Transformation,
            plots::Vector{AbstractPlot},
            theme::Attributes,
            children::Vector{Scene},
            current_screens::Vector{MakieScreen},
            backgroundcolor::Observable{RGBAf},
            visible::Observable{Bool},
            ssao::SSAO,
            lights::Vector;
            deregister_callbacks = Observables.ObserverFunction[]
        )
        scene = new(
            parent,
            events,
            viewport,
            clear,
            camera,
            camera_controls,
            transformation,
            nothing,
            plots,
            theme,
            children,
            current_screens,
            backgroundcolor,
            visible,
            ssao,
            deregister_callbacks,
            ComputeGraph(),
            DimConversions(),
            false,
            nothing
        )
        add_camera_computation!(scene.compute, scene)
        add_light_computation!(scene.compute, scene, lights)
        add_input!((k, v) -> Ref{Any}(v), scene.compute, :transform_func, transformation.transform_func)
        on(scene, events.window_open) do open
            if !open
                scene.isclosed = true
            end
        end
        # Only finalize the root scene!
        # Children can not go out of scope without their parent being finalized
        if isnothing(parent)
            finalizer(scene) do s
                @async try
                    free(s)
                catch e
                    @error "Error while freeing scene" exception = (e, catch_backtrace())
                end
            end
        end
        return scene
    end
end

isclosed(scene::Scene) = scene.isclosed

# on & map versions that deregister when scene closes!
function Observables.on(
        @nospecialize(f), @nospecialize(scene::Union{Plot, Scene}),
        @nospecialize(observable::Union{Observable, Computed});
        update = false, priority = 0
    )
    to_deregister = on(f, observable; update = update, priority = priority)::Observables.ObserverFunction
    push!(scene.deregister_callbacks::Vector{Observables.ObserverFunction}, to_deregister)
    return to_deregister
end

function Observables.onany(@nospecialize(f), @nospecialize(scene::Union{Plot, Scene}), @nospecialize(observables...); update = false, priority = 0)
    to_deregister = onany(f, observables...; priority = priority, update = update)
    append!(scene.deregister_callbacks::Vector{Observables.ObserverFunction}, to_deregister)
    return to_deregister
end

@inline function Base.map!(
        f, @nospecialize(scene::Union{Plot, Scene}), result::AbstractObservable, os...;
        update::Bool = true, priority = 0
    )
    # note: the @inline prevents de-specialization due to the splatting
    observables = map(x -> x isa Computed ? ComputePipeline.get_observable!(x) : x, os)
    callback = Observables.MapCallback(f, result, observables)
    for o in observables
        o isa AbstractObservable && on(callback, scene, o, priority = priority)
    end
    update && callback(nothing)
    return result
end

@inline function Base.map(
        f::F, @nospecialize(scene::Union{Plot, Scene}), arg1::Union{Computed, AbstractObservable}, args...;
        ignore_equal_values = false, priority = 0
    ) where {F}
    # note: the @inline prevents de-specialization due to the splatting
    obs = Observable(f(arg1[], map(Observables.to_value, args)...); ignore_equal_values = ignore_equal_values)
    map!(f, scene, obs, arg1, args...; update = false, priority = priority)
    return obs
end

get_scene(scene::Scene) = scene
get_scene(plot::AbstractPlot) = parent_scene(plot)

_plural_s(x) = length(x) != 1 ? "s" : ""

function Base.show(io::IO, scene::Scene)
    return print(io, "Scene(", length(scene.children), " children, ", length(scene.plots), " plots)")
end
function Base.show(io::IO, ::MIME"text/plain", scene::Scene)
    println(io, "Scene ($(size(scene, 1))px, $(size(scene, 2))px):")
    print(io, "  $(length(scene.plots)) Plot$(_plural_s(scene.plots))")

    if length(scene.plots) > 0
        print(io, ":")
        for (i, plot) in enumerate(scene.plots)
            print(io, "\n")
            print(io, "    $(i == length(scene.plots) ? '└' : '├') ", plot)
        end
    end

    print(io, "\n  $(length(scene.children)) Child Scene$(_plural_s(scene.children))")

    return if length(scene.children) > 0
        print(io, ":")
        for (i, subscene) in enumerate(scene.children)
            print(io, "\n")
            print(io, "    $(i == length(scene.children) ? '└' : '├') Scene ($(size(subscene, 1))px, $(size(subscene, 2))px)")
        end
    end
end

function Scene(;
        viewport::Union{Observable{Rect2i}, Nothing} = nothing,
        events::Events = Events(),
        clear::Union{Automatic, Observable{Bool}, Bool} = automatic,
        transform_func = identity,
        camera::Union{Function, Camera, Nothing} = nothing,
        camera_controls::AbstractCamera = EmptyCamera(),
        transformation::Transformation = Transformation(transform_func),
        plots::Vector{AbstractPlot} = AbstractPlot[],
        children::Vector{Scene} = Scene[],
        current_screens::Vector{MakieScreen} = MakieScreen[],
        parent = nothing,
        visible = Observable(true),
        ssao = SSAO(),
        lights = automatic,
        theme = Attributes(),
        deregister_callbacks = Observables.ObserverFunction[],
        theme_kw...
    )

    global_theme = merge_without_obs!(copy(theme), current_default_theme())
    m_theme = merge_without_obs!(Attributes(theme_kw), global_theme)

    bg = Observable{RGBAf}(to_color(m_theme.backgroundcolor[]); ignore_equal_values = true)

    wasnothing = isnothing(viewport)
    if wasnothing
        sz = if haskey(m_theme, :resolution)
            @warn "Found `resolution` in the theme when creating a `Scene`. The `resolution` keyword for `Scene`s and `Figure`s has been deprecated. Use `Figure(; size = ...` or `Scene(; size = ...)` instead, which better reflects that this is a unitless size and not a pixel resolution. The key could also come from `set_theme!` calls or related theming functions."
            m_theme.resolution[]
        else
            m_theme.size[]
        end
        viewport = Observable(Recti(0, 0, sz); ignore_equal_values = true)
    end

    cam = camera isa Camera ? camera : Camera(viewport)
    _lights = lights isa Automatic ? AbstractLight[] : lights

    if lights isa Automatic
        haskey(m_theme, :lightposition) && @warn("`lightposition` is deprecated. Set `light_direction` instead.")

        if haskey(m_theme, :lights)
            copyto!(_lights, m_theme.lights[])
        else
            haskey(m_theme, :light_direction) || error("Theme must contain `light_direction::Vec3f` or an explicit `lights::Vector`!")
            haskey(m_theme, :light_color) || error("Theme must contain `light_color::RGBf` or an explicit `lights::Vector`!")
            haskey(m_theme, :camera_relative_light) || @warn("Theme should contain `camera_relative_light::Bool`.")

            if haskey(m_theme, :ambient)
                push!(_lights, AmbientLight(m_theme[:ambient][]))
            end

            push!(
                _lights, DirectionalLight(
                    m_theme[:light_color][], m_theme[:light_direction][],
                    to_value(get(m_theme, :camera_relative_light, false))
                )
            )
        end
    end


    # if we have an opaque background, automatically set clear to true!
    if clear isa Automatic
        clear = Observable(alpha(bg[]) == 1 ? true : false)
    else
        clear = convert(Observable{Bool}, clear)
    end
    scene = Scene(
        parent, events, viewport, clear, cam, camera_controls,
        transformation, plots, m_theme,
        children, current_screens, bg, visible, ssao, _lights;
        deregister_callbacks = deregister_callbacks
    )
    camera isa Function && camera(scene)

    if wasnothing
        on(events.window_area, priority = typemax(Int)) do w_area
            if !any(x -> x ≈ 0.0, widths(w_area)) && viewport[] != w_area
                viewport[] = w_area
            end
            return Consume(false)
        end
    end

    return scene
end

function Scene(
        parent::Scene;
        events = parent.events,
        viewport = nothing,
        clear = false,
        camera = nothing,
        visible = parent.visible,
        camera_controls = parent.camera_controls,
        transformation = Transformation(parent),
        kw...
    )

    if camera !== parent.camera
        camera_controls = EmptyCamera()
    end
    child_px_area = viewport isa Observable ? viewport : Observable(Rect2i(0, 0, 0, 0); ignore_equal_values = true)
    deregister_callbacks = Observables.ObserverFunction[]
    _visible = Observable(true)
    if visible isa Observable
        listener = on(visible; update = true) do v
            _visible[] = v
        end
        push!(deregister_callbacks, listener)
    elseif visible isa Bool
        _visible[] = visible
    else
        error("Unsupported typer visible: $(typeof(visible))")
    end
    child = Scene(;
        events = events,
        viewport = child_px_area,
        clear = convert(Observable{Bool}, clear),
        camera = camera,
        visible = _visible,
        camera_controls = camera_controls,
        parent = parent,
        transformation = transformation,
        current_screens = copy(parent.current_screens),
        theme = theme(parent),
        deregister_callbacks = deregister_callbacks,
        kw...
    )
    # if !isnothing(listener)
    #     push!(child.deregister_callbacks, listener)
    # end
    if isnothing(viewport)
        map!(identity, child, child_px_area, parent.viewport)
    elseif viewport isa Rect2
        child_px_area[] = Rect2i(viewport)
    else
        if !(viewport isa Observable)
            error("viewport must be an Observable{Rect2} or a Rect2")
        end
    end
    push!(parent.children, child)
    child.parent = parent
    return child
end

# legacy constructor
function Scene(parent::Scene, area; kw...)
    return Scene(parent; viewport = area, kw...)
end

# Base overloads for Scene
Base.parent(scene::Scene) = scene.parent
isroot(scene::Scene) = parent(scene) === nothing
rootparent(x) = rootparent(parent(x))
rootparent(x::Scene) = x

function root(scene::Scene)
    while !isroot(scene)
        scene = parent(scene)
    end
    return scene
end
parent_or_self(scene::Scene) = isroot(scene) ? scene : parent(scene)

GeometryBasics.widths(scene::Scene) = widths(to_value(viewport(scene)))

Base.size(scene::Scene) = Tuple(widths(scene))
Base.size(x::Scene, i) = size(x)[i]

function Base.resize!(scene::Scene, xy::Tuple{Number, Number})
    return resize!(scene, Recti(0, 0, xy))
end
Base.resize!(scene::Scene, x::Number, y::Number) = resize!(scene, (x, y))
function Base.resize!(scene::Scene, rect::Rect2)
    viewport(scene)[] = rect
    return if isroot(scene)
        for screen in scene.current_screens
            resize!(screen, widths(rect)...)
        end
    end
end

# Just indexing into a scene gets you plot 1, plot 2 etc
Base.iterate(scene::Scene, idx = 1) = idx <= length(scene) ? (scene[idx], idx + 1) : nothing
Base.length(scene::Scene) = length(scene.plots)
Base.lastindex(scene::Scene) = length(scene.plots)
getindex(scene::Scene, idx::Integer) = scene.plots[idx]
struct OldAxis end

zero_origin(area) = Recti(0, 0, widths(area))

function child(scene::Scene; camera, attributes...)
    return Scene(scene; camera = camera, attributes...)
end

"""
Creates a subscene with a pixel camera
"""
function cam2d(scene::Scene)
    return child(scene, clear = false, camera = cam2d!)
end

function campixel(scene::Scene)
    return child(scene, clear = false, camera = campixel!)
end

function camrelative(scene::Scene)
    return child(scene, clear = false, camera = cam_relative!)
end

function getindex(scene::Scene, ::Type{OldAxis})
    for plot in scene
        isaxis(plot) && return plot
    end
    return nothing
end

function free(scene::Scene)
    # Errors should be handled at a lower level because otherwise
    # some of the cleanup will be incomplete.
    empty!(scene; reset_theme = false)
    for field in [:backgroundcolor, :viewport, :visible]
        Observables.clear(getfield(scene, field))
    end
    for screen in copy(scene.current_screens)
        delete!(screen, scene)
    end
    empty!(scene.current_screens)
    scene.parent = nothing
    return
end

function Base.empty!(scene::Scene; reset_theme = true)
    foreach(empty!, copy(scene.children))
    # clear plots of this scene
    for plot in copy(scene.plots)
        delete!(scene, plot)
    end

    # clear all child scenes
    if !isnothing(scene.parent)
        filter!(x -> x !== scene, scene.parent.children)
    end

    empty!(scene.children)
    empty!(scene.plots)
    empty!(scene.theme)

    # conditional, since in free we dont want this!
    if reset_theme
        merge_without_obs!(scene.theme, CURRENT_DEFAULT_THEME)
    end

    disconnect!(scene.camera)
    scene.camera_controls = EmptyCamera()

    for fieldname in (:rotation, :translation, :scale, :transform_func, :model)
        Observables.clear(getfield(scene.transformation, fieldname))
    end
    for obsfunc in scene.deregister_callbacks
        Observables.off(obsfunc)
    end
    empty!(scene.deregister_callbacks)
    return nothing
end

function Base.push!(plot::Plot, subplot)
    validate_attribute_keys(subplot)
    subplot.parent = plot
    return push!(plot.plots, subplot)
end

function Base.push!(scene::Scene, @nospecialize(plot::Plot))
    validate_attribute_keys(plot)
    push!(scene.plots, plot)
    for screen in scene.current_screens
        Base.invokelatest(insert!, screen, scene, plot)
    end
    return
end

# Note: can be called from scene finalizer - @debug may cause segfaults when active
function Base.delete!(screen::MakieScreen, ::Scene, ::AbstractPlot)
    return @debug "Deleting plots not implemented for backend: $(typeof(screen))"
end

# Note: can be called from scene finalizer - @debug may cause segfaults when active
function Base.delete!(screen::MakieScreen, ::Scene)
    # This may not be necessary for every backed
    return @debug "Deleting scenes not implemented for backend: $(typeof(screen))"
end

# Note: can be called from scene finalizer
function free(plot::AbstractPlot)
    for f in plot.deregister_callbacks
        Observables.off(f)
    end
    foreach(free, plot.plots)
    empty!(plot.attributes)
    # empty!(plot.plots)
    empty!(plot.deregister_callbacks)
    free(plot.transformation)
    return
end

# Note: can be called from scene finalizer
function Base.delete!(scene::Scene, plot::AbstractPlot)
    filter!(x -> x !== plot, scene.plots)

    # Remove references to the plot compute graph from any parent compute graph.
    # (E.g. the scene compute graph)
    # This is meant to make the plot graph GC-able.
    ComputePipeline.unsafe_disconnect_from_parents!(plot.attributes)

    # TODO, if we want to delete a subplot of a plot,
    # It won't be in scene.plots directly, but will still be deleted
    # by delete!(screen, scene, plot)
    # Should we check here if the plot is in the scene as a subplot?
    # on the other hand, delete!(Dict(:a=>1), :b) also doesn't error...

    # if length(scene.plots) == len
    #     error("$(typeof(plot)) not in scene!")
    # end
    for screen in scene.current_screens
        delete!(screen, scene, plot)
    end
    return free(plot)
end

#=
supports_move_to(::MakieScreen) = false

function supports_move_to(plot::Plot)
    scene = get_scene(plot)
    return all(scene.current_screens) do screen
        return supports_move_to(screen)
    end
end

function move_to!(screen::MakieScreen, plot::Plot, scene::Scene)
    # TODO, move without deleting!
    # Will be easier with Observable refactor
    delete!(screen, scene, plot)
    insert!(screen, scene, plot)
    return
end

function move_to!(plot::Plot, scene::Scene)
    if plot.parent === scene
        return
    end

    # TODO: This requires surgery, disconnecting the plot from the old scene
    # compute graph and connecting it to the new scene compute graph.
    # unsafe_disconnect_from_parents!() + register_computation!() is not enough

    if is_space_compatible(plot, scene)
        obsfunc = connect!(transformation(scene), transformation(plot))
        append!(plot.deregister_callbacks, obsfunc)
    end
    for screen in root(scene).current_screens
        if supports_move_to(screen)
            move_to!(screen, plot, scene)
        end
    end
    current_parent = parent_scene(plot)
    filter!(x -> x !== plot, current_parent.plots)
    push!(scene.plots, plot)
    plot.parent = scene
    return
end
=#

events(x) = events(get_scene(x))
events(scene::Scene) = scene.events
events(scene::SceneLike) = events(scene.parent)

camera(x) = camera(get_scene(x))
camera(scene::Scene) = scene.camera
camera(scene::SceneLike) = camera(scene.parent)

cameracontrols(x) = cameracontrols(get_scene(x))
cameracontrols(scene::Scene) = scene.camera_controls
cameracontrols(scene::SceneLike) = cameracontrols(scene.parent)

function cameracontrols!(scene::Scene, cam)
    scene.camera_controls = cam
    return cam
end
cameracontrols!(scene::SceneLike, cam) = cameracontrols!(parent(scene), cam)
cameracontrols!(x, cam) = cameracontrols!(get_scene(x), cam)

viewport(x) = viewport(get_scene(x))
"""
    viewport(scene::Scene)

Gets the viewport of the scene in device independent units as an `Observable{Rect2{Int}}`.
"""
viewport(scene::Scene) = scene.viewport
viewport(scene::SceneLike) = viewport(scene.parent)

plots(x) = plots(get_scene(x))
plots(scene::SceneLike) = scene.plots

"""
Fetches all plots sharing the same camera
"""
plots_from_camera(scene::Scene) = plots_from_camera(scene, scene.camera)
function plots_from_camera(scene::Scene, camera::Camera, list = AbstractPlot[])
    append!(list, scene.plots)
    for child in scene.children
        child.camera == camera && plots_from_camera(child, camera, list)
    end
    return list
end


function insertplots!(@nospecialize(screen::AbstractDisplay), scene::Scene)
    for elem in scene.plots
        insert!(screen, scene, elem)
    end
    return foreach(child -> insertplots!(screen, child), scene.children)
end

update_cam!(x, bb::AbstractCamera, rect) = update_cam!(get_scene(x), bb, rect)
update_cam!(scene::Scene, bb::AbstractCamera, rect) = nothing

not_in_data_space(p) = !is_data_space(p)

function center!(scene::Scene, padding = 0.01, exclude = not_in_data_space)
    bb = boundingbox(scene, exclude)
    w = widths(bb)
    pad = w .* padding
    bb = Rect3d(minimum(bb) .- pad, w .+ 2pad)
    update_cam!(scene, bb)
    return scene
end

parent_scene(x) = parent_scene(get_scene(x))
parent_scene(x::Plot) = parent_scene(parent(x))::Scene
parent_scene(x::Scene) = x
parent_scene(::Nothing) = nothing

Base.isopen(x::SceneLike) = events(x).window_open[]

function is2d(scene::SceneLike)
    lims = boundingbox(scene)
    lims === nothing && return nothing
    return is2d(lims)
end
is2d(lims::Rect2) = true
is2d(lims::Rect3) = widths(lims)[3] == 0.0

#####
##### Figure type
#####

struct Figure
    scene::Scene
    layout::GridLayoutBase.GridLayout
    content::Vector
    attributes::Attributes
    current_axis::Ref{Any}

    function Figure(args...)
        f = new(args...)
        current_figure!(f)
        return f
    end
end

struct FigureAxisPlot
    figure::Figure
    axis
    plot::AbstractPlot
end

const FigureLike = Union{Scene, Figure, FigureAxisPlot}

"""
    is_atomic_plot(plot::Plot)

Defines what Makie considers an atomic plot, used in `collect_atomic_plots`.
Backends may have a different definition of what is considered an atomic plot,
but instead of overloading this function, they should create their own definition and pass it to `collect_atomic_plots`
"""
is_atomic_plot(plot::Plot) = isempty(plot.plots)
# Text is special, since it contains lines for latexstrings, but is still atomic itself
is_atomic_plot(plot::Text) = true

"""
    collect_atomic_plots(scene::Scene, plots = AbstractPlot[]; is_atomic_plot = is_atomic_plot)
    collect_atomic_plots(x::Plot, plots = AbstractPlot[]; is_atomic_plot = is_atomic_plot)

Collects all plots in the provided `<: ScenePlot` and returns a vector of all plots
which satisfy `is_atomic_plot`, which defaults to Makie's definition of `Makie.is_atomic_plot`.
"""
function collect_atomic_plots(xplot::Plot, plots = AbstractPlot[]; is_atomic_plot = is_atomic_plot)
    if is_atomic_plot(xplot)
        # Atomic plot!
        push!(plots, xplot)
    else
        for elem in xplot.plots
            collect_atomic_plots(elem, plots; is_atomic_plot = is_atomic_plot)
        end
    end
    return plots
end

# Text is atomic but contains another atomic (lines for latexstrings)
function collect_atomic_plots(xplot::Text, plots = AbstractPlot[]; is_atomic_plot = is_atomic_plot)
    push!(plots, xplot)
    for elem in xplot.plots
        collect_atomic_plots(elem, plots; is_atomic_plot = is_atomic_plot)
    end
    return plots
end

function collect_atomic_plots(array, plots = AbstractPlot[]; is_atomic_plot = is_atomic_plot)
    for elem in array
        collect_atomic_plots(elem, plots; is_atomic_plot = is_atomic_plot)
    end
    return plots
end

function collect_atomic_plots(scene::Scene, plots = AbstractPlot[]; is_atomic_plot = is_atomic_plot)
    collect_atomic_plots(scene.plots, plots; is_atomic_plot = is_atomic_plot)
    collect_atomic_plots(scene.children, plots; is_atomic_plot = is_atomic_plot)
    return plots
end

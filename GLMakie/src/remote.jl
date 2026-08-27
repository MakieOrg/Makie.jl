################################################################################
### Remote screens
################################################################################

# A RemoteScreen stands in for a Screen on a machine that holds the data but
# cannot render it. Where Screen turns a plot's render leaves into a
# RenderObject on the GPU, RemoteScreen collects the same leaves into a
# RemoteObject and sends it over a connection to a process that can render.
# Nothing here touches OpenGL, so it works on the NULL platform.

"""
    send(connection, message)

The only thing a transport has to implement. Messages are plain tuples:

    (:scene,  id, [name => value, ...])
    (:plot,   id, scene_id, plotfunc, inputs, uniforms, values)
    (:update, id, [name => value, ...])
    (:delete, id)

A `:plot` message carries everything needed to draw it, so sending the current
objects is all a newly connected client needs.
"""
function send end

"""
    RemoteObject

The counterpart of a `RenderObject` for a `RemoteScreen`: the leaf values a
renderer needs for one primitive plot. `values` always holds the current state,
so a client that connects late can be sent the whole object.
"""
mutable struct RemoteObject
    id::UInt64
    scene_id::UInt64
    plotfunc::Symbol
    # kept split because register_robj! treats them differently: uniforms are
    # passed through to the render object, inputs need backend handling.
    inputs::Vector{Symbol}
    uniforms::Vector{Symbol}
    values::Dict{Symbol, Any}
end

function Base.show(io::IO, robj::RemoteObject)
    n = length(robj.inputs) + length(robj.uniforms)
    return print(io, "RemoteObject(", robj.plotfunc, ", id = ", robj.id, ", ", n, " leaves)")
end

mutable struct RemoteScreen{Connection} <: Makie.MakieScreen
    connection::Connection
    # Read where a Screen's config is: the light limits size the uniform arrays,
    # so sender and receiver have to agree on them. Both at their defaults is
    # that agreement -- a receiver is an ordinary GLMakie screen.
    config::ScreenConfig
    scene::Union{Nothing, Scene}
    cache::Dict{UInt64, RemoteObject}   # objectid(plot) => object
    # insertion order: a receiver draws in the order it is told about objects,
    # and Dict iteration order would put e.g. a menu's text under its own box
    order::Vector{UInt64}
    cache2plot::Dict{UInt64, Plot}
    scene_ids::IdDict{Scene, UInt64}
    requires_update::Bool
    sendloop::Union{Nothing, Task}
    stop_sendloop::Bool
end

function RemoteScreen(connection; screen_config...)
    config = Makie.merge_screen_config(ScreenConfig, Dict{Symbol, Any}(screen_config))
    screen = RemoteScreen(
        connection, config, nothing, Dict{UInt64, RemoteObject}(), UInt64[], Dict{UInt64, Plot}(),
        IdDict{Scene, UInt64}(), false, nothing, false
    )
    watch_atlas!(screen)
    return screen
end

# Every glyph rendered into the atlas gets forwarded, whatever asked for it --
# text, scatter markers, BezierPaths. The receiver needs no idea which plot a
# glyph belongs to, because it is handed sdf_uv rather than looking it up.
struct AtlasForwarder{S} <: Function
    screen::S
end

function (forward::AtlasForwarder)(sdf, area)
    send(forward.screen.connection, (:glyph, collect(sdf), area))
    return
end

watch_atlas!(screen::RemoteScreen) =
    Makie.font_render_callback!(AtlasForwarder(screen), Makie.get_texture_atlas())

# AtlasForwarder is immutable, so the one built here is `==` the one registered.
unwatch_atlas!(screen::RemoteScreen) =
    Makie.remove_font_render_callback!(Makie.get_texture_atlas(), AtlasForwarder(screen))

# The counterpart of GLMakie's render loop: resolving the graph is what makes
# updates get sent, so without this nothing propagates until someone asks.
#
# Resolving text can insert a glyph, and the atlas tells every callback about it
# -- including the texture upload of a Screen in this same process, which is only
# legal on the thread holding its GL context. So do not open a GLMakie window
# beside a RemoteScreen serving the same figure: the upload will run here and
# segfault. Serving is for a process that does not draw.
function start_sendloop!(screen::RemoteScreen; framerate = 30.0)
    isnothing(screen.sendloop) || return screen.sendloop
    screen.sendloop = Threads.@spawn while !screen.stop_sendloop
        poll_updates(screen)
        sleep(1.0 / framerate)
    end
    return screen.sendloop
end

function stop_sendloop!(screen::RemoteScreen)
    screen.stop_sendloop = true
    return
end

# Scene state a receiving scene needs so its plots come out the same. Camera and
# lights are both per-scene: a plot reads them from the scene it is drawn in, so
# they are sent once per scene rather than once per render object.
const SCENE_WIRE_NAMES = (
    # camera (see add_camera_computation!)
    :viewport, :view, :projection, :eyeposition, :upvector, :view_direction,
    # lighting inputs (see lighting.jl). The derived nodes -- dirlight_color and
    # friends -- are map! outputs, so the receiving scene recomputes them from
    # these rather than being handed values it could not write.
    :ambient_color, :lights, :shading,
)

# Scene fields rather than compute nodes, so they are read and applied directly.
const SCENE_WIRE_FIELDS = (:backgroundcolor, :visible, :clear)

struct RemoteSceneUpdater <: Function
    screen::RemoteScreen
    scene::Scene
    id::UInt64
end

scene_field_state(scene::Scene) =
    Pair{Symbol, Any}[name => getproperty(scene, name)[] for name in SCENE_WIRE_FIELDS]

function (updater::RemoteSceneUpdater)(args::NamedTuple, changed::NamedTuple, @nospecialize(last))
    # Applying some of a scene's values and all of them is the same operation,
    # so a full send and an update are the same message.
    names = isnothing(last) ? keys(args) : filter(name -> changed[name], keys(args))
    updates = Pair{Symbol, Any}[n => args[n] for n in names]
    isnothing(last) && append!(updates, scene_field_state(updater.scene))
    isroot = updater.scene === updater.screen.scene
    isempty(updates) || send(updater.screen.connection, (:scene, updater.id, updates, isroot))
    updater.screen.requires_update = true
    return (updater.id,)
end

function scene_id!(screen::RemoteScreen, scene::Scene)
    haskey(screen.scene_ids, scene) && return screen.scene_ids[scene]
    id = objectid(scene)
    screen.scene_ids[scene] = id
    register_computation!(
        RemoteSceneUpdater(screen, scene, id), scene.compute,
        collect(SCENE_WIRE_NAMES), [:remote_scene]
    )
    scene.compute[:remote_scene][]
    for name in SCENE_WIRE_FIELDS
        Makie.on(getproperty(scene, name)) do value
            send(screen.connection, (:scene, id, Pair{Symbol, Any}[name => value], scene === screen.scene))
            return
        end
    end
    return id
end

plot_message(robj::RemoteObject) =
    (:plot, robj.id, robj.scene_id, robj.plotfunc, robj.inputs, robj.uniforms, robj.values)

"""
    send_state(screen)

Send everything the screen currently holds, scenes first. This is what a client
that connects after plots already exist needs; it is the same set of messages it
would have received had it been connected all along.
"""
function send_state(screen::RemoteScreen, connection = screen.connection)
    # The whole atlas, not the glyphs this screen watched being written: it is
    # shared by everything in the process, so by the time a screen exists it
    # usually already holds glyphs nobody told this screen about.
    atlas = Makie.get_texture_atlas()
    send(connection, (:glyph, copy(atlas.data), Rect2{Int32}(0, 0, size(atlas.data)...)))
    for (scene, id) in screen.scene_ids
        state = Pair{Symbol, Any}[name => scene.compute[name][] for name in SCENE_WIRE_NAMES]
        append!(state, scene_field_state(scene))
        send(connection, (:scene, id, state, scene === screen.scene))
    end
    for id in screen.order
        send(connection, plot_message(screen.cache[id]))
    end
    return
end

struct RemoteObjectUpdater <: Function
    screen::RemoteScreen
    robj::RemoteObject
end

function (updater::RemoteObjectUpdater)(args::NamedTuple, changed::NamedTuple, @nospecialize(last))
    robj = updater.robj
    if isnothing(last)
        for name in keys(args)
            robj.values[name] = args[name]
        end
        send(updater.screen.connection, plot_message(robj))
    else
        updates = Pair{Symbol, Any}[]
        for name in keys(args)
            changed[name] || continue
            value = args[name]
            robj.values[name] = value
            push!(updates, name => value)
        end
        isempty(updates) || send(updater.screen.connection, (:update, robj.id, updates))
    end
    updater.screen.requires_update = true
    return (robj,)
end

"""
    register_light_attributes!(screen::RemoteScreen, scene, attr, uniforms)

Serving a plot that a `Screen` in this process is also drawing. GLMakie reads
already-registered lights as a render object being built twice and refuses;
here they are nodes that exist and can be read as they are, so the plot is
shipped with the lights it was given.
"""
function register_light_attributes!(screen::RemoteScreen, scene::Scene, attr, uniforms)
    if haskey(attr, :ambient) && haskey(attr, :gl_renderobject)
        for name in LIGHT_ROBJ_UNIFORMS
            haskey(attr, name) && push!(uniforms, name)
        end
        return
    end
    return invoke(register_light_attributes!, Tuple{Any, Any, Any, Any}, screen, scene, attr, uniforms)
end

function draw_remote(screen::RemoteScreen, scene::Scene, plot::Plot)
    haskey(screen.cache, objectid(plot)) && return

    # The same path a Screen takes, stopping where OpenGL would start. The names
    # come from robj_inputs!, so there is nothing here to keep in sync with it.
    inputs, uniforms = register_render_leaves!(scene, plot)
    # robj_inputs! appends to uniforms, and the receiving register_robj! appends
    # the same names again, so ship what the primitive declared.
    wire_inputs, wire_uniforms = copy(inputs), copy(uniforms)
    input2glname = Dict{Symbol, Symbol}()
    names = robj_inputs!(screen, scene, plot, inputs, uniforms, input2glname)

    # A receiver builds the render object itself, so it needs what that reads off
    # the plot as well as the leaves. Kept out of inputs/uniforms: putting them
    # there makes update_robjs! re-upload them and fight the stored GL type.
    for name in ROBJ_CONSTRUCTION_ATTRIBUTES
        haskey(plot.attributes, name) && push!(names, name)
    end

    # The camera belongs to the scene, so it is sent once per scene. Watching it
    # here would resend every matrix for every primitive on each pan.
    camera = camera_robj_uniforms(plot.attributes)
    watched = filter(!in(camera), names)

    robj = RemoteObject(
        objectid(plot), scene_id!(screen, scene), Makie.plotkey(plot),
        wire_inputs, wire_uniforms, Dict{Symbol, Any}()
    )
    screen.cache[objectid(plot)] = robj
    push!(screen.order, objectid(plot))
    screen.cache2plot[robj.id] = plot

    register_computation!(RemoteObjectUpdater(screen, robj), plot.attributes, watched, [:remote_object])
    plot.attributes[:remote_object][] # resolve once so the object is sent
    return robj
end

# Mirrors Base.insert!(::Screen, ...): walk down to the primitives the backend
# can actually draw.
function Base.insert!(screen::RemoteScreen, scene::Scene, @nospecialize(plot::Plot))
    if isempty(plot.plots) # if no plots inserted, this truly is an atomic
        draw_remote(screen, scene, plot)
    elseif plot isa Text
        draw_remote(screen, scene, plot)
        insert!(screen, scene, plot.plots[1])
    elseif plot isa Makie.PlotList
        Makie.for_each_atomic_plot(plot) do p
            haskey(screen.cache, objectid(p)) || insert!(screen, scene, p)
        end
    else
        foreach(p -> insert!(screen, scene, p), plot.plots)
    end
    screen.requires_update = true
    return
end

draw_remote(::RemoteScreen, ::Scene, ::PlotList) = nothing

function Base.delete!(screen::RemoteScreen, ::Scene, plot::Plot)
    robj = get(screen.cache, objectid(plot), nothing)
    isnothing(robj) && return
    delete!(screen.cache, objectid(plot))
    filter!(!=(objectid(plot)), screen.order)
    delete!(screen.cache2plot, robj.id)
    haskey(plot.attributes, :remote_object) && delete!(plot.attributes, :remote_object)
    send(screen.connection, (:delete, robj.id))
    return
end

# Mirrors GLMakie's poll_updates: requesting the output node is what makes the
# graph resolve and the updater run.
function poll_updates(screen::RemoteScreen)
    for (scene, _) in screen.scene_ids
        scene.compute[:remote_scene][]
    end
    for plot in values(screen.cache2plot)
        scene = Makie.parent_scene(plot)
        scene.visible[] || continue
        try
            plot.attributes[:remote_object][]
        catch e
            @error "Failed to update remote object - skipping update" exception = (e, catch_backtrace())
            ComputePipeline.mark_resolved!(plot.attributes[:remote_object])
        end
    end
    return
end

# Scenes are otherwise only registered when a primitive lands in one, so a scene
# holding no plots of its own -- a Figure's root, for instance -- would never be
# mirrored and its background and visibility would never be sent.
function register_scenes!(screen::RemoteScreen, scene::Scene)
    scene_id!(screen, scene)
    foreach(child -> register_scenes!(screen, child), scene.children)
    return
end

function Base.display(screen::RemoteScreen, scene::Scene; display_kw...)
    screen.scene = scene
    Makie.push_screen!(scene, screen)
    register_scenes!(screen, scene)
    Makie.insertplots!(screen, scene)
    start_sendloop!(screen)
    return screen
end

Base.isopen(::RemoteScreen) = true

# There is no window on this side. resize!(scene, ...) sets the viewport itself
# and then notifies its screens, and the new viewport reaches the far side as
# ordinary scene state, so there is nothing further to do here.
Base.resize!(::RemoteScreen, ::Int, ::Int) = nothing
Base.size(screen::RemoteScreen) = isnothing(screen.scene) ? (0, 0) : size(screen.scene)

function Base.empty!(screen::RemoteScreen)
    for (id, _) in screen.cache2plot
        send(screen.connection, (:delete, id))
    end
    empty!(screen.cache)
    empty!(screen.order)
    empty!(screen.cache2plot)
    empty!(screen.scene_ids)
    return
end

function Base.close(screen::RemoteScreen)
    stop_sendloop!(screen)
    unwatch_atlas!(screen)
    empty!(screen)
    # the connection owns a listening socket; leaving it bound makes the next
    # RemoteScreen on the same port fail with EADDRINUSE
    applicable(close, screen.connection) && close(screen.connection)
    return
end

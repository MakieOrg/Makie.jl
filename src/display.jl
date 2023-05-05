@enum ImageStorageFormat JuliaNative GLNative

update_state_before_display!(_) = nothing

function backend_show end

"""
Current backend
"""
const CURRENT_BACKEND = Ref{Union{Missing, Module}}(missing)
current_backend() = CURRENT_BACKEND[]

function set_active_backend!(backend::Union{Missing, Module})
    CURRENT_BACKEND[] = backend
    return
end

function push_screen!(scene::Scene, display)
    error("$(display) not a valid Makie display.")
end

"""
    push_screen!(scene::Scene, screen::MakieScreen)

Adds a screen to the scene and registeres a clean up event when screen closes.
Also, makes sure that always just one screen is active for on scene.
"""
function push_screen!(scene::Scene, screen::T) where {T<:MakieScreen}
    if !(screen in scene.current_screens)
        # If screen isn't already part of this scene, we make sure
        # that the screen only has one screen per type
        of_same_type = filter(x -> x isa T, scene.current_screens) # collect all of same type
        foreach(x -> delete_screen!(scene, x), of_same_type)
        # Now we can push the screen :)
        push!(scene.current_screens, screen)
    end
    # Now only thing left is to make sure all children also have the screen!
    for children in scene.children
        push_screen!(children, screen)
    end
    return
end

"""
    delete_screen!(scene::Scene, screen::MakieScreen)

Removes screen from scene and cleans up screen
"""
function delete_screen!(scene::Scene, screen::MakieScreen)
    delete!(screen, scene)
    empty!(screen)
    filter!(x-> x !== screen, scene.current_screens)
    return
end

function set_screen_config!(backend::Module, new_values)
    key = nameof(backend)
    backend_defaults = CURRENT_DEFAULT_THEME[key]
    bkeys = keys(backend_defaults)
    for (k, v) in pairs(new_values)
        if !(k in bkeys)
            error("$k is not a valid screen config. Applicable options: $(keys(backend_defaults)). For help, check `?$(backend).ScreenCofig`")
        end
        backend_defaults[k] = v
    end
    return backend_defaults
end

function merge_screen_config(::Type{Config}, screen_config_kw) where Config
    backend = parentmodule(Config)
    key = nameof(backend)
    backend_defaults = CURRENT_DEFAULT_THEME[key]
    kw_nt = values(screen_config_kw)
    arguments = map(fieldnames(Config)) do name
        if haskey(kw_nt, name)
            return getfield(kw_nt, name)
        else
            return to_value(backend_defaults[name])
        end
    end
    return Config(arguments...)
end


const ALWAYS_INLINE_PLOTS = Ref{Bool}(false)

"""
    inline!(inline=true)

Prevents opening a window when e.g. in the REPL.
Usually, Makie opens a window when displaying a plot.
Only case Makie always shows the plot inside the plotpane is when using VSCode eval.
If you want to always force inlining the plot into the plotpane, set `inline!(true)` (E.g. when run in the VSCode REPL).
In other cases `inline!(true/false)` won't do anything.
"""
function inline!(inline=true)
    ALWAYS_INLINE_PLOTS[] = inline
end

wait_for_display(screen) = nothing

"""
    Base.display(figlike::FigureLike; backend=current_backend(), screen_config...)

Displays the figurelike in a window or the browser, depending on the backend.

The parameters for `screen_config` are backend dependend,
see `?Backend.Screen` or `Base.doc(Backend.Screen)` for applicable options.
"""
function Base.display(figlike::FigureLike; backend=current_backend(), update=true, screen_config...)
    if ismissing(backend)
        error("""
        No backend available!
        Make sure to also `import/using` a backend (GLMakie, CairoMakie, WGLMakie).

        If you imported GLMakie, it may have not built correctly.
        In that case, try `]build GLMakie` and watch out for any warnings.
        """)
    end
    if ALWAYS_INLINE_PLOTS[]
        Core.invoke(display, Tuple{Any}, figlike)
        screen = getscreen(get_scene(figlike))
        wait_for_display(screen)
        return screen
    else
        scene = get_scene(figlike)
        update && update_state_before_display!(figlike)
        screen = getscreen(backend, scene; screen_config...)
        display(screen, scene)
        return screen
    end
end

is_displayed(screen::MakieScreen, scene::Scene) = screen in scene.current_screens


# Backends overload display(::Backend.Screen, scene::Scene), while Makie overloads the below,
# so that they don't need to worry
# about stuff like `update_state_before_display!`
function Base.display(screen::MakieScreen, figlike::FigureLike; update=true, display_attributes...)
    scene = get_scene(figlike)
    update && update_state_before_display!(figlike)
    display(screen, get_scene(figlike); display_attributes...)
    return screen
end

function _backend_showable(mime::MIME{SYM}) where SYM
    # If we open a window, don't become part of the display/show system
    !ALWAYS_INLINE_PLOTS[] && return false
    Backend = current_backend()
    if ismissing(Backend)
        return Symbol("text/plain") == SYM
    end
    return backend_showable(Backend.Screen, mime)
end

Base.showable(mime::MIME, fig::FigureLike) = _backend_showable(mime)

# need to define this to resolve ambiguoity issue
Base.showable(mime::MIME"application/json", fig::FigureLike) = _backend_showable(mime)

backend_showable(@nospecialize(screen), @nospecialize(mime)) = false

# fallback show when no backend is selected
function backend_show(backend, io::IO, ::MIME"text/plain", scene::Scene)
    if backend isa Missing
        @warn """
        Printing Scene as text because no backend is available (GLMakie, CairoMakie, WGLMakie).
        Maybe you imported GLMakie but it didn't build correctly.
        In that case, try `]build GLMakie` and watch out for any warnings.
        """
    end
    print(io, scene)
    return
end

function Base.show(io::IO, ::MIME"text/plain", scene::Scene)
    show(io, scene)
end

# VSCode per default displays an object as markdown as well.
# Which, without throwing a method error, would show a plot 2 times from within the display system.
# This can lead to hangs e.g. for WGLMakie, where there is only one plotpane/browser, which then one waits on
function Base.show(io::IO, m::MIME"text/markdown", fig::FigureLike)
    throw(MethodError(show, io, m, fig))
end

function Base.show(io::IO, m::MIME, figlike::FigureLike)
    if !ALWAYS_INLINE_PLOTS[]
        # If we always want to open a window, we call display manually here
        # and then throw a method error to signal the calling display system, that we don't want to display it with them
        display(figlike)
        throw(MethodError(show, io, m, figlike))
    end
    scene = get_scene(figlike)
    backend = current_backend()
    # get current screen the scene is already displayed on, or create a new screen
    update_state_before_display!(figlike)
    screen = getscreen(backend, scene, io, m; visible=false)
    backend_show(screen, io, m, scene)
    return screen
end

format2mime(::Type{FileIO.format"PNG"}) = MIME("image/png")
format2mime(::Type{FileIO.format"SVG"}) = MIME("image/svg+xml")
format2mime(::Type{FileIO.format"JPEG"}) = MIME("image/jpeg")
format2mime(::Type{FileIO.format"TIFF"}) = MIME("image/tiff")
format2mime(::Type{FileIO.format"BMP"}) = MIME("image/bmp")
format2mime(::Type{FileIO.format"PDF"}) = MIME("application/pdf")
format2mime(::Type{FileIO.format"TEX"}) = MIME("application/x-tex")
format2mime(::Type{FileIO.format"EPS"}) = MIME("application/postscript")
format2mime(::Type{FileIO.format"HTML"}) = MIME("text/html")

filetype(::FileIO.File{F}) where F = F
# Allow format to be overridden with first argument

"""
    FileIO.save(filename, scene; resolution = size(scene), pt_per_unit = 0.75, px_per_unit = 1.0)

Save a `Scene` with the specified filename and format.

# Supported Formats

- `GLMakie`: `.png`, `.jpeg`, and `.bmp`
- `CairoMakie`: `.svg`, `.pdf`, `.png`, and `.jpeg`
- `WGLMakie`: `.png`

# Supported Keyword Arguments

## All Backends

- `resolution`: `(width::Int, height::Int)` of the scene in dimensionless units (equivalent to `px` for GLMakie and WGLMakie).

## CairoMakie

- `pt_per_unit`: The size of one scene unit in `pt` when exporting to a vector format.
- `px_per_unit`: The size of one scene unit in `px` when exporting to a bitmap format. This provides a mechanism to export the same scene with higher or lower resolution.
"""
function FileIO.save(
        filename::String, fig::FigureLike; args...
    )
    FileIO.save(FileIO.query(filename), fig; args...)
end

function FileIO.save(
        file::FileIO.Formatted, fig::FigureLike;
        resolution = size(get_scene(fig)),
        backend = current_backend(),
        update = true,
        screen_config...
    )
    scene = get_scene(fig)
    if resolution != size(scene)
        resize!(scene, resolution)
    end
    filename = FileIO.filename(file)
    # Delete previous file if it exists and query only the file string for type.
    # We overwrite existing files anyway, so this doesn't change the behavior.
    # But otherwise we could get a filetype :UNKNOWN from a corrupt existing file
    # (from an error during save, e.g.), therefore we don't want to rely on the
    # type readout from an existing file.
    isfile(filename) && rm(filename)
    # query the filetype only from the file extension
    F = filetype(file)
    mime = format2mime(F)
    try
        return open(filename, "w") do io
            # If the scene already got displayed, we get the current screen its displayed on
            # Else, we create a new scene and update the state of the fig
            update && update_state_before_display!(fig)
            screen = getscreen(backend, scene, io, mime; visible=false, screen_config...)
            backend_show(screen, io, mime, scene)
        end
    catch e
        # So, if open(io-> error(...), "w"), the file will get created, but not removed...
        isfile(filename) && rm(filename; force=true)
        rethrow(e)
    end
end

# Methods are used in backends to unwrap
raw_io(io::IO) = io
raw_io(io::IOContext) = raw_io(io.io)

# This has to be overloaded by the backend for its screen type.
function colorbuffer(x::MakieScreen)
    error("colorbuffer not implemented for screen $(typeof(x))")
end

function jl_to_gl_format(image)
    @static if VERSION < v"1.6"
        d1, d2 = size(image)
        bufc = Array{eltype(image)}(undef, d2, d1) #permuted
        ind1, ind2 = axes(image)
        n = first(ind1) + last(ind1)
        for i in ind1
            @simd for j in ind2
                @inbounds bufc[j, n-i] = image[i, j]
            end
        end
        return bufc
    else
        reverse!(image; dims=1)
        return PermutedDimsArray(image, (2, 1))
    end
end

# less specific for overloading by backends
function colorbuffer(screen::MakieScreen, format::ImageStorageFormat)
    image = colorbuffer(screen)
    if format == GLNative
        return jl_to_gl_format(image)
    elseif format == JuliaNative
        return image
    end
end

function apply_screen_config! end

"""
    getscreen(scene::Scene)

Gets the current screen a scene is associated with.
Returns nothing if not yet displayed on a screen.
"""
function getscreen(scene::Scene, backend=current_backend())
    isempty(scene.current_screens) && return nothing # stop search
    idx = findfirst(scene.current_screens) do screen
        parentmodule(typeof(screen)) === backend
    end
    isnothing(idx) && return nothing
    # TODO, when would we actually want to get a specific screen?
    return scene.current_screens[idx]
end

getscreen(scene::SceneLike, backend=current_backend()) = getscreen(get_scene(scene), backend)

function getscreen(backend::Union{Missing, Module}, scene::Scene, args...; screen_config...)
    screen = getscreen(scene, backend)
    config = Makie.merge_screen_config(backend.ScreenConfig, screen_config)
    if !isnothing(screen) && parentmodule(typeof(screen)) == backend
        new_screen = apply_screen_config!(screen, config, scene, args...)
        if new_screen !== screen
            # Apply config is allowed to recreate a screen, but that means we need to delete the old one:
            delete_screen!(scene, screen)
        end
        return new_screen
    end
    if ismissing(backend)
        error("""
            You have not loaded a backend.  Please load one (`using GLMakie` or `using CairoMakie`)
            before trying to render a Scene.
            """)
    else
        return backend.Screen(scene, config, args...)
    end
end

"""
    colorbuffer(scene, format::ImageStorageFormat = JuliaNative; backend=current_backend(), screen_config...)
    colorbuffer(screen, format::ImageStorageFormat = JuliaNative)

Returns the content of the given scene or screen rasterised to a Matrix of
Colors. The return type is backend-dependent, but will be some form of RGB
or RGBA.

- `format = JuliaNative` : Returns a buffer in the format of standard julia images (dims permuted and one reversed)
- `format = GLNative` : Returns a more efficient format buffer for GLMakie which can be directly
                        used in FFMPEG without conversion
- `screen_config`: Backend dependend, look up via `?Backend.Screen`/`Base.doc(Backend.Screen)`
"""
function colorbuffer(fig::FigureLike, format::ImageStorageFormat = JuliaNative; update=true, backend = current_backend(), screen_config...)
    scene = get_scene(fig)
    update && update_state_before_display!(fig)
    screen = getscreen(backend, scene, format; start_renderloop=false, visible=false, screen_config...)
    return colorbuffer(screen, format)
end

# Fallback for any backend that will just use colorbuffer to write out an image
function backend_show(screen::MakieScreen, io::IO, m::MIME"image/png", scene::Scene)
    img = colorbuffer(screen)
    FileIO.save(FileIO.Stream{FileIO.format"PNG"}(Makie.raw_io(io)), img)
    return
end

function backend_show(screen::MakieScreen, io::IO, m::MIME"image/jpeg", scene::Scene)
    img = colorbuffer(scene)
    FileIO.save(FileIO.Stream{FileIO.format"JPEG"}(Makie.raw_io(io)), img)
    return
end

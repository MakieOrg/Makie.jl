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

Adds a screen to the scene and registered a clean up event when screen closes.
Also, makes sure that always just one screen is active for on scene.
"""
function push_screen!(scene::Scene, screen::T) where {T <: MakieScreen}
    if !(screen in scene.current_screens)
        # If screen isn't already part of this scene, we make sure
        # that the screen only has one screen per type
        of_same_type = filter(x -> x isa T, scene.current_screens) # collect all of same type
        # foreach(x -> delete_screen!(scene, x), of_same_type)
        # Now we can push the screen :)
        push!(scene.current_screens, screen)
        unique!(scene.current_screens)
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
    filter!(x -> x !== screen, scene.current_screens)
    return
end

function set_screen_config!(backend::Module, new_values)
    key = nameof(backend)
    backend_defaults = CURRENT_DEFAULT_THEME[key]
    bkeys = keys(backend_defaults)
    for (k, v) in pairs(new_values)
        if !(k in bkeys)
            error("$k is not a valid screen config. Applicable options: $(keys(backend_defaults)). For help, check `?$(backend).ScreenConfig`")
        end
        backend_defaults[k] = v
    end
    return backend_defaults
end

function merge_screen_config(::Type{Config}, config::Dict) where {Config}
    backend = parentmodule(Config)
    key = nameof(backend)
    backend_defaults = CURRENT_DEFAULT_THEME[key]
    arguments = map(fieldnames(Config)) do name
        if haskey(config, name)
            return config[name]
        else
            return to_value(backend_defaults[name])
        end
    end
    return Config(arguments...)
end


const ALWAYS_INLINE_PLOTS = Ref{Union{Automatic, Bool}}(automatic)

"""
    inline!(inline=true)

Prevents opening a window when e.g. in the REPL.
Usually, Makie opens a window when displaying a plot.
Only case Makie always shows the plot inside the plotpane is when using VSCode eval.
If you want to always force inlining the plot into the plotpane, set `inline!(true)` (E.g. when run in the VSCode REPL).
In other cases `inline!(true/false)` won't do anything.
"""
function inline!(inline = automatic)
    return ALWAYS_INLINE_PLOTS[] = inline
end

wait_for_display(screen) = nothing

function has_mime_display(mime)
    for display in Base.Multimedia.displays
        # Ugh, why would textdisplay say it supports HTML??
        display isa TextDisplay && continue
        displayable(display, mime) && return true
    end
    return false
end

can_show_inline(::Missing) = false # no backend
function can_show_inline(Backend)
    for mime in (MIME"juliavscode/html"(), MIME"text/html"(), MIME"image/png"(), MIME"image/svg+xml"())
        if backend_showable(Backend.Screen, mime) && has_mime_display(mime)
            return true
        end
    end
    return false
end

"""
    Base.display(figlike::FigureLike; backend=current_backend(), screen_config...)

Displays the figurelike in a window or the browser, depending on the backend.

The parameters for `screen_config` are backend dependent,
see `?Backend.Screen` or `Base.doc(Backend.Screen)` for applicable options.

`backend` accepts Makie backend modules, e.g.: `backend = GLMakie`, `backend = CairoMakie`, etc.
"""
function Base.display(
        figlike::FigureLike; backend = current_backend(),
        inline = ALWAYS_INLINE_PLOTS[], update = true, screen_config...
    )
    config = Dict{Symbol, Any}(screen_config)
    if ismissing(backend)
        error(
            """
            No backend available!
            Make sure to also `import/using` a backend (GLMakie, CairoMakie, WGLMakie).

            If you imported GLMakie, it may have not built correctly.
            In that case, try `]build GLMakie` and watch out for any warnings.
            """
        )
    end

    # We show inline if explicitly requested or if automatic and we can actually show something inline!
    scene = get_scene(figlike)
    if (inline === true || inline === automatic) && can_show_inline(backend)
        # We can't forward the screenconfig to show, but show uses the current screen if there is any
        # We use that, to create a screen before show and rely on show picking up that screen
        screen = getscreen(backend, scene, config)
        push_screen!(scene, screen)
        Core.invoke(display, Tuple{Any}, figlike)
        # In WGLMakie, we need to wait for the display being done
        screen = getscreen(scene)
        wait_for_display(screen)
        return screen
    else
        if inline === true
            @warn """

                Makie.inline!(do_inline) was set to true, but we didn't detect a display that can show the plot,
                so we aren't inlining the plot and try to show the plot in a window.
                If this wasn't set on purpose, call `Makie.inline!()` to restore the default.
            """
        end
        update && update_state_before_display!(figlike)
        screen = getscreen(backend, scene, config)
        display(screen, scene)
        return screen
    end
end

is_displayed(screen::MakieScreen, scene::Scene) = screen in scene.current_screens


# Backends overload display(::Backend.Screen, scene::Scene), while Makie overloads the below,
# so that they don't need to worry
# about stuff like `update_state_before_display!`
function Base.display(screen::MakieScreen, figlike::FigureLike; update = true, display_attributes...)
    scene = get_scene(figlike)
    update && update_state_before_display!(figlike)
    display(screen, get_scene(figlike); display_attributes...)
    return screen
end

# This isn't particularly nice,
# But, for `Makie.inline!(false)`, we want to show a plot in a gui regardless
# of an enabled plotpane or not
# Since VSCode doesn't call any display/show method for Figurelike if we return
# `showable(mime, fig) == false`, we need to return `showable(mime, figlike) == true`
# For some vscode displayable mime, even for `Makie.inline!(false)` when we want to display in our own window.
# Only diagnostic can be used for this, since other mimes expect something to be shown after all and
# therefore will look broken in the plotpane if we dont print anything to the IO.
# I tried `throw(MethodError(...))` as well, but with plotpane enabled + showable == true,
# VScode doesn't catch that method error.
const MIME_TO_TRICK_VSCODE = MIME"application/vnd.julia-vscode.diagnostics"

function _backend_showable(mime::MIME{SYM}) where {SYM}
    if ALWAYS_INLINE_PLOTS[] == false
        if mime isa MIME_TO_TRICK_VSCODE
            return true
        end
    end
    Backend = current_backend()
    if ismissing(Backend)
        return Symbol("text/plain") == SYM
    end
    return backend_showable(Backend.Screen, mime)
end

Base.showable(mime::MIME, fig::FigureLike) = _backend_showable(mime)

# need to define this to resolve ambiguity issue
Base.showable(mime::MIME"application/json", fig::FigureLike) = _backend_showable(mime)

const WEB_MIMES = (
    MIME"text/html",
    MIME"application/vnd.webio.application+html",
    MIME"application/prs.juno.plotpane+html",
    MIME"juliavscode/html",
)


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

# VSCode per default displays an object as markdown as well.
# Which, without throwing a method error, would show a plot 2 times from within the display system.
# This can lead to hangs e.g. for WGLMakie, where there is only one plotpane/browser, which then one waits on
function Base.show(io::IO, m::MIME"text/markdown", fig::FigureLike)
    throw(MethodError(show, io, m, fig))
end

function Base.show(io::IO, m::MIME, figlike::FigureLike; backend = current_backend(), update = true)
    if ALWAYS_INLINE_PLOTS[] == false && m isa MIME_TO_TRICK_VSCODE
        # We use this mime to display the figure in a window here.
        # See declaration of MIME_TO_TRICK_VSCODE for more info
        display(figlike)
        return () # this is a diagnostic vscode mime, so we can just return nothing
    end
    scene = get_scene(figlike)
    # get current screen the scene is already displayed on, or create a new screen
    update && update_state_before_display!(figlike)
    screen = getscreen(backend, scene, Dict(:visible => false), io, m)
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

filetype(::FileIO.File{F}) where {F} = F
# Allow format to be overridden with first argument

"""
    FileIO.save(filename, scene; size = size(scene), pt_per_unit = 0.75, px_per_unit = 1.0)

Save a `Scene` with the specified filename and format.

# Supported Formats

- `GLMakie`: `.png`
- `CairoMakie`: `.svg`, `.pdf` and `.png`
- `WGLMakie`: `.png`

# Supported Keyword Arguments

## All Backends

- `size`: `(width::Int, height::Int)` of the scene in dimensionless units.
- `update`: Whether the figure should be updated before saving. This resets the limits of all Axes in the figure. Defaults to `true`.
- `backend`: Specify the `Makie` backend that should be used for saving. Defaults to the current backend.
- `px_per_unit`: The size of one scene unit in `px` when exporting to a bitmap format. This provides a mechanism to export the same scene with higher or lower resolution.
- Further keywords will be forwarded to the screen.


## CairoMakie

- `pt_per_unit`: The size of one scene unit in `pt` when exporting to a vector format.
"""
function FileIO.save(
        filename::String, fig::FigureLike; args...
    )
    return FileIO.save(FileIO.query(filename), fig; args...)
end

function FileIO.save(
        file::FileIO.Formatted, fig::FigureLike;
        size = Base.size(get_scene(fig)),
        resolution = nothing,
        backend = current_backend(),
        update = true,
        screen_config...
    )
    if ismissing(backend)
        error(
            """
            No backend available!
            Make sure to also `import/using` a backend (GLMakie, CairoMakie, WGLMakie).

            If you imported GLMakie, it may have not built correctly.
            In that case, try `]build GLMakie` and watch out for any warnings.
            """
        )
    end
    scene = get_scene(fig)
    if resolution !== nothing
        @warn "The keyword argument `resolution` for `save()` has been deprecated. Use `size` instead, which better reflects that this is a unitless size and not a pixel resolution."
        size = resolution
    end
    if size != Base.size(scene)
        resize!(scene, size)
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
            visible = isvisible(getscreen(scene)) # if already has a screen, don't hide it!
            config = Dict{Symbol, Any}(screen_config)
            get!(config, :visible, visible)
            screen = getscreen(backend, scene, config, io, mime)
            events(fig).tick[] = Tick(OneTimeRenderTick, 0, 0.0, 0.0)
            backend_show(screen, io, mime, scene)
        end
    catch e
        # So, if open(io-> error(...), "w"), the file will get created, but not removed...
        isfile(filename) && rm(filename; force = true)
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
                @inbounds bufc[j, n - i] = image[i, j]
            end
        end
        return bufc
    else
        reverse!(image; dims = 1)
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
function getscreen(scene::Scene, backend = current_backend())
    isempty(scene.current_screens) && return nothing # stop search
    idx = findfirst(scene.current_screens) do screen
        parentmodule(typeof(screen)) === backend
    end
    isnothing(idx) && return nothing
    # TODO, when would we actually want to get a specific screen?
    screen = scene.current_screens[idx]
    isopen(screen) && return screen
    return screen
end

getscreen(scene::SceneLike, backend = current_backend()) = getscreen(get_scene(scene), backend)

function getscreen(backend::Union{Missing, Module}, scene::Scene, _config::Dict, args...)
    screen = getscreen(scene, backend)
    config = merge_screen_config(backend.ScreenConfig, _config)
    if !isnothing(screen) && parentmodule(typeof(screen)) == backend
        new_screen = apply_screen_config!(screen, config, scene, args...)
        if new_screen !== screen
            # Apply config is allowed to recreate a screen, but that means we need to delete the old one:
            delete_screen!(scene, screen)
        end
        return new_screen
    end
    if ismissing(backend)
        error(
            """
            You have not loaded a backend.  Please load one (`using GLMakie` or `using CairoMakie`)
            before trying to render a Scene.
            """
        )
    else
        return backend.Screen(scene, config, args...)
    end
end

function get_sub_picture(image, format::ImageStorageFormat, rect)
    xmin, ymin = minimum(rect) .- Vec(1, 0)
    xmax, ymax = maximum(rect)
    start = size(image, 1) - ymax
    stop = size(image, 1) - ymin
    return image[start:stop, xmin:xmax]
end

# Needs to be overloaded by backends, with fallback true
isvisible(screen::MakieScreen) = true
isvisible(::Nothing) = false

# Make colorbuffer(fig) thread safe
const COLORBUFFER_LOCK = ReentrantLock()

"""
    colorbuffer(scene, format::ImageStorageFormat = JuliaNative; update=true, backend=current_backend(), screen_config...)

Returns the content of the given scene or screen rasterised to a Matrix of
Colors. The return type is backend-dependent, but will be some form of RGB
or RGBA.

- `backend::Module`: A module which is a Makie backend.  For example, `backend = GLMakie`, `backend = CairoMakie`, etc.
- `format = JuliaNative` : Returns a buffer in the format of standard julia images (dims permuted and one reversed)
- `format = GLNative` : Returns a more efficient format buffer for GLMakie which can be directly
                        used in FFMPEG without conversion
- `screen_config`: Backend dependent, look up via `?Backend.Screen`/`Base.doc(Backend.Screen)`
- `update=true`: resets/updates limits. Set to false, if you want to preserver camera movements.
"""
function colorbuffer(fig::FigureLike, format::ImageStorageFormat = JuliaNative; update = true, backend = current_backend(), screen_config...)
    return lock(COLORBUFFER_LOCK) do
        scene = get_scene(fig)
        update && update_state_before_display!(fig)
        # if already has a screen, use their visibility value, if no screen, returns false
        visible = isvisible(getscreen(scene))
        config = Dict{Symbol, Any}(screen_config)
        get!(config, :visible, visible)
        get!(config, :start_renderloop, false)
        screen = getscreen(backend, scene, config)
        img = colorbuffer(screen, format)
        if !isroot(scene)
            return get_sub_picture(img, format, viewport(scene)[])
        else
            return img
        end
    end
end

px_per_unit(screen::MakieScreen)::Float64 = 1.0 # fallback for backends who don't have upscaling

# Fallback for any backend that will just use colorbuffer to write out an image
function backend_show(screen::MakieScreen, io::IO, ::MIME"image/png", scene::Scene)
    img = colorbuffer(screen)
    px_per_unit = Makie.px_per_unit(screen)::Float64
    dpi = px_per_unit * 96 # attach dpi metadata corresponding to 1 unit == 1 CSS pixel
    FileIO.save(FileIO.Stream{FileIO.format"PNG"}(Makie.raw_io(io)), img; dpi)
    return
end

function backend_show(screen::MakieScreen, io::IO, ::MIME"image/jpeg", scene::Scene)
    img = colorbuffer(screen)
    FileIO.save(FileIO.Stream{FileIO.format"JPEG"}(Makie.raw_io(io)), img)
    return
end

function backend_show(screen::MakieScreen, io::IO, ::Union{WEB_MIMES...}, scene::Scene)
    w, h = size(scene)
    png_io = IOBuffer()
    backend_show(screen, png_io, MIME"image/png"(), scene)
    b64 = Base64.base64encode(String(take!(png_io)))
    style = "object-fit: contain; height: auto;"
    print(io, "<img width=$w height=$h style='$style' src=\"data:image/png;base64, $(b64)\"/>")
    return
end

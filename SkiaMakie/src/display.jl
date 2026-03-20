#########################################
# Backend interface to Makie #
#########################################

function tryrun(cmd::Cmd)
    try
        return success(cmd)
    catch e
        return false
    end
end

function openurl(url::String)
    if Sys.isapple()
        tryrun(`open $url`) && return
    elseif Sys.iswindows()
        tryrun(`powershell.exe start $url`) && return
    elseif Sys.isunix()
        tryrun(`xdg-open $url`) && return
        tryrun(`gnome-open $url`) && return
    end
    tryrun(`python -mwebbrowser $(url)`) && return
    tryrun(`python3 -mwebbrowser $(url)`) && return
    return @warn("Can't find a way to open a browser, open $(url) manually!")
end

function Base.display(screen::Screen, scene::Scene; connect = false, figure = nothing)
    return screen
end

function Base.display(screen::Screen{IMAGE}, scene::Scene; connect = false, figure = nothing, screen_config...)
    config = Makie.merge_screen_config(ScreenConfig, Dict{Symbol, Any}(screen_config))
    screen = Makie.apply_screen_config!(screen, config, scene)
    path = joinpath(mktempdir(), "display.png")
    Makie.push_screen!(scene, screen)
    skia_draw(screen, scene)
    save_surface_to_png(screen.surface, path)
    if screen.visible
        openurl("file:///" * path)
    end
    return screen
end

# Disabling mimes and showable

const DISABLED_MIMES = Set{String}()
const SUPPORTED_MIMES = Set(
    [
        map(x -> string(x()), Makie.WEB_MIMES)...,
        "image/svg+xml",
        "application/pdf",
        "image/png",
    ]
)

function Makie.backend_showable(::Type{Screen}, ::MIME{SYM}) where {SYM}
    supported_mimes = Base.setdiff(SUPPORTED_MIMES, DISABLED_MIMES)
    return string(SYM) in supported_mimes
end

function Makie.backend_show(screen::Screen{IMAGE}, io::IO, ::MIME"image/png", scene::Scene, figure = nothing)
    Makie.push_screen!(scene, screen)
    empty!(screen)
    skia_draw(screen, scene)
    w, h = Base.size(screen)
    snapshot = sk_surface_make_image_snapshot(screen.surface)
    pngdata = sk_encode_png(C_NULL, snapshot, Int32(0))
    # Read the encoded PNG data and write to IO
    data_size = sk_data_get_size(pngdata)
    data_ptr = sk_data_get_data(pngdata)
    write(io, unsafe_wrap(Array, Ptr{UInt8}(data_ptr), data_size))
    return screen
end

function to_mime_string(mime::Union{String, Symbol, MIME})
    if mime isa MIME
        mime_str = string(mime)
        !(mime_str in SUPPORTED_MIMES) && error("Mime $(mime) not supported by SkiaMakie")
        return mime_str
    else
        mime_str = string(mime)
        if !(mime_str in SUPPORTED_MIMES)
            mime_str = string(to_mime(convert(RenderType, mime_str)))
        end
        return mime_str
    end
end

function disable_mime!(mimes::Union{String, Symbol, MIME}...)
    empty!(DISABLED_MIMES)
    isempty(mimes) && return
    mime_strings = Set{String}()
    for mime in mimes
        push!(mime_strings, to_mime_string(mime))
    end
    union!(DISABLED_MIMES, mime_strings)
    return
end

function enable_only_mime!(mimes::Union{String, Symbol, MIME}...)
    empty!(DISABLED_MIMES)
    isempty(mimes) && return
    mime_strings = Set{String}()
    for mime in mimes
        push!(mime_strings, to_mime_string(mime))
    end
    union!(DISABLED_MIMES, setdiff(SUPPORTED_MIMES, mime_strings))
    return
end

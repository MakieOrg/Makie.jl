#########################################
# Backend interface to Makie #
#########################################

"""
    tryrun(cmd::Cmd)
Try to run a command. Return `true` if `cmd` runs and is successful (exits with a code of `0`).
Return `false` otherwise.
"""
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
    # our last hope
    tryrun(`python3 -mwebbrowser $(url)`) && return
    return @warn("Can't find a way to open a browser, open $(url) manually!")
end

function Base.display(screen::Screen, scene::Scene; connect = false)
    # Nothing to do, since drawing is done in the other functions
    # TODO write to file and implement upenurl
    return screen
end

function Base.display(screen::Screen{IMAGE}, scene::Scene; connect = false, screen_config...)
    config = Makie.merge_screen_config(ScreenConfig, Dict{Symbol, Any}(screen_config))
    screen = Makie.apply_screen_config!(screen, config, scene)
    path = joinpath(mktempdir(), "display.png")
    Makie.push_screen!(scene, screen)
    cairo_draw(screen, scene)
    Cairo.write_to_png(screen.surface, path)
    if screen.visible
        openurl("file:///" * path)
    end
    return screen
end

function Makie.backend_show(screen::Screen{SVG}, io::IO, ::MIME"image/svg+xml", scene::Scene)
    mark(io)
    # fix for #4970, to avoid that the finalizer of this surface tries to write to `io` later
    # when `io` is possibly not valid anymore
    Cairo.finish(screen.surface)
    # we can't avoid that Cairo writes an svg scaffold into `io` unless
    # we refactor the whole screen setup code so the svg surface isn't initialized with the `io`
    # in the first place, so instead we just overwrite that part again with the string we build below
    reset(io)

    Makie.push_screen!(scene, screen)
    # Display the plot on a new screen writing to a string, so that we can manipulate the
    # result (the io in `screen` should directly write to the file we're saving)
    svg = sprint() do io2
        screen2 = Screen(screen, io2, SVG)
        cairo_draw(screen2, scene)
        Cairo.flush(screen2.surface)
        Cairo.finish(screen2.surface)
    end

    # for some reason, in the svg, surfaceXXX ids keep counting up,
    # even with the very same figure drawn again and again
    # so we need to reset them to counting up from 1
    # so that the same figure results in the same svg and in the same salt
    surfaceids = sort(unique(collect(m.match for m in eachmatch(r"surface\d+", svg))))

    for (i, id) in enumerate(surfaceids)
        svg = replace(svg, id => "surface$i")
    end

    # salt svg ids with the 8 hex characters of the crc32 checksum to avoid collisions
    # across svgs when embedding them on websites.
    # the hash and therefore the salt will always be the same for the same file
    # so the output is deterministic
    salt = repr(CRC32c.crc32c(svg))[(end - 7):end]

    # matches:
    # id="someid"
    # xlink:href="someid" (but not xlink:href="data:someothercontent" which is how image data is attached)
    # url(#someid)
    svg = replace(svg, r"((?:(?:id|xlink:href)=\"(?!data:)[^\"]+)|url\(#[^)]+)" => SubstitutionString("\\1-$salt"))

    print(io, svg)
    return screen
end

function Makie.backend_show(screen::Screen{PDF}, io::IO, ::MIME"application/pdf", scene::Scene)
    Makie.push_screen!(scene, screen)
    cairo_draw(screen, scene)
    Cairo.finish(screen.surface)
    return screen
end

function Makie.backend_show(screen::Screen{EPS}, io::IO, ::MIME"application/postscript", scene::Scene)
    Makie.push_screen!(scene, screen)
    cairo_draw(screen, scene)
    Cairo.finish(screen.surface)
    return screen
end

# Disabling mimes and showable

const DISABLED_MIMES = Set{String}()
const SUPPORTED_MIMES = Set(
    [
        map(x -> string(x()), Makie.WEB_MIMES)...,
        "image/svg+xml",
        "application/pdf",
        "application/postscript",
        "image/png",
    ]
)

function Makie.backend_showable(::Type{Screen}, ::MIME{SYM}) where {SYM}
    supported_mimes = Base.setdiff(SUPPORTED_MIMES, DISABLED_MIMES)
    return string(SYM) in supported_mimes
end

"""
    to_mime_string(mime::Union{String, Symbol, MIME})

Converts anything like `"png", :png, "image/png", MIME"image/png"()` to `"image/png"`.
"""
function to_mime_string(mime::Union{String, Symbol, MIME})
    if mime isa MIME
        mime_str = string(mime)
        if !(mime_str in SUPPORTED_MIMES)
            error("Mime $(mime) not supported by CairoMakie")
        end
        return mime_str
    else
        mime_str = string(mime)
        if !(mime_str in SUPPORTED_MIMES)
            mime_str = string(to_mime(convert(RenderType, mime_str)))
        end
        return mime_str
    end
end

"""
    disable_mime!(mime::Union{String, Symbol, MIME}...)

The default is automatic, which lets the display system figure out the best mime.
If set to any other valid mime, will result in `showable(any_other_mime, figurelike)` to return false and only return true for `showable(preferred_mime, figurelike)`.
Depending on the display system used, this may result in nothing getting displayed.
"""
function disable_mime!(mimes::Union{String, Symbol, MIME}...)
    empty!(DISABLED_MIMES) # always start from 0
    if isempty(mimes)
        # Reset disabled mimes when called with no arguments
        return
    end
    mime_strings = Set{String}()
    for mime in mimes
        push!(mime_strings, to_mime_string(mime))
    end
    union!(DISABLED_MIMES, mime_strings)
    return
end

function enable_only_mime!(mimes::Union{String, Symbol, MIME}...)
    empty!(DISABLED_MIMES) # always start from 0
    if isempty(mimes)
        # Reset disabled mimes when called with no arguments
        return
    end
    mime_strings = Set{String}()
    for mime in mimes
        push!(mime_strings, to_mime_string(mime))
    end
    union!(DISABLED_MIMES, setdiff(SUPPORTED_MIMES, mime_strings))
    return
end

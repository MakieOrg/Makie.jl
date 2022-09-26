
#########################################
# Backend interface to Makie #
#########################################

function Makie.backend_display(screen::Screen, scene::Scene)
    return open(x.path, "w") do io
        Makie.backend_show(screen, io, to_mime(x), scene)
    end
end

function Makie.backend_show(screen::Screen, io::IO, ::MIME"image/svg+xml", scene::Scene)

    cairo_draw(screen, scene)
    Cairo.flush(screen.surface)
    Cairo.finish(screen.surface)

    svg = String(take!(screen.io))

    # for some reason, in the svg, surfaceXXX ids keep counting up,
    # even with the very same figure drawn again and again
    # so we need to reset them to counting up from 1
    # so that the same figure results in the same svg and in the same salt
    surfaceids = sort(unique(collect(m.match for m in eachmatch(r"surface\d+", svg))))

    for (i, id) in enumerate(surfaceids)
        svg = replace(svg, id => "surface$i")
    end

    # salt svg ids with the first 8 characters of the base64 encoded
    # sha512 hash to avoid collisions across svgs when embedding them on
    # websites. the hash and therefore the salt will always be the same for the same file
    # so the output is deterministic
    salt = String(Base64.base64encode(SHA.sha512(svg)))[1:8]

    ids = sort(unique(collect(m[1] for m in eachmatch(r"id\s*=\s*\"([^\"]*)\"", svg))))

    for id in ids
        svg = replace(svg, id => "$id-$salt")
    end

    print(io, svg)
    return screen
end

function Makie.backend_show(screen::Screen, io::IO, ::MIME"application/pdf", scene::Scene)
    cairo_draw(screen, scene)
    Cairo.finish(screen.surface)
    return screen
end

function Makie.backend_show(screen::Screen, io::IO, ::MIME"application/postscript", scene::Scene)
    cairo_draw(screen, scene)
    Cairo.finish(screen.surface)
    return screen
end

function Makie.backend_show(screen::Screen, io::IO, ::MIME"image/png", scene::Scene)
    cairo_draw(screen, scene)
    Cairo.write_to_png(screen.surface, io)
    return screen
end

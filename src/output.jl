import Hiccup, Media, Images, Juno, FileIO, ModernGL, Interact
import FileIO: save

colorbuffer(screen) = error("Color buffer retrieval not implemented for $(typeof(screen))")


"""
    scene2image(scene::Scene)

Buffers the `scene` in an image buffer.
"""
function scene2image(scene::Scene)
    d = global_gl_screen()
    display(d, scene)
    colorbuffer(d)
    # for d in Base.Multimedia.displays
        # if Base.Multimedia.displayable(d, "image/png")
            # display(d, scene)
            # colorbuffer(d)
        # end
    # end
end


"""
    save(path::String, scene::Scene)

Saves an image of the `scene` at the specified `path`.
"""
function save(path::String, scene::Scene)
    img = scene2image(scene)
    if img != nothing
        save(path, img)
    else
        # TODO create a screen
        error("Scene isn't displayed on a screen")
    end
end

import Juno, Media

Media.media(Scene, Media.Plot)

Juno.@render Juno.PlotPane p::Scene begin
    try
        HTML(stringmime("image/svg+xml", p))
    catch e
        Base.show_backtrace(STDERR, Base.catch_backtrace())
        rethrow(e)
    end
end

# Base.mimewritable(::MIME"text/html", scene::VideoStream) = true
Base.mimewritable(::MIME"image/png", scene::Scene) = true


function show(io::IO, mime::MIME"application/javascript", scene::Scene)
    #TODO use WebIO
    print(io, scene2javascript(scene))
    # print(io, "<img src=\"data:image/png;base64,")
    # b64pipe = Base64EncodePipe(io)
    # show(b64pipe, MIME"image/png"(), scene2image(scene))
    # print(io, "\">")
end
function show(io::IO, mime::MIME"text/html", scene::Scene)
    print(io, "<img src=\"data:image/png;base64,")
    b64pipe = Base64EncodePipe(io)
    show(b64pipe, MIME"image/png"(), scene2image(scene))
    print(io, "\">")
end

function svg(scene::Scene, path::Union{String, IO})
    cs = CairoBackend.CairoScreen(scene, path)
    CairoBackend.draw_all(cs, scene)
end

# function svg(scene::Scene, io::IO)
#     mktempdir() do dir
#         path = joinpath(dir, "output.svg")
#         svg(scene, path)
#         write(io, open(read, path))
#     end
# end

function show(io::IO, m::MIME"image/svg+xml", scene::Scene)
    if false#AbstractPlotting.is2d(scene)
        svg(scene, io)
    else
        show(io, MIME"text/html"(), scene)
    end
end

function show(io::IO, m::MIME"image/png", scene::Scene)
    img = scene2image(scene)
    FileIO.save(FileIO.Stream(FileIO.format"PNG", io), img)
end
# function Base.show(io::IO, mime::MIME"image/png", scene::Scene)
#     s = map(scene.events.entered_window) do value
#         scene2image(scene)
#     end
#     display(s)
# end

# function Base.show(io::IO, mime::MIME"text/html", vs::VideoStream)
#     path = "file/" * finish(vs, "mp4")
#     html = """
#         <video width="100%" autoplay controls="false">
#             <source src="%path" type="video/mp4">
#             Your browser does not support the video tag. Please use a modern browser like Chrome or Firefox.
#         </video>
#     """
#     display(
#         Main.IJulia.InlineDisplay(),
#         mime,
#         html
#     )
# end


export VideoStream, recordframe!, finish, record

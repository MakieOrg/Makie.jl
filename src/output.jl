
colorbuffer(screen) = error("Color buffer retrieval not implemented for $(typeof(screen))")


"""
    scene2image(scene::Scene)

Buffers the `scene` in an image buffer.
"""
function scene2image(scene::Scene)
    scene.updated[] = true
    d = global_gl_screen()
    force_update!()
    yield()
    display(d, scene)
    colorbuffer(d)
end


"""
    save(path::String, scene::Scene)

Saves an image of the `scene` at the specified `path`.
"""
function save(path::String, scene::Scene)
    img = scene2image(scene)
    if img != nothing
        try
            FileIO.save(path, img)
        catch e
            # TODO print error?? But it's super long if its JuliaPlots/Makie.jl#138
            error("Failed to save Image. You likely need to install ImageMagick with `]add ImageMagick`")
        end
    else
        # TODO create a screen
        error("Scene isn't displayed on a screen")
    end
end


# Base.showable(::MIME"text/html", scene::VideoStream) = true
#Base.showable(::MIME"image/png", scene::Scene) = true


# Let's not lie: with only the OpenGL backend, we don't really support any svg/html mime

# function show(io::IO, mime::MIME"application/javascript", scene::Scene)
#     #TODO use WebIO
#     print(io, scene2javascript(scene))
# end

# function show(io::IO, mime::MIME"text/html", scene::Scene)
#     print(io, "<img src=\"data:image/png;base64,")
#     b64pipe = Base64EncodePipe(io)
#     img = scene2image(scene)
#     FileIO.save(FileIO.Stream(FileIO.format"PNG", b64pipe), img)
#     print(io, "\">")
# end

# function svg(scene::Scene, path::Union{String, IO})
#     cs = CairoBackend.CairoScreen(scene, path)
#     CairoBackend.draw_all(cs, scene)
# end


# function show(io::IO, m::MIME"image/svg+xml", scene::Scene)
#     if false#AbstractPlotting.is2d(scene)
#         svg(scene, io)
#     else
#         show(io, MIME"text/html"(), scene)
#     end
# end

function show(io::IO, m::MIME"image/png", scene::Scene)
    img = scene2image(scene)
    FileIO.save(FileIO.Stream(FileIO.format"PNG", io), img)
end


export VideoStream, recordframe!, finish, record

# Stepper for generating progressive plot examples
mutable struct Stepper
    scene::Scene
    folder::String
    step::Int
end

function Stepper(scene, path)
    ispath(path) || mkpath(path)
    Stepper(scene, path, 1)
end

"""
    step!(s::Stepper)
steps through a `Makie.Stepper` and outputs a file with filename `filename-step.jpg`.
This is useful for generating progressive plot examples.
"""
function step!(s::Stepper)
    Makie.save(joinpath(s.folder, basename(s.folder) * "-$(s.step).jpg"), s.scene)
    s.step += 1
    return s
end

export Stepper, step!

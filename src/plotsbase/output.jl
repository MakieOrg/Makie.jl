import Hiccup, Media, Images, Juno, FileIO, ModernGL

function scene2image(scene::Scene)
    screen = getscreen(scene)
    if screen != nothing
        render_frame(screen) # let it render
        yield()
        ModernGL.glFinish()
        return GLWindow.screenbuffer(screen)
    else
        return nothing
    end
end

function show(io::IO, ::MIME"image/png", scene::Scene)
    img = scene2image(scene)
    if img != nothing
        png = map(RGB{U8}, buff)
        FileIO.save(FileIO.Stream(FileIO.DataFormat{:PNG}, io), png)
    end
    return
end

function save(path::String, scene::Scene)
    img = scene2image(scene)
    if img != nothing
        FileIO.save(path, img)
    else
        error("Scene doesn't contain a plot!")
    end
end

Media.media(Scene, Media.Plot)

function Juno.render(e::Juno.Editor, plt::Scene)
    Juno.render(e, nothing)
end

const use_atom_plot_pane = Ref(false)
use_plot_pane(x::Bool = true) = (use_atom_plot_pane[] = x)

function Juno.render(pane::Juno.PlotPane, plt::Scene)
    if use_atom_plot_pane[]
        img = scene2image(plt)
        if img != nothing
            Juno.render(pane, HTML("<img src=\"data:image/png;base64,$(stringmime(MIME("image/png"), img))\">"))
        end
    end
end

#using Gtk
using Cairo

# struct CairoGtkPane
#     window::GtkWindow
#     canvas::GtkCanvas
# end

struct CairoScreen{S}
    scene::Scene
    surface::S
    context::CairoContext
    pane::Void#Union{CairoGtkPane, Void}
end
# # we render the scene directly, since we have no screen dependant state like in e.g. opengl
Base.insert!(screen::CairoScreen, scene::Scene, plot) = nothing

# Default to Gtk Window+Canvas as backing device
function CairoScreen(scene::Scene)
    w, h = round.(Int, scene.camera.resolution[])
    info(w, " ", h)
    surf = CairoRGBSurface(w, h)
    ctx = CairoContext(surf)
    win = GtkWindow()
    canv = GtkCanvas(w, h)
    push!(win, canv)
    CairoScreen(scene, surf, ctx, CairoGtkPane(win, canv))
end

function CairoScreen(scene::Scene, path::String; mode=:svg)
    w, h = round.(Int, scene.camera.resolution[])
    # TODO: Add other surface types (PDF, etc.)
    if mode == :svg
        surf = CairoSVGSurface(path, w, h)
    else
        error("No available Cairo surface for mode $mode")
    end
    ctx = CairoContext(surf)
    CairoScreen(scene, surf, ctx, nothing)
end


function project_position(scene, point, model)
    p4d = Makie.to_ndim(Vec4f0, Makie.to_ndim(Vec3f0, point, 0f0), 1f0)
    clip = scene.camera.projectionview[] * model * p4d
    p = (clip / clip[4])[Vec(1, 2)]
    ((((p + 1f0) / 2f0) .* (scene.camera.resolution[] - 1f0)) + 1f0)
end


function cairo_draw(screen::CairoScreen, primitive::Lines)
    scene = screen.scene
    fields = value.(getindex.(primitive.attributes, (:color, :linewidth, :linestyle)))
    ctx = screen.context
    model = primitive.attributes[:model][]
    pos = project_position(scene, first(primitive.args[1]), model)
    Cairo.move_to(ctx, pos[1], pos[2])
    broadcast_foreach(primitive.args[1], fields...) do point, color, linewidth, linestyle
        pos = project_position(scene, point, model)
        Cairo.set_line_width(ctx, Float64(linewidth))
        c = attribute_convert(color, key"color"())
        Cairo.set_source_rgba(ctx, red(c), green(c), blue(c), alpha(c))
        if linestyle != nothing
            set_dash(ctx, attribute_convert(linestyle, key"linestyle"()), 0.0)
        end
        Cairo.line_to(ctx, pos[1], pos[2])
        Cairo.move_to(ctx, pos[1], pos[2])
    end
    Cairo.stroke(ctx)
    nothing
end

function cairo_draw(screen::CairoScreen, primitive::Scatter)
    scene = screen.scene
    fields = value.(getindex.(primitive.attributes, (:color, :markersize, :strokecolor, :strokewidth, :marker)))
    ctx = screen.context
    model = primitive.attributes[:model][]
    broadcast_foreach(primitive.args[1], fields...) do point, color, markersize, strokecolor, strokewidth, marker
        # TODO: Implement marker
        # TODO: Accept :radius field or similar?

        pos = project_position(scene, point, model)
        c = attribute_convert(color, key"color"())
        Cairo.set_source_rgba(ctx, red(c), green(c), blue(c), alpha(c))
        Cairo.arc(ctx, pos[1], pos[2], 10.0, 0, 2*pi)
        Cairo.fill(ctx)

        sc = attribute_convert(strokecolor, key"color"())
        Cairo.set_source_rgba(ctx, red(sc), green(sc), blue(sc), alpha(sc))
        Cairo.set_line_width(ctx, Float64(strokewidth))
        #if linestyle != nothing
        #    set_dash(ctx, attribute_convert(linestyle, key"linestyle"()), 0.0)
        #end
        Cairo.arc(ctx, pos[1], pos[2], 10.0, 0, 2*pi)
        Cairo.stroke(ctx)
    end
    nothing
end

function cairo_draw(screen::CairoScreen, primitive::Text)
    scene = screen.scene
    ctx = screen.context
    model = primitive.attributes[:model][]
    pos = project_position(scene, Vec2f0(primitive.attributes[:position][]), model)
    color = primitive.attributes[:color][]
    textsize = primitive.attributes[:textsize][]
    Cairo.move_to(ctx, pos[1], pos[2])
    c = attribute_convert(color, key"color"())
    Cairo.set_source_rgba(ctx, red(c), green(c), blue(c), alpha(c))
    Cairo.set_font_size(ctx, textsize)
    Cairo.show_text(ctx, primitive.args[1])
    nothing
end

# TODO: heatmap!

#TODO those are from Visualize.jl and need to get ported to the above

#=
function cairo_draw(screen::CairoScreen, primitive::Text)
    set_font_face(cr, text.font)
    for (c, sprite) in zip(text.data, text.text)
        vert = Visualize.vert_particles(sprite, canvas, uniforms)
        rect = vert.rect
        pos = rect[Vec(1, 2)]
        scale = rect[Vec(3, 4)]
        pos = clip2pixel_space(Vec4f0(pos[1], pos[2], 0, 1), canvas.resolution)
        move_to(cd, pos...)
        set_source_rgba(cr, vert.color...)
        set_font_size(cr, vert.scale[1])
        show_text(cr, string(c))
    end
end

function draw_window!(scene::Scene, cr::CairoContext)
    Cairo.save(cr)
    Cairo.set_source_rgba(cr, scene.backgroundcolor[]...)    # light gray
    Cairo.rectangle(cr, 0.0, 0.0, get(window, Visualize.Resolution)...) # background
    Cairo.fill(cr)
    Cairo.restore(cr)
    Cairo.reset_clip(cr)
    for (prim, (drawable, args)) in window[Visualize.Renderlist]
        Cairo.save(cr)
        drawable(args...)
        Cairo.restore(cr)
    end
    return
end
=#

function cairo_clear(screen::CairoScreen{S} where S)
    ctx = screen.context
    w, h = Cairo.width(ctx), Cairo.height(ctx)
    Cairo.rectangle(ctx, 0, 0, w, h)
    # FIXME: Cairo.set_source_rgb(ctx, screen.scene.theme[:color]...)
    Cairo.fill(ctx)
end

function cairo_finish(screen::CairoScreen{CairoRGBSurface})
    info("draw")
    showall(screen.pane.window)
    #=@guarded=# draw(screen.pane.canvas) do canvas
        ctx = getgc(canvas)
        w, h = Cairo.width(ctx), Cairo.height(ctx)
        info(w, " ", h)
        # TODO: Maybe just use set_source(ctx, screen.surface)?
        Cairo.image(ctx, screen.surface, 0, 0, w, h)
    end
end
cairo_finish(screen::CairoScreen{S} where S) = finish(screen.surface)

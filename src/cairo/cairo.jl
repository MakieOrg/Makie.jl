module CairoBackend

import ..Makie
using ..Makie: Scene, Lines, Text, Heatmap, Scatter, @key_str, broadcast_foreach
using ..Makie: convert_attribute, @extractvalue, LineSegments, to_ndim, NativeFont
using ..Makie: @info, @get_attribute
using Reactive, Colors, GeometryTypes

#using Gtk
using Cairo


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
    @info("Cairo screen: ", w, " ", h)
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
    res = scene.camera.resolution[]
    p4d = to_ndim(Vec4f0, to_ndim(Vec3f0, point, 0f0), 1f0)
    clip = scene.camera.projectionview[] * model * p4d
    p = (clip / clip[4])[Vec(1, 2)]
    p = Vec2f0(p[1], -p[2])
    ((((p + 1f0) / 2f0) .* (res - 1f0)) + 1f0)
end
project_scale(scene::Scene, s::Number) = project_scale(scene, Vec2f0(s))
function project_scale(scene::Scene, s)
    p4d = to_ndim(Vec4f0, s, 0f0)
    p = (scene.camera.projectionview[] * p4d)[Vec(1, 2)] ./ 2f0
    p .* scene.camera.resolution[]
end

function draw_segment(scene, ctx, point::Point, model, connect, do_stroke, c, linewidth, linestyle, primitive)
    pos = project_position(scene, point, model)
    function stroke()
        Cairo.set_line_width(ctx, Float64(linewidth))
        Cairo.set_source_rgba(ctx, red(c), green(c), blue(c), alpha(c))
        if linestyle != nothing
            #set_dash(ctx, linestyle, 0.0)
        end
        Cairo.stroke(ctx)
    end
    if !all(isfinite.(pos))
        connect[] = false
    else
        if connect[]
            Cairo.line_to(ctx, pos[1], pos[2])
            isa(primitive, LineSegments) && (connect[] = false)
        end
        if do_stroke[]
            stroke(); do_stroke[] = false; connect[] = true
            Cairo.move_to(ctx, pos[1], pos[2])
        else
            do_stroke[] = true
        end
    end
end

function draw_segment(scene, ctx, segment::Tuple{<: Point, <: Point}, model, connect, do_stroke, c, linewidth, linestyle, primitive)
    A = project_position(scene, segment[1], model)
    B = project_position(scene, segment[2], model)
    function stroke()
        Cairo.set_line_width(ctx, Float64(linewidth))
        Cairo.set_source_rgba(ctx, red(c), green(c), blue(c), alpha(c))
        if linestyle != nothing
            #set_dash(ctx, linestyle, 0.0)
        end
        Cairo.stroke(ctx)
    end
    Cairo.move_to(ctx, A[1], A[2])
    Cairo.line_to(ctx, B[1], B[2])
    stroke()
end

function cairo_draw(screen::CairoScreen, primitive::Union{Lines, LineSegments})
    scene = screen.scene
    fields = @get_attribute(primitive, (color, linewidth, linestyle))
    ctx = screen.context
    model = primitive[:model][]
    positions = primitive[1][]
    N = length(positions)
    connect = Ref(true); do_stroke = Ref(true)
    broadcast_foreach(1:N, positions, fields...) do i, point, c, linewidth, linestyle
        draw_segment(scene, ctx, point, model, connect, do_stroke, c, linewidth, linestyle, primitive)
    end
    nothing
end

function cairo_draw(screen::CairoScreen, primitive::Scatter)
    scene = screen.scene
    fields = @get_attribute(primitive, (color, markersize, strokecolor, strokewidth, marker))
    ctx = screen.context
    model = primitive[:model][]
    broadcast_foreach(primitive[1][], fields...) do point, c, markersize, strokecolor, strokewidth, marker
        # TODO: Implement marker
        # TODO: Accept :radius field or similar?
        scale = project_scale(scene, markersize)
        pos = project_position(scene, point, model)
        Cairo.set_source_rgba(ctx, red(c), green(c), blue(c), alpha(c))
        Cairo.arc(ctx, pos[1], pos[2], scale[1] / 2, 0, 2*pi)
        Cairo.fill(ctx)
        sc = to_color(strokecolor)
        Cairo.set_source_rgba(ctx, red(sc), green(sc), blue(sc), alpha(sc))
        Cairo.set_line_width(ctx, Float64(strokewidth))
        #if linestyle != nothing
        #    set_dash(ctx, convert_attribute(linestyle, key"linestyle"()), 0.0)
        #end
        Cairo.arc(ctx, pos[1], pos[2], scale[1], 0, 2*pi)
        Cairo.stroke(ctx)
    end
    nothing
end



function cairo_draw(screen::CairoScreen, primitive::Makie.Combined)
    foreach(x-> cairo_draw(screen, x), primitive.plots)
end

scale_matrix(x, y) = Cairo.CairoMatrix(x, 0.0, 0.0, y, 0.0, 0.0)
function rot_scale_matrix(x, y, q)
    sx, sy, sz = 2q[4]*q[1], 2q[4]*q[2], 2q[4]*q[3]
    xx, xy, xz = 2q[1]^2, 2q[1]*q[2], 2q[1]*q[3]
    yy, yz, zz = 2q[2]^2, 2q[2]*q[3], 2q[3]^2
    m = Cairo.CairoMatrix(
        x, 1 - (xx + zz), yz + sx,
        y, yz - sx, 1 - (xx + yy)
    )
    m
end

function set_font_matrix(cr, matrix)
    ccall((:cairo_set_font_matrix, Cairo._jl_libcairo), Void, (Ptr{Void}, Ptr{Void}), cr.ptr, Ref(matrix))
end


function set_ft_font(cr, font)
    font_face = ccall(
        (:cairo_ft_font_face_create_for_ft_face, Cairo._jl_libcairo),
        Ptr{Void}, (Ptr{Void}, Cint),
        font, 0
    )
    ccall((:cairo_set_font_face, Cairo._jl_libcairo), Void, (Ptr{Void}, Ptr{Void}), cr.ptr, font_face)
end
fontname(x::String) = x
fontname(x::Symbol) = string(x)
function fontname(x::NativeFont)
    ft_rect = unsafe_load(x[1])
    unsafe_string(ft_rect.family_name)
end

import ..GLVisualize
using AbstractPlotting
function fontscale(scene, c, font, s)
    atlas = GLVisualize.get_texture_atlas()
    s = (s ./ atlas.scale[AbstractPlotting.glyph_index!(atlas, c, font)]) ./ 0.02
    project_scale(scene, s)
end

function cairo_draw(screen::CairoScreen, primitive::Text)
    scene = screen.scene
    ctx = screen.context
    @get_attribute(primitive, (textsize, color, font, align, rotation, model))
    txt = value(primitive[1])
    position = primitive.attributes[:position][]
    N = length(txt)
    broadcast_foreach(1:N, position, textsize, color, font, rotation) do i, p, ts, cc, f, r
        Cairo.save(ctx)
        pos = project_position(scene, p, model)
        Cairo.move_to(ctx, pos[1], pos[2])
        Cairo.set_source_rgba(ctx, red(cc), green(cc), blue(cc), alpha(cc))

        Cairo.select_font_face(
            ctx, fontname(f),
            Cairo.FONT_SLANT_NORMAL,
            Cairo.FONT_WEIGHT_BOLD
        )
        #set_ft_font(ctx, f)
        char = N == length(position) ? txt[i] : first(txt)
        ts = fontscale(scene, char, f, ts)
        mat = scale_matrix(ts...)
        set_font_matrix(ctx, mat)
        # set_font_size(ctx, 16)
        # TODO this only works in 2d
        rotate(ctx, 2acos(r[4]))
        if N == length(position) # if one position per glyph
            Cairo.show_text(ctx, string(txt[i]))
        else
            Cairo.show_text(ctx, txt)
        end
        Cairo.restore(ctx)
    end
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

function cairo_clear(screen::CairoScreen)
    ctx = screen.context
    w, h = Cairo.width(ctx), Cairo.height(ctx)
    Cairo.rectangle(ctx, 0, 0, w, h)
    # FIXME: Cairo.set_source_rgb(ctx, screen.scene.theme[:color]...)
    Cairo.fill(ctx)
end

function cairo_finish(screen::CairoScreen{CairoRGBSurface})
    @info("draw")
    showall(screen.pane.window)
    #=@guarded=# draw(screen.pane.canvas) do canvas
        ctx = getgc(canvas)
        w, h = Cairo.width(ctx), Cairo.height(ctx)
        info(w, " ", h)
        # TODO: Maybe just use set_source(ctx, screen.surface)?
        Cairo.image(ctx, screen.surface, 0, 0, w, h)
    end
end
cairo_finish(screen::CairoScreen) = finish(screen.surface)

end

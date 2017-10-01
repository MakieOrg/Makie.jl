const RGBAf0 = RGA{Float32}

struct Axis{T}
    title::String
    dims::NTuple{N, Tuple{String, RGBAf0}}
    area::HyperCube{N, Float32}
    ranges::NTuple{N, UnitRange{Float32}}
    grid_color::RGBAf0
end

function draw_grid_lines(sp, grid_segs, thickness, style, model, color)

    kw_args = Dict{Symbol, Any}(
        :model => model
    )
    d = Dict(
        :linestyle => style,
        :linewidth => thickness,
        :linecolor => color
    )
    Plots.extract_linestyle(d, kw_args)
    GL.lines(map(Point2f0, grid_segs.pts), kw_args)
end

function draw_ticks(
        axis, ticks, isx, lims, m, text = "",
        positions = Point2f0[], offsets=Vec2f0[]
    )
    sz = pointsize(axis[:tickfont])
    atlas = GLVisualize.get_texture_atlas()
    font = GLVisualize.defaultfont()

    flip = axis[:flip]; mirror = axis[:mirror]

    align = if isx
        mirror ? :bottom : :top
    else
        mirror ? :left : :right
    end
    axis_gap = Point2f0(isx ? 0 : sz / 2, isx ? sz / 2 : 0)
    for (cv, dv) in zip(ticks...)

        x, y = cv, lims[1]
        xy = isx ? (x, y) : (y, x)
        _pos = m * GeometryTypes.Vec4f0(xy[1], xy[2], 0, 1)
        startpos = Point2f0(_pos[1], _pos[2]) - axis_gap
        str = string(dv)
        # need to tag a new UnicodeFun version for this... also the numbers become
        # so small that it looks terrible -.-
        # _str = split(string(dv), "^")
        # if length(_str) == 2
        #     _str[2] = UnicodeFun.to_superscript(_str[2])
        # end
        # str = join(_str, "")
        position = GLVisualize.calc_position(str, startpos, sz, font, atlas)
        offset = GLVisualize.calc_offset(str, sz, font, atlas)
        alignoff = align_offset(startpos, last(position), atlas, sz, font, align)
        map!(position, position) do pos
            pos .+ alignoff
        end
        append!(positions, position)
        append!(offsets, offset)
        text *= str

    end
    text, positions, offsets
end


function draw_axes_2d(sp::Plots.Subplot{Plots.GLVisualizeBackend}, model, area)
    xticks, yticks, xspine_segs, yspine_segs, xgrid_segs, ygrid_segs, xborder_segs, yborder_segs = Plots.axis_drawing_info(sp)
    xaxis = sp[:xaxis]; yaxis = sp[:yaxis]

    xgc = Colors.color(Plots.color(xaxis[:foreground_color_grid]))
    ygc = Colors.color(Plots.color(yaxis[:foreground_color_grid]))
    axis_vis = []
    if xaxis[:grid]
        grid = draw_grid_lines(sp, xgrid_segs, xaxis[:gridlinewidth], xaxis[:gridstyle], model, RGBA(xgc, xaxis[:gridalpha]))
        push!(axis_vis, grid)
    end
    if yaxis[:grid]
        grid = draw_grid_lines(sp, ygrid_segs, yaxis[:gridlinewidth], yaxis[:gridstyle], model, RGBA(ygc, yaxis[:gridalpha]))
        push!(axis_vis, grid)
    end

    xac = Colors.color(Plots.color(xaxis[:foreground_color_axis]))
    yac = Colors.color(Plots.color(yaxis[:foreground_color_axis]))
    if alpha(xaxis[:foreground_color_axis]) > 0
        spine = draw_grid_lines(sp, xspine_segs, 1f0, :solid, model, RGBA(xac, 1.0f0))
        push!(axis_vis, spine)
    end
    if alpha(yaxis[:foreground_color_axis]) > 0
        spine = draw_grid_lines(sp, yspine_segs, 1f0, :solid, model, RGBA(yac, 1.0f0))
        push!(axis_vis, spine)
    end
    fcolor = Plots.color(xaxis[:foreground_color_axis])

    xlim = Plots.axis_limits(xaxis)
    ylim = Plots.axis_limits(yaxis)

    if !(xaxis[:ticks] in (nothing, false, :none)) && !(sp[:framestyle] == :none)
        ticklabels = map(model) do m
            mirror = xaxis[:mirror]
            t, positions, offsets = draw_ticks(xaxis, xticks, true, ylim, m)
            mirror = xaxis[:mirror]
            t, positions, offsets = draw_ticks(
                yaxis, yticks, false, xlim, m,
                t, positions, offsets
            )
        end
        kw_args = Dict{Symbol, Any}(
            :position => map(x-> x[2], ticklabels),
            :offset => map(last, ticklabels),
            :color => fcolor,
            :relative_scale => pointsize(xaxis[:tickfont]),
            :scale_primitive => false
        )
        push!(axis_vis, visualize(map(first, ticklabels), Style(:default), kw_args))
    end

    xbc = Colors.color(Plots.color(xaxis[:foreground_color_border]))
    ybc = Colors.color(Plots.color(yaxis[:foreground_color_border]))
    intensity = sp[:framestyle] == :semi ? 0.5f0 : 1.0f0
    if sp[:framestyle] in (:box, :semi)
        xborder = draw_grid_lines(sp, xborder_segs, intensity, :solid, model, RGBA(xbc, intensity))
        yborder = draw_grid_lines(sp, yborder_segs, intensity, :solid, model, RGBA(ybc, intensity))
        push!(axis_vis, xborder, yborder)
    end

    area_w = GeometryTypes.widths(area)
    if sp[:title] != ""
        tf = sp[:titlefont]; color = color(sp[:foreground_color_title])
        font = Plots.Font(tf.family, tf.pointsize, :hcenter, :top, tf.rotation, color)
        xy = Point2f0(area.w/2, area_w[2] + pointsize(tf)/2)
        kw = Dict(:model => text_model(font, xy), :scale_primitive => true)
        extract_font(font, kw)
        t = PlotText(sp[:title], font)
        push!(axis_vis, glvisualize_text(xy, t, kw))
    end
    if xaxis[:guide] != ""
        tf = xaxis[:guidefont]; color = color(xaxis[:foreground_color_guide])
        xy = Point2f0(area.w/2, - pointsize(tf)/2)
        font = Plots.Font(tf.family, tf.pointsize, :hcenter, :bottom, tf.rotation, color)
        kw = Dict(:model => text_model(font, xy), :scale_primitive => true)
        t = PlotText(xaxis[:guide], font)
        extract_font(font, kw)
        push!(axis_vis, glvisualize_text(xy, t, kw))
    end

    if yaxis[:guide] != ""
        tf = yaxis[:guidefont]; color = color(yaxis[:foreground_color_guide])
        font = Plots.Font(tf.family, tf.pointsize, :hcenter, :top, 90f0, color)
        xy = Point2f0(-pointsize(tf)/2, area.h/2)
        kw = Dict(:model => text_model(font, xy), :scale_primitive=>true)
        t = PlotText(yaxis[:guide], font)
        extract_font(font, kw)
        push!(axis_vis, glvisualize_text(xy, t, kw))
    end

    axis_vis
end

function draw_axes_3d(sp, model)
    x = Plots.axis_limits(sp[:xaxis])
    y = Plots.axis_limits(sp[:yaxis])
    z = Plots.axis_limits(sp[:zaxis])

    min = Vec3f0(x[1], y[1], z[1])
    visualize(
        GeometryTypes.AABB{Float32}(min, Vec3f0(x[2], y[2], z[2])-min),
        :grid, model=model
    )
end

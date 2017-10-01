

function extract_limits(sp, d, kw_args)
    clims = sp[:clims]
    if is_2tuple(clims)
        if isfinite(clims[1]) && isfinite(clims[2])
          kw_args[:limits] = Vec2f0(clims)
        end
    end
    nothing
end

to_vec{T <: StaticArrays.StaticVector}(::Type{T}, vec::T) = vec
to_vec{T <: StaticArrays.StaticVector}(::Type{T}, s::Number) = T(s)

to_vec{T <: StaticArrays.StaticVector{2}}(::Type{T}, vec::StaticArrays.StaticVector{3}) = T(vec[1], vec[2])
to_vec{T <: StaticArrays.StaticVector{3}}(::Type{T}, vec::StaticArrays.StaticVector{2}) = T(vec[1], vec[2], 0)

to_vec{T <: StaticArrays.StaticVector}(::Type{T}, vecs::AbstractVector) = map(x-> to_vec(T, x), vecs)


function make_gradient{C <: Colorant}(grad::Vector{C})
    grad
end
function make_gradient(grad::ColorGradient)
    RGBA{Float32}[c for c in grad.colors]
end
make_gradient(c) = make_gradient(cgrad())

function extract_any_color(d, kw_args)
    if d[:marker_z] == nothing
        c = scalar_color(d, :fill)
        extract_c(d, kw_args, :fill)
        if isa(c, Colorant)
            kw_args[:color] = c
        else
            kw_args[:color] = nothing
            kw_args[:color_map] = make_gradient(c)
            clims = d[:subplot][:clims]
            if Plots.is_2tuple(clims)
                if isfinite(clims[1]) && isfinite(clims[2])
                    kw_args[:color_norm] = Vec2f0(clims)
                end
            elseif clims == :auto
                kw_args[:color_norm] = Vec2f0(ignorenan_extrema(d[:y]))
            end
        end
    else
        kw_args[:color] = nothing
        clims = d[:subplot][:clims]
        if Plots.is_2tuple(clims)
            if isfinite(clims[1]) && isfinite(clims[2])
                kw_args[:color_norm] = Vec2f0(clims)
            end
        elseif clims == :auto
            kw_args[:color_norm] = Vec2f0(ignorenan_extrema(d[:y]))
        else
            error("Unsupported limits: $clims")
        end
        kw_args[:intensity] = convert(Vector{Float32}, d[:marker_z])
        kw_args[:color_map] = color_map(d, :marker)
    end
end

function extract_stroke(d, kw_args)
    extract_c(d, kw_args, :line)
    if haskey(d, :linewidth)
        kw_args[:thickness] = d[:linewidth] * 3
    end
end

function extract_color(d, sym)
    d[Symbol("$(sym)color")]
end

color(c::PlotUtils.ColorGradient) = c.colors
color{T<:Colorant}(c::Vector{T}) = c
color(c::RGBA{Float32}) = c
color(c::Colorant) = RGBA{Float32}(c)

function color(tuple::Tuple)
    color(tuple...)
end

# convert to RGBA
function color(c, a)
    c = convertColor(c, a)
    RGBA{Float32}(c)
end
function scalar_color(d, sym)
    color(extract_color(d, sym))
end

function color_map(d, sym)
    colors = extract_color(d, sym)
    _color_map(colors)
end
function _color_map(colors::PlotUtils.ColorGradient)
    colors.colors
end
function _color_map(c)
    Plots.default_gradient()
end



function hover(to_hover::Vector, to_display, window)
    hover(to_hover[], to_display, window)
end

function get_cam(x)
    if isa(x, GLAbstraction.Context)
        return get_cam(x.children)
    elseif isa(x, Vector)
        return get_cam(first(x))
    elseif isa(x, GLAbstraction.RenderObject)
        return x[:preferred_camera]
    end
end


function hover(to_hover, to_display, window)
    if isa(to_hover, GLAbstraction.Context)
        return hover(to_hover.children, to_display, window)
    end
    area = map(window.inputs[:mouseposition]) do mp
        SimpleRectangle{Int}(round(Int, mp+10)..., 100, 70)
    end
    mh = GLWindow.mouse2id(window)
    popup = GLWindow.Screen(
        window,
        hidden = map(mh-> !(mh.id == to_hover.id), mh),
        area = area,
        stroke = (2f0, RGBA(0f0, 0f0, 0f0, 0.8f0))
    )
    cam = get!(popup.cameras, :perspective) do
        GLAbstraction.PerspectiveCamera(
            popup.inputs, Vec3f0(3), Vec3f0(0),
            keep = Signal(false),
            theta = Signal(Vec3f0(0)), trans = Signal(Vec3f0(0))
        )
    end

    map(enumerate(to_display)) do id
        i,d = id
        robj = visualize(d)
        viewit = Reactive.droprepeats(map(mh->mh.id == to_hover.id && mh.index == i, mh))
        camtype = get_cam(robj)
        Reactive.preserve(map(viewit) do vi
            if vi
                empty!(popup)
                if camtype == :perspective
                    cam.projectiontype.value = GLVisualize.PERSPECTIVE
                else
                    cam.projectiontype.value = GLVisualize.ORTHOGRAPHIC
                end
                GLVisualize._view(robj, popup, camera = cam)
                bb = GLAbstraction.boundingbox(robj).value
                mini = minimum(bb)
                w = GeometryTypes.widths(bb)
                wborder = w * 0.08f0 #8 percent border
                bb = GeometryTypes.AABB{Float32}(mini - wborder, w + 2 * wborder)
                GLAbstraction.center!(cam, bb)
            end
        end)
    end
    nothing
end

function extract_extrema(d, kw_args)
    xmin, xmax = ignorenan_extrema(d[:x]); ymin, ymax = ignorenan_extrema(d[:y])
    kw_args[:primitive] = GeometryTypes.SimpleRectangle{Float32}(xmin, ymin, xmax-xmin, ymax-ymin)
    nothing
end

function extract_font(font, kw_args)
    kw_args[:family] = font.family
    kw_args[:relative_scale] = pointsize(font)
    kw_args[:color] = color(font.color)
end

function extract_colornorm(d, kw_args)
    clims = d[:subplot][:clims]
    if Plots.is_2tuple(clims)
        if isfinite(clims[1]) && isfinite(clims[2])
            kw_args[:color_norm] = Vec2f0(clims)
        end
    elseif clims == :auto
        z = if haskey(d, :marker_z) && d[:marker_z] != nothing
            d[:marker_z]
        elseif haskey(d, :line_z) && d[:line_z] != nothing
            d[:line_z]
        elseif isa(d[:z], Plots.Surface)
            d[:z].surf
        else
            d[:y]
        end
        kw_args[:color_norm] = Vec2f0(ignorenan_extrema(z))
        kw_args[:intensity] = map(Float32, collect(z))
    end
end

function extract_gradient(d, kw_args, sym)
    key = Symbol("$(sym)color")
    haskey(d, key) || return
    c = make_gradient(d[key])
    kw_args[:color] = nothing
    extract_colornorm(d, kw_args)
    kw_args[:color_map] = c
    return
end

function extract_c(d, kw_args, sym)
    key = Symbol("$(sym)color")
    haskey(d, key) || return
    c = color(d[key])
    kw_args[:color] = nothing
    kw_args[:color_map] = nothing
    kw_args[:color_norm] = nothing
    if (
            isa(c, AbstractVector) &&
            ((haskey(d, :marker_z) && d[:marker_z] != nothing) ||
            (haskey(d, :line_z) && d[:line_z] != nothing))
        )
        extract_colornorm(d, kw_args)
        kw_args[:color_map] = c
    else
        kw_args[:color] = c
    end
    return
end

function extract_stroke(d, kw_args, sym)
    key = Symbol("$(sym)strokecolor")
    haskey(d, key) || return
    c = color(d[key])
    if c != nothing
        if !isa(c, Colorant)
            error("Stroke Color not supported: $c")
        end
        kw_args[:stroke_color] = c
        kw_args[:stroke_width] = Float32(d[Symbol("$(sym)strokewidth")]) * 2
    end
    return
end


function bar(d, kw_args)
    x, y = d[:x], d[:y]
    nx, ny = length(x), length(y)
    axis = d[:subplot][isvertical(d) ? :xaxis : :yaxis]
    cv = [discrete_value!(axis, xi)[1] for xi=x]
    x = if nx == ny
        cv
    elseif nx == ny + 1
        0.5diff(cv) + cv[1:end-1]
    else
        error("bar recipe: x must be same length as y (centers), or one more than y (edges).\n\t\tlength(x)=$(length(x)), length(y)=$(length(y))")
    end
    if haskey(kw_args, :stroke_width) # stroke is inside for bars
        #kw_args[:stroke_width] = -kw_args[:stroke_width]
    end
    # compute half-width of bars
    bw = nothing
    hw = if bw == nothing
        ignorenan_mean(diff(x))
    else
        Float64[_cycle(bw,i)*0.5 for i=1:length(x)]
    end

    # make fillto a vector... default fills to 0
    fillto = d[:fillrange]
    if fillto == nothing
        fillto = 0
    end
    # create the bar shapes by adding x/y segments
    positions, scales = Array{Point2f0}(ny), Array{Vec2f0}(ny)
    m = Reactive.value(kw_args[:model])
    sx, sy = m[1,1], m[2,2]
    for i=1:ny
        center = x[i]
        hwi = abs(_cycle(hw,i)); yi = y[i]; fi = _cycle(fillto,i)
        if Plots.isvertical(d)
            sz = (hwi*sx, yi*sy)
        else
            sz = (yi*sx, hwi*2*sy)
        end
        positions[i] = (center-hwi*0.5, fi)
        scales[i] = sz
    end

    kw_args[:scale] = scales
    kw_args[:offset] = Vec2f0(0)
    visualize((GLVisualize.RECTANGLE, positions), Style(:default), kw_args)
    #[]
end

const _box_halfwidth = 0.4

notch_width(q2, q4, N) = 1.58 * (q4-q2)/sqrt(N)

function boxplot(d, kw_args)
    kwbox = copy(kw_args)
    range = 1.5; notch = false
    x, y = d[:x], d[:y]
    glabels = sort(collect(unique(x)))
    warning = false
    outliers_x, outliers_y = zeros(0), zeros(0)

    box_pos = Point2f0[]
    box_scale = Vec2f0[]
    outliers = Point2f0[]
    t_segments = Point2f0[]
    m = Reactive.value(kw_args[:model])
    sx, sy = m[1,1], m[2,2]
    for (i,glabel) in enumerate(glabels)
        # filter y
        values = y[filter(i -> _cycle(x,i) == glabel, 1:length(y))]
        # compute quantiles
        q1,q2,q3,q4,q5 = quantile(values, linspace(0,1,5))
        # notch
        n = Plots.notch_width(q2, q4, length(values))
        # warn on inverted notches?
        if notch && !warning && ( (q2>(q3-n)) || (q4<(q3+n)) )
            warn("Boxplot's notch went outside hinges. Set notch to false.")
            warning = true # Show the warning only one time
        end

        # make the shape
        center = Plots.discrete_value!(d[:subplot][:xaxis], glabel)[1]
        hw = d[:bar_width] == nothing ? Plots._box_halfwidth*2 : _cycle(d[:bar_width], i)
        l, m, r = center - hw/2, center, center + hw/2

        # internal nodes for notches
        L, R = center - 0.5 * hw, center + 0.5 * hw
        # outliers
        if Float64(range) != 0.0  # if the range is 0.0, the whiskers will extend to the data
            limit = range*(q4-q2)
            inside = Float64[]
            for value in values
                if (value < (q2 - limit)) || (value > (q4 + limit))
                    push!(outliers, (center, value))
                else
                    push!(inside, value)
                end
            end
            # change q1 and q5 to show outliers
            # using maximum and minimum values inside the limits
            q1, q5 = ignorenan_extrema(inside)
        end
        # Box
        if notch
            push!(t_segments, (m, q1), (l, q1), (r, q1), (m, q1), (m, q2))# lower T
            push!(box_pos, (l, q2));push!(box_scale, (hw*sx, n*sy)) # lower box
            push!(box_pos, (l, q4));push!(box_scale, (hw*sx, n*sy)) # upper box
            push!(t_segments, (m, q5), (l, q5), (r, q5), (m, q5), (m, q4))# upper T

        else
            push!(t_segments, (m, q2), (m, q1), (l, q1), (r, q1))# lower T
            push!(box_pos, (l, q2)); push!(box_scale, (hw*sx, (q3-q2)*sy)) # lower box
            push!(box_pos, (l, q4)); push!(box_scale, (hw*sx, (q3-q4)*sy)) # upper box
            push!(t_segments, (m, q4), (m, q5), (r, q5), (l, q5))# upper T
        end
    end
    kwbox = Dict{Symbol, Any}(
        :scale => box_scale,
        :model => kw_args[:model],
        :offset => Vec2f0(0),
    )
    extract_marker(d, kw_args)
    outlier_kw = Dict(
        :model => kw_args[:model],
        :color =>  scalar_color(d, :fill),
        :stroke_width => Float32(d[:markerstrokewidth]),
        :stroke_color => scalar_color(d, :markerstroke),
    )
    lines_kw = Dict(
        :model => kw_args[:model],
        :stroke_width =>  d[:linewidth],
        :stroke_color =>  scalar_color(d, :fill),
    )
    vis1 = GLVisualize.visualize((GLVisualize.RECTANGLE, box_pos), Style(:default), kwbox)
    vis2 = GLVisualize.visualize((GLVisualize.CIRCLE, outliers), Style(:default), outlier_kw)
    vis3 = GLVisualize.visualize(t_segments, Style(:linesegment), lines_kw)
    [vis1, vis2, vis3]
end


# ---------------------------------------------------------------------------
function viewport(bb, rect)
    l, b, bw, bh = bb
    rw, rh = rect.w, rect.h
    GLVisualize.SimpleRectangle(
        round(Int, rw * l),
        round(Int, rh * b),
        round(Int, rw * bw),
        round(Int, rh * bh)
    )
end

function to_modelmatrix(rect, subrect, rel_plotarea, sp)
    xmin, xmax = Plots.axis_limits(sp[:xaxis])
    ymin, ymax = Plots.axis_limits(sp[:yaxis])
    mini, maxi = Vec3f0(xmin, ymin, 0), Vec3f0(xmax, ymax, 1)
    if Plots.is3d(sp)
        zmin, zmax = Plots.axis_limits(sp[:zaxis])
        mini, maxi = Vec3f0(xmin, ymin, zmin), Vec3f0(xmax, ymax, zmax)
        s = Vec3f0(1) ./ (maxi-mini)
        return GLAbstraction.scalematrix(s)*GLAbstraction.translationmatrix(-mini)
    end
    l, b, bw, bh = rel_plotarea
    w, h = rect.w*bw, rect.h*bh
    x, y = rect.w*l - subrect.x, rect.h*b - subrect.y
    t = -mini
    s = Vec3f0(w, h, 1) ./ (maxi-mini)
    GLAbstraction.translationmatrix(Vec3f0(x,y,0))*GLAbstraction.scalematrix(s)*GLAbstraction.translationmatrix(t)
end

# ----------------------------------------------------------------


function scale_for_annotations!(series::Series, scaletype::Symbol = :pixels)
    anns = series[:series_annotations]
    if anns != nothing && !isnull(anns.baseshape)
        # we use baseshape to overwrite the markershape attribute
        # with a list of custom shapes for each
        msw, msh = anns.scalefactor
        offsets = Array{Vec2f0}(length(anns.strs))
        series[:markersize] = map(1:length(anns.strs)) do i
            str = _cycle(anns.strs, i)
            # get the width and height of the string (in mm)
            sw, sh = text_size(str, anns.font.pointsize)

            # how much to scale the base shape?
            # note: it's a rough assumption that the shape fills the unit box [-1,-1,1,1],
            # so we scale the length-2 shape by 1/2 the total length
            xscale = 0.5to_pixels(sw) * 1.8
            yscale = 0.5to_pixels(sh) * 1.8

            # we save the size of the larger direction to the markersize list,
            # and then re-scale a copy of baseshape to match the w/h ratio
            s = Vec2f0(xscale, yscale)
            offsets[i] = -s
            s
        end
        series[:offset] = offsets
    end
    return
end




function _display(plt::Plot{GLVisualizeBackend}, visible = true)
    screen = create_window(plt, visible)
    sw, sh = plt[:size]
    sw, sh = sw*px, sh*px

    for sp in plt.subplots
        _3d = Plots.is3d(sp)
        # camera = :perspective
        # initialize the sub-screen for this subplot
        rel_bbox = Plots.bbox_to_pcts(bbox(sp), sw, sh)
        sub_area = map(screen.area) do rect
            Plots.viewport(rel_bbox, rect)
        end
        c = plt[:background_color_outside]
        sp_screen = GLVisualize.Screen(
            screen, color = c,
            area = sub_area
        )
        sp.o = sp_screen
        cam = get!(sp_screen.cameras, :perspective) do
            inside = sp_screen.inputs[:mouseinside]
            theta = _3d ? nothing : Signal(Vec3f0(0)) # surpress rotation for 2D (nothing will get usual rotation controle)
            GLAbstraction.PerspectiveCamera(
                sp_screen.inputs, Vec3f0(3), Vec3f0(0),
                keep = inside, theta = theta
            )
        end

        rel_plotarea = Plots.bbox_to_pcts(plotarea(sp), sw, sh)
        model_m = map(Plots.to_modelmatrix,
            screen.area, sub_area,
            Signal(rel_plotarea), Signal(sp)
        )

        # loop over the series and add them to the subplot
        if !_3d
            axis = draw_axes_2d(sp, model_m, Reactive.value(sub_area))
            GLVisualize._view(axis, sp_screen, camera=:perspective)
            cam.projectiontype.value = GLVisualize.ORTHOGRAPHIC
            Reactive.run_till_now() # make sure Reactive.push! arrives
            GLAbstraction.center!(cam,
                GeometryTypes.AABB(
                    Vec3f0(-20), Vec3f0((GeometryTypes.widths(sp_screen)+40f0)..., 1)
                )
            )
        else
            axis = draw_axes_3d(sp, model_m)
            GLVisualize._view(axis, sp_screen, camera=:perspective)
            push!(cam.projectiontype, GLVisualize.PERSPECTIVE)
        end
        for series in Plots.series_list(sp)

            d = series.d
            st = d[:seriestype]; kw_args = KW() # exctract kw

            kw_args[:model] = model_m # add transformation
            if !_3d # 3D is treated differently, since we need boundingboxes for camera
                kw_args[:boundingbox] = nothing # don't calculate bb, we dont need it
            end
            scale_for_annotations!(series)
            if st in (:surface, :wireframe)
                x, y, z = extract_surface(d)
                extract_gradient(d, kw_args, :fill)
                z = Plots.transpose_z(d, z, false)
                if isa(x, AbstractMatrix) && isa(y, AbstractMatrix)
                    x, y = Plots.transpose_z(d, x, false), Plots.transpose_z(d, y, false)
                end
                if st == :wireframe
                    kw_args[:wireframe] = true
                    kw_args[:stroke_color] = d[:linecolor]
                    kw_args[:stroke_width] = Float32(d[:linewidth]/100f0)
                end
                vis = GL.surface(x, y, z, kw_args)
            elseif (st in (:path, :path3d)) && d[:linewidth] > 0
                kw = copy(kw_args)
                points = Plots.extract_points(d)
                extract_linestyle(d, kw)
                vis = GL.lines(points, kw)
                if d[:markershape] != :none
                    kw = copy(kw_args)
                    extract_stroke(d, kw)
                    extract_marker(d, kw)
                    vis2 = GL.scatter(copy(points), kw)
                    vis = [vis; vis2]
                end
                if d[:fillrange] != nothing
                    kw = copy(kw_args)
                    fr = d[:fillrange]
                    ps = if all(x-> x >= 0, diff(d[:x])) # if is monotonic
                        vcat(points, Point2f0[(points[i][1], _cycle(fr, i)) for i=length(points):-1:1])
                    else
                        points
                    end
                    extract_c(d, kw, :fill)
                    vis = [GL.poly(ps, kw), vis]
                end
            elseif st in (:scatter, :scatter3d) #|| d[:markershape] != :none
                extract_marker(d, kw_args)
                points = extract_points(d)
                vis = GL.scatter(points, kw_args)
            elseif st == :shape
                extract_c(d, kw_args, :fill)
                vis = GL.shape(d, kw_args)
            elseif st == :contour
                x,y,z = extract_surface(d)
                z = transpose_z(d, z, false)
                extract_extrema(d, kw_args)
                extract_gradient(d, kw_args, :fill)
                kw_args[:fillrange] = d[:fillrange]
                kw_args[:levels] = d[:levels]

                vis = GL.contour(x,y,z, kw_args)
            elseif st == :heatmap
                x,y,z = extract_surface(d)
                extract_gradient(d, kw_args, :fill)
                extract_extrema(d, kw_args)
                extract_limits(sp, d, kw_args)
                vis = GL.heatmap(x,y,z, kw_args)
            elseif st == :bar
                extract_c(d, kw_args, :fill)
                extract_stroke(d, kw_args, :marker)
                vis = bar(d, kw_args)
            elseif st == :image
                extract_extrema(d, kw_args)
                vis = GL.image(d[:z].surf, kw_args)
            elseif st == :boxplot
                 extract_c(d, kw_args, :fill)
                 vis = boxplot(d, kw_args)
             elseif st == :volume
                  volume = d[:y]
                  _d = copy(d)
                  _d[:y] = 0:1
                  _d[:x] = 0:1
                  kw_args = KW()
                  extract_gradient(_d, kw_args, :fill)
                  vis = visualize(volume.v, Style(:default), kw_args)
             else
                error("failed to display plot type $st")
            end

            isa(vis, Array) && isempty(vis) && continue # nothing to see here

            GLVisualize._view(vis, sp_screen, camera=:perspective)
            if haskey(d, :hover) && !(d[:hover] in (false, :none, nothing))
                hover(vis, d[:hover], sp_screen)
            end
            if isdefined(:GLPlot) && isdefined(Main.GLPlot, :(register_plot!))
                del_signal = Main.GLPlot.register_plot!(vis, sp_screen, create_gizmo=false)
                append!(_glplot_deletes, del_signal)
            end
            anns = series[:series_annotations]
            for (x, y, str, font) in EachAnn(anns, d[:x], d[:y])
                txt_args = Dict{Symbol, Any}(:model => eye(GLAbstraction.Mat4f0))
                x, y = Reactive.value(model_m) * GeometryTypes.Vec{4, Float32}(x, y, 0, 1)
                extract_font(font, txt_args)
                t = glvisualize_text(Point2f0(x, y), PlotText(str, font), txt_args)
                GLVisualize._view(t, sp_screen, camera = :perspective)
            end

        end
        generate_legend(sp, sp_screen, model_m)
        if _3d
            GLAbstraction.center!(sp_screen)
        end
        GLAbstraction.post_empty()
        yield()
    end
end







function shape(d, kw_args)
    points = Plots.extract_points(d)
    result = []
    for rng in iter_segments(d[:x], d[:y])
        ps = points[rng]
        meshes = poly(ps, kw_args)
        append!(result, meshes)
    end
    result
end





"""
Ugh, so much special casing (╯°□°）╯︵ ┻━┻
"""
function label_scatter(d, w, ho)
    kw = KW()
    extract_stroke(d, kw)
    extract_marker(d, kw)
    kw[:scale] = Vec2f0(w/2)
    kw[:offset] = Vec2f0(-w/4)
    if haskey(kw, :intensity)
        cmap = kw[:color_map]
        norm = kw[:color_norm]
        kw[:color] = GLVisualize.color_lookup(cmap, kw[:intensity][1], norm)
        delete!(kw, :intensity)
        delete!(kw, :color_map)
        delete!(kw, :color_norm)
    else
        color = get(kw, :color, nothing)
        kw[:color] = isa(color, Array) ? first(color) : color
    end
    strcolor = get(kw, :stroke_color, RGBA{Float32}(0,0,0,0))
    kw[:stroke_color] = isa(strcolor, Array) ? first(strcolor) : strcolor
    p = get(kw, :primitive, GeometryTypes.Circle)
    if isa(p, GLNormalMesh)
        bb = GeometryTypes.AABB{Float32}(GeometryTypes.vertices(p))
        bbw = GeometryTypes.widths(bb)
        if isapprox(bbw[3], 0)
            bbw = Vec3f0(bbw[1], bbw[2], 1)
        end
        mini = minimum(bb)
        m = GLAbstraction.translationmatrix(-mini)
        m *= GLAbstraction.scalematrix(1 ./ bbw)
        kw[:primitive] = m * p
        kw[:scale] = Vec3f0(w/2)
        delete!(kw, :offset)
    end
    if isa(p, Array)
        kw[:primitive] = GeometryTypes.Circle
    end
    GL.scatter(Point2f0[(w/2, ho)], kw)
end


function make_label(sp, series, i)
    GL = Plots
    w, gap, ho = 20f0, 5f0, 5
    result = []
    d = series.d
    st = d[:seriestype]
    kw_args = KW()
    if (st in (:path, :path3d)) && d[:linewidth] > 0
        points = Point2f0[(0, ho), (w, ho)]
        kw = KW()
        extract_linestyle(d, kw)
        append!(result, GL.lines(points, kw))
        if d[:markershape] != :none
            push!(result, label_scatter(d, w, ho))
        end
    elseif st in (:scatter, :scatter3d) #|| d[:markershape] != :none
        push!(result, label_scatter(d, w, ho))
    else
        extract_c(d, kw_args, :fill)
        if isa(kw_args[:color], AbstractVector)
            kw_args[:color] = first(kw_args[:color])
        end
        push!(result, visualize(
            GeometryTypes.SimpleRectangle(-w/2, ho-w/4, w/2, w/2),
            Style(:default), kw_args
        ))
    end
    labeltext = if isa(series[:label], Array)
        i += 1
        series[:label][i]
    else
        series[:label]
    end
    color = sp[:foreground_color_legend]
    ft = sp[:legendfont]
    font = Plots.Font(ft.family, ft.pointsize, :left, :bottom, 0.0, color)
    xy = Point2f0(w+gap, 0.0)
    kw = Dict(:model => text_model(font, xy), :scale_primitive=>false)
    extract_font(font, kw)
    t = PlotText(labeltext, font)
    push!(result, glvisualize_text(xy, t, kw))
    GLAbstraction.Context(result...), i
end


function generate_legend(sp, screen, model_m)
    legend = GLAbstraction.Context[]
    if sp[:legend] != :none
        i = 0
        for series in series_list(sp)
            should_add_to_legend(series) || continue
            result, i = make_label(sp, series, i)
            push!(legend, result)
        end
        if isempty(legend)
            return
        end
        list = visualize(legend, gap=Vec3f0(0,5,0))
        bb = GLAbstraction._boundingbox(list)
        wx,wy,_ = GeometryTypes.widths(bb)
        xmin, _ = Plots.axis_limits(sp[:xaxis])
        _, ymax = Plots.axis_limits(sp[:yaxis])
        area = map(model_m) do m
            p = m * GeometryTypes.Vec4f0(xmin, ymax, 0, 1)
            h = round(Int, wy)+20
            w = round(Int, wx)+20
            x,y = round(Int, p[1])+30, round(Int, p[2]-h)-30
            GeometryTypes.SimpleRectangle(x, y, w, h)
        end
        sscren = GLWindow.Screen(
            screen, area = area,
            color = sp[:background_color_legend],
            stroke = (2f0, RGBA(0.3, 0.3, 0.3, 0.9))
        )
        GLAbstraction.translate!(list, Vec3f0(10,10,0))
        GLVisualize._view(list, sscren, camera=:fixed_pixel)
    end
    return
end

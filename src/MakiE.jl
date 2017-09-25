module MakiE

#=
TODO
    * move all gl_ methods to GLPlot
    * integrate GLPlot UI
    * clean up corner cases
    * find a cleaner way for extracting properties
    * polar plots
    * labes and axis
    * fix units in all visuals (e.g dotted lines, marker scale, surfaces)
=#

const _glvisualize_attr = merge_with_base_supported([
    :annotations,
    :background_color_legend, :background_color_inside, :background_color_outside,
    :foreground_color_grid, :foreground_color_legend, :foreground_color_title,
    :foreground_color_axis, :foreground_color_border, :foreground_color_guide, :foreground_color_text,
    :label,
    :linecolor, :linestyle, :linewidth, :linealpha,
    :markershape, :markercolor, :markersize, :markeralpha,
    :markerstrokewidth, :markerstrokecolor, :markerstrokealpha,
    :fillrange, :fillcolor, :fillalpha,
    :bins, :bar_width, :bar_edges, :bar_position,
    :title, :title_location, :titlefont,
    :window_title,
    :guide, :lims, :ticks, :scale, :flip, :rotation,
    :tickfont, :guidefont, :legendfont,
    :grid, :gridalpha, :gridstyle, :gridlinewidth,
    :legend, :colorbar,
    :marker_z,
    :line_z,
    :levels,
    :ribbon, :quiver, :arrow,
    :orientation,
    :overwrite_figure,
    #:polar,
    :normalize, :weights,
    :contours, :aspect_ratio,
    :match_dimensions,
    :clims,
    :inset_subplots,
    :dpi,
    :hover,
    :framestyle,
])
const _glvisualize_seriestype = [
    :path, :shape,
    :scatter, :hexbin,
    :bar, :boxplot,
    :heatmap, :image, :volume,
    :contour, :contour3d, :path3d, :scatter3d, :surface, :wireframe
]
const _glvisualize_style = [:auto, :solid, :dash, :dot, :dashdot]
const _glvisualize_marker = _allMarkers
const _glvisualize_scale = [:identity, :ln, :log2, :log10]



# --------------------------------------------------------------------------------------

function _initialize_backend(::GLVisualizeBackend; kw...)
    @eval begin
        import GLVisualize, GeometryTypes, Reactive, GLAbstraction, GLWindow, Contour
        import GeometryTypes: Point2f0, Point3f0, Vec2f0, Vec3f0, GLNormalMesh, SimpleRectangle, Point, Vec
        import FileIO, Images
        export GLVisualize
        import Reactive: Signal
        import GLAbstraction: Style
        import GLVisualize: visualize
        import Plots.GL
        import UnicodeFun
        Plots.slice_arg{C<:Colorant}(img::Matrix{C}, idx::Int) = img
        is_marker_supported(::GLVisualizeBackend, shape::GLVisualize.AllPrimitives) = true
        is_marker_supported{C<:Colorant}(::GLVisualizeBackend, shape::Union{Vector{Matrix{C}}, Matrix{C}}) = true
        is_marker_supported(::GLVisualizeBackend, shape::Shape) = true
        const GL = Plots
    end
end

function add_backend_string(b::GLVisualizeBackend)
    """
    if !Plots.is_installed("GLVisualize")
        Pkg.add("GLVisualize")
    end
    """
end

# ---------------------------------------------------------------------------

# initialize the figure/window
# function _create_backend_figure(plt::Plot{GLVisualizeBackend})
#     # init a screen
#
#     GLPlot.init()
# end
const _glplot_deletes = []


function get_plot_screen(list::Vector, name, result = [])
    for elem in list
        get_plot_screen(elem, name, result)
    end
    return result
end
function get_plot_screen(screen, name, result = [])
    if screen.name == name
        push!(result, screen)
        return result
    end
    get_plot_screen(screen.children, name, result)
end

function create_window(plt::Plot{GLVisualizeBackend}, visible)
    name = Symbol("__Plots.jl")
    # make sure we have any screen open
    if isempty(GLVisualize.get_screens())
        # create a fresh, new screen
        parent_screen = GLVisualize.glscreen(
            "Plots",
            resolution = plt[:size],
            visible = visible
        )
        @async GLWindow.renderloop(parent_screen)
        GLVisualize.add_screen(parent_screen)
    end
    # now lets get ourselves a permanent Plotting screen
    plot_screens = get_plot_screen(GLVisualize.current_screen(), name)
    screen = if isempty(plot_screens) # no screen with `name`
        parent = GLVisualize.current_screen()
        screen = GLWindow.Screen(
            parent, area = map(GLWindow.zeroposition, parent.area),
            name = name
        )
        screen
    elseif length(plot_screens) == 1
        plot_screens[1]
    else
        # okay this is silly! Lets see if we can. There is an ID we could use
        # will not be fine for more than 255 screens though -.-.
        error("multiple Plot screens. Please don't use any screen with the name $name")
    end
    # Since we own this window, we can do deep cleansing
    empty!(screen)
    plt.o = screen
    GLWindow.set_visibility!(screen, visible)
    resize!(screen, plt[:size]...)
    screen
end
# ---------------------------------------------------------------------------

const _gl_marker_map = KW(
    :rect => '■',
    :star5 => '★',
    :diamond => '◆',
    :hexagon => '⬢',
    :cross => '✚',
    :xcross => '❌',
    :utriangle => '▲',
    :dtriangle => '▼',
    :ltriangle => '◀',
    :rtriangle => '▶',
    :pentagon => '⬟',
    :octagon => '⯄',
    :star4 => '✦',
    :star6 => '🟋',
    :star8 => '✷',
    :vline => '┃',
    :hline => '━',
    :+ => '+',
    :x => 'x',
    :circle => '●'
)

function gl_marker(shape)
    shape
end
function gl_marker(shape::Shape)
    points = Point2f0[GeometryTypes.Vec{2, Float32}(p) for p in zip(shape.x, shape.y)]
    bb = GeometryTypes.AABB(points)
    mini, maxi = minimum(bb), maximum(bb)
    w3 = maxi-mini
    origin, width = Point2f0(mini[1], mini[2]), Point2f0(w3[1], w3[2])
    map!(p -> ((p - origin) ./ width) - 0.5f0, points, points) # normalize and center
    GeometryTypes.GLNormalMesh(points)
end
# create a marker/shape type
function gl_marker(shape::Vector{Symbol})
    String(map(shape) do sym
        get(_gl_marker_map, sym, '●')
    end)
end

function gl_marker(shape::Symbol)
    if shape == :rect
        GeometryTypes.HyperRectangle(Vec2f0(0), Vec2f0(1))
    elseif shape == :circle || shape == :none
        GeometryTypes.HyperSphere(Point2f0(0), 1f0)
    elseif haskey(_gl_marker_map, shape)
        _gl_marker_map[shape]
    elseif haskey(_shapes, shape)
        gl_marker(_shapes[shape])
    else
        error("Shape $shape not supported by GLVisualize")
    end
end

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

function extract_marker(d, kw_args)
    dim = Plots.is3d(d) ? 3 : 2
    scaling = dim == 3 ? 0.003 : 2
    if haskey(d, :markershape)
        shape = d[:markershape]
        shape = gl_marker(shape)
        if shape != :none
            kw_args[:primitive] = shape
        end
    end
    dim = isa(kw_args[:primitive], GLVisualize.Sprites) ? 2 : 3
    if haskey(d, :markersize)
        msize = d[:markersize]
        kw_args[:scale] = to_vec(GeometryTypes.Vec{dim, Float32}, msize .* scaling)
    end
    if haskey(d, :offset)
        kw_args[:offset] = d[:offset]
    end
    # get the color
    key = :markercolor
    haskey(d, key) || return
    c = gl_color(d[key])
    if isa(c, AbstractVector) && d[:marker_z] != nothing
        extract_colornorm(d, kw_args)
        kw_args[:color] = nothing
        kw_args[:color_map] = c
        kw_args[:intensity] = convert(Vector{Float32}, d[:marker_z])
    else
        kw_args[:color] = c
    end
    key = :markerstrokecolor
    haskey(d, key) || return
    c = gl_color(d[key])
    if c != nothing
        if !(isa(c, Colorant) || (isa(c, Vector) && eltype(c) <: Colorant))
            error("Stroke Color not supported: $c")
        end
        kw_args[:stroke_color] = c
        kw_args[:stroke_width] = Float32(d[:markerstrokewidth])
    end
end

function _extract_surface(d::Plots.Surface)
    d.surf
end
function _extract_surface(d::AbstractArray)
    d
end

# TODO when to transpose??
function extract_surface(d)
    map(_extract_surface, (d[:x], d[:y], d[:z]))
end
function topoints{P}(::Type{P}, array)
    [P(x) for x in zip(array...)]
end
function extract_points(d)
    dim = is3d(d) ? 3 : 2
    array = (d[:x], d[:y], d[:z])[1:dim]
    topoints(Point{dim, Float32}, array)
end
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
        kw_args[:color_map] = gl_color_map(d, :marker)
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

gl_color(c::PlotUtils.ColorGradient) = c.colors
gl_color{T<:Colorant}(c::Vector{T}) = c
gl_color(c::RGBA{Float32}) = c
gl_color(c::Colorant) = RGBA{Float32}(c)

function gl_color(tuple::Tuple)
    gl_color(tuple...)
end

# convert to RGBA
function gl_color(c, a)
    c = convertColor(c, a)
    RGBA{Float32}(c)
end
function scalar_color(d, sym)
    gl_color(extract_color(d, sym))
end

function gl_color_map(d, sym)
    colors = extract_color(d, sym)
    _gl_color_map(colors)
end
function _gl_color_map(colors::PlotUtils.ColorGradient)
    colors.colors
end
function _gl_color_map(c)
    Plots.default_gradient()
end



dist(a, b) = abs(a-b)
mindist(x, a, b) = NaNMath.min(dist(a, x), dist(b, x))

function gappy(x, ps)
    n = length(ps)
    x <= first(ps) && return first(ps) - x
    for j=1:(n-1)
        p0 = ps[j]
        p1 = ps[NaNMath.min(j+1, n)]
        if p0 <= x && p1 >= x
            return mindist(x, p0, p1) * (isodd(j) ? 1 : -1)
        end
    end
    return last(ps) - x
end
function ticks(points, resolution)
    Float16[gappy(x, points) for x = linspace(first(points),last(points), resolution)]
end


function insert_pattern!(points, kw_args)
    tex = GLAbstraction.Texture(ticks(points, 100), x_repeat=:repeat)
    kw_args[:pattern] = tex
    kw_args[:pattern_length] = Float32(last(points))
end
function extract_linestyle(d, kw_args)
    haskey(d, :linestyle) || return
    ls = d[:linestyle]
    lw = d[:linewidth]
    kw_args[:thickness] = lw
    if ls == :dash
        points = [0.0, lw, 2lw, 3lw, 4lw]
        insert_pattern!(points, kw_args)
    elseif ls == :dot
        tick, gap = lw/2, lw/4
        points = [0.0, tick, tick+gap, 2tick+gap, 2tick+2gap]
        insert_pattern!(points, kw_args)
    elseif ls == :dashdot
        dtick, dgap = lw, lw
        ptick, pgap = lw/2, lw/4
        points = [0.0, dtick, dtick+dgap, dtick+dgap+ptick, dtick+dgap+ptick+pgap]
        insert_pattern!(points, kw_args)
    elseif ls == :dashdotdot
        dtick, dgap = lw, lw
        ptick, pgap = lw/2, lw/4
        points = [0.0, dtick, dtick+dgap, dtick+dgap+ptick, dtick+dgap+ptick+pgap, dtick+dgap+ptick+pgap+ptick,  dtick+dgap+ptick+pgap+ptick+pgap]
        insert_pattern!(points, kw_args)
    end
    extract_c(d, kw_args, :line)
    nothing
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
    kw_args[:color] = gl_color(font.color)
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
    c = gl_color(d[key])
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
    c = gl_color(d[key])
    if c != nothing
        if !isa(c, Colorant)
            error("Stroke Color not supported: $c")
        end
        kw_args[:stroke_color] = c
        kw_args[:stroke_width] = Float32(d[Symbol("$(sym)strokewidth")]) * 2
    end
    return
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
    GL.gl_lines(map(Point2f0, grid_segs.pts), kw_args)
end

function align_offset(startpos, lastpos, atlas, rscale, font, align)
    xscale, yscale = GLVisualize.glyph_scale!('X', rscale)
    xmove = (lastpos-startpos)[1] + xscale
    if isa(align, GeometryTypes.Vec)
        return -Vec2f0(xmove, yscale) .* align
    elseif align == :top
        return -Vec2f0(xmove/2f0, yscale)
    elseif align == :right
        return -Vec2f0(xmove, yscale/2f0)
    else
        error("Align $align not known")
    end
end


function alignment2num(x::Symbol)
    (x in (:hcenter, :vcenter)) && return 0.5
    (x in (:left, :bottom)) && return 0.0
    (x in (:right, :top)) && return 1.0
    0.0 # 0 default, or better to error?
end

function alignment2num(font::Plots.Font)
    Vec2f0(map(alignment2num, (font.halign, font.valign)))
end

pointsize(font) = font.pointsize * 2

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

function glvisualize_text(position, text, kw_args)
    text_align = alignment2num(text.font)
    startpos = Vec2f0(position)
    atlas = GLVisualize.get_texture_atlas()
    font = GLVisualize.defaultfont()
    rscale = kw_args[:relative_scale]

    position = GLVisualize.calc_position(text.str, startpos, rscale, font, atlas)
    offset = GLVisualize.calc_offset(text.str, rscale, font, atlas)
    alignoff = align_offset(startpos, last(position), atlas, rscale, font, text_align)

    map!(position, position) do pos
        pos .+ alignoff
    end
    kw_args[:position] = position
    kw_args[:offset] = offset
    kw_args[:scale_primitive] = true
    visualize(text.str, Style(:default), kw_args)
end

function text_model(font, pivot)
    pv = GeometryTypes.Vec3f0(pivot[1], pivot[2], 0)
    if font.rotation != 0.0
        rot = Float32(deg2rad(font.rotation))
        rotm = GLAbstraction.rotationmatrix_z(rot)
        return GLAbstraction.translationmatrix(pv)*rotm*GLAbstraction.translationmatrix(-pv)
    else
        eye(GeometryTypes.Mat4f0)
    end
end
function gl_draw_axes_2d(sp::Plots.Subplot{Plots.GLVisualizeBackend}, model, area)
    xticks, yticks, xspine_segs, yspine_segs, xgrid_segs, ygrid_segs, xborder_segs, yborder_segs = Plots.axis_drawing_info(sp)
    xaxis = sp[:xaxis]; yaxis = sp[:yaxis]

    xgc = Colors.color(Plots.gl_color(xaxis[:foreground_color_grid]))
    ygc = Colors.color(Plots.gl_color(yaxis[:foreground_color_grid]))
    axis_vis = []
    if xaxis[:grid]
        grid = draw_grid_lines(sp, xgrid_segs, xaxis[:gridlinewidth], xaxis[:gridstyle], model, RGBA(xgc, xaxis[:gridalpha]))
        push!(axis_vis, grid)
    end
    if yaxis[:grid]
        grid = draw_grid_lines(sp, ygrid_segs, yaxis[:gridlinewidth], yaxis[:gridstyle], model, RGBA(ygc, yaxis[:gridalpha]))
        push!(axis_vis, grid)
    end

    xac = Colors.color(Plots.gl_color(xaxis[:foreground_color_axis]))
    yac = Colors.color(Plots.gl_color(yaxis[:foreground_color_axis]))
    if alpha(xaxis[:foreground_color_axis]) > 0
        spine = draw_grid_lines(sp, xspine_segs, 1f0, :solid, model, RGBA(xac, 1.0f0))
        push!(axis_vis, spine)
    end
    if alpha(yaxis[:foreground_color_axis]) > 0
        spine = draw_grid_lines(sp, yspine_segs, 1f0, :solid, model, RGBA(yac, 1.0f0))
        push!(axis_vis, spine)
    end
    fcolor = Plots.gl_color(xaxis[:foreground_color_axis])

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

    xbc = Colors.color(Plots.gl_color(xaxis[:foreground_color_border]))
    ybc = Colors.color(Plots.gl_color(yaxis[:foreground_color_border]))
    intensity = sp[:framestyle] == :semi ? 0.5f0 : 1.0f0
    if sp[:framestyle] in (:box, :semi)
        xborder = draw_grid_lines(sp, xborder_segs, intensity, :solid, model, RGBA(xbc, intensity))
        yborder = draw_grid_lines(sp, yborder_segs, intensity, :solid, model, RGBA(ybc, intensity))
        push!(axis_vis, xborder, yborder)
    end

    area_w = GeometryTypes.widths(area)
    if sp[:title] != ""
        tf = sp[:titlefont]; color = gl_color(sp[:foreground_color_title])
        font = Plots.Font(tf.family, tf.pointsize, :hcenter, :top, tf.rotation, color)
        xy = Point2f0(area.w/2, area_w[2] + pointsize(tf)/2)
        kw = Dict(:model => text_model(font, xy), :scale_primitive => true)
        extract_font(font, kw)
        t = PlotText(sp[:title], font)
        push!(axis_vis, glvisualize_text(xy, t, kw))
    end
    if xaxis[:guide] != ""
        tf = xaxis[:guidefont]; color = gl_color(xaxis[:foreground_color_guide])
        xy = Point2f0(area.w/2, - pointsize(tf)/2)
        font = Plots.Font(tf.family, tf.pointsize, :hcenter, :bottom, tf.rotation, color)
        kw = Dict(:model => text_model(font, xy), :scale_primitive => true)
        t = PlotText(xaxis[:guide], font)
        extract_font(font, kw)
        push!(axis_vis, glvisualize_text(xy, t, kw))
    end

    if yaxis[:guide] != ""
        tf = yaxis[:guidefont]; color = gl_color(yaxis[:foreground_color_guide])
        font = Plots.Font(tf.family, tf.pointsize, :hcenter, :top, 90f0, color)
        xy = Point2f0(-pointsize(tf)/2, area.h/2)
        kw = Dict(:model => text_model(font, xy), :scale_primitive=>true)
        t = PlotText(yaxis[:guide], font)
        extract_font(font, kw)
        push!(axis_vis, glvisualize_text(xy, t, kw))
    end

    axis_vis
end

function gl_draw_axes_3d(sp, model)
    x = Plots.axis_limits(sp[:xaxis])
    y = Plots.axis_limits(sp[:yaxis])
    z = Plots.axis_limits(sp[:zaxis])

    min = Vec3f0(x[1], y[1], z[1])
    visualize(
        GeometryTypes.AABB{Float32}(min, Vec3f0(x[2], y[2], z[2])-min),
        :grid, model=model
    )
end

function gl_bar(d, kw_args)
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

function gl_boxplot(d, kw_args)
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
function gl_viewport(bb, rect)
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
            Plots.gl_viewport(rel_bbox, rect)
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
            axis = gl_draw_axes_2d(sp, model_m, Reactive.value(sub_area))
            GLVisualize._view(axis, sp_screen, camera=:perspective)
            cam.projectiontype.value = GLVisualize.ORTHOGRAPHIC
            Reactive.run_till_now() # make sure Reactive.push! arrives
            GLAbstraction.center!(cam,
                GeometryTypes.AABB(
                    Vec3f0(-20), Vec3f0((GeometryTypes.widths(sp_screen)+40f0)..., 1)
                )
            )
        else
            axis = gl_draw_axes_3d(sp, model_m)
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
                vis = GL.gl_surface(x, y, z, kw_args)
            elseif (st in (:path, :path3d)) && d[:linewidth] > 0
                kw = copy(kw_args)
                points = Plots.extract_points(d)
                extract_linestyle(d, kw)
                vis = GL.gl_lines(points, kw)
                if d[:markershape] != :none
                    kw = copy(kw_args)
                    extract_stroke(d, kw)
                    extract_marker(d, kw)
                    vis2 = GL.gl_scatter(copy(points), kw)
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
                    vis = [GL.gl_poly(ps, kw), vis]
                end
            elseif st in (:scatter, :scatter3d) #|| d[:markershape] != :none
                extract_marker(d, kw_args)
                points = extract_points(d)
                vis = GL.gl_scatter(points, kw_args)
            elseif st == :shape
                extract_c(d, kw_args, :fill)
                vis = GL.gl_shape(d, kw_args)
            elseif st == :contour
                x,y,z = extract_surface(d)
                z = transpose_z(d, z, false)
                extract_extrema(d, kw_args)
                extract_gradient(d, kw_args, :fill)
                kw_args[:fillrange] = d[:fillrange]
                kw_args[:levels] = d[:levels]

                vis = GL.gl_contour(x,y,z, kw_args)
            elseif st == :heatmap
                x,y,z = extract_surface(d)
                extract_gradient(d, kw_args, :fill)
                extract_extrema(d, kw_args)
                extract_limits(sp, d, kw_args)
                vis = GL.gl_heatmap(x,y,z, kw_args)
            elseif st == :bar
                extract_c(d, kw_args, :fill)
                extract_stroke(d, kw_args, :marker)
                vis = gl_bar(d, kw_args)
            elseif st == :image
                extract_extrema(d, kw_args)
                vis = GL.gl_image(d[:z].surf, kw_args)
            elseif st == :boxplot
                 extract_c(d, kw_args, :fill)
                 vis = gl_boxplot(d, kw_args)
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



function _show(io::IO, ::MIME"image/png", plt::Plot{GLVisualizeBackend})
    _display(plt, false)
    GLWindow.poll_glfw()
    if Base.n_avail(Reactive._messages) > 0
        Reactive.run_till_now()
    end
    yield()
    GLWindow.render_frame(GLWindow.rootscreen(plt.o))
    GLWindow.swapbuffers(plt.o)
    buff = GLWindow.screenbuffer(plt.o)
    png = map(RGB{U8}, buff)
    FileIO.save(FileIO.Stream(FileIO.DataFormat{:PNG}, io), png)
end


function gl_image(img, kw_args)
    rect = kw_args[:primitive]
    kw_args[:primitive] = GeometryTypes.SimpleRectangle{Float32}(rect.x, rect.y, rect.h, rect.w) # seems to be flipped
    visualize(img, Style(:default), kw_args)
end

function handle_segment{P}(lines, line_segments, points::Vector{P}, segment)
    (isempty(segment) || length(segment) < 2) && return
    if length(segment) == 2
         append!(line_segments, view(points, segment))
    elseif length(segment) == 3
        p = view(points, segment)
        push!(line_segments, p[1], p[2], p[2], p[3])
    else
        append!(lines, view(points, segment))
        push!(lines, P(NaN))
    end
end

function gl_lines(points, kw_args)
    result = []
    isempty(points) && return result
    P = eltype(points)
    lines = P[]
    line_segments = P[]
    last = 1
    for (i,p) in enumerate(points)
        if isnan(p) || i==length(points)
            _i = isnan(p) ? i-1 : i
            handle_segment(lines, line_segments, points, last:_i)
            last = i+1
        end
    end
    if !isempty(lines)
        pop!(lines) # remove last NaN
        push!(result, visualize(lines, Style(:lines), kw_args))
    end
    if !isempty(line_segments)
        push!(result, visualize(line_segments, Style(:linesegment), kw_args))
    end
    return result
end

function gl_shape(d, kw_args)
    points = Plots.extract_points(d)
    result = []
    for rng in iter_segments(d[:x], d[:y])
        ps = points[rng]
        meshes = gl_poly(ps, kw_args)
        append!(result, meshes)
    end
    result
end



function gl_scatter(points, kw_args)
    prim = get(kw_args, :primitive, GeometryTypes.Circle)
    if isa(prim, GLNormalMesh)
        if haskey(kw_args, :model)
            p = get(kw_args, :perspective, eye(GeometryTypes.Mat4f0))
            kw_args[:scale] = GLAbstraction.const_lift(kw_args[:model], kw_args[:scale], p) do m, sc, p
                s  = Vec3f0(m[1,1], m[2,2], m[3,3])
                ps = Vec3f0(p[1,1], p[2,2], p[3,3])
                r  = sc ./ (s .* ps)
                r
            end
        end
    else # 2D prim
        kw_args[:scale] = to_vec(Vec2f0, kw_args[:scale])
    end

    if haskey(kw_args, :stroke_width)
        s = Reactive.value(kw_args[:scale])
        sw = kw_args[:stroke_width]
        if sw*5 > _cycle(Reactive.value(s), 1)[1] # restrict marker stroke to 1/10th of scale (and handle arrays of scales)
            kw_args[:stroke_width] = s[1] / 5f0
        end
    end
    kw_args[:scale_primitive] = false
    if isa(prim, String)
        kw_args[:position] = points
        if !isa(kw_args[:scale], Vector) # if not vector, we can assume it's relative scale
            kw_args[:relative_scale] = kw_args[:scale]
            delete!(kw_args, :scale)
        end
        return visualize(prim, Style(:default), kw_args)
    end

    visualize((prim, points), Style(:default), kw_args)
end


function gl_poly(points, kw_args)
    last(points) == first(points) && pop!(points)
    polys = GeometryTypes.split_intersections(points)
    result = []
    for poly in polys
        mesh = GLNormalMesh(poly) # make polygon
        if !isempty(GeometryTypes.faces(mesh)) # check if polygonation has any faces
            push!(result, GLVisualize.visualize(mesh, Style(:default), kw_args))
        else
            warn("Couldn't draw the polygon: $points")
        end
    end
    result
end




function gl_surface(x,y,z, kw_args)
    if isa(x, Range) && isa(y, Range)
        main = z
        kw_args[:ranges] = (x, y)
    else
        if isa(x, AbstractMatrix) && isa(y, AbstractMatrix)
            main = map(s->map(Float32, s), (x, y, z))
        elseif isa(x, AbstractVector) || isa(y, AbstractVector)
            x = Float32[x[i] for i = 1:size(z,1), j = 1:size(z,2)]
            y = Float32[y[j] for i = 1:size(z,1), j = 1:size(z,2)]
            main = (x, y, map(Float32, z))
        else
            error("surface: combination of types not supported: $(typeof(x)) $(typeof(y)) $(typeof(z))")
        end
        if get(kw_args, :wireframe, false)
            points = map(Point3f0, zip(vec(x), vec(y), vec(z)))
            faces = Cuint[]
            idx = (i,j) -> sub2ind(size(z), i, j) - 1
            for i=1:size(z,1), j=1:size(z,2)

                i < size(z,1) && push!(faces, idx(i, j), idx(i+1, j))
                j < size(z,2) && push!(faces, idx(i, j), idx(i, j+1))

            end
            color = get(kw_args, :stroke_color, RGBA{Float32}(0,0,0,1))
            kw_args[:color] = color
            kw_args[:thickness] = get(kw_args, :stroke_width, 1f0)
            kw_args[:indices] = faces
            delete!(kw_args, :stroke_color)
            delete!(kw_args, :stroke_width)

            return visualize(points, Style(:linesegment), kw_args)
        end
    end
    return visualize(main, Style(:surface), kw_args)
end


function gl_contour(x, y, z, kw_args)
    if kw_args[:fillrange] != nothing

        delete!(kw_args, :intensity)
        I = GLVisualize.Intensity{Float32}
        main = [I(z[j,i]) for i=1:size(z, 2), j=1:size(z, 1)]
        return visualize(main, Style(:default), kw_args)

    else
        h = kw_args[:levels]
        T = eltype(z)
        levels = Contour.contours(map(T, x), map(T, y), z, h)
        result = Point2f0[]
        zmin, zmax = get(kw_args, :limits, Vec2f0(ignorenan_extrema(z)))
        cmap = get(kw_args, :color_map, get(kw_args, :color, RGBA{Float32}(0,0,0,1)))
        colors = RGBA{Float32}[]
        for c in levels.contours
            for elem in c.lines
                append!(result, elem.vertices)
                push!(result, Point2f0(NaN32))
                col = GLVisualize.color_lookup(cmap, c.level, zmin, zmax)
                append!(colors, fill(col, length(elem.vertices) + 1))
            end
        end
        kw_args[:color] = colors
        kw_args[:color_map] = nothing
        kw_args[:color_norm] = nothing
        kw_args[:intensity] = nothing
        return visualize(result, Style(:lines),kw_args)
    end
end


function gl_heatmap(x,y,z, kw_args)
    get!(kw_args, :color_norm, Vec2f0(ignorenan_extrema(z)))
    get!(kw_args, :color_map, Plots.make_gradient(cgrad()))
    delete!(kw_args, :intensity)
    I = GLVisualize.Intensity{Float32}
    heatmap = I[z[j,i] for i=1:size(z, 2), j=1:size(z, 1)]
    tex = GLAbstraction.Texture(heatmap, minfilter=:nearest)
    kw_args[:stroke_width] = 0f0
    kw_args[:levels] = 1f0
    visualize(tex, Style(:default), kw_args)
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
    GL.gl_scatter(Point2f0[(w/2, ho)], kw)
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
        append!(result, GL.gl_lines(points, kw))
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

end # module

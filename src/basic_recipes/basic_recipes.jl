
@recipe(Poly) do scene
    Theme(;
        color = theme(scene, :color),
        visible = theme(scene, :visible),
        strokecolor = RGBAf0(0,0,0,0),
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        strokewidth = 0.0,
        shading = false,
        linestyle = nothing,
    )
end
convert_arguments(::Type{<: Poly}, v::AbstractVector{<: AbstractVector{<: VecTypes}}) = (v,)
convert_arguments(::Type{<: Poly}, v::AbstractVector{<: VecTypes}) = ([convert_arguments(Scatter, v)[1]],)
convert_arguments(::Type{<: Poly}, v::AbstractVector{<: Union{Circle, Rectangle, HyperRectangle}}) = (v,)
convert_arguments(::Type{<: Poly}, args...) = ([convert_arguments(Scatter, args...)[1]],)
convert_arguments(::Type{<: Poly}, vertices::AbstractArray, indices::AbstractArray) = convert_arguments(Mesh, vertices, indices)

function plot!(plot::Poly{<: Tuple{Union{AbstractMesh, GeometryPrimitive}}})
    mesh!(
        plot, plot[1],
        color = plot[:color], colormap = plot[:colormap], colorrange = plot[:colorrange],
        shading = false, visible = plot[:visible]
    )
    wireframe!(
        plot, plot[1],
        color = plot[:strokecolor], linestyle = plot[:linestyle],
        linewidth = plot[:strokewidth], visible = plot[:visible]
    )
end

function plot!(plot::Poly{<: Tuple{<: AbstractVector{P}}}) where P <: AbstractVector{<: VecTypes}
    polygons = plot[1]
    color_node = plot[:color]
    attributes = Attributes()
    meshes = lift(polygons) do polygons
        polys = Vector{Point2f0}[]
        for poly in polygons
            s = GeometryTypes.split_intersections(poly)
            append!(polys, s)
        end
        GLNormalMesh.(polys)
    end
    mesh!(plot, meshes, visible = plot[:visible], shading = plot[:shading], color = plot[:color])
    outline = lift(polygons) do polygons
        line = Point2f0[]
        for poly in polygons
            append!(line, poly)
            push!(line, poly[1])
            push!(line, Point2f0(NaN))
        end
        line
    end
    lines!(
        plot, outline, visible = plot[:visible],
        color = plot[:strokecolor], linestyle = plot[:linestyle],
        linewidth = plot[:strokewidth],
    )
end

function plot!(plot::Mesh{<: Tuple{<: AbstractVector{P}}}) where P <: AbstractMesh
    meshes = plot[1]
    color_node = plot[:color]
    attributes = Attributes(visible = plot[:visible], shading = plot[:shading])
    bigmesh = if color_node[] isa Vector && length(color_node[]) == length(meshes[])
        lift(meshes, color_node) do meshes, colors
            meshes = GeometryTypes.add_attribute.(GLNormalMesh.(meshes), to_color.(colors))
            merge(meshes)
        end
    else
        attributes[:color] = color_node
        lift(meshes) do meshes
            merge(GLPlainMesh.(meshes))
        end
    end
    mesh!(plot, attributes, bigmesh)
end

function plot!(plot::Poly{<: Tuple{<: AbstractVector{T}}}) where T <: Union{Circle, Rectangle, Rect}
    positions = plot[1]
    position = lift(positions) do rects
        Point.(minimum.(rects))
    end
    markersize = lift(positions, name = "markersize") do rects
        widths.(rects)
    end
    scatter!(
        plot, position,
        marker = T, markersize = markersize, transform_marker = true,
        marker_offset = Vec2f0(0),
        color = plot[:color],
        strokecolor = plot[:strokecolor],
        colormap = plot[:colormap],
        colorrange = plot[:colorrange],
        strokewidth = plot[:strokewidth], visible = plot[:visible]
    )
end
function data_limits(p::Poly{<: Tuple{<: AbstractVector{T}}}) where T <: Union{Circle, Rectangle, Rect}
    xyz = p.plots[1][1][]
    msize = p.plots[1][:markersize][]
    xybb = FRect3D(xyz)
    mwidth = FRect3D(xyz .+ msize)
    union(mwidth, xybb)
end

@recipe(Arrows, points, directions) do scene
    theme = Theme(
        arrowhead = automatic,
        arrowtail = nothing,
        linecolor = :black,
        linewidth = 1,
        arrowsize = 0.3,
        linestyle = nothing,
        scale = Vec3f0(1),
        normalize = false,
        lengthscale = 1.0f0
    )
    # connect arrow + linecolor by default
    get!(theme, :arrowcolor, theme[:linecolor])
    theme
end

# For the matlab/matplotlib users
const quiver = arrows
const quiver! = arrows!
export quiver, quiver!

arrow_head(N, marker) = marker
arrow_head(N, marker::Automatic) = N == 2 ? '▲' : Pyramid(Point3f0(0, 0, -0.5), 1f0, 1f0)

scatterfun(N) = N == 2 ? scatter! : meshscatter!


convert_arguments(::Type{<: Arrows}, x, y, u, v) = (Point2f0.(x, y), Vec2f0.(u, v))
function convert_arguments(::Type{<: Arrows}, x::AbstractVector, y::AbstractVector, u::AbstractMatrix, v::AbstractMatrix)
    (vec(Point2f0.(x, y')), vec(Vec2f0.(u, v)))
end
convert_arguments(::Type{<: Arrows}, x, y, z, u, v, w) = (Point3f0.(x, y, z), Vec3f0.(u, v, w))

function plot!(arrowplot::Arrows{<: Tuple{AbstractVector{<: Point{N, T}}, V}}) where {N, T, V}
    @extract arrowplot (points, directions, lengthscale, arrowhead, arrowsize, arrowcolor)
    headstart = lift(points, directions, lengthscale) do points, directions, s
        map(points, directions) do p1, dir
            dir = arrowplot[:normalize][] ? StaticArrays.normalize(dir) : dir
            Point{N, Float32}(p1) => Point{N, Float32}(p1 .+ (dir .* Float32(s)))
        end
    end
    linesegments!(
        arrowplot, headstart,
        color = arrowplot[:linecolor], linewidth = arrowplot[:linewidth],
        linestyle = arrowplot[:linestyle],
    )
    scatterfun(N)(
        arrowplot,
        lift(x-> last.(x), headstart),
        marker = lift(x-> arrow_head(N, x), arrowhead), markersize = arrowsize,
        color = arrowcolor, rotations = directions
    )
end

@recipe(Wireframe) do scene
    default_theme(scene, LineSegments)
end

function argument_conversion(::Type{Wireframe}, x::AbstractVector, y::AbstractVector, z::AbstractMatrix)
    (ngrid(x, y)..., z)
end


xvector(x::AbstractVector, len) = x
xvector(x::ClosedInterval, len) = range(minimum(x), stop=maximum(x), length=len)
xvector(x::AbstractMatrix, len) = x

yvector(x, len) = xvector(x, len)'
yvector(x::AbstractMatrix, len) = x

"""
    `wireframe(x, y, z)`, `wireframe(positions)`, or `wireframe(mesh)`

Draws a wireframe, either interpreted as a surface or as a mesh.
"""
function plot!(plot::Wireframe{<: Tuple{<: Any, <: Any, <: AbstractMatrix}})
    points_faces = lift(plot[1:3]...) do x, y, z
        T = eltype(z); M, N = size(z)
        points = vec(Point3f0.(xvector(x, M), yvector(y, N), z))
        # Connect the vetices with faces, as one would use for a 2D Rectangle
        # grid with M,N grid points
        faces = decompose(Face{2, GLIndex}, SimpleRectangle(0, 0, 1, 1), (M, N))
        view(points, faces)
    end
    linesegments!(plot, Theme(plot), points_faces)
end


function plot!(plot::Wireframe{Tuple{T}}) where T
    points = lift(plot[1]) do g
        # get the point representation of the geometry
        indices = decompose(Face{2, GLIndex}, g)
        points = decompose(Point3f0, g)
        view(points, indices)
    end
    linesegments!(plot, Theme(plot), points)
end


function sphere_streamline(linebuffer, ∇ˢf, pt, h, n)
    push!(linebuffer, pt)
    df = normalize(∇ˢf(pt[1], pt[2], pt[3]))
    push!(linebuffer, normalize(pt .+ h*df))
    for k=2:n
        cur_pt = last(linebuffer)
        push!(linebuffer, cur_pt)
        df = normalize(∇ˢf(cur_pt...))
        push!(linebuffer, normalize(cur_pt .+ h*df))
    end
    return
end

@recipe(StreamLines, points, directions) do scene
    Theme(
        h = 0.01f0,
        n = 5,
        color = :black,
        linewidth = 1
    )
end

function plot!(plot::StreamLines{<: AbstractVector{T}}) where T
    @extract plot (points, directions)
    linebuffer = T[]
    lines = lift(directions, points, plot[:h], plot[:n]) do ∇ˢf, origins, h, n
        empty!(linebuffer)
        for point in origins
            sphere_streamline(linebuffer, ∇ˢf, point, h, n)
        end
        linebuffer
    end
    linesegments!(plot, Theme(plot), lines)
end


@recipe(Series, series) do scene
    Theme(
        seriescolors = :Set1,
        seriestype = :lines
    )
end
convert_arguments(::Type{<: Series}, A::AbstractMatrix{<: Number}) = (A,)
function plot!(sub::Series)
    A = sub[1]
    colors = map_once(sub[:seriescolors], A) do colors, A
        cmap = to_colormap(colors)
        if size(A, 2) > length(cmap)
            @info("Colormap doesn't have enough distinctive values. Please consider using another value for seriescolors")
            cmap = interpolated_getindex.((cmap,), range(0, stop=1, length=M))
        end
        cmap
    end
    map_once(A, sub[:seriestype]) do A, stype
        empty!(sub.plots)
        N, M = size(A)
        for i = 1:M
            c = lift(getindex, colors, i)
            attributes = Theme(color = c)
            a_view = view(A, :, i)
            if stype in (:lines, :scatter_lines)
                lines!(sub, attributes, a_view)
            end
            # if stype in (:scatter, :scatter_lines)
            #     scatter!(subsub, attributes, a_view)
            # end
            # subsub
        end
    end
    labels = get(sub, :labels) do
        map(i-> "y $i", 1:size(A[], 2))
    end
    legend!(sub, copy(sub.plots), labels)
    sub
end



"""
    `annotations(strings::Vector{String}, positions::Vector{Point})`

Plots an array of texts at each position in `positions`.
"""
@recipe(Annotations, text, position) do scene
    default_theme(scene, Text)
end

"""
Pushes an updates to all listeners of `node`
"""
function notify!(node::Node)
    node[] = node[]
end

function plot!(plot::Annotations)
    position = plot[2]
    sargs = (
        plot[:model], plot[:font],
        plot[1], position,
        getindex.(plot, (:color, :textsize, :align, :rotation))...,
    )
    N = to_value(position) |> eltype |> length
    atlas = get_texture_atlas()
    combinedpos = [Point3f0(0)]; colors = RGBAf0[RGBAf0(0,0,0,0)]
    scales = Vec2f0[(0,0)]; fonts = NativeFont[to_font("Dejavu Sans")]
    rotations = Quaternionf0[Quaternionf0(0,0,0,0)]

    tplot = text!(plot, "",
        align = Vec2f0(0), model = Mat4f0(I),
        position = combinedpos, color = colors,
        textsize = scales, font = fonts, rotation = rotations
    ).plots[end]

    onany(sargs...) do model, font, args...
        if length(args[1]) != length(args[2])
            error("For each text annotation, there needs to be one position. Found: $(length(t)) strings and $(length(p)) positions")
        end
        io = IOBuffer();
        empty!(combinedpos); empty!(colors); empty!(scales); empty!(fonts); empty!(rotations)

        broadcast_foreach(1:length(args[1]), args...) do idx, text, startpos, color, tsize, alignment, rotation
            # the fact, that Font == Vector{FT_FreeType.Font} is pretty annoying for broadcasting.
            # TODO have a better Font type!
            f = to_font(font)
            f = isa(f, NativeFont) ? f : f[idx]
            c = to_color(color)
            rot = to_rotation(rotation)
            pos, s = layout_text(text, startpos, tsize, f, alignment, rot, model)
            print(io, text)
            n = length(pos)
            append!(combinedpos, pos)
            append!(scales, s)
            append!(colors, repeated(c, n))
            append!(fonts, repeated(f, n))
            append!(rotations, repeated(rot, n))
        end
        str = String(take!(io))
        # update string the signals
        tplot[1] = str
        tplot[:scales] = scales
        tplot[:color] = colors
        tplot[:rotation] = rotations
        # fonts shouldn't need an update, since it will get udpated when listening on string
        #
        return
    end
    # update one time in the beginning, since otherwise the above won't run
    notify!(sargs[1])
    plot
end

is2d(scene::SceneLike) = widths(limits(scene)[])[3] == 0.0


@recipe(Arc, origin, radius, start_angle, stop_angle) do scene
    Theme(;
        default_theme(scene, Lines)...,
        resolution = 361,
    )
end

function plot!(p::Arc)
    args = getindex.(p, (:origin, :radius, :start_angle, :stop_angle, :resolution))
    positions = lift(args...) do origin, radius, start_angle, stop_angle, resolution
        map(range(start_angle, stop=stop_angle, length=resolution)) do angle
            origin .+ (Point2f0(sin(angle), cos(angle)) .* radius)
        end
    end
    lines!(p, Theme(p), positions)
end



function AbstractPlotting.plot!(plot::Plot(AbstractVector{<: Complex}))
    plot[:axis, :labels] = ("Re(x)", "Im(x)")
    lines!(plot, lift(im-> Point2f0.(real.(im), imag.(im)), x[1]))
end




@recipe(BarPlot, x, y) do scene
    Theme(;
        fillto = 0.0,
        color = theme(scene, :color),
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        marker = Rect,
        strokewidth = 0,
        strokecolor = :white,
        width = automatic
    )
end

function data_limits(p::BarPlot)
    xy = p.plots[1][1][]
    msize = p.plots[1][:markersize][]
    xstart, xend = first(msize)[1], last(msize)[1]
    xvals = first.(xy)
    # correct widths
    xvals[1] = xvals[1] - (xstart / 2)
    xvals[end] = xvals[end] + (xend / 2)
    xybb = FRect3D(xy)
    y = last.(msize) .+ last.(xy)
    bb = xyz_boundingbox(xvals, y)
    union(bb, xybb)
end


conversion_trait(::Type{<: BarPlot}) = PointBased()


function AbstractPlotting.plot!(p::BarPlot)
    pos_scale = lift(p[1], p[:fillto], p[:width]) do xy, fillto, hw
        # compute half-width of bars
        if hw === automatic
            hw = mean(diff(first.(xy))) # TODO ignore nan?
        end
        # make fillto a vector... default fills to 0
        positions = Point2f0.(first.(xy), Float32.(fillto))
        scales = Vec2f0.(abs.(hw), last.(xy))
        offset = Vec2f0.(hw ./ -2f0, 0)
        positions, scales, offset
    end

    scatter!(
        p, lift(first, pos_scale),
        marker = p[:marker], marker_offset = lift(last, pos_scale),
        markersize = lift(getindex, pos_scale, Node(2)),
        color = p[:color], colormap = p[:colormap], colorrange = p[:colorrange],
        transform_marker = true, strokewidth = p[:strokewidth],
        strokecolor = p[:strokecolor]
    )
end

function convert_arguments(P::PlotFunc, r::AbstractVector, f::Function)
    ptype = plottype(P, Lines)
    to_plotspec(ptype, convert_arguments(ptype, r, f.(r)))
end

function convert_arguments(P::PlotFunc, i::AbstractInterval, f::Function)
    convert_arguments(P, PlotUtils.adapted_grid(f, endpoints(i)), f)
end

to_tuple(t::Tuple) = t
to_tuple(t) = (t,)

function convert_arguments(P::PlotFunc, f::Function, args...; kwargs...)
    tmp = f(args...; kwargs...) |> to_tuple
    convert_arguments(P, tmp...)
end

@recipe(ScatterLines) do scene
    merge(default_theme(scene, Scatter), default_theme(scene, Lines))
end

function plot!(p::Combined{scatterlines, <:NTuple{N, Any}}) where N
    plot!(p, Lines, Theme(p), p[1:N]...)
    plot!(p, Scatter, Theme(p), p[1:N]...)
end



@recipe(Band, x, ylower, yupper) do scene
    Theme(;
        default_theme(scene, Mesh)...,
        color = RGBAf0(1.0,0,0,0.2)
    )
end

function band_connect(n)
    ns = 1:n-1
    ns2 = n+1:2n-1
    [GLTriangle.(ns, ns .+ 1, ns2); GLTriangle.(ns .+ 1, ns2 .+ 1, ns2)]
end

function plot!(plot::Band)
    coordinates = lift( (x, ylower, yupper) -> [Point2f0.(x, ylower); Point2f0.(x, yupper)], plot[1], plot[2], plot[3])
    connectivity = lift(x -> band_connect(length(x)), plot[1])
    mesh!(plot, coordinates, connectivity;
        color = plot[:color], colormap = plot[:colormap],
        colorrange = plot[:colorrange],
        shading = false, visible = plot[:visible]
    )
end


function fill_view(x, y1, y2, where::Nothing)
  x, y1, y2
end
function fill_view(x, y1, y2, where::Function)
  fill_view(x, y1, y2, where.(x, y1, y2))
end
function fill_view(x, y1, y2, bools::AbstractVector{<: Union{Integer, Bool}})
  view(x, bools), view(y1, bools), view(y2, bools)
end

"""
    fill_between!(x, y1, y2; where = nothing, scene = current_scene(), kw_args...)

fill the section between 2 lines with the condition `where`
"""
function fill_between!(x, y1, y2; where = nothing, scene = current_scene(), kw_args...)
  xv, ylow, yhigh = fill_view(x, y1, y2, where)
  band!(scene, xv, ylow, yhigh; kw_args...)
end

export fill_between!

"""
    contour(x, y, z)
Creates a contour plot of the plane spanning x::Vector, y::Vector, z::Matrix
"""
@recipe(Contour) do scene
    default = default_theme(scene)
    pop!(default, :color)
    Theme(;
        default...,
        color = nothing,
        colormap = theme(scene, :colormap),
        colorrange = AbstractPlotting.automatic,
        levels = 5,
        linewidth = 1.0,
        fillrange = false,
    )
end

"""
    contour3d(x, y, z)
Creates a 3D contour plot of the plane spanning x::Vector, y::Vector, z::Matrix,
with z-elevation for each level
"""
@recipe(Contour3d) do scene
    default_theme(scene, Contour)
end


function contourlines(::Type{<: Contour}, contours, cols)
    result = Point2f0[]
    colors = RGBA{Float32}[]
    for (color, c) in zip(cols, Contours.levels(contours))
        for elem in Contours.lines(c)
            append!(result, elem.vertices)
            push!(result, Point2f0(NaN32))
            append!(colors, fill(color, length(elem.vertices) + 1))
        end
    end
    result, colors
end

function contourlines(::Type{<: Contour3d}, contours, cols)
    result = Point3f0[]
    colors = RGBA{Float32}[]
    for (color, c) in zip(cols, Contours.levels(contours))
        for elem in Contours.lines(c)
            for p in elem.vertices
                push!(result, Point3f0(p[1], p[2], c.level))
            end
            push!(result, Point3f0(NaN32))
            append!(colors, fill(color, length(elem.vertices) + 1))
        end
    end
    result, colors
end


to_levels(x::AbstractVector{<: Number}, cnorm) = x
function to_levels(n::Integer, cnorm)
    zmin, zmax = cnorm
    dz = (zmax - zmin) / (n + 1)
    range(zmin + dz; step = dz, length = n)
end
conversion_trait(::Type{<: Contour3d}) = SurfaceLike()
conversion_trait(::Type{<: Contour}) = SurfaceLike()
conversion_trait(::Type{<: Contour{<: Tuple{X, Y, Z, Vol}}}) where {X, Y, Z, Vol} = VolumeLike()
conversion_trait(::Type{<: Contour{<: Tuple{<: AbstractArray{T, 3}}}}) where T = VolumeLike()


function plot!(plot::Contour{<: Tuple{X, Y, Z, Vol}}) where {X, Y, Z, Vol}
    x, y, z, volume = plot[1:4]
    @extract plot (color, levels, linewidth, alpha)
    valuerange = lift(nan_extrema, volume)
    cliprange = replace_automatic!(plot, :colorrange) do
        valuerange
    end
    cmap = lift(color, levels, linewidth, alpha, cliprange, valuerange) do _cmap, l, lw, alpha, cliprange, vrange
        levels = to_levels(l, vrange)
        nlevels = length(levels)
        N = nlevels * 50
        iso_eps = nlevels * ((vrange[2] - vrange[1]) / N) # TODO calculate this
        cmap = to_colormap(_cmap)
        v_interval = cliprange[1] .. cliprange[2]
        # resample colormap and make the empty area between iso surfaces transparent
        map(1:N) do i
            i01 = (i-1) / (N - 1)
            c = AbstractPlotting.interpolated_getindex(cmap, i01)
            isoval = vrange[1] + (i01 * (vrange[2] - vrange[1]))
            line = reduce(levels, init = false) do v0, level
                (isoval in v_interval) || return false
                v0 || (abs(level - isoval) <= iso_eps)
            end
            RGBAf0(Colors.color(c), line ? alpha : 0.0)
        end

    end
    volume!(
        plot, x, y, z, volume, colormap = cmap, colorrange = cliprange, algorithm = 7,
        transparency = plot[:transparency],
        overdraw = plot[:overdraw]
    )
end

function color_per_level(color, colormap, colorrange, alpha, levels)
    color_per_level(to_color(color), colormap, colorrange, alpha, levels)
end

function color_per_level(color::Colorant, colormap, colorrange, alpha, levels)
    fill(color, length(levels))
end

function color_per_level(colors::AbstractVector{<: Colorant}, colormap, colorrange, alpha, levels)
    if length(levels) == length(colors)
        return colors
    else
        # TODO resample?!
        error("For a contour plot, `color` with an array of colors needs to
        have the same length as `levels`.
        Found $(length(colors)) colors, but $(length(levels)) levels")
    end
end

function color_per_level(::Nothing, colormap, colorrange, a, levels)
    cmap = to_colormap(colormap)
    map(levels) do level
        c = interpolated_getindex(cmap, level, colorrange)
        RGBAf0(color(c), alpha(c) * a)
    end
end


function plot!(plot::T) where T <: Union{Contour, Contour3d}
    x, y, z = plot[1:3]
    if to_value(plot[:fillrange])
        plot[:interpolate] = true
        # TODO normalize linewidth for heatmap
        plot[:linewidth] = map(x-> x ./ 10f0, plot[:linewidth])
        heatmap!(plot, Theme(plot), x, y, z)
    else
        zrange = lift(nan_extrema, z)
        replace_automatic!(plot, :colorrange) do
            zrange
        end
        levels = lift(to_levels, plot[:levels], zrange)
        args = @extract plot (color, colormap, colorrange, alpha)
        level_colors = lift(color_per_level, args..., levels)
        result = lift(x, y, z, levels, level_colors) do x, y, z, levels, level_colors
            t = eltype(z)
            # Compute contours
            xv, yv = to_vector(x, size(z,1), t), to_vector(y, size(z,2), t)
            levels_t = convert(Vector{eltype(z)}, levels)
            contours = Contours.contours(xv, yv, z, levels_t)
            contourlines(T, contours, level_colors)
        end
        lines!(
            plot, lift(first, result);
            color = lift(last, result), linewidth = plot[:linewidth]
        )
    end
    plot
end

function AbstractPlotting.data_limits(x::Contour{<: Tuple{X, Y, Z}}) where {X, Y, Z}
    AbstractPlotting.xyz_boundingbox(to_value.((x[1], x[2]))...)
end


@recipe(VolumeSlices, x, y, z, volume) do scene
    Theme(
        colormap = theme(scene, :colormap),
        colorrange = nothing,
        alpha = 0.1,
        contour = Theme(),
        heatmap = Theme(),
    )
end

convert_arguments(::Type{<: VolumeSlices}, x, y, z, volume) = convert_arguments(Contour, x, y, z, volume)
function plot!(vs::VolumeSlices)
    @extract vs (x, y, z, volume)
    replace_automatic!(vs, :colorrange) do
        map(extrema, volume)
    end
    keys = (:colormap, :alpha, :colorrange)
    contour!(vs, vs[:contour], x, y, z, volume)
    planes = (:xy, :xz, :yz)
    hattributes = vs[:heatmap]
    sliders = map(zip(planes, (x, y, z))) do plane_r
        plane, r = plane_r
        idx = node(plane, Node(1))
        vs[plane] = idx
        hmap = heatmap!(vs, hattributes, x, y, zeros(length(x[]), length(y[]))).plots[end]
        on(idx) do i
            transform!(hmap, (plane, r[][i]))
            indices = ntuple(Val(3)) do j
                planes[j] == plane ? i : (:)
            end
            hmap[3][] = view(volume[], indices...)
        end
        idx
    end
    plot!(scene, vs, rest)
end

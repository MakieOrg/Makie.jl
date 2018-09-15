
@recipe(Poly) do scene
    Theme(;
        color = theme(scene, :color),
        visible = theme(scene, :visible),
        strokecolor = RGBAf0(0,0,0,0),
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        strokewidth = 0.0,
        linestyle = nothing,
    )
end
AbstractPlotting.convert_arguments(::Type{<: Poly}, v::AbstractVector{<: VecTypes}) = convert_arguments(Scatter, v)
AbstractPlotting.convert_arguments(::Type{<: Poly}, v::AbstractVector{<: Union{Circle, Rectangle}}) = (v,)
AbstractPlotting.convert_arguments(::Type{<: Poly}, args...) = convert_arguments(Scatter, args...)
AbstractPlotting.convert_arguments(::Type{<: Poly}, vertices::AbstractArray, indices::AbstractArray) = convert_arguments(Mesh, vertices, indices)

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

function plot!(plot::Poly{<: Tuple{<: AbstractVector{P}}}) where P
    positions = plot[1]
    bigmesh = lift(positions) do p
        polys = GeometryTypes.split_intersections(p)
        merge(GLPlainMesh.(polys))
    end
    mesh!(plot, bigmesh, color = plot[:color], visible = plot[:visible])
    outline = lift(positions) do p
        push!(copy(p), p[1]) # close path
    end
    lines!(
        plot, outline, visible = plot[:visible],
        color = plot[:strokecolor], linestyle = plot[:linestyle],
        linewidth = plot[:strokewidth],
    )
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
        map(x-> last.(x), headstart),
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

Theme(x::AbstractPlot) = x.attributes
# function wireframe(
#         geometry, data::Dict
#     )
#     points = const_lift(geometry) do g
#         decompose(Point3f0, g) # get the point representation of the geometry
#     end
#     # Get line index representation
#     indices = decompose(Face{2, GLIndex}, value(geometry))
#     data[:indices] = reinterpret(GLuint, indices)
#     _default(points, style"linesegment"(), data)
# end
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
    lines = map(directions, points, plot[:h], plot[:n]) do ∇ˢf, origins, h, n
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
            c = map(getindex, colors, Node(i))
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

function plot!(plot::Annotations)
    position = plot[2]
    sargs = (
        plot[:model], plot[:font],
        plot[1], position,
        getindex.(Ref(plot), (:color, :textsize, :align, :rotation))...,
    )
    N = value(position) |> eltype |> length
    tp = map(sargs...) do model, font, args...
        if length(args[1]) != length(args[2])
            error("For each text annotation, there needs to be one position. Found: $(length(t)) strings and $(length(p)) positions")
        end
        atlas = get_texture_atlas()
        io = IOBuffer(); combinedpos = Point{N, Float32}[]; colors = RGBAf0[]
        scales = Vec2f0[]; fonts = NativeFont[]; rotations = Quaternionf0[]; alignments = Vec2f0[]
        broadcast_foreach(1:length(args[1]), args...) do idx, text, startpos, color, tsize, alignment, rotation
            # the fact, that Font == Vector{FT_FreeType.Font} is pretty annoying for broadcasting.
            # TODO have a better Font type!
            f = to_font(font)
            f = isa(f, NativeFont) ? f : f[idx]
            c = to_color(color)
            rot = to_rotation(rotation)
            ali = to_align(alignment)
            pos, s = layout_text(text, startpos, tsize, f, alignment, rot, model)
            print(io, text)
            n = length(pos)
            append!(combinedpos, pos)
            append!(scales, s)
            append!(colors, repeated(c, n))
            append!(fonts,  repeated(f, n))
            append!(rotations, repeated(rot, n))
            append!(alignments, repeated(ali, n))
        end
        (String(take!(io)), combinedpos, colors, scales, fonts, rotations)
    end
    t_attributes = Attributes()
    t_attributes[:position] = map(x-> x[2], tp)
    t_attributes[:color] = map(x-> x[3], tp)
    t_attributes[:textsize] = map(x-> x[4], tp)
    t_attributes[:font] = map(x-> x[5], tp)
    t_attributes[:rotation] = map(x-> x[6], tp)
    t_attributes[:align] = Vec2f0(0)
    t_attributes[:model] = Mat4f0(I)
    t_attributes[:raw] = true
    text!(plot, t_attributes, map(x-> x[1], tp))
    plot
end

is2d(scene::SceneLike) = widths(limits(scene)[])[3] == 0.0

function scale_scene!(scene)
    area = pixelarea(scene)[]
    lims = data_limits(scene)
    # not really sure how to scale 3D scenes in a reasonable way
    mini, maxi = minimum(lims), maximum(lims)
    l = ((mini[1], maxi[1]), (mini[2], maxi[2]))
    xyzfit = fit_ratio(area, l)
    s = to_ndim(Vec3f0, xyzfit, 1f0)
    scale!(scene, s)
    force_update!()
    yield()
    return scene
end

function plot!(scene::SceneLike, subscene::AbstractPlot, attributes::Attributes)
    plot_attributes, rest = merged_get!(:plot, scene, attributes) do
        Theme(
            show_axis = true,
            show_legend = false,
            scale_plot = true,
            center = true,
            axis = Attributes(),
            legend = Attributes(),
            camera = automatic,
            limits = automatic,
            padding = Vec3f0(0.1),
            raw = false
        )
    end
    if plot_attributes[:raw][] == false
        s_limits = limits(scene)
        map_once(plot_attributes[:limits], plot_attributes[:padding]) do limit, padd
            if limit == automatic
                @info("calculating limits")
                @log_performance "calculating limits" begin
                    x = data_limits(scene)
                    # for when scene is empty
                    dlimits = if x == FRect3D(Vec3f0(0), Vec3f0(0))
                        data_limits(subscene)
                    else
                        union(x, data_limits(subscene))
                    end
                    lim_w = widths(dlimits)
                    padd_abs = lim_w .* Vec3f0(padd)
                    s_limits[] = FRect3D(minimum(dlimits) .- padd_abs, lim_w .+  2padd_abs)
                end
            else
                s_limits[] = FRect3D(limit)
            end
        end
        if plot_attributes[:show_axis][] && !(any(isaxis, plots(scene)))
            axis_attributes = plot_attributes[:axis]
            if is2d(scene)
                @info("Creating axis 2D")
                axis2d!(scene, axis_attributes, s_limits)
            else
                limits3d = map(s_limits) do l
                    mini, maxi = minimum(l), maximum(l)
                    tuple.(Tuple.((mini, maxi))...)
                end
                @info("Creating axis 3D")
                axis3d!(scene, axis_attributes, limits3d)
            end
        end
        # if plot_attributes[:show_legend][] && haskey(p.attributes, :colormap)
        #     legend_attributes = plot_attributes[:legend][]
        #     colorlegend(scene, p.attributes[:colormap], p.attributes[:colorrange], legend_attributes)
        # end
        if plot_attributes[:camera][] == automatic
            cam = cameracontrols(scene)
            if cam == EmptyCamera()
                if is2d(scene)
                    @info("setting camera to 2D")
                    cam2d!(scene)
                else
                    @info("setting camera to 3D")
                    cam3d!(scene)
                end
            end
        end
    end
    push!(scene.plots, subscene)
    value(plot_attributes[:center]) && center!(scene)
    scene
end

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
        width = nothing
    )
end

function data_limits(p::BarPlot)
    xy = p.plots[1][1][]
    msize = p.plots[1][:markersize][]
    xybb = FRect3D(xy)
    y = last.(msize) .+ last.(xy)
    bb = AbstractPlotting.xyz_boundingbox(first.(xy), y)
    union(bb, xybb)
end


convert_arguments(::Type{<: BarPlot}, x::AbstractVector{<: Number}, y::AbstractVector{<: Number}) = (x, y)
convert_arguments(::Type{<: BarPlot}, y::AbstractVector{<: Number}) = (1:length(y), y)

function AbstractPlotting.plot!(p::BarPlot)
    pos_scale = lift(p[1], p[2], p[:fillto], p[:width]) do x, y, fillto, hw
        nx, ny = length(x), length(y)
        cv = x
        x = if nx == ny
            cv
        elseif nx == ny + 1
            0.5diff(cv) + cv[1:end-1]
        else
            error("bar recipe: x must be same length as y (centers), or one more than y (edges).\n\t\tlength(x)=$(length(x)), length(y)=$(length(y))")
        end
        # compute half-width of bars
        if hw == nothing
            hw = mean(diff(x)) # TODO ignore nan?
        end
        # make fillto a vector... default fills to 0
        positions = Point2f0.(cv, Float32.(fillto))
        scales = Vec2f0.(abs.(hw), y)
        offset = Vec2f0.(hw ./ -2f0, 0)
        positions, scales, offset
    end
    scatter!(
        p, lift(first, pos_scale),
        marker = p[:marker], marker_offset = lift(last, pos_scale),
        markersize = lift(getindex, pos_scale, Node(2)),
        color = p[:color], colormap = p[:colormap], colorrange = p[:colorrange],
        transform_marker = true
    )
end

convert_arguments(P::Type{<:AbstractPlot}, f::Function) = convert_arguments(P, f, -5, 5)
convert_arguments(P::Type{<:AbstractPlot}, f::Function, r) = convert_arguments(P, r, f.(r))
convert_arguments(P::Type{<:AbstractPlot}, f::Function, min, max) =
    convert_arguments(P, f, PlotUtils.adapted_grid(f, (min, max)))

@recipe(ScatterLines) do scene
    Theme()
end

function plot!(scene::SceneLike, ::Type{<:ScatterLines}, attributes::Attributes, p...)
    plot!(scene, Lines, attributes, p...)
    plot!(scene, Scatter, attributes, p...)
    scene
end

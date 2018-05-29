@recipe(Arrows, points, directions) do scene
    theme = Theme(
        arrowhead = Pyramid(Point3f0(0, 0, -0.5), 1f0, 1f0),
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
    theme[:arrowcolor] = theme[:linecolor]
    theme
end

arrow_head(::Type{<: Point{3}}) = Pyramid(Point3f0(0, 0, -0.5), 1f0, 1f0)
arrow_head(::Type{<: Point{2}}) = '▲'

scatterfun(::Type{<: Point{2}}) = scatter!
scatterfun(::Type{<: Point{3}}) = meshscatter!


function plot!(arrowplot::Arrows)
    @extract arrowplot (points, directions, lengthscale, arrowhead, arrowsize, arrowcolor)
    headstart = lift(points, directions, lengthscale) do points, directions, s
        map(points, directions) do p1, dir
            dir = attributes[:normalize][] ? StaticArrays.normalize(dir) : dir
            p1 => p1 .+ (dir .* Float32(s))
        end
    end
    linesegments!(
        arrowplot, get(arrowplot, :color => :linecolor, :linewidth, :linestyle),
        map(reinterpret, Signal(Point3f0), headstart),
    )
    scatterfun(T)(
        arrowplot,
        get(arrowplot,
            marker = :arrowhead, markersize = :arrowsize,
            color = :arrowcolor, rotations = :directions
        ),
        map(x-> last.(x), headstart)
    )
end



@recipe(Wireframe) do scene
    default_theme(scene, LineSegments)
end

function argument_conversion(::Type{Wireframe}, x::AbstractVector, y::AbstractVector, z::AbstractMatrix)
    (ngrid(x, y)..., z)
end


"""
    wireframe(x, y, z) / wireframe(positions) / wireframe(mesh)
Draws a wireframe either interpreted as a surface or mesh
"""
function plot!(plot::Wireframe{Tuple{T, T, T}}) where T <: AbstractVector{<: VecTypes}
    points_faces = lift(getindex.(plot, (:x, :y, :z))) do x, y, z
        points = argument_convert(vec(x), vec(y), vec(z))
        NF = (length(z) * 4) - ((size(z, 1) + size(z, 2)) * 2)
        faces = Vector{Int}(NF)
        idx = (i, j) -> sub2ind(size(z), i, j)
        li = 1
        for i = 1:size(z, 1), j = 1:size(z, 2)
            if i < size(z, 1)
                faces[li] = idx(i, j);
                faces[li + 1] = idx(i + 1, j)
                li += 2
            end
            if j < size(z, 2)
                faces[li] = idx(i, j)
                faces[li + 1] = idx(i, j + 1)
                li += 2
            end
        end
        view(points, faces)
    end
    linesegment!(plot, plot, points_faces)
end


function plot!(plot::Wireframe{Tuple{T}}) where T
    points = lift(plot[1]) do g
        # get the point representation of the geometry
        indices = decompose(Face{2, GLIndex}, g)
        points = decompose(Point3f0, g)
        view(points, indices)
    end
    linesegment!(plot, plot, points)
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
    linesegments!(plot, plot, lines)
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
    replace_nothing!(vs, :colorrange) do
        map(extrema, volume)
    end
    keys = (:colormap, :alpha, :colorrange)
    contour!(vs, vs[:contour], x, y, z, volume)
    planes = (:xy, :xz, :yz)
    hattributes = vs[:heatmap]
    sliders = map(zip(planes, (x, y, z))) do plane_r
        plane, r = plane_r
        idx = node(plane, Signal(1))
        attributes[plane] = idx
        hmap = heatmap!(vs, hattributes, x, y, zeros(length(x[]), length(y[])))
        foreach(idx) do i
            transform!(hmap, (plane, r[][i]))
            indices = ntuple(Val{3}) do j
                planes[j] == plane ? i : (:)
            end
            hmap[3][] = view(volume[], indices...)
        end
        idx
    end
    plot!(scene, vs, rest)
end

@recipe(Series, series) do scene
    Theme(
        seriescolors = :Set1,
        seriestype = :lines
    )
end

function plot!(sub::Series)
    A = sub[:series]
    colors = map_once(sub[:seriescolors], A) do colors, A
        cmap = to_colormap(colors)
        if size(A, 2) > length(cmap)
            @info("Colormap doesn't have enough distinctive values. Please consider using another value for seriescolors")
            cmap = interpolated_getindex.((cmap,), linspace(0, 1, M))
        end
        cmap
    end
    plots = map_once(A, sub[:seriestype]) do A, stype
        empty!(sub.plots)
        N, M = size(A)
        map(1:M) do i
            c = map(getindex, colors, Node(i))
            attributes = Theme(color = c)
            subsub = Combined{:LineScatter}(sub, attributes, A)
            a_view = A[:, i]
            if stype in (:lines, :scatter_lines)
                lines!(subsub, attributes, a_view)
            end
            if stype in (:scatter, :scatter_lines)
                scatter!(subsub, attributes, a_view)
            end
            subsub
        end
    end
    labels = get(sub, :labels) do
        map(i-> "y $i", 1:size(matrix, 2))
    end
    legend!(sub, plots[], labels, rest)
    sub
end



"""
    annotations(strings::Vector{String}, positions::Vector{Point})

Plots an array of texts at each position in `positions`
"""
@recipe(Annotations, text, position) do scene
    default_theme(scene, Text)
end

function plot!(plot::Annotations)
    position = plot[2]
    sargs = (
        plot[:model], plot[:font],
        plot[1], position,
        getindex.(plot, (:color, :textsize, :align, :rotation))...,
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
        (String(take!(io)), combinedpos, colors, scales, fonts, rotations, rotations)
    end
    t_attributes = copy(plot.attributes)
    t_attributes[:position] = map(x-> x[2], tp)
    t_attributes[:color] = map(x-> x[3], tp)
    t_attributes[:textsize] = map(x-> x[4], tp)
    t_attributes[:font] = map(x-> x[5], tp)
    t_attributes[:rotation] = map(x-> x[6], tp)
    t_attributes[:align] = map(x-> x[7], tp)
    t_attributes[:model] = eye(Mat4f0)
    t_attributes[:raw] = true
    text!(plot, t_attributes, map(x-> x[1], tp))
    plot
end



is2d(scene::SceneLike) = widths(limits(scene)[])[3] == 0.0

function plot!(scene::SceneLike, subscene::AbstractPlot, attributes::Attributes)
    plot_attributes, rest = merged_get!(:plot, scene, attributes) do
        Theme(
            show_axis = true,
            show_legend = false,
            scale_plot = true,
            center = false,
            axis = Attributes(),
            legend = Attributes(),
            camera = :automatic,
            limits = :automatic,
            padding = Vec3f0(0.1),
            raw = false
        )
    end
    push!(scene.plots, subscene)
    if plot_attributes[:raw][] == false
        s_limits = limits(scene)
        map_once(plot_attributes[:limits], plot_attributes[:padding]) do limit, padd
            if limit == :automatic
                @info("calculating limits")
                @log_performance "calculating limits" begin
                    dlimits = data_limits(scene)
                    lim_w = widths(dlimits)
                    padd_abs = lim_w .* Vec3f0(padd)
                    s_limits[] = FRect3D(minimum(dlimits) .- padd_abs, lim_w .+  2padd_abs)
                end
            else
                s_limits[] = FRect3D(limit)
            end
        end
        area_widths = RefValue(widths(pixelarea(scene)[]))
        # map_once(pixelarea(scene), s_limits, plot_attributes[:scale_plot]) do area, limits, scaleit
        #     # not really sure how to scale 3D scenes in a reasonable way
        #     if scaleit && is2d(scene) # && area_widths[] != widths(area)
        #         area_widths[] = widths(area)
        #         mini, maxi = minimum(limits), maximum(limits)
        #         l = ((mini[1], maxi[1]), (mini[2], maxi[2]))
        #         xyzfit = fit_ratio(area, l)
        #         s = to_ndim(Vec3f0, xyzfit, 1f0)
        #         @info("calculated scaling: ", Tuple(s))
        #         scale!(scene, s)
        #     end
        #     return
        # end
        if plot_attributes[:show_axis][] && !(any(isaxis, plots(scene)))
            axis_attributes = plot_attributes[:axis][]
            if is2d(scene)
                limits2d = map(s_limits) do l
                    l2d = FRect2D(l)
                    Tuple.((minimum(l2d), maximum(l2d)))
                end
                @info("Creating axis 2D")
                axis2d!(scene, axis_attributes, limits2d)
            else
                limits3d = map(s_limits) do l
                    mini, maxi = minimum(l), maximum(l)
                    tuple.(Tuple.((mini, maxi))...)
                end
                @info("Creating axis 3D")
                axis3d!(scene, limits3d, axis_attributes)
            end
        end
        # if plot_attributes[:show_legend][] && haskey(p.attributes, :colormap)
        #     legend_attributes = plot_attributes[:legend][]
        #     colorlegend(scene, p.attributes[:colormap], p.attributes[:colorrange], legend_attributes)
        # end
        if plot_attributes[:camera][] == :automatic
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
    scene
end

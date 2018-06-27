"""
    contour(x, y, z)
Creates a contour plot of the plane spanning x::Vector, y::Vector, z::Matrix
"""
@recipe(Contour) do scene
    Theme(;
        default_theme(scene)...,
        colormap = theme(scene, :colormap),
        colorrange = nothing,
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
    Theme(;
        default_theme(scene)...,
        colormap = theme(scene, :colormap),
        colorrange = nothing,
        levels = 5,
        linewidth = 1.0,
        fillrange = false,
    )
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
function to_levels(x::Integer, cnorm)
    linspace(cnorm..., x)
end

function plot!(plot::Contour{<: Tuple{X, Y, Z, Vol}}) where {X, Y, Z, Vol}
    replace_nothing!(()-> Signal(0.5), plot, :alpha)
    x, y, z, volume = plot[1:4]
    @extract plot (colormap, levels, linewidth, alpha)
    colorrange = replace_nothing!(plot, :colorrange) do
        map(x-> Vec2f0(extrema(x)), volume)
    end
    cmap = lift(colormap, levels, linewidth, alpha, colorrange) do _cmap, l, lw, alpha, cnorm
        levels = to_levels(l, cnorm)
        N = length(levels) * 50
        iso_eps = 0.1 # TODO calculate this
        cmap = to_colormap(_cmap)
        # resample colormap and make the empty area between iso surfaces transparent
        map(1:N) do i
            i01 = (i-1) / (N - 1)
            c = AbstractPlotting.interpolated_getindex(cmap, i01)
            isoval = cnorm[1] + (i01 * (cnorm[2] - cnorm[1]))
            line = reduce(false, levels) do v0, level
                v0 || (abs(level - isoval) <= iso_eps)
            end
            RGBAf0(color(c), line ? alpha : 0.0)
        end
    end
    volume!(plot, x, y, z, volume, colormap = cmap, colorrange = colorrange, algorithm = :iso)
end

function plot!(plot::T) where T <: Union{Contour, Contour3d}
    x, y, z = plot[1:3]
    if value(plot[:fillrange])
        plot[:interpolate] = true
        # TODO normalize linewidth for heatmap
        plot[:linewidth] = map(x-> x ./ 10f0, plot[:linewidth])
        heatmap!(plot, plot.attributes, x, y, z)
    else
        result = lift(x, y, z, plot[:levels]) do x, y, z, levels
            t = eltype(z)
            levels = round(Int, levels)
            contours = Contours.contours(to_vector(x, size(z, 1), t), to_vector(y, size(z, 2), t), z, levels)
            cols = AbstractPlotting.resampled_colors(plot, levels)
            contourlines(T, contours, cols)
        end
        lines!(plot, lift(first, result); color = lift(last, result), raw = true)
    end
    plot
end

function AbstractPlotting.data_limits(x::Contour{<: Tuple{X, Y, Z}}) where {X, Y, Z}
    AbstractPlotting._boundingbox(value.((x[1], x[2]))...)
end


@recipe(Poly) do scene
    Theme(;
        color = theme(scene, :color),
        linecolor = RGBAf0(0,0,0,0),
        colormap = theme(scene, :colormap),
        colorrange = nothing,
        linewidth = 0.0,
        linestyle = nothing
    )
end
AbstractPlotting.convert_arguments(::Type{<: Poly}, v::AbstractVector{<: VecTypes}) = convert_arguments(Scatter, v)
AbstractPlotting.convert_arguments(::Type{<: Poly}, v::AbstractVector{<: Union{Circle, Rectangle}}) = (v,)
AbstractPlotting.convert_arguments(::Type{<: Poly}, args...) = convert_arguments(Mesh, args...)
AbstractPlotting.calculated_attributes!(plot::Poly) = plot

function plot!(plot::Poly{<: Tuple{Union{AbstractMesh, GeometryPrimitive}}})
    bigmesh = lift(GLNormalMesh, plot[1])
    mesh!(
        plot, bigmesh,
        color = plot[:color], colormap = plot[:colormap], colorrange = plot[:colorrange],
        shading = false
    )
    wireframe!(
        plot, bigmesh,
        color = plot[:linecolor], linestyle = plot[:linestyle],
        linewidth = plot[:linewidth],
    )
end

function plot!(plot::Poly{<: Tuple{<: AbstractVector{P}}}) where P
    positions = plot[1]
    bigmesh = lift(positions) do p
        polys = GeometryTypes.split_intersections(p)
        merge(GLPlainMesh.(polys))
    end
    mesh!(plot, bigmesh, color = plot[:color])
    outline = lift(positions) do p
        push!(copy(p), p[1]) # close path
    end
    lines!(
        plot, outline,
        color = plot[:linecolor], linestyle = plot[:linestyle],
        linewidth = plot[:linewidth],
    )
end

function plot!(plot::Poly{<: Tuple{<: AbstractVector{T}}}) where T <: Union{Circle, Rectangle}
    positions = plot[1]
    position = lift(positions) do rects
        map(rects) do rect
            Point(minimum(rect) .+ (widths(rect) ./ 2f0))
        end
    end
    markersize = lift(positions, name = "markersize") do rects
        widths.(rects)
    end
    scatter!(plot, position, marker = T, markersize = markersize)
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
        vs[plane] = idx
        hmap = heatmap!(vs, hattributes, x, y, zeros(length(x[]), length(y[]))).plots[end]
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

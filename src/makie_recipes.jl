"""
    contour(x, y, z)
Creates a contour plot of the plane spanning x::Vector, y::Vector, z::Matrix
"""
@recipe(Contour) do scene
    default = default_theme(scene)
    pop!(default, :color)
    Theme(;
        default...,
        color = theme(scene, :colormap),
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
function to_levels(x::Integer, cnorm)
    range(cnorm[1], stop = cnorm[2], length = x)
end
import AbstractPlotting: convert_arguments
convert_arguments(::Type{<: Contour3d}, args...) = convert_arguments(Heatmap, args...)
convert_arguments(::Type{<: Contour}, args...) = convert_arguments(Volume, args...)
convert_arguments(::Type{<: Contour}, data::AbstractMatrix) = convert_arguments(Heatmap, data)

function plot!(plot::Contour{<: Tuple{X, Y, Z, Vol}}) where {X, Y, Z, Vol}
    x, y, z, volume = plot[1:4]
    @extract plot (color, levels, linewidth, alpha)
    valuerange = lift(x-> Vec2f0(extrema(x)), volume)
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
    volume!(plot, x, y, z, volume, colormap = cmap, colorrange = cliprange, algorithm = 7)
end

function plot!(plot::T) where T <: Union{Contour, Contour3d}
    x, y, z = plot[1:3]
    if to_value(plot[:fillrange])
        plot[:interpolate] = true
        # TODO normalize linewidth for heatmap
        plot[:linewidth] = map(x-> x ./ 10f0, plot[:linewidth])
        heatmap!(plot, Theme(plot), x, y, z)
    else
        result = lift(x, y, z, plot[:levels]) do x, y, z, levels
            t = eltype(z)
            levels = round(Int, levels)
            contours = Contours.contours(to_vector(x, size(z, 2), t), to_vector(y, size(z, 1), t), z, levels)
            cols = AbstractPlotting.resampled_colors(plot, levels)
            contourlines(T, contours, cols)
        end
        lines!(plot, lift(first, result); color = lift(last, result), linewidth = plot[:linewidth])
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

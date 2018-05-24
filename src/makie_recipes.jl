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


"""
    contour3d(x, y, z)
Creates a contour plot of the plane spanning x::Vector, y::Vector, z::Matrix,
with z- elevation for each level
"""
function contourlines(::Type{Contour}, contours, cols)
    result = Point2f0[]
    colors = RGBA{Float32}[]
    for (color, c) in zip(cols, Main.Contour.levels(contours))
        for elem in Main.Contour.lines(c)
            append!(result, elem.vertices)
            push!(result, Point2f0(NaN32))
            append!(colors, fill(color, length(elem.vertices) + 1))
        end
    end
    result, colors
end

function contourlines(::Type{Contour3d}, contours, cols)
    result = Point3f0[]
    colors = RGBA{Float32}[]
    for (color, c) in zip(cols, Main.Contour.levels(contours))
        for elem in Main.Contour.lines(c)
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

function contourplot(scene::SceneLike, ::Type{Contour}, attributes::Attributes, x, y, z, vol)
    attributes, rest = merged_get!(:contour, scene, attributes) do
        default_theme(scene, Contour)
    end
    replace_nothing!(attributes, :alpha) do
        Signal(0.5)
    end
    xyz_volume = convert_arguments(Contour, x, y, z, vol)
    x, y, z, volume = node.((:x, :y, :z, :volume), xyz_volume)
    colorrange = replace_nothing!(attributes, :colorrange) do
        map(x-> Vec2f0(extrema(x)), volume)
    end
    @extract attributes (colormap, levels, linewidth, alpha)
    cmap = map(colormap, levels, linewidth, alpha, colorrange) do _cmap, l, lw, alpha, cnorm
        levels = to_levels(l, cnorm)
        N = length(levels) * 50
        iso_eps = 0.01 # TODO calculate this
        cmap = to_colormap(_cmap)
        # resample colormap and make the empty area between iso surfaces transparent
        map(1:N) do i
            i01 = (i-1) / (N - 1)
            c = interpolated_getindex(cmap, i01)
            isoval = cnorm[1] + (i01 * (cnorm[2] - cnorm[1]))
            line = reduce(false, levels) do v0, level
                v0 || (abs(level - isoval) <= iso_eps)
            end
            RGBAf0(color(c), line ? alpha : 0.0)
        end
    end
    c = Combined{:Contour}(scene, attributes, x, y, z, volume)
    volume!(c, x, y, z, volume, colormap = cmap, colorrange = colorrange, algorithm = :iso)
    plot!(scene, c, rest)
end

function contourplot(scene::SceneLike, ::Type{T}, attributes::Attributes, args...) where T
    attributes, rest = merged_get!(:contour, scene, attributes) do
        default_theme(scene, Contour)
    end
    x, y, z = convert_arguments(Contour, node.((:x, :y, :z), args)...)
    contourplot = Combined{:Contour}(scene, attributes, x, y, z)
    calculate_values!(contourplot, Contour, attributes, (x, y, z))
    t = eltype(z)
    if value(attributes[:fillrange])
        attributes[:interpolate] = true
        if T == Contour
            # TODO normalize linewidth for heatmap
            attributes[:linewidth] = map(x-> x ./ 10f0, attributes[:linewidth])
            heatmap!(contourplot, attributes, x, y, z)
        else
            surface!(contourplot, attributes, x, y, z)
        end
    else
        levels = round(Int, value(attributes[:levels]))
        contours = Main.Contour.contours(to_vector(x, size(z, 1), t), to_vector(y, size(z, 2), t), z, levels)
        cols = resampled_colors(attributes, levels)
        result, colors = contourlines(T, contours, cols)
        attributes[:color] = colors
        lines!(contourplot, merge(attributes, rest), result)
    end
    plot!(scene, contourplot, rest)
end

@recipe(Poly) do scene
    Theme(
        linecolor = RGBAf0(0,0,0,0),
        linewidth = 0.0,
        linestyle = nothing
    )
end

 function plot!(plot::Poly{Tuple{P}}) where P <: AbstractVector
    bigmesh = map(positions) do p
        polys = GeometryTypes.split_intersections(p)
        merge(GLPlainMesh.(polys))
    end
    mesh!(plot, bigmesh, color = plot[:color])
    outline = map(positions) do p
        push!(copy(p), p[1]) # close path
    end
    lines!(
        plot, outline,
        color = plot[:linecolor], linestyle = plot[:linestyle],
        linewidth = plot[:linewidth],
    )
    return plot!(scene, plot, rest)
end

function plot!(plot::Poly{Tuple{<: AbstractVector{T}}}) where T <: Union{Circle, Rectangle}
    position = map(positions) do rects
        map(rects) do rect
            minimum(rect) .+ (widths(rect) ./ 2f0)
        end
    end
    attributes[:markersize] = map(positions, name = :markersize) do rects
        widths.(rects)
    end
    attributes[:marker] = T
    scatter!(plot, attributes, position)
    plot
end


function layout_text(
        string::AbstractString, startpos::VecTypes{N, T}, textsize::Number,
        font, align, rotation, model
    ) where {N, T}

    offset_vec = to_align(align)
    ft_font = to_font(font)
    rscale = to_textsize(textsize)
    rot = to_rotation(rotation)

    atlas = GLVisualize.get_texture_atlas()
    mpos = model * Vec4f0(to_ndim(Vec3f0, startpos, 0f0)..., 1f0)
    pos = to_ndim(Point{N, Float32}, mpos, 0)

    positions2d = GLVisualize.calc_position(string, Point2f0(0), rscale, ft_font, atlas)
    aoffset = align_offset(Point2f0(0), positions2d[end], atlas, rscale, ft_font, offset_vec)
    aoffsetn = to_ndim(Point{N, Float32}, aoffset, 0f0)
    scales = Vec2f0[GLVisualize.glyph_scale!(atlas, c, ft_font, rscale) for c = string]
    positions = map(positions2d) do p
        pn = qmul(rot, to_ndim(Point{N, Float32}, p, 0f0) .+ aoffsetn)
        pn .+ (pos)
    end
    positions, scales
end

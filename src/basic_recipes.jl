
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
plot!(scene::SceneLike, t::Type{Contour}, attributes::Attributes, args...) = contourplot(scene, t, attributes, args...)
plot!(scene::SceneLike, t::Type{Contour3d}, attributes::Attributes, args...) = contourplot(scene, t, attributes, args...)

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


@recipe function poly(plot, rest, positions)
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

@recipe function poly(plot, rest, positions::AbstractVector{T}) where T <: Union{Circle, Rectangle}
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

function default_theme(scene, ::Type{Poly})
    Theme(;
        default_theme(scene)...,
        linecolor = RGBAf0(0,0,0,0),
        linewidth = 0.0,
        linestyle = nothing
    )
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



@recipe function annotations(scene, plot, rest, text, position)
    sargs = (
        plot[:model], plot[:font],
        text, position,
        getindex.(plot, (:color, :textsize, :align, :rotation))...,
    )
    tp = map(sargs...) do model, font, args...
        if length(args[1]) != length(args[2])
            error("For each text annotation, there needs to be one position. Found: $(length(t)) strings and $(length(p)) positions")
        end
        atlas = GLVisualize.get_texture_atlas()
        io = IOBuffer(); combinedpos = Point{N, Float32}[]; colors = RGBAf0[]
        scales = Vec2f0[]; fonts = Font[]; rotations = Vec4f0[]; alignments = Vec2f0[]
        broadcast_foreach(1:length(args[1]), args...) do idx, text, startpos, color, tsize, alignment, rotation
            # the fact, that Font == Vector{FT_FreeType.Font} is pretty annoying for broadcasting.
            # TODO have a better Font type!
            f = to_font(font)
            f = isa(f, Font) ? f : f[idx]
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
    t_attributes = merge(data(plot), rest)
    t_attributes[:position] = map(x-> x[2], tp)
    t_attributes[:color] = map(x-> x[3], tp)
    t_attributes[:textsize] = map(x-> x[4], tp)
    t_attributes[:font] = map(x-> x[5], tp)
    t_attributes[:rotation] = map(x-> x[6], tp)
    t_attributes[:align] = map(x-> x[7], tp)
    t_attributes[:model] = eye(Mat4f0)
    text!(plot, t_attributes, map(x-> x[1], tp))
    plot
end

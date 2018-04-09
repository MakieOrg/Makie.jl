function default_theme(scene, ::Type{Contour})
    Theme(;
        default_theme(scene)...,
        colormap = scene.theme[:colormap],
        levels = 5,
        linewidth = 1.0,
        fillrange = false,
    )
end

to_vector(x::AbstractVector, len, T) = convert(Vector{T}, x)
to_vector(x::ClosedInterval, len, T) = linspace(T.(extrema(x))..., len)

function resample(x::AbstractVector, len)
    length(x) == len && return x
    interpolated_getindex.((x,), linspace(0.0, 1.0, len))
end

function plot!(scene::Scene, ::Type{Contour}, attributes::Attributes, args...)
    attributes, rest = merged_get!(:contour, scene, attributes) do
        default_theme(scene, Contour)
    end
    calculate_values!(scene, Contour, attributes, args)
    T = eltype(last(args))
    x, y, z = convert_arguments(Contour, args...)
    contourplot = Combined{:Contour}(scene, attributes, x, y, z)
    if value(attributes[:fillrange])
        attributes[:interpolate] = true
        heatmap!(contourplot, attributes, x, y, z)
    else
        levels = round(Int, value(attributes[:levels]))
        T = eltype(z)
        contours = Main.Contour.contours(to_vector(x, size(z, 1), T), to_vector(y, size(z, 2), T), z, levels)
        result = Point2f0[]
        colors = RGBA{Float32}[]
        cols = if haskey(attributes, :color)
            c = attribute_convert(value(attributes[:color]), key"color"())
            repeated(c, levels)
        else
            c = attribute_convert(value(attributes[:colormap]), key"colormap"())
            resample(c, levels)
        end
        for (color, c) in zip(cols, Main.Contour.levels(contours))
            for elem in Main.Contour.lines(c)
                append!(result, elem.vertices)
                push!(result, Point2f0(NaN32))
                append!(colors, fill(color, length(elem.vertices) + 1))
            end
        end
        attributes[:color] = colors
        lines!(contourplot, merge(attributes, rest), result)
    end
    contourplot
end


function plot!(scene::Scene, ::Type{Poly}, attributes::Attributes, positions::AbstractVector{<: VecTypes{2, T}}) where T <: AbstractFloat
    attributes, rest = merged_get!(:poly, scene, attributes) do
        Theme(;
            default_theme(scene)...,
            linecolor = RGBAf0(0,0,0,0),
            linewidth = 0.0,
            linestyle = nothing
        )
    end
    positions_n = to_node(positions)
    bigmesh = map(positions_n) do p
        polys = GeometryTypes.split_intersections(p)
        merge(GLPlainMesh.(polys))
    end
    poly = Combined{:Poly}(scene, attributes, positions_n)
    mesh!(poly, bigmesh, color = attributes[:color])
    outline = map(positions_n) do p
        push!(copy(p), p[1]) # close path
    end
    lines!(
        poly, outline,
        color = attributes[:linecolor], linestyle = attributes[:linestyle],
        linewidth = attributes[:linewidth],
        visible = map(x-> x > 0.0, attributes[:linewidth])
    )
    return poly
end
# function poly(scene::makie, points::AbstractVector{Point2f0}, attributes::Dict)
#     attributes[:positions] = points
#     _poly(scene, attributes)
# end
# function poly(scene::makie, x::AbstractVector{<: Number}, y::AbstractVector{<: Number}, attributes::Dict)
#     attributes[:x] = x
#     attributes[:y] = y
#     _poly(scene, attributes)
# end
function plot!(scene::Scene, ::Type{Poly}, attributes::Attributes, x::AbstractVector{T}) where T <: Union{Circle, Rectangle}
    position = map(to_node(x)) do rects
        map(rects) do rect
            minimum(rect) .+ (widths(rect) ./ 2f0)
        end
    end
    attributes[:markersize] = lift_node(to_node(x)) do rects
        widths.(rects)
    end
    attributes[:marker] = T
    poly = Combined{:Poly}(scene, attributes, x)
    plot!(poly, Scatter, attributes, position)
    poly
end

function layout_text(
        string::AbstractString, startpos::VecTypes{N, T}, textsize::Number,
        font, align, rotation, model
    ) where {N, T}

    offset_vec = attribute_convert(align, key"align"())
    ft_font = attribute_convert(font, key"font"())
    rscale = attribute_convert(textsize, key"textsize"())
    rot = attribute_convert(rotation, key"rotation"())

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


function plot!(scene::Scenelike, ::Type{Annotations}, attributes::Attributes, text::AbstractVector{String}, positions::AbstractVector{<: VecTypes{N, T}}) where {N, T}
    attributes, rest = merged_get!(:annotations, scene, attributes) do
        default_theme(scene, Text)
    end

    calculate_values!(scene, Text, attributes, text)
    t_args = (to_node(text), to_node(positions))
    annotations = Combined{:Annotations}(scene, attributes, t_args...)
    sargs = (
        attributes[:model], attributes[:font],
        t_args...,
        getindex.(attributes, (:color, :textsize, :align, :rotation))...,
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
            f = attribute_convert(font, key"font"())
            f = isa(f, Font) ? f : f[idx]
            c = attribute_convert(color, key"color"())
            rot = attribute_convert(rotation, key"rotation"())
            ali = attribute_convert(alignment, key"align"())
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
    t_attributes = merge(attributes, rest)
    t_attributes[:position] = map(x-> x[2], tp)
    t_attributes[:color] = map(x-> x[3], tp)
    t_attributes[:textsize] = map(x-> x[4], tp)
    t_attributes[:font] = map(x-> x[5], tp)
    t_attributes[:rotation] = map(x-> x[6], tp)
    t_attributes[:align] = map(x-> x[7], tp)
    t_attributes[:model] = eye(Mat4f0)
    plot!(annotations, Text, t_attributes, map(x->x[1], tp))
    annotations
end



function plot!(scene::Scene, attributes::Attributes, matrix::AbstractMatrix{<: AbstractFloat})
    attributes, rest = merged_get!(:series, scene, attributes) do
        Theme(
            seriescolors = :Set1,
            seriestype = :lines
        )
    end
    A = node(:series, matrix)
    sub = Combined{:Series}(scene, attributes, A)
    colors = map_once(attributes[:seriescolors], A) do colors, A
        cmap = attribute_convert(colors, key"colormap"())
        if size(A, 2) > length(cmap)
            warn("Colormap doesn't have enough distinctive values. Please consider using another value for seriescolors")
            cmap = interpolated_getindex.((cmap,), linspace(0, 1, M))
        end
        cmap
    end
    plots = map_once(A, attributes[:seriestype]) do A, stype
        empty!(sub.plots)
        N, M = size(A)
        map(1:M) do i
            # subsub = Scene(sub)
            c = map(getindex, colors, Node(i))
            if stype in (:lines, :scatter_lines)
                lines!(sub, 1:N, A[:, i], color = c, raw = true)
            end
            if stype in (:scatter, :scatter_lines)
                scatter!(subsub, 1:N, A[:, i], color = c, raw = true)
            end
            subsub
        end
    end
    labels = get(attributes, :labels) do
        map(i-> "y $i", 1:size(matrix, 2))
    end
    l = legend(scene, plots[], labels, rest)
    plot!(scene, sub, rest)
end

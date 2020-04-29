################################################################################
#                             Lines, LineSegments                              #
################################################################################

function draw_atomic(scene::Scene, screen::CairoScreen, primitive::Union{Lines, LineSegments})
    fields = @get_attribute(primitive, (color, linewidth, linestyle))
    linestyle = AbstractPlotting.convert_attribute(linestyle, AbstractPlotting.key"linestyle"())
    ctx = screen.context
    model = primitive[:model][]
    positions = primitive[1][]

    isempty(positions) && return

    # workaround for a LineSegments object created from a GLNormalMesh
    # the input argument is a view of points using faces, which results in
    # a vector of tuples of two points. we convert those to a list of points
    # so they don't trip up the rest of the pipeline
    # TODO this shouldn't be necessary anymore!
    if positions isa SubArray{<:Point3, 1, P, <:Tuple{Array{<:AbstractFace}}} where P
        positions = let
            pos = Point3f0[]
            for tup in positions
                push!(pos, tup[1])
                push!(pos, tup[2])
            end
            pos
        end
    end

    projected_positions = project_position.(Ref(scene), positions, Ref(model))

    if color isa AbstractArray{<: Number}
        color = numbers_to_colors(color, primitive)
    end

    # color is now a color or an array of colors
    # if it's an array of colors, each segment must be stroked separately

    # linestyle can be set globally
    !isnothing(linestyle) && Cairo.set_dash(ctx, linestyle)

    if color isa AbstractArray || linewidth isa AbstractArray
        # stroke each segment separately, this means disjointed segments with probably
        # wonky dash patterns if segments are short

        # we can hide the gaps by setting the line cap to round
        Cairo.set_line_cap(ctx, Cairo.CAIRO_LINE_CAP_ROUND)
        draw_multi(primitive, ctx, projected_positions, color, linewidth)
    else
        # stroke the whole line at once if it has only one color
        # this allows correct linestyles and line joins as well and will be the
        # most common case
        Cairo.set_line_width(ctx, linewidth)
        Cairo.set_source_rgba(ctx, red(color), green(color), blue(color), alpha(color))
        draw_single(primitive, ctx, projected_positions)
    end
    nothing
end

function draw_single(primitive::Lines, ctx, positions)
    Cairo.move_to(ctx, positions[1]...)
    for i in 2:length(positions)
        if isnan(positions[i])
            i == length(positions) && break
            Cairo.move_to(ctx, positions[i+1]...)
        else
            Cairo.line_to(ctx, positions[i]...)
        end
    end
    Cairo.stroke(ctx)
end

function draw_single(primitive::LineSegments, ctx, positions)
    @assert iseven(length(positions))
    Cairo.move_to(ctx, positions[1]...)
    for i in 2:length(positions)
        if iseven(i)
            Cairo.line_to(ctx, positions[i]...)
        else
            Cairo.move_to(ctx, positions[i]...)
        end
    end
    Cairo.stroke(ctx)
end

# if linewidth is not an array
function draw_multi(primitive, ctx, positions, colors::AbstractArray, linewidth)
    draw_multi(primitive, ctx, positions, colors, [linewidth for c in colors])
end

# if color is not an array
function draw_multi(primitive, ctx, positions, color, linewidths::AbstractArray)
    draw_multi(primitive, ctx, positions, [color for l in linewidths], linewidths)
end

function draw_multi(primitive::Union{Lines, LineSegments}, ctx, positions, colors::AbstractArray, linewidths::AbstractArray)
    if primitive isa LineSegments
        @assert iseven(length(positions))
    end
    @assert length(positions) == length(colors)
    @assert length(linewidths) == length(colors)

    iterator = if primitive isa Lines
        1:length(positions)-1
    elseif primitive isa LineSegments
        1:2:length(positions)
    end

    for i in iterator
        if isnan(positions[i+1]) || isnan(positions[i])
            continue
        end
        Cairo.move_to(ctx, positions[i]...)

        Cairo.line_to(ctx, positions[i+1]...)
        if linewidths[i] != linewidths[i+1]
            error("Cairo doesn't support two different line widths ($(linewidths[i]) and $(linewidths[i+1])) at the endpoints of a line.")
        end
        Cairo.set_line_width(ctx, linewidths[i])
        c1 = colors[i]
        c2 = colors[i+1]
        # we can avoid the more expensive gradient if the colors are the same
        # this happens if one color was given for each segment
        if c1 == c2
            Cairo.set_source_rgba(ctx, red(c1), green(c1), blue(c1), alpha(c1))
            Cairo.stroke(ctx)
        else
            pat = Cairo.pattern_create_linear(positions[i]..., positions[i+1]...)
            Cairo.pattern_add_color_stop_rgba(pat, 0, red(c1), green(c1), blue(c1), alpha(c1))
            Cairo.pattern_add_color_stop_rgba(pat, 1, red(c2), green(c2), blue(c2), alpha(c2))
            Cairo.set_source(ctx, pat)
            Cairo.stroke(ctx)
            Cairo.destroy(pat)
        end
    end
end


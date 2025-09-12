"""
    waterfall(x, y; kwargs...)

Plots a [waterfall chart](https://en.wikipedia.org/wiki/Waterfall_chart) to visualize individual
positive and negative components that add up to a net result as a barplot with stacked bars next
to each other.
"""
@recipe Waterfall begin
    color = @inherit patchcolor
    dodge = automatic
    n_dodge = automatic
    gap = 0.2
    dodge_gap = 0.03
    width = automatic
    cycle = [:color => :patchcolor]
    stack = automatic
    show_direction = false
    marker_pos = :utriangle
    marker_neg = :dtriangle
    direction_color = @inherit backgroundcolor
    show_final = false
    final_color = plot_color(:grey90, 0.5)
    final_gap = automatic
    final_dodge_gap = 0
end

conversion_trait(::Type{<:Waterfall}) = PointBased()

function Makie.plot!(p::Waterfall)
    function stack_bars(xy, dodge, stack)
        x, y = first.(xy), last.(xy)
        if stack === automatic
            stack = dodge === automatic ? :x : :dodge
        end
        i_dodge = dodge === automatic ? ones(Int, length(x)) : dodge
        i_stack, i_group = stack === :dodge ? (i_dodge, x) : (x, i_dodge)
        xy = similar(xy)
        fillto = similar(x)
        final = similar(xy)
        groupby = StructArray(; grp = i_group)
        for (grp, inds) in StructArrays.finduniquesorted(groupby)
            fromto = stack_from_to_final(i_stack[inds], y[inds])
            fillto[inds] .= fromto.from
            xy[inds] .= Point2f.(x[inds], fromto.to)
            final[inds] .= Point2f.(x[inds], fromto.final)
        end
        return xy, fillto, final
    end

    map!(stack_bars, p, [:converted_1, :dodge, :stack], [:xy, :fillto, :final])

    map!(p, [:final_gap, :gap, :dodge], :computed_final_gap) do final_gap, gap, dodge
        return final_gap === automatic ? (dodge == automatic ? 0 : gap) : final_gap
    end

    # TODO: change to use `visible` after bounding box issue is fixed (see https://github.com/MakieOrg/Makie.jl/pull/5184#issuecomment-3191231795)
    if p.show_final[]
        barplot!(
            p, p.final;
            dodge = p.dodge,
            color = p.final_color,
            dodge_gap = p.final_dodge_gap,
            gap = p.computed_final_gap,
        )
    end

    barplot!(p, p.attributes, p.xy; fillto = p.fillto, stack = automatic)

    function direction_markers(
            xy, fillto, marker_pos, marker_neg, width,
            gap, dodge, n_dodge, dodge_gap
        )
        xs = first(compute_x_and_width(first.(xy), width, gap, dodge, n_dodge, dodge_gap))
        MarkerType = promote_type(typeof(marker_pos), typeof(marker_neg))
        PointType = eltype(xy)
        shapes = MarkerType[]
        scatter_xy = PointType[]
        for i in eachindex(xs)
            y = last(xy[i])
            fto = fillto[i]
            if fto > y
                push!(scatter_xy, (xs[i], (y + fto) / 2))
                push!(shapes, marker_neg)
            elseif fto < y
                push!(scatter_xy, (xs[i], (y + fto) / 2))
                push!(shapes, marker_pos)
            end
        end
        return scatter_xy, shapes
    end

    map!(
        direction_markers, p,
        [:xy, :fillto, :marker_pos, :marker_neg, :width, :gap, :dodge, :n_dodge, :dodge_gap],
        [:scatter_xy, :shapes]
    )

    if p.show_direction[]
        scatter!(p, p.scatter_xy; marker = p.shapes, color = p.direction_color)
    end

    return p
end

function stack_from_to_final(i_stack, y)
    order = 1:length(y) # save current order
    perm = sortperm(i_stack) # sort by i_stack
    inv_perm = sortperm(order[perm]) # restore original order
    from, to = stack_from_to_sorted(view(y, perm))
    return (from = view(from, inv_perm), to = view(to, inv_perm), final = last(to))
end

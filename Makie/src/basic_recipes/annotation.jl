baremodule Ann # bare for cleanest tab-completion behavior

    using Base
    baremodule Paths

        using Base

        struct Line end
        struct Corner end
        Base.@kwdef struct Arc
            height::Float64 = 0.5 # positive numbers are arcs going up then down, negative down then up, 1 is half circle
        end

    end

    baremodule Arrows

        using Base

        using ...Makie

        Base.@kwdef struct Line
            length::Float64 = 8.0
            angle::Float64 = deg2rad(60)
            color = Makie.automatic
            linewidth::Union{Makie.Automatic, Float64} = Makie.automatic
        end

        Base.@kwdef struct Head
            length::Float64 = 8.0
            angle::Float64 = deg2rad(60)
            color = Makie.automatic
            notch::Float64 = 0 # 0 to 1
        end
    end

    baremodule Styles

        using Base

        using ..Arrows: Arrows
        using ...Makie: Makie

        struct Line end

        Base.@kwdef struct LineArrow
            head = Arrows.Line()
            tail = nothing
        end

        """
            Ann.Styles.WithText(style; text, ...)

        Wraps another annotation `style` and additionally draws `text` along the
        connection path using `pathtext`. The inner `style` is rendered first,
        then the text is layered on top so it follows the same curve.
        """
        struct WithText
            style::Any
            text::Any
            fontsize::Float64
            align::Any
            offset::Float64
            color::Any
        end
        function WithText(
                style;
                text = "",
                fontsize = 12.0,
                align = (:center, :bottom),
                offset = 4.0,
                color = Makie.automatic,
            )
            return WithText(style, text, Float64(fontsize), align, Float64(offset), color)
        end

    end
end

using .Ann

"""
    annotation(x_target, y_target)
    annotation(x_label, y_label, x_target, y_target)
    annotation(points_target)
    annotation(points_label, points_target)

Annotate one or more target points with a combination of optional text labels and
connections between labels and targets, typically in the form of an arrow.

If no label positions are given, they will be determined automatically such
that overlaps between labels and data points are reduced. In this mode, the labels should
be very close to their associated data points so connection plots are typically not visible.
"""
@recipe Annotation (label_offsets_or_positions::Vector{<:Vec2}, target_positions::Vector{<:Point2}) begin
    """
    The color of the text labels. If `automatic`, `textcolor` matches `color`.
    """
    textcolor = automatic
    """
    The basic color of the connection object. For more fine-grained adjustments, modify the `style` object directly.
    """
    color = @inherit linecolor
    """
    One object or an array of objects that determine the textual content of the labels.
    """
    text = ""
    """
    Sets the font. Can be a `Symbol` which will be looked up in the `fonts` dictionary or a `String` specifying the (partial) name of a font or the file path of a font file.
    """
    font = @inherit font
    """
    Used as a dictionary to look up fonts specified by `Symbol`, for example `:regular`, `:bold` or `:italic`.
    """
    fonts = @inherit fonts
    """
    The size of the label font.
    """
    fontsize = @inherit fontsize
    """
    The alignment of text relative to the label anchor position.
    """
    align = (:center, :center)
    """
    Sets the alignment of text w.r.t its bounding box. Can be `:left, :center, :right` or a fraction. Will default to the horizontal alignment in `align`.
    """
    justification = automatic
    """
    The lineheight multiplier.
    """
    lineheight = 1.0
    """
    One path type or an array of path types that determine how to connect each label to its point.
    Suitable objects can be found in the module `Ann.Paths`.
    """
    path = Ann.Paths.Line()
    """
    One style object or an array of style objects that determine how the path from a label to its point
    is visualized. Suitable objects can be found in the module `Ann.Styles`.
    """
    style = automatic
    """
    One tuple or an array of tuples with two numbers, where each number specifies the radius of a circle
    in screen space which clips the connection path at the start or end, respectively, to add a
    little bit of visual space between arrow and label or target.
    """
    shrink = (5.0, 7.0)
    """
    Determines which object is used to clip the path at the start. If set to `automatic`, the
    boundingbox of the text label is used.
    """
    clipstart = automatic
    """
    The maximum number of iterations that the label placement algorithm is allowed to run.
    With `maxiter = 0`, labels stay at their target positions or given offsets.
    """
    maxiter = automatic
    """
    The space in which the label positions are given. Can be `:relative_pixel` (the positions are given in
    screen space relative to the target data positions) or `:data`. If a text label should be positioned
    somewhere close to the labeled point, `:relative_pixel` is usually easier to get a consistent visual result.
    If an arrow is supposed to point from one data point to another, `:data` is the appropriate choice.
    """
    labelspace = :relative_pixel
    "The default line width for connection styles that have lines"
    linewidth = 1.0
    """
    The algorithm used to automatically place labels with reduced overlaps. `automatic` uses
    `Makie.CandidatePlacement()`.
    The positioning of the labels with a given input may change between non-breaking versions.
    """
    algorithm = automatic
    "Controls whether the plot gets rendered or not."
    visible = true
end

function convert_arguments(::Type{<:Annotation}, x::Real, y::Real)
    return [Vec2d(NaN)], [Vec2d(x, y)]
end

function convert_arguments(::Type{<:Annotation}, p::VecTypes{2})
    return [Vec2d(NaN)], [Point2d(p...)]
end

function convert_arguments(::Type{<:Annotation}, x::Real, y::Real, x2::Real, y2::Real)
    return [Vec2d(x, y)], [Point2d(x2, y2)]
end

function convert_arguments(::Type{<:Annotation}, p1::VecTypes{2}, p2::VecTypes{2})
    return [Vec2d(p1...)], [Point2d(p2...)]
end

function convert_arguments(::Type{<:Annotation}, v::AbstractVector{<:VecTypes{2}})
    N = length(v)
    return fill(Vec2d(NaN), N), Point2d.(getindex.(v, 1), getindex.(v, 2))
end

function convert_arguments(::Type{<:Annotation}, v1::AbstractVector{<:VecTypes{2}}, v2::AbstractVector{<:VecTypes{2}})
    return Vec2d.(getindex.(v1, 1), getindex.(v1, 2)), Point2d.(getindex.(v2, 1), getindex.(v2, 2))
end

function convert_arguments(::Type{<:Annotation}, v1::AbstractVector{<:Real}, v2::AbstractVector{<:Real})
    N = length(v1)
    return fill(Vec2d(NaN), N), Point2d.(v1, v2)
end

function convert_arguments(::Type{<:Annotation}, v1::AbstractVector{<:Real}, v2::AbstractVector{<:Real}, v3::AbstractVector{<:Real}, v4::AbstractVector{<:Real})
    return Vec2d.(v1, v2), Point2d.(v3, v4)
end

# still without offset
# Empty strings produce non-finite Rect3d() bounding boxes, replace with zero-size rects
_guard_nonfinite(bb) = isfinite_rect(bb) ? bb : Rect2d(0, 0, 0, 0)

function plot!(p::Annotation)
    map!(default_automatic, p, [:textcolor, :color], :computed_textcolor)

    txt = text!(
        p,
        p.target_positions;
        text = p.text,
        align = p.align,
        offset = zeros(Vec2f, length(p.target_positions[])),
        color = p.computed_textcolor,
        font = p.font,
        fonts = p.fonts,
        fontsize = p.fontsize,
        justification = p.justification,
        lineheight = p.lineheight,
        visible = p.visible,
    )

    # ink bounding boxes per string, excluding `offsets` (including them here
    # would error when input lengths change as they do not get resized beforehand)
    register_ink_string_boundingboxes!(txt)

    add_constant!(p.attributes, :space, :data)
    register_projected_positions!(
        p, Point2f, input_name = :target_positions,
        output_name = :screenpoints_target, output_space = :pixel
    )

    map!(p, [txt.ink_string_boundingboxes, p.screenpoints_target], :text_bbs) do bboxes, px_pos
        return _guard_nonfinite.(Rect2d.(bboxes)) .+ px_pos
    end

    register_camera_matrix!(p, :data, :pixel)
    inputs = [
        :screenpoints_target, :labelspace, :label_offsets_or_positions,
        :world_to_pixel, :f32c, :model, :transform_func,
    ]
    register_computation!(
        p.attributes, inputs, [:screenpoints_label]
    ) do (tps, space, loffpos, proj, f32c, model, tf), changed, cached
        if space === :relative_pixel
            if isnothing(cached) || changed[1] || changed[2] || changed[3]
                return (tps .+ loffpos,)
            else
                # Skip updates from camera and transform func
                return (nothing,)
            end
        else
            transformed_label_pos = apply_transform(tf, loffpos)
            f32c_mat = f32_convert_matrix(f32c)
            return (_project(Point2f, proj * f32c_mat * model, transformed_label_pos),)
        end
    end

    add_input!(p.attributes, :viewport, parent_scene(p).compute[:viewport])

    # To make offsets accessible in plot attributes and get good synchronization
    # we create a compute node here and an Observable later
    inputs = [
        :algorithm, :screenpoints_target, :screenpoints_label, :text_bbs,
        :viewport, :maxiter, :shrink,
    ]
    register_computation!(p.attributes, inputs, [:offsets, :placement_view]) do args, changed, cached
        offsets = isnothing(cached) ? Vec2f[] : cached[1]
        view = placement_view(args.screenpoints_target, args.viewport)
        # keep the previous layout as a warm start across small view changes,
        # so zooming and panning only move labels that have to move
        reset = isnothing(cached) || length(offsets) != length(args.screenpoints_target) ||
            changed.algorithm || !similar_view(cached[2], view)
        resize!(offsets, length(args.screenpoints_target))

        calculate_best_offsets!(
            args.algorithm,
            offsets,
            args.screenpoints_target,
            args.screenpoints_label,
            args.text_bbs,
            Rect2d((0, 0), widths(args.viewport));
            maxiter = args.maxiter,
            reset,
            leaderthreshold = sum(args.shrink) + maximum(args.shrink),
        )

        return (offsets, view)
    end

    # create observable updating offsets in text plot
    # This forces everything offsets rely on to update asap, before the backend pulls
    on(offsets -> update!(txt, offset = offsets), p.offsets, update = true)

    inputs = [
        :text_bbs, :screenpoints_target, :offsets, :path, :clipstart, :shrink,
        :style, :color, :linewidth,
    ]
    map!(p, inputs, :plotspecs) do text_bbs, points, offsets, path, clipstart, shrink, style, color, linewidth
        specs = PlotSpec[]
        broadcast_foreach(text_bbs, points, clipstart, offsets) do text_bb, p2, clipstart, offset
            offset_bb = text_bb + offset

            (p2 in offset_bb || rect_point_distance(offset_bb, p2) < sum(shrink)) && return
            p1 = startpoint(path, offset_bb, p2)
            _path = connection_path(path, p1, p2)

            clipstart = if clipstart === automatic
                offset_bb
            else
                clipstart
            end
            clipped_path = clip_path_from_start(_path, clipstart)

            shrunk_path = shrink_path(clipped_path, shrink)
            is_stub(shrunk_path, maximum(shrink)) && return

            append!(specs, annotation_style_plotspecs(style, shrunk_path, p1, p2; color, linewidth))
        end
        return specs
    end

    # TODO: passing dynamic attributes doesn't work (visible)
    plotlist!(p, p.plotspecs; visible = p.visible[])

    return p
end

# like `register_raw_string_boundingboxes!` but with the ink extent of each glyph instead of its
# ascender, descender and advance, so that labels hug their visible shape
function register_ink_string_boundingboxes!(plot)
    inputs = [
        :text_blocks, :glyphindices, :text_scales, :glyph_extents, :glyph_origins, :text_rotation,
        :linesegments, :linewidths, :lineindices,
    ]
    map!(plot.attributes, inputs, :ink_string_boundingboxes) do blocks, glyphs, scales, extents, origins, rotation, segments, linewidths, lineindices
        text_bbs = map(blocks) do idxs
            output = Rect3d()
            for i in idxs
                glyphs[i] == 0 && continue
                ink = extents[i].ink_bounding_box
                scale = sv_getindex(scales, i)
                glyphbb = Rect3d(to_ndim(Point3d, origin(ink) .* scale, 0), to_ndim(Vec3d, widths(ink) .* scale, 0))
                output = update_boundingbox(output, rotate_bbox(glyphbb, rotation[i]) + origins[i])
            end
            return output
        end
        for (pos, lw, (block_idx, glyph_idx)) in zip(segments, linewidths, lineindices)
            bb = Rect3d(to_ndim(Point3d, pos, 0) .- 0.5lw, Vec3d(lw))
            text_bbs[block_idx] = update_boundingbox(text_bbs[block_idx], bb)
        end
        return text_bbs
    end
    return plot.ink_string_boundingboxes
end

function calculate_best_offsets!(
        algorithm, offsets::Vector{<:Vec2}, textpositions::Vector{<:Point2}, textpositions_offset::Vector{<:Point2}, text_bbs::Vector{<:Rect2}, bbox::Rect2;
        maxiter::Union{Automatic, Int},
        reset::Bool,
        leaderthreshold::Real,
    )
    if !(length(offsets) == length(textpositions) == length(textpositions_offset) == length(text_bbs))
        error(
            """
            Mismatching array sizes:
                - offsets: $(length(offsets))
                - textpositions: $(length(textpositions))
                - textpositions_offset: $(length(textpositions_offset))
                - text_bbs: $(length(text_bbs))
            """
        )
    end

    if reset
        offsets .= zero.(eltype(offsets))
    end

    fixed = Vec2d.(textpositions_offset .- textpositions)
    for i in eachindex(offsets)
        is_fixed(fixed[i]) && (offsets[i] = fixed[i])
    end
    all(is_fixed, fixed) && return
    # giving one component of the position could be cool, like only x in data space, but this
    # doesn't really work because projection into screen space needs x and y together

    algorithm = algorithm === automatic ? CandidatePlacement() : algorithm
    return place_labels!(algorithm, offsets, textpositions, text_bbs, bbox, fixed; maxiter, reset, leaderthreshold)
end

is_fixed(offset::Vec2) = !any(isnan, offset)

function placement_view(targets, viewport)
    finite = filter(t -> all(isfinite, t), targets)
    bbox = isempty(finite) ? Rect2d(0, 0, 0, 0) : Rect2d(finite)
    return (bbox = bbox, size = Vec2d(widths(viewport)))
end

function similar_view(old, new)
    old.size == new.size || return false
    old_widths = max.(widths(old.bbox), 1)
    zoom = max.(widths(new.bbox), 1) ./ old_widths
    pan = norm(center(new.bbox) - center(old.bbox)) / maximum(old_widths)
    return all(1 / WARM_START_ZOOM .<= zoom .<= WARM_START_ZOOM) && pan <= WARM_START_PAN
end

pad_rect(rect::Rect2, padding) = Rect2d(rect.origin .- padding, rect.widths .+ 2 * padding)

"""
    CandidatePlacement(; gaps, nangles, padding, pointradius, centroidweight, leaderpenalty, restarts, seed)

The default label placement algorithm of `annotation`. Each label is placed on one of a finite
set of candidate positions around its target point. Candidates lie on rings with the given `gaps`
(in pixels) between the point and the label box, which is padded by `padding` pixels per side, at
`nangles` evenly spaced angles per ring. A candidate's cost penalizes, from most to least severe,
overlap with other labels or the axis boundary and covering data points (which are treated as
circles of `pointradius` pixels), leader lines crossing each other or running over other labels
or points, positions without a leader that have other points within reach of the label (unless
the own point lies in between), and finally the gap to the target.
`centroidweight` scales an additional cost per pixel of distance between the label center and
the point, which keeps labels compact around their points, and `leaderpenalty` pixels of gap are
added for visible leaders that deviate from the eight main directions.

Labels with an empty bounding box, for example from empty strings, stay at their target and
only act as obstacles, which allows labelling a subset of points while avoiding all of them.
Labels whose offset or position is given rather than `NaN` are fixed there and likewise only act
as obstacles for the remaining labels.

Labels start at their cheapest candidates, then the assignment is improved by simulated
annealing and finished with local descent, where every label is repeatedly moved to its
cheapest candidate given all others until nothing moves. This is repeated `restarts` times and
the layout with the lowest total cost is kept. `maxiter` bounds the number of descent passes.
The annealing uses its own generator started from `seed`, so the same input gives the same
layout on every Julia version. When the view changes, the previous layout is kept as the
starting point and only labels that are in conflict or find a clearly better position move.
"""
Base.@kwdef struct CandidatePlacement
    gaps::Vector{Float64} = [4.0, 10.0, 18.0, 30.0, 48.0, 72.0, 104.0, 150.0, 210.0]
    nangles::Int = 32
    padding::Vec2d = Vec2d(4, 4)
    pointradius::Float64 = 5.0
    centroidweight::Float64 = 0.15
    leaderpenalty::Float64 = 4.0
    restarts::Int = 3
    seed::UInt64 = 0
end

const OVERLAP_PENALTY = 1000.0
const CROSSING_PENALTY = 300.0
const LEADER_POINT_PENALTY = 100.0
const AMBIGUITY_PENALTY = 100.0
const AMBIGUITY_SHIELD_WIDTH = 8.0
const ANNEAL_MOVES_PER_LABEL = 100
const ANNEAL_MAX_MOVES_PER_STAGE = 3000
const ANNEAL_STAGES = 50
const ANNEAL_COOLING = 0.9
const ANNEAL_TEMPERATURE = 300.0
const ANNEAL_MIN_TEMPERATURE = 20.0
const WARM_START_HYSTERESIS = 10.0
const WARM_START_ZOOM = 1.4
const WARM_START_PAN = 0.5

is_feasible(c) = c.cost < OVERLAP_PENALTY

struct LabelCandidate
    offset::Vec2d
    box::Rect2d
    extent::Rect2d
    leader_start::Point2d
    cost::Float64
end

function LabelCandidate(offset, box::Rect2, target::Point2, leader_start, cost)
    lower = min.(minimum(box), target)
    upper = max.(maximum(box), target)
    return LabelCandidate(Vec2d(offset), box, Rect2d(lower, upper - lower), leader_start, cost)
end

struct PlacementProblem
    targets::Vector{Point2d}
    candidates::Vector{Vector{LabelCandidate}}
    neighbors::Vector{Vector{Int}}
    padding::Vec2d
end

function place_labels!(
        algorithm::CandidatePlacement, offsets::Vector{<:Vec2}, textpositions::Vector{<:Point2},
        text_bbs::Vector{<:Rect2}, bbox::Rect2, fixed::Vector{Vec2d};
        maxiter::Union{Automatic, Int}, reset::Bool, leaderthreshold::Real,
    )
    maxiter = maxiter === automatic ? 20 : maxiter
    n = length(offsets)
    (n == 0 || maxiter == 0) && return

    targets = Point2d.(textpositions)
    neighbors = neighbor_lists(algorithm, targets, text_bbs)
    candidates = map(1:n) do i
        if is_fixed(fixed[i])
            [candidate_at_offset(algorithm, text_bbs[i], targets[i], fixed[i])]
        elseif any(iszero, widths(text_bbs[i]))
            [candidate_at_offset(algorithm, text_bbs[i], targets[i], Vec2d(0))]
        else
            label_candidates(algorithm, targets, neighbors[i], i, text_bbs[i], bbox, leaderthreshold)
        end
    end
    problem = PlacementProblem(targets, candidates, neighbors, algorithm.padding)

    if reset
        layout = first.(candidates)
        rng = LabelPlacementRNG(algorithm.seed)
        trials = map(1:algorithm.restarts) do _
            trial = copy(layout)
            anneal_placement!(trial, problem, rng)
            descend_placement!(trial, problem, maxiter)
            return trial
        end
        if isempty(trials)
            descend_placement!(layout, problem, maxiter)
        else
            layout = argmin(trial -> total_energy(trial, problem), trials)
        end
    else
        layout = [previous_candidate(candidates[i], offsets[i]) for i in 1:n]
        descend_placement!(layout, problem, maxiter; hysteresis = WARM_START_HYSTERESIS)
        if any(i -> pairwise_penalty(layout[i], i, problem, layout) >= CROSSING_PENALTY, 1:n)
            anneal_placement!(layout, problem, LabelPlacementRNG(algorithm.seed))
            descend_placement!(layout, problem, maxiter; hysteresis = WARM_START_HYSTERESIS)
        end
    end

    offsets .= (c -> c.offset).(layout)
    return
end

previous_candidate(candidates, offset) = argmin(c -> norm(c.offset - offset), candidates)

function total_energy(layout, problem::PlacementProblem)
    static = sum(c -> c.cost, layout)
    pairwise = sum(i -> pairwise_penalty(layout[i], i, problem, layout), eachindex(layout))
    return static + pairwise / 2
end

function neighbor_lists(algorithm::CandidatePlacement, targets, text_bbs)
    maxgap = maximum(algorithm.gaps)
    radius = [maxgap + norm(widths(pad_rect(bb, algorithm.padding))) for bb in text_bbs]
    return map(eachindex(targets)) do i
        filter(j -> j != i && norm(targets[i] - targets[j]) < radius[i] + radius[j], eachindex(targets))
    end
end

function rect_corners(rect::Rect2)
    (l, b), (r, t) = extrema(rect)
    return (Point2d(l, b), Point2d(r, b), Point2d(r, t), Point2d(l, t))
end

function best_candidate(i, problem::PlacementProblem, layout; hysteresis = 0.0)
    best = layout[i]
    best_cost = best.cost + pairwise_penalty(best, i, problem, layout) - hysteresis
    for c in problem.candidates[i]
        c.cost >= best_cost && break
        cost = c.cost + pairwise_penalty(c, i, problem, layout; bound = best_cost - c.cost)
        if cost < best_cost
            best, best_cost = c, cost
        end
    end
    return best
end

function descend_placement!(layout, problem::PlacementProblem, maxiter; hysteresis = 0.0)
    for _ in 1:maxiter
        moved = false
        for i in eachindex(layout)
            best = best_candidate(i, problem, layout; hysteresis)
            best === layout[i] && continue
            layout[i] = best
            moved = true
        end
        moved || break
    end
    return
end

# Own generator so that layouts are reproducible across Julia versions, which the generators in
# Random do not guarantee. Knuth's MMIX linear congruential generator (a = 6364136223846793005,
# c = 1442695040888963407, m = 2^64), whose low bits have short periods, so the output is scrambled
# with the first xorshift-multiply step of the MurmurHash3 64-bit finalizer.
mutable struct LabelPlacementRNG
    state::UInt64
end

function next_uint(rng::LabelPlacementRNG)
    rng.state = rng.state * 0x5851f42d4c957f2d + 0x14057b7ef767814f
    x = rng.state
    return (x ⊻ (x >> 33)) * 0xff51afd7ed558ccd
end

next_int(rng::LabelPlacementRNG, n::Int) = Int(next_uint(rng) % UInt64(n)) + 1
next_float(rng::LabelPlacementRNG) = Float64(next_uint(rng) >> 11) / 2.0^53

function anneal_placement!(layout, problem::PlacementProblem, rng::LabelPlacementRNG)
    n = length(layout)
    nproposals = map(problem.candidates) do candidates
        nfeasible = count(is_feasible, candidates)
        nfeasible == 0 ? length(candidates) : nfeasible
    end
    penalties = fill(NaN, n)
    current_penalty(i) = isnan(penalties[i]) ? (penalties[i] = pairwise_penalty(layout[i], i, problem, layout)) : penalties[i]
    temperature = ANNEAL_TEMPERATURE
    for _ in 1:ANNEAL_STAGES
        temperature < ANNEAL_MIN_TEMPERATURE && break
        conflicted = filter(i -> current_penalty(i) > 0, 1:n)
        isempty(conflicted) && break
        accepted = 0
        for _ in 1:min(ANNEAL_MOVES_PER_LABEL * length(conflicted), ANNEAL_MAX_MOVES_PER_STAGE)
            i = conflicted[next_int(rng, length(conflicted))]
            candidate = problem.candidates[i][next_int(rng, nproposals[i])]
            candidate === layout[i] && continue
            old_cost = layout[i].cost + current_penalty(i)
            new_cost = candidate.cost + pairwise_penalty(candidate, i, problem, layout)
            delta = new_cost - old_cost
            if delta <= 0 || next_float(rng) < exp(-delta / temperature)
                layout[i] = candidate
                penalties[i] = NaN
                penalties[problem.neighbors[i]] .= NaN
                accepted += delta != 0
            end
        end
        accepted == 0 && break
        temperature *= ANNEAL_COOLING
    end
    return
end

function label_candidates(algorithm::CandidatePlacement, targets, neighbors, i, text_bb, viewport, leaderthreshold)
    target = targets[i]
    padded_bb = pad_rect(text_bb, algorithm.padding)
    diagonal = norm(widths(padded_bb))
    margin = algorithm.pointradius + minimum(algorithm.padding)
    reach(gap) = gap + diagonal + leaderthreshold + margin
    obstacles = sort(neighbors; by = j -> norm(targets[j] - target))
    obstacle_distances = [norm(targets[j] - target) for j in obstacles]
    candidates = Vector{LabelCandidate}(undef, length(algorithm.gaps) * algorithm.nangles)
    # labels of points outside the viewport stay with their point, where they are clipped,
    # instead of piling up along the viewport edge
    keep_inside = target in viewport ? viewport : nothing
    for (index, (gap, k)) in enumerate(Iterators.product(algorithm.gaps, 0:(algorithm.nangles - 1)))
        reachable = view(targets, view(obstacles, 1:searchsortedlast(obstacle_distances, reach(gap))))
        angle = 2pi * k / algorithm.nangles
        direction = Vec2d(cos(angle), sin(angle))
        ring_center = target + direction * ring_distance(padded_bb, direction, gap)
        unslid = padded_bb + (ring_center - center(padded_bb))
        box = slide_inside(unslid, keep_inside)
        offset = center(box) - center(padded_bb)
        leader_start = leader_start_point(box, target)
        leader_visible = rect_point_distance(text_bb + offset, target) >= leaderthreshold
        claim_distance = leader_visible ? 0.0 : leaderthreshold
        cost = gap + algorithm.centroidweight * norm(center(box) - target) +
            (leader_visible ? algorithm.leaderpenalty * sin(4 * leader_angle(leader_start, target))^2 : 0.0) +
            slide_penalty(box, unslid, target, minimum(algorithm.gaps)) +
            static_penalty(algorithm, box, leader_start, target, reachable, keep_inside, claim_distance)
        candidates[index] = LabelCandidate(offset, box, target, leader_start, cost)
    end
    return sort!(candidates; by = c -> c.cost, alg = QuickSort)
end

function leader_angle(leader_start, target)
    v = target - leader_start
    return atan(v[2], v[1])
end

slide_penalty(box, unslid, target, mingap) = box != unslid && rect_point_distance(box, target) < mingap ? OVERLAP_PENALTY : 0.0

slide_inside(box::Rect2, ::Nothing) = box
function slide_inside(box::Rect2, viewport::Rect2)
    any(widths(box) .> widths(viewport)) && return box
    shift = max.(minimum(viewport) - minimum(box), 0) + min.(maximum(viewport) - maximum(box), 0)
    return box + shift
end

function candidate_at_offset(algorithm::CandidatePlacement, text_bb, target, offset)
    box = pad_rect(text_bb, algorithm.padding) + offset
    return LabelCandidate(offset, box, target, leader_start_point(box, target), 0.0)
end

# distance along `direction` at which a box centered there keeps `gap` between its
# nearest edge or corner and the origin
function ring_distance(rect::Rect2, direction::VecTypes{2}, gap)
    w, h = 0.5 .* widths(rect)
    dx, dy = abs.(direction)
    if dx > 0 && (w + gap) / dx * dy <= h
        return (w + gap) / dx
    elseif dy > 0 && (h + gap) / dy * dx <= w
        return (h + gap) / dy
    end
    s = w * dx + h * dy
    return s + sqrt(s^2 - (w^2 + h^2 - gap^2))
end

nearest_point(rect::Rect2, p::Point2) = Point2d(clamp.(p, minimum(rect), maximum(rect)))

# leaders attach to the pill inscribed in the label box, perpendicular on its straight sides and
# turning toward the target around its rounded ends
function leader_start_point(box::Rect2, target::Point2)
    radius = 0.5 * minimum(widths(box))
    core = Point2d(clamp.(target, minimum(box) .+ radius, maximum(box) .- radius))
    v = target - core
    distance = norm(v)
    return distance == 0 ? core : core + radius * v / distance
end

function static_penalty(algorithm::CandidatePlacement, box, leader_start, target, obstacles, viewport, claim_distance)
    r = algorithm.pointradius
    penalty = 0.0
    leader_clearance = r + minimum(algorithm.padding)
    for t in obstacles
        if rect_point_distance(box, t) < r
            penalty += OVERLAP_PENALTY
        else
            penalty += ambiguity_penalty(box, t, target, claim_distance)
        end
        if segment_point_distance(leader_start, target, t) < leader_clearance
            penalty += LEADER_POINT_PENALTY
        end
    end
    penalty += viewport_penalty(box, viewport)
    return penalty
end

viewport_penalty(box, ::Nothing) = 0.0
viewport_penalty(box, viewport::Rect2) = overlap_penalty(prod(widths(box)) - overlap_area(box, viewport))

overlap_penalty(area) = area > 0 ? OVERLAP_PENALTY * (1 + area / 100) : 0.0

# a label without a leader could be read as belonging to any other point within reach of the
# pill inscribed in the label, the more so the closer it is, unless the own point lies between them
function ambiguity_penalty(box, point, target, claim_distance)
    distance = pill_distance(box, point)
    distance < claim_distance || return 0.0
    start = leader_start_point(box, target)
    own = target - start
    other = point - start
    own_distance = norm(own)
    along = dot(other, own) / own_distance
    lateral = abs(own[1] * other[2] - own[2] * other[1]) / own_distance
    shielded = along > own_distance && lateral < AMBIGUITY_SHIELD_WIDTH
    return shielded ? 0.0 : AMBIGUITY_PENALTY * (1 - distance / claim_distance)
end

pill_distance(box::Rect2, p::Point2) = norm(p - leader_start_point(box, p))

function pairwise_penalty(c::LabelCandidate, i, problem::PlacementProblem, layout; bound = Inf)
    targets = problem.targets
    penalty = 0.0
    for j in problem.neighbors[i]
        other = layout[j]
        rects_disjoint(c.extent, other.extent) && continue
        penalty += overlap_penalty(overlap_area(c.box, other.box))
        if segments_cross(c.leader_start, targets[i], other.leader_start, targets[j])
            penalty += CROSSING_PENALTY
        end
        penalty += leader_label_penalty(other.leader_start, targets[j], c.box, problem.padding)
        penalty += leader_label_penalty(c.leader_start, targets[i], other.box, problem.padding)
        penalty >= bound && return penalty
    end
    return penalty
end

function leader_label_penalty(leader_start, target, box, padding)
    segment_intersects_rect(leader_start, target, box) || return 0.0
    textbox = pad_rect(box, -padding)
    return segment_intersects_rect(leader_start, target, textbox) ? CROSSING_PENALTY : CROSSING_PENALTY / 3
end

rects_disjoint(a::Rect2, b::Rect2) = any(maximum(a) .< minimum(b)) || any(maximum(b) .< minimum(a))

function overlap_area(a::Rect2, b::Rect2)
    return prod(max.(0, min.(maximum(a), maximum(b)) .- max.(minimum(a), minimum(b))))
end

rect_point_distance(rect::Rect2, p::Point2) = norm(p - nearest_point(rect, p))

function segment_point_distance(a::Point2, b::Point2, p::Point2)
    ab = b - a
    len2 = dot(ab, ab)
    len2 == 0 && return norm(p - a)
    t = clamp(dot(p - a, ab) / len2, 0, 1)
    return norm(p - (a + t * ab))
end

function segments_cross(p1::Point2, p2::Point2, q1::Point2, q2::Point2)
    d1 = cross2d(q2 - q1, p1 - q1)
    d2 = cross2d(q2 - q1, p2 - q1)
    d3 = cross2d(p2 - p1, q1 - p1)
    d4 = cross2d(p2 - p1, q2 - p1)
    return ((d1 > 0) != (d2 > 0)) && ((d3 > 0) != (d4 > 0))
end

cross2d(a::VecTypes{2}, b::VecTypes{2}) = a[1] * b[2] - a[2] * b[1]

function segment_intersects_rect(a::Point2, b::Point2, rect::Rect2)
    (l, bo), (r, t) = extrema(rect)
    inside(p) = l < p[1] < r && bo < p[2] < t
    (inside(a) || inside(b)) && return true
    corners = rect_corners(rect)
    for k in 1:4
        segments_cross(a, b, corners[k], corners[mod1(k + 1, 4)]) && return true
    end
    return false
end

startpoint(::Ann.Paths.Line, text_bb, p2) = leader_start_point(text_bb, p2)

function startpoint(::Ann.Paths.Corner, text_bb, p2)
    l = left(text_bb)
    r = right(text_bb)
    b = bottom(text_bb)
    t = top(text_bb)
    dir = p2 - (text_bb.origin + 0.5 * text_bb.widths)
    if abs(dir[1]) < abs(dir[2])
        x = dir[1] > 0 ? r : l
        y = (t + b) / 2
    else
        x = (l + r) / 2
        y = dir[2] > 0 ? t : b
    end
    return Point2d(x, y)
end

data_limits(p::Annotation) = Rect3f(Rect2f(p.target_positions[]))
boundingbox(p::Annotation, space::Symbol = :data) = apply_transform_and_model(p, data_limits(p))

function connection_path(::Ann.Paths.Line, p1, p2)
    return BezierPath(
        [
            MoveTo(p1),
            LineTo(p2),
        ]
    )
end

function connection_path(::Ann.Paths.Corner, p1, p2)
    dir = p2 - p1
    return if abs(dir[1]) > abs(dir[2])
        BezierPath(
            [
                MoveTo(p1),
                LineTo(p1[1], p2[2]),
                LineTo(p2),
            ]
        )
    else
        BezierPath(
            [
                MoveTo(p1),
                LineTo(p2[1], p1[2]),
                LineTo(p2),
            ]
        )
    end
end

function startpoint(::Ann.Paths.Arc, text_bb, p2)
    return center(text_bb)
end

function circle_centers(p1::Point2, p2::Point2, r)
    d = norm(p2 - p1)
    if d > 2r
        return nothing  # No circle possible
    end

    m = (p1 + p2) / 2
    h = sqrt(r^2 - (d / 2)^2)

    # Perpendicular direction
    dir = p2 - p1
    perp = Point2(-dir[2], dir[1]) / d  # Normalized

    c1 = m + h * perp
    c2 = m - h * perp
    return c1, c2
end


function arc_center_radius(p1::Point2, p2::Point2, x::Real)
    xabs = abs(x)
    chord = p2 - p1
    mid = Point2((p1[1] + p2[1]) / 2, (p1[2] + p2[2]) / 2)
    len = norm(chord)
    height = xabs * len / 2
    if height == 0
        error("Height x must be non-zero for a valid arc.")
    end
    # Radius from chord length and height
    r = (len^2) / (8height) + height / 2
    # Unit perpendicular vector to chord
    perp = normalize(Point2(-chord[2], chord[1]))
    # Center lies along perpendicular from midpoint, distance (r - x)

    direction = sign(x) * chord[1] > 0 ? -1 : 1

    center = mid + direction * perp * (r - height)
    return r, center
end

function connection_path(ca::Ann.Paths.Arc, p1, p2)
    abs(ca.height) < 1.0e-4 && return connection_path(Ann.Paths.Line(), p1, p2)
    radius, center = arc_center_radius(p1, p2, ca.height)
    return BezierPath([MoveTo(p1), EllipticalArc(center, radius, radius, 0.0, atan(reverse(p1 - center)...), atan(reverse(p2 - center)...))])
end

function is_stub(path::BezierPath, minlength)
    length(path.commands) < 2 && return true
    start::MoveTo = path.commands[1]
    return norm(endpoint(path.commands[end]) - start.p) < minlength
end

function shrink_path(path, shrink)
    start::MoveTo = path.commands[1]
    stop = endpoint(path.commands[end])

    if length(path.commands) < 2
        return path
    end

    if shrink[1] > 0
        for i in 2:length(path.commands)
            p_prev = endpoint(path.commands[i - 1])
            intersects, moveto, newcommand = circle_intersection(start.p, shrink[1], p_prev, path.commands[i])
            if !intersects # should mean that the command is contained in the circle because we start at its center
                if i == length(path.commands)
                    # path is completely contained
                    return BezierPath(path.commands[1:1]) # empty BezierPath doesn't work currently because of bbox
                end
                continue
            else
                path = BezierPath(
                    [
                        moveto;
                        newcommand;
                        @view(path.commands[(i + 1):end])
                    ]
                )
                break
            end
        end
    end

    if shrink[2] > 0
        for i in length(path.commands):-1:2
            p_prev = endpoint(path.commands[i - 1])
            p_end, reversed = reversed_command(p_prev, path.commands[i])
            intersects, moveto, newcommand = circle_intersection(stop, shrink[2], p_end, reversed)
            if !intersects
                if i == 2
                    # path is completely contained
                    return BezierPath(path.commands[1:1]) # empty BezierPath doesn't work currently because of bbox
                end
                continue
            else
                _, new_reversed = reversed_command(moveto.p, newcommand)
                path = BezierPath(
                    [
                        @view(path.commands[1:(i - 1)]);
                        new_reversed
                    ]
                )
                break
            end
        end
    end

    return path
end

function reversed_command(p_prev, l::LineTo)
    return l.p, LineTo(p_prev)
end

function reversed_command(p_prev, e::EllipticalArc)
    # assumed that p_prev is at the start of e, otherwise there's a linesegment additionally but we can't deal with that here
    return endpoint(e), EllipticalArc(e.c, e.r1, e.r2, e.angle, e.a2, e.a1)
end

function circle_intersection(center::Point2, r, p1::Point2, command::LineTo)
    p2 = command.p
    # Unpack points
    x1, y1 = p1
    x2, y2 = p2
    cx, cy = center

    # Translate points so the circle center is at the origin
    x1 -= cx; y1 -= cy
    x2 -= cx; y2 -= cy

    # Line direction
    dx = x2 - x1
    dy = y2 - y1

    # Quadratic equation coefficients
    a = dx^2 + dy^2
    b = 2 * (x1 * dx + y1 * dy)
    c = x1^2 + y1^2 - r^2

    # Discriminant
    discriminant = b^2 - 4 * a * c

    if discriminant < 0
        return false, nothing, nothing
    end

    # Two solutions for t
    sqrt_discriminant = sqrt(discriminant)
    t1 = (-b - sqrt_discriminant) / (2 * a)
    t2 = (-b + sqrt_discriminant) / (2 * a)

    # Check if the solutions are within the segment
    t = if 0 <= t2 <= 1
        t2
    elseif 0 <= t1 <= 1
        t1
    else
        return false, nothing, nothing
    end

    # Intersection point in translated coordinates
    ix = x1 + t * dx
    iy = y1 + t * dy

    # Translate back to original coordinates
    ix += cx
    iy += cy

    return true, MoveTo(Point2d(ix, iy)), command
end

function circle_intersection(center::Point2, r, p1::Point2, command::EllipticalArc)
    if command.r1 == command.r2
        # special case circular arc
        # Unpack points
        cx, cy = center
        px, py = p1
        r_a = command.r1
        angle1 = command.a1
        angle2 = command.a2

        # Translate the arc center to the origin
        arc_center = command.c
        arc_center_translated = arc_center - center

        # Compute the distance between the circle center and the arc center
        d = norm(arc_center_translated)

        # Check if the circle and arc intersect
        if d > r + r_a || d < abs(r - r_a)
            return false, nothing, nothing
        end

        # Compute the intersection points
        a = (r^2 - r_a^2 + d^2) / (2 * d)
        h = sqrt(r^2 - a^2)
        p = center + a * normalize(arc_center_translated)
        perp = Point2(-arc_center_translated[2], arc_center_translated[1]) / d
        intersection1 = p + h * perp
        intersection2 = p - h * perp

        # Check if the intersection points lie on the arc
        angle_intersection1 = atan(intersection1[2] - arc_center[2], intersection1[1] - arc_center[1])
        angle_intersection2 = atan(intersection2[2] - arc_center[2], intersection2[1] - arc_center[1])

        between_1 = is_between(angle_intersection1, angle1, angle2)
        between_2 = is_between(angle_intersection2, angle1, angle2)

        if between_1 && between_2
            # TODO: which one to pick?
            return true, MoveTo(intersection1), EllipticalArc(arc_center, r_a, r_a, 0.0, angle_intersection1, angle2)
        elseif between_1
            return true, MoveTo(intersection1), EllipticalArc(arc_center, r_a, r_a, 0.0, angle_intersection1, angle2)
        elseif between_2
            return true, MoveTo(intersection2), EllipticalArc(arc_center, r_a, r_a, 0.0, angle_intersection2, angle2)
        end
        #     return false, nothing, nothing
        # end
        return false, nothing, nothing
    else
        error("Not implemented for ellipses")
    end
end

function is_between(x, a, b)
    a, b = min(a, b), max(a, b)
    return a <= x <= b
end

function clip_path_from_start(path::BezierPath, bbox::Rect2)

    if length(path.commands) < 2
        return path
    end

    for i in 2:length(path.commands)
        p_prev = endpoint(path.commands[i - 1])
        is_contained = bbox_containment(bbox, p_prev, path.commands[i])
        is_contained && continue
        intersects, moveto, newcommand = bbox_intersection(bbox, p_prev, path.commands[i])
        if intersects
            path = BezierPath(
                [
                    moveto;
                    newcommand;
                    @view(path.commands[(i + 1):end])
                ]
            )
            break
        end
    end

    return path
end

function bbox_containment(bbox::Rect2, p_prev::Point2, comm::LineTo)
    return p_prev in bbox && comm.p in bbox
end

function bbox_containment(bbox::Rect2, p_prev::Point2, comm::EllipticalArc)
    return false # TODO: implement
end

function bbox_intersection(bbox::Rect2, p_prev::Point2, comm::LineTo)
    intersects, pt = line_rectangle_intersection(p_prev, comm.p, bbox)
    if intersects
        return intersects, MoveTo(pt), comm
    else
        return intersects, nothing, nothing
    end
end

function bbox_intersection(bbox::Rect2, p_prev::Point2, comm::EllipticalArc)
    if comm.r1 == comm.r2
        # circular arc
        r = comm.r1
        # Analytical circular arc intersection with bounding box
        cx, cy = comm.c
        r = comm.r1
        angle1, angle2 = comm.a1, comm.a2

        # Define the four edges of the bounding box
        edges = (
            (Point2d(bbox.origin[1], bbox.origin[2]), Point2d(bbox.origin[1] + bbox.widths[1], bbox.origin[2])),           # Bottom edge
            (Point2d(bbox.origin[1], bbox.origin[2]), Point2d(bbox.origin[1], bbox.origin[2] + bbox.widths[2])),           # Left edge
            (Point2d(bbox.origin[1] + bbox.widths[1], bbox.origin[2]), Point2d(bbox.origin[1] + bbox.widths[1], bbox.origin[2] + bbox.widths[2])), # Right edge
            (Point2d(bbox.origin[1], bbox.origin[2] + bbox.widths[2]), Point2d(bbox.origin[1] + bbox.widths[1], bbox.origin[2] + bbox.widths[2])),  # Top edge
        )

        for (p1, p2) in edges
            # Find intersection of the circle with the line segment
            intersects, t1, t2 = circle_line_intersection(cx, cy, r, p1, p2)
            if intersects
                for t in (t1, t2)
                    if 0 <= t <= 1
                        intersection = p1 + t * (p2 - p1)
                        angle = atan(intersection[2] - cy, intersection[1] - cx)
                        if is_between(angle, angle1, angle2)
                            return true, MoveTo(intersection), EllipticalArc(comm.c, comm.r1, comm.r2, comm.angle, angle, comm.a2)
                        end
                    end
                end
            end
        end

        return false, nothing, nothing
    else
        error("Not implemented for ellipses")
    end
end

function circle_line_intersection(cx, cy, r, p1::Point2, p2::Point2)
    x1, y1 = p1
    x2, y2 = p2

    # Translate line to circle's center
    dx, dy = x2 - x1, y2 - y1
    fx, fy = x1 - cx, y1 - cy

    a = dx^2 + dy^2
    b = 2 * (fx * dx + fy * dy)
    c = fx^2 + fy^2 - r^2

    discriminant = b^2 - 4 * a * c
    if discriminant < 0
        return false, nothing, nothing
    end

    sqrt_discriminant = sqrt(discriminant)
    t1 = (-b - sqrt_discriminant) / (2 * a)
    t2 = (-b + sqrt_discriminant) / (2 * a)

    return true, t1, t2
end

function line_rectangle_intersection(p1::Point2, p2::Point2, rect::Rect2)
    # Unpack points and rectangle properties
    x1, y1 = p1
    x2, y2 = p2
    (rx, ry) = rect.origin
    (rw, rh) = rect.widths

    # List of rectangle edges (each edge is represented as a pair of points)
    edges = (
        (Point2d(rx, ry), Point2d(rx + rw, ry)),           # Bottom edge
        (Point2d(rx, ry), Point2d(rx, ry + rh)),           # Left edge
        (Point2d(rx + rw, ry), Point2d(rx + rw, ry + rh)), # Right edge
        (Point2d(rx, ry + rh), Point2d(rx + rw, ry + rh)),  # Top edge
    )

    # Helper function to find intersection of two line segments
    function segment_intersection(p1::Point2, p2::Point2, q1::Point2, q2::Point2)
        local x1, y1 = p1
        local x2, y2 = p2
        x3, y3 = q1
        x4, y4 = q2

        denom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1)
        if denom == 0.0
            return (false, nothing)  # Parallel lines
        end

        ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denom
        ub = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / denom

        if 0.0 <= ua <= 1.0 && 0.0 <= ub <= 1.0
            ix = x1 + ua * (x2 - x1)
            iy = y1 + ua * (y2 - y1)
            return (true, Point2d(ix, iy))
        else
            return (false, nothing)  # Intersection not within the segments
        end
    end

    closest_intersection = nothing
    min_distance = Inf

    # Check intersection with each edge
    for (q1, q2) in edges
        intersects, point = segment_intersection(p1, p2, q1, q2)
        if intersects
            # Calculate distance to p2
            distance = hypot(point[1] - p2[1], point[2] - p2[2])
            if distance < min_distance
                min_distance = distance
                closest_intersection = point
            end
        end
    end

    if isnothing(closest_intersection)
        return (false, nothing)
    else
        return (true, closest_intersection)
    end
end

annotation_style_plotspecs(::Automatic, path, p1, p2; kwargs...) = annotation_style_plotspecs(Ann.Styles.Line(), path, p1, p2; kwargs...)

function annotation_style_plotspecs(l::Ann.Styles.LineArrow, path::BezierPath, p1, p2; color, linewidth)
    length(path.commands) < 2 && return PlotSpec[]
    p_head = endpoint(path.commands[end])

    _startpoint(c::MoveTo) = c.p

    p_tail = _startpoint(path.commands[1])

    shrink_for_head = shrinksize(l.head)
    shrink_for_tail = shrinksize(l.tail)

    shortened_path = shrink_path(path, (shrink_for_tail, shrink_for_head))
    length(shortened_path.commands) < 2 && return PlotSpec[]

    head_dir = normalize(p2 - endpoint(shortened_path.commands[end]))
    head_rotation = atan(head_dir[2], head_dir[1])
    tail_dir = normalize(p1 - _startpoint(shortened_path.commands[1]))
    tail_rotation = atan(tail_dir[2], tail_dir[1])


    specs = [
        PlotSpec(:Lines, shortened_path; color, space = :pixel, linewidth);
    ]
    if l.head !== nothing
        append!(specs, plotspecs(l.head, p_head; rotation = head_rotation, color, linewidth))
    end
    if l.tail !== nothing
        append!(specs, plotspecs(l.tail, p_tail; rotation = tail_rotation, color, linewidth))
    end
    return specs
end

function annotation_style_plotspecs(::Ann.Styles.Line, path::BezierPath, p1, p2; color, linewidth)
    return [
        PlotSpec(:Lines, path; color, linewidth, space = :pixel),
    ]
end

function annotation_style_plotspecs(s::Ann.Styles.WithText, path::BezierPath, p1, p2; color, linewidth)
    specs = annotation_style_plotspecs(s.style, path, p1, p2; color, linewidth)
    textcolor = s.color === automatic ? color : s.color
    push!(
        specs,
        PlotSpec(
            :PathText, path;
            text = s.text, fontsize = s.fontsize, align = s.align,
            offset = s.offset, color = textcolor, space = :pixel,
        ),
    )
    return specs
end

_auto(x::Automatic, default) = default
_auto(x, default) = x

shrinksize(other) = 0.0

function shrinksize(l::Ann.Arrows.Head)
    return l.length * (1 - l.notch)
end

function plotspecs(l::Ann.Arrows.Line, pos; rotation, color, linewidth)
    color = _auto(l.color, color)
    linewidth = _auto(l.linewidth, linewidth)
    sidelen = l.length / cos(l.angle / 2)
    dir1 = Point2(-cos(l.angle / 2 + rotation), -sin(l.angle / 2 + rotation))
    dir2 = Point2(-cos(-l.angle / 2 + rotation), -sin(-l.angle / 2 + rotation))
    p1 = pos + dir1 * sidelen
    p2 = pos + dir2 * sidelen
    return [
        PlotSpec(:Lines, [p1, pos, p2]; space = :pixel, color, linewidth),
    ]
end

function plotspecs(h::Ann.Arrows.Head, pos; rotation, color, linewidth)
    color = _auto(h.color, color)
    len = h.length
    L = 1 / cos(h.angle / 2)
    p1 = L * Point2(-cos(h.angle / 2), -sin(h.angle / 2))
    p2 = Point2(-(1 - h.notch), 0)
    p3 = L * Point2(-cos(-h.angle / 2), -sin(-h.angle / 2))

    marker = BezierPath([MoveTo(0, 0), LineTo(p1), LineTo(p2), LineTo(p3), ClosePath()])
    return [
        PlotSpec(:Scatter, pos; space = :pixel, rotation, color, marker, markersize = len),
    ]
end

function attribute_examples(::Type{Annotation})
    return Dict(
        :shrink => [
            Example(
                code = raw"""
                fig = Figure()
                ax = Axis(fig[1, 1], xgridvisible = false, ygridvisible = false)
                shrinks = [(0, 0), (5, 5), (10, 10), (20, 20), (5, 20), (20, 5)]
                for (i, shrink) in enumerate(shrinks)
                    annotation!(ax, -200, 0, 0, i; text = "shrink = $shrink", shrink, style = Ann.Styles.LineArrow())
                    scatter!(ax, 0, i)
                end
                fig
                """
            ),
        ],
        :style => [
            Example(
                code = raw"""
                fig = Figure()
                ax = Axis(fig[1, 1], yautolimitmargin = (0.3, 0.3), xgridvisible = false, ygridvisible = false)
                annotation!(-200, 0, 0, 0, style = Ann.Styles.Line())
                annotation!(-200, 0, 0, -1, style = Ann.Styles.LineArrow())
                annotation!(-200, 0, 0, -2, style = Ann.Styles.LineArrow(head = Ann.Arrows.Head()))
                annotation!(-200, 0, 0, -3, style = Ann.Styles.LineArrow(tail = Ann.Arrows.Line(length = 20)))
                fig
                """
            ),
            Example(
                code = raw"""
                fig = Figure()
                ax = Axis(fig[1, 1])
                A, B = Point2f(1, 2), Point2f(5, 5)
                scatter!(ax, [A, B], markersize = 10, color = :black)
                text!(ax, [A, B], text = ["A", "B"],
                    align = (:right, :top), offset = (-6, -4))
                annotation!(ax, [A], [B];
                    text = [""],
                    path = Ann.Paths.Arc(height = 0.4),
                    style = Ann.Styles.WithText(Ann.Styles.LineArrow();
                        text = "from A to B", fontsize = 14),
                    color = :steelblue, labelspace = :data, shrink = (5.0, 5.0))
                fig
                """
            ),
        ],
        :path => [
            Example(
                code = raw"""
                fig = Figure()
                ax = Axis(fig[1, 1], yautolimitmargin = (0.3, 0.3), xgridvisible = false, ygridvisible = false)
                scatter!(ax, fill(0, 4), 0:-1:-3)
                annotation!(-200, 0, 0, 0, path = Ann.Paths.Line(), text = "Line()")
                annotation!(-200, 0, 0, -1, path = Ann.Paths.Arc(height = 0.1), text = "Arc(height = 0.1)")
                annotation!(-200, 0, 0, -2, path = Ann.Paths.Arc(height = 0.3), text = "Arc(height = 0.3)")
                annotation!(-200, 30, 0, -3, path = Ann.Paths.Corner(), text = "Corner()")
                fig
                """
            ),
        ],
        :labelspace => [
            Example(
                code = raw"""
                g(x) = cos(6x) * exp(x)
                xs = 0:0.01:4
                ys = g.(xs)

                f, ax, _ = lines(xs, ys; axis = (; xgridvisible = false, ygridvisible = false))

                annotation!(ax, 1, 20, 2.1, g(2.1),
                    text = "(1, 20)\nlabelspace = :data",
                    path = Ann.Paths.Arc(0.3),
                    style = Ann.Styles.LineArrow(),
                    labelspace = :data
                )

                annotation!(ax, -100, -100, 2.65, g(2.65),
                    text = "(-100, -100)\nlabelspace = :relative_pixel",
                    path = Ann.Paths.Arc(-0.3),
                    style = Ann.Styles.LineArrow()
                )

                f
                """
            ),
        ],
    )
end

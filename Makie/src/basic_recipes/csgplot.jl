# TODO: try to only have user facing functions here?
# Maybe also Node?
"""
TODO: list all

## 2D Shapes

## 3D Shapes

## Transformations

## Merges

"""
module CSG
    using Makie: VecTypes
    import ..SDF

    # TODO:
    """
        CSG.Sphere(position::VecTypes{3}, radius::Real; kwargs...)

    Creates a sphere with a given `radius` and `position` for constructive
    solid geometry. Keyword arguments may include `color` and any CSG
    transformation.
    """
    function Sphere(position::VecTypes{3}, radius::Real; kwargs...)
        return SDF.Shape(:sphere, radius, translation = position; kwargs...)
    end
end

function update_brickmap!(
        brickmap::SDFBrickmap, bb::Rect3f, root::SDF.Node,
        regions_to_update::Vector{Rect3f}
    )
    # TODO: Is this an error?
    isempty(regions_to_update) && return

    N_blocks = size(brickmap.indices, 1)

    # coarse grid (indices) with
    # minimum = mini + 0 * delta
    # maximum = mini + N_blocks * delta
    # each bricks 1 delta large, center at (i, j, k) .+ 0.5
    delta = widths(bb) ./ N_blocks
    mini = minimum(bb)

    # TODO: maybe try to make list of
    #   merged_aligned_bb/index ranges => bbs_that_got_merged
    # and then loop based on first, check second
    # Find region that needs updating
    raw_update_bb = reduce(union, regions_to_update, init = Rect3f())
    low = trunc.(Int, clamp.(fld.(minimum(raw_update_bb) .- mini, delta), 0, N_blocks-1)) .+ 1
    high = trunc.(Int, clamp.(cld.(maximum(raw_update_bb) .- mini, delta), 1, N_blocks))
    @info "Diffed bbs: $regions_to_update"
    @info "Merged: $raw_update_bb"
    @info "Ranges: $low .. $high"

    # for node bbox and SDF based skipping
    box_scale = norm(widths(bb))
    brickdiameter = sqrt(3.0) * box_scale / (N_blocks - 1) # relative to bb
    brickradius = 0.5 * brickdiameter

    # step through brick grid (delta is the width of the brick, bricksize is edge-like)
    bricksize = brickmap.bricksize
    brick_delta = delta / (bricksize - 1)

    # -cellsize .. cellsize -> -127.5 .. 127.5
    # where cellsize is the (1, 1, 1) distance to the next entry
    uint8_scale = 127.5f0 * bricksize / brickdiameter

    # Note: one buffer per thread for multithreading, or create them per thread?
    pos_cache = SDF.Cache{Point3f}((bricksize, bricksize, bricksize))
    sdf_cache = SDF.Cache{Float32}((bricksize, bricksize, bricksize))
    color_cache = SDF.Cache{RGBAf}((bricksize, bricksize, bricksize))

    # print_bb_rec(root)

    content_count = 0
    content_count2 = 0
    content_count3 = 0

    for k in low[3]:high[3]
        z = mini[3] + delta[3] * (k - 0.5)
        for j in low[2]:high[2]
            y = mini[2] + delta[2] * (j - 0.5)
            for i in low[1]:high[1]
                x = mini[1] + delta[1] * (i - 0.5)

                pos = Point3f(x, y, z)
                local_bb = Rect3f(pos .- 0.5 .* delta, delta)
                in_changed_region = any(bb -> overlaps(local_bb, bb), regions_to_update)

                if in_changed_region
                    brick_may_contain_surface = SDF.is_inside(pos, root, brickradius)

                    if brick_may_contain_surface
                        content_count += 1

                        # check if brick could contain edge based on center
                        dist = SDF.compute_signed_distance_at(root, pos)
                        if abs(dist) < brickradius
                            content_count2 += 1
                            # Note: we already checked that this brick needs to be updated
                            content_count3 += update_brick!(
                                brickmap, root, i, j, k,
                                mini, delta, brick_delta,
                                uint8_scale,
                                pos_cache, sdf_cache, color_cache
                            )
                        else
                            free_brick!(brickmap, i, j, k)
                        end
                    else
                        free_brick!(brickmap, i, j, k)
                    end
                end

            end
        end
    end

    # TODO: merge overlapping bboxes, update indices per merge bbox
    ShaderAbstractions.update!(brickmap.indices)

    finish_update!(brickmap)

    return
end

function update_brick!(
        brickmap::SDFBrickmap, root::SDF.Node,
        i, j, k,
        mini, delta, brick_delta,
        uint8_scale,
        pos_cache::SDF.Cache{<:Point},
        sdf_cache::SDF.Cache{<:Real},
        color_cache::SDF.Cache{<:Colorant}
    )

    # cleanup leftover state
    SDF.reset!(pos_cache)
    SDF.reset!(sdf_cache)
    SDF.reset!(color_cache)

    # setup positions
    bricksize = brickmap.bricksize
    origin = Point3f(mini + delta .* ((i, j, k) .- 1))
    positions = SDF.get_buffer(pos_cache)
    @inbounds for ijk in CartesianIndices((bricksize, bricksize, bricksize))
        _ijk = Tuple(ijk)
        positions[ijk] = origin .+ brick_delta .* (_ijk .- 1)
    end

    # TODO: Can we remove unchanged bricks too? Or are they still needed for correct results?
    # compute sdfs + colors
    reduced_tree = SDF.trimmed_tree(Rect3f(origin, delta), root)
    if reduced_tree.main_idx == 0
        free_brick!(brickmap, i, j, k)
        return false # empty tree
    end
    SDF.compute_color_at(reduced_tree, pos_cache, sdf_cache, color_cache)

    # analyze results (should it create a brick?)
    sdfs = SDF.get_first_buffer(sdf_cache)
    colors = SDF.get_first_buffer(color_cache)

    contains_positive = false
    contains_negative = false
    contains_resolvable_distance = false
    contains_multiple_colors = false
    first_color_set = false
    first_color = colors[1]

    @inbounds for i in eachindex(sdfs)
        sdf = sdfs[i]
        f_normed = uint8_scale * sdf
        contains_negative |= sdf <= 0
        contains_positive |= sdf >= 0
        is_resolvable = abs(f_normed) < 127.5f0
        contains_resolvable_distance |= is_resolvable
        if !contains_multiple_colors && is_resolvable
            if !first_color_set
                first_color = colors[i]
                first_color_set = true
            elseif colors[i] != first_color
                contains_multiple_colors = true
            end
        elseif contains_multiple_colors && contains_negative && contains_positive
            break
        end
    end

    # Add data
    # or check contains_positive, contains_negative
    if contains_resolvable_distance
        # Note: needs lock for multithreading
        brick_idx, sdf_brick = get_or_create_brick(brickmap, i, j, k)
        @assert brick_idx > 0
        @inbounds for i in eachindex(sdf_brick)
            f_normed = clamp(uint8_scale * sdfs[i] + 128, 0, 255.9)
            sdf_brick[i] = N0f8(trunc(UInt8, f_normed), nothing)
        end
        finish_brick_update!(brickmap, brick_idx)

        if contains_multiple_colors
            set_interpolated_color!(brickmap, brick_idx, colors)
        else
            set_static_color!(brickmap, brick_idx, first_color)
        end

        return true

    else

        free_brick!(brickmap, i, j, k)
        return false
    end
end

"""
Plots constructive solid geometry, i.e. 3D geometry created from simpler
geometry using transformations and boolean operations. See `Makie.CSG`.
"""
@recipe CSGPlot (x::EndPoints, y::EndPoints, z::EndPoints, csg_tree::SDF.Node) begin
    "Sample density of signed distances used in rendering the geometry."
    resolution = 512
    "Minimum step length used in ray marching."
    minstep = 1e-5
    "TODO: Maximum number of steps allowed in ray marching."
    maxsteps = 1000
    "Size of bricks in the generated Brickmap (per dimension)."
    bricksize = 8
end

conversion_trait(::Type{<:CSGPlot}) = VolumeLike()

function expand_dimensions(::VolumeLike, root::SDF.Node)
    @info "called"
    SDF.calculate_global_bboxes!(root)
    bb = root.bbox[]
    # need padding so the surface isn't on the boundary
    # 0 width bbox would probably be a problem?
    ws = max.(1e-3, widths(bb))
    mini = minimum(bb)
    x, y, z = EndPoints.(mini .- 0.01ws, mini .+ 1.01ws)
    return (x, y, z, root)
end

function convert_arguments(::Type{<:CSGPlot}, x::RangeLike, y::RangeLike, z::RangeLike, root::SDF.Node)
    return (
        to_endpoints(x, "x", VolumeLike), to_endpoints(y, "y", VolumeLike),
        to_endpoints(z, "z", VolumeLike), root,
    )
end

preferred_axis_type(::CSGPlot) = LScene

function pad_tree_bbs!(node::SDF.Node, by::Vec3f)
    node.bbox[] = Rect(minimum(node.bb[]) .- by, widths(node.bb[]) .+ 2by)
    foreach(child -> pad_tree_bbs!(child, by), node.children)
    return
end

function print_bb_rec(node, depth = 0)
    main = node.commands[node.main_idx]
    name = SDF.Commands.get_name(main.id)
    # println("  "^depth, name, " ", node.bbox[])
    str = "  "^depth * "$name $(node.bbox[])\n"
    printstyled(str, color = node.changed[] ? :bold : :light_black)
    foreach(child -> print_bb_rec(child, depth + 2), node.children)
end

function plot!(p::CSGPlot)

    N = p.resolution[]
    @info "$N^3 dense array: $(N^3 * 5 / 1024^2)MB"
    bricksize = p.bricksize[]
    N_blocks = cld(N-1, bricksize-1)
    N = N_blocks * (bricksize-1) + 1
    # brickmap = Brickmap{N0f8}((bricksize, bricksize, bricksize), N, color = SparseBrickmapColors())
    brickmap = SDFBrickmap(bricksize, N)


    map!(p, [:x, :y, :z], :data_limits) do x, y, z
        return Rect3f(x[1], y[1], z[1], x[2] - x[1], y[2] - y[1], z[2] - z[1])
    end

    # TODO: all node bounding boxes need to be padded asap but changes in
    # data_limits should not trigger a recalculation of bricks
    # TODO: do we actually need this?
    # onany(p.csg_tree, p.data_limits) do root, bb
    #     delta = widths(bb) ./ N_blocks
    #     pad_tree_bbs!(root, delta)
    # end

    # TODO: diffing
    register_computation!(p, [:csg_tree], [:diffed_tree, :diffed_bboxes]) do (new_tree,), changed, cached
        SDF.calculate_global_bboxes!(new_tree)
        if isnothing(cached)
            return (new_tree, Rect3f[new_tree.bbox[]])
        else
            old_tree = cached.diffed_tree
            @assert new_tree !== old_tree
            SDF.mark_changed_nodes!(new_tree, old_tree, empty!(cached.diffed_bboxes))
            @info "Old:"
            print_bb_rec(old_tree)
            @info "New:"
            print_bb_rec(new_tree)
            # TODO: optimize rects - merge overlapping, remove duplicated
            # or maybe lower to brick rects?
            return (new_tree, cached.diffed_bboxes)
        end
    end

    map!(p, [:data_limits, :diffed_tree, :diffed_bboxes], :brickmap) do bb, root, bbs
        @time update_brickmap!(brickmap, bb, root, bbs)
        return brickmap
    end

    # force this to run before connecting the backend so we don't spam updates
    # during construction
    p.brickmap[]

    volume!(p, p.x, p.y, p.z, p.brickmap, algorithm = :sdf, isorange = p.minstep)
end

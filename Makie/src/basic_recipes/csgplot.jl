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

function plot!(p::CSGPlot)
    map!(p, [:x, :y, :z], :data_limits) do x, y, z
        return Rect3f(x[1], y[1], z[1], x[2] - x[1], y[2] - y[1], z[2] - z[1])
    end

    # TODO: diffing
    register_computation!(p, [:csg_tree], [:diffed_tree]) do (new_tree,), changed, cached
        if !isnothing(cached)
            # TODO: search for changes and mark them in new_tree
            @assert new_tree !== cached.diffed_tree
        end
        return (new_tree, )
    end

    map!(p, [:data_limits, :resolution, :diffed_tree], :brickmap) do bb, N, root
        @time brickmap = sdf_brickmap(bb, root, N)
        # Float16+ for sdf + 3x N0f8 for RGB
        @info "$N^3 dense array: $(N^3 * 5 / 1024^2)MB"
        return brickmap
    end

    # TODO: for diffed updates we probably need to generate Samplers here
    # so we can update the correct regions
    map!(p, :brickmap, :brick_indices) do brickmap
        return ShaderAbstractions.Sampler(brickmap.indexmap, minfilter = :nearest)
    end

    map!(p, :brickmap, :sdf_bricks) do brickmap
        # TODO: use consistent 2D size to avoid reordering?
        # Or use the Z-order curve? Actually doesn't seem that difficult?
        @info "Brickmap packing"
        packed = pack_bricks(brickmap)
        return ShaderAbstractions.Sampler(packed, minfilter = :linear)
    end

    map!(p, :brickmap, [:color_indexmap, :color_bricks]) do brickmap
        # TODO: same todo as sdf bricks
        @info "Color Packing"
        @time indexmap, bricks = pack_brick_colors(brickmap, brickmap.attributes[:color]::SparseBrickmapColors)
        indexmap_tex = ShaderAbstractions.Sampler(indexmap, minfilter = :nearest)
        brick_tex = ShaderAbstractions.Sampler(bricks, minfilter = :linear)

        return indexmap_tex, brick_tex
    end

    map!(p, [:brickmap, :brick_indices, :sdf_bricks, :color_indexmap, :color_bricks], :buffers) do brickmap, args...
        a = Base.summarysize(args[1]) / 1024^2
        b = Base.summarysize(args[2]) / 1024^2
        c = Base.summarysize(args[3]) / 1024^2
        d = Base.summarysize(args[4]) / 1024^2
        @info "$a + $b + $c + $d = $(a+b+c+d) (indices, bricks, color indexmap, color bricks)"
        return CSGBuffers(args..., brickmap.bricksize[1])
    end

    volume!(p, p.x, p.y, p.z, p.buffers, algorithm = :sdf, isorange = p.minstep)
end

preferred_axis_type(::CSGPlot) = LScene

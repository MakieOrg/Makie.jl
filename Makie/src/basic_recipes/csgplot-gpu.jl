# GPU-accelerated SDF brick evaluation via type-specialized operations
#
# The SDF.Node tree is converted into nested structs where each operation is
# a concrete type parameter. Julia specializes `eval_sdf` on the full tree
# type, and KernelAbstractions compiles it to GPU code. No command buffer,
# no interpreter - just compiled arithmetic.
#
# Example:
#   gpu_tree = to_gpu_op(sdf_node)
#   # typeof(gpu_tree) == GPUUnion{GPUTranslation{GPUSphere}, GPURect}
#   # eval_sdf(gpu_tree, pos) is fully specialized at compile time

# ============================================================================
# Shapes (leaf nodes)
# ============================================================================
using GLMakie
using Makie: SDF, SDFBrickmap, CSG, free_brick!, get_or_create_brick,
    finish_brick_update!,
    set_interpolated_color!,
    set_static_color!,
    finish_update!,
    N0f8
using KernelAbstractions, Atomix, ShaderAbstractions

struct GPUSphere
    radius::Float32
    color::RGBAf
end

struct GPUEllipsoid
    radii::Vec3f
    color::RGBAf
end

struct GPURect
    widths::Vec3f
    color::RGBAf
end

struct GPUOctahedron
    radius::Float32
    color::RGBAf
end

struct GPUPyramid
    width::Float32
    height::Float32
    color::RGBAf
end

struct GPUTorus
    r_outer::Float32
    r_inner::Float32
    color::RGBAf
end

struct GPUCappedTorus
    opening_angle::Float32
    r_outer::Float32
    r_inner::Float32
    color::RGBAf
end

struct GPUCapsule
    radius::Float32
    height::Float32
    color::RGBAf
end

struct GPUCylinder
    radius::Float32
    height::Float32
    color::RGBAf
end

struct GPUCone
    radius::Float32
    height::Float32
    color::RGBAf
end

struct GPUCappedCone
    height::Float32
    r_bottom::Float32
    r_top::Float32
    color::RGBAf
end

struct GPUBoxFrame
    widths::Vec3f
    line_width::Float32
    color::RGBAf
end

struct GPULink
    len::Float32
    r_outer::Float32
    r_inner::Float32
    color::RGBAf
end

# ============================================================================
# Prefix transforms (wrap a child, transform position before evaluation)
# ============================================================================

struct GPUTranslation{C}
    child::C
    offset::Vec3f
end

struct GPURotation{C}
    child::C
    q::Quaternionf
end

struct GPUMirror{C}
    child::C
    axis::Vec3f
end

struct GPURevolution{C}
    child::C
    offset::Float32
end

struct GPUElongate{C}
    child::C
    h::Vec3f
end

struct GPUInfiniteRepetition{C}
    child::C
    period::Vec3f
end

struct GPULimitedRepetition{C}
    child::C
    period::Vec3f
    limits::Vec3f
end

struct GPUTwist{C}
    child::C
    k::Float32
end

struct GPUBend{C}
    child::C
    k::Float32
end

# ============================================================================
# Merge operations (binary, left-folded for N>2 children)
# ============================================================================

struct GPUUnion{A, B}
    a::A
    b::B
end

struct GPUSubtraction{A, B}
    a::A
    b::B
end

struct GPUIntersection{A, B}
    a::A
    b::B
end

struct GPUXor{A, B}
    a::A
    b::B
end

struct GPUSmoothUnion{A, B}
    a::A
    b::B
    k::Float32
end

struct GPUSmoothSubtraction{A, B}
    a::A
    b::B
    k::Float32
end

struct GPUSmoothIntersection{A, B}
    a::A
    b::B
    k::Float32
end

struct GPUSmoothXor{A, B}
    a::A
    b::B
    k::Float32
end

# ============================================================================
# Postfix operations (wrap a child, modify the SDF result)
# ============================================================================

struct GPUExtrusion{C}
    child::C
    h::Vec3f
end

struct GPURounding{C}
    child::C
    r::Float32
end

struct GPUOnion{C}
    child::C
    thickness::Float32
end

# ============================================================================
# eval_sdf: fully inlined, type-specialized
# Returns (sdf::Float32, color::RGBAf) for every op type.
# ============================================================================

# ---- Shapes ----

@inline eval_sdf(op::GPUSphere, pos::Point3f) = (SDF.OP.sphere(pos, op.radius), op.color)
@inline eval_sdf(op::GPUEllipsoid, pos::Point3f) = (SDF.OP.ellipsoid(pos, op.radii), op.color)
@inline eval_sdf(op::GPURect, pos::Point3f) = (SDF.OP.rect(pos, op.widths), op.color)
@inline eval_sdf(op::GPUOctahedron, pos::Point3f) = (SDF.OP.octahedron(pos, op.radius), op.color)
@inline eval_sdf(op::GPUPyramid, pos::Point3f) = (SDF.OP.pyramid(pos, op.width, op.height), op.color)
@inline eval_sdf(op::GPUTorus, pos::Point3f) = (SDF.OP.torus(pos, op.r_outer, op.r_inner), op.color)
@inline eval_sdf(op::GPUCappedTorus, pos::Point3f) = (SDF.OP.capped_torus(pos, op.opening_angle, op.r_outer, op.r_inner), op.color)
@inline eval_sdf(op::GPUCapsule, pos::Point3f) = (SDF.OP.capsule(pos, op.radius, op.height), op.color)
@inline eval_sdf(op::GPUCylinder, pos::Point3f) = (SDF.OP.cylinder(pos, op.radius, op.height), op.color)
@inline eval_sdf(op::GPUCone, pos::Point3f) = (SDF.OP.cone(pos, op.radius, op.height), op.color)
@inline eval_sdf(op::GPUCappedCone, pos::Point3f) = (SDF.OP.capped_cone(pos, op.height, op.r_bottom, op.r_top), op.color)
@inline eval_sdf(op::GPUBoxFrame, pos::Point3f) = (SDF.OP.box_frame(pos, op.widths, op.line_width), op.color)
@inline eval_sdf(op::GPULink, pos::Point3f) = (SDF.OP.link(pos, op.len, op.r_outer, op.r_inner), op.color)

# ---- Prefixes ----

@inline eval_sdf(op::GPUTranslation, pos::Point3f) = eval_sdf(op.child, SDF.OP.translation(pos, op.offset))
@inline eval_sdf(op::GPURotation, pos::Point3f) = eval_sdf(op.child, SDF.OP.rotation(pos, op.q))
@inline eval_sdf(op::GPUMirror, pos::Point3f) = eval_sdf(op.child, SDF.OP.mirror(pos, op.axis))
@inline eval_sdf(op::GPURevolution, pos::Point3f) = eval_sdf(op.child, SDF.OP.revolution(pos, op.offset))
@inline eval_sdf(op::GPUElongate, pos::Point3f) = eval_sdf(op.child, SDF.OP.elongate(pos, op.h))
@inline eval_sdf(op::GPUInfiniteRepetition, pos::Point3f) = eval_sdf(op.child, SDF.OP.infinite_repetition(pos, op.period))
@inline eval_sdf(op::GPULimitedRepetition, pos::Point3f) = eval_sdf(op.child, SDF.OP.limited_repetition(pos, op.period, op.limits))
@inline eval_sdf(op::GPUTwist, pos::Point3f) = eval_sdf(op.child, SDF.OP.twist(pos, op.k))
@inline eval_sdf(op::GPUBend, pos::Point3f) = eval_sdf(op.child, SDF.OP.bend(pos, op.k))

# ---- Merges ----

@inline function eval_sdf(op::GPUUnion, pos::Point3f)
    s1, c1 = eval_sdf(op.a, pos)
    s2, c2 = eval_sdf(op.b, pos)
    return SDF.OP.union(s1, s2, c1, c2)
end

@inline function eval_sdf(op::GPUSubtraction, pos::Point3f)
    s1, c1 = eval_sdf(op.a, pos)
    s2, c2 = eval_sdf(op.b, pos)
    return SDF.OP.difference(s1, s2, c1, c2)
end

@inline function eval_sdf(op::GPUIntersection, pos::Point3f)
    s1, c1 = eval_sdf(op.a, pos)
    s2, c2 = eval_sdf(op.b, pos)
    return SDF.OP.intersection(s1, s2, c1, c2)
end

@inline function eval_sdf(op::GPUXor, pos::Point3f)
    s1, c1 = eval_sdf(op.a, pos)
    s2, c2 = eval_sdf(op.b, pos)
    return SDF.OP.xor(s1, s2, c1, c2)
end

@inline function eval_sdf(op::GPUSmoothUnion, pos::Point3f)
    s1, c1 = eval_sdf(op.a, pos)
    s2, c2 = eval_sdf(op.b, pos)
    return SDF.OP.smooth_union(s1, s2, c1, c2, op.k)
end

@inline function eval_sdf(op::GPUSmoothSubtraction, pos::Point3f)
    s1, c1 = eval_sdf(op.a, pos)
    s2, c2 = eval_sdf(op.b, pos)
    return SDF.OP.smooth_difference(s1, s2, c1, c2, op.k)
end

@inline function eval_sdf(op::GPUSmoothIntersection, pos::Point3f)
    s1, c1 = eval_sdf(op.a, pos)
    s2, c2 = eval_sdf(op.b, pos)
    return SDF.OP.smooth_intersection(s1, s2, c1, c2, op.k)
end

@inline function eval_sdf(op::GPUSmoothXor, pos::Point3f)
    s1, c1 = eval_sdf(op.a, pos)
    s2, c2 = eval_sdf(op.b, pos)
    return SDF.OP.smooth_xor(s1, s2, c1, c2, op.k)
end

# ---- Postfixes ----

@inline function eval_sdf(op::GPUExtrusion, pos::Point3f)
    sdf, color = eval_sdf(op.child, pos)
    return SDF.OP.extrusion(pos, sdf, op.h), color
end

@inline function eval_sdf(op::GPURounding, pos::Point3f)
    sdf, color = eval_sdf(op.child, pos)
    return SDF.OP.rounding(pos, sdf, op.r), color
end

@inline function eval_sdf(op::GPUOnion, pos::Point3f)
    sdf, color = eval_sdf(op.child, pos)
    return SDF.OP.onion(pos, sdf, op.thickness), color
end

# ============================================================================
# SDF.Node → GPU op tree conversion
# ============================================================================

function to_gpu_op(node::SDF.Node)
    if isempty(node.children)
        # leaf: shape
        op = _make_shape(node.commands[node.main_idx])
    else
        # merge: convert children, fold left with merge op
        gpu_children = map(to_gpu_op, node.children)
        op = gpu_children[1]
        merge_cmd = node.commands[node.main_idx]
        for i in 2:length(gpu_children)
            op = _make_merge(merge_cmd, op, gpu_children[i])
        end
    end

    # wrap postfixes (innermost applied first)
    for i in node.main_idx+1:length(node.commands)
        op = _wrap_postfix(node.commands[i], op)
    end

    # wrap prefixes (last prefix wraps first = innermost, first prefix = outermost)
    for i in node.main_idx-1:-1:1
        op = _wrap_prefix(node.commands[i], op)
    end

    return op
end

function _make_shape(cmd::SDF.Command)
    d = cmd.data
    color = RGBAf(d[1], d[2], d[3], d[4])

    if cmd.id == :sphere;       return GPUSphere(d[5], color)
    elseif cmd.id == :ellipsoid; return GPUEllipsoid(Vec3f(d[5], d[6], d[7]), color)
    elseif cmd.id == :rect;     return GPURect(Vec3f(d[5], d[6], d[7]), color)
    elseif cmd.id == :octahedron; return GPUOctahedron(d[5], color)
    elseif cmd.id == :pyramid;  return GPUPyramid(d[5], d[6], color)
    elseif cmd.id == :torus;    return GPUTorus(d[5], d[6], color)
    elseif cmd.id == :capped_torus; return GPUCappedTorus(d[5], d[6], d[7], color)
    elseif cmd.id == :capsule;  return GPUCapsule(d[5], d[6], color)
    elseif cmd.id == :cylinder; return GPUCylinder(d[5], d[6], color)
    elseif cmd.id == :cone;     return GPUCone(d[5], d[6], color)
    elseif cmd.id == :capped_cone; return GPUCappedCone(d[5], d[6], d[7], color)
    elseif cmd.id == :box_frame; return GPUBoxFrame(Vec3f(d[5], d[6], d[7]), d[8], color)
    elseif cmd.id == :link;     return GPULink(d[5], d[6], d[7], color)
    else
        error("Unknown shape: $(cmd.id)")
    end
end

function _make_merge(cmd::SDF.Command, a, b)
    d = cmd.data

    if cmd.id == :union;               return GPUUnion(a, b)
    elseif cmd.id == :subtraction;     return GPUSubtraction(a, b)
    elseif cmd.id == :intersection;    return GPUIntersection(a, b)
    elseif cmd.id == :xor;             return GPUXor(a, b)
    elseif cmd.id == :smooth_union;    return GPUSmoothUnion(a, b, d[1])
    elseif cmd.id == :smooth_subtraction; return GPUSmoothSubtraction(a, b, d[1])
    elseif cmd.id == :smooth_intersection; return GPUSmoothIntersection(a, b, d[1])
    elseif cmd.id == :smooth_xor;      return GPUSmoothXor(a, b, d[1])
    else
        error("Unknown merge: $(cmd.id)")
    end
end

function _wrap_prefix(cmd::SDF.Command, child)
    d = cmd.data

    if cmd.id == :translation;    return GPUTranslation(child, Vec3f(d[1], d[2], d[3]))
    elseif cmd.id == :rotation;   return GPURotation(child, Quaternionf(d[1], d[2], d[3], d[4]))
    elseif cmd.id == :mirror;     return GPUMirror(child, Vec3f(d[1], d[2], d[3]))
    elseif cmd.id == :revolution; return GPURevolution(child, d[1])
    elseif cmd.id == :elongate;   return GPUElongate(child, Vec3f(d[1], d[2], d[3]))
    elseif cmd.id == :infinite_repetition; return GPUInfiniteRepetition(child, Vec3f(d[1], d[2], d[3]))
    elseif cmd.id == :limited_repetition;  return GPULimitedRepetition(child, Vec3f(d[1], d[2], d[3]), Vec3f(d[4], d[5], d[6]))
    elseif cmd.id == :twist;      return GPUTwist(child, d[1])
    elseif cmd.id == :bend;       return GPUBend(child, d[1])
    else
        error("Unknown prefix: $(cmd.id)")
    end
end

function _wrap_postfix(cmd::SDF.Command, child)
    d = cmd.data

    if cmd.id == :extrusion;   return GPUExtrusion(child, Vec3f(d[1], d[2], d[3]))
    elseif cmd.id == :rounding; return GPURounding(child, d[1])
    elseif cmd.id == :onion;    return GPUOnion(child, d[1])
    else
        error("Unknown postfix: $(cmd.id)")
    end
end

# ============================================================================
# KA kernels
# ============================================================================

using KernelAbstractions
import Atomix

struct BrickWorkItem
    i::Int32
    j::Int32
    k::Int32
    origin::Point3f
end

# Cull bricks: check center-point SDF, push qualifying bricks to work queue
@kernel function gpu_cull_bricks_kernel!(
        work_items, work_count, # output queue + atomic counter
        gpu_tree,               # the type-specialized SDF tree
        mini::Point3f, delta::Vec3f, brickradius::Float32,
        low_i::Int32, low_j::Int32, low_k::Int32,
        dim_i::Int32, dim_j::Int32, dim_k::Int32
    )
    idx = @index(Global)
    total = dim_i * dim_j * dim_k
    if idx <= total
        # linear -> (i,j,k) within update region
        li = Int32((idx - 1) % dim_i)
        lj = Int32(((idx - 1) ÷ dim_i) % dim_j)
        lk = Int32((idx - 1) ÷ (dim_i * dim_j))
        i = li + low_i
        j = lj + low_j
        k = lk + low_k

        pos = Point3f(
            mini[1] + delta[1] * (i - 0.5f0),
            mini[2] + delta[2] * (j - 0.5f0),
            mini[3] + delta[3] * (k - 0.5f0)
        )

        sdf, _ = eval_sdf(gpu_tree, pos)
        if abs(sdf) < brickradius
            slot = Atomix.@atomic work_count[1] += Int32(1)
            work_items[slot] = BrickWorkItem(i, j, k, pos)
        end
    end
end

# Evaluate SDF + color at all sample points for queued bricks
@kernel function gpu_eval_bricks_kernel!(
        output_sdf, output_color, # (bricksize^3 * max_bricks,)
        work_items, n_bricks,     # from cull kernel
        gpu_tree,                 # type-specialized SDF tree
        brick_delta::Vec3f, bricksize::Int32
    )
    idx = @index(Global)
    bs3 = bricksize * bricksize * bricksize
    brick_idx = Int32((idx - Int32(1)) ÷ bs3 + Int32(1))
    if brick_idx <= n_bricks
        local_idx = Int32((idx - Int32(1)) % bs3)
        li = local_idx % bricksize
        lj = (local_idx ÷ bricksize) % bricksize
        lk = local_idx ÷ (bricksize * bricksize)

        work = work_items[brick_idx]
        # origin of the brick (bottom-left corner)
        origin = work.origin - Point3f(0.5f0, 0.5f0, 0.5f0) .* brick_delta .* (bricksize - Int32(1))

        pos = origin + brick_delta .* Point3f(li, lj, lk)

        sdf, color = eval_sdf(gpu_tree, pos)
        output_sdf[idx] = sdf
        output_color[idx] = color
    end
end

# ============================================================================
# CPU orchestration
# ============================================================================

function gpu_update_brickmap!(
        brickmap::SDFBrickmap, bb::Rect3f, root::SDF.Node,
        regions_to_update::Vector{Rect3f},
        backend # KernelAbstractions backend, e.g. CPU() or CUDABackend()
    )
    isempty(regions_to_update) && return

    # Convert tree to GPU-specialized type
    gpu_tree = to_gpu_op(root)

    N_blocks = size(brickmap.indices, 1)
    delta = widths(bb) ./ N_blocks
    mini = minimum(bb)

    raw_update_bb = reduce(Base.union, regions_to_update, init = Rect3f())
    low = trunc.(Int32, clamp.(fld.(minimum(raw_update_bb) .- mini, delta), 0, N_blocks-1)) .+ Int32(1)
    high = trunc.(Int32, clamp.(cld.(maximum(raw_update_bb) .- mini, delta), 1, N_blocks))

    box_scale = norm(widths(bb))
    brickdiameter = sqrt(3.0f0) * box_scale / (N_blocks - 1)
    brickradius = 0.5f0 * brickdiameter

    bricksize = Int32(brickmap.bricksize)
    brick_delta = Vec3f(delta ./ (bricksize - 1))
    uint8_scale = 127.5f0 * bricksize / brickdiameter

    dims = Int32.(high .- low .+ 1)
    total_cells = prod(dims)

    # Allocate GPU buffers
    work_items = KernelAbstractions.allocate(backend, BrickWorkItem, total_cells)
    work_count = KernelAbstractions.zeros(backend, Int32, 1)

    # Phase 1: cull bricks on GPU
    gpu_cull_bricks_kernel!(backend, 256)(
        work_items, work_count, gpu_tree,
        Point3f(mini), Vec3f(delta), brickradius,
        low[1], low[2], low[3],
        dims[1], dims[2], dims[3];
        ndrange = total_cells
    )
    KernelAbstractions.synchronize(backend)

    n_bricks = Int(Array(work_count)[1])
    n_bricks == 0 && return
    @info "GPU cull: $n_bricks / $total_cells bricks need evaluation"

    # Phase 2: evaluate SDF at all sample points
    bs3 = Int(bricksize)^3
    total_samples = n_bricks * bs3
    output_sdf = KernelAbstractions.allocate(backend, Float32, total_samples)
    output_color = KernelAbstractions.allocate(backend, RGBAf, total_samples)

    gpu_eval_bricks_kernel!(backend, 64)(
        output_sdf, output_color,
        work_items, Int32(n_bricks),
        gpu_tree,
        brick_delta, bricksize;
        ndrange = total_samples
    )
    KernelAbstractions.synchronize(backend)

    # Phase 3: copy results back to CPU and do brick management
    cpu_work = Array(work_items)[1:n_bricks]
    cpu_sdf = Array(output_sdf)
    cpu_color = Array(output_color)

    for bi in 1:n_bricks
        work = cpu_work[bi]
        i, j, k = Int(work.i), Int(work.j), Int(work.k)
        sample_range = (bi-1)*bs3+1 : bi*bs3

        brick_sdfs = @view cpu_sdf[sample_range]
        brick_colors = @view cpu_color[sample_range]

        # Same analysis as update_brick! (lines 1452-1476 of csgplot.jl)
        contains_positive = false
        contains_negative = false
        contains_resolvable = false
        contains_multiple_colors = false
        first_color = brick_colors[1]
        first_color_set = false

        for si in eachindex(brick_sdfs)
            sdf = brick_sdfs[si]
            f_normed = uint8_scale * sdf
            contains_negative |= sdf <= 0
            contains_positive |= sdf >= 0
            is_resolvable = abs(f_normed) < 127.5f0
            contains_resolvable |= is_resolvable
            if !contains_multiple_colors && is_resolvable
                if !first_color_set
                    first_color = brick_colors[si]
                    first_color_set = true
                elseif brick_colors[si] != first_color
                    contains_multiple_colors = true
                end
            elseif contains_multiple_colors && contains_negative && contains_positive
                break
            end
        end

        if contains_resolvable
            brick_idx, sdf_brick = get_or_create_brick(brickmap, i, j, k)
            @assert brick_idx > 0
            @inbounds for si in 1:length(sdf_brick)
                f_normed = clamp(uint8_scale * brick_sdfs[si] + 128, 0, 255.9)
                sdf_brick[si] = N0f8(trunc(UInt8, f_normed), nothing)
            end
            finish_brick_update!(brickmap, brick_idx)

            if contains_multiple_colors
                set_interpolated_color!(brickmap, brick_idx, brick_colors)
            else
                set_static_color!(brickmap, brick_idx, first_color)
            end
        else
            free_brick!(brickmap, i, j, k)
        end
    end

    # Also free bricks that were in the update region but didn't pass culling.
    # The cull kernel only outputs bricks that DO have nearby surface.
    # Any brick in the update region NOT in the output list should be freed.
    # (For now, we skip this - a full implementation would track which indices
    # were touched. The current CPU path handles this via in_changed_region checks.)
    # TODO: either do a second pass to free stale bricks, or track them in the cull kernel.

    ShaderAbstractions.update!(brickmap.indices)
    finish_update!(brickmap)

    return
end

# ============================================================================
# Demo
# ============================================================================

function demo_gpu_sdf(; backend=AMDGPU.ROCBackend(), bricksize=8, N_blocks=32)
    sdf_tree = CSG.diff(
        CSG.intersect(
            CSG.smooth_union(
                CSG.Cylinder(0.2, 0.7; color=:lightgray),
                CSG.union(
                    map(1:4) do n
                        CSG.Rect(
                            Vec3f(0.1, 0.07, 0.2);
                            color=:lightgray,
                            translation=0.8 * Vec3f(cos(n * pi / 8 - pi / 16), sin(n * pi / 8 - pi / 16), 0),
                            rotation=qrotation(Vec3f(0, 0, 1), -n * pi / 8 + pi / 16),
                        )
                    end...;
                    mirror=(true, true, false),
                );
                smooth=0.02,
            ),
            CSG.Cylinder(0.1, 1; color=:orange),
        ),
        CSG.Cylinder(0.2, 0.4),
    )
    SDF.calculate_global_bboxes!(sdf_tree)

    bb = Rect3f(Point3f(-1), Vec3f(2))
    bm_size = N_blocks * (bricksize - 1) + 1
    brickmap = SDFBrickmap(bricksize, bm_size)
    regions = Rect3f[sdf_tree.bbox[]]
    @time gpu_update_brickmap!(brickmap, bb, sdf_tree, regions, backend)

    fig = Figure()
    ax = LScene(fig[1, 1])
    ep = Makie.EndPoints(-1.0, 1.0)
    volume!(ax, ep, ep, ep, brickmap, algorithm=:sdf, isorange=1e-5)
    display(fig)
    return fig
end

# Reduced type-explosion SDF evaluation using function pointers
#
# Two structs only:
#   Geometry       - leaf node, stores a C function pointer for the SDF primitive
#   Operation{A,B} - inner node, stores a C function pointer for the math + kind tag
#
# Function pointers are Ptr{Cvoid} from @cfunction -- isbits, type-erased,
# no type parameters from the function identity. Type explosion comes only
# from the tree shape (Operation{A,B} nesting), not from which shape/op is used.

using GLMakie
using Makie: SDF, SDFBrickmap, CSG, free_brick!, get_or_create_brick,
    finish_brick_update!,
    set_interpolated_color!,
    set_static_color!,
    finish_update!,
    N0f8
using KernelAbstractions, Atomix, ShaderAbstractions

# ============================================================================
# Return type for merge operations (isbits, C-ABI compatible)
# ============================================================================

struct SDFResult
    sdf::Float32
    color::RGBAf
end

# ============================================================================
# Structs
# ============================================================================

const PREFIX  = UInt8(1)
const MERGE   = UInt8(2)
const POSTFIX = UInt8(3)

struct Geometry
    func::Ptr{Cvoid}   # @cfunction: (Point3f, Vec4f) -> Float32
    params::Vec4f
    color::RGBAf
end

struct Operation{A, B}
    kind::UInt8         # PREFIX, MERGE, or POSTFIX
    func::Ptr{Cvoid}   # @cfunction (signature depends on kind)
    child_a::A
    child_b::B          # Nothing for unary ops
    params1::Vec4f
    params2::Vec4f
end

# ============================================================================
# eval_sdf
# ============================================================================

@inline eval_sdf(::Nothing, ::Point3f) = (0f0, RGBAf(0, 0, 0, 0))

@inline function eval_sdf(g::Geometry, pos::Point3f)
    sdf = ccall(g.func, Float32, (Point3f, Vec4f), pos, g.params)
    return sdf, g.color
end

function eval_sdf(op::Operation, pos::Point3f)
    if op.kind == PREFIX
        new_pos = ccall(op.func, Point3f, (Point3f, Vec4f, Vec4f), pos, op.params1, op.params2)
        return eval_sdf(op.child_a, new_pos)
    elseif op.kind == MERGE
        s1, c1 = eval_sdf(op.child_a, pos)
        s2, c2 = eval_sdf(op.child_b, pos)
        r = ccall(op.func, SDFResult, (Float32, Float32, RGBAf, RGBAf, Vec4f), s1, s2, c1, c2, op.params1)
        return r.sdf, r.color
    else # POSTFIX
        sdf, color = eval_sdf(op.child_a, pos)
        new_sdf = ccall(op.func, Float32, (Point3f, Float32, Vec4f), pos, sdf, op.params1)
        return new_sdf, color
    end
end

# ============================================================================
# Shape wrappers: (Point3f, Vec4f) -> Float32
# ============================================================================

_c_sphere(pos::Point3f, p::Vec4f)::Float32       = SDF.OP.sphere(pos, p[1])
_c_ellipsoid(pos::Point3f, p::Vec4f)::Float32    = SDF.OP.ellipsoid(pos, Vec3f(p[1], p[2], p[3]))
_c_rect(pos::Point3f, p::Vec4f)::Float32         = SDF.OP.rect(pos, Vec3f(p[1], p[2], p[3]))
_c_octahedron(pos::Point3f, p::Vec4f)::Float32   = SDF.OP.octahedron(pos, p[1])
_c_pyramid(pos::Point3f, p::Vec4f)::Float32      = SDF.OP.pyramid(pos, p[1], p[2])
_c_torus(pos::Point3f, p::Vec4f)::Float32        = SDF.OP.torus(pos, p[1], p[2])
_c_capped_torus(pos::Point3f, p::Vec4f)::Float32 = SDF.OP.capped_torus(pos, p[1], p[2], p[3])
_c_capsule(pos::Point3f, p::Vec4f)::Float32      = SDF.OP.capsule(pos, p[1], p[2])
_c_cylinder(pos::Point3f, p::Vec4f)::Float32     = SDF.OP.cylinder(pos, p[1], p[2])
_c_cone(pos::Point3f, p::Vec4f)::Float32         = SDF.OP.cone(pos, p[1], p[2])
_c_capped_cone(pos::Point3f, p::Vec4f)::Float32  = SDF.OP.capped_cone(pos, p[1], p[2], p[3])
_c_box_frame(pos::Point3f, p::Vec4f)::Float32    = SDF.OP.box_frame(pos, Vec3f(p[1], p[2], p[3]), p[4])
_c_link(pos::Point3f, p::Vec4f)::Float32         = SDF.OP.link(pos, p[1], p[2], p[3])

# ============================================================================
# Prefix wrappers: (Point3f, Vec4f, Vec4f) -> Point3f
# ============================================================================

_c_translation(pos::Point3f, p1::Vec4f, p2::Vec4f)::Point3f         = SDF.OP.translation(pos, Vec3f(p1[1], p1[2], p1[3]))
_c_rotation(pos::Point3f, p1::Vec4f, p2::Vec4f)::Point3f            = SDF.OP.rotation(pos, Quaternionf(p1[1], p1[2], p1[3], p1[4]))
_c_mirror(pos::Point3f, p1::Vec4f, p2::Vec4f)::Point3f              = SDF.OP.mirror(pos, Vec3f(p1[1], p1[2], p1[3]))
_c_revolution(pos::Point3f, p1::Vec4f, p2::Vec4f)::Point3f          = SDF.OP.revolution(pos, p1[1])
_c_elongate(pos::Point3f, p1::Vec4f, p2::Vec4f)::Point3f            = SDF.OP.elongate(pos, Vec3f(p1[1], p1[2], p1[3]))
_c_infinite_rep(pos::Point3f, p1::Vec4f, p2::Vec4f)::Point3f        = SDF.OP.infinite_repetition(pos, Vec3f(p1[1], p1[2], p1[3]))
_c_limited_rep(pos::Point3f, p1::Vec4f, p2::Vec4f)::Point3f         = SDF.OP.limited_repetition(pos, Vec3f(p1[1], p1[2], p1[3]), Vec3f(p2[1], p2[2], p2[3]))
_c_twist(pos::Point3f, p1::Vec4f, p2::Vec4f)::Point3f               = SDF.OP.twist(pos, p1[1])
_c_bend(pos::Point3f, p1::Vec4f, p2::Vec4f)::Point3f                = SDF.OP.bend(pos, p1[1])

# ============================================================================
# Merge wrappers: (Float32, Float32, RGBAf, RGBAf, Vec4f) -> SDFResult
# ============================================================================

_c_union(s1::Float32, s2::Float32, c1::RGBAf, c2::RGBAf, p::Vec4f)::SDFResult               = SDFResult(SDF.OP.union(s1, s2, c1, c2)...)
_c_subtraction(s1::Float32, s2::Float32, c1::RGBAf, c2::RGBAf, p::Vec4f)::SDFResult         = SDFResult(SDF.OP.difference(s1, s2, c1, c2)...)
_c_intersection(s1::Float32, s2::Float32, c1::RGBAf, c2::RGBAf, p::Vec4f)::SDFResult        = SDFResult(SDF.OP.intersection(s1, s2, c1, c2)...)
_c_xor(s1::Float32, s2::Float32, c1::RGBAf, c2::RGBAf, p::Vec4f)::SDFResult                 = SDFResult(SDF.OP.xor(s1, s2, c1, c2)...)
_c_smooth_union(s1::Float32, s2::Float32, c1::RGBAf, c2::RGBAf, p::Vec4f)::SDFResult        = SDFResult(SDF.OP.smooth_union(s1, s2, c1, c2, p[1])...)
_c_smooth_subtraction(s1::Float32, s2::Float32, c1::RGBAf, c2::RGBAf, p::Vec4f)::SDFResult  = SDFResult(SDF.OP.smooth_difference(s1, s2, c1, c2, p[1])...)
_c_smooth_intersection(s1::Float32, s2::Float32, c1::RGBAf, c2::RGBAf, p::Vec4f)::SDFResult = SDFResult(SDF.OP.smooth_intersection(s1, s2, c1, c2, p[1])...)
_c_smooth_xor(s1::Float32, s2::Float32, c1::RGBAf, c2::RGBAf, p::Vec4f)::SDFResult          = SDFResult(SDF.OP.smooth_xor(s1, s2, c1, c2, p[1])...)

# ============================================================================
# Postfix wrappers: (Point3f, Float32, Vec4f) -> Float32
# ============================================================================

_c_extrusion(pos::Point3f, sdf::Float32, p::Vec4f)::Float32 = SDF.OP.extrusion(pos, sdf, Vec3f(p[1], p[2], p[3]))
_c_rounding(pos::Point3f, sdf::Float32, p::Vec4f)::Float32  = SDF.OP.rounding(pos, sdf, p[1])
_c_onion(pos::Point3f, sdf::Float32, p::Vec4f)::Float32     = SDF.OP.onion(pos, sdf, p[1])

# ============================================================================
# @cfunction pointers (created at include time)
# ============================================================================

const _ShapeSig   = Tuple{Point3f, Vec4f}
const _PrefixSig  = Tuple{Point3f, Vec4f, Vec4f}
const _MergeSig   = Tuple{Float32, Float32, RGBAf, RGBAf, Vec4f}
const _PostfixSig = Tuple{Point3f, Float32, Vec4f}

# Shapes
const FPTR_SPHERE       = @cfunction(_c_sphere,       Float32, (Point3f, Vec4f))
const FPTR_ELLIPSOID    = @cfunction(_c_ellipsoid,    Float32, (Point3f, Vec4f))
const FPTR_RECT         = @cfunction(_c_rect,         Float32, (Point3f, Vec4f))
const FPTR_OCTAHEDRON   = @cfunction(_c_octahedron,   Float32, (Point3f, Vec4f))
const FPTR_PYRAMID      = @cfunction(_c_pyramid,      Float32, (Point3f, Vec4f))
const FPTR_TORUS        = @cfunction(_c_torus,        Float32, (Point3f, Vec4f))
const FPTR_CAPPED_TORUS = @cfunction(_c_capped_torus, Float32, (Point3f, Vec4f))
const FPTR_CAPSULE      = @cfunction(_c_capsule,      Float32, (Point3f, Vec4f))
const FPTR_CYLINDER     = @cfunction(_c_cylinder,     Float32, (Point3f, Vec4f))
const FPTR_CONE         = @cfunction(_c_cone,         Float32, (Point3f, Vec4f))
const FPTR_CAPPED_CONE  = @cfunction(_c_capped_cone,  Float32, (Point3f, Vec4f))
const FPTR_BOX_FRAME    = @cfunction(_c_box_frame,    Float32, (Point3f, Vec4f))
const FPTR_LINK         = @cfunction(_c_link,         Float32, (Point3f, Vec4f))

# Prefixes
const FPTR_TRANSLATION  = @cfunction(_c_translation,  Point3f, (Point3f, Vec4f, Vec4f))
const FPTR_ROTATION     = @cfunction(_c_rotation,     Point3f, (Point3f, Vec4f, Vec4f))
const FPTR_MIRROR       = @cfunction(_c_mirror,       Point3f, (Point3f, Vec4f, Vec4f))
const FPTR_REVOLUTION   = @cfunction(_c_revolution,   Point3f, (Point3f, Vec4f, Vec4f))
const FPTR_ELONGATE     = @cfunction(_c_elongate,     Point3f, (Point3f, Vec4f, Vec4f))
const FPTR_INFINITE_REP = @cfunction(_c_infinite_rep, Point3f, (Point3f, Vec4f, Vec4f))
const FPTR_LIMITED_REP  = @cfunction(_c_limited_rep,  Point3f, (Point3f, Vec4f, Vec4f))
const FPTR_TWIST        = @cfunction(_c_twist,        Point3f, (Point3f, Vec4f, Vec4f))
const FPTR_BEND         = @cfunction(_c_bend,         Point3f, (Point3f, Vec4f, Vec4f))

# Merges
const FPTR_UNION              = @cfunction(_c_union,              SDFResult, (Float32, Float32, RGBAf, RGBAf, Vec4f))
const FPTR_SUBTRACTION        = @cfunction(_c_subtraction,        SDFResult, (Float32, Float32, RGBAf, RGBAf, Vec4f))
const FPTR_INTERSECTION       = @cfunction(_c_intersection,       SDFResult, (Float32, Float32, RGBAf, RGBAf, Vec4f))
const FPTR_XOR                = @cfunction(_c_xor,                SDFResult, (Float32, Float32, RGBAf, RGBAf, Vec4f))
const FPTR_SMOOTH_UNION       = @cfunction(_c_smooth_union,       SDFResult, (Float32, Float32, RGBAf, RGBAf, Vec4f))
const FPTR_SMOOTH_SUBTRACTION = @cfunction(_c_smooth_subtraction, SDFResult, (Float32, Float32, RGBAf, RGBAf, Vec4f))
const FPTR_SMOOTH_INTERSECTION= @cfunction(_c_smooth_intersection,SDFResult, (Float32, Float32, RGBAf, RGBAf, Vec4f))
const FPTR_SMOOTH_XOR         = @cfunction(_c_smooth_xor,         SDFResult, (Float32, Float32, RGBAf, RGBAf, Vec4f))

# Postfixes
const FPTR_EXTRUSION = @cfunction(_c_extrusion, Float32, (Point3f, Float32, Vec4f))
const FPTR_ROUNDING  = @cfunction(_c_rounding,  Float32, (Point3f, Float32, Vec4f))
const FPTR_ONION     = @cfunction(_c_onion,     Float32, (Point3f, Float32, Vec4f))

# ============================================================================
# SDF.Node -> Geometry/Operation tree conversion
# ============================================================================

const _z4 = zero(Vec4f)

const _shape_ptrs = Dict{Symbol, Ptr{Cvoid}}(
    :sphere       => FPTR_SPHERE,       :ellipsoid    => FPTR_ELLIPSOID,
    :rect         => FPTR_RECT,         :octahedron   => FPTR_OCTAHEDRON,
    :pyramid      => FPTR_PYRAMID,      :torus        => FPTR_TORUS,
    :capped_torus => FPTR_CAPPED_TORUS, :capsule      => FPTR_CAPSULE,
    :cylinder     => FPTR_CYLINDER,     :cone         => FPTR_CONE,
    :capped_cone  => FPTR_CAPPED_CONE,  :box_frame    => FPTR_BOX_FRAME,
    :link         => FPTR_LINK,
)

const _shape_nparams = Dict{Symbol, Int}(
    :sphere => 1, :ellipsoid => 3, :rect => 3, :octahedron => 1,
    :pyramid => 2, :torus => 2, :capped_torus => 3, :capsule => 2,
    :cylinder => 2, :cone => 2, :capped_cone => 3, :box_frame => 4, :link => 3,
)

const _merge_ptrs = Dict{Symbol, Ptr{Cvoid}}(
    :union => FPTR_UNION, :subtraction => FPTR_SUBTRACTION,
    :intersection => FPTR_INTERSECTION, :xor => FPTR_XOR,
    :smooth_union => FPTR_SMOOTH_UNION, :smooth_subtraction => FPTR_SMOOTH_SUBTRACTION,
    :smooth_intersection => FPTR_SMOOTH_INTERSECTION, :smooth_xor => FPTR_SMOOTH_XOR,
)

const _prefix_ptrs = Dict{Symbol, Ptr{Cvoid}}(
    :translation => FPTR_TRANSLATION, :rotation => FPTR_ROTATION,
    :mirror => FPTR_MIRROR, :revolution => FPTR_REVOLUTION,
    :elongate => FPTR_ELONGATE, :infinite_repetition => FPTR_INFINITE_REP,
    :limited_repetition => FPTR_LIMITED_REP, :twist => FPTR_TWIST, :bend => FPTR_BEND,
)

const _postfix_ptrs = Dict{Symbol, Ptr{Cvoid}}(
    :extrusion => FPTR_EXTRUSION, :rounding => FPTR_ROUNDING, :onion => FPTR_ONION,
)

function to_gpu_op_v2(node::SDF.Node)
    if isempty(node.children)
        op = _make_shape_v2(node.commands[node.main_idx])
    else
        gpu_children = map(to_gpu_op_v2, node.children)
        op = gpu_children[1]
        merge_cmd = node.commands[node.main_idx]
        for i in 2:length(gpu_children)
            op = _make_merge_v2(merge_cmd, op, gpu_children[i])
        end
    end

    for i in node.main_idx+1:length(node.commands)
        op = _wrap_postfix_v2(node.commands[i], op)
    end
    for i in node.main_idx-1:-1:1
        op = _wrap_prefix_v2(node.commands[i], op)
    end

    return op
end

function _make_shape_v2(cmd::SDF.Command)
    d = cmd.data
    color = RGBAf(d[1], d[2], d[3], d[4])
    n = get(_shape_nparams, cmd.id, 0)
    params = Vec4f(
        n >= 1 ? d[5] : 0f0, n >= 2 ? d[6] : 0f0,
        n >= 3 ? d[7] : 0f0, n >= 4 ? d[8] : 0f0,
    )
    fptr = get(_shape_ptrs, cmd.id, C_NULL)
    fptr == C_NULL && error("Unknown shape: $(cmd.id)")
    return Geometry(fptr, params, color)
end

function _make_merge_v2(cmd::SDF.Command, a, b)
    d = cmd.data
    fptr = get(_merge_ptrs, cmd.id, C_NULL)
    fptr == C_NULL && error("Unknown merge: $(cmd.id)")
    p1 = startswith(String(cmd.id), "smooth_") ? Vec4f(d[1], 0, 0, 0) : _z4
    return Operation(MERGE, fptr, a, b, p1, _z4)
end

function _wrap_prefix_v2(cmd::SDF.Command, child)
    d = cmd.data
    fptr = get(_prefix_ptrs, cmd.id, C_NULL)
    fptr == C_NULL && error("Unknown prefix: $(cmd.id)")
    p1 = if cmd.id == :rotation
        Vec4f(d[1], d[2], d[3], d[4])
    elseif cmd.id in (:translation, :mirror, :elongate, :infinite_repetition, :limited_repetition)
        Vec4f(d[1], d[2], d[3], 0)
    else
        Vec4f(d[1], 0, 0, 0)
    end
    p2 = cmd.id == :limited_repetition ? Vec4f(d[4], d[5], d[6], 0) : _z4
    return Operation(PREFIX, fptr, child, nothing, p1, p2)
end

function _wrap_postfix_v2(cmd::SDF.Command, child)
    d = cmd.data
    fptr = get(_postfix_ptrs, cmd.id, C_NULL)
    fptr == C_NULL && error("Unknown postfix: $(cmd.id)")
    n = cmd.id == :extrusion ? 3 : 1
    p1 = Vec4f(d[1], n >= 2 ? d[2] : 0f0, n >= 3 ? d[3] : 0f0, 0f0)
    return Operation(POSTFIX, fptr, child, nothing, p1, _z4)
end

# ============================================================================
# KA kernels
# ============================================================================

struct BrickWorkItem
    i::Int32
    j::Int32
    k::Int32
    origin::Point3f
end

@kernel function gpu_cull_kernel!(
        work_items, work_count, gpu_tree,
        mini::Point3f, delta::Vec3f, brickradius::Float32,
        low_i::Int32, low_j::Int32, low_k::Int32,
        dim_i::Int32, dim_j::Int32, dim_k::Int32
    )
    idx = @index(Global)
    total = dim_i * dim_j * dim_k
    if idx <= total
        li = Int32((idx - 1) % dim_i)
        lj = Int32(((idx - 1) ÷ dim_i) % dim_j)
        lk = Int32((idx - 1) ÷ (dim_i * dim_j))
        i = li + low_i; j = lj + low_j; k = lk + low_k
        pos = Point3f(
            mini[1] + delta[1] * (i - 0.5f0),
            mini[2] + delta[2] * (j - 0.5f0),
            mini[3] + delta[3] * (k - 0.5f0))
        sdf, _ = eval_sdf(gpu_tree, pos)
        if abs(sdf) < brickradius
            slot = Atomix.@atomic work_count[1] += Int32(1)
            work_items[slot] = BrickWorkItem(i, j, k, pos)
        end
    end
end

@kernel function gpu_eval_bricks_kernel!(
        output_sdf, output_color, work_items, n_bricks,
        gpu_tree, brick_delta::Vec3f, bricksize::Int32
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

function gpu_update_brickmap_v2!(
        brickmap::SDFBrickmap, bb::Rect3f, root::SDF.Node,
        regions::Vector{Rect3f}, backend=KernelAbstractions.CPU();
        max_bricks_per_region::Int=8192
    )
    gpu_tree = to_gpu_op_v2(root)

    bricksize = Int32(brickmap.bricksize)
    N_blocks = Int32(size(brickmap.indices.data, 1))
    mini = Point3f(minimum(bb))
    delta = Vec3f(widths(bb) ./ N_blocks)       # brick width (matches CPU path)
    brick_delta = Vec3f(delta ./ (bricksize - 1)) # voxel spacing within a brick

    box_scale = Float32(norm(widths(bb)))
    brickdiameter = Float32(sqrt(3) * box_scale / (N_blocks - 1))
    brickradius = 0.5f0 * brickdiameter
    uint8_scale = 127.5f0 * bricksize / brickdiameter
    bs3 = bricksize * bricksize * bricksize

    for region in regions
        rmin = Point3f(minimum(region))
        rmax = Point3f(maximum(region))
        low = Int32.(trunc.(Int, clamp.(fld.(rmin .- mini, delta), 0, N_blocks - 1)) .+ 1)
        high = Int32.(trunc.(Int, clamp.(cld.(rmax .- mini, delta), 1, N_blocks)))
        dims = high .- low .+ Int32(1)
        total_bricks = Int(dims[1]) * Int(dims[2]) * Int(dims[3])

        work_items = KernelAbstractions.allocate(backend, BrickWorkItem, max_bricks_per_region)
        work_count = KernelAbstractions.allocate(backend, Int32, 1)
        KernelAbstractions.fill!(work_count, Int32(0))

        cull! = gpu_cull_kernel!(backend, 256)
        cull!(work_items, work_count, gpu_tree,
            mini, delta, brickradius,
            low[1], low[2], low[3], dims[1], dims[2], dims[3];
            ndrange=total_bricks)
        KernelAbstractions.synchronize(backend)

        h_count = Array(work_count)
        n_bricks = Int(h_count[1])
        @info "GPU cull: $n_bricks / $total_bricks bricks need evaluation"
        n_bricks == 0 && continue

        output_sdf = KernelAbstractions.allocate(backend, Float32, bs3 * n_bricks)
        output_color = KernelAbstractions.allocate(backend, RGBAf, bs3 * n_bricks)

        eval_k! = gpu_eval_bricks_kernel!(backend, 256)
        eval_k!(output_sdf, output_color, work_items, Int32(n_bricks), gpu_tree,
            brick_delta, bricksize; ndrange=bs3 * n_bricks)
        KernelAbstractions.synchronize(backend)

        h_work = Array(work_items)[1:n_bricks]
        h_sdf = Array(output_sdf)
        h_color = Array(output_color)

        for bi in 1:n_bricks
            work = h_work[bi]
            i, j, k = Int(work.i), Int(work.j), Int(work.k)
            offset = (bi - 1) * bs3
            brick_sdfs = @view h_sdf[offset+1:offset+bs3]
            brick_colors = @view h_color[offset+1:offset+bs3]

            contains_negative = false
            contains_positive = false
            contains_resolvable = false
            first_color = brick_colors[1]
            contains_multiple_colors = false

            for si in 1:bs3
                s = brick_sdfs[si]
                if s < 0; contains_negative = true; end
                if s > 0; contains_positive = true; end
                if abs(s) < brickdiameter; contains_resolvable = true; end
                if brick_colors[si] != first_color; contains_multiple_colors = true; end
                if contains_resolvable && contains_multiple_colors && contains_negative && contains_positive
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
    end

    ShaderAbstractions.update!(brickmap.indices)
    finish_update!(brickmap)
    return
end

# ============================================================================
# Demo (CPU backend)
# ============================================================================

function demo_gpu_sdf_v2(; backend=KernelAbstractions.CPU(), bricksize=8, N_blocks=32)
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
                            rotation=qrotation(Vec3f(0, 0, 1), -n * pi / 8 + pi / 16))
                    end...;
                    mirror=(true, true, false));
                smooth=0.02),
            CSG.Cylinder(0.1, 1; color=:orange)),
        CSG.Cylinder(0.2, 0.4))
    SDF.calculate_global_bboxes!(sdf_tree)

    bb = Rect3f(Point3f(-1), Vec3f(2))
    bm_size = N_blocks * (bricksize - 1) + 1
    brickmap = SDFBrickmap(bricksize, bm_size)
    regions = Rect3f[sdf_tree.bbox[]]
    @time gpu_update_brickmap_v2!(brickmap, bb, sdf_tree, regions, backend)

    fig = Figure()
    ax = LScene(fig[1, 1])
    ep = Makie.EndPoints(-1.0, 1.0)
    volume!(ax, ep, ep, ep, brickmap, algorithm=:sdf, isorange=1e-5)
    display(fig)
    return fig
end

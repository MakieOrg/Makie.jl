using KernelAbstractions, Atomix

module SDF2
    using KernelAbstractions, Atomix, Colors, FixedPointNumbers, LinearAlgebra
    using GeometryBasics
    using Makie: SDF, RGBAf, Quaternionf

    abstract type Node end
    abstract type ShapeNode <: Node end
    abstract type TransformationNode <: Node end
    abstract type PrefixNode <: TransformationNode end
    abstract type PostfixNode <: TransformationNode end
    abstract type MergeNode <: Node end

    ############################################################################
    ### Shape creating Nodes
    ############################################################################

    struct Sphere <: ShapeNode
        radius::Float32
        color::RGBAf
    end

    struct Ellipsoid <: ShapeNode
        radii::Vec3f
        color::RGBAf
    end

    struct Rect <: ShapeNode
        widths::Vec3f
        color::RGBAf
    end

    struct Octahedron <: ShapeNode
        radius::Float32
        color::RGBAf
    end

    struct Pyramid <: ShapeNode
        width::Float32
        height::Float32
        color::RGBAf
    end

    struct Torus <: ShapeNode
        r_outer::Float32
        r_inner::Float32
        color::RGBAf
    end

    struct CappedTorus <: ShapeNode
        opening_angle::Float32
        r_outer::Float32
        r_inner::Float32
        color::RGBAf
    end

    struct Capsule <: ShapeNode
        radius::Float32
        height::Float32
        color::RGBAf
    end

    struct Cylinder <: ShapeNode
        radius::Float32
        height::Float32
        color::RGBAf
    end

    struct Cone <: ShapeNode
        radius::Float32
        height::Float32
        color::RGBAf
    end

    struct CappedCone <: ShapeNode
        height::Float32
        r_bottom::Float32
        r_top::Float32
        color::RGBAf
    end

    struct BoxFrame <: ShapeNode
        widths::Vec3f
        line_width::Float32
        color::RGBAf
    end

    struct Link <: ShapeNode
        len::Float32
        r_outer::Float32
        r_inner::Float32
        color::RGBAf
    end

    @inline eval_sdf(op::Sphere, pos::Point3f) = (SDF.OP.sphere(pos, op.radius), op.color)
    @inline eval_sdf(op::Ellipsoid, pos::Point3f) = (SDF.OP.ellipsoid(pos, op.radii), op.color)
    @inline eval_sdf(op::Rect, pos::Point3f) = (SDF.OP.rect(pos, op.widths), op.color)
    @inline eval_sdf(op::Octahedron, pos::Point3f) = (SDF.OP.octahedron(pos, op.radius), op.color)
    @inline eval_sdf(op::Pyramid, pos::Point3f) = (SDF.OP.pyramid(pos, op.width, op.height), op.color)
    @inline eval_sdf(op::Torus, pos::Point3f) = (SDF.OP.torus(pos, op.r_outer, op.r_inner), op.color)
    @inline eval_sdf(op::CappedTorus, pos::Point3f) = (SDF.OP.capped_torus(pos, op.opening_angle, op.r_outer, op.r_inner), op.color)
    @inline eval_sdf(op::Capsule, pos::Point3f) = (SDF.OP.capsule(pos, op.radius, op.height), op.color)
    @inline eval_sdf(op::Cylinder, pos::Point3f) = (SDF.OP.cylinder(pos, op.radius, op.height), op.color)
    @inline eval_sdf(op::Cone, pos::Point3f) = (SDF.OP.cone(pos, op.radius, op.height), op.color)
    @inline eval_sdf(op::CappedCone, pos::Point3f) = (SDF.OP.capped_cone(pos, op.height, op.r_bottom, op.r_top), op.color)
    @inline eval_sdf(op::BoxFrame, pos::Point3f) = (SDF.OP.box_frame(pos, op.widths, op.line_width), op.color)
    @inline eval_sdf(op::Link, pos::Point3f) = (SDF.OP.link(pos, op.len, op.r_outer, op.r_inner), op.color)


    ############################################################################
    ### Prefix Transformation Nodes
    ############################################################################

    struct Translation{C} <: PrefixNode
        child::C
        offset::Vec3f
    end

    struct Rotation{C} <: PrefixNode
        child::C
        q::Quaternionf
    end

    struct Mirror{C} <: PrefixNode
        child::C
        axis::Vec3f
    end

    struct Revolution{C} <: PrefixNode
        child::C
        offset::Float32
    end

    struct Elongate{C} <: PrefixNode
        child::C
        h::Vec3f
    end

    struct InfiniteRepetition{C} <: PrefixNode
        child::C
        period::Vec3f
    end

    struct LimitedRepetition{C} <: PrefixNode
        child::C
        period::Vec3f
        limits::Vec3f
    end

    struct Twist{C} <: PrefixNode
        child::C
        k::Float32
    end

    struct Bend{C} <: PrefixNode
        child::C
        k::Float32
    end

    @inline eval_sdf(op::Translation, pos::Point3f) = eval_sdf(op.child, SDF.OP.translation(pos, op.offset))
    @inline eval_sdf(op::Rotation, pos::Point3f) = eval_sdf(op.child, SDF.OP.rotation(pos, op.q))
    @inline eval_sdf(op::Mirror, pos::Point3f) = eval_sdf(op.child, SDF.OP.mirror(pos, op.axis))
    @inline eval_sdf(op::Revolution, pos::Point3f) = eval_sdf(op.child, SDF.OP.revolution(pos, op.offset))
    @inline eval_sdf(op::Elongate, pos::Point3f) = eval_sdf(op.child, SDF.OP.elongate(pos, op.h))
    @inline eval_sdf(op::InfiniteRepetition, pos::Point3f) = eval_sdf(op.child, SDF.OP.infinite_repetition(pos, op.period))
    @inline eval_sdf(op::LimitedRepetition, pos::Point3f) = eval_sdf(op.child, SDF.OP.limited_repetition(pos, op.period, op.limits))
    @inline eval_sdf(op::Twist, pos::Point3f) = eval_sdf(op.child, SDF.OP.twist(pos, op.k))
    @inline eval_sdf(op::Bend, pos::Point3f) = eval_sdf(op.child, SDF.OP.bend(pos, op.k))

    ############################################################################
    ### Merge Nodes
    ############################################################################

    struct Union{A, B} <: MergeNode
        a::A
        b::B
    end

    struct Subtraction{A, B} <: MergeNode
        a::A
        b::B
    end

    struct Intersection{A, B} <: MergeNode
        a::A
        b::B
    end

    struct Xor{A, B} <: MergeNode
        a::A
        b::B
    end

    struct SmoothUnion{A, B} <: MergeNode
        a::A
        b::B
        k::Float32
    end

    struct SmoothSubtraction{A, B} <: MergeNode
        a::A
        b::B
        k::Float32
    end

    struct SmoothIntersection{A, B} <: MergeNode
        a::A
        b::B
        k::Float32
    end

    struct SmoothXor{A, B} <: MergeNode
        a::A
        b::B
        k::Float32
    end

    @inline function eval_sdf(op::Union, pos::Point3f)
        s1, c1 = eval_sdf(op.a, pos)
        s2, c2 = eval_sdf(op.b, pos)
        return SDF.OP.union(s1, s2, c1, c2)
    end

    @inline function eval_sdf(op::Subtraction, pos::Point3f)
        s1, c1 = eval_sdf(op.a, pos)
        s2, c2 = eval_sdf(op.b, pos)
        return SDF.OP.difference(s1, s2, c1, c2)
    end

    @inline function eval_sdf(op::Intersection, pos::Point3f)
        s1, c1 = eval_sdf(op.a, pos)
        s2, c2 = eval_sdf(op.b, pos)
        return SDF.OP.intersection(s1, s2, c1, c2)
    end

    @inline function eval_sdf(op::Xor, pos::Point3f)
        s1, c1 = eval_sdf(op.a, pos)
        s2, c2 = eval_sdf(op.b, pos)
        return SDF.OP.xor(s1, s2, c1, c2)
    end

    @inline function eval_sdf(op::SmoothUnion, pos::Point3f)
        s1, c1 = eval_sdf(op.a, pos)
        s2, c2 = eval_sdf(op.b, pos)
        return SDF.OP.smooth_union(s1, s2, c1, c2, op.k)
    end

    @inline function eval_sdf(op::SmoothSubtraction, pos::Point3f)
        s1, c1 = eval_sdf(op.a, pos)
        s2, c2 = eval_sdf(op.b, pos)
        return SDF.OP.smooth_difference(s1, s2, c1, c2, op.k)
    end

    @inline function eval_sdf(op::SmoothIntersection, pos::Point3f)
        s1, c1 = eval_sdf(op.a, pos)
        s2, c2 = eval_sdf(op.b, pos)
        return SDF.OP.smooth_intersection(s1, s2, c1, c2, op.k)
    end

    @inline function eval_sdf(op::SmoothXor, pos::Point3f)
        s1, c1 = eval_sdf(op.a, pos)
        s2, c2 = eval_sdf(op.b, pos)
        return SDF.OP.smooth_xor(s1, s2, c1, c2, op.k)
    end

    ############################################################################
    ### Postfix Transformation
    ############################################################################

    struct Extrusion{C} <: PostfixNode
        child::C
        h::Vec3f
    end

    struct Rounding{C} <: PostfixNode
        child::C
        r::Float32
    end

    struct Onion{C} <: PostfixNode
        child::C
        thickness::Float32
    end

    @inline function eval_sdf(op::Extrusion, pos::Point3f)
        sdf, color = eval_sdf(op.child, pos)
        return SDF.OP.extrusion(pos, sdf, op.h), color
    end

    @inline function eval_sdf(op::Rounding, pos::Point3f)
        sdf, color = eval_sdf(op.child, pos)
        return SDF.OP.rounding(pos, sdf, op.r), color
    end

    @inline function eval_sdf(op::Onion, pos::Point3f)
        sdf, color = eval_sdf(op.child, pos)
        return SDF.OP.onion(pos, sdf, op.thickness), color
    end

    ############################################################################
    ### Tree transformation
    ############################################################################

    function Node(node::SDF.Node)
        if isempty(node.children)
            # leaf: shape
            op = _make_shape(node.commands[node.main_idx])
        else
            # merge: convert children, fold left with merge op
            children = map(Node, node.children)
            op = children[1]
            merge_cmd = node.commands[node.main_idx]
            for i in 2:length(children)
                op = _make_merge(merge_cmd, op, children[i])
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

        if cmd.id == :sphere;           return Sphere(d[5], color)
        elseif cmd.id == :ellipsoid;    return Ellipsoid(Vec3f(d[5], d[6], d[7]), color)
        elseif cmd.id == :rect;         return Rect(Vec3f(d[5], d[6], d[7]), color)
        elseif cmd.id == :octahedron;   return Octahedron(d[5], color)
        elseif cmd.id == :pyramid;      return Pyramid(d[5], d[6], color)
        elseif cmd.id == :torus;        return Torus(d[5], d[6], color)
        elseif cmd.id == :capped_torus; return CappedTorus(d[5], d[6], d[7], color)
        elseif cmd.id == :capsule;      return Capsule(d[5], d[6], color)
        elseif cmd.id == :cylinder;     return Cylinder(d[5], d[6], color)
        elseif cmd.id == :cone;         return Cone(d[5], d[6], color)
        elseif cmd.id == :capped_cone;  return CappedCone(d[5], d[6], d[7], color)
        elseif cmd.id == :box_frame;    return BoxFrame(Vec3f(d[5], d[6], d[7]), d[8], color)
        elseif cmd.id == :link;         return Link(d[5], d[6], d[7], color)
        else
            error("Unknown shape: $(cmd.id)")
        end
    end

    function _make_merge(cmd::SDF.Command, a, b)
        d = cmd.data

        if cmd.id == :union;               return Union(a, b)
        elseif cmd.id == :subtraction;     return Subtraction(a, b)
        elseif cmd.id == :intersection;    return Intersection(a, b)
        elseif cmd.id == :xor;             return Xor(a, b)
        elseif cmd.id == :smooth_union;    return SmoothUnion(a, b, d[1])
        elseif cmd.id == :smooth_subtraction;  return SmoothSubtraction(a, b, d[1])
        elseif cmd.id == :smooth_intersection; return SmoothIntersection(a, b, d[1])
        elseif cmd.id == :smooth_xor;      return SmoothXor(a, b, d[1])
        else
            error("Unknown merge: $(cmd.id)")
        end
    end

    function _wrap_prefix(cmd::SDF.Command, child)
        d = cmd.data

        if cmd.id == :translation;    return Translation(child, Vec3f(d[1], d[2], d[3]))
        elseif cmd.id == :rotation;   return Rotation(child, Quaternionf(d[1], d[2], d[3], d[4]))
        elseif cmd.id == :mirror;     return Mirror(child, Vec3f(d[1], d[2], d[3]))
        elseif cmd.id == :revolution; return Revolution(child, d[1])
        elseif cmd.id == :elongate;   return Elongate(child, Vec3f(d[1], d[2], d[3]))
        elseif cmd.id == :infinite_repetition; return InfiniteRepetition(child, Vec3f(d[1], d[2], d[3]))
        elseif cmd.id == :limited_repetition;  return LimitedRepetition(child, Vec3f(d[1], d[2], d[3]), Vec3f(d[4], d[5], d[6]))
        elseif cmd.id == :twist;      return Twist(child, d[1])
        elseif cmd.id == :bend;       return Bend(child, d[1])
        else
            error("Unknown prefix: $(cmd.id)")
        end
    end

    function _wrap_postfix(cmd::SDF.Command, child)
        d = cmd.data

        if cmd.id == :extrusion;    return Extrusion(child, Vec3f(d[1], d[2], d[3]))
        elseif cmd.id == :rounding; return Rounding(child, d[1])
        elseif cmd.id == :onion;    return Onion(child, d[1])
        else
            error("Unknown postfix: $(cmd.id)")
        end
    end

    ############################################################################
    ### Kernels
    ############################################################################

    using KernelAbstractions, Atomix

    # Copy bricks from source to target.
    # This keeps linear brick indices consistent, for example (2D)
    # [brick1 brick3; brick2 brick4][:] = [brick1, brick2, brick3, brick4]
    # reorders to
    # [brick1 brick4 -; brick2 - - ; brick3 - -][:] = [brick1, brick2, brick3, brick4, -, -, -, -, -]
    # (Note that bricks themselves contain multiple elements, so bricks are not
    # continuous in memory. This makes sampling easier in OpenGL.)
    @kernel function copy_bricks!(target, @Const(source), @Const(bricksize))
        # s source, t target, e element, b brick, o offset, 0 0-based
        # Cartesian index of selected element in source
        cart = @index(Global, Cartesian)
        sei, sej, sek = Tuple(cart)

        # Cartesian index of brick in source
        sbi0 = div(sei - 1, bricksize)
        sbj0 = div(sej - 1, bricksize)
        sbk0 = div(sek - 1, bricksize)

        # Cartesian offset within brick in source and target (matches)
        soi0 = (sei - 1) % bricksize
        soj0 = (sej - 1) % bricksize
        sok0 = (sek - 1) % bricksize

        # Linear index of brick in source and target (matches)
        src_size = div(size(source, 1), bricksize)
        brick_idx0 = (sbk0 * src_size + sbj0) * src_size + sbi0

        # Cartesian index of brick in target
        trg_size = div(size(source, 1), bricksize)
        tbi0 = brick_idx0 % trg_size
        tbj0 = div(brick_idx0, trg_size) % trg_size
        tbk0 = div(brick_idx0, trg_size * trg_size)

        # Cartesian element index in target
        tei = tbi0 * bricksize + soi0 + 1
        tej = tbj0 * bricksize + soj0 + 1
        tek = tbk0 * bricksize + sok0 + 1

        # copy
        target[tei, tej, tek] = source[sei, sej, sek]
    end

    struct BrickWorkItem
        # TODO: Avoid holding this in memory and calculate on the fly instead?
        # center position of the brick
        origin::Point3f
        # index into bm_indices
        i::UInt16
        j::UInt16
        k::UInt16
        # n-th new brick created in this work cycle. (0 if this item reuses an
        # existing brick)
        available_index::UInt32
    end

    # Produces work items for each brick that may contain an sdf edge/surface.
    # To do this, the function iterates through a region of the space the SDF
    # tree is defined on, based on an index range low_* .. dim_*. For each
    # index corresponding to a brick, the sdf at the center of the brick is
    # evaluated and if it could contain 0, a work item is created.
    # The number of created work items is counted in `work_count[1]`.
    # The number of items that need to create a new brick is counted in `work_items[2]`
    @kernel function cull_bricks_kernel!(
            work_items, work_count, # output queue + atomic counter
            @Const(bm_indices), @Const(sdf_tree),
            @Const(mini::Point3f), @Const(delta::Vec3f), @Const(brickradius::Float32),
            @Const(low_i::Int32), @Const(low_j::Int32), @Const(low_k::Int32),
            @Const(dim_i::Int32), @Const(dim_j::Int32), @Const(dim_k::Int32)
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

            sdf, _ = eval_sdf(sdf_tree, pos)
            if abs(sdf) < brickradius
                is_new_brick = Int32(bm_indices[i, j, k] == 0)
                slot = Atomix.@atomic work_count[1] += Int32(1)
                available_index = Atomix.@atomic work_count[2] += is_new_brick
                available_index = available_index * is_new_brick
                work_items[slot] = BrickWorkItem(pos, i, j, k, available_index)
            end
        end
    end

    # TODO: rename
    # Evaluates the sdf tree for each element in each brick associated with a
    # work item. The result is written to bm_bricks (i.e. the output sdf bricks)
    # Colors are also evaluated and get saved to a color buffer.
    # Note: bm_bricks must be resized to fit all newly added bricks beforehand.
    @kernel function eval_bricks_kernel!(
            @Const(bm_indices),         # spatial index -> brick_idx
            bm_bricks,                  # brickmap with enough slots
            @Const(available_bricks),   # indices of bricks that can be overwritten
            output_color,               # (bricksize^3 * max_bricks,)
            @Const(work_items),         # origin, brick element indices
            @Const(n_brick_to_update),  # number of bricks to be added
            @Const(tree),           # type-specialized SDF tree
            @Const(brick_delta::Vec3f), @Const(bricksize::Int32), @Const(uint8_scale::Float32),
            @Const(brickmap_size::Int32)
        )
        # 1 .. bricksize^3 * n_brick_to_update (maybe rounded up by work group size?)
        idx = @index(Global)

        # 1 .. n_brick_to_update (maybe rounded up by work group size?)
        bs3 = bricksize * bricksize * bricksize
        work_idx = Int32(div(idx - Int32(1), bs3) + Int32(1))

        if work_idx <= n_brick_to_update
            work = work_items[work_idx]

            # 0-based offset(s) of the cell selected by `idx` within a brick
            local_idx = Int32((idx - Int32(1)) % bs3)
            li = local_idx % bricksize # looks good
            lj = div(local_idx, bricksize) % bricksize # wrong
            lk = div(local_idx, bricksize * bricksize)

            # origin of the brick (bottom-left corner)
            origin = work.origin - Point3f(0.5f0, 0.5f0, 0.5f0) .* brick_delta .* (bricksize - Int32(1))
            # position of the cell selected by idx
            pos = origin + brick_delta .* Point3f(li, lj, lk)

            sdf, color = eval_sdf(tree, pos)

            # get the index of the brick within the brickmap
            brick_idx = if work.available_index == 0
                bm_indices[work.i, work.j, work.k] # edit
            else
                available_bricks[work.available_index] # add
            end
            # Cartesian index of the brick within the brickmap
            bi = (brick_idx - 1) % brickmap_size
            bj = div(brick_idx - 1, brickmap_size) % brickmap_size
            bk = div(brick_idx - 1, brickmap_size * brickmap_size)

            # index of the cell selected by idx within the brickmap
            gi = bi * bricksize + li
            gj = bj * bricksize + lj
            gk = bk * bricksize + lk
            cell_idx = (gk * brickmap_size * bricksize + gj) * brickmap_size * bricksize + gi + 1

            sdf8 = unsafe_trunc(UInt8, clamp(uint8_scale * sdf + 128f0, 0f0, 255.99f0))
            bm_bricks[cell_idx] = N0f8(sdf8, 1)

            # use RGB(15, 10, 25) as a marker for colors that won't show
            # if that color is used move to blue 24/26
            rf = 255f0 * red(color)
            gf = 255f0 * green(color)
            bf = 255f0 * blue(color)
            r = unsafe_trunc(UInt8, rf)
            g = unsafe_trunc(UInt8, gf)
            b = unsafe_trunc(UInt8, bf)
            is_mask = (r == 15) && (g == 10) && (b == 25)
            b = ifelse(is_mask, ifelse(bf - Float32(b) < 0f0, b - 0x01, b + 0x01), b)
            c = ifelse(
                0x00 < sdf8 < 0xff,
                RGB(N0f8(r, 0), N0f8(g, 0), N0f8(b, 0)),
                RGB(N0f8(15, 0), N0f8(10, 0), N0f8(25, 0)),
            )
            output_color[idx] = c
        end
    end

    # Updates bm_indices, adding all the bricks that contain resolved distances
    # and removing all the bricks that don't. Also tracks indices of work items
    # related to accepted bricks in indexbuffer.
    @kernel function update_indices!(
            bm_indices, available_bricks, indexbuffer,
            @Const(bm_bricks), @Const(work_items),
            @Const(bricksize), @Const(n_brick_to_update), @Const(bm_size)
        )
        work_idx = @index(Global)

        if work_idx <= n_brick_to_update
            work = work_items[work_idx]

            # get brick index, map to Cartesian index where brick starts (0 based)
            brick_idx = if work.available_index == 0
                bm_indices[work.i, work.j, work.k]
            else
                available_bricks[work.available_index]
            end
            i0 = bricksize * ((brick_idx - 1) % bm_size)
            j0 = bricksize * (div(brick_idx - 1, bm_size) % bm_size)
            k0 = bricksize * (div(brick_idx - 1, bm_size * bm_size))

            # TODO: should this break?
            # check brick for distance samples < max distance (abs(sdf) < max)
            is_resolved = false
            for k in 1:bricksize
                for j in 1:bricksize
                    for i in 1:bricksize
                        sdf = bm_bricks[i0 + i, j0 + j, k0 + k]
                        is_resolved = is_resolved || (0 < sdf.i < 0xff)
                    end
                end
            end

            # TODO: easy to remove branch,
            # brick_idx * Int32(is_resolved)
            # available *= Int(!is_resolved)
            if is_resolved
                # valid brick, register brick and remove it from available bricks
                # (if this wasn't an edit)
                bm_indices[work.i, work.j, work.k] = UInt32(brick_idx)
                if work.available_index != 0
                    available_bricks[work.available_index] = UInt32(0)
                end
                indexbuffer[work_idx] = UInt32(work_idx)
            else
                bm_indices[work.i, work.j, work.k] = UInt32(0)
                indexbuffer[work_idx] = UInt32(0)
            end
        end
    end

    # Goes through each brick in color_buffer and checks if the color (near the
    # surface/edge) is uniform.
    # If it is, searches for the appropriate color in the uniform color section
    # of color_bricks, sets up the appropriate connection in color_indexmap and
    # removes the work index from the indexbuffer.
    # If the brick does not have a uniform color, the code checks if a new
    # color brick is needed and increments n_new_color_bricks_needed in that
    # case. It also updates work.available_index to associate with color bricks
    # instead of sdf bricks
    @kernel function process_uniform_colors(
            color_bricks, color_indexmap, indexbuffer, n_new_color_bricks_needed,
            @Const(bm_indices), @Const(color_buffer), work_items,
            @Const(bricksize), @Const(n_valid_bricks), @Const(n_static_colors)
        )
        mask_color = RGB(N0f8(15, 0), N0f8(10, 0), N0f8(25, 0))

        # if so:
        # - find the color in the static color Brick
        # - add resulting index to color_indexmap
        # - remove entry from indexbuffer2
        # otherwise:
        # - keep index in indexbuffer2
        idx = @index(Global)
        if idx <= n_valid_bricks
            work_idx = indexbuffer[idx]
            work = work_items[work_idx]

            bs3 = bricksize * bricksize * bricksize
            start = (work_idx - 1) * bs3

            first_color = mask_color
            first_color_set = false
            is_dynamic_color = false
            for i in 1:bs3
                new_color = color_buffer[start + i]

                is_valid = mask_color != new_color # close to edge
                is_different = first_color != new_color
                is_dynamic_color = is_dynamic_color || (is_valid && is_different && first_color_set)
                # or if ...; is_dynamic_color = true; break end

                first_color_set = first_color_set || is_valid
                first_color = ifelse(is_valid, new_color, first_color)
            end

            brick_idx = bm_indices[work.i, work.j, work.k]

            if !first_color_set
                # did not find any valid colors, so there are no colors to set
                color_indexmap[brick_idx] = UInt32(0)
                indexbuffer[idx] = UInt32(0)
                # return not allowed
            else
                # could be that we have a single interpolated color here too...
                static_idx = 100_000 # 0 based
                if !is_dynamic_color
                    for lin in 0:n_static_colors-1
                        i = lin % bricksize
                        j = div(lin, bricksize) % bricksize
                        k = div(lin, bricksize * bricksize)
                        static_color = color_bricks[i+1, j+1, k+1] # 1 based getindex
                        static_idx = ifelse(static_color == first_color, lin, static_idx)
                    end
                end

                if is_dynamic_color || static_idx == 100_000
                    # count number of bricks that need to be added
                    # and track the counter in work items for later use
                    is_new_brick = Int32(color_indexmap[brick_idx] == 0)
                    available_index = Atomix.@atomic n_new_color_bricks_needed[1] += is_new_brick
                    available_index = available_index * is_new_brick
                    work_items[work_idx] = BrickWorkItem(work.origin, work.i, work.j, work.k, available_index)
                else
                    index_with_flag = (UInt32(1) << 31) | static_idx
                    color_indexmap[brick_idx] = index_with_flag
                    indexbuffer[idx] = UInt32(0)
                end
            end
        end
    end

    # Copy non-uniform color bricks from color_buffer to color_bricks and
    # update register their indices in color_indexmap
    @kernel function process_color_bricks(
            color_bricks, color_indexmap, @Const(indexbuffer),
            @Const(bm_indices),
            @Const(color_buffer), @Const(work_items), @Const(n_new_color_bricks_needed),
            @Const(bricksize), @Const(bm_size), @Const(start_of_new_bricks)
        )
        idx = @index(Global) # per brick element
        bs3 = bricksize * bricksize * bricksize
        buffer_idx = div(idx - 1, bs3) + 1

        if buffer_idx <= n_new_color_bricks_needed
            work_idx = indexbuffer[buffer_idx]
            work = work_items[work_idx]

            # get brick index, map to Cartesian index where brick starts (0 based)
            sdf_brick_idx = bm_indices[work.i, work.j, work.k]
            color_brick_idx = if work.available_index == 0
                color_indexmap[sdf_brick_idx] # flag not active, so counts normally
            else
                start_of_new_bricks + work.available_index
            end
            # @assert color_brick_idx > 0

            # bm_size = div(size(color_bricks, 1), bricksize)
            bi = (color_brick_idx) % bm_size
            bj = div(color_brick_idx, bm_size) % bm_size
            bk = div(color_brick_idx, bm_size * bm_size)

            # 0-based offset(s) of the cell selected by `idx` within a brick
            local_idx = Int32((idx - Int32(1)) % bs3)
            li = local_idx % bricksize
            lj = div(local_idx, bricksize) % bricksize
            lk = div(local_idx, bricksize * bricksize)

            # index of the cell selected by idx within the brickmap
            gi = bi * bricksize + li
            gj = bj * bricksize + lj
            gk = bk * bricksize + lk

            # index in color_buffer. The brick is chosen by work_idx, the element
            # within the brick by the offset in idx
            input_idx = (work_idx - 1) * bs3 + local_idx + 1

            # @assert(
            #     (gi > 7) || (gj > 7) || (gk > 7),
            #     "$color_brick_idx -> ($bi, $bj, $bk), $local_idx -> ($li, $lj, $lk) -> ($gi, $gj, $gk) -> $cell_idx"
            # )
            # @assert(
            #     cell_idx <= length(color_bricks),
            #     "$color_brick_idx -> ($bi, $bj, $bk), $local_idx -> ($li, $lj, $lk) -> ($gi, $gj, $gk) -> $cell_idx"
            # )
            color_bricks[gi + 1, gj + 1, gk + 1] = color_buffer[input_idx]

            color_indexmap[sdf_brick_idx] = color_brick_idx
        end
    end

    ############################################################################
    ### Brickmap generation/update
    ############################################################################

    # resize brick buffer and track new indices in available
    function resize_brickmap(backend, old_brickmap, bricks_needed, bricksize, available::Vector)
        bricks_in_use = div(length(old_brickmap), bricksize^3) - length(available)

        new = resize_brickmap(backend, old_brickmap, bricks_in_use, bricks_needed, bricksize)

        # TODO: Is this bad?
        # add every available brick so we can easily grab the index on the GPU
        D = div(size(new, 1), bricksize)
        append!(available, (bricks_in_use + 1) : D^3)
        @assert allunique(available)
        # now: [ prev_available | rest ]
        # TODO: correct starting values - every brick that's got a slot

        return new
    end

    # just resize brick buffer
    function resize_brickmap(backend, old_brickmap, bricks_in_use, bricks_needed, bricksize)
        target_brick_count = bricks_in_use + bricks_needed

        # open_brick_slots = total_brick_slots - brick_counter
        # growby = n_new_bricks - open_brick_slots
        # -> growby = n_new_bricks - total_brick_slots + brick_counter
        # D = ceil(Int, cbrt(total_brick_slots + growby))
        # -> n_new_bricks + brick_counter

        total_brick_slots = div(length(old_brickmap), bricksize^3)
        total_brick_slots >= target_brick_count && return old_brickmap
        D = ceil(Int, cbrt(target_brick_count))

        old_size = div(size(old_brickmap, 1), bricksize)
        @info "Resizing brickmap from $(old_size)^3 to $D^3 bricks to accommodate $(bricks_needed) new bricks."

        # new = KernelAbstractions.allocate(backend, N0f8, D * bricksize, D * bricksize, D * bricksize)
        new = KernelAbstractions.zeros(backend, eltype(old_brickmap), D * bricksize, D * bricksize, D * bricksize)

        copy_bricks!(backend, 256)(
            new, old_brickmap, bricksize,
            ndrange = size(old_brickmap)
        )
        KernelAbstractions.synchronize(backend)

        return new
    end

    # collect all the colors set by shapes (without repeats)
    function collect_possible_static_colors(node::MergeNode, colors = RGB{N0f8}[])
        collect_possible_static_colors(node.a, colors)
        collect_possible_static_colors(node.b, colors)
        return colors
    end

    function collect_possible_static_colors(node::TransformationNode, colors = RGB{N0f8}[])
        collect_possible_static_colors(node.child, colors)
        return colors
    end

    function collect_possible_static_colors(node::ShapeNode, colors = RGB{N0f8}[])
        rgb8 = RGB{N0f8}(node.color)
        rgb8 in colors || push!(colors, node.color)
        return colors
    end

    # remove indices marked as invalid/discarded (0)
    function remove_discarded_indices(backend, indexbuffer)
        cpu_indexbuffer = Array(indexbuffer)
        prev = length(cpu_indexbuffer)
        filter!(!iszero, cpu_indexbuffer)
        n_valid_bricks = length(cpu_indexbuffer)
        @info "Cleared indexbuffer: $prev -> $n_valid_bricks"
        indexbuffer = KernelAbstractions.allocate(backend, UInt32, n_valid_bricks)
        copyto!(indexbuffer, cpu_indexbuffer)
        return indexbuffer, n_valid_bricks
    end

    mutable struct PersistentBuffers{A, B, C, D}
        # optimally these would be passed directly to the Graphics API
        indices::A          # ~ Array{UInt32, 3}
        sdf_bricks::B       # ~ Array{N0f8, 3}
        color_indexmap::C   # ~ Array{UInt32, 2}
        color_bricks::D     # ~ Array{RGB{N0f8}, 3}

        # maybe better to keep on the CPU side?
        available_bricks::Vector{UInt32}
        available_color_bricks::Vector{UInt32}

        # function PersistentBuffers(a::A, b::B, c::C, d::D, e, f)
    end

    function PersistentBuffers(backend, N_bricks, bricksize)
        return PersistentBuffers(
            KernelAbstractions.zeros(backend, UInt32, N_bricks, N_bricks, N_bricks),
            KernelAbstractions.allocate(backend, N0f8, (0, 0, 0)),
            KernelAbstractions.zeros(backend, UInt32, 0, 0), # TODO: does this need to be zeros?
            KernelAbstractions.allocate(backend, RGB{N0f8}, (bricksize, bricksize, bricksize)),

            UInt32[],
            UInt32[],
        )
    end

    import ComputePipeline: is_same
    # never discard this update
    is_same(::PersistentBuffers, ::PersistentBuffers) = false

    function update_brickmap!(
            bm::PersistentBuffers,
            bb::Rect3f, tree::Node,
            regions_to_update::Vector{Rect3f},
            backend, # KernelAbstractions backend, e.g. CPU() or CUDABackend()
            N_bricks, bricksize
        )

        isempty(regions_to_update) && return brickmap

        @info "Initialize brickmap parameters"

        delta = widths(bb) ./ N_bricks
        mini = minimum(bb)

        raw_update_bb = reduce(Base.union, regions_to_update, init = Rect3f())
        low = trunc.(Int32, clamp.(fld.(minimum(raw_update_bb) .- mini, delta), 0, N_bricks-1)) .+ Int32(1)
        high = trunc.(Int32, clamp.(cld.(maximum(raw_update_bb) .- mini, delta), 1, N_bricks))

        box_scale = norm(widths(bb))
        brickdiameter = sqrt(3.0f0) * box_scale / (N_bricks - 1)
        brickradius = 0.5f0 * brickdiameter

        bricksize = Int32(bricksize)
        brick_delta = Vec3f(delta ./ (bricksize - 1))
        uint8_scale = 127.5f0 * bricksize / brickdiameter

        dims = Int32.(high .- low .+ 1)
        n_brick_to_update_to_check = prod(dims)
        @info "$low .. $high, $dims"

        @time begin
            @info "Initialize Brickmap GPU buffers"
            # TODO: track?
            color_brick_counter = 0

            @info "Initialize work buffers"
            @time begin
                # Allocate GPU buffers
                work_items = KernelAbstractions.allocate(backend, BrickWorkItem, n_brick_to_update_to_check)
                # (number of items to recalculate, number of new bricks)
                work_count = KernelAbstractions.zeros(backend, Int32, 2)
            end

            # Phase 1: cull bricks on GPU
            @info "cull bricks"
            @time begin
                cull_bricks_kernel!(backend, 256)(
                    work_items, work_count, bm.indices, tree,
                    Point3f(mini), Vec3f(delta), brickradius,
                    low[1], low[2], low[3],
                    dims[1], dims[2], dims[3];
                    ndrange = n_brick_to_update_to_check
                )
                KernelAbstractions.synchronize(backend)
            end

            @info "Prepare update of sdf bricks"
            @time begin
                n_brick_to_update, n_new_bricks = Array(work_count)
                n_brick_to_update == 0 && return
                @info "GPU cull: $n_brick_to_update / $n_brick_to_update_to_check bricks need evaluation"

                # Phase 2: resize bricks storage to have space for the new bricks
                bm.sdf_bricks = resize_brickmap(
                    backend, bm.sdf_bricks, n_new_bricks, bricksize, bm.available_bricks
                )

                # move to GPU
                gpu_available_bricks = KernelAbstractions.allocate(backend, UInt32, length(bm.available_bricks))
                copyto!(gpu_available_bricks, bm.available_bricks)

                KernelAbstractions.synchronize(backend)

                # Phase 3: evaluate SDF at all sample points
                bs3 = Int(bricksize)^3
                n_updated_elements = n_brick_to_update * bs3
                # TODO: Any way to avoid this big, mostly discarded buffer?
                output_color = KernelAbstractions.allocate(backend, RGB{N0f8}, n_updated_elements)
            end

            @info "Update $(div(n_updated_elements, bs3)) sdf bricks ($n_updated_elements elements)"
            @time begin
                eval_bricks_kernel!(backend, 64)(
                    bm.indices,
                    bm.sdf_bricks,
                    gpu_available_bricks,
                    output_color,
                    work_items,
                    Int32(n_brick_to_update),
                    tree,
                    brick_delta, bricksize, uint8_scale,
                    Int32(div(size(bm.sdf_bricks, 1), bricksize));
                    ndrange = n_updated_elements
                )
                KernelAbstractions.synchronize(backend)
            end

            # Phase 4: commit or discard bricks
            @info "Update brick indices and collect colors to update"
            @time begin
                # track work_items indices for accepted bricks
                indexbuffer = KernelAbstractions.allocate(backend, UInt32, n_brick_to_update)

                update_indices!(backend, 256)(
                    bm.indices,
                    gpu_available_bricks,
                    indexbuffer,
                    bm.sdf_bricks,
                    work_items,
                    bricksize,
                    n_brick_to_update,
                    Int32(div(size(bm.sdf_bricks, 1), bricksize)),
                    ndrange = n_brick_to_update
                )
                KernelAbstractions.synchronize(backend)
            end

            @info "sdf brick bookkeeping"
            @time begin
                # Bookkeeping for unused bricks
                copyto!(bm.available_bricks, gpu_available_bricks)
                filter!(!iszero, bm.available_bricks)
            end

            @info "Remove skipped indices from color indexbuffer"
            @time indexbuffer, n_valid_bricks = remove_discarded_indices(backend, indexbuffer)

            # prepare static/uniform colors
            @info "update static colors"
            @time begin
                static_colors = collect_possible_static_colors(tree)
                n_static_colors = length(static_colors)
                append!(static_colors, fill(RGB{N0f8}(1,0,1), bs3 - n_static_colors))
                v = view(bm.color_bricks, 1:bricksize, 1:bricksize, 1:bricksize)
                copyto!(v, static_colors)
            end

            @info "Resize color indexmap"
            @time begin
                # create a slot for each brick
                max_brick_idx = div(length(bm.sdf_bricks), bs3)
                if length(bm.color_indexmap) < max_brick_idx
                    @info "Resize color indexmap from $(length(bm.color_indexmap)) -> $max_brick_idx"
                    # 0 is our indicator for unset indices (the 0 brick is reserved for
                    # static colors which add UInt32(1) << 31)
                    D = ceil(Int, sqrt(max_brick_idx))
                    new = KernelAbstractions.zeros(backend, UInt32, D, D)
                    copyto!(view(new, 1:length(bm.color_indexmap)), bm.color_indexmap)
                    bm.color_indexmap = new
                end
            end

            # for each color brick, check if the colors is static
            # if so:
            # - find the color in the static color Brick
            # - add resulting index to color_indexmap
            # - remove entry from indexbuffer2
            # otherwise:
            # - keep index in indexbuffer2
            @info "Process uniformly colored bricks"
            @time begin
                n_new_color_bricks_needed = KernelAbstractions.zeros(backend, UInt32, 1)
                process_uniform_colors(backend, 256)(
                    bm.color_bricks, bm.color_indexmap, indexbuffer,
                    n_new_color_bricks_needed,
                    bm.indices, output_color, work_items,
                    bricksize, n_valid_bricks, n_static_colors,
                    ndrange = n_valid_bricks
                )
                KernelAbstractions.synchronize(backend)
            end

            @info "Trim indexbuffer to exclude uniformly colored bricks"
            @time indexbuffer, n_color_bricks = remove_discarded_indices(backend, indexbuffer)

            @info "Resize color bricks"
            @time begin
                # TODO: This needs its own "available" buffer
                n_new_color_bricks = Array(n_new_color_bricks_needed)[1]
                @assert n_new_color_bricks + color_brick_counter >= length(indexbuffer) "added $n_new_color_bricks + prev $color_brick_counter >= touched $(length(indexbuffer))"
                bm.color_bricks = resize_brickmap(
                    backend, bm.color_bricks,
                    color_brick_counter + 1, # first reserved for static colors
                    n_new_color_bricks, bricksize
                )
            end

            # handle color bricks
            @info "Copy and connect color bricks"
            @time begin
                process_color_bricks(backend, 256)(
                    bm.color_bricks, bm.color_indexmap, indexbuffer, # outputs
                    bm.indices, # inout
                    output_color, work_items, n_color_bricks, # inputs
                    bricksize,
                    Int32(div(size(bm.color_bricks, 1), bricksize)),
                    color_brick_counter, # we got a + 1 to skip over static color brick in work items
                    ndrange = n_color_bricks * bs3
                )
                KernelAbstractions.synchronize(backend)
            end

            # TODO: what about deletion?
            color_brick_counter += n_new_color_bricks
            @info "All GPU tasks:"
        end

        return
    end

end

"""
Plots constructive solid geometry, i.e. 3D geometry created from simpler
geometry using transformations and boolean operations. See `Makie.CSG`.
"""
@recipe CSGPlot2 (x::EndPoints, y::EndPoints, z::EndPoints, csg_tree::SDF.Node) begin
    "Sample density of signed distances used in rendering the geometry."
    resolution = 512
    "Minimum step length used in ray marching."
    minstep = 1e-5
    "TODO: Maximum number of steps allowed in ray marching."
    maxsteps = 1000
    "Size of bricks in the generated Brickmap (per dimension)."
    bricksize = 8
    """
    Sets the backend used for KernelAbstractions. This should be set to one of
    `CUDABackend()`, `ROCBackend()`, `oneAPIBackend()` or `MetalBackend()` with
    th respective packages loaded to use GPU acceleration.
    """
    backend = CPU()
end

conversion_trait(::Type{<:CSGPlot2}) = VolumeLike()

# same as CSGPlot
# function expand_dimensions(::VolumeLike, root::SDF.Node)
#     @info "called"
#     SDF.calculate_global_bboxes!(root)
#     bb = root.bbox[]
#     # need padding so the surface isn't on the boundary
#     # 0 width bbox would probably be a problem?
#     ws = max.(1e-3, widths(bb))
#     mini = minimum(bb)
#     x, y, z = EndPoints.(mini .- 0.01ws, mini .+ 1.01ws)
#     return (x, y, z, root)
# end

function convert_arguments(::Type{<:CSGPlot2}, x::RangeLike, y::RangeLike, z::RangeLike, root::SDF.Node)
    return (
        to_endpoints(x, "x", VolumeLike), to_endpoints(y, "y", VolumeLike),
        to_endpoints(z, "z", VolumeLike), root,
    )
end

preferred_axis_type(::CSGPlot2) = LScene

# function pad_tree_bbs!(node::SDF.Node, by::Vec3f)
#     node.bbox[] = Rect(minimum(node.bb[]) .- by, widths(node.bb[]) .+ 2by)
#     foreach(child -> pad_tree_bbs!(child, by), node.children)
#     return
# end

# function print_bb_rec(node, depth = 0)
#     main = node.commands[node.main_idx]
#     name = main.id
#     # println("  "^depth, name, " ", node.bbox[])
#     str = "  "^depth * "$name $(node.bbox[])\n"
#     printstyled(str, color = node.changed[] ? :bold : :light_black)
#     foreach(child -> print_bb_rec(child, depth + 2), node.children)
# end

function plot!(p::CSGPlot2)
    map!(p, [:x, :y, :z], :data_limits) do x, y, z
        return Rect3f(x[1], y[1], z[1], x[2] - x[1], y[2] - y[1], z[2] - z[1])
    end

    # TODO: should bricksize just be static?
    # Note: These are not the total amounth of elements/bricks but the amount
    #       along one dimension
    map!(p, [:resolution, :bricksize], [:N_elements, :N_bricks]) do resolution, bricksize
        N_bricks = cld(resolution - 1, bricksize - 1)
        N_elements = N_bricks * (bricksize - 1) + 1
        @info "$resolution -> $N_elements elements, $N_bricks bricks"
        return N_elements, N_bricks
    end

    # TODO: all node bounding boxes need to be padded asap but changes in
    # data_limits should not trigger a recalculation of bricks
    # TODO: do we actually need this?
    # onany(p.csg_tree, p.data_limits) do root, bb
    #     delta = widths(bb) ./ N_blocks
    #     pad_tree_bbs!(root, delta)
    # end

    # TODO: Using optimized trees would cause recompilation so it's probably
    # not worth it here...
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

    map!(SDF2.Node, p, :csg_tree, :deeply_nested_tree)

    # TODO: async
    register_computation!(
            p,
            [:backend, :data_limits, :deeply_nested_tree, :diffed_bboxes, :N_bricks, :bricksize],
            [:persistent_buffers]
        ) do (backend, bb, root, bbs, N_bricks, bricksize), changed, cached

        persistent_buffers = if isnothing(cached)
            SDF2.PersistentBuffers(backend, N_bricks, bricksize)
        else
            cached[1]
        end

        SDF2.update_brickmap!(
            persistent_buffers, bb, root, bbs, backend, N_bricks, bricksize
        )

        return (persistent_buffers,)
    end

    # TODO: async
    register_computation!(
            p, [:persistent_buffers, :bricksize], [:samplers]
        ) do (buffers, bricksize), changed, cached

        samplers = if isnothing(cached)
            SDFBrickmapSamplers(bricksize)
        else
            cached[1]
        end

        # TODO: optimally we'd just have the data on the gpu and keep it there...
        # TODO: Would it be better to locally resize and copyto!()?
        @info "Notify ShaderAbstractions"
        @time begin
            ShaderAbstractions.update!(samplers.indices, Array(buffers.indices))
            ShaderAbstractions.update!(samplers.bricks, Array(buffers.sdf_bricks))
            ShaderAbstractions.update!(samplers.color_indexmap, Array(buffers.color_indexmap))
            ShaderAbstractions.update!(samplers.color_bricks, Array(buffers.color_bricks))
        end

        return (samplers,)
    end

    # force this to run before connecting the backend so we don't spam updates
    # during construction
    p.samplers[]

    volume!(p, p.x, p.y, p.z, p.samplers, algorithm = :sdf, isorange = p.minstep)
end
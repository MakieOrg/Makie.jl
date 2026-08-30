"""
What RayMakie still names from Lava, and why each one is allowed to stay.

This file used to be a debt ledger. `Lava.` in RayMakie's source meant a Makie
backend reaching into a Vulkan runtime — queues, framebuffers, render passes,
`present_frame!` — and the list existed to stop it growing while that runtime was
moved out. On 2026-08-27 it was: **124 references across 8 files.**

The move happened, and it is now **31 across 2**, all of one kind. Everything
that needed a device went to Mantle: `GraphicsPipeline`, `VulkanFramebuffer`,
`VulkanTexture2D`, `VulkanBatchQueue`, `vk_context`, `blit!`, `present_frame!`,
`acquire_next_image!`, `begin_pass!`, `LavaArray`. What is left is what a
shader is written IN and what a pipeline is DESCRIBED with:

  * **shader-stage intrinsics** — `gfx_input`/`gfx_output`, `emit_vertex!`,
    `frag_coord_x`, `dFdx`, `set_position!`, `sample_texture_2d`,
    `vertex_index`. These are the graphics counterpart of what
    `KernelInterface` holds for compute, and they belong to whoever lowers them.
  * **pipeline-description enums** — `TriangleList`, `NoCull`, `DepthOff`,
    `Premultiplied`, `GeometryConfig`. Pure Julia, no Vulkan: `graphics/types.jl`
    describes what a pipeline should be, and Mantle's `graphics/pipeline.jl`
    builds it. That is why one stayed and the other left.
  * **`LavaDeviceArray`** — the `(pointer, dims)` pair a kernel receives. Its
    host counterpart `LavaArray` is Mantle's, and the two sitting on opposite
    sides is the split stated in miniature.

So the ledger's meaning inverted. It no longer says "this should be zero"; it
says **this is compiler vocabulary, and nothing that needs a device may join
it**. A `Lava.BatchQueue` reappearing here would mean the split had come undone.

Counts are not pinned per name — RayMakie writes `LavaDeviceArray` wherever a
kernel signature needs it and that moves with ordinary edits. The name SETS are,
which is what catches a new kind of reference.

Parsed rather than grepped: `import Lava: a, b,` continues across lines, and a
regex either misses the continuation or matches the word in a comment.

The walker below also exists in Hikari's `test_no_lava_references.jl`. It is
copied on purpose: the two are separate packages with no test dependency between
them, and inventing a shared package to hold thirty lines of AST walk would be a
worse trade than the copy.
"""

using Test

const LAVA_SURFACE = Dict(
    # Shader-stage intrinsics and the enums a pipeline is described with.
    "src/RayMakie.jl" => Set([
        # `Premultiplied`, `TriangleList`, `NoCull` and `DepthOff` were here
        # until the runtime moved out of the compiler: blend, cull, depth and
        # topology describe a pipeline rather than compile one, so they are
        # imported from Mantle now and are no longer part of the Lava surface.
        # `RayMakie.jl` says so at its import; this list had not caught up.
        "PointList", "LineList", "LineListAdjacency", "LineStripAdjacency",
        "TriangleStrip", "GeometryConfig", "GfxTexture2D",
        "vertex_index", "instance_index", "primitive_id_in",
        "set_position!", "set_point_size!",
        "frag_coord_x", "frag_coord_y", "dFdx", "dFdy",
        "gfx_input", "gfx_input_flat", "gfx_output", "gfx_output_flat",
        "geom_input", "geom_input_position",
        "emit_vertex!", "end_primitive!", "sample_texture_2d",
        "LavaDeviceArray",
    ]),
    # The device-side array, in a kernel argument type.
    "src/overlay/renderobject.jl" => Set(["LavaDeviceArray"]),
)

"""Where the surface stood after the split. It may fall; it may not rise."""
const LAVA_SURFACE_BUDGET = 31

"""
Every `Lava.<name>` and every name in an `import Lava: …` list, as `name =>
count`. `Lava` alone is not a reference to anything.
"""
function lava_references(path::AbstractString)
    found = Dict{String, Int}()
    note!(name) = (found[name] = get(found, name, 0) + 1)

    function walk(ex)
        ex isa Expr || return
        if ex.head === :. && length(ex.args) == 2 &&
                ex.args[1] === :Lava && ex.args[2] isa QuoteNode
            note!(String(ex.args[2].value))
            return
        end
        if (ex.head === :import || ex.head === :using) && length(ex.args) == 1 &&
                ex.args[1] isa Expr && ex.args[1].head === :(:)
            spec = ex.args[1]
            if spec.args[1] isa Expr && spec.args[1].head === :. &&
                    spec.args[1].args == [:Lava]
                for name in spec.args[2:end]
                    name isa Expr && name.head === :. && note!(String(name.args[1]))
                end
                return
            end
        end
        foreach(walk, ex.args)
        return
    end

    walk(Meta.parseall(read(path, String)))
    return found
end

# Names that need a DEVICE. None of these may appear: each one is something the
# 2026-08-27 move put in Mantle, and its return would mean the split came undone.
const RUNTIME_NAMES = Set([
    "LavaArray", "LavaBackend", "VulkanBatchQueue", "VkContext", "vk_context",
    "GraphicsPipeline", "VulkanFramebuffer", "VulkanTexture2D", "VulkanSampler",
    "WindowTarget", "OffscreenTarget", "VulkanWindow", "blit!", "present_frame!",
    "acquire_next_image!", "allocate_batch_queue!", "release_batch_queue!",
    "begin_pass!", "end_pass!", "draw_in_pass!", "pin!", "flush!",
])

@testset "RayMakie names only compiler vocabulary from Lava" begin
    pkg = pkgdir(RayMakie)
    src = joinpath(pkg, "src")

    actual = Dict{String, Dict{String, Int}}()
    for (root, _, files) in walkdir(src), file in files
        endswith(file, ".jl") || continue
        path = joinpath(root, file)
        refs = lava_references(path)
        isempty(refs) || (actual[relpath(path, pkg)] = refs)
    end

    @test sort(collect(keys(actual))) == sort(collect(keys(LAVA_SURFACE)))

    for (file, allowed) in LAVA_SURFACE
        @testset "$file" begin
            names = Set(keys(get(actual, file, Dict{String, Int}())))
            @test isempty(setdiff(names, allowed))
            gone = setdiff(allowed, names)
            isempty(gone) ||
                @info "$file no longer references $(join(sort(collect(gone)), ", ")) — delete these from LAVA_SURFACE"
            @test isempty(gone)
        end
    end

    # The claim the docstring makes, checked rather than asserted in prose.
    @testset "nothing that needs a device" begin
        for (file, refs) in actual
            @test (file, sort(collect(intersect(keys(refs), RUNTIME_NAMES)))) == (file, String[])
        end
    end

    total = sum(sum(values(v)) for v in values(actual); init = 0)
    @test total <= LAVA_SURFACE_BUDGET
    total < LAVA_SURFACE_BUDGET &&
        @info "Lava surface is down to $total from $LAVA_SURFACE_BUDGET — lower LAVA_SURFACE_BUDGET to hold the ground"
end

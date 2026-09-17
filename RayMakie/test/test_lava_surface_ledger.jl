"""
What RayMakie still names from Lava, and why each one is allowed to stay.

`Lava.` in RayMakie's source means a Makie backend reaching into a Vulkan
runtime — queues, framebuffers, render passes, `present_frame!` — and this file
is what keeps the count at zero.

Everything that needs a device is Mantle's: `GraphicsPipeline`,
`VulkanFramebuffer`, `VulkanTexture2D`, `vk_context`, `blit!`, `present_frame!`,
`acquire_next_image!`, `begin_pass!`, `LavaArray`. The two categories that could
plausibly stay, and did not:

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

Both of those are `KernelInterface`'s and Mantle's instead: a shader is written
in the portable vocabulary and lowered by whichever backend compiles it, and
`LavaDeviceArray` is spelled `AbstractVector` in the signatures that would name
it. So the count is **0 across 0 files**, which is what makes `using Metal,
Mantle` enough to render with.

The ledger keeps its meaning at zero. It says: nothing from Lava may come back —
not a queue, not a framebuffer, and not an intrinsic either, because a shader
that names one is a shader only one backend can compile.

Parsed rather than grepped: `import Lava: a, b,` continues across lines, and a
regex either misses the continuation or matches the word in a comment.

The walker below also exists in Hikari's `test_no_lava_references.jl`. It is
copied on purpose: the two are separate packages with no test dependency between
them, and inventing a shared package to hold thirty lines of AST walk would be a
worse trade than the copy.
"""

using Test

const LAVA_SURFACE = Dict{String, Set{String}}()

"""Where the surface stands. It may not rise."""
const LAVA_SURFACE_BUDGET = 0

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

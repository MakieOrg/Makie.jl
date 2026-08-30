using Test

# Load a GPU backend, and say which one.
#
# This file used to load none. `using RayMakie` alone leaves Mantle with no
# registered backend, so every test that renders died with "Mantle: no GPU
# backend is available" — 45 of 85 assertions on an Apple machine, reported as
# errors rather than as "this suite needs a device it cannot find". It passed on
# a Vulkan box only because something else in the environment had pulled Lava
# in. The same hole took Mantle's own suite down until 2026-08-29.
#
# Probed rather than named: both packages resolve on any platform, and which one
# is USABLE is the question. Note that "did the package import" is NOT that
# question — `Lava` is the SPIR-V compiler and imports perfectly well on a
# machine with no Vulkan loader, registering no backend at all. So each
# candidate is loaded and then Mantle is asked what actually registered.
using Mantle

const BACKEND = let found = nothing
    for name in ("Lava", "Metal")
        id = Base.identify_package(name)
        id === nothing && continue
        try
            Base.require(id)
        catch err
            @info "RayMakie tests: $name is installed but not loadable here" exception = err
            continue
        end
        avail = Base.invokelatest(Mantle.availablebackends)
        if !isempty(avail)
            found = Base.invokelatest(Mantle.defaultbackend)
            break
        end
    end
    found
end

BACKEND === nothing &&
    error("RayMakie's tests need a GPU backend. Install/enable Lava (with a Vulkan " *
          "loader) or Metal (on an Apple GPU). Refusing to run: without one, every " *
          "rendering test errors identically and the run says nothing about RayMakie.")

@info "RayMakie tests: using $(nameof(typeof(BACKEND)))"

# Single-process test entry point.
#
# Only test files that are stable when chained together in a single session
# are listed here. Several of the older files in this directory either
#   (1) have zero `@test` assertions (println scripts: test_basic_gpu.jl,
#       test_per_instance_colors.jl, test_smoke_volume{,_gpu}.jl), or
#   (2) referenced removed APIs (test_materials_scene.jl) — FIXED, see below, or
#   (3) bypass the RayMakie package init by `include()`-ing internal source
#       files (test_lava_array_meshscatter.jl pulls in lava_arrays.jl by hand,
#       which leaves the VulkanBatchQueue in a state that desyncs every
#       subsequent RayMakie test in the same process), or
#   (4) leave LavaArray finalizers attached to a semaphore whose timeline
#       has been freed; running GC after them segfaults
#       (test_caching_gc_correctness.jl).
# Run those individually in fresh sessions when needed.
#
# (4) is FIXED — `Mantle.allocate_batch_queue!` now hands the context ownership of
# every queue it returns, so a semaphore cannot be finalized while a buffer that
# names it is still alive, and `release_batch_queue!` is the way back out; see
# Mantle's vulkan/test_batch_queue_lifetime.jl for the invariant.
#
# Re-checked 2026-08-25, and the reason they were failing had stopped being (4)
# some time ago: both `test_caching_gc_correctness.jl` and
# `test_dolphin_update_stress.jl` were calling runtime APIs the per-VulkanBatchQueue
# deferred-free refactor deleted — `flush_deferred_frees!`, `_live_buffers`,
# `LIVE_BUFFERS`, `GPU_LIVE_BYTES`. They errored on the first line of every
# testset, so the exclusion comment above was describing a hazard that no longer
# applied to a file that could not run at all. Ported to
# `drain_deferred_frees!(bq)` / `live_buffer_count(ctx)` / `gpu_live_bytes(ctx)`
# and both are back in the list below (36 and 7 assertions).
#
# `test_materials_scene.jl` was the same story and had drifted across THREE
# independent API moves at once: `Hikari.FilmSensor` -> `PixelSensor` (and
# `white_balance` -> `whitebalance`), a missing `using Raycore` despite
# `Raycore.KA.CPU()` being the default argument on four call sites, and `sensor`
# moving off `ScreenConfig` onto the integrator. Fixed and included.
#
# The lesson generalises: an excluded test file rots, and its exclusion note
# rots with it — this comment claimed a GC-lifetime hazard for files that could
# not get far enough to reach one. Two of the three are leak regressions, the
# coverage least likely to be duplicated elsewhere and most likely to matter.

const TEST_FILES = [
    # Source-only, no device: the architecture ledger goes first so it is
    # reported before anything that can take a device down with it.
    "test_lava_surface_ledger.jl",
    # CPU-only (no render), so it fails fast and before anything touches a device.
    "test_pbrt_import_settings.jl",
    "test_hw_accel_switch.jl",
    "test_material_precedence.jl",
    "test_lava_meshscatter_pervec.jl",
    "test_meshscatter_update_stress.jl",
    "test_mesh_update_stress.jl",
    "test_recolor_keeps_blas.jl",
    "test_transform_update_hwtlas.jl",
    "test_update_paths.jl",
    # Leak / GC regressions.
    "test_materials_scene.jl",
]

# The Vulkan runtime's DEFERRED-FREE LEDGER, and nothing else.
#
# `vk_flush!`, `vk_context()`, `drain_deferred_frees!`, `live_buffer_count` —
# that ledger is how the Vulkan backend reclaims GPU memory, and it is that
# backend's mechanism, not a Mantle verb every backend answers. A unified-memory
# backend has nothing to defer and nothing to count. Same split Mantle's own
# suite makes with `test/vulkan/` and `test/metal/`.
#
# Kept as a list rather than deleted: it is a LEAK regression, the coverage
# least likely to be duplicated elsewhere.
const VULKAN_RUNTIME_TEST_FILES = ["test_caching_gc_correctness.jl"]

# NOT listed: test_dolphin_update_stress.jl — and here is exactly what is known,
# so the next person does not have to re-derive it (2026-08-25).
#
# It is no longer dead: it was ported off the removed `LIVE_BUFFERS` /
# `GPU_LIVE_BYTES` globals and passes 7/7 standalone (~24 s), and 12/12 when run
# after test_transform_update_hwtlas.jl. But in the full run above it errors:
#
#     TypeError: expected Mantle.CommandBatch, got Nothing
#       Mantle/src/vulkan/runtime/launch.jl:298, in pack_args_direct!
#
# i.e. `bq.active_batch` is nothing where a recording batch is expected. Ruled
# out: it is NOT the `queue_released` guard added to `vk_free!` at the same time
# (the close-a-screen-then-dolphin pairing passes), and NOT the port itself
# (standalone passes). So some other file earlier in this list leaves the queue
# in a state dolphin does not tolerate; which one is unbisected.
#
# Run it on its own to get the leak coverage:
#   julia --project=… -e 'using Test; include("test/test_dolphin_update_stress.jl")'

# Point RayMakie at the backend that was found, once, before any file renders.
# Individual files still override the device where they mean to.
using RayMakie
RayMakie.activate!(; device = BACKEND)

# Rasterised overlays — lines, scatter, text drawn OVER the raytraced image.
# They need a graphics pipeline and a framebuffer, which is a backend capability
# rather than a given: Metal.jl compiles Julia to compute kernels only, there is
# no `MTLRenderPipelineState` wrapper and no vertex/fragment stage, so
# `supports_graphics` is false there and stays false. RayMakie's `colorbuffer`
# already has a direct-readback path for scenes with no overlays, and that is
# the one such a backend takes.
#
# Asked as a capability, never as a vendor name. Ungated, these errored with
# `MethodError: no constructors have been defined for Framebuffer` — ten of
# them, which reads as "RayMakie is broken" rather than "this device cannot
# rasterise".
const GRAPHICS_TEST_FILES = [
    "test_overlay_compositing.jl",
    "test_figure_scene_routing.jl",
]

@testset "RayMakie" begin
    for fname in TEST_FILES
        @testset "$fname" begin
            include(joinpath(@__DIR__, fname))
        end
    end

    # `supports_batch_queue`, not `supports_graphics`: these files composite
    # rasterised overlays by RECORDING INTO a batch queue, and the two questions
    # came apart when Metal learned to rasterise. Metal compiles vertex and
    # fragment programs and draws with them, but has no command pool or fence to
    # build a `BatchQueue` out of, so `allocate_batch_queue!` throws there by
    # design. Asking the wrong question sends this straight into that throw.
    if Mantle.supports_batch_queue(BACKEND)
        for fname in GRAPHICS_TEST_FILES
            @testset "$fname" begin
                include(joinpath(@__DIR__, fname))
            end
        end
    else
        @info "RayMakie tests: no batch queue to record overlays into; skipping the rasterised-overlay files" backend =
              nameof(typeof(BACKEND)) files = GRAPHICS_TEST_FILES rasterises = Mantle.supports_graphics(BACKEND)
    end

    if isdefined(Mantle, :vk_context)
        for fname in VULKAN_RUNTIME_TEST_FILES
            @testset "$fname" begin
                include(joinpath(@__DIR__, fname))
            end
        end
    else
        @info "RayMakie tests: no Vulkan runtime loaded; skipping its deferred-free \
               ledger tests" files = VULKAN_RUNTIME_TEST_FILES
    end
end

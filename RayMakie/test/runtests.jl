using Test

# Single-process test entry point.
#
# Only test files that are stable when chained together in a single session
# are listed here. Several of the older files in this directory either
#   (1) have zero `@test` assertions (println scripts: test_basic_gpu.jl,
#       test_per_instance_colors.jl, test_smoke_volume{,_gpu}.jl), or
#   (2) referenced removed APIs (test_materials_scene.jl) — FIXED, see below, or
#   (3) bypass the RayMakie package init by `include()`-ing internal source
#       files (test_lava_array_meshscatter.jl pulls in lava_arrays.jl by hand,
#       which leaves the BatchQueue in a state that desyncs every
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
# `test_dolphin_update_stress.jl` were calling runtime APIs the per-BatchQueue
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
    "test_material_precedence.jl",
    "test_overlay_compositing.jl",
    "test_figure_scene_routing.jl",
    "test_lava_meshscatter_pervec.jl",
    "test_meshscatter_update_stress.jl",
    "test_mesh_update_stress.jl",
    "test_recolor_keeps_blas.jl",
    "test_transform_update_hwtlas.jl",
    "test_update_paths.jl",
    # Leak / GC regressions.
    "test_caching_gc_correctness.jl",
    "test_materials_scene.jl",
]

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

@testset "RayMakie" begin
    for fname in TEST_FILES
        @testset "$fname" begin
            include(joinpath(@__DIR__, fname))
        end
    end
end

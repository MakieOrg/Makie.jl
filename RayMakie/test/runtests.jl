using Test

# Single-process test entry point.
#
# Only test files that are stable when chained together in a single session
# are listed here. Several of the older files in this directory either
#   (1) have zero `@test` assertions (println scripts: test_basic_gpu.jl,
#       test_per_instance_colors.jl, test_smoke_volume{,_gpu}.jl), or
#   (2) reference removed APIs (test_materials_scene.jl uses
#       Hikari.FilmSensor which no longer exists), or
#   (3) bypass the RayMakie package init by `include()`-ing internal source
#       files (test_lava_array_meshscatter.jl pulls in lava_arrays.jl by hand,
#       which leaves the Lava BatchQueue in a state that desyncs every
#       subsequent RayMakie test in the same process), or
#   (4) leave LavaArray finalizers attached to a semaphore whose timeline
#       has been freed; running GC after them segfaults
#       (test_caching_gc_correctness.jl).
# Run those individually in fresh sessions when needed.
#
# (4) is FIXED — `Lava.allocate_batch_queue!` now hands the context ownership of
# every queue it returns, so a semaphore cannot be finalized while a buffer that
# names it is still alive, and `release_batch_queue!` is the way back out. The
# exclusion above stands only until someone re-checks
# test_caching_gc_correctness.jl against it; see Lava's
# test_batch_queue_lifetime.jl for the invariant.

const TEST_FILES = [
    # CPU-only (no render), so it fails fast and before anything touches a device.
    "test_pbrt_import_settings.jl",
    "test_material_precedence.jl",
    "test_overlay_compositing.jl",
    "test_figure_scene_routing.jl",
    "test_lava_meshscatter_pervec.jl",
    "test_meshscatter_update_stress.jl",
    "test_mesh_update_stress.jl",
]

@testset "RayMakie" begin
    for fname in TEST_FILES
        @testset "$fname" begin
            include(joinpath(@__DIR__, fname))
        end
    end
end

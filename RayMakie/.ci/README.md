# RayMakie software Vulkan CI

Use Julia 1.12 and this explicit environment to resolve the current
`ff/breaking-0.25` Makie checkout with the published material/backend branches:

```sh
julia --project=RayMakie/.ci -e 'using Pkg; Pkg.instantiate()'
RAYMAKIE_TEST_LAVAPIPE=true LIBGL_ALWAYS_SOFTWARE=true \
    xvfb-run -a julia --project=RayMakie/.ci -e \
    'using Pkg; Pkg.test("RayMakie"; allow_reresolve=false, julia_args=`--check-bounds=auto`)'
```

`Lavapipe_jll` supplies Vulkan; Mesa's system OpenGL driver is used only by
GLMakie's comparison tests. The suite asserts that Vulkan actually selected
llvmpipe after loading the backend. All material updates, nested field updates,
image updates and supported graphics/window tests run. No pixel tolerances or
sample counts are reduced for software rendering.

The normal bounds policy is required by the GPU stack, as in Raycore's GPU
suite. A forced `--check-bounds=yes` injects device exception paths.

`LocalPreferences.toml` disables development precompile workloads and enables
ComputePipeline's consistency checks. The generated Manifest is not committed;
refresh the branch sources with `Pkg.update()` when reusing this environment.

For a hardware worker, omit `RAYMAKIE_TEST_LAVAPIPE` and select the device with
`RAYMAKIE_TEST_DEVICE` when more than one device is present. `Pkg.test` accepts
file names in `test_args` for focused material, image and text update checks.

The 100k-instance regression checks device storage and host allocations directly.
Its frame time is reported; the former two-second wall-clock gate depended on
GPU hardware and could not measure a software renderer fairly.

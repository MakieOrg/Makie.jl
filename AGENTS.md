# Makie Development Guide

## Repository Structure

Makie is a monorepo. The core plotting library lives in `Makie/`, the compute graph infrastructure in `ComputePipeline/`, and the backends in `CairoMakie/`, `GLMakie/`, `WGLMakie/`, and `RPRMakie/`.

## Documentation

The `docs/src/explanations/` directory contains high-level documentation useful for understanding Makie's internals, for example:

- `architecture.md` -- general overview of how Makie is structured
- `recipes.md` -- a primer on how to create plot recipes
- `compute-pipeline.md` -- more detailed description of the compute graph system
- `conversion_pipeline.md` -- describes Makie's complex input conversion system

## API Boundaries

The backends are always pinned to a specific patch version of Makie, so there is no official API boundary between Makie and the backends. Makie has its public API (the backends have almost none of their own), but code that crosses the Makie-backend boundary can freely use Makie internals since the pinning guarantees compatibility.

## Setting Up a Development Environment

Each backend has its own `test/` environment, but those are tied to that specific backend and its test dependencies. For running examples and debugging, it's better to set up a scratch environment in `.scratch/` (gitignored). A scratch env gives you more flexibility -- you can load multiple backends together, add only the packages you need, and freely mix and match without being constrained by any single backend's project structure. It's also useful for testing downstream packages like AlgebraOfGraphics alongside local Makie changes.

```
mkdir -p .scratch
```

### 1. Disable PrecompileTools Workloads

Makie's precompilation workloads are expensive. To skip them during development, create a `.scratch/LocalPreferences.toml` before `dev`'ing any packages:

```toml
[Makie]
precompile_workload = false

[CairoMakie]
precompile_workload = false

[GLMakie]
precompile_workload = false

[WGLMakie]
precompile_workload = false
```

### 2. Choosing one or more Backends

- **CairoMakie** -- good default for development. Works everywhere (no GPU needed), loads faster, and is sufficient for most non-interactive 2D plots.
- **GLMakie** -- use when working on interactive features or testing OpenGL rendering.
- **WGLMakie** -- the slowest of the three main backends, use when working on web/browser-based rendering.
- **RPRMakie** -- rarely used raytracing backend with incomplete functionality.

Only `dev` the backends you need. Each additional backend adds precompilation overhead.

### 3. Dev the Relevant Local Packages

From the `.scratch/` directory, `dev` the local packages you need. Always dev `ComputePipeline` and `Makie` as they are the core. Then add only the backend(s) you actually need to avoid unnecessary dependencies.

```julia
using Pkg
Pkg.activate(".scratch")
Pkg.develop([
    PackageSpec(path="ComputePipeline"),
    PackageSpec(path="Makie"),
    PackageSpec(path="CairoMakie"),  # or GLMakie, WGLMakie, ... as needed
])
```

## Example Code for Testing

To check if recipes still work as intended, useful example code can be found in `ReferenceTests/src/tests/`, primarily:

- `examples2d.jl`
- `examples3d.jl`
- `figures_and_makielayout.jl`
- `primitives.jl`

Individual plots and blocks may also have examples defined via `attribute_examples(::Type{SomePlotOrBlock})`.

## Comparing Before/After Images

When changing rendering methods or other visual behavior, compare before and after images to check for regressions. Add `PixelMatch.jl` to the `.scratch` environment for pixel-level image comparison:

```julia
using FileIO, PixelMatch

img1 = load("before.png")
img2 = load("after.png")
num_diff_pixels, diff_img = pixelmatch(img1, img2)
# if needed, the diff image can be saved for the user
save("diff.png", diff_img)
```

## Code Formatting

All code must be formatted before finalizing a PR:

```sh
julia tooling/formatter/format.jl
```

## Changelog

User-facing changes (bug fixes, new features, breaking changes) must be recorded in `CHANGELOG.md` under the `## Unreleased` section at the top. Each entry is a single bullet point with a brief description and a link to the PR.

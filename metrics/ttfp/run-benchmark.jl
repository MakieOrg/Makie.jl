#= TODO
Improve analysis of benchmark results to account for the variance in the benchmarks.
=#

using Pkg, TOML
Pkg.activate(@__DIR__)
Pkg.update()

include("plot-benchmark.jl")

length(ARGS) == 4 || error("Usage: run-benchmark.jl <Package> <n_samples> <merged checkout> <base checkout>")
Package, n_samples_arg, merged_checkout, base_checkout = ARGS
n_samples = parse(Int, n_samples_arg)
n_inference_samples = 3

@info("Benchmarking $(Package) at $(merged_checkout) against $(base_checkout) with $(n_samples) samples")

results_dir = abspath("benchmark_results")
results_file(project) = joinpath(results_dir, "$Package-$(basename(project)).json")

function run_benchmark(project, run_index, mode)
    benchmark_file = joinpath(@__DIR__, "benchmark-ttfp.jl")
    println(basename(project), " ", mode, " ", run_index)
    run(`$(Base.julia_cmd()) --startup-file=no --project=$(project) $benchmark_file $Package $(results_file(project)) $run_index $mode`)
    return
end

function run_benchmarks(projects)
    # go A, A, B, B, A, A, B, B, etc. because if A or B have some effect on their
    # subsequent run, then we distribute those more evenly. If we used A, B, A, B then
    # B would always influence A and A always B which might bias the results (something
    # that can carry over separate processes like thermal throttling or so)

    A, B = projects
    As = Iterators.partition(fill(A, n_samples), 2)
    Bs = Iterators.partition(fill(B, n_samples), 2)
    timing_order = collect(Iterators.flatten(Iterators.flatten(zip(As, Bs))))

    # The first run after precompilation pays for a cold disk cache.
    for project in projects
        run_benchmark(project, 0, "warmup")
    end
    for (run_index, project) in enumerate(timing_order)
        run_benchmark(project, run_index, "timing")
    end
    for (run_index, project) in enumerate(repeat(projects, n_inference_samples))
        run_benchmark(project, run_index, "inference")
    end
    return
end

function make_project_folder(name)
    project = joinpath(@__DIR__, "benchmark-projects", name)
    rm(results_file(project); force = true)
    # It seems, that between julia versions, the manifest must be deleted to not get problems
    isdir(project) && rm(project; force = true, recursive = true)
    mkpath(project)
    return project
end

function setup_project(name, checkout)
    project = make_project_folder(name)
    Pkg.activate(project)
    Pkg.develop([(; path = joinpath(checkout, pkg)) for pkg in ["ComputePipeline", "Makie", Package]])
    Pkg.add(Package == "WGLMakie" ? ["JSON", "SnoopCompileCore", "Electron"] : ["JSON", "SnoopCompileCore"])
    @time Pkg.precompile()
    return project
end

function manifest_versions(project)
    manifest = TOML.parsefile(joinpath(project, "Manifest.toml"))
    return Dict(name => get(first(entries), "version", "stdlib") for (name, entries) in manifest["deps"])
end

function manifest_diff_markdown(merged, base)
    merged_versions, base_versions = manifest_versions(merged), manifest_versions(base)
    names = sort!(collect(union(keys(merged_versions), keys(base_versions))))
    rows = NamedTuple[]
    for name in names
        m, b = get(merged_versions, name, nothing), get(base_versions, name, nothing)
        m == b && continue
        change = m === nothing ? "removed" :
            b === nothing ? "added" :
            VersionNumber(m) > VersionNumber(b) ? "upgraded" : "downgraded"
        push!(rows, (; name, base = something(b, "-"), merged = something(m, "-"), change))
    end
    isempty(rows) && return "$Package: Manifests identical\n"

    counts = join(["$(count(r -> r.change == c, rows)) $c" for c in ["added", "removed", "upgraded", "downgraded"]], ", ")
    table = join(["| $(r.name) | $(r.base) | $(r.merged) | $(r.change) |" for r in rows], "\n")
    return """
    <details><summary>$Package: Manifest differences ($counts)</summary>

    | Package | base | merged | change |
    |---|---|---|---|
    $table

    </details>
    """
end

mkpath(results_dir)
ENV["JULIA_PKG_PRECOMPILE_AUTO"] = 0
projects = [setup_project("merged", merged_checkout), setup_project("base", base_checkout)]

manifest_diff = manifest_diff_markdown(projects...)
println(manifest_diff)
write(joinpath(results_dir, "$Package-manifest-diff.md"), manifest_diff)

run_benchmarks(projects)

fig = plot_results(load_results(results_dir, Package), Package)
save(joinpath(results_dir, "$Package.svg"), fig)

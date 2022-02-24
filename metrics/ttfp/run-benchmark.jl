cd(@__DIR__)
using Pkg
Pkg.activate(".")
Pkg.instantiate()
using JSON, Statistics, GitHub, Base64, SHA, Downloads, Dates, CairoMakie

include("benchmark-library.jl")

ctx = github_context()
bench_infos = bench_info.(Ref(ctx), [GitHub.tag(ctx.repo, "v0.16.5"), current_commit()])
@info("benchmarking commits $(bench_infos)")
benchmarks = get_benchmark_data.(Ref(ctx), bench_infos)

@info("done benchmarking, plotting")
fig = plot_benchmarks(benchmarks, bench_infos)

name = join(map(best_name, bench_infos), "-vs-")

@info("uploading plot $(name) to github")
image_url = upload_data(ctx, fig, "benchmarks/$(name).png")

comment = """
## Compile Times compared to tagged

![]($(image_url))
"""

pr_num = get(ENV, "PR_NUMBER", nothing)

if !isnothing(pr_num)
    @info("Commenting plot on PR $(pr_num)")
    pr = GitHub.pull_request(ctx.repo, pr_num)
    make_or_edit_comment(ctx, pr, comment)
else
    @info("No comment, no PR found")
end

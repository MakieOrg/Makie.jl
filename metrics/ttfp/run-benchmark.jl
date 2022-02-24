cd(@__DIR__)
using Pkg
Pkg.activate(".")
using JSON, Statistics, GitHub, Base64, SHA, Downloads, Dates, CairoMakie

include("benchmark-library.jl")

ctx = github_context()
commits_to_bench = [tag_commit("v0.16.5"), current_commit()]
benchmarks = get_benchmark_data.(Ref(ctx), commits_to_bench)
fig = plot_benchmarks(benchmarks)

name = join(map(x-> x[1:5], commits_to_bench), "-vs-")
image_url = upload_data(ctx, fig, "benchmarks/$(name).png")

comment = """
## Compile Times compared to tagged

![]($(image_url))
"""

pr = GitHub.PullRequest(benchmarks[end]["pr"])

make_or_edit_comment(ctx, pr, comment)

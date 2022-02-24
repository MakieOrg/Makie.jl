using Pkg
Pkg.instantiate()
using JSON, Statistics, GitHub, Base64, SHA, Downloads, Dates
cd(@__DIR__)
include("benchmark-library.jl")

ctx = github_context()

url = upload_file(ctx, "test.png", "test3.png")

comment = """
## Compile Times compared to tagged

![]($(url))
"""

pr = GitHub.PullRequest(1691)

make_or_edit_comment(ctx, pr, comment)

# save("test.png", series(rand(4,10)))
